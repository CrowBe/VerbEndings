extends Node
## Host-authoritative owner of the canonical three-Round Trial lifecycle.
## Presentation and scene composition consume signals; they never advance state.

enum Phase {
	IDLE,
	VERB_SELECTION,
	PAIR_DRAFT,
	EXPERIMENT_BRIEF,
	LABORATORY_ENTRY,
	EXPERIMENT,
	RECALL,
	RESULT_ANNOUNCEMENT,
	THEMATIC_MOMENT,
	COLLAPSE,
	COMPLETE,
}

signal trial_started(trial_seed: int)
signal phase_changed(phase: Phase, round_index: int, protocol: ExperimentProtocol)
signal experiment_requested(round_index: int, protocol: ExperimentProtocol)
signal laboratory_entry_requested(round_index: int, protocol: ExperimentProtocol)
signal recall_requested(round_index: int, protocol: ExperimentProtocol)
signal experiment_time_changed(seconds_remaining: float)
signal round_result_announced(round_index: int, ordered_player_ids: Array,
		trial_ranking: Array)
signal trial_completed(winner_id: int)

var current_phase: Phase = Phase.IDLE
var experiment_seconds_remaining: float = 0.0
var automatic_drafts: bool = false
var experiment_duration_override: float = -1.0

var _active_round_controller: Node = null
var _round_result_received: bool = false
var _pending_order: Array = []
var _winner_id: int = -1


func _ready() -> void:
	CollapseManager.ultimate_winner_decided.connect(_on_winner_decided)


func _process(delta: float) -> void:
	if current_phase != Phase.EXPERIMENT or _round_result_received:
		return
	if not NetworkSession.can_simulate():
		return
	experiment_seconds_remaining = maxf(experiment_seconds_remaining - delta, 0.0)
	experiment_time_changed.emit(experiment_seconds_remaining)
	if is_zero_approx(experiment_seconds_remaining):
		_finish_experiment()


## Starts a complete Trial after the host has registered the roster and Verbs.
func start_trial(trial_seed: int, auto_complete_drafts: bool = false,
		duration_override: float = -1.0, preferred_protocol: String = "") -> bool:
	if not NetworkSession.can_simulate() or LobbyManager.lobby_players.is_empty():
		return false
	for player_id: int in LobbyManager.lobby_players:
		if VerbChainManager.active_players.get(player_id, Enums.VerbType.NONE) \
				== Enums.VerbType.NONE:
			push_warning("TrialCoordinator: every Subject needs a Verb before the Trial.")
			return false
	reset()
	FacilityStateLedger.reset_for_trial(trial_seed)
	automatic_drafts = auto_complete_drafts
	experiment_duration_override = duration_override
	if preferred_protocol.is_empty():
		RoundManager.secretly_queue_rounds(trial_seed)
	elif not RoundManager.queue_local_protocol(preferred_protocol, trial_seed):
		return false
	trial_started.emit(trial_seed)
	_set_phase(Phase.VERB_SELECTION)
	if automatic_drafts:
		_begin_pair_draft()
	else:
		call_deferred("_begin_pair_draft")
	return true


## Registers the Round scene created by the composition root for the requested
## Protocol. Exactly one result signal is accepted for each Experiment.
func set_active_round_controller(controller: Node) -> bool:
	if current_phase != Phase.EXPERIMENT or controller == null \
			or not controller.has_signal("round_finished") \
			or not controller.has_method("end_round"):
		return false
	if _active_round_controller != null and is_instance_valid(_active_round_controller):
		_disconnect_round_controller()
	_active_round_controller = controller
	_active_round_controller.round_finished.connect(_on_round_finished)
	return true


## Completion-condition hook for Round controllers. The coordinator validates
## it against the authored mode before ending the Experiment.
func notify_completion_condition(condition: String) -> bool:
	if current_phase != Phase.EXPERIMENT or RoundManager.current_protocol == null:
		return false
	var mode: String = RoundManager.current_protocol.completion_mode
	var accepted: bool = condition == "one_eligible_subject" \
			and mode == "TIMER_OR_ONE_ELIGIBLE"
	accepted = accepted or condition == "all_objectives" \
			and mode == "TIMER_OR_ALL_OBJECTIVES"
	if accepted:
		_finish_experiment()
	return accepted


