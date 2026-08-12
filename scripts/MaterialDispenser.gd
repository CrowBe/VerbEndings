class_name MaterialDispenser
extends Node3D
## Facility apparatus that supplies Material during non-combat Experiments.
## The Semantic Engine is offline during the Collapse, so dispensing stops.

const MATERIAL_SCENE: PackedScene = preload("res://scenes/Material.tscn")

@export_range(0.1, 60.0, 0.1) var dispense_interval: float = 12.0
@export_range(0.0, 100.0, 0.1) var dispense_amount: float = 15.0
## Every Applied Attrition dispenser names the non-walking route required to
## reach it. The controller validates that it is also physically elevated.
@export var traversal_route: StringName = &""

@onready var dispense_socket: Marker3D = $DispenseSocket

var _dispense_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if CollapseManager.is_active:
		_dispense_timer = 0.0
		return
	_dispense_timer += delta
	if _dispense_timer >= dispense_interval:
		_dispense_timer = 0.0
		dispense()


func dispense() -> MaterialResource:
	if CollapseManager.is_active:
		return null
	var material_resource: MaterialResource = MATERIAL_SCENE.instantiate()
	material_resource.absorb_amount = dispense_amount
	get_parent().add_child(material_resource)
	material_resource.global_position = dispense_socket.global_position
	return material_resource
