extends Node

class ScenarioRound:
	extends Node
	signal round_finished(ordered_player_ids: Array)
	var tied_scoring: bool = false

	func end_round() -> void:
		var ordered: Array = LobbyManager.lobby_players.duplicate()
		ordered.sort()
		if tied_scoring:
			for subject_id: int in ordered:
				ScoreManager.add_points(subject_id, 10,
						RoundManager.current_round_type, "scale_scenario_tie")
		else:
			ScoreManager.award_placements(RoundManager.current_round_type, ordered)
		round_finished.emit(ordered)


class CapacitySubject:
	extends Node3D
	var is_destabilised: bool = false
	var is_overdrive: bool = false
	var stability: float = 100.0

	func enter_overdrive(_partner_id = null) -> void:
		is_overdrive = true

	func exit_overdrive(_partner_id = -1) -> void:
		is_overdrive = false

	func restabilise() -> void:
		is_destabilised = false
		stability = 100.0


const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const COMPOUND_SCENE: PackedScene = preload(
		"res://scenes/environment/Compound.tscn")

var _mode: String = "lifecycle"
var _subject_count: int = 8
var _scenario_seed: int = 24680
var _collapse_expected: bool = false
var _failures: Array[String] = []
var _phases: Array[String] = []
var _pairings: Array = []
var _tube_assignments: Array = []
var _expression_spend_observed: bool = false
var _impact_destabilisation_observed: bool = false
var _winner_id: int = -1


func _ready() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	_mode = _string_argument(arguments, "--mode", _mode)
	_subject_count = _int_argument(arguments, "--subject-count", _subject_count)
	_scenario_seed = _int_argument(arguments, "--seed", _scenario_seed)
	_collapse_expected = "--collapse" in arguments
	call_deferred("_run")


func _run() -> void:
	if _mode == "capacity":
		await _run_capacity_scenario()
	else:
		await _run_lifecycle_scenario()
	if not _failures.is_empty():
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _run_lifecycle_scenario() -> void:
	_expect(_subject_count >= 2 and _subject_count <= 9,
			"canonical lifecycle scenarios require 2–9 unique Verbs")
	TrialCoordinator.phase_changed.connect(_on_phase_changed)
	TrialCoordinator.experiment_requested.connect(_on_experiment_requested)
	TrialCoordinator.trial_completed.connect(
			func(subject_id: int) -> void: _winner_id = subject_id)
	_prepare_lifecycle_roster()
	_expect(TrialCoordinator.start_trial(_scenario_seed, true, 0.01),
			"the seeded Trial starts")
	for _frame: int in 720:
		if TrialCoordinator.current_phase == TrialCoordinator.Phase.COMPLETE:
			break
		await get_tree().process_frame
	_expect(TrialCoordinator.current_phase == TrialCoordinator.Phase.COMPLETE,
			"the seeded Trial reaches a final result")
	_expect(RoundManager.round_history.size() == 3,
			"the Trial runs exactly three Protocols")
	_expect(_phases.count("Pair Draft") == 3
			and _phases.count("Laboratory Entry") == 3
			and _phases.count("Experiment") == 3
			and _phases.count("Recall") == 3
			and _phases.count("Result Announcement") == 3,
			"every Round follows the canonical lifecycle")
	_expect(_expression_spend_observed,
			"the scenario observes non-Destabilising Expression spend")
	_expect(_impact_destabilisation_observed,
			"the scenario observes Impact Destabilisation")
	_expect(_pairings.size() == 3 and _tube_assignments.size() == 3,
			"every Pair Draft records Pair and Dispensing Line state")
	if _subject_count % 2 == 1:
		var has_self_chain: bool = false
		for round_pairings: Array in _pairings:
			for pairing: Array in round_pairings:
				if pairing[0] == pairing[1]:
					has_self_chain = true
		_expect(has_self_chain, "the odd roster receives a Self-Chain")
	_expect((_collapse_expected and "Collapse" in _phases)
			or (not _collapse_expected and "Collapse" not in _phases),
			"the configured sole-winner or tied-First-Place path is used")
	var digest := {
		"mode": _mode,
		"subject_count": _subject_count,
		"seed": _scenario_seed,
		"protocol_order": RoundManager.round_history.duplicate(),
		"phases": _phases,
		"pairings": _pairings,
		"tube_assignments": _tube_assignments,
		"scores": ScoreManager.player_points.duplicate(true),
		"winner_id": _winner_id,
		"collapse": _collapse_expected,
		"expression_spend": _expression_spend_observed,
		"impact_destabilisation": _impact_destabilisation_observed,
	}
	_report(digest)


func _prepare_lifecycle_roster() -> void:
	TrialCoordinator.reset()
	LobbyManager.reset()
	VerbChainManager.reset()
	ScoreManager.reset()
	for index: int in _subject_count:
		var subject_id: int = index + 1
		LobbyManager.join_lobby(subject_id)
		ScoreManager.register_player(subject_id)
		var subject := PLAYER_SCENE.instantiate() as Node3D
		subject.name = "ScaleSubject%d" % subject_id
		subject.set_multiplayer_authority(subject_id)
		subject.set("accepts_local_input", false)
		add_child(subject)
	LobbyManager.open_verb_selection()
	for index: int in _subject_count:
		var verb: Enums.VerbType = Enums.VerbType.values()[index + 1]
		_expect(LobbyManager.select_verb_for_local_playtest(index + 1, verb),
				"Subject %d claims a unique Verb" % (index + 1))
		var subject: Node = SubjectRoster.body_of(index + 1)
		if subject != null:
			subject.set_character_identity(verb)


