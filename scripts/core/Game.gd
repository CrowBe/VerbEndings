extends Node
## Root scene coordinator for the playable greybox.
##
## Game is the composition root: it owns local bootstrap, network Subject
## composition, and Round scene loading.
## TrialCoordinator drives lifecycle state; Game responds by composing the
## requested Round scene and keeping presentation nodes out of domain logic.

const DEFAULT_PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const DEFAULT_LOCAL_CONFIG: LocalPlaytestConfig = preload("res://resources/local_playtest.tres")
const LABORATORY_TRANSIT_SCRIPT: Script = preload(
		"res://scripts/presentation/LaboratoryTransit.gd")
const ROUND_SCENES: Dictionary = {
	"PVP": preload("res://scenes/rounds/PVPRound.tscn"),
	"PVE": preload("res://scenes/rounds/PVERound.tscn"),
	"ENVIRONMENT": preload("res://scenes/rounds/EnvironmentRound.tscn"),
}
const ROUND_LABORATORIES: Dictionary = {
	"PVP": &"CompetitiveStress",
	"PVE": &"AdaptiveContainment",
	"ENVIRONMENT": &"AppliedAttrition",
}

@export var auto_start_greybox: bool = true
@export var local_playtest_config: LocalPlaytestConfig = DEFAULT_LOCAL_CONFIG
@export var player_scene: PackedScene = DEFAULT_PLAYER_SCENE

@onready var world_root: Node3D = $World
@onready var compound: Compound = $World/Compound
@onready var players_root: Node3D = $World/Players
@onready var round_root: Node3D = $World/Round
@onready var transit_root: Node = $World/LaboratoryTransit

var current_round: Node3D = null
var local_player: Node3D = null
var local_subjects: Array[Node3D] = []
var active_seed: int = 0
var laboratory_transit: LaboratoryTransit = null


func _ready() -> void:
	TrialCoordinator.experiment_requested.connect(_on_experiment_requested)
	TrialCoordinator.phase_changed.connect(_on_trial_phase_changed)
	NetworkSession.roster_changed.connect(_on_network_roster_changed)
	LobbyManager.verb_selected.connect(_on_network_verb_selected)
	laboratory_transit = LABORATORY_TRANSIT_SCRIPT.new() as LaboratoryTransit
	transit_root.add_child(laboratory_transit)
	laboratory_transit.entry_completed.connect(_on_laboratory_entry_completed)
	laboratory_transit.recall_completed.connect(_on_recall_completed)
	if auto_start_greybox:
		start_local_playtest()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") \
			and TrialCoordinator.current_phase == TrialCoordinator.Phase.LABORATORY_ENTRY:
		if NetworkSession.mode == NetworkSession.Mode.LOCAL:
			if local_player != null:
				laboratory_transit.request_release(
						local_player.get_multiplayer_authority())
		else:
			NetworkSession.request_release()
	elif event.is_action_pressed("restart_same_seed"):
		restart_local_playtest(false)
	elif event.is_action_pressed("restart_new_seed"):
		restart_local_playtest(true)
	elif event.is_action_pressed("start_local_playtest"):
		start_local_playtest()


## Starts the resource-configured local quick start through domain services.
func start_local_playtest() -> void:
	active_seed = local_playtest_config.trial_seed
	_build_local_playtest(active_seed)


func restart_local_playtest(use_new_seed: bool) -> void:
	if use_new_seed:
		active_seed += 1
	elif active_seed == 0:
		active_seed = local_playtest_config.trial_seed
	_build_local_playtest(active_seed)


## Hosts an ENet session and enrols this process as Subject 1.
func host_session(port: int = NetworkSession.DEFAULT_PORT,
		max_clients: int = NetworkSession.DEFAULT_MAX_CLIENTS,
		trial_seed: int = local_playtest_config.trial_seed) -> Error:
	_prepare_session_state()
	active_seed = trial_seed
	var error: Error = NetworkSession.host_session(port, max_clients, trial_seed)
	if error == OK:
		LobbyManager.open_verb_selection()
	return error


