extends Node

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const RESIDUAL_SCENE := preload("res://scenes/Residual.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var subject := PLAYER_SCENE.instantiate()
	get_tree().root.add_child(subject)
	var collision: CollisionShape3D = subject.get_node("CollisionShape3D")
	subject.animation_adapter.set_visual_visible(false)
	_expect(not subject.get_node("Visual").visible,
			"Subject presentation can be hidden independently")
	_expect(collision != null and collision.shape != null,
			"hiding Subject presentation preserves gameplay collision")

	subject.animation_adapter.play_jump_start()
	_expect(subject.animation_adapter.last_semantic_clip == &"jump_start",
			"jump input maps to jump_start")
	subject.animation_adapter.play_land()
	_expect(subject.animation_adapter.last_semantic_clip == &"land",
			"landing maps to land")
	subject.animation_adapter.play_stability_loss()
	_expect(subject.animation_adapter.last_semantic_clip == &"stability_loss",
			"Stability loss maps to stability_loss")
	subject.animation_adapter.play_destabilise()
	_expect(subject.animation_adapter.last_semantic_clip == &"destabilise",
			"Destabilisation maps to destabilise")
	subject.animation_adapter.face_direction(Vector3.RIGHT, 1.0)
	_expect(subject.animation_adapter.get_facing_direction().is_equal_approx(Vector3.RIGHT),
			"gameplay facing follows the presentation heading")

	for verb: Enums.VerbType in [
		Enums.VerbType.BURN,
		Enums.VerbType.SHIELD,
		Enums.VerbType.GROW,
		Enums.VerbType.STRETCH,
		Enums.VerbType.ROLL,
		Enums.VerbType.JUMP,
		Enums.VerbType.BOUNCE,
		Enums.VerbType.FREEZE,
		Enums.VerbType.REWIND,
	]:
		subject.animation_adapter.play_verb_expression(Enums.verb_name(verb))
		_expect(
				subject.animation_adapter.last_semantic_clip == StringName(
						"verb_expression_%s" % Enums.verb_name(verb).to_lower()),
				"every Verb maps to its semantic expression clip")

	var residual := RESIDUAL_SCENE.instantiate()
	get_tree().root.add_child(residual)
	residual.animation_adapter.set_visual_visible(false)
	_expect(not residual.get_node("Visual").visible,
			"Residual presentation can be hidden independently")
	_expect(residual.get_node("CollisionShape3D").shape != null,
			"hiding Residual presentation preserves gameplay collision")

	subject.queue_free()
	residual.queue_free()
	if _failures.is_empty():
		print("Animation adapter tests passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
