extends Node

const KIT_PIECE_SCENE: PackedScene = preload(
		"res://scenes/environment/EnvironmentKitPiece.tscn")


func _ready() -> void:
	var failures: Array[String] = []
	await _test_collidable_rebuild(failures)
	await _test_collision_disabled_rebuild(failures)
	if failures.is_empty():
		print("Environment kit piece rebuild tests passed.")
		get_tree().quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	get_tree().quit(1)


func _test_collidable_rebuild(failures: Array[String]) -> void:
	var piece: EnvironmentKitPiece = KIT_PIECE_SCENE.instantiate()
	piece.configure(
			EnvironmentKitPiece.Kind.FLOOR_BAY,
			Vector3(4.0, 0.5, 4.0),
			Color("c8ced1"),
			true)
	add_child(piece)
	await get_tree().process_frame
	await get_tree().physics_frame
	_expect_live_visual_and_collision(
			piece, true, "initial collidable piece", failures)

	piece.configure(
			EnvironmentKitPiece.Kind.WALL_BAY,
			Vector3(6.0, 3.0, 0.5),
			Color("66727a"),
			true)
	piece.call("_rebuild")
	await get_tree().process_frame
	await get_tree().physics_frame
	_expect_live_visual_and_collision(
			piece, true, "rebuilt collidable piece", failures)
	piece.queue_free()
	await get_tree().process_frame


func _test_collision_disabled_rebuild(failures: Array[String]) -> void:
	var piece: EnvironmentKitPiece = KIT_PIECE_SCENE.instantiate()
	piece.configure(
			EnvironmentKitPiece.Kind.FLOOR_BAY,
			Vector3(4.0, 0.5, 4.0),
			Color("c8ced1"),
			false)
	add_child(piece)
	await get_tree().process_frame
	await get_tree().physics_frame
	piece.call("_rebuild")
	await get_tree().process_frame
	await get_tree().physics_frame
	_expect_live_visual_and_collision(
			piece, false, "rebuilt collision-disabled piece", failures)
	piece.queue_free()
	await get_tree().process_frame


func _expect_live_visual_and_collision(
	piece: EnvironmentKitPiece,
	expects_collision: bool,
	context: String,
	failures: Array[String],
) -> void:
	var live_mesh_count: int = 0
	for child: Node in piece.get_children():
		if child is MeshInstance3D \
				and child.mesh != null \
				and child.mesh.get_surface_count() > 0:
			live_mesh_count += 1
	var live_collision_count: int = _count_live_collision_shapes(piece)
	_expect(live_mesh_count > 0,
			"%s must retain a live non-empty visual mesh" % context, failures)
	_expect(
			live_collision_count > 0 if expects_collision \
					else live_collision_count == 0,
			"%s must %s live gameplay collision"
			% [context, "retain" if expects_collision else "not create"],
			failures)


func _count_live_collision_shapes(node: Node) -> int:
	var count: int = 0
	if node is CollisionShape3D and node.shape != null:
		count += 1
	for child: Node in node.get_children():
		count += _count_live_collision_shapes(child)
	return count


func _expect(
	condition: bool,
	message: String,
	failures: Array[String],
) -> void:
	if not condition:
		failures.append(message)
