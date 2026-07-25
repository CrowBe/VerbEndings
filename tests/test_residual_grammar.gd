extends Node

var _failures: int = 0


func _ready() -> void:
	await _test_seeded_adverb_development()
	await _test_grammar_caps_and_independence()
	await _test_verbless_adverb_behaviour()
	if _failures == 0:
		print("Residual grammar tests passed.")
		get_tree().quit(0)
	else:
		push_error("%d Residual grammar test(s) failed." % _failures)
		get_tree().quit(1)


func _test_seeded_adverb_development() -> void:
	var first := await _spawn_residual(410)
	var second := await _spawn_residual(410)
	_expect(is_equal_approx(
			first.adverb_development_time, second.adverb_development_time),
			"identical seeds select identical survival thresholds")
	first.develop_adverb()
	second.develop_adverb()
	_expect(first.adverb == second.adverb,
			"identical seeds select identical Adverbs")
	first.queue_free()
	second.queue_free()


func _test_grammar_caps_and_independence() -> void:
	var residual := await _spawn_residual(52)
	residual.develop_adverb()
	var selected_adverb: Residual.AdverbType = residual.adverb
	residual.develop_adverb()
	_expect(residual.adverb == selected_adverb,
			"a Residual cannot replace its one Adverb")

	residual.assume_verb(Enums.VerbType.BURN)
	residual.assume_verb(Enums.VerbType.FREEZE)
	_expect(residual.verb == Enums.VerbType.BURN,
			"a Residual cannot replace its one assumed Verb")
	_expect(residual.adverb == selected_adverb,
			"Assumption does not replace or grant an Adverb")
	residual.queue_free()


func _test_verbless_adverb_behaviour() -> void:
	var residual := await _spawn_residual(73)
	var base_speed := residual.get_speed()
	var base_damage := residual.get_damage()
	residual.adverb = Residual.AdverbType.VIOLENTLY
	_expect(residual.verb == Enums.VerbType.NONE,
			"Adverb development does not self-develop a Verb")
	_expect(residual.get_speed() > base_speed,
			"an Adverb changes a Verbless Residual's movement")
	_expect(residual.get_damage() > base_damage,
			"an Adverb changes a Verbless Residual's attack")
	residual.queue_free()


func _spawn_residual(seed_value: int) -> Residual:
	var residual: Residual = preload("res://scenes/Residual.tscn").instantiate()
	residual.setup(1.0, seed_value)
	add_child(residual)
	await get_tree().process_frame
	return residual


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error(message)
