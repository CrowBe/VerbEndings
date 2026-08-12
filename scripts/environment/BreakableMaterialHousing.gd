class_name BreakableMaterialHousing
extends StaticBody3D
## A hero-prop casing that trades damage-focused Verb use for Material.

signal housing_broken(housing: BreakableMaterialHousing, material_amount: float)

const MATERIAL_SCENE: PackedScene = preload("res://scenes/Material.tscn")

@export_range(1.0, 1000.0, 1.0) var durability: float = 20.0
@export_range(0.0, 100.0, 0.1) var contained_material: float = 25.0

@onready var release_socket: Marker3D = $ReleaseSocket

var remaining_durability: float
var is_broken: bool = false


func _ready() -> void:
	remaining_durability = durability


## Damage is authoritative and source-agnostic. Player Impacts and BURN's
## area effect both reach this method through the stable impact-receiver seam.
func take_hit(amount: float, _source = null) -> void:
	if is_broken or amount <= 0.0:
		return
	remaining_durability = maxf(remaining_durability - amount, 0.0)
	if remaining_durability > 0.0:
		return
	is_broken = true
	$CollisionShape3D.set_deferred("disabled", true)
	$Visual.visible = false
	var material_resource: MaterialResource = MATERIAL_SCENE.instantiate()
	material_resource.absorb_amount = contained_material
	get_parent().add_child(material_resource)
	material_resource.global_position = release_socket.global_position
	housing_broken.emit(self, contained_material)
