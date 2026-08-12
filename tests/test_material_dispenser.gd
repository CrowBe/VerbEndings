extends Node
## Headless suite for the Material Dispenser production visual boundary.
## Instantiates the real scene and verifies the imported GLB presentation,
## the Godot-owned cylinder collision, the presentation bounds and triangle
## budget, the expected surface materials, the DispenseSocket alignment, and
## dispensing while the presentation is hidden. The assertions use tolerant
## ranges so the final production asset's exact mesh and triangle counts do
## not break the suite.

const DISPENSER_SCENE: PackedScene = preload("res://scenes/MaterialDispenser.tscn")
const DISPENSER_GLB_PATH := "res://assets/exports/props/material_dispenser.glb"

const EXPECTED_MATERIALS: Array[String] = [
	"Warm_Off_White",
	"Equipment_Grey",
	"Charcoal",
	"Systems_Cyan",
	"Soft_White_Emission",
]

const WIDTH_M := 1.6
const HEIGHT_M := 2.0
const FRONT_EXTENT_M := 1.1
const MAX_DEPTH_M := 1.92
const DIMENSION_TOLERANCE_M := 0.02
const FRONT_EXTENT_TOLERANCE_M := 0.02
const FLOOR_TOLERANCE_M := 0.01
const MIN_TRIANGLES := 8000
const MAX_TRIANGLES := 15000
const SOCKET_ALIGNMENT := Vector3(0.0, 0.4, 1.1)
const POSITION_TOLERANCE_M := 0.001

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var container := Node3D.new()
	container.name = "DispenserFixture"
	get_tree().root.add_child(container)

	var dispenser: Node3D = DISPENSER_SCENE.instantiate()
	container.add_child(dispenser)

	_expect(dispenser.get_script() != null and dispenser.has_method("dispense"),
			"dispenser retains its stable root script")
	var apparatus: StaticBody3D = dispenser.get_node_or_null("Apparatus")
	_expect(apparatus != null, "Apparatus StaticBody3D remains the gameplay body")
	var collision: CollisionShape3D = dispenser.get_node_or_null("Apparatus/CollisionShape3D")
	_expect(collision != null and collision.shape != null,
			"Godot cylinder collision remains on Apparatus")
	_expect(collision != null and not collision.disabled,
			"Godot cylinder collision is enabled")

	var visual: Node3D = dispenser.get_node_or_null("Apparatus/Visual")
	_expect(visual != null, "imported Visual child exists on Apparatus")
	if visual == null:
		_finish(container)
		return

	_expect(visual.scene_file_path == DISPENSER_GLB_PATH,
			"Visual is the imported GLB scene")

	var mesh_instances: Array[MeshInstance3D] = _mesh_instances(visual)
	_expect(not mesh_instances.is_empty(), "Visual contains mesh instances")
	_expect(_collision_descendants(visual).is_empty(),
			"Visual contains no collision descendants")
	_expect(not _has_ancestor(collision, visual),
			"Godot collision remains outside Visual")

	visual.visible = false
	_expect(not visual.visible, "Visual can be hidden independently")
	_expect(collision.shape != null and not collision.disabled,
			"hiding Visual leaves Godot collision enabled")

	var bounds := _visual_bounds(visual, dispenser)
	_expect(bounds.size.x > WIDTH_M - DIMENSION_TOLERANCE_M
			and bounds.size.x < WIDTH_M + DIMENSION_TOLERANCE_M,
			"overall visual width is approximately 1.6 m")
	_expect(bounds.size.y > HEIGHT_M - DIMENSION_TOLERANCE_M
			and bounds.size.y < HEIGHT_M + DIMENSION_TOLERANCE_M,
			"overall visual height is approximately 2.0 m")
	_expect(absf(bounds.position.y) <= FLOOR_TOLERANCE_M,
			"overall visual floor offset is zero")
	_expect(bounds.size.z <= MAX_DEPTH_M,
			"overall visual depth is no more than 1.92 m")
	_expect(bounds.end.z > FRONT_EXTENT_M - FRONT_EXTENT_TOLERANCE_M
			and bounds.end.z < FRONT_EXTENT_M + FRONT_EXTENT_TOLERANCE_M,
			"front extent is approximately Godot +Z = 1.1 m")

	var triangle_count := 0
	for mesh_instance: MeshInstance3D in mesh_instances:
		var mesh: Mesh = mesh_instance.mesh
		if mesh == null:
			continue
		triangle_count += mesh.get_faces().size() / 3
	_expect(triangle_count >= MIN_TRIANGLES and triangle_count <= MAX_TRIANGLES,
			"total visual triangles stay within the 8,000 to 15,000 production-preparation budget")

	var material_names: Array[String] = []
	for mesh_instance: MeshInstance3D in mesh_instances:
		var mesh: Mesh = mesh_instance.mesh
		if mesh == null:
			continue
		for surface_index: int in range(mesh.get_surface_count()):
			var material: Material = mesh.surface_get_material(surface_index)
			if material != null:
				material_names.append(material.resource_name)
	for expected: String in EXPECTED_MATERIALS:
		_expect(expected in material_names,
				"expected surface material %s is present" % expected)

	var socket: Marker3D = dispenser.get_node_or_null("DispenseSocket")
	_expect(socket != null, "DispenseSocket remains on the dispenser root")
	if socket != null:
		_expect(socket.position.distance_to(SOCKET_ALIGNMENT) <= POSITION_TOLERANCE_M,
				"DispenseSocket stays aligned at y = 0.4, z = 1.1")

	_expect(not CollapseManager.is_active,
			"Collapse is inactive for the dispense check")
	var dispensed: Node = dispenser.dispense()
	_expect(dispensed != null,
			"dispense() creates Material while the Visual is hidden")
	if dispensed != null:
		_expect(dispensed is MaterialResource,
				"dispense() returns a MaterialResource")
		_expect(dispensed.global_position.distance_to(socket.global_position)
				<= POSITION_TOLERANCE_M,
				"dispensed Material appears at the socket")
		dispensed.queue_free()

	_finish(container)


func _mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		result.append(root)
	for child: Node in root.find_children("*", "MeshInstance3D", true, false):
		result.append(child)
	return result


func _collision_descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for type_name: String in ["CollisionShape3D", "PhysicsBody3D", "Area3D"]:
		for child: Node in root.find_children("*", type_name, true, false):
			result.append(child)
	return result


func _has_ancestor(node: Node, ancestor: Node) -> bool:
	var cursor: Node = node.get_parent()
	while cursor != null:
		if cursor == ancestor:
			return true
		cursor = cursor.get_parent()
	return false


func _visual_bounds(visual: Node3D, relative_to: Node3D) -> AABB:
	var inverse_root: Transform3D = relative_to.global_transform.affine_inverse()
	var bounds := AABB()
	var have_bounds := false
	for mesh_instance: MeshInstance3D in _mesh_instances(visual):
		var mesh: Mesh = mesh_instance.mesh
		if mesh == null:
			continue
		var local_bounds: AABB = mesh.get_aabb()
		var transform: Transform3D = inverse_root * mesh_instance.global_transform
		for corner_index: int in range(8):
			var corner: Vector3 = transform * local_bounds.get_endpoint(corner_index)
			if have_bounds:
				bounds = bounds.expand(corner)
			else:
				bounds = AABB(corner, Vector3.ZERO)
				have_bounds = true
	return bounds


func _finish(container: Node) -> void:
	container.queue_free()
	if _failures.is_empty():
		print("Material Dispenser visual boundary tests passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
