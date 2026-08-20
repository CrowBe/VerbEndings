extends Node
## ENet session transport and explicit host-authoritative replication.
##
## Domain services remain transport-agnostic. This service enrols connected
## peers, validates their requests against the RPC sender, and publishes only
## already-revealed Trial state. RoundManager's secret Protocol queue never
## leaves the host.

signal session_hosted(port: int)
signal session_joined(peer_id: int)
signal session_closed
signal roster_changed(player_ids: Array[int])
signal authoritative_state_received(snapshot: Dictionary)
signal participant_disconnected(subject_id: int)
signal host_disconnected
## Validated client Release intent for the Drop implementation to consume.
signal release_requested(player_id: int)

const DEFAULT_PORT: int = 28714
const DEFAULT_MAX_CLIENTS: int = 8
const SNAPSHOT_INTERVAL: float = 0.05

enum Mode { LOCAL, HOST, CLIENT }

var mode: Mode = Mode.LOCAL
var trial_seed: int = 0
var _snapshot_elapsed: float = 0.0
var _movement_intents: Dictionary = {}
var _jump_intents: Dictionary = {}


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	TrialCoordinator.phase_changed.connect(_on_phase_changed)
	ScoreManager.trial_ranking_updated.connect(_on_trial_ranking_updated)
	LobbyManager.verb_selected.connect(_on_verb_selected)
	LobbyManager.draft_started.connect(_on_draft_started)
	LobbyManager.pair_locked.connect(_on_pair_locked)
	CollapseManager.collapse_triggered.connect(_on_collapse_triggered)
	CollapseManager.collapse_stage_changed.connect(_on_collapse_stage_changed)
	CollapseManager.player_eliminated.connect(_on_player_eliminated)


func _process(delta: float) -> void:
	if mode != Mode.HOST or not multiplayer.has_multiplayer_peer():
		return
	_snapshot_elapsed += delta
	if _snapshot_elapsed < SNAPSHOT_INTERVAL:
		return
	_snapshot_elapsed = 0.0
	_publish_snapshot(false)


func host_session(port: int = DEFAULT_PORT,
		max_clients: int = DEFAULT_MAX_CLIENTS, seed_value: int = 0) -> Error:
	shutdown()
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, max_clients)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	mode = Mode.HOST
	trial_seed = seed_value
	_enrol_player(multiplayer.get_unique_id())
	session_hosted.emit(port)
	_publish_snapshot(true)
	return OK


func join_session(address: String, port: int = DEFAULT_PORT) -> Error:
	shutdown()
	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, port)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	return OK


func shutdown() -> void:
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	mode = Mode.LOCAL
	trial_seed = 0
	_snapshot_elapsed = 0.0
	_movement_intents.clear()
	_jump_intents.clear()
	session_closed.emit()


## Transport authority: this process owns the ENet server peer. Use this for
## transport work only — enrolling peers, resolving RPC requests, publishing.
func is_host() -> bool:
	return mode == Mode.HOST and multiplayer.is_server()


## Domain authority: this process decides gameplay and lifecycle state. True
## for a local Trial and for the host; false for a client, which only applies
## replicated state. Every simulation and lifecycle guard asks this.
func can_simulate() -> bool:
	return mode != Mode.CLIENT


## This process receives authoritative state instead of producing it.
func is_client() -> bool:
	return mode == Mode.CLIENT


## No multiplayer peer: one process owns every Subject.
func is_local() -> bool:
	return mode == Mode.LOCAL


func request_verb(verb: Enums.VerbType) -> void:
	if is_host():
		LobbyManager.select_verb(multiplayer.get_unique_id(), verb)
		_publish_snapshot(true)
	elif mode == Mode.CLIENT:
		_request_verb.rpc_id(1, verb)


func request_pairing(target_id: int) -> void:
	if is_host():
		LobbyManager.request_pairing(multiplayer.get_unique_id(), target_id)
		_publish_snapshot(true)
	elif mode == Mode.CLIENT:
		_request_pairing.rpc_id(1, target_id)


func submit_movement(direction: Vector2, jump: bool = false) -> void:
	var bounded := direction.limit_length(1.0)
	if is_host():
		_store_movement_intent(multiplayer.get_unique_id(), bounded, jump)
	elif mode == Mode.CLIENT:
		_request_movement.rpc_id(1, bounded, jump)


