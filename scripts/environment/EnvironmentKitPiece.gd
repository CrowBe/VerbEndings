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


func _ready() -> void:
	_rebuild()


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


func set_collision_active(active: bool) -> void:
	collision_enabled = active
	var body: StaticBody3D = get_node_or_null("GameplayCollision")
	if body != null:
		body.collision_layer = 1 if active else 0
		body.collision_mask = 1 if active else 0


func _rebuild() -> void:
	for child: Node in get_children():
		child.queue_free()
	set_meta("kit_kind", KIND_NAMES[kind])
	set_meta("dimensions_m", dimensions)
	set_meta("origin_contract", &"floor_centred")
	set_meta("grid_increment_m", 1.0)
	if kind == Kind.DOOR_FRAME_4M:
		_build_door_frame()
	elif kind == Kind.COLUMN:
		_build_column()
	else:
		_build_box(&"Visual", dimensions, Vector3(0.0, dimensions.y * 0.5, 0.0))


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
