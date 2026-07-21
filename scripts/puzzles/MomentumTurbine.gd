class_name MomentumTurbine
extends PuzzleUnit
## Momentum Turbine — a free-spinning rotor that must be driven through a
## number of full revolutions. Spin decays, so players keep feeding it.
## Verb flavor: ROLL couples momentum straight in (the signature synergy),
## BOUNCE ricochets impacts into spin, FREEZE lowers the bearing friction.

const ROTOR_SIZE: Vector3 = Vector3(3.0, 0.3, 0.4)
const ROTOR_MASS: float = 12.0
const SPIN_TORQUE: float = 30.0
const TARGET_ROTATIONS: float = 6.0
## Bearing drag: fraction of angular velocity lost per second.
const SPIN_DECAY: float = 0.15

var _rotor: RigidBody3D
var _accumulated_radians: float = 0.0


func _ready() -> void:
	unit_name = "Momentum Turbine"
	_rotor = _make_box_rigid(ROTOR_SIZE, ROTOR_MASS, Vector3(0.0, 1.2, 0.0))
	# Pin the hub in place: the rotor may only spin around Y.
	_rotor.axis_lock_linear_x = true
	_rotor.axis_lock_linear_y = true
	_rotor.axis_lock_linear_z = true
	_rotor.axis_lock_angular_x = true
	_rotor.axis_lock_angular_z = true
	_rotor.gravity_scale = 0.0


func _physics_process(delta: float) -> void:
	if is_completed:
		return
	var spin: float = absf(_rotor.angular_velocity.y)
	_accumulated_radians += spin * delta
	_rotor.angular_velocity.y *= 1.0 - SPIN_DECAY * delta
	_set_progress(_accumulated_radians / (TAU * TARGET_ROTATIONS))


## Feed the rotor. Aim direction sets spin sense; default keeps whatever
## direction it already turns (or clockwise from rest).
func _apply_interaction(power: float, direction: Vector3) -> void:
	var sense: float = signf(direction.x + direction.z)
	if sense == 0.0:
		sense = signf(_rotor.angular_velocity.y)
	if sense == 0.0:
		sense = 1.0
	_rotor.apply_torque_impulse(Vector3(0.0, sense * SPIN_TORQUE * power, 0.0))
