extends Node


func _ready() -> void:
	var failures: Array[String] = []
	var first_sequence: Array[StringName] = _sequence_for_seed(1601)
	var repeated_sequence: Array[StringName] = _sequence_for_seed(1601)
	_expect(first_sequence == repeated_sequence,
			"identical seeds must select identical Protocol sequences", failures)
	_expect(first_sequence.size() == 3,
			"a Trial must select three Protocols", failures)

	for protocol: ExperimentProtocol in RoundManager.PROTOCOLS:
		_expect(not protocol.protocol_id.is_empty(),
				"every Protocol needs a stable id", failures)
		_expect(not protocol.objective.is_empty(),
				"every Protocol needs an Objective", failures)
		_expect(not protocol.completion_condition.is_empty(),
				"every Protocol needs a completion condition", failures)
		var brief: String = protocol.experiment_brief()
		_expect(brief.contains("EXPERIMENT PROTOCOL"),
				"brief must use canonical Protocol terminology", failures)
		_expect(brief.contains("OBJECTIVE"),
				"brief must include the authored Objective", failures)
		_expect(not brief.contains(protocol.classification),
				"brief must not expose development classifications", failures)

	if failures.is_empty():
		print("Experiment Protocol tests passed.")
		get_tree().quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	get_tree().quit(1)


func _sequence_for_seed(seed: int) -> Array[StringName]:
	RoundManager.secretly_queue_rounds(seed)
	var sequence: Array[StringName] = []
	for _round_index: int in RoundManager.TOTAL_ROUNDS:
		RoundManager.advance_to_next_round()
		sequence.append(RoundManager.current_protocol.protocol_id)
	return sequence


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
