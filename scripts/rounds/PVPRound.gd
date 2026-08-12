extends Node3D
## Competitive Stress round controller. Subjects contest one open impact
## crucible while measurement pylons sample displacement and resilience.
##
## NETWORK: The host owns metric sampling, Destabilisation, Recall and scoring.

signal metrics_updated(player_id: int, dominance: float, displacement: float,
		resilience: float)
signal round_finished(ordered_player_ids: Array)

const SAMPLE_INTERVAL: float = 0.25
const DOMINANCE_RADIUS: float = 12.0
const DOMINANCE_WEIGHT: float = 3.0
const DISPLACEMENT_WEIGHT: float = 1.0
const RESILIENCE_WEIGHT: float = 0.5
const BASELINE_STABILITY: float = 100.0

@export var protocol: ExperimentProtocol = preload(
		"res://resources/protocols/competitive_stress.tres")

## Subject-owned measurements for the current Experiment.
var dominance_seconds: Dictionary = {}
var displacement_metres: Dictionary = {}
var resilience_samples: Dictionary = {}

var _sample_timer: float = 0.0
var _previous_positions: Dictionary = {}


func _ready() -> void:
	for body: Node in get_tree().get_nodes_in_group("players"):
		_register_subject(body)


func _physics_process(delta: float) -> void:
	_sample_timer += delta
	if _sample_timer < SAMPLE_INTERVAL:
		return
	var sample_delta: float = _sample_timer
	_sample_timer = 0.0
	for body: Node in get_tree().get_nodes_in_group("players"):
		if not _previous_positions.has(body):
			_register_subject(body)
		_sample_subject(body, sample_delta)


func end_round() -> void:
	var ordered: Array = VerbChainManager.active_players.keys()
	ordered.sort_custom(func(a: int, b: int) -> bool:
		var score_a: float = _round_metric(a)
		var score_b: float = _round_metric(b)
		if score_a != score_b:
			return score_a > score_b
		return a < b)
	ScoreManager.award_placements("PVP", ordered)
	round_finished.emit(ordered)


func _register_subject(body: Node) -> void:
	if not body is Node3D:
		return
	_previous_positions[body] = body.global_position
	if body.has_signal("destabilised") \
			and not body.destabilised.is_connected(_on_subject_destabilised):
		body.destabilised.connect(_on_subject_destabilised)


func _sample_subject(body: Node3D, sample_delta: float) -> void:
	var player_id: int = body.get_multiplayer_authority()
	var previous: Vector3 = _previous_positions.get(body, body.global_position)
	displacement_metres[player_id] = displacement_metres.get(player_id, 0.0) \
			+ body.global_position.distance_to(previous)
	_previous_positions[body] = body.global_position

	if not body.get("is_destabilised"):
		var local_position: Vector3 = to_local(body.global_position)
		var floor_position := Vector2(local_position.x, local_position.z)
		if floor_position.length() <= DOMINANCE_RADIUS:
			dominance_seconds[player_id] = dominance_seconds.get(player_id, 0.0) \
					+ sample_delta
		var stability: float = body.get("stability")
		resilience_samples[player_id] = resilience_samples.get(player_id, 0.0) \
				+ stability / BASELINE_STABILITY * sample_delta

	metrics_updated.emit(player_id, dominance_seconds.get(player_id, 0.0),
			displacement_metres.get(player_id, 0.0),
			resilience_samples.get(player_id, 0.0))


func _on_subject_destabilised(player: Node, source: Node) -> void:
	if source != null and source.is_in_group("players"):
		ScoreManager.award_bonus(source.get_multiplayer_authority(), "PVP",
				"knockout")
	if not CollapseManager.is_active:
		var eligible_count: int = 0
		for body: Node in get_tree().get_nodes_in_group("players"):
			if not body.get("is_destabilised"):
				eligible_count += 1
		if eligible_count <= 1:
			TrialCoordinator.notify_completion_condition("one_eligible_subject")
		player.call_deferred("restabilise")


func _round_metric(player_id: int) -> float:
	return dominance_seconds.get(player_id, 0.0) * DOMINANCE_WEIGHT \
			+ displacement_metres.get(player_id, 0.0) * DISPLACEMENT_WEIGHT \
			+ resilience_samples.get(player_id, 0.0) * RESILIENCE_WEIGHT