func reset() -> void:
	_disconnect_round_controller()
	current_phase = Phase.IDLE
	experiment_seconds_remaining = 0.0
	_round_result_received = false
	_pending_order.clear()
	_winner_id = -1
	automatic_drafts = false
	experiment_duration_override = -1.0
	CollapseManager.reset()


func phase_name(phase: Phase = current_phase) -> String:
	return Phase.keys()[phase].capitalize().replace("_", " ")


func get_winner_id() -> int:
	return _winner_id


## Applies host-authored presentation state without advancing client logic.
func apply_replicated_state(phase: Phase, seconds_remaining: float,
		winner_id: int) -> void:
	current_phase = phase
	experiment_seconds_remaining = seconds_remaining
	_winner_id = winner_id


func _begin_pair_draft() -> void:
	if current_phase != Phase.VERB_SELECTION and current_phase != Phase.RESULT_ANNOUNCEMENT:
		return
	_set_phase(Phase.PAIR_DRAFT)
	if not automatic_drafts \
			and not LobbyManager.draft_completed.is_connected(_on_draft_completed):
		LobbyManager.draft_completed.connect(_on_draft_completed, CONNECT_ONE_SHOT)
	if RoundManager.current_round_index == 0:
		LobbyManager.begin_round_one_draft()
	else:
		LobbyManager.begin_subsequent_round_draft(RoundManager.current_round_index + 1)
	if automatic_drafts:
		LobbyManager.complete_draft_automatically()
		_on_draft_completed()


func _on_draft_completed() -> void:
	if current_phase != Phase.PAIR_DRAFT:
		return
	var round_type: String = RoundManager.advance_to_next_round()
	if round_type.is_empty():
		return
	_set_phase(Phase.EXPERIMENT_BRIEF)
	if automatic_drafts:
		_begin_laboratory_entry()


## Player-facing presentation completion seam. Interactive Trials remain on
## the Experiment Brief until the local presentation explicitly continues.
func complete_experiment_brief() -> bool:
	if not NetworkSession.can_simulate() or current_phase != Phase.EXPERIMENT_BRIEF:
		return false
	_begin_laboratory_entry()
	return true


func _begin_laboratory_entry() -> void:
	if current_phase != Phase.EXPERIMENT_BRIEF:
		return
	_set_phase(Phase.LABORATORY_ENTRY)
	laboratory_entry_requested.emit(
			RoundManager.current_round_index, RoundManager.current_protocol)


## Host-authoritative presentation completion seam. The Experiment cannot
## begin until every Subject has independently Released and Landed.
func complete_laboratory_entry() -> bool:
	if not NetworkSession.can_simulate() or current_phase != Phase.LABORATORY_ENTRY:
		return false
	_begin_experiment()
	return true


func _begin_experiment() -> void:
	if current_phase != Phase.LABORATORY_ENTRY:
		return
	_round_result_received = false
	_pending_order.clear()
	_set_phase(Phase.EXPERIMENT)
	var authored_duration: float = RoundManager.current_protocol.duration_seconds
	experiment_seconds_remaining = experiment_duration_override \
			if experiment_duration_override >= 0.0 else authored_duration
	experiment_requested.emit(RoundManager.current_round_index, RoundManager.current_protocol)


func _finish_experiment() -> void:
	if _round_result_received or _active_round_controller == null \
			or not is_instance_valid(_active_round_controller):
		return
	_round_result_received = true
	_active_round_controller.call("end_round")


func _on_round_finished(ordered_player_ids: Array) -> void:
	if current_phase != Phase.EXPERIMENT:
		return
	_pending_order = ordered_player_ids.duplicate()
	_disconnect_round_controller()
	_set_phase(Phase.RECALL)
	_recall_subjects()
	recall_requested.emit(RoundManager.current_round_index, RoundManager.current_protocol)