func _on_phase_changed(phase: TrialCoordinator.Phase, _round_index: int,
		_protocol: ExperimentProtocol) -> void:
	_phases.append(TrialCoordinator.phase_name(phase))
	if phase == TrialCoordinator.Phase.LABORATORY_ENTRY:
		TrialCoordinator.call_deferred("complete_laboratory_entry")
	elif phase == TrialCoordinator.Phase.RECALL:
		TrialCoordinator.call_deferred("complete_recall")
	elif phase == TrialCoordinator.Phase.COLLAPSE:
		for subject_id: int in range(2, _subject_count + 1):
			CollapseManager.eliminate_player(subject_id)


func _on_experiment_requested(_round_index: int,
		_protocol: ExperimentProtocol) -> void:
	var round_pairings: Array = []
	for chain: Dictionary in VerbChainManager.verb_chains.values():
		round_pairings.append([chain.player_a_id, chain.player_b_id])
	round_pairings.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	_pairings.append(round_pairings)
	var tubes: Array = []
	for subject_id: int in LobbyManager.lobby_players:
		tubes.append([subject_id, LobbyManager.get_dispensing_line_tube(subject_id)])
	_tube_assignments.append(tubes)
	if RoundManager.current_round_index == 1:
		var expressing_subject: Node = SubjectRoster.body_of(1)
		var impacted_subject: Node = SubjectRoster.body_of(2)
		var starting_stability: float = expressing_subject.stability
		expressing_subject.express_verb()
		_expression_spend_observed = expressing_subject.stability < starting_stability \
				and expressing_subject.stability >= 1.0
		impacted_subject.apply_impact(impacted_subject.BASELINE_STABILITY, null, false)
		_impact_destabilisation_observed = impacted_subject.is_destabilised
	var controller := ScenarioRound.new()
	controller.tied_scoring = _collapse_expected
	add_child(controller)
	TrialCoordinator.set_active_round_controller(controller)


func _run_capacity_scenario() -> void:
	_expect(_subject_count in [12, 24],
			"capacity scenarios cover the authored 12- and 24-Subject cases")
	FacilityStateLedger.reset_for_trial(_scenario_seed)
	CollapseManager.reset()
	var compound := COMPOUND_SCENE.instantiate() as Compound
	add_child(compound)
	var subjects: Array[Node3D] = []
	var subject_ids: Array[int] = []
	for index: int in _subject_count:
		var subject := CapacitySubject.new()
		var subject_id: int = index + 1
		subject.name = "CapacitySubject%d" % subject_id
		subject.set_multiplayer_authority(subject_id)
		subject.add_to_group("players")
		add_child(subject)
		subjects.append(subject)
		subject_ids.append(subject_id)
	CollapseManager.trigger_collapse(subject_ids)
	_expect(CollapseManager.entry_assignments.size() == _subject_count,
			"every Subject receives one seeded Collapse entry")
	_expect(compound.begin_collapse(CollapseManager.entry_assignments,
			subjects, subject_ids), "the Compound accepts the capacity plan")
	var used_sockets: Dictionary = {}
	var positions: Array[Vector3] = []
	for subject_id: int in subject_ids:
		var assignment: Dictionary = CollapseManager.entry_assignments[subject_id]
		var socket_key: String = "%s:%d" % [
			assignment.laboratory_id, assignment.socket_index]
		used_sockets[socket_key] = true
		positions.append(compound.get_collapse_entry_transform(
				assignment.laboratory_id, assignment.socket_index).origin)
	_expect(used_sockets.size() == _subject_count,
			"capacity entry sockets never duplicate a Subject")
	var minimum_spacing: float = INF
	for first_index: int in positions.size():
		for second_index: int in range(first_index + 1, positions.size()):
			minimum_spacing = minf(minimum_spacing,
					positions[first_index].distance_to(positions[second_index]))
	_expect(minimum_spacing > 0.0,
			"capacity entry sockets have non-zero physical separation")
	var snapshot: Dictionary = CollapseManager.snapshot()
	CollapseManager.reset()
	CollapseManager.apply_replicated_state(snapshot)
	_expect(CollapseManager.snapshot() == snapshot,
			"the authoritative Collapse snapshot round-trips without divergence")
	_report({
		"mode": _mode,
		"subject_count": _subject_count,
		"seed": _scenario_seed,
		"entry_assignments": snapshot.entry_assignments,
		"failure_order": snapshot.failure_order,
		"unique_socket_count": used_sockets.size(),
		"minimum_socket_spacing_metres": snappedf(minimum_spacing, 0.001),
		"snapshot_round_trip": true,
	})


func _report(digest: Dictionary) -> void:
	if not _failures.is_empty():
		return
	print("MULTIPLAYER_SCALE_SCENARIO %s" % JSON.stringify(digest))
	get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _string_argument(arguments: PackedStringArray, key: String,
		fallback: String) -> String:
	for argument: String in arguments:
		if argument.begins_with(key + "="):
			return argument.trim_prefix(key + "=")
	return fallback


func _int_argument(arguments: PackedStringArray, key: String,
		fallback: int) -> int:
	return _string_argument(arguments, key, str(fallback)).to_int()
