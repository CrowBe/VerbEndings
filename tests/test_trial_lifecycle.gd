extends Node

class FakeRound:
	extends Node
	signal round_finished(ordered_player_ids: Array)
	var tied_scoring: bool = false
	var end_call_count: int = 0

	func end_round() -> void:
		end_call_count += 1
		var ordered: Array = VerbChainManager.active_players.keys()
		ordered.sort()
		if tied_scoring:
			for player_id: int in ordered:
				ScoreManager.add_points(player_id, 10,
						RoundManager.current_round_type, "test_tie")
		else:
			ScoreManager.award_placements(RoundManager.current_round_type, ordered)
		round_finished.emit(ordered)

var _failures: Array[String] = []
var _phases: Array[TrialCoordinator.Phase] = []
var _round_protocol_ids: Array[StringName] = []
var _controllers: Array[FakeRound] = []
var _tied_scoring: bool = false
var _winner_id: int = -1
var _observed_self_chain: bool = false
var _observed_authored_condition: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	TrialCoordinator.phase_changed.connect(_on_phase_changed)
	TrialCoordinator.experiment_requested.connect(_on_experiment_requested)
	TrialCoordinator.trial_completed.connect(
			func(player_id: int) -> void: _winner_id = player_id)
	_prepare_roster(3)
	_expect(TrialCoordinator.start_trial(24680, true, 0.01),
			"a host can start a fully enrolled Trial")
	await _wait_for_phase(TrialCoordinator.Phase.COMPLETE)
	_expect(_winner_id == 1, "the sole First Place Subject wins after Round Three")
	_expect(RoundManager.round_history.size() == 3,
			"the coordinator plays exactly three Protocols")
	_expect(_round_protocol_ids.size() == 3 \
			and _round_protocol_ids[0] != _round_protocol_ids[1] \
			and _round_protocol_ids[1] != _round_protocol_ids[2] \
			and _round_protocol_ids[0] != _round_protocol_ids[2],
			"the seeded Trial plays every authored Protocol once")
	_expect(_phases.count(TrialCoordinator.Phase.VERB_SELECTION) == 1,
			"Verb Selection occurs once")
	_expect(_phases.count(TrialCoordinator.Phase.PAIR_DRAFT) == 3,
			"Pair Draft occurs before every Round")
	_expect(_observed_self_chain,
			"an odd roster receives a Self-Chain during the lifecycle")
	_expect(_observed_authored_condition,
			"an authored completion condition can end an Experiment before its timer")
	_expect(_phases.count(TrialCoordinator.Phase.EXPERIMENT) == 3 \
			and _phases.count(TrialCoordinator.Phase.RECALL) == 3 \
			and _phases.count(TrialCoordinator.Phase.RESULT_ANNOUNCEMENT) == 3,
			"every Experiment has one Recall and Result Announcement")
	for controller: FakeRound in _controllers:
		_expect(controller.end_call_count == 1,
				"every Round controller emits exactly one result")
	_expect(ScoreManager.round_scores.size() == 3,
			"Round Scores remain distinct while Trial Scores accumulate")

	_phases.clear()
	_round_protocol_ids.clear()
	_controllers.clear()
	_observed_self_chain = false
	_winner_id = -1
	_tied_scoring = true
	_prepare_roster(3)
	_expect(TrialCoordinator.start_trial(24680, true, 0.01),
			"a Trial can replay after teardown")
	await _wait_for_phase(TrialCoordinator.Phase.COLLAPSE)
	_expect(CollapseManager.surviving_players == [1, 2, 3],
			"a tied First Place populates the Collapse deterministically")
	_expect(VerbChainManager.verb_chains.is_empty(),
			"scheduled Pair dissolution leaves no chains in the Collapse")
	CollapseManager.eliminate_player(3)
	CollapseManager.eliminate_player(2)
	await _wait_for_phase(TrialCoordinator.Phase.COMPLETE)
	_expect(_winner_id == 1, "the last Collapse Subject becomes Trial Winner")

	TrialCoordinator.reset()
	LobbyManager.reset()
	VerbChainManager.reset()
	ScoreManager.reset()
	if _failures.is_empty():
		print("Trial lifecycle tests passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _prepare_roster(subject_count: int) -> void:
	TrialCoordinator.reset()
	LobbyManager.reset()
	VerbChainManager.reset()
	ScoreManager.reset()
	for index: int in subject_count:
		var player_id: int = index + 1
		LobbyManager.join_lobby(player_id)
		ScoreManager.register_player(player_id)
	LobbyManager.open_verb_selection()
	for index: int in subject_count:
		LobbyManager.select_verb(index + 1, Enums.VerbType.values()[index + 1])


func _on_phase_changed(phase: TrialCoordinator.Phase, _round_index: int,
		_protocol: ExperimentProtocol) -> void:
	_phases.append(phase)
	if phase == TrialCoordinator.Phase.LABORATORY_ENTRY:
		TrialCoordinator.call_deferred("complete_laboratory_entry")
	elif phase == TrialCoordinator.Phase.RECALL:
		TrialCoordinator.call_deferred("complete_recall")


func _on_experiment_requested(_round_index: int, protocol: ExperimentProtocol) -> void:
	_round_protocol_ids.append(protocol.protocol_id)
	for chain: Dictionary in VerbChainManager.verb_chains.values():
		if chain.is_self_chain:
			_observed_self_chain = true
	var controller := FakeRound.new()
	controller.tied_scoring = _tied_scoring
	add_child(controller)
	_controllers.append(controller)
	TrialCoordinator.set_active_round_controller(controller)
	if not _observed_authored_condition:
		if protocol.completion_mode == "TIMER_OR_ONE_ELIGIBLE":
			_observed_authored_condition = TrialCoordinator.notify_completion_condition(
					"one_eligible_subject")
		elif protocol.completion_mode == "TIMER_OR_ALL_OBJECTIVES":
			_observed_authored_condition = TrialCoordinator.notify_completion_condition(
					"all_objectives")


func _wait_for_phase(target: TrialCoordinator.Phase) -> void:
	for _frame: int in 240:
		if TrialCoordinator.current_phase == target:
			return
		await get_tree().process_frame
	_failures.append("timed out waiting for %s" % TrialCoordinator.phase_name(target))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
