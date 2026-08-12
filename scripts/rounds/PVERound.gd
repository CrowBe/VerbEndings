extends Node3D
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

## NETWORK: @rpc replication hook — broadcast for the Elimination-feed HUD.
signal residual_destabilised(player_id: int, new_destabilisation_count: int)
## NETWORK: @rpc replication hook — broadcast the final round placements.
signal round_finished(ordered_player_ids: Array)

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

## NETWORK: @rpc replication hook — sync elapsed for the round clock HUD.
var elapsed: float = 0.0
## player_id -> Residuals Destabilised this round.
## NETWORK: @rpc replication hook — sync to all peers.
var destabilisation_counts: Dictionary = {}
## player_id -> survival ticks earned this round.
## NETWORK: @rpc replication hook — sync to all peers.
var survival_ticks: Dictionary = {}
## Stable input for deterministic Residual grammar. Multiplayer hosts provide
## the authoritative Trial seed here.
@export var grammar_seed: int = 0
@export var protocol: ExperimentProtocol = preload(
		"res://resources/protocols/adaptive_containment.tres")

var _spawn_timer: float = 0.0
var _survival_timer: float = 0.0
var _residual_sequence: int = 0


func _ready() -> void:
	for body: Node in get_tree().get_nodes_in_group("players"):
		body.destabilised.connect(_on_player_destabilised)


func _physics_process(delta: float) -> void:
	# NETWORK: the whole director loop is server-only.
	elapsed += delta

	_spawn_timer += delta
	if _spawn_timer >= _current_spawn_interval():
		_spawn_timer = 0.0
		_spawn_wave()

	_survival_timer += delta
	if _survival_timer >= SURVIVAL_TICK_SECONDS:
		_survival_timer = 0.0
		_award_survival_ticks()

## Ends the round: placements by weighted Destabilisations + survival,
## best first.
## NETWORK: @rpc replication hook — server-side, on round timer expiry.
func end_round() -> void:
	var ordered: Array = VerbChainManager.active_players.keys()
	ordered.sort_custom(func(a: int, b: int) -> bool:
		var score_a: float = _round_score(a)
		var score_b: float = _round_score(b)
		if score_a != score_b:
			return score_a > score_b
		return a < b)
	ScoreManager.award_protocol_placements(protocol, ordered)
	round_finished.emit(ordered)


## One residual per stable player, on that player's spawn ring.
func _spawn_wave() -> void:
	for body: Node in get_tree().get_nodes_in_group("players"):
		if body.is_destabilised:
			continue
		var residual: Residual = RESIDUAL_SCENE.instantiate()
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
	for body: Node in get_tree().get_nodes_in_group("players"):
		if body.is_destabilised:
			continue
		var player_id: int = body.get_multiplayer_authority()
		survival_ticks[player_id] = survival_ticks.get(player_id, 0) + 1
		ScoreManager.award_protocol_bonus(player_id, protocol, "survival_tick")


func _on_residual_destabilised(_residual: Residual, attacker_player_id: int) -> void:
	destabilisation_counts[attacker_player_id] = \
			destabilisation_counts.get(attacker_player_id, 0) + 1
	ScoreManager.award_protocol_bonus(attacker_player_id, protocol, "swarm_kill")
	residual_destabilised.emit(
			attacker_player_id, destabilisation_counts[attacker_player_id])


## A last hit is the sole Assumption path.
func _on_player_destabilised(player: Node, source: Node) -> void:
	if source is Residual:
		source.assume_verb(player.assigned_verb)
	if not CollapseManager.is_active:
		VerbChainManager.sever_chain_for(player.get_multiplayer_authority())
		player.call_deferred("restabilise")


func _round_score(player_id: int) -> float:
	return destabilisation_counts.get(player_id, 0) * DESTABILISATION_WEIGHT \
			+ survival_ticks.get(player_id, 0) * SURVIVAL_WEIGHT
