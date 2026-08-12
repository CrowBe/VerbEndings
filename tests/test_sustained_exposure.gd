extends Node

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const ROUND_SCENE: PackedScene = preload(
		"res://scenes/rounds/EnvironmentRound.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	VerbChainManager.reset()
	ScoreManager.reset()
	RoundManager.current_round_index = 1
	RoundManager.current_round_type = "ENVIRONMENT"

	var fixture := Node3D.new()
	fixture.name = "SustainedExposureFixture"
	add_child(fixture)
	var subject_a: Node = _add_subject(fixture, 1, Enums.VerbType.BURN)
	var subject_b: Node = _add_subject(fixture, 2, Enums.VerbType.JUMP)
	var environment_round: EnvironmentRound = ROUND_SCENE.instantiate()
	fixture.add_child(environment_round)
	environment_round.set_physics_process(false)

	_test_protocol(environment_round.protocol)
	_test_authored_routes(environment_round)
	_test_atmospheric_loss(environment_round, fixture, subject_a, subject_b)
	_test_material_scoring(environment_round, subject_a, subject_b)
	_test_breakable_supply(environment_round, fixture)

	fixture.queue_free()
	if _failures.is_empty():
		print("Sustained Exposure tests passed.")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	get_tree().quit(1)


func _add_subject(
	fixture: Node3D,
	player_id: int,
	verb: Enums.VerbType,
) -> Node:
	VerbChainManager.register_player(player_id, verb)
	ScoreManager.register_player(player_id)
	var subject: Node = PLAYER_SCENE.instantiate()
	subject.name = "Subject%d" % player_id
	subject.set_multiplayer_authority(player_id)
	subject.accepts_local_input = false
	subject.stabilisation_rate = 0.0
	# A hazard must suppress these guaranteed shedding rolls.
	subject.material_shed_probability = 1.0
	subject.destabilise_shed_probability = 1.0
	fixture.add_child(subject)
	return subject


func _test_protocol(protocol: ExperimentProtocol) -> void:
	_expect(protocol.protocol_id == &"sustained_exposure",
			"the authored Protocol uses the sustained_exposure id")
	_expect(protocol.classification == "ENVIRONMENT",
			"the Protocol uses the ENVIRONMENT development classification")
	_expect(protocol.completion_mode == "TIMER",
			"Sustained Exposure completes on its authored timer")
	_expect(protocol.scoring_rules.get("placement") \
			== "survival_time_and_material_secured",
			"the Protocol authors the survival-and-Material placement blend")
	_expect(not protocol.objective.to_lower().contains("residual"),
			"the Objective does not mention Residuals before any reveal")
	for verb_value: int in range(Enums.VerbType.BURN, Enums.VerbType.REWIND + 1):
		var verb_name: String = Enums.verb_name(verb_value as Enums.VerbType).capitalize()
		_expect(protocol.verb_answers.has(verb_name)
				and not str(protocol.verb_answers[verb_name]).is_empty(),
				"%s has an authored hazard, route or housing answer" % verb_name)


func _test_authored_routes(environment_round: EnvironmentRound) -> void:
	var apparatus: Array[PuzzleUnit] = environment_round.get_apparatus()
	_expect(apparatus.size() >= EnvironmentRound.MIN_APPARATUS_COUNT,
			"at least five physics apparatuses remain in the traversal field")
	for expected_script: Script in EnvironmentRound.APPARATUS_TYPES:
		_expect(apparatus.any(func(unit: PuzzleUnit) -> bool:
			return unit.get_script() == expected_script),
			"every retained physics apparatus type is present")
	for unit: PuzzleUnit in apparatus:
		_expect(not unit.has_signal("puzzle_completed"),
				"apparatus interaction has no completion-scoring signal")

	var dispensers: Array[Node] = environment_round.find_children(
			"*", "MaterialDispenser", true, false)
	_expect(not dispensers.is_empty(), "the Experiment authors Material dispensers")
	for dispenser: MaterialDispenser in dispensers:
		_expect(dispenser.position.y >= 4.0,
				"every dispenser is elevated beyond a walking route")
		_expect(not dispenser.traversal_route.is_empty(),
				"every dispenser names its authored traversal route")
	_expect(environment_round.get_tree().get_nodes_in_group("residuals").is_empty(),
			"Sustained Exposure contains no Residuals")


func _test_atmospheric_loss(
	environment_round: EnvironmentRound,
	fixture: Node3D,
	subject_a: Node,
	subject_b: Node,
) -> void:
	var material_before: int = _material_count(fixture)
	environment_round.atmospheric_stability_loss_per_second = 60.0
	environment_round.apply_exposure(2.0)
	_expect(subject_a.is_destabilised and subject_b.is_destabilised,
			"continuous atmospheric loss eventually Destabilises every live Subject")
	_expect(_material_count(fixture) == material_before,
			"atmospheric Stability Loss creates no Impact-shed Material")
	_expect(is_equal_approx(environment_round.survival_seconds[1], 2.0),
			"survival time is measured until Destabilisation")


func _test_material_scoring(
	environment_round: EnvironmentRound,
	subject_a: Node,
	subject_b: Node,
) -> void:
	subject_a.restabilise()
	subject_b.restabilise()
	subject_a.apply_hazard_stability_loss(20.0, environment_round)
	_expect(subject_a.absorb_material(15.0),
			"a live exposed Subject can absorb secured Material")
	_expect(is_equal_approx(environment_round.material_secured[1], 15.0),
			"the Environment Round records Material actually absorbed")
	environment_round.survival_seconds[1] = 30.0
	environment_round.survival_seconds[2] = 30.0
	var ordered: Array = environment_round.get_ordered_placements()
	environment_round.end_round()
	_expect(ordered == [1, 2],
			"Material secured differentiates Subjects with equal survival time")


func _test_breakable_supply(
	environment_round: EnvironmentRound,
	fixture: Node3D,
) -> void:
	var housings: Array[Node] = environment_round.find_children(
			"*", "BreakableMaterialHousing", true, false)
	_expect(not housings.is_empty(),
			"damage-focused Verbs have authored breakable Material housings")
	if housings.is_empty():
		return
	var material_before: int = _material_count(fixture)
	var housing: BreakableMaterialHousing = housings[0]
	housing.take_hit(housing.durability, null)
	_expect(housing.is_broken, "a sufficient Impact breaks the hero-prop housing")
	_expect(_material_count(fixture) == material_before + 1,
			"a broken housing releases its contained Material")


func _material_count(root: Node) -> int:
	return root.find_children("*", "MaterialResource", true, false).size()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
