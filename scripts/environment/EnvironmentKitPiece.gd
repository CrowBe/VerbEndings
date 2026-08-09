class_name EnvironmentKitPiece
extends Node3D
## Runtime-configurable greybox kit piece with a floor-centred origin.
##
## The visual and gameplay collision are deliberately separate children so a
## later presentation asset can replace Visual without changing collision.

enum Kind {
	FLOOR_BAY,
	WALL_BAY,
	RADIAL_FLOOR_SEGMENT,
	ANNULAR_FLOOR_SEGMENT,
	DOME_SHELL_BAY,
	SPINE_JUNCTION,
	DOOR_FRAME_4M,
	SHUTTER_4M,
	DECK_RAIL,
	COLUMN,
	TRUSS,
	VENT,
	PANEL,
}

const KIND_NAMES: Array[StringName] = [
	&"FloorBay",
	&"WallBay",
	&"RadialFloorSegment",
	&"AnnularFloorSegment",
	&"DomeShellBay",
	&"SpineJunction",
	&"DoorFrame4m",
	&"Shutter4m",
	&"DeckRail",
	&"Column",
	&"Truss",
	&"Vent",
	&"Panel",
]

@export var kind: Kind = Kind.FLOOR_BAY
@export var dimensions: Vector3 = Vector3(2.0, 0.5, 2.0)
@export var collision_enabled: bool = true
@export var greybox_colour: Color = Color("c8ced1")
@export var annular_radius_m: float = 0.0
@export var annular_module_degrees: float = 0.0


func _ready() -> void:
	_rebuild()


func _exit_tree() -> void:
	_detach_visual_meshes()


func configure(
		new_kind: Kind,
		new_dimensions: Vector3,
		new_colour: Color = Color("c8ced1"),
		with_collision: bool = true,
) -> EnvironmentKitPiece:
	kind = new_kind
	dimensions = new_dimensions
	greybox_colour = new_colour
	collision_enabled = with_collision
	set_meta("kit_kind", KIND_NAMES[kind])
	set_meta("dimensions_m", dimensions)
	set_meta("origin_contract", &"floor_centred")
	set_meta("grid_increment_m", 1.0)
	return self


func configure_annular(
	radius_m: float,
	module_degrees: float,
) -> EnvironmentKitPiece:
	annular_radius_m = radius_m
	annular_module_degrees = module_degrees
	set_meta("annular_radius_m", annular_radius_m)
	set_meta("radial_module_degrees", annular_module_degrees)
	return self


func set_collision_active(active: bool) -> void:
	collision_enabled = active
	var body: StaticBody3D = get_node_or_null("GameplayCollision")
	if body != null:
		body.collision_layer = 1 if active else 0
		body.collision_mask = 1 if active else 0


func _rebuild() -> void:
	_detach_visual_meshes()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	set_meta("kit_kind", KIND_NAMES[kind])
	set_meta("dimensions_m", dimensions)
	set_meta("origin_contract", &"floor_centred")
	set_meta("grid_increment_m", 1.0)
	if annular_radius_m > 0.0 and annular_module_degrees > 0.0:
		_build_annular_prism()
	elif kind == Kind.DOOR_FRAME_4M:
		_build_door_frame()
	elif kind == Kind.COLUMN:
		_build_column()
	else:
		_build_box(&"Visual", dimensions, Vector3(0.0, dimensions.y * 0.5, 0.0))


func _detach_visual_meshes() -> void:
	# Procedural Mesh resources are otherwise released while their
	# MeshInstance3D children are being destroyed. Godot 4.3's headless
	# renderer can then inspect an already-freed mesh RID during teardown.
	for child: Node in get_children():
		if child is MeshInstance3D:
			child.mesh = null