func request_basic_hit() -> void:
	if is_host():
		_resolve_action(multiplayer.get_unique_id(), &"basic_hit")
	elif mode == Mode.CLIENT:
		_request_action.rpc_id(1, &"basic_hit")


func request_verb_expression() -> void:
	if is_host():
		_resolve_action(multiplayer.get_unique_id(), &"verb_expression")
	elif mode == Mode.CLIENT:
		_request_action.rpc_id(1, &"verb_expression")


func request_release() -> void:
	if is_host():
		_resolve_action(multiplayer.get_unique_id(), &"release")
	elif mode == Mode.CLIENT:
		# Start the owning client's presentation handoff immediately; the host
		# still validates the authoritative Release before simulating the Drop.
		release_requested.emit(multiplayer.get_unique_id())
		_request_action.rpc_id(1, &"release")


func get_movement_intent(player_id: int) -> Vector2:
	return _movement_intents.get(player_id, Vector2.ZERO)


func consume_jump_intent(player_id: int) -> bool:
	var requested: bool = _jump_intents.get(player_id, false)
	_jump_intents[player_id] = false
	return requested


func publish_now() -> void:
	if is_host():
		_publish_snapshot(true)


## Human-readable summary of replicated state, used by logging and the
## two-process suite to compare peers.
func state_digest() -> Dictionary:
	var lobby: Dictionary = LobbyManager.snapshot()
	var scores: Dictionary = ScoreManager.snapshot()
	return {
		"seed": trial_seed,
		"roster": lobby.lobby_players,
		"verbs": VerbChainManager.active_players.duplicate(true),
		"chains": VerbChainManager.verb_chains.duplicate(true),
		"dispensing_line_tubes": lobby.dispensing_line_tubes,
		"scores": scores.player_points,
		"round_scores": scores.round_scores,
		"round_index": RoundManager.current_round_index,
		"round_type": RoundManager.current_round_type,
		"round_history": RoundManager.round_history.duplicate(),
		"phase": TrialCoordinator.current_phase,
		"winner_id": TrialCoordinator.get_winner_id(),
		"collapse_active": CollapseManager.is_active,
		"collapse_survivors": CollapseManager.surviving_players.duplicate(),
		"collapse_state": CollapseManager.snapshot(),
		"facility_state": FacilityStateLedger.snapshot(false),
		"subjects": _subject_gameplay_digest(),
	}


@rpc("any_peer", "call_remote", "reliable")
func _request_verb(verb: Enums.VerbType) -> void:
	if not is_host():
		return
	LobbyManager.select_verb(multiplayer.get_remote_sender_id(), verb)
	_publish_snapshot(true)


@rpc("any_peer", "call_remote", "reliable")
func _request_pairing(target_id: int) -> void:
	if not is_host():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if LobbyManager.current_chooser_id != sender_id:
		return
	LobbyManager.request_pairing(sender_id, target_id)
	_publish_snapshot(true)


@rpc("any_peer", "call_remote", "unreliable_ordered", 0)
func _request_movement(direction: Vector2, jump: bool) -> void:
	if is_host():
		_store_movement_intent(multiplayer.get_remote_sender_id(), direction, jump)


@rpc("any_peer", "call_remote", "reliable")
func _request_action(action: StringName) -> void:
	if is_host():
		_resolve_action(multiplayer.get_remote_sender_id(), action)


@rpc("authority", "call_remote", "reliable")
func _receive_full_state(snapshot: Dictionary) -> void:
	_apply_snapshot(snapshot)


@rpc("authority", "call_remote", "unreliable_ordered", 1)
func _receive_actor_snapshot(snapshot: Dictionary) -> void:
	if mode != Mode.CLIENT:
		return
	TrialCoordinator.apply_replicated_experiment_clock(
			snapshot.get("experiment_seconds", 0.0))
	_apply_subject_snapshots(snapshot.get("subjects", []))
	_apply_residual_snapshots(snapshot.get("residuals", []))
	_apply_containment_tool_snapshots(snapshot.get("containment_tools", []))


func _on_peer_connected(peer_id: int) -> void:
	if not is_host():
		return
	_enrol_player(peer_id)
	_publish_snapshot(true)


