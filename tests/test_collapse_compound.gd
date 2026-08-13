extends Node

class FakeSubject:
	extends Node3D
	signal destabilised(subject: Node, source: Node)
	var is_overdrive: bool = false
	var restabilise_calls: int = 0

	func enter_overdrive(_partner_id = null) -> void:
		is_overdrive = true

	func exit_overdrive(_partner_id = -1) -> void:
		is_overdrive = false

	func restabilise() -> void:
		restabilise_calls += 1


const COMPOUND_SCENE: PackedScene = preload(
		"res://scenes/environment/Compound.tscn")

var _failures: Array[String] = []
var _subjects: Array[Node3D] = []
var _winner_id: int = -1


func _ready() -> void:
	var compound := COMPOUND_SCENE.instantiate() as Compound
	add_child(compound)
	for player_id: int in 8:
		var subject := FakeSubject.new()
		subject.name = "CollapseSubject%d" % (player_id + 1)
		subject.set_multiplayer_authority(player_id + 1)
		subject.add_to_group("players")
		add_child(subject)
		_subjects.append(subject)
	var spectator := FakeSubject.new()
	spectator.name = "Spectator"
	spectator.set_multiplayer_authority(99)
	spectator.add_to_group("players")
	add_child(spectator)
	_subjects.append(spectator)

	CollapseManager.collapse_stage_changed.connect(
			func(stage: CollapseManager.Stage, laboratory_id: StringName) -> void:
				CollapseComposition.apply_stage(compound, stage, laboratory_id))
	CollapseManager.ultimate_winner_decided.connect(
			func(player_id: int) -> void: _winner_id = player_id)

	FacilityStateLedger.reset_for_trial(20260812)
	CollapseManager.trigger_collapse([1, 2, 3, 4, 5, 6, 7, 8])
	var first_plan: Dictionary = CollapseManager.entry_assignments.duplicate(true)
	_test_entry_plan(first_plan)
	_expect(compound.get_node("AssignmentDeck").get_meta(
			"access_sealed", false),
			"Collapse seals the Assignment Deck")
	_expect(_subjects[0].process_mode == Node.PROCESS_MODE_DISABLED,
			"eligible Subjects receive a protected orientation window")
	_expect(not _subjects[8].visible,
			"Subjects outside tied First Place do not enter the Collapse")

	CollapseManager.reset()
	compound.reset_collapse(_subjects)
	FacilityStateLedger.reset_for_trial(20260812)
	CollapseManager.trigger_collapse([1, 2, 3, 4, 5, 6, 7, 8])
	_expect(CollapseManager.entry_assignments == first_plan,
			"identical seeds reproduce Collapse entry sockets")

	CollapseManager.advance_timeline(CollapseManager.ORIENTATION_SECONDS + 0.1)
	_expect(compound.get_node("PerimeterMaintenanceRoute").get_meta(
			"collapse_open", false),
			"the dependable perimeter connection opens after orientation")
	_expect(compound.get_node("SeparatorSpines").get_meta(
			"collapse_open", false),
			"separator routes open after orientation")
	var first_spine := compound.get_node(
			"SeparatorSpines").get_child(0) as EnvironmentKitPiece
	_expect(not first_spine.collision_enabled,
			"open separator routes remove their gameplay blockage")
	_expect(not compound.get_node("CentralCore").get_meta(
			"collapse_shortcuts_open", false),
			"dangerous Core shortcuts remain closed initially")
	_expect(_subjects[0].process_mode == Node.PROCESS_MODE_INHERIT,
			"Subjects regain movement when safe routes open")

	CollapseManager.advance_timeline(
			CollapseManager.CORE_SHORTCUT_SECONDS
			- CollapseManager.ORIENTATION_SECONDS)
	_expect(compound.get_node("CentralCore").get_meta(
			"collapse_shortcuts_open", false),
			"Core shortcuts open at the authored later stage")

	CollapseManager.advance_timeline(
			CollapseManager.FIRST_FAILURE_TELEGRAPH_SECONDS
			- CollapseManager.CORE_SHORTCUT_SECONDS)
	var failing_laboratory: StringName = CollapseManager.failure_order[0]
	var hazard := compound.get_node(
			"CollapseHazards/%sFailure" % failing_laboratory) as Area3D
	_expect(hazard.get_meta("telegraphed", false) and not hazard.monitoring \
			and hazard.get_node("WarningVisual").visible,
			"a non-lethal warning precedes each authored failure")
	_expect(FacilityStateLedger.laboratories[
			failing_laboratory].round_stage == &"questionable",
			"failure telegraphs are recorded by the facility ledger")

	CollapseManager.advance_timeline(CollapseManager.FAILURE_WARNING_SECONDS)
	_expect(hazard.monitoring and hazard.get_meta("active", false),
			"the warned Laboratory failure activates its hazard")
	_expect(FacilityStateLedger.laboratories[
			failing_laboratory].round_stage == &"containment_failure",
			"active failure state is server-authoritative ledger state")
	_expect(_available_route_count(failing_laboratory) >= 2,
			"authored failure retains at least two exits from its Laboratory")

	# A client composes the same facility from replicated state alone, without
	# having observed any stage signal.
	compound.reset_collapse(_subjects)
	_expect(not hazard.get_meta("active", false),
			"resetting the Compound clears an active failure hazard")
	CollapseComposition.apply_current_state(compound)
	_expect(compound.get_node("AssignmentDeck").get_meta("access_sealed", false)
			and compound.get_node("PerimeterMaintenanceRoute").get_meta(
				"collapse_open", false)
			and compound.get_node("CentralCore").get_meta(
				"collapse_shortcuts_open", false),
			"catching up to replicated state composes every stage already reached")
	_expect(hazard.monitoring and hazard.get_meta("active", false),
			"catching up re-applies authored failures the Collapse has run")
	CollapseComposition.apply_current_state(compound)
	_expect(hazard.monitoring and _available_route_count(failing_laboratory) >= 2,
			"composing the same state twice changes nothing")

	CollapseManager.reset()
	compound.reset_collapse(_subjects)
	FacilityStateLedger.reset_for_trial(20260812)
	CollapseManager.trigger_collapse([1, 2])
	CollapseManager.eliminate_players([
		{"player_id": 2, "survival_seconds": 25.0},
		{"player_id": 1, "survival_seconds": 25.0},
	])
	_expect(_winner_id == 1,
			"simultaneous final Eliminations use the stable Subject-id tie rule")
	_expect(CollapseManager.surviving_players == [1],
			"the deterministic tie winner remains the final survivor")
	_expect(not _subjects[1].visible \
			and _subjects[1].process_mode == Node.PROCESS_MODE_DISABLED,
			"Collapse Elimination removes a Subject from active play")
	_expect((_subjects[0] as FakeSubject).restabilise_calls == 0,
			"Collapse resolution never Recalls or Restabilises a Subject")

	CollapseManager.reset()
	FacilityStateLedger.reset_for_trial(0)
	if _failures.is_empty():
		print("Collapse Compound tests passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _test_entry_plan(plan: Dictionary) -> void:
	_expect(plan.size() == 8, "every eligible Subject receives one entry socket")
	var occupied: Dictionary = {}
	var laboratory_counts: Dictionary = {}
	for assignment: Dictionary in plan.values():
		var socket_key: String = "%s:%d" % [
			assignment.laboratory_id, assignment.socket_index]
		_expect(not occupied.has(socket_key),
				"Collapse entry sockets are unique")
		occupied[socket_key] = true
		laboratory_counts[assignment.laboratory_id] = \
				laboratory_counts.get(assignment.laboratory_id, 0) + 1
		_expect(is_equal_approx(assignment.hazard_exposure, 1.0),
				"entry sockets expose every Subject to the same initial hazard")
		_expect(assignment.exit_count >= 2,
				"entry sockets never create an initial dead end")
	var counts: Array = laboratory_counts.values()
	counts.sort()
	_expect(counts.size() == 3 and counts[-1] - counts[0] <= 1,
			"seeded entries distribute Subjects comparably across Laboratories")


func _available_route_count(laboratory_id: StringName) -> int:
	var laboratory: Dictionary = FacilityStateLedger.laboratories[laboratory_id]
	var routes: Dictionary = laboratory.routes.duplicate()
	for prop: Dictionary in laboratory.props.values():
		var threshold: StringName = prop.thresholds[prop.threshold_index]
		for route_id: StringName in prop.blocked_routes_by_threshold.get(
				threshold, []):
			routes.erase(route_id)
	return routes.size()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
