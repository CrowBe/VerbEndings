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
	if not _is_host():
		return
	experiment_seconds_remaining = maxf(experiment_seconds_remaining - delta, 0.0)
	experiment_time_changed.emit(experiment_seconds_remaining)
	if is_zero_approx(experiment_seconds_remaining):
		_finish_experiment()


## Starts a complete Trial after the host has registered the roster and Verbs.
func start_trial(trial_seed: int, auto_complete_drafts: bool = false,
		duration_override: float = -1.0, preferred_protocol: String = "") -> bool:
	if not _is_host() or LobbyManager.lobby_players.is_empty():
		return false
	for player_id: int in LobbyManager.lobby_players:
		if VerbChainManager.active_players.get(player_id, Enums.VerbType.NONE) \
				== Enums.VerbType.NONE:
			push_warning("TrialCoordinator: every Subject needs a Verb before the Trial.")
			return false
	reset()
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


func _begin_pair_draft() -> void:
	if current_phase != Phase.VERB_SELECTION and current_phase != Phase.RESULT_ANNOUNCEMENT:
		return
	_set_phase(Phase.PAIR_DRAFT)
	if not LobbyManager.draft_completed.is_connected(_on_draft_completed):
		LobbyManager.draft_completed.connect(_on_draft_completed, CONNECT_ONE_SHOT)
	if RoundManager.current_round_index == 0:
		LobbyManager.begin_round_one_draft()
	else:
		LobbyManager.begin_subsequent_round_draft(RoundManager.current_round_index + 1)
	if automatic_drafts:
		LobbyManager.complete_draft_automatically()
	# An odd roster can complete synchronously before the connection above.
	if LobbyManager.current_chooser_id == -1 and LobbyManager.draft_queue.is_empty():
		call_deferred("_on_draft_completed")


func _on_draft_completed() -> void:
	if current_phase != Phase.PAIR_DRAFT:
		return
	var round_type: String = RoundManager.advance_to_next_round()
	if round_type.is_empty():
		return
	_set_phase(Phase.EXPERIMENT_BRIEF)
	if automatic_drafts:
		_begin_laboratory_entry()
		_begin_experiment()
	else:
		call_deferred("_begin_laboratory_entry")


func _begin_laboratory_entry() -> void:
	if current_phase != Phase.EXPERIMENT_BRIEF:
		return
	_set_phase(Phase.LABORATORY_ENTRY)
	call_deferred("_begin_experiment")


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
	call_deferred("_announce_result")


func _announce_result() -> void:
	if current_phase != Phase.RECALL:
		return
	_set_phase(Phase.RESULT_ANNOUNCEMENT)
	round_result_announced.emit(RoundManager.current_round_index,
			_pending_order.duplicate(), ScoreManager.get_trial_ranking())
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
	for body: Node in get_tree().get_nodes_in_group("players"):
		if body.has_method("restabilise"):
			body.call("restabilise")


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
	phase_changed.emit(current_phase, RoundManager.current_round_index,
			RoundManager.current_protocol)


func _is_host() -> bool:
	return not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
