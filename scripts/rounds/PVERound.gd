extends ExperimentController
## PVE round controller: the swarm.
##
## Residuals spawn on a ring around each stable player — never closer than
## MIN_SPAWN_DISTANCE — and both the spawn rate and per-residual strength
## grow over the round. Each Residual independently develops one seeded
## Adverb after surviving its configured threshold. A Residual may separately
## assume one Verb only by Destabilising its Subject.
##
## Scoring combines DESTABILISATIONS and SURVIVAL TIME: swarm_kill bonuses
## per Residual Destabilised (the bonus key is serialised Protocol data),
## survival_tick bonuses on a timer while stable, and end-of-round placements
## ranked by a weighted blend of both.
##
## PVP is disabled for this round (RoundManager.is_pvp_enabled()).
##
## NETWORK: Spawning, AI, evolution, and scoring are all server-side.

## NETWORK: replication boundary — broadcast for the Elimination-feed HUD.
signal residual_destabilised(player_id: int, new_destabilisation_count: int)

const RESIDUAL_SCENE: PackedScene = preload("res://scenes/Residual.tscn")

## Spawn ring around each player.
const MIN_SPAWN_DISTANCE: float = 8.0
const MAX_SPAWN_DISTANCE: float = 14.0
## Spawn cadence: starts relaxed, tightens as the round ages.
const BASE_SPAWN_INTERVAL: float = 4.0
const MIN_SPAWN_INTERVAL: float = 1.2
const SPAWN_INTERVAL_DECAY: float = 0.02
## Residual strength growth: +1% per second of round time.
const STRENGTH_GROWTH_PER_SECOND: float = 0.01
## Survival scoring cadence.
const SURVIVAL_TICK_SECONDS: float = 10.0
## Placement blend: one Destabilisation outweighs one survival tick 3:1.
const DESTABILISATION_WEIGHT: float = 3.0
const SURVIVAL_WEIGHT: float = 1.0

## NETWORK: replication boundary — sync elapsed for the round clock HUD.
var elapsed: float = 0.0
## player_id -> Residuals Destabilised this round.
## NETWORK: replication boundary — sync to all peers.
var destabilisation_counts: Dictionary = {}
## player_id -> survival ticks earned this round.
## NETWORK: replication boundary — sync to all peers.
var survival_ticks: Dictionary = {}
## Stable input for deterministic Residual grammar. Multiplayer hosts provide
## the authoritative Trial seed here.
@export var grammar_seed: int = 0

var _spawn_timer: float = 0.0
var _survival_timer: float = 0.0
var _residual_sequence: int = 0


func _default_protocol() -> ExperimentProtocol:
	return preload("res://resources/protocols/adaptive_containment.tres")


func _physics_process(delta: float) -> void:
	if not NetworkSession.can_simulate():
		return
	elapsed += delta

	_spawn_timer += delta
	if _spawn_timer >= _current_spawn_interval():
		_spawn_timer = 0.0
		_spawn_wave()

	_survival_timer += delta
	if _survival_timer >= SURVIVAL_TICK_SECONDS:
		_survival_timer = 0.0
		_award_survival_ticks()

## Placements blend Residuals Destabilised with survival time.
func get_performance(player_id: int) -> float:
	return destabilisation_counts.get(player_id, 0) * DESTABILISATION_WEIGHT \
			+ survival_ticks.get(player_id, 0) * SURVIVAL_WEIGHT


## One residual per stable player, on that player's spawn ring.
func _spawn_wave() -> void:
	refresh_subjects()
	for body: Node in SubjectRoster.bodies():
		if body.is_destabilised:
			continue
		var residual: Residual = RESIDUAL_SCENE.instantiate()
		residual.name = "NetworkResidual%d" % _residual_sequence
		residual.setup(_current_strength_multiplier(), grammar_seed + _residual_sequence)
		_residual_sequence += 1
		residual.position = to_local(_ring_position_around(body))
		residual.residual_destabilised.connect(_on_residual_destabilised)
		add_child(residual)


## Random point on the ring: MIN..MAX spawn distance, random bearing.
## The minimum guarantees no residual ever materializes on top of a player.
func _ring_position_around(body: Node3D) -> Vector3:
	var angle: float = randf() * TAU
	var distance: float = randf_range(MIN_SPAWN_DISTANCE, MAX_SPAWN_DISTANCE)
	var offset := Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
	return body.global_position + offset


func _current_spawn_interval() -> float:
	return maxf(
			BASE_SPAWN_INTERVAL - elapsed * SPAWN_INTERVAL_DECAY,
			MIN_SPAWN_INTERVAL)


func _current_strength_multiplier() -> float:
	return 1.0 + elapsed * STRENGTH_GROWTH_PER_SECOND


func _award_survival_ticks() -> void:
	for player_id: int in SubjectRoster.stable_ids():
		survival_ticks[player_id] = survival_ticks.get(player_id, 0) + 1
		ScoreManager.award_protocol_bonus(player_id, protocol, "survival_tick")


func _on_residual_destabilised(_residual: Residual, attacker_player_id: int) -> void:
	destabilisation_counts[attacker_player_id] = \
			destabilisation_counts.get(attacker_player_id, 0) + 1
	ScoreManager.award_protocol_bonus(attacker_player_id, protocol, "swarm_kill")
	residual_destabilised.emit(
			attacker_player_id, destabilisation_counts[attacker_player_id])


## A last hit is the sole Assumption path.
func _on_subject_eliminated(_player_id: int, subject: Node, source: Node) -> void:
	if source is Residual:
		source.assume_verb(subject.assigned_verb)
