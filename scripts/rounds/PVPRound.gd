extends ExperimentController
## Competitive Stress round controller. Subjects contest one open impact
## crucible while measurement pylons sample displacement and resilience.
##
## NETWORK: The host owns metric sampling, Destabilisation, Recall and scoring.

signal metrics_updated(player_id: int, dominance: float, displacement: float,
		resilience: float)

const SAMPLE_INTERVAL: float = 0.25
const DOMINANCE_RADIUS: float = 12.0
const DOMINANCE_WEIGHT: float = 3.0
const DISPLACEMENT_WEIGHT: float = 1.0
const RESILIENCE_WEIGHT: float = 0.5
const BASELINE_STABILITY: float = 100.0

## Subject-owned measurements for the current Experiment.
var dominance_seconds: Dictionary = {}
var displacement_metres: Dictionary = {}
var resilience_samples: Dictionary = {}

var _sample_timer: float = 0.0
var _previous_positions: Dictionary = {}


func _default_protocol() -> ExperimentProtocol:
	return preload("res://resources/protocols/competitive_stress.tres")


func _physics_process(delta: float) -> void:
	if not NetworkSession.can_simulate():
		return
	_sample_timer += delta
	if _sample_timer < SAMPLE_INTERVAL:
		return
	var sample_delta: float = _sample_timer
	_sample_timer = 0.0
	refresh_subjects()
	for body: Node in SubjectRoster.bodies():
		_sample_subject(body, sample_delta)


## Dominance, displacement and resilience, weighted as authored.
func get_performance(player_id: int) -> float:
	return dominance_seconds.get(player_id, 0.0) * DOMINANCE_WEIGHT \
			+ displacement_metres.get(player_id, 0.0) * DISPLACEMENT_WEIGHT \
			+ resilience_samples.get(player_id, 0.0) * RESILIENCE_WEIGHT


func _on_subject_registered(_player_id: int, body: Node) -> void:
	if body is Node3D:
		_previous_positions[body] = (body as Node3D).global_position


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


## The Subject that landed the Impact takes the authored knockout bonus.
func _on_subject_eliminated(_player_id: int, _subject: Node, source: Node) -> void:
	if source != null and source.is_in_group("players"):
		ScoreManager.award_protocol_bonus(source.get_multiplayer_authority(),
				protocol, "knockout")
