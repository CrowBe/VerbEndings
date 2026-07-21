class_name WreckingPendulum
extends PuzzleUnit
## Wrecking Pendulum — a heavy bob hangs from a pin joint. Players pump the
## swing with well-timed shoves until the bob's arc is wide enough to count
## as smashing the brittle target wall. Verb flavor: ROLL/BOUNCE transfer
## momentum into the pump; STRETCH shoves from safely outside the arc.

const ANCHOR_HEIGHT: float = 5.0
const BOB_RADIUS: float = 0.6
const BOB_MASS: float = 40.0
const PUMP_IMPULSE: float = 45.0
## Horizontal displacement of the bob that completes the smash.
const TARGET_SWING: float = 3.5

var _bob: RigidBody3D
var _best_swing: float = 0.0


func _ready() -> void:
	unit_name = "Wrecking Pendulum"
	var anchor: StaticBody3D = _make_static_box(
			Vector3(0.4, 0.4, 0.4), Vector3(0.0, ANCHOR_HEIGHT, 0.0))
	_bob = _make_sphere_rigid(
			BOB_RADIUS, BOB_MASS, Vector3(0.0, ANCHOR_HEIGHT - 3.0, 0.0))
	# The brittle target wall the arc must reach.
	_make_static_box(Vector3(0.3, 2.0, 2.0), Vector3(TARGET_SWING + 0.5, 1.0, 0.0))
	var joint := PinJoint3D.new()
	joint.position = Vector3(0.0, ANCHOR_HEIGHT, 0.0)
	add_child(joint)
	joint.node_a = joint.get_path_to(anchor)
	joint.node_b = joint.get_path_to(_bob)


func _physics_process(_delta: float) -> void:
	if is_completed:
		return
	var horizontal: Vector3 = _bob.global_position - global_position
	horizontal.y = 0.0
	# Progress only ratchets up — a decaying swing keeps its best arc.
	_best_swing = maxf(_best_swing, horizontal.length())
	_set_progress(_best_swing / TARGET_SWING)


## Pump the swing: push the bob along the aim (or its current travel).
func _apply_interaction(power: float, direction: Vector3) -> void:
	var pump: Vector3 = direction
	if pump == Vector3.ZERO:
		pump = _bob.linear_velocity.normalized()
		if pump == Vector3.ZERO:
			pump = Vector3.RIGHT
	pump.y = 0.0
	_bob.apply_central_impulse(pump.normalized() * PUMP_IMPULSE * power)
