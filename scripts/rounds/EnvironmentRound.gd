class_name EnvironmentRound
extends ExperimentController
## Sustained Exposure controller for the Applied Attrition Laboratory.
## The atmosphere continuously drains every live Subject while the Semantic
## Engine and authored housings provide the only Material supply.

signal exposure_updated(player_id: int, survival_seconds: float,
		material_secured: float, performance: float)

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

## Subject-owned measurements for this Experiment.
var survival_seconds: Dictionary = {}
var material_secured: Dictionary = {}

var _apparatus: Array[PuzzleUnit] = []


func _ready() -> void:
	_scatter_apparatus()
	super._ready()


func _default_protocol() -> ExperimentProtocol:
	return preload("res://resources/protocols/sustained_exposure.tres")


func _physics_process(delta: float) -> void:
	if not NetworkSession.can_simulate():
		return
	apply_exposure(delta)


## Public deterministic seam used by the focused headless suite.
func apply_exposure(delta: float) -> void:
	if delta <= 0.0:
		return
	refresh_subjects()
	for player_id: int in subject_bodies():
		var subject: Node = subject_bodies()[player_id]
		if not is_instance_valid(subject) or subject.get("is_destabilised") \
				or not subject.has_method("apply_hazard_stability_loss"):
			continue
		survival_seconds[player_id] = survival_seconds.get(player_id, 0.0) + delta
		subject.call("apply_hazard_stability_loss",
				atmospheric_stability_loss_per_second * delta, self)
		exposure_updated.emit(player_id, survival_seconds[player_id],
				material_secured.get(player_id, 0.0), get_performance(player_id))


## Ranks the authored blend of survival time and Material secured.
func get_performance(player_id: int) -> float:
	return survival_seconds.get(player_id, 0.0) * survival_weight \
			+ material_secured.get(player_id, 0.0) * material_weight


func get_apparatus() -> Array[PuzzleUnit]:
	return _apparatus.duplicate()


func _configure_from_protocol() -> void:
	survival_weight = float(protocol.scoring_rules.get(
			"survival_weight", survival_weight))
	material_weight = float(protocol.scoring_rules.get(
			"material_weight", material_weight))


func _on_subject_registered(player_id: int, subject: Node) -> void:
	survival_seconds[player_id] = 0.0
	material_secured[player_id] = 0.0
	var material_callback := Callable(self, "_on_material_absorbed").bind(player_id)
	if subject.has_signal("material_absorbed") \
			and not subject.material_absorbed.is_connected(material_callback):
		subject.material_absorbed.connect(material_callback)


func _on_material_absorbed(amount: float, player_id: int) -> void:
	material_secured[player_id] = material_secured.get(player_id, 0.0) + amount
	exposure_updated.emit(player_id, survival_seconds.get(player_id, 0.0),
			material_secured[player_id], get_performance(player_id))


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
