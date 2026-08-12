extends Node

const COMPOUND_SCENE: PackedScene = preload(
		"res://scenes/environment/Compound.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	FacilityStateLedger.laboratories.clear()
	var compound := COMPOUND_SCENE.instantiate() as Compound
	add_child(compound)
	_test_four_layers_and_compound_application(compound)
	_test_route_and_threshold_guards()
	_test_overlay_guards()
	_test_seed_reproduction_and_round_retention()
	compound.queue_free()
	if _failures.is_empty():
		print("Facility state ledger tests passed.")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_four_layers_and_compound_application(compound: Compound) -> void:
	FacilityStateLedger.reset_for_trial(1907)
	_expect(FacilityStateLedger.set_round_stage(
			&"AppliedAttrition", &"questionable", &"round_two_stage"),
			"Round stage accepts a named authored transition")
	_expect(FacilityStateLedger.set_experiment_lifecycle(
			&"AppliedAttrition", &"live", &"sustained_exposure_live"),
			"Experiment lifecycle accepts a named authored transition")
	_expect(FacilityStateLedger.set_active_objective(
			&"AppliedAttrition", &"Reach Material", &"material_objective"),
			"the active Objective is recorded")
	_expect(FacilityStateLedger.set_structural_cosmetic_state(
			&"AppliedAttrition", &"TestFloor", &"scorched", &"floor_scorched"),
			"structural surfaces accept cosmetic state")
	_expect(FacilityStateLedger.transition_prop(&"AppliedAttrition",
			&"ElevatedDispensingArmature", &"stressed", &"armature_stressed"),
			"selected props accept authored threshold transitions")
	var laboratory: Dictionary = FacilityStateLedger.laboratories.AppliedAttrition
	_expect(laboratory.round_stage == &"questionable",
			"Round stage is independent")
	_expect(laboratory.experiment_lifecycle == &"live",
			"Experiment lifecycle is independent")
	_expect(laboratory.persistent_state.ElevatedDispensingArmature == &"stressed",
			"persistent prop state is retained")
	_expect(compound.get_laboratory(&"AppliedAttrition").get_meta(
			"TestFloor_cosmetic_state") == &"scorched",
			"Compound consumes cosmetic ledger transitions")
	_expect(not FacilityStateLedger.transition_prop(&"AppliedAttrition",
			&"ElevatedDispensingArmature", &"pristine", &"repair_armature"),
			"persistent thresholds cannot move backwards")
	_expect(FacilityStateLedger.transition_prop(&"CompetitiveStress",
			&"ReinforcedImpactCrucible", &"destroyed", &"crucible_destroyed"),
			"an authored prop transition may explicitly change collision")
	var crucible: Node = compound.get_laboratory(
			&"CompetitiveStress").get_node("ReinforcedImpactCrucible")
	_expect(_all_kit_collision_matches(crucible, false),
			"Compound applies the selected prop's explicit collision state")


func _test_route_and_threshold_guards() -> void:
	_expect(FacilityStateLedger.register_laboratory(
			&"RouteTest", [&"west", &"east"]),
			"a Laboratory registers authored routes")
	var thresholds: Array[StringName] = [&"pristine", &"destroyed"]
	_expect(FacilityStateLedger.register_prop(&"RouteTest", &"WestGate",
			thresholds, {}, {&"destroyed": [&"west"]}),
			"a selected prop registers its route effect")
	_expect(FacilityStateLedger.register_prop(&"RouteTest", &"EastGate",
			thresholds, {}, {&"destroyed": [&"east"]}),
			"a second selected prop registers its route effect")
	_expect(FacilityStateLedger.transition_prop(
			&"RouteTest", &"WestGate", &"destroyed", &"west_failure"),
			"a threshold may close one redundant route")
	_expect(not FacilityStateLedger.transition_prop(
			&"RouteTest", &"EastGate", &"destroyed", &"east_failure"),
			"a threshold cannot remove the last valid route")


func _test_overlay_guards() -> void:
	_expect(not FacilityStateLedger.activate_event_overlay(&"AppliedAttrition",
			&"MaterialSurge", [&"power"], {}, [], &"repair_surge", true),
			"event overlays cannot repair persistent state")
	_expect(not FacilityStateLedger.activate_event_overlay(&"AppliedAttrition",
			&"Blackout", [&"power"], {}, [&"Reach Material"], &"blackout"),
			"event overlays cannot invalidate the active Objective")
	_expect(FacilityStateLedger.activate_event_overlay(&"AppliedAttrition",
			&"ContainmentPulse", [&"power"], {
				&"ElevatedDispensingArmature": [&"stressed"],
			}, [], &"containment_pulse"),
			"a compatible event overlay composes over persistent state")
	_expect(not FacilityStateLedger.activate_event_overlay(&"AppliedAttrition",
			&"PowerDip", [&"power"], {}, [], &"power_dip"),
			"event overlays cannot write conflicting channels")
	_expect(not FacilityStateLedger.activate_event_overlay(&"AppliedAttrition",
			&"PristineOnly", [&"machinery"], {
				&"ElevatedDispensingArmature": [&"pristine"],
			}, [], &"pristine_only"),
			"event overlays cannot contradict the persistent threshold")
	_expect(not FacilityStateLedger.transition_prop(&"AppliedAttrition",
			&"ElevatedDispensingArmature", &"destroyed", &"armature_destroyed"),
			"persistent transitions cannot contradict an active overlay")
	_expect(FacilityStateLedger.deactivate_event_overlay(
			&"AppliedAttrition", &"ContainmentPulse", &"pulse_complete"),
			"an event overlay can end without repairing persistent state")


func _test_seed_reproduction_and_round_retention() -> void:
	var first_tokens: Array[int] = []
	for entry: Dictionary in FacilityStateLedger.transition_history:
		first_tokens.append(entry.seed_token)
	var retained_threshold: StringName = FacilityStateLedger.current_prop_threshold(
			&"AppliedAttrition", &"ElevatedDispensingArmature")
	FacilityStateLedger.set_round_stage(
			&"CompetitiveStress", &"containment_failure", &"round_three_stage")
	_expect(FacilityStateLedger.current_prop_threshold(&"AppliedAttrition",
			&"ElevatedDispensingArmature") == retained_threshold,
			"entering another Laboratory retains prior persistent state")
	FacilityStateLedger.reset_for_trial(1907)
	FacilityStateLedger.set_round_stage(
			&"AppliedAttrition", &"questionable", &"round_two_stage")
	FacilityStateLedger.set_experiment_lifecycle(
			&"AppliedAttrition", &"live", &"sustained_exposure_live")
	FacilityStateLedger.set_active_objective(
			&"AppliedAttrition", &"Reach Material", &"material_objective")
	FacilityStateLedger.set_structural_cosmetic_state(
			&"AppliedAttrition", &"TestFloor", &"scorched", &"floor_scorched")
	FacilityStateLedger.transition_prop(&"AppliedAttrition",
			&"ElevatedDispensingArmature", &"stressed", &"armature_stressed")
	var reproduced_tokens: Array[int] = []
	for entry: Dictionary in FacilityStateLedger.transition_history:
		reproduced_tokens.append(entry.seed_token)
	_expect(reproduced_tokens == first_tokens.slice(0, reproduced_tokens.size()),
			"the same seed and named transitions reproduce seeded tokens")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _all_kit_collision_matches(node: Node, expected: bool) -> bool:
	if node is EnvironmentKitPiece \
			and (node as EnvironmentKitPiece).collision_enabled != expected:
		return false
	for child: Node in node.get_children():
		if not _all_kit_collision_matches(child, expected):
			return false
	return true
