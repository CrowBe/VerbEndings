extends Node

class FakeNetworkRound:
	extends Node
	signal round_finished(ordered_player_ids: Array)

	func end_round() -> void:
		var ordered: Array = LobbyManager.lobby_players.duplicate()
		ordered.sort()
		ScoreManager.award_placements(RoundManager.current_round_type, ordered)
		round_finished.emit(ordered)


const TEST_SEED: int = 91427
const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
var _is_server: bool = false
var _trial_started: bool = false
var _reported: bool = false
var _verb_requested: bool = false
var _disconnect_scenario: bool = false
var _deadline_msec: int = 0


func _ready() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	_is_server = "--server" in arguments
	_disconnect_scenario = "--disconnect" in arguments
	var port: int = _argument_value(arguments, "--port", 28714)
	_deadline_msec = Time.get_ticks_msec() + 15000
	NetworkSession.roster_changed.connect(_on_roster_changed)
	NetworkSession.authoritative_state_received.connect(_on_state_received)
	TrialCoordinator.experiment_requested.connect(_on_experiment_requested)
	TrialCoordinator.trial_completed.connect(_on_trial_completed)
	if _is_server:
		if NetworkSession.host_session(port, 2, TEST_SEED) != OK:
			_fail("server could not create its ENet peer")
	else:
		if NetworkSession.join_session("127.0.0.1", port) != OK:
			_fail("client could not create its ENet peer")


func _process(_delta: float) -> void:
	if Time.get_ticks_msec() > _deadline_msec and not _reported:
		_fail("network scenario timed out")


func _on_roster_changed(player_ids: Array[int]) -> void:
	_spawn_subjects(player_ids)
	if player_ids.size() != 2:
		return
	if _is_server and not _trial_started:
		LobbyManager.open_verb_selection()
		LobbyManager.select_verb_for_local_playtest(1, Enums.VerbType.BURN)
		NetworkSession.publish_now()
	elif not _is_server:
		var own_id: int = multiplayer.get_unique_id()
		if VerbChainManager.active_players.get(own_id, Enums.VerbType.NONE) \
				== Enums.VerbType.NONE and not _verb_requested:
			_verb_requested = true
			NetworkSession.request_verb(Enums.VerbType.SHIELD)


func _on_state_received(_snapshot: Dictionary) -> void:
	if _is_server:
		return
	var own_id: int = multiplayer.get_unique_id()
	if VerbChainManager.active_players.get(own_id, Enums.VerbType.NONE) \
			== Enums.VerbType.NONE and LobbyManager.lobby_players.size() == 2 \
			and not _verb_requested:
		_verb_requested = true
		NetworkSession.request_verb(Enums.VerbType.SHIELD)
	if TrialCoordinator.current_phase == TrialCoordinator.Phase.COMPLETE:
		var own_subject: Node = _subject_for(multiplayer.get_unique_id())
		if own_subject != null and own_subject.stability < 100.0:
			_report_success()
	elif _disconnect_scenario \
			and TrialCoordinator.current_phase == TrialCoordinator.Phase.EXPERIMENT:
		_reported = true
		get_tree().quit(0)


func _physics_process(_delta: float) -> void:
	if not _is_server or _trial_started:
		return
	if LobbyManager.lobby_players.size() != 2:
		return
	for player_id: int in LobbyManager.lobby_players:
		if VerbChainManager.active_players.get(player_id, Enums.VerbType.NONE) \
				== Enums.VerbType.NONE:
			return
	_trial_started = TrialCoordinator.start_trial(TEST_SEED, true, 0.03)
	NetworkSession.publish_now()


func _on_experiment_requested(_round_index: int,
		_protocol: ExperimentProtocol) -> void:
	if not _is_server:
		return
	var controller := FakeNetworkRound.new()
	add_child(controller)
	TrialCoordinator.set_active_round_controller(controller)


func _on_trial_completed(_winner_id: int) -> void:
	if not _is_server:
		return
	for subject: Node in get_tree().get_nodes_in_group("players"):
		if subject.get_multiplayer_authority() != 1:
			subject.apply_impact(27.0, null, false)
	NetworkSession.publish_now()
	_print_success()
	await get_tree().create_timer(0.4).timeout
	get_tree().quit(0)


func _report_success() -> void:
	if _reported:
		return
	_print_success()
	get_tree().quit(0)


func _print_success() -> void:
	if _reported:
		return
	_reported = true
	var role: String = "SERVER" if _is_server else "CLIENT"
	var prefix: String = "NETWORK_DISCONNECT" if _disconnect_scenario \
			else "NETWORK_SCENARIO"
	print("%s_%s %s" % [prefix, role,
			JSON.stringify(NetworkSession.state_digest())])


func _fail(message: String) -> void:
	if _reported:
		return
	_reported = true
	push_error(message)
	get_tree().quit(1)


func _argument_value(arguments: PackedStringArray, key: String,
		fallback: int) -> int:
	for argument: String in arguments:
		if argument.begins_with(key + "="):
			return argument.trim_prefix(key + "=").to_int()
	return fallback


func _spawn_subjects(player_ids: Array[int]) -> void:
	var existing: Array[int] = []
	for subject: Node in get_tree().get_nodes_in_group("players"):
		var player_id: int = subject.get_multiplayer_authority()
		if player_id not in player_ids:
			subject.queue_free()
			continue
		existing.append(player_id)
	for player_id: int in player_ids:
		if player_id in existing:
			continue
		var subject: Node = PLAYER_SCENE.instantiate()
		subject.name = "Subject%d" % player_id
		subject.set_multiplayer_authority(player_id)
		subject.accepts_local_input = false
		add_child(subject)


func _subject_for(player_id: int) -> Node:
	for subject: Node in get_tree().get_nodes_in_group("players"):
		if subject.get_multiplayer_authority() == player_id:
			return subject
	return null
