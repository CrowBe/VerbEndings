extends Node

const COMPOUND_SCENE: PackedScene = preload(
		"res://scenes/environment/Compound.tscn")
const GAME_SCENE: PackedScene = preload("res://scenes/core/Game.tscn")
const ROUND_TYPES: Array[String] = [
	"ENVIRONMENT", "PVP", "PVE",
	"ENVIRONMENT", "PVP", "PVE",
	"ENVIRONMENT", "PVP", "PVE",
	"ENVIRONMENT", "PVP", "PVE",
]


func _ready() -> void:
	var failures: Array[String] = []
	await _test_direct_compound_teardown()
	await _test_repeated_round_switching(failures)
	if failures.is_empty():
		print("Compound lifetime and teardown tests passed.")
		get_tree().quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	get_tree().quit(1)


func _test_direct_compound_teardown() -> void:
	var compound: Compound = COMPOUND_SCENE.instantiate()
	add_child(compound)
	await get_tree().process_frame
	await get_tree().physics_frame
	compound.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _test_repeated_round_switching(failures: Array[String]) -> void:
	var game: Node = GAME_SCENE.instantiate()
	game.auto_start_greybox = false
	add_child(game)
	await get_tree().process_frame
	var compound: Compound = game.get_node("World/Compound")
	var retained_ids: Dictionary = {}
	for laboratory_id: StringName in Compound.LABORATORY_IDS:
		var laboratory: Node3D = compound.get_laboratory(laboratory_id)
		retained_ids[laboratory_id] = laboratory.get_instance_id()
		laboratory.set_meta("lifetime_test_state", laboratory_id)
	for round_type: String in ROUND_TYPES:
		_expect(game.load_round(round_type) != null,
				"Game must load repeated %s Round" % round_type, failures)
		await get_tree().process_frame
		await get_tree().physics_frame
		_expect(game.get_node("World/Round").get_child_count() == 1,
				"Round switching must keep exactly one active Round", failures)
	for laboratory_id: StringName in Compound.LABORATORY_IDS:
		var laboratory: Node3D = compound.get_laboratory(laboratory_id)
		_expect(laboratory.get_instance_id() == retained_ids[laboratory_id],
				"Round switching must retain %s Laboratory identity"
				% laboratory_id, failures)
		_expect(laboratory.get_meta("lifetime_test_state") == laboratory_id,
				"Round switching must retain %s Laboratory state"
				% laboratory_id, failures)
	var config := LocalPlaytestConfig.new()
	config.protocol_classification = "PVE"
	config.subject_count = 1
	config.initial_verbs = [Enums.VerbType.BURN]
	game.local_playtest_config = config
	game.start_local_playtest()
	var expected_position: Vector3 = compound.get_laboratory(
			&"AdaptiveContainment").to_global(Vector3(0.0, 1.0, 16.0))
	_expect(game.local_player.global_position.is_equal_approx(expected_position),
			"Round switching must preserve correct Subject placement", failures)
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _expect(
	condition: bool,
	message: String,
	failures: Array[String],
) -> void:
	if not condition:
		failures.append(message)
