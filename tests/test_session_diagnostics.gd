extends Node

const TEST_SUMMARY_PATH := "user://verbendings_session_summary_test.json"

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SessionDiagnostics.use_output_path_for_testing(TEST_SUMMARY_PATH)
	SessionDiagnostics.begin_session(55123)
	SessionDiagnostics.record_protocol(&"sustained_exposure")
	SessionDiagnostics.record_protocol(&"competitive_stress")
	SessionDiagnostics.record_protocol(&"adaptive_containment")
	for index: int in SessionDiagnostics.MAX_LIFECYCLE_TRANSITIONS + 5:
		SessionDiagnostics.record_lifecycle_transition("EXPERIMENT", index % 3 + 1)
	for index: int in SessionDiagnostics.MAX_DISCONNECTS + 5:
		SessionDiagnostics.record_disconnect(index + 2, "EXPERIMENT", 2)
	SessionDiagnostics.complete_session(1)

	var summary: Dictionary = SessionDiagnostics.summary()
	_expect(summary.build_identifier == "mvp-playtest.1",
			"the summary records the configured build identifier")
	_expect(summary.trial_seed == 55123,
			"the summary records the reproducible Trial seed")
	_expect(summary.protocol_order == [
			"sustained_exposure", "competitive_stress", "adaptive_containment"],
			"the summary records the revealed Protocol order")
	_expect(summary.lifecycle_transitions.size() \
			== SessionDiagnostics.MAX_LIFECYCLE_TRANSITIONS \
			and summary.lifecycle_transitions_truncated,
			"lifecycle capture is explicitly bounded")
	_expect(summary.disconnects.size() == SessionDiagnostics.MAX_DISCONNECTS \
			and summary.disconnects_truncated,
			"disconnect capture is explicitly bounded")
	_expect(summary.final_result.status == "complete" \
			and summary.final_result.winner_subject_id == 1,
			"the summary records the final Trial result")

	var summary_text: String = SessionDiagnostics.summary_json()
	_expect(not summary_text.contains("127.0.0.1") \
			and not summary_text.contains("user://") \
			and not summary_text.contains(ProjectSettings.globalize_path("res://")),
			"the serialised summary contains no address or machine-specific path")
	var saved := FileAccess.get_file_as_string(TEST_SUMMARY_PATH)
	_expect(saved.strip_edges() == summary_text,
			"the latest bounded summary is available as a local file")
	_expect(JSON.parse_string(saved) is Dictionary,
			"the saved summary is valid JSON")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SUMMARY_PATH))
	SessionDiagnostics.restore_default_output_path()
	if _failures.is_empty():
		print("Session diagnostics tests passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
