class_name EnvironmentRound
extends Node3D
## Sustained Exposure controller for the Applied Attrition Laboratory.
## The atmosphere continuously drains every live Subject while the Semantic
## Engine and authored housings provide the only Material supply.

signal exposure_updated(player_id: int, survival_seconds: float,
		material_secured: float, performance: float)
signal subject_eliminated(player_id: int, survival_seconds: float)
signal round_finished(ordered_player_ids: Array)

## These five apparatus types are obstacles and traversal tools. Their state
## is physical only and never contributes to Experiment scoring.
const APPARATUS_TYPES: Array[Script] = [
	preload("res://scripts/puzzles/CounterweightPlate.gd"),
	preload("res://scripts/puzzles/WreckingPendulum.gd"),
	preload("res://scripts/puzzles/GravityFunnel.gd"),
	preload("res://scripts/puzzles/DominoTower.gd"),
	preload("res://scripts/puzzles/MomentumTurbine.gd"),
]
const MIN_APPARATUS_COUNT: int = 5
const APPARATUS_CLEARANCE: float = 12.0

@export_range(0.1, 100.0, 0.1) var atmospheric_stability_loss_per_second := 4.0
@export_range(0.0, 10.0, 0.05) var survival_weight := 1.0
@export_range(0.0, 10.0, 0.05) var material_weight := 0.35
@export var apparatus_count: int = 8
@export var scatter_half_extent: float = 20.0
@export var protocol: ExperimentProtocol = preload(
		"res://resources/protocols/sustained_exposure.tres")

## Subject-owned measurements for this Experiment.
var survival_seconds: Dictionary = {}
var material_secured: Dictionary = {}

var _subjects: Dictionary = {}
var _apparatus: Array[PuzzleUnit] = []


func _ready() -> void:
	_apply_authored_scoring_rules()
	_scatter_apparatus()
	_refresh_subjects()


func _physics_process(delta: float) -> void:
	apply_exposure(delta)


## Public deterministic seam used by the focused headless suite.
func apply_exposure(delta: float) -> void:
	if delta <= 0.0:
		return
	_refresh_subjects()
	for player_id: int in _subjects:
		var subject: Node = _subjects[player_id]
		if not is_instance_valid(subject) or subject.get("is_destabilised"):
			continue
		survival_seconds[player_id] = survival_seconds.get(player_id, 0.0) + delta
		subject.call("apply_hazard_stability_loss",
				atmospheric_stability_loss_per_second * delta, self)
		exposure_updated.emit(player_id, survival_seconds[player_id],
				material_secured.get(player_id, 0.0), get_performance(player_id))


## Ranks the authored blend of survival time and Material secured. Stable
## Subject id ordering resolves exact ties on every peer.
func end_round() -> void:
	var ordered: Array = get_ordered_placements()
	ScoreManager.award_protocol_placements(protocol, ordered)
	round_finished.emit(ordered)


func get_ordered_placements() -> Array:
	var ordered: Array = VerbChainManager.active_players.keys()
	if ordered.is_empty():
		ordered = survival_seconds.keys()
	ordered.sort_custom(func(a: int, b: int) -> bool:
		var score_a: float = get_performance(a)
		var score_b: float = get_performance(b)
		if not is_equal_approx(score_a, score_b):
			return score_a > score_b
		return a < b)
	return ordered


func get_performance(player_id: int) -> float:
	return survival_seconds.get(player_id, 0.0) * survival_weight \
			+ material_secured.get(player_id, 0.0) * material_weight


func get_apparatus() -> Array[PuzzleUnit]:
	return _apparatus.duplicate()


func _apply_authored_scoring_rules() -> void:
	survival_weight = float(protocol.scoring_rules.get(
			"survival_weight", survival_weight))
	material_weight = float(protocol.scoring_rules.get(
			"material_weight", material_weight))


func _refresh_subjects() -> void:
	for subject: Node in get_tree().get_nodes_in_group("players"):
		if not subject.has_method("apply_hazard_stability_loss"):
			continue
		var player_id: int = subject.get_multiplayer_authority()
		if _subjects.has(player_id):
			continue
		_subjects[player_id] = subject
		survival_seconds[player_id] = 0.0
		material_secured[player_id] = 0.0
		var material_callback := Callable(self, "_on_material_absorbed").bind(player_id)
		if subject.has_signal("material_absorbed") \
				and not subject.material_absorbed.is_connected(material_callback):
			subject.material_absorbed.connect(material_callback)
		var elimination_callback := Callable(self, "_on_subject_destabilised")
		if subject.has_signal("destabilised") \
				and not subject.destabilised.is_connected(elimination_callback):
			subject.destabilised.connect(elimination_callback)


func _on_material_absorbed(amount: float, player_id: int) -> void:
	material_secured[player_id] = material_secured.get(player_id, 0.0) + amount
	exposure_updated.emit(player_id, survival_seconds.get(player_id, 0.0),
			material_secured[player_id], get_performance(player_id))


func _on_subject_destabilised(subject: Node, source: Node) -> void:
	if source != self:
		return
	var player_id: int = subject.get_multiplayer_authority()
	VerbChainManager.sever_chain_for(player_id)
	subject_eliminated.emit(player_id, survival_seconds.get(player_id, 0.0))


func _scatter_apparatus() -> void:
	var count: int = maxi(apparatus_count, MIN_APPARATUS_COUNT)
	var placed: Array[Vector3] = []
	for i: int in count:
		var unit: PuzzleUnit = APPARATUS_TYPES[i % APPARATUS_TYPES.size()].new()
		unit.position = _pick_clear_position(placed)
		placed.append(unit.position)
		add_child(unit)
		_apparatus.append(unit)


func _pick_clear_position(placed: Array[Vector3]) -> Vector3:
	# Rejection-sample a spot with clearance; give up gracefully after a
	# few tries so a crowded scatter area still fills.
	for _attempt: int in 20:
		var candidate := Vector3(
				randf_range(-scatter_half_extent, scatter_half_extent), 0.0,
				randf_range(-scatter_half_extent, scatter_half_extent))
		var clear: bool = true
		for existing: Vector3 in placed:
			if candidate.distance_to(existing) < APPARATUS_CLEARANCE:
				clear = false
				break
		if clear:
			return candidate
	return Vector3(
			randf_range(-scatter_half_extent, scatter_half_extent), 0.0,
			randf_range(-scatter_half_extent, scatter_half_extent))
