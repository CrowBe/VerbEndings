extends Node3D
## PUZZLE round controller. Scatters at least MIN_UNIT_COUNT small physics
## puzzle units through the arena; players (still tethered to their pair)
## race to rack up the highest COMPLETION COUNT before the timer ends.
##
## PVP is disabled for this round — RoundManager.is_pvp_enabled() returns
## false whenever the current round type is not "PVP", and Player.apply_impact
## drops player-on-player hits accordingly. Nothing here needs to opt out.
##
## NETWORK: The server owns unit placement (positions must be rolled once
## and replicated, never rolled per-client) and all scoring.

## NETWORK: @rpc replication hook — broadcast for the completion-count HUD.
signal completion_scored(player_id: int, new_count: int)
## NETWORK: @rpc replication hook — broadcast the final round placements.
signal round_finished(ordered_player_ids: Array)

## One of each type per cycle; extras keep cycling through the list.
const PUZZLE_TYPES: Array[Script] = [
	preload("res://scripts/puzzles/CounterweightPlate.gd"),
	preload("res://scripts/puzzles/WreckingPendulum.gd"),
	preload("res://scripts/puzzles/GravityFunnel.gd"),
	preload("res://scripts/puzzles/DominoTower.gd"),
	preload("res://scripts/puzzles/MomentumTurbine.gd"),
]
const MIN_UNIT_COUNT: int = 5
## Keeps scattered units from overlapping each other's graybox footprints.
const UNIT_CLEARANCE: float = 12.0

@export var unit_count: int = 8
@export var arena_half_extent: float = 45.0

## player_id -> puzzle units completed (contributed to).
## NETWORK: @rpc replication hook — sync to all peers.
var completion_counts: Dictionary = {}

var _units: Array[PuzzleUnit] = []


func _ready() -> void:
	_scatter_units()


## Rolls scatter positions and instances the units. Server-side only; the
## resulting layout is what gets replicated to clients.
func _scatter_units() -> void:
	var count: int = maxi(unit_count, MIN_UNIT_COUNT)
	var placed: Array[Vector3] = []
	for i: int in count:
		var unit: PuzzleUnit = PUZZLE_TYPES[i % PUZZLE_TYPES.size()].new()
		unit.position = _pick_clear_position(placed)
		placed.append(unit.position)
		unit.puzzle_completed.connect(_on_unit_completed)
		add_child(unit)
		_units.append(unit)


## Ends the round: placements by completion count, best first. Ties break
## by player id for determinism. Everyone registered gets ranked, including
## players on zero completions.
## NETWORK: @rpc replication hook — server-side, on round timer expiry.
func end_round() -> void:
	var ordered: Array = VerbChainManager.active_players.keys()
	ordered.sort_custom(func(a: int, b: int) -> bool:
		var count_a: int = completion_counts.get(a, 0)
		var count_b: int = completion_counts.get(b, 0)
		if count_a != count_b:
			return count_a > count_b
		return a < b)
	ScoreManager.award_placements("PUZZLE", ordered)
	round_finished.emit(ordered)


func get_completed_unit_count() -> int:
	var total: int = 0
	for unit: PuzzleUnit in _units:
		if unit.is_completed:
			total += 1
	return total


func _on_unit_completed(_unit: PuzzleUnit, contributor_ids: Array) -> void:
	for player_id: int in contributor_ids:
		completion_counts[player_id] = completion_counts.get(player_id, 0) + 1
		ScoreManager.award_bonus(player_id, "PUZZLE", "unit_complete")
		completion_scored.emit(player_id, completion_counts[player_id])


func _pick_clear_position(placed: Array[Vector3]) -> Vector3:
	# Rejection-sample a spot with clearance; give up gracefully after a
	# few tries so a crowded arena still fills.
	for _attempt: int in 20:
		var candidate := Vector3(
				randf_range(-arena_half_extent, arena_half_extent), 0.0,
				randf_range(-arena_half_extent, arena_half_extent))
		var clear: bool = true
		for existing: Vector3 in placed:
			if candidate.distance_to(existing) < UNIT_CLEARANCE:
				clear = false
				break
		if clear:
			return candidate
	return Vector3(
			randf_range(-arena_half_extent, arena_half_extent), 0.0,
			randf_range(-arena_half_extent, arena_half_extent))
