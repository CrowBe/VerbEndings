class_name CounterweightPlate
extends PuzzleUnit
## Counterweight Plate — shove loose crates onto the pressure plate until
## their combined resting mass crosses the target. Verb flavor: GROW-scaled
## shoves move the heaviest crates solo; lighter verbs ferry small crates.

const CRATE_COUNT: int = 5
const CRATE_SIZE: Vector3 = Vector3(0.8, 0.8, 0.8)
const CRATE_MASS: float = 20.0
const TARGET_MASS: float = 60.0
const SHOVE_IMPULSE: float = 60.0
const CRATE_SCATTER_RADIUS: float = 4.0

var _plate: Area3D
var _crates: Array[RigidBody3D] = []


func _ready() -> void:
	unit_name = "Counterweight Plate"
	_plate = _make_area_box(Vector3(2.5, 1.0, 2.5), Vector3(0.0, 0.5, 0.0))
	for i: int in CRATE_COUNT:
		var angle: float = TAU * i / CRATE_COUNT
		var pos := Vector3(
				cos(angle) * CRATE_SCATTER_RADIUS, CRATE_SIZE.y,
				sin(angle) * CRATE_SCATTER_RADIUS)
		_crates.append(_make_box_rigid(CRATE_SIZE, CRATE_MASS, pos))


func _physics_process(_delta: float) -> void:
	if is_completed:
		return
	var mass_on_plate: float = 0.0
	var overlapping: Array[Node3D] = _plate.get_overlapping_bodies()
	for crate: RigidBody3D in _crates:
		if crate in overlapping:
			mass_on_plate += crate.mass
	_set_progress(mass_on_plate / TARGET_MASS)


## A shove sends the crate nearest the player's aim toward the plate.
func _apply_interaction(power: float, direction: Vector3) -> void:
	var crate: RigidBody3D = _nearest_unplaced_crate()
	if crate == null:
		return
	var shove: Vector3 = direction
	if shove == Vector3.ZERO:
		shove = (_plate.global_position - crate.global_position).normalized()
	crate.apply_central_impulse(shove * SHOVE_IMPULSE * power)


func _nearest_unplaced_crate() -> RigidBody3D:
	var overlapping: Array[Node3D] = _plate.get_overlapping_bodies()
	var best: RigidBody3D = null
	var best_distance: float = INF
	for crate: RigidBody3D in _crates:
		if crate in overlapping:
			continue
		var distance: float = crate.global_position.distance_to(_plate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = crate
	return best