func _on_peer_disconnected(peer_id: int) -> void:
	if not is_host():
		return
	participant_disconnected.emit(peer_id)
	LobbyManager.release_player(peer_id)
	ScoreManager.release_player(peer_id)
	_movement_intents.erase(peer_id)
	_jump_intents.erase(peer_id)
	roster_changed.emit(LobbyManager.lobby_players.duplicate())
	_publish_snapshot(true)


func _on_connected_to_server() -> void:
	session_joined.emit(multiplayer.get_unique_id())


func _on_connection_failed() -> void:
	shutdown()


func _on_server_disconnected() -> void:
	host_disconnected.emit()
	shutdown()


func _on_phase_changed(_phase: TrialCoordinator.Phase, _round_index: int,
		_protocol: ExperimentProtocol) -> void:
	publish_now()


func _on_trial_ranking_updated(_ranking: Array) -> void:
	publish_now()


func _on_verb_selected(_player_id: int, _verb: Enums.VerbType,
		_seconds_taken: float) -> void:
	publish_now()


func _on_draft_started(_round_index: int, _draft_order: Array) -> void:
	publish_now()


func _on_pair_locked(_chooser_id: int, _target_id: int,
		_chain: Dictionary) -> void:
	publish_now()


func _on_collapse_triggered(_participant_ids: Array) -> void:
	publish_now()


func _on_collapse_stage_changed(_stage: CollapseManager.Stage,
		_laboratory_id: StringName) -> void:
	publish_now()


func _on_player_eliminated(_player_id: int, _survivors_left: int) -> void:
	publish_now()


func _enrol_player(player_id: int) -> void:
	LobbyManager.join_lobby(player_id)
	ScoreManager.register_player(player_id)
	roster_changed.emit(LobbyManager.lobby_players.duplicate())


func _store_movement_intent(player_id: int, direction: Vector2, jump: bool) -> void:
	if player_id not in LobbyManager.lobby_players:
		return
	_movement_intents[player_id] = direction.limit_length(1.0)
	if jump:
		_jump_intents[player_id] = true


func _resolve_action(player_id: int, action: StringName) -> void:
	if player_id not in LobbyManager.lobby_players:
		return
	if action == &"release":
		release_requested.emit(player_id)
		return
	var subject: Node = SubjectRoster.body_of(player_id)
	if subject == null:
		return
	if action == &"basic_hit":
		subject.basic_hit()
	elif action == &"verb_expression":
		subject.express_verb()


func _publish_snapshot(reliable: bool) -> void:
	if not is_host() or multiplayer.get_peers().is_empty():
		return
	if reliable:
		_receive_full_state.rpc(_build_snapshot())
	else:
		_receive_actor_snapshot.rpc({
			"experiment_seconds": TrialCoordinator.experiment_seconds_remaining,
			"subjects": _subject_snapshots(),
			"residuals": _residual_snapshots(),
			"containment_tools": _containment_tool_snapshots(),
		})


## The authoritative wire snapshot. Each module composes its own state; this
## transport routes those compositions and adds nothing of its own beyond the
## session seed.
func _build_snapshot() -> Dictionary:
	var snapshot: Dictionary = state_digest()
	snapshot["lobby_state"] = LobbyManager.snapshot()
	snapshot["score_state"] = ScoreManager.snapshot()
	snapshot["experiment_seconds"] = TrialCoordinator.experiment_seconds_remaining
	snapshot["subjects"] = _subject_snapshots()
	snapshot["residuals"] = _residual_snapshots()
	snapshot["containment_tools"] = _containment_tool_snapshots()
	return snapshot


func _subject_snapshots() -> Array[Dictionary]:
	var subjects: Array[Dictionary] = []
	for subject: Node in SubjectRoster.bodies():
		subjects.append(subject.snapshot())
	return subjects


func _subject_gameplay_digest() -> Dictionary:
	var subjects: Dictionary = {}
	for subject: Node in SubjectRoster.bodies():
		subjects[subject.get_multiplayer_authority()] = {
			"stability": subject.stability,
			"destabilised": subject.is_destabilised,
			"partner_id": subject.paired_partner_id,
			"overdrive": subject.is_overdrive,
		}
	return subjects


