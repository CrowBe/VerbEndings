class_name ContainmentTool
extends StaticBody3D
## A Subject-operated Adaptive Containment tool.
##
## Tools expose the same Impact/interact seam as other environment apparatus,
## while PVERound owns their effect on the current encounter. The Compound
## owns placement and presentation so the tools persist with the Laboratory.

signal activated(tool: ContainmentTool)
signal active_state_changed(tool: ContainmentTool, active: bool)

const EFFECT_BAIT: StringName = &"bait"
const EFFECT_SHUTTER: StringName = &"shutter"
const EFFECT_POWER: StringName = &"power"

@export var effect_id: StringName = &""
@export_range(0.1, 60.0, 0.1) var active_seconds: float = 6.0
@export_range(0.1, 60.0, 0.1) var cooldown_seconds: float = 10.0
@export var linked_opening_ids: Array[StringName] = []

var active_time_remaining: float = 0.0
var cooldown_time_remaining: float = 0.0

@onready var active_cue: MeshInstance3D = $ActiveCue


func _enter_tree() -> void:
	add_to_group("environment_apparatus")
	add_to_group("impact_receivers")
	add_to_group("containment_tools")


func _ready() -> void:
	_update_presentation()


func _physics_process(delta: float) -> void:
	var was_active: bool = is_active()
	active_time_remaining = maxf(active_time_remaining - delta, 0.0)
	cooldown_time_remaining = maxf(cooldown_time_remaining - delta, 0.0)
	if was_active and not is_active():
		_update_presentation()
		active_state_changed.emit(self, false)


func configure(
	p_effect_id: StringName,
	p_active_seconds: float,
	p_cooldown_seconds: float,
	p_linked_opening_ids: Array[StringName] = [],
) -> void:
	effect_id = p_effect_id
	active_seconds = p_active_seconds
	cooldown_seconds = p_cooldown_seconds
	linked_opening_ids = p_linked_opening_ids.duplicate()


## A basic Impact and the general apparatus interaction both reach this seam.
func take_hit(amount: float, _source: Node = null) -> void:
	if amount > 0.0:
		activate()


func interact(_verb: Enums.VerbType, _direction: Vector3 = Vector3.ZERO) -> void:
	activate()


func activate() -> bool:
	if not NetworkSession.can_simulate() or cooldown_time_remaining > 0.0:
		return false
	active_time_remaining = active_seconds
	cooldown_time_remaining = cooldown_seconds
	_update_presentation()
	activated.emit(self)
	active_state_changed.emit(self, true)
	return true


func is_active() -> bool:
	return active_time_remaining > 0.0


func reset() -> void:
	var was_active: bool = is_active()
	active_time_remaining = 0.0
	cooldown_time_remaining = 0.0
	_update_presentation()
	if was_active:
		active_state_changed.emit(self, false)


func snapshot() -> Dictionary:
	return {
		"name": name,
		"active_time": active_time_remaining,
		"cooldown_time": cooldown_time_remaining,
	}


func apply_replicated_state(state: Dictionary) -> void:
	var was_active: bool = is_active()
	active_time_remaining = maxf(float(state.get("active_time", 0.0)), 0.0)
	cooldown_time_remaining = maxf(float(state.get("cooldown_time", 0.0)), 0.0)
	_update_presentation()
	if is_active() != was_active:
		active_state_changed.emit(self, is_active())


func _update_presentation() -> void:
	if is_node_ready():
		active_cue.visible = is_active()