## Joins an ENet host. The authoritative roster creates Subjects on receipt.
func join_session(address: String,
		port: int = NetworkSession.DEFAULT_PORT) -> Error:
	_prepare_session_state()
	return NetworkSession.join_session(address, port)


## Starts the host-authored Trial once every connected Subject has a Verb.
func start_hosted_trial(duration_override: float = -1.0) -> bool:
	if not NetworkSession.is_host():
		return false
	for player_id: int in LobbyManager.lobby_players:
		if VerbChainManager.active_players.get(player_id, Enums.VerbType.NONE) \
				== Enums.VerbType.NONE:
			return false
	var started: bool = TrialCoordinator.start_trial(
			active_seed, false, duration_override)
	NetworkSession.publish_now()
	return started


func _build_local_playtest(trial_seed: int) -> void:
	NetworkSession.shutdown()
	_prepare_session_state()
	active_seed = trial_seed
	seed(trial_seed)
	_spawn_local_subjects()
	TrialCoordinator.start_trial(trial_seed, true, -1.0,
			local_playtest_config.protocol_classification)


func _prepare_session_state() -> void:
	if laboratory_transit != null:
		laboratory_transit.cancel()
	_teardown_local_playtest()
	LobbyManager.reset()
	VerbChainManager.reset()
	ScoreManager.reset()
	RoundManager.reset()
	TrialCoordinator.reset()


## Compatibility seam for existing lifetime tests and developer tooling.
func start_greybox_trial(round_type: String) -> void:
	local_playtest_config.protocol_classification = round_type
	start_local_playtest()


func load_round(round_type: String) -> Node3D:
	var laboratory_id: StringName = ROUND_LABORATORIES.get(round_type, &"")
	if laboratory_id.is_empty() or not compound.select_active_laboratory(laboratory_id):
		push_warning("Game: no Laboratory registered for round type '%s'." % round_type)
		return null
	if current_round != null:
		# Detach before moving the shared Round root so the outgoing Round cannot
		# render for one frame at the next Laboratory while queue_free resolves.
		round_root.remove_child(current_round)
		current_round.queue_free()
		current_round = null
	var round_scene: PackedScene = ROUND_SCENES.get(round_type)
	if round_scene == null:
		push_warning("Game: no scene registered for round type '%s'." % round_type)
		return null
	current_round = round_scene.instantiate() as Node3D
	if current_round == null:
		push_warning("Game: round scene for '%s' must instantiate a Node3D root." % round_type)
		return null
	round_root.transform = compound.get_laboratory_anchor_transform(laboratory_id)
	if RoundManager.current_protocol != null \
			and RoundManager.current_protocol.classification == round_type:
		current_round.set("protocol", RoundManager.current_protocol)
	round_root.add_child(current_round)
	RoundManager.current_round_type = round_type
	return current_round


func _spawn_local_subjects() -> void:
	for subject_index: int in local_playtest_config.subject_count:
		var player_id: int = subject_index + 1
		LobbyManager.join_lobby(player_id)
		ScoreManager.register_player(player_id)
	LobbyManager.open_verb_selection()
	for subject_index: int in local_playtest_config.subject_count:
		var player_id: int = subject_index + 1
		var verb: Enums.VerbType = _select_local_verb(player_id, subject_index)
		if verb == Enums.VerbType.NONE:
			push_warning("Game: no unique Verb remains for local Subject %d." % player_id)
			continue
		var subject: Node3D = player_scene.instantiate() as Node3D
		if subject == null:
			continue
		subject.name = "LocalSubject%d" % player_id
		subject.set_multiplayer_authority(player_id)
		subject.set("accepts_local_input", subject_index == 0)
		subject.call("set_character_identity", verb)
		players_root.add_child(subject)
		local_subjects.append(subject)
	local_player = local_subjects[0] if not local_subjects.is_empty() else null


