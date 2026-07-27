class_name AnimationAdapter
extends Node
## Stable presentation boundary for actor visuals.
##
## Gameplay requests semantic clips through this adapter. A proxy visual may
## use the built-in procedural fallbacks; production visuals can provide an
## AnimationPlayer containing the same semantic clip names.

signal basic_hit_impact

const MOVEMENT_DEAD_ZONE: float = 0.1

@export var visual_root_path: NodePath = ^"Visual"
@export var animation_player_path: NodePath

var last_semantic_clip: StringName = &""
var _current_locomotion: StringName = &""

@onready var visual_root: Node3D = get_node_or_null(visual_root_path)
@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path)


func set_visual_visible(is_visible: bool) -> void:
	if visual_root != null:
		visual_root.visible = is_visible


func face_direction(direction: Vector3, turn_amount: float) -> void:
	if visual_root == null or direction.is_zero_approx():
		return
	visual_root.rotation.y = lerp_angle(
			visual_root.rotation.y, atan2(direction.x, direction.z), turn_amount)


func get_facing_direction() -> Vector3:
	if visual_root == null:
		return Vector3.BACK
	return visual_root.global_transform.basis * Vector3.BACK


func update_locomotion(horizontal_speed: float, is_grounded: bool) -> void:
	if not is_grounded:
		return
	var clip: StringName = &"move" if horizontal_speed > MOVEMENT_DEAD_ZONE else &"idle"
	if clip == _current_locomotion:
		return
	_current_locomotion = clip
	play_semantic(clip)


func play_jump_start() -> void:
	play_semantic(&"jump_start")


func play_land() -> void:
	play_semantic(&"land")


func play_basic_hit() -> void:
	if play_semantic(&"basic_hit"):
		# Production clips resolve their gameplay Impact immediately until
		# authored call-method tracks provide a later marker.
		basic_hit_impact.emit()
		return
	_play_proxy_basic_hit()


func play_verb_expression(verb_name: String) -> void:
	play_semantic(StringName("verb_expression_%s" % verb_name.to_lower()))


func play_stability_loss() -> void:
	play_semantic(&"stability_loss")


func play_destabilise() -> void:
	play_semantic(&"destabilise")


func play_semantic(clip: StringName) -> bool:
	last_semantic_clip = clip
	return _play_animation_player_clip(clip)


func apply_verb_treatment(verb: Enums.VerbType) -> void:
	if visual_root == null:
		return
	var treatment_mesh: MeshInstance3D = visual_root.get_node_or_null("VerbTreatment")
	if treatment_mesh == null:
		return
	var colours: Dictionary = {
		Enums.VerbType.BURN: Color("#ff6a3d"),
		Enums.VerbType.SHIELD: Color("#35bceb"),
		Enums.VerbType.GROW: Color("#66c95a"),
		Enums.VerbType.STRETCH: Color("#d45ac7"),
		Enums.VerbType.ROLL: Color("#4169d8"),
		Enums.VerbType.JUMP: Color("#f2c94c"),
		Enums.VerbType.BOUNCE: Color("#ff7db5"),
		Enums.VerbType.FREEZE: Color("#a8e8e8"),
		Enums.VerbType.REWIND: Color("#8067d8"),
	}
	var treatment := StandardMaterial3D.new()
	treatment.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	treatment.albedo_color = colours.get(verb, Color.WHITE) * Color(1, 1, 1, 0.38)
	treatment.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	treatment_mesh.material_override = treatment
	treatment_mesh.visible = true


func apply_adverb_treatment(adverb: int) -> void:
	if visual_root == null:
		return
	var overlay_mesh: MeshInstance3D = visual_root.get_node_or_null("AdverbOverlay")
	if overlay_mesh == null:
		return
	var overlay := StandardMaterial3D.new()
	overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overlay.albedo_color = {
		1: Color(0.95, 0.95, 0.95, 0.7),
		2: Color(0.15, 0.15, 0.15, 0.8),
		3: Color(0.55, 0.55, 0.55, 0.75),
	}.get(adverb, Color.TRANSPARENT)
	overlay_mesh.material_override = overlay
	overlay_mesh.visible = true


func _play_animation_player_clip(clip: StringName) -> bool:
	if animation_player == null or not animation_player.has_animation(clip):
		return false
	animation_player.play(clip)
	return true


func _play_proxy_basic_hit() -> void:
	if visual_root == null:
		basic_hit_impact.emit()
		return
	var fist_pivot: Node3D = visual_root.get_node_or_null("FistPivot")
	var fist_mesh: MeshInstance3D = visual_root.get_node_or_null("FistPivot/FistMesh")
	if fist_pivot == null or fist_mesh == null:
		basic_hit_impact.emit()
		return
	fist_mesh.visible = true
	fist_mesh.scale = Vector3.ONE * 0.2
	fist_pivot.position.z = 0.3
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(fist_mesh, "scale", Vector3.ONE * 1.6, 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(fist_pivot, "position:z", 1.2, 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(basic_hit_impact.emit)
	tween.tween_interval(0.08)
	tween.set_parallel(true)
	tween.tween_property(fist_mesh, "scale", Vector3.ONE * 0.2, 0.15)
	tween.tween_property(fist_pivot, "position:z", 0.3, 0.15)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void: fist_mesh.visible = false)