func _residual_snapshots() -> Array[Dictionary]:
	var residuals: Array[Dictionary] = []
	for residual: Node3D in get_tree().get_nodes_in_group("residuals"):
		residuals.append({
			"name": residual.name,
			"transform": residual.global_transform,
			"visible": residual.visible,
			"stability": residual.stability,
			"verb": residual.verb,
			"adverb": residual.adverb,
			"entry_opening_id": residual.entry_opening_id,
			"entry_complete": residual.entry_complete,
		})
	return residuals


func _containment_tool_snapshots() -> Array[Dictionary]:
	var tools: Array[Dictionary] = []
	for tool: Node in get_tree().get_nodes_in_group("containment_tools"):
		if tool.has_method("snapshot"):
			tools.append(tool.snapshot())
	return tools


## Hands each module its own replicated state. Every module announces its own
## transitions, so the transport emits no domain signals of its own.
func _apply_snapshot(snapshot: Dictionary) -> void:
	if mode != Mode.CLIENT:
		return
	trial_seed = snapshot.get("seed", 0)
	LobbyManager.apply_replicated_state(snapshot.get("lobby_state", {}))
	VerbChainManager.apply_replicated_state(
			snapshot.get("verbs", {}), snapshot.get("chains", {}))
	ScoreManager.apply_replicated_state(snapshot.get("score_state", {}))
	RoundManager.apply_replicated_state(
			snapshot.get("round_index", 0), snapshot.get("round_type", ""),
			snapshot.get("round_history", []))
	FacilityStateLedger.apply_replicated_snapshot(snapshot.get("facility_state", {}))
	CollapseManager.apply_replicated_state(snapshot.get("collapse_state", {
		"is_active": snapshot.get("collapse_active", false),
		"surviving_players": snapshot.get("collapse_survivors", []),
	}))
	_apply_subject_snapshots(snapshot.get("subjects", []))
	TrialCoordinator.apply_replicated_state(
			snapshot.get("phase", TrialCoordinator.Phase.IDLE),
			snapshot.get("experiment_seconds", 0.0),
			snapshot.get("winner_id", -1), trial_seed)
	_apply_residual_snapshots(snapshot.get("residuals", []))
	_apply_containment_tool_snapshots(snapshot.get("containment_tools", []))
	roster_changed.emit(LobbyManager.lobby_players.duplicate())
	authoritative_state_received.emit(snapshot)


func _apply_subject_snapshots(snapshots: Array) -> void:
	for subject_state: Dictionary in snapshots:
		var subject: Node = SubjectRoster.body_of(subject_state.player_id)
		if subject == null:
			continue
		subject.apply_replicated_state(subject_state)


func _apply_residual_snapshots(snapshots: Array) -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return
	var parent: Node = current_scene.get_node_or_null("World/Round")
	if parent == null:
		return
	var existing: Dictionary = {}
	for residual: Node in get_tree().get_nodes_in_group("residuals"):
		existing[residual.name] = residual
	var received_names: Array[StringName] = []
	for residual_state: Dictionary in snapshots:
		var residual_name: StringName = residual_state.name
		received_names.append(residual_name)
		var residual: Node3D = existing.get(residual_name)
		if residual == null:
			residual = preload("res://scenes/Residual.tscn").instantiate()
			residual.name = residual_name
			parent.add_child(residual)
		residual.global_transform = residual_state.transform
		residual.visible = residual_state.get("visible", true)
		residual.stability = residual_state.stability
		residual.verb = residual_state.verb
		residual.adverb = residual_state.adverb
		residual.entry_opening_id = residual_state.get("entry_opening_id", &"")
		residual.entry_complete = residual_state.get("entry_complete", true)
		residual.animation_adapter.apply_verb_treatment(residual.verb)
		residual.animation_adapter.apply_adverb_treatment(residual.adverb)
	for residual_name: StringName in existing:
		if residual_name not in received_names:
			existing[residual_name].queue_free()


func _apply_containment_tool_snapshots(snapshots: Array) -> void:
	if mode != Mode.CLIENT:
		return
	var tools: Dictionary = {}
	for tool: Node in get_tree().get_nodes_in_group("containment_tools"):
		tools[tool.name] = tool
	for tool_state: Dictionary in snapshots:
		var tool: Node = tools.get(StringName(tool_state.get("name", &"")))
		if tool != null and tool.has_method("apply_replicated_state"):
			tool.apply_replicated_state(tool_state)