func _on_network_roster_changed(player_ids: Array[int]) -> void:
	if NetworkSession.mode == NetworkSession.Mode.LOCAL:
		return
	var existing: Dictionary = {}
	for subject: Node3D in local_subjects:
		if is_instance_valid(subject):
			existing[subject.get_multiplayer_authority()] = subject
	for player_id: int in player_ids:
		if existing.has(player_id):
			continue
		var subject: Node3D = player_scene.instantiate() as Node3D
		if subject == null:
			continue
		subject.name = "NetworkSubject%d" % player_id
		subject.set_multiplayer_authority(player_id)
		subject.set("accepts_local_input", player_id == multiplayer.get_unique_id())
		players_root.add_child(subject)
		local_subjects.append(subject)
	for subject: Node3D in local_subjects.duplicate():
		if not is_instance_valid(subject):
			local_subjects.erase(subject)
			continue
		if subject.get_multiplayer_authority() not in player_ids:
			players_root.remove_child(subject)
			subject.queue_free()
			local_subjects.erase(subject)
	for subject: Node3D in local_subjects:
		var verb: Enums.VerbType = VerbChainManager.active_players.get(
				subject.get_multiplayer_authority(), Enums.VerbType.NONE)
		subject.call("set_character_identity", verb)
	local_player = null
	for subject: Node3D in local_subjects:
		if subject.get_multiplayer_authority() == multiplayer.get_unique_id():
			local_player = subject
			break


func _on_network_verb_selected(player_id: int, verb: Enums.VerbType,
		_seconds_taken: float) -> void:
	if NetworkSession.mode == NetworkSession.Mode.LOCAL:
		return
	for subject: Node in local_subjects:
		if subject.get_multiplayer_authority() == player_id:
			subject.call("set_character_identity", verb)
			return


func _select_local_verb(player_id: int, subject_index: int) -> Enums.VerbType:
	var configured: Enums.VerbType = local_playtest_config.verb_for_subject(subject_index)
	var selectable: Array[Dictionary] = LobbyManager.get_selectable_verbs()
	for entry: Dictionary in selectable:
		if entry.verb == configured \
				and LobbyManager.select_verb_for_local_playtest(player_id, configured):
			return configured
	for entry: Dictionary in selectable:
		var fallback: Enums.VerbType = entry.verb
		if LobbyManager.select_verb_for_local_playtest(player_id, fallback):
			return fallback
	return Enums.VerbType.NONE


func _teardown_local_playtest() -> void:
	if current_round != null:
		round_root.remove_child(current_round)
		current_round.queue_free()
		current_round = null
	for subject: Node3D in local_subjects:
		if is_instance_valid(subject):
			players_root.remove_child(subject)
			subject.queue_free()
	local_subjects.clear()
	local_player = null


func _on_experiment_requested(_round_index: int, protocol: ExperimentProtocol) -> void:
	var controller: Node3D = current_round
	if controller == null:
		controller = load_round(protocol.classification)
	if controller == null:
		return
	if protocol.classification == "PVE":
		controller.set("grammar_seed", active_seed + RoundManager.current_round_index)
	TrialCoordinator.set_active_round_controller(controller)


func _on_trial_phase_changed(phase: TrialCoordinator.Phase, _round_index: int,
		protocol: ExperimentProtocol) -> void:
	if phase == TrialCoordinator.Phase.LABORATORY_ENTRY and protocol != null:
		var controller: Node3D = load_round(protocol.classification)
		if controller == null:
			return
		var laboratory_id: StringName = ROUND_LABORATORIES.get(
				protocol.classification, &"")
		if not laboratory_transit.begin_entry(
				compound, laboratory_id, local_subjects):
			TrialCoordinator.complete_laboratory_entry()
	elif phase == TrialCoordinator.Phase.RECALL:
		if current_round != null:
			current_round.process_mode = Node.PROCESS_MODE_DISABLED
		var laboratory_id: StringName = ROUND_LABORATORIES.get(
				RoundManager.current_round_type, &"")
		if not laboratory_transit.begin_recall(
				compound, laboratory_id, local_subjects):
			_on_recall_completed()


func _on_laboratory_entry_completed() -> void:
	if NetworkSession.mode != NetworkSession.Mode.CLIENT:
		TrialCoordinator.complete_laboratory_entry()


func _on_recall_completed() -> void:
	if current_round != null:
		round_root.remove_child(current_round)
		current_round.queue_free()
		current_round = null
	if NetworkSession.mode != NetworkSession.Mode.CLIENT:
		TrialCoordinator.complete_recall()
