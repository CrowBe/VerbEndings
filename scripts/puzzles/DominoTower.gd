class_name DominoTower
extends PuzzleUnit
## Domino Tower — a stacked block tower that must be brought down. The unit
## completes when the crown block has dropped far enough that the tower is
## unambiguously toppled. Verb flavor: JUMP stomps the base loose, GROW
## body-checks the stack, BURN weakens it low, STRETCH pulls from the top.

const BLOCK_COUNT: int = 5
const BLOCK_SIZE: Vector3 = Vector3(1.2, 0.6, 1.2)
const BLOCK_MASS: float = 8.0
const TOPPLE_IMPULSE: float = 25.0
## The crown block must fall this fraction of the tower's height.
const TOPPLE_DROP_FRACTION: float = 0.6

var _blocks: Array[RigidBody3D] = []
var _crown_start_height: float = 0.0


func _ready() -> void:
	unit_name = "Domino Tower"
	for i: int in BLOCK_COUNT:
		var pos := Vector3(0.0, BLOCK_SIZE.y * (float(i) + 0.5), 0.0)
		_blocks.append(_make_box_rigid(BLOCK_SIZE, BLOCK_MASS, pos))
	_crown_start_height = _crown().position.y


func _physics_process(_delta: float) -> void:
	if is_completed:
		return
	var drop: float = _crown_start_height - _crown().position.y
	_set_progress(drop / (_crown_start_height * TOPPLE_DROP_FRACTION))


## Hit the tower: aim decides where; default is a broadside at the crown,
## the highest-leverage point.
func _apply_interaction(power: float, direction: Vector3) -> void:
	var hit: Vector3 = direction
	if hit == Vector3.ZERO:
		hit = Vector3.FORWARD
	hit.y = 0.0
	_crown().apply_central_impulse(hit.normalized() * TOPPLE_IMPULSE * power)


func _crown() -> RigidBody3D:
	var highest: RigidBody3D = _blocks[0]
	for block: RigidBody3D in _blocks:
		if block.position.y > highest.position.y:
			highest = block
	return highest
