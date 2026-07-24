extends Node

const PLAYER_SCENE := preload("res://scenes/Player.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var subject := PLAYER_SCENE.instantiate()
	get_tree().root.add_child(subject)
	subject.set_character_identity(Enums.VerbType.BURN)
	subject.expression_costs[Enums.VerbType.BURN] = 60.0

	subject.express_verb()
	_expect(is_equal_approx(subject.stability, 40.0),
			"Expression deducts the configured Base Expression Cost")
	subject._verb_timer = 0.0
	subject.express_verb()
	_expect(is_equal_approx(subject.stability, 1.0),
			"Expression spend floors Stability at 1")
	_expect(not subject.is_destabilised,
			"Expression spend cannot Destabilise a Subject")
	_expect(subject.is_critical_stability,
			"single-digit Stability raises the Critical Stability hook")

	subject.apply_impact(1.0)
	_expect(subject.is_destabilised,
			"an external Impact can Destabilise a Subject at 1 Stability")
	subject.restabilise()
	_expect(is_equal_approx(subject.stability, subject.BASELINE_STABILITY),
			"Recall Restabilisation restores baseline Stability")
	_expect(not subject.is_destabilised,
			"Restabilisation makes the Subject eligible to continue")

	subject._set_stability(40.0)
	subject.stabilisation_rate = 2.5
	subject._apply_stabilisation(2.0)
	_expect(is_equal_approx(subject.stability, 45.0),
			"Stabilisation Rate restores a percentage of baseline per second")

	subject._set_stability(99.0)
	subject._apply_stabilisation(2.0)
	_expect(is_equal_approx(subject.stability, subject.BASELINE_STABILITY),
			"Stabilisation Rate stops exactly at baseline")

	subject._set_stability(1.0)
	subject.apply_impact(1.0)
	subject._apply_stabilisation(10.0)
	_expect(is_equal_approx(subject.stability, 0.0),
			"Destabilised Subjects do not recover through the rate")
	_expect(subject.is_destabilised,
			"Stabilisation Rate does not prevent Impact Destabilisation")

	subject.queue_free()
	if _failures.is_empty():
		print("Stability tests passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
