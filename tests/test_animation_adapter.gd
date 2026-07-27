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

	await _test_proxy_basic_hit(subject.animation_adapter)
	await _test_production_basic_hit_without_marker()
	await _test_production_basic_hit_with_marker()

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


func _test_proxy_basic_hit(adapter: AnimationAdapter) -> void:
	var fist_pivot: Node3D = adapter.visual_root.get_node("FistPivot")
	var impact_state := {"count": 0, "fist_position_z": 0.0}
	adapter.basic_hit_impact.connect(func() -> void:
		impact_state.count += 1
		impact_state.fist_position_z = fist_pivot.position.z
	)
	adapter.play_basic_hit()
	_expect(impact_state.count == 0,
			"proxy fallback does not resolve Impact at animation request time")
	await get_tree().create_timer(0.06).timeout
	_expect(impact_state.count == 0,
			"proxy fallback preserves its anticipation before full extension")
	await get_tree().create_timer(0.08).timeout
	_expect(impact_state.count == 1,
			"proxy fallback resolves Impact at full extension")
	_expect(is_equal_approx(impact_state.fist_position_z, 1.2),
			"proxy Impact coincides with the fist's full extension")
	await get_tree().create_timer(0.30).timeout
	_expect(impact_state.count == 1,
			"proxy fallback resolves exactly one Impact")


func _test_production_basic_hit_without_marker() -> void:
	var fixture: Dictionary = _create_production_adapter(0.12, [])
	var adapter: AnimationAdapter = fixture.adapter
	var impact_state := {"count": 0}
	adapter.basic_hit_impact.connect(func() -> void: impact_state.count += 1)
	adapter.play_basic_hit()
	_expect(impact_state.count == 0,
			"production fallback does not resolve Impact at animation request time")
	await get_tree().create_timer(0.06).timeout
	_expect(impact_state.count == 0,
			"production fallback waits for the basic_hit clip duration")
	await get_tree().create_timer(0.10).timeout
	_expect(impact_state.count == 1,
			"production clip without a marker resolves one fallback Impact")
	adapter.play_basic_hit()
	await get_tree().create_timer(0.04).timeout
	adapter.play_basic_hit()
	await get_tree().create_timer(0.10).timeout
	_expect(impact_state.count == 2,
			"an overlapping accepted attempt does not suppress the earlier fallback")
	await get_tree().create_timer(0.06).timeout
	_expect(impact_state.count == 3,
			"each overlapping accepted attempt resolves exactly one fallback Impact")
	fixture.root.queue_free()


func _test_production_basic_hit_with_marker() -> void:
	var fixture: Dictionary = _create_production_adapter(0.16, [0.04, 0.07])
	var adapter: AnimationAdapter = fixture.adapter
	var impact_state := {"count": 0}
	adapter.basic_hit_impact.connect(func() -> void: impact_state.count += 1)
	adapter.play_basic_hit()
	await get_tree().create_timer(0.02).timeout
	_expect(impact_state.count == 0,
			"production marker does not resolve Impact before its authored frame")
	await get_tree().create_timer(0.05).timeout
	_expect(impact_state.count == 1,
			"production marker resolves Impact at its authored contact frame")
	await get_tree().create_timer(0.16).timeout
	_expect(impact_state.count == 1,
			"duplicate markers and the production fallback resolve exactly one Impact")
	adapter.play_basic_hit()
	await get_tree().create_timer(0.10).timeout
	_expect(impact_state.count == 2,
			"a second accepted production attempt resolves its own single Impact")
	await get_tree().create_timer(0.12).timeout
	_expect(impact_state.count == 2,
			"each accepted production attempt remains exactly once after fallback")
	fixture.root.queue_free()


func _create_production_adapter(
		clip_length: float, marker_times: Array[float]) -> Dictionary:
	var root := Node3D.new()
	root.name = "ProductionFixture"
	get_tree().root.add_child(root)

	var visual := Node3D.new()
	visual.name = "Visual"
	root.add_child(visual)

	var animation_player := AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	root.add_child(animation_player)

	var adapter := AnimationAdapter.new()
	adapter.name = "AnimationAdapter"
	adapter.visual_root_path = ^"../Visual"
	adapter.animation_player_path = ^"../AnimationPlayer"
	root.add_child(adapter)

	var animation := Animation.new()
	animation.length = clip_length
	if not marker_times.is_empty():
		var marker_track: int = animation.add_track(Animation.TYPE_METHOD)
		animation.track_set_path(marker_track, ^"AnimationAdapter")
		for marker_time: float in marker_times:
			animation.track_insert_key(marker_track, marker_time, {
				"method": &"basic_hit_contact",
				"args": [],
			})
	var library := AnimationLibrary.new()
	library.add_animation(&"basic_hit", animation)
	animation_player.add_animation_library(&"", library)

	return {
		"root": root,
		"adapter": adapter,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
