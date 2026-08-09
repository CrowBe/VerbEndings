class_name PuzzleUnit
extends Node3D
## Base class for the PUZZLE round's small scorable units.
##
## Each unit is a self-contained physics toy scattered across the Round's
## scatter area.
## Progress runs 0..1; on completion, every player who contributed gains a
## completion (PuzzleRound handles scoring — players chase a high completion
## COUNT, not a single big finish).
##
## ANY verb adds value: every VerbType has an assist profile that scales the
## force of that player's interactions, so no verb is dead weight at any
## unit. Subclasses build their own greybox physics bodies in _ready() via
## the helpers below and override _apply_interaction().
##
## NETWORK: Physics simulation is server-authoritative; progress and
## completion are broadcast via the RPC hooks on the signals.

## NETWORK: @rpc replication hook — broadcast for per-unit progress bars.
signal progress_changed(unit: PuzzleUnit, progress: float)
## NETWORK: @rpc replication hook — broadcast; PuzzleRound scores it.
signal puzzle_completed(unit: PuzzleUnit, contributor_ids: Array)

## Verb assist profiles: interaction force multiplier + flavor text.
## Every verb is at least 1.0, so any pair composition can clear any unit —
## some verbs just clear certain units faster.
const VERB_ASSISTS: Dictionary = {
	Enums.VerbType.NONE: {"power": 1.0, "assist": "bare hands"},
	Enums.VerbType.BURN: {"power": 1.35, "assist": "thermal jets add thrust"},
	Enums.VerbType.SHIELD: {"power": 1.2, "assist": "braced push, zero recoil"},
	Enums.VerbType.GROW: {"power": 1.5, "assist": "raw mass advantage"},
	Enums.VerbType.STRETCH: {"power": 1.3, "assist": "long-reach leverage"},
	Enums.VerbType.ROLL: {"power": 1.45, "assist": "momentum transfer"},
	Enums.VerbType.JUMP: {"power": 1.25, "assist": "drop-impact stomps"},
	Enums.VerbType.BOUNCE: {"power": 1.4, "assist": "restitution doubling"},
	Enums.VerbType.FREEZE: {"power": 1.2, "assist": "friction control"},
	Enums.VerbType.REWIND: {"power": 1.3, "assist": "undo a bad shove"},
}

@export var unit_name: String = "Puzzle Unit"

## NETWORK: @rpc replication hook — sync both to all peers.
var is_completed: bool = false
var progress: float = 0.0

## Players who touched this unit before it completed; all of them score.
var _contributor_ids: Array[int] = []


## Group registration lives in _enter_tree (not _ready) so subclasses can
## override _ready without needing a super() call. Player._nearest_puzzle_unit
## finds units through this group.
func _enter_tree() -> void:
	add_to_group("puzzle_units")


## Simulated RPC hook: a player interacts with the unit (shove, stomp,
## spin — the subclass decides). `direction` is the player's aim; ZERO lets
## the subclass pick a sensible default (usually "toward the goal").
## NETWORK: @rpc replication hook — becomes @rpc("any_peer", "reliable");
## server validates range/liveness before applying.
func interact(player_id: int, verb: Enums.VerbType, direction: Vector3 = Vector3.ZERO) -> void:
	if is_completed:
		return
	if player_id not in _contributor_ids:
		_contributor_ids.append(player_id)
	_apply_interaction(get_verb_power(verb), direction)


func get_verb_power(verb: Enums.VerbType) -> float:
	return VERB_ASSISTS.get(verb, {"power": 1.0}).power


## Subclass hook: turn one verb-scaled interaction into physics.
func _apply_interaction(_power: float, _direction: Vector3) -> void:
	pass


## Subclasses report progress through here; crossing 1.0 completes the unit.
func _set_progress(value: float) -> void:
	if is_completed:
		return
	progress = clampf(value, 0.0, 1.0)
	progress_changed.emit(self, progress)
	if progress >= 1.0:
		is_completed = true
		puzzle_completed.emit(self, _contributor_ids.duplicate())


## --- Greybox body builders ---------------------------------------------
## Shared placeholder construction so every unit is playable with zero art.

func _make_box_rigid(size: Vector3, mass: float, local_pos: Vector3) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = mass
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	body.add_child(mesh)
	body.position = local_pos
	add_child(body)
	return body


func _make_sphere_rigid(radius: float, mass: float, local_pos: Vector3) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = mass
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	mesh.mesh = sphere_mesh
	body.add_child(mesh)
	body.position = local_pos
	add_child(body)
	return body


func _make_static_box(size: Vector3, local_pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	body.add_child(mesh)
	body.position = local_pos
	add_child(body)
	return body


func _make_area_box(size: Vector3, local_pos: Vector3) -> Area3D:
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	area.position = local_pos
	add_child(area)
	return area