## Host-authoritative presentation completion seam. Result Announcement waits
## until every eligible Subject has traversed Recall to the Assignment Deck.
func complete_recall() -> bool:
	if not NetworkSession.can_simulate() or current_phase != Phase.RECALL:
		return false
	_announce_result()
	return true


func _announce_result() -> void:
	if current_phase != Phase.RECALL:
		return
	_set_phase(Phase.RESULT_ANNOUNCEMENT)
	round_result_announced.emit(RoundManager.current_round_index,
			_pending_order.duplicate(), ScoreManager.get_trial_ranking())
	if not automatic_drafts:
		return
	_complete_result_presentation()


## Player-facing presentation completion seam. Interactive Trials keep the
## Result Announcement visible until the local presentation acknowledges it.
func complete_result_announcement() -> bool:
	if not NetworkSession.can_simulate() or current_phase != Phase.RESULT_ANNOUNCEMENT:
		return false
	_complete_result_presentation()
	return true


func _complete_result_presentation() -> void:
	if RoundManager.current_protocol.includes_thematic_moment:
		_set_phase(Phase.THEMATIC_MOMENT)
		call_deferred("_finish_round_lifecycle")
		return
	_finish_round_lifecycle()


func _finish_round_lifecycle() -> void:
	if current_phase != Phase.RESULT_ANNOUNCEMENT \
			and current_phase != Phase.THEMATIC_MOMENT:
		return
	if RoundManager.is_trial_complete():
		VerbChainManager.dissolve_all_chains()
		if CollapseManager.resolve_trial_end():
			_set_phase(Phase.COLLAPSE)
		return
	call_deferred("_begin_pair_draft")


func _recall_subjects() -> void:
	SubjectRoster.recall_all()


func _on_winner_decided(player_id: int) -> void:
	_winner_id = player_id
	_set_phase(Phase.COMPLETE)
	trial_completed.emit(player_id)


func _disconnect_round_controller() -> void:
	if _active_round_controller != null and is_instance_valid(_active_round_controller) \
			and _active_round_controller.has_signal("round_finished") \
			and _active_round_controller.round_finished.is_connected(_on_round_finished):
		_active_round_controller.round_finished.disconnect(_on_round_finished)
	_active_round_controller = null


func _set_phase(next_phase: Phase) -> void:
	current_phase = next_phase
	_update_facility_lifecycle()
	phase_changed.emit(current_phase, RoundManager.current_round_index,
			RoundManager.current_protocol)


func _update_facility_lifecycle() -> void:
	if RoundManager.current_protocol == null:
		return
	var laboratory_id: StringName = {
		"ENVIRONMENT": &"AppliedAttrition",
		"PVP": &"CompetitiveStress",
		"PVE": &"AdaptiveContainment",
	}.get(RoundManager.current_protocol.classification, &"")
	if laboratory_id.is_empty():
		return
	var stage_index: int = clampi(RoundManager.current_round_index - 1, 0, 2)
	FacilityStateLedger.set_round_stage(laboratory_id,
			FacilityStateLedger.ROUND_STAGES[stage_index],
			&"round_%d_stage" % RoundManager.current_round_index)
	var lifecycle: StringName = {
		Phase.EXPERIMENT_BRIEF: &"brief",
		Phase.LABORATORY_ENTRY: &"entry",
		Phase.EXPERIMENT: &"live",
		Phase.RECALL: &"recall",
		Phase.RESULT_ANNOUNCEMENT: &"resolve",
		Phase.THEMATIC_MOMENT: &"resolve",
	}.get(current_phase, &"idle")
	FacilityStateLedger.set_experiment_lifecycle(laboratory_id, lifecycle,
			&"%s_%s" % [
				laboratory_id, phase_name(current_phase).to_lower().replace(" ", "_")])
	var objective: StringName = RoundManager.current_protocol.objective \
			if lifecycle in [&"brief", &"entry", &"live"] else &""
	FacilityStateLedger.set_active_objective(laboratory_id, objective,
			&"%s_objective_%s" % [laboratory_id, lifecycle])