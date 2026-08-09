class_name GravityFunnel
extends PuzzleUnit
## Gravity Funnel — loose balls are scattered around a sunken catch basin;
## herd enough of them in to complete the unit. Verb flavor: ROLL steers
## balls mid-travel, FREEZE removes overshoot friction, BOUNCE banks shots in
## off the rim.

const BALL_COUNT: int = 6
const BALLS_NEEDED: int = 4
const BALL_RADIUS: float = 0.35
const BALL_MASS: float = 3.0
const HERD_IMPULSE: float = 9.0
const SCATTER_RADIUS: float = 5.0

var _basin: Area3D
var _balls: Array[RigidBody3D] = []
var _banked_count: int = 0


func _ready() -> void:
	unit_name = "Gravity Funnel"
	# Catch basin: straddles floor level so ground-rolling balls overlap it.
	_basin = _make_area_box(Vector3(2.0, 1.0, 2.0), Vector3(0.0, 0.0, 0.0))
	_basin.body_entered.connect(_on_basin_entered)
	for i: int in BALL_COUNT:
		var angle: float = TAU * i / BALL_COUNT
		var pos := Vector3(
				cos(angle) * SCATTER_RADIUS, BALL_RADIUS,
				sin(angle) * SCATTER_RADIUS)
		_balls.append(_make_sphere_rigid(BALL_RADIUS, BALL_MASS, pos))


## Herd the ball nearest the basin the rest of the way in.
func _apply_interaction(power: float, direction: Vector3) -> void:
	var ball: RigidBody3D = _nearest_loose_ball()
	if ball == null:
		return
	var herd: Vector3 = direction
	if herd == Vector3.ZERO:
		herd = (_basin.global_position - ball.global_position).normalized()
	ball.apply_central_impulse(herd * HERD_IMPULSE * power)


func _on_basin_entered(body: Node3D) -> void:
	var ball := body as RigidBody3D
	if is_completed or ball == null or ball not in _balls:
		return
	_balls.erase(ball)
	_banked_count += 1
	_set_progress(float(_banked_count) / BALLS_NEEDED)


func _nearest_loose_ball() -> RigidBody3D:
	var best: RigidBody3D = null
	var best_distance: float = INF
	for ball: RigidBody3D in _balls:
		var distance: float = ball.global_position.distance_to(_basin.global_position)
		if distance < best_distance:
			best_distance = distance
			best = ball
	return best
