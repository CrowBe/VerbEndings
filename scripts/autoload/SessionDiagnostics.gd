extends Node
## Privacy-safe, bounded record of one locally observed Trial session.
##
## The summary deliberately contains only reproducibility and lifecycle data:
## no addresses, display names, timestamps, or machine-specific paths.

const MAX_PROTOCOLS: int = 3
const MAX_LIFECYCLE_TRANSITIONS: int = 64
const MAX_DISCONNECTS: int = 24
const DEFAULT_SUMMARY_PATH: String = "user://latest_session_summary.json"

var _summary: Dictionary = {}
var _session_active: bool = false
var _output_path: String = DEFAULT_SUMMARY_PATH


func _ready() -> void:
	TrialCoordinator.trial_started.connect(_on_trial_started)
	TrialCoordinator.phase_changed.connect(_on_phase_changed)
	TrialCoordinator.trial_completed.connect(_on_trial_completed)
	RoundManager.round_started.connect(_on_round_started)
	NetworkSession.authoritative_state_received.connect(_on_authoritative_state)
	NetworkSession.participant_disconnected.connect(_on_participant_disconnected)
	NetworkSession.host_disconnected.connect(_on_host_disconnected)
	_reset_summary(0)


func begin_session(trial_seed: int) -> void:
	_reset_summary(trial_seed)
	_session_active = true
	_save_summary()


func prepare_session(trial_seed: int) -> void:
	_reset_summary(trial_seed)
	_session_active = false
	_save_summary()


func record_protocol(protocol_id: StringName) -> void:
	if not _session_active or protocol_id.is_empty():
		return
	var protocols: Array = _summary.protocol_order
	if protocol_id in protocols:
		return
	if protocols.size() >= MAX_PROTOCOLS:
		_summary.protocol_order_truncated = true
	else:
		protocols.append(String(protocol_id))
	_save_summary()


func record_lifecycle_transition(phase: String, round_index: int) -> void:
	if not _session_active:
		return
	var transitions: Array = _summary.lifecycle_transitions
	if transitions.size() >= MAX_LIFECYCLE_TRANSITIONS:
		_summary.lifecycle_transitions_truncated = true
	else:
		transitions.append({
			"phase": phase,
			"round": round_index,
		})
	_save_summary()


func record_disconnect(subject_id: int, phase: String, round_index: int) -> void:
	if not _session_active:
		return
	var disconnects: Array = _summary.disconnects
	if disconnects.size() >= MAX_DISCONNECTS:
		_summary.disconnects_truncated = true
	else:
		disconnects.append({
			"subject_id": subject_id,
			"phase": phase,
			"round": round_index,
		})
	_save_summary()


func complete_session(winner_subject_id: int) -> void:
	if not _session_active:
		return
	_summary.final_result = {
		"status": "complete",
		"winner_subject_id": winner_subject_id,
	}
	_session_active = false
	_save_summary()


func build_identifier() -> String:
	return str(ProjectSettings.get_setting(
			"application/config/version", "development"))


func current_seed() -> int:
	return int(_summary.get("trial_seed", 0))


func summary() -> Dictionary:
	return _summary.duplicate(true)


func summary_json() -> String:
	return JSON.stringify(_summary, "  ", true)


func summary_file_path() -> String:
	return ProjectSettings.globalize_path(_output_path)


func use_output_path_for_testing(path: String) -> void:
	_output_path = path


func restore_default_output_path() -> void:
	_output_path = DEFAULT_SUMMARY_PATH


func _reset_summary(trial_seed: int) -> void:
	_summary = {
		"schema": 1,
		"build_identifier": build_identifier(),
		"trial_seed": trial_seed,
		"protocol_order": [],
		"protocol_order_truncated": false,
		"lifecycle_transitions": [],
		"lifecycle_transitions_truncated": false,
		"disconnects": [],
		"disconnects_truncated": false,
		"final_result": {"status": "incomplete"},
	}


func _save_summary() -> Error:
	var file := FileAccess.open(_output_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(summary_json() + "\n")
	return OK


func _on_trial_started(trial_seed: int) -> void:
	begin_session(trial_seed)


func _on_phase_changed(phase: TrialCoordinator.Phase, round_index: int,
		_protocol: ExperimentProtocol) -> void:
	if not _session_active:
		var replicated_seed: int = NetworkSession.trial_seed
		if replicated_seed == 0:
			return
		begin_session(replicated_seed)
	record_lifecycle_transition(TrialCoordinator.Phase.keys()[phase], round_index)


func _on_round_started(_round_index: int, protocol: ExperimentProtocol) -> void:
	if protocol != null:
		record_protocol(protocol.protocol_id)


func _on_trial_completed(winner_subject_id: int) -> void:
	complete_session(winner_subject_id)


func _on_authoritative_state(snapshot: Dictionary) -> void:
	var replicated_seed: int = int(snapshot.get("seed", 0))
	if replicated_seed != 0 and current_seed() != replicated_seed:
		begin_session(replicated_seed)
	for classification: String in snapshot.get("round_history", []):
		var protocol_id := _protocol_id_for_classification(classification)
		if not protocol_id.is_empty():
			record_protocol(protocol_id)


func _on_participant_disconnected(subject_id: int) -> void:
	record_disconnect(subject_id, TrialCoordinator.Phase.keys()[
			TrialCoordinator.current_phase], RoundManager.current_round_index)


func _on_host_disconnected() -> void:
	record_disconnect(1, TrialCoordinator.Phase.keys()[
			TrialCoordinator.current_phase], RoundManager.current_round_index)


func _protocol_id_for_classification(classification: String) -> StringName:
	for protocol: ExperimentProtocol in RoundManager.PROTOCOLS:
		if protocol.classification == classification:
			return protocol.protocol_id
	return &""
