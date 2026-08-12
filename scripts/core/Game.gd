extends Node
## Root scene coordinator for the playable greybox.
##
## Game is the composition root: it owns bootstrap, Round scene loading, and
## temporary local-player spawning until multiplayer spawning is implemented.
## It does not drive the three-Round Trial lifecycle; RoundManager owns
## Protocol selection and Game adopts the selected Protocol only when its
## classification matches the requested Round.

const DEFAULT_PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const DEFAULT_LOCAL_CONFIG: LocalPlaytestConfig = preload("res://resources/local_playtest.tres")
const ROUND_SCENES: Dictionary = {
	"PVP": preload("res://scenes/rounds/PVPRound.tscn"),
	"PVE": preload("res://scenes/rounds/PVERound.tscn"),
	"PUZZLE": preload("res://scenes/rounds/PuzzleRound.tscn"),
}
const ROUND_LABORATORIES: Dictionary = {
	"PVP": &"CompetitiveStress",
	"PVE": &"AdaptiveContainment",
	"PUZZLE": &"AppliedCausality",
}

@export var auto_start_greybox: bool = true
@export var local_playtest_config: LocalPlaytestConfig = DEFAULT_LOCAL_CONFIG
@export var player_scene: PackedScene = DEFAULT_PLAYER_SCENE

@onready var world_root: Node3D = $World
@onready var compound: Compound = $World/Compound
@onready var players_root: Node3D = $World/Players
@onready var round_root: Node3D = $World/Round

var current_round: Node3D = null
var local_player: Node3D = null
var local_subjects: Array[Node3D] = []
var active_seed: int = 0


func _ready() -> void:
	if auto_start_greybox:
		start_local_playtest()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_same_seed"):
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


func _build_local_playtest(trial_seed: int) -> void:
	_teardown_local_playtest()
	LobbyManager.reset()
	VerbChainManager.reset()
	ScoreManager.reset()
	if not RoundManager.queue_local_protocol(
			local_playtest_config.protocol_classification, trial_seed):
		return
	seed(trial_seed)
	var round_type: String = RoundManager.advance_to_next_round()
	_spawn_local_subjects()
	_pair_local_roster()
	load_round(round_type)


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
	_place_local_subjects_for_round(round_type)
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


func _select_local_verb(player_id: int, subject_index: int) -> Enums.VerbType:
	var configured: Enums.VerbType = local_playtest_config.verb_for_subject(subject_index)
	var selectable: Array[Dictionary] = LobbyManager.get_selectable_verbs()
	for entry: Dictionary in selectable:
		if entry.verb == configured and LobbyManager.select_verb(player_id, configured):
			return configured
	for entry: Dictionary in selectable:
		var fallback: Enums.VerbType = entry.verb
		if LobbyManager.select_verb(player_id, fallback):
			return fallback
	return Enums.VerbType.NONE


func _pair_local_roster() -> void:
	VerbChainManager.auto_pair_all_players()


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


func _place_local_subjects_for_round(round_type: String) -> void:
	if local_subjects.is_empty():
		return
	var laboratory_id: StringName = ROUND_LABORATORIES.get(round_type, &"")
	var laboratory: Node3D = compound.get_laboratory(laboratory_id)
	if laboratory == null:
		return
	var centre_offset: float = (local_subjects.size() - 1) * 1.5
	for subject_index: int in local_subjects.size():
		local_subjects[subject_index].global_position = laboratory.to_global(Vector3(
			subject_index * 3.0 - centre_offset, 1.0, 16.0))
