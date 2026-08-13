extends Node
## Focused suite for the shared Experiment lifecycle contract.
##
## Every Protocol controller inherits ExperimentController, so these
## assertions cover Sustained Exposure, Competitive Stress and Adaptive
## Containment at once.

class ProbeController:
	extends ExperimentController

	var performance: Dictionary = {}
	var award_order: Array[String] = []
	var eliminations: Array[int] = []

	func _default_protocol() -> ExperimentProtocol:
		return preload("res://resources/protocols/competitive_stress.tres")

	func get_performance(player_id: int) -> float:
		return performance.get(player_id, 0.0)

	func _on_subject_eliminated(player_id: int, _subject: Node,
			_source: Node) -> void:
		eliminations.append(player_id)


const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_elimination_is_canonical()
	await _test_authored_controller_keeps_subjects_down()
	_test_severance_is_guarded_during_collapse()
	_test_award_precedes_announcement()
	_test_placement_ordering()

	if _failures.is_empty():
		print("Experiment controller tests passed.")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	get_tree().quit(1)


## CONTEXT.md: a Destabilised Subject is Eliminated from that Experiment and
## automatically Recalled — it returns in the next Round, not mid-Experiment.
func _test_elimination_is_canonical() -> void:
	var fixture: Dictionary = _fixture([21, 22])
	var subject: Node = fixture.subjects[21]
	var controller: ProbeController = fixture.controller

	subject.apply_impact(subject.BASELINE_STABILITY, null, false)
	_expect(subject.is_destabilised,
			"an Impact reducing Stability to zero Destabilises the Subject")
	_expect(controller.eliminations == [21],
			"the controller reports the Elimination exactly once")
	_expect(controller.is_eliminated(21),
			"an Eliminated Subject is recorded for the rest of the Experiment")

	await get_tree().process_frame
	await get_tree().process_frame
	_expect(subject.is_destabilised,
			"a Destabilised Subject stays down for the rest of the Experiment")

	subject.apply_impact(10.0, null, false)
	_expect(controller.eliminations == [21],
			"a further Impact on a Destabilised Subject Eliminates it only once")

	SubjectRoster.recall_all()
	_expect(not subject.is_destabilised
			and is_equal_approx(subject.stability, subject.BASELINE_STABILITY),
			"Recall restores every Subject to baseline Stability")
	_teardown(fixture)


## The same policy holds for an authored Protocol controller, which inherits
## it rather than implementing its own.
func _test_authored_controller_keeps_subjects_down() -> void:
	var fixture: Dictionary = _fixture([71, 72], false)
	var controller: Node = preload("res://scripts/rounds/PVPRound.gd").new()
	fixture.root.add_child(controller)
	var eliminated: Node = fixture.subjects[71]
	var attacker: Node = fixture.subjects[72]

	eliminated.apply_impact(eliminated.BASELINE_STABILITY, attacker, false)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(eliminated.is_destabilised,
			"Competitive Stress leaves a Destabilised Subject out of the Experiment")
	_expect(ScoreManager.get_round_score(1, 72) > 0,
			"the Subject that landed the Impact still takes the knockout bonus")
	_teardown(fixture)


## Severance costs the surviving Partner Stability during an Experiment, and
## the Collapse has no Pairs left to Sever.
func _test_severance_is_guarded_during_collapse() -> void:
	var fixture: Dictionary = _fixture([31, 32])
	var survivor: Node = fixture.subjects[32]
	VerbChainManager.establish_verb_chain(31, 32)
	var expected: float = survivor.BASELINE_STABILITY - survivor.severance_loss

	fixture.subjects[31].apply_impact(survivor.BASELINE_STABILITY, null, false)
	_expect(is_equal_approx(survivor.stability, expected),
			"losing a Partner costs the survivor exactly its Severance Loss")
	_teardown(fixture)

	var collapse_fixture: Dictionary = _fixture([41, 42])
	var collapse_survivor: Node = collapse_fixture.subjects[42]
	VerbChainManager.establish_verb_chain(41, 42)
	CollapseManager.trigger_collapse([41, 42])
	collapse_fixture.subjects[41].apply_impact(
			collapse_survivor.BASELINE_STABILITY, null, false)
	_expect(is_equal_approx(collapse_survivor.stability,
			collapse_survivor.BASELINE_STABILITY),
			"the Collapse dissolves every Pair, so no Severance Loss applies")
	CollapseManager.reset()
	_teardown(collapse_fixture)


## TrialCoordinator reads the Trial Ranking as soon as round_finished lands,
## so placements must already be scored when it is emitted.
func _test_award_precedes_announcement() -> void:
	var fixture: Dictionary = _fixture([51, 52])
	var controller: ProbeController = fixture.controller
	controller.performance = {51: 10.0, 52: 4.0}
	var scored_on_announcement: Array[bool] = []
	controller.round_finished.connect(func(_ordered: Array) -> void:
		scored_on_announcement.append(ScoreManager.get_round_score(1, 51) > 0.0))

	controller.end_round()
	_expect(scored_on_announcement == [true],
			"placements reach ScoreManager before round_finished is emitted")

	controller.end_round()
	_expect(ScoreManager.get_round_score(1, 51) > 0.0
			and scored_on_announcement.size() == 1,
			"a second end_round cannot pay the Experiment twice")
	_teardown(fixture)


func _test_placement_ordering() -> void:
	var fixture: Dictionary = _fixture([61, 62, 63])
	var controller: ProbeController = fixture.controller
	controller.performance = {61: 5.0, 62: 9.0, 63: 5.0}
	_expect(controller.get_ordered_placements() == [62, 61, 63],
			"placements rank by performance, and exact ties by Subject id")
	_teardown(fixture)


func _fixture(player_ids: Array, with_probe: bool = true) -> Dictionary:
	VerbChainManager.reset()
	ScoreManager.reset()
	RoundManager.current_round_index = 1
	RoundManager.current_round_type = "PVP"
	var root := Node3D.new()
	root.name = "ExperimentFixture"
	add_child(root)
	var subjects: Dictionary = {}
	for player_id: int in player_ids:
		VerbChainManager.register_player(player_id, Enums.VerbType.BURN)
		ScoreManager.register_player(player_id)
		var subject: Node = PLAYER_SCENE.instantiate()
		subject.name = "Subject%d" % player_id
		subject.set_multiplayer_authority(player_id)
		subject.accepts_local_input = false
		subject.stabilisation_rate = 0.0
		subject.material_shed_probability = 0.0
		subject.destabilise_shed_probability = 0.0
		root.add_child(subject)
		subjects[player_id] = subject
	var controller: ProbeController = null
	if with_probe:
		controller = ProbeController.new()
		root.add_child(controller)
	return {"root": root, "controller": controller, "subjects": subjects}


func _teardown(fixture: Dictionary) -> void:
	fixture.root.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