func _build_annular_prism() -> void:
	var faces := PackedVector3Array()
	var subdivision_count: int = maxi(1, ceili(annular_module_degrees / 5.0))
	var half_angle: float = deg_to_rad(annular_module_degrees * 0.5)
	var step_angle: float = deg_to_rad(
			annular_module_degrees / subdivision_count)
	var inner_radius: float = annular_radius_m - dimensions.z * 0.5
	var outer_radius: float = annular_radius_m + dimensions.z * 0.5
	for index: int in subdivision_count:
		var start_angle: float = -half_angle + index * step_angle
		var end_angle: float = start_angle + step_angle
		var inner_start := _annular_point(inner_radius, start_angle)
		var outer_start := _annular_point(outer_radius, start_angle)
		var inner_end := _annular_point(inner_radius, end_angle)
		var outer_end := _annular_point(outer_radius, end_angle)
		var inner_start_top := inner_start + Vector3.UP * dimensions.y
		var outer_start_top := outer_start + Vector3.UP * dimensions.y
		var inner_end_top := inner_end + Vector3.UP * dimensions.y
		var outer_end_top := outer_end + Vector3.UP * dimensions.y
		_append_triangle(
				faces, inner_start_top, outer_end_top, outer_start_top)
		_append_triangle(
				faces, inner_start_top, inner_end_top, outer_end_top)
		_append_triangle(faces, inner_start, outer_start, outer_end)
		_append_triangle(faces, inner_start, outer_end, inner_end)
		_append_quad(
				faces, outer_start, outer_start_top, outer_end_top, outer_end)
		_append_quad(
				faces, inner_start, inner_end, inner_end_top, inner_start_top)
		if index == 0:
			_append_quad(
					faces,
					inner_start,
					inner_start_top,
					outer_start_top,
					outer_start)
		if index == subdivision_count - 1:
			_append_quad(
					faces, inner_end, outer_end, outer_end_top, inner_end_top)

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex: Vector3 in faces:
		surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh := surface.commit()
	mesh.surface_set_material(0, _material())
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Visual"
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	if not collision_enabled:
		return
	var body := StaticBody3D.new()
	body.name = "GameplayCollision"
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _annular_point(radius: float, angle: float) -> Vector3:
	return Vector3(
			sin(angle) * radius,
			0.0,
			annular_radius_m - cos(angle) * radius)


func _append_quad(
	faces: PackedVector3Array,
	first: Vector3,
	second: Vector3,
	third: Vector3,
	fourth: Vector3,
) -> void:
	_append_triangle(faces, first, second, third)
	_append_triangle(faces, first, third, fourth)


func _append_triangle(
	faces: PackedVector3Array,
	first: Vector3,
	second: Vector3,
	third: Vector3,
) -> void:
	faces.append(first)
	faces.append(second)
	faces.append(third)


func _build_door_frame() -> void:
	var opening_width: float = maxf(dimensions.x, 4.0)
	var opening_height: float = maxf(dimensions.y, 4.5)
	var depth: float = maxf(dimensions.z, 1.0)
	var jamb_width: float = 1.0
	var header_height: float = 1.0
	_build_box(&"LeftJamb", Vector3(jamb_width, opening_height + header_height, depth),
			Vector3(-(opening_width + jamb_width) * 0.5,
					(opening_height + header_height) * 0.5, 0.0))
	_build_box(&"RightJamb", Vector3(jamb_width, opening_height + header_height, depth),
			Vector3((opening_width + jamb_width) * 0.5,
					(opening_height + header_height) * 0.5, 0.0))
	_build_box(&"Header", Vector3(opening_width, header_height, depth),
			Vector3(0.0, opening_height + header_height * 0.5, 0.0))
	set_meta("clear_opening_m", Vector2(opening_width, opening_height))


func _build_column() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Visual"
	var mesh := CylinderMesh.new()
	mesh.top_radius = dimensions.x * 0.5
	mesh.bottom_radius = dimensions.z * 0.5
	mesh.height = dimensions.y
	mesh.radial_segments = 12
	mesh.material = _material()
	mesh_instance.mesh = mesh
	mesh_instance.position.y = dimensions.y * 0.5
	add_child(mesh_instance)
	if not collision_enabled:
		return
	var body := StaticBody3D.new()
	body.name = "GameplayCollision"
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := CylinderShape3D.new()
	shape.radius = maxf(dimensions.x, dimensions.z) * 0.5
	shape.height = dimensions.y
	collision.shape = shape
	collision.position.y = dimensions.y * 0.5
	body.add_child(collision)
	add_child(body)


func _build_box(node_name: StringName, size: Vector3, offset: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material()
	mesh_instance.mesh = mesh
	mesh_instance.position = offset
	add_child(mesh_instance)
	if not collision_enabled:
		return
	var body: StaticBody3D = get_node_or_null("GameplayCollision")
	if body == null:
		body = StaticBody3D.new()
		body.name = "GameplayCollision"
		add_child(body)
	var collision := CollisionShape3D.new()
	collision.name = "%sCollision" % node_name
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = offset
	body.add_child(collision)


func _material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = greybox_colour
	material.roughness = 0.82
	return material
