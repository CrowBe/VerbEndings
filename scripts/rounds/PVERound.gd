extends Node3D
## PVE round controller: the swarm.
##
## Monsters spawn on a ring around each living player — never closer than
## MIN_SPAWN_DISTANCE — and both the spawn rate and per-monster strength
## grow over the round. After EVOLUTION_TIME, monsters start taking verbs:
## new spawns roll one immediately, existing monsters evolve randomly on a
## cadence, and any monster that lands a last hit on a player preemptively
## inherits the victim's verb instead (see SwarmMonster.assume_verb).
##
## Scoring combines KILLS and SURVIVAL TIME: swarm_kill bonuses per kill,
## survival_tick bonuses on a timer while alive, and end-of-round placements
## ranked by a weighted blend of both.
##
## PVP is disabled for this round (RoundManager.is_pvp_enabled()).
##
## NETWORK: Spawning, AI, evolution, and scoring are all server-side.

## NETWORK: @rpc replication hook — broadcast for the kill-feed HUD.
signal monster_killed(player_id: int, new_kill_count: int)
## NETWORK: @rpc replication hook — broadcast the final round placements.
signal round_finished(ordered_player_ids: Array)

const MONSTER_SCENE: PackedScene = preload("res://scenes/SwarmMonster.tscn")

## Spawn ring around each player.
const MIN_SPAWN_DISTANCE: float = 8.0
const MAX_SPAWN_DISTANCE: float = 14.0
## Spawn cadence: starts relaxed, tightens as the round ages.
const BASE_SPAWN_INTERVAL: float = 4.0
const MIN_SPAWN_INTERVAL: float = 1.2
const SPAWN_INTERVAL_DECAY: float = 0.02
## Monster strength growth: +1% per second of round time.
const STRENGTH_GROWTH_PER_SECOND: float = 0.01
## When the evolution phase begins, and how often existing monsters roll.
const EVOLUTION_TIME: float = 90.0
const EVOLUTION_INTERVAL: float = 12.0
## Survival scoring cadence.
const SURVIVAL_TICK_SECONDS: float = 10.0
## Placement blend: one kill outweighs one survival tick 3:1.
const KILL_WEIGHT: float = 3.0
const SURVIVAL_WEIGHT: float = 1.0

## NETWORK: @rpc replication hook — sync elapsed for the round clock HUD.
var elapsed: float = 0.0
## player_id -> monsters killed this round.
## NETWORK: @rpc replication hook — sync to all peers.
var kill_counts: Dictionary = {}
## player_id -> survival ticks earned this round.
## NETWORK: @rpc replication hook — sync to all peers.
var survival_ticks: Dictionary = {}

var _spawn_timer: float = 0.0
var _survival_timer: float = 0.0
var _evolution_timer: float = 0.0


func _ready() -> void:
	for body: Node in get_tree().get_nodes_in_group("players"):
		body.died.connect(_on_player_died)


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

	if elapsed >= EVOLUTION_TIME:
		_evolution_timer += delta
		if _evolution_timer >= EVOLUTION_INTERVAL:
			_evolution_timer = 0.0
			_evolve_random_monster()


## Ends the round: placements by weighted kills + survival, best first.
## NETWORK: @rpc replication hook — server-side, on round timer expiry.
func end_round() -> void:
	var ordered: Array = VerbChainManager.active_players.keys()
	ordered.sort_custom(func(a: int, b: int) -> bool:
		var score_a: float = _round_score(a)
		var score_b: float = _round_score(b)
		if score_a != score_b:
			return score_a > score_b
		return a < b)
	ScoreManager.award_placements("PVE", ordered)
	round_finished.emit(ordered)


## One monster per living player, on that player's spawn ring.
func _spawn_wave() -> void:
	for body: Node in get_tree().get_nodes_in_group("players"):
		if not body.is_alive:
			continue
		var monster: SwarmMonster = MONSTER_SCENE.instantiate()
		monster.setup(_current_strength_multiplier())
		monster.position = _ring_position_around(body)
		monster.monster_died.connect(_on_monster_died)
		add_child(monster)
		# Evolution phase: fresh spawns arrive with a verb already rolled.
		if elapsed >= EVOLUTION_TIME:
			monster.evolve_random()


## Random point on the ring: MIN..MAX spawn distance, random bearing.
## The minimum guarantees no monster ever materializes on top of a player.
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
		if not body.is_alive:
			continue
		var player_id: int = body.get_multiplayer_authority()
		survival_ticks[player_id] = survival_ticks.get(player_id, 0) + 1
		ScoreManager.award_bonus(player_id, "PVE", "survival_tick")


func _evolve_random_monster() -> void:
	var unevolved: Array = get_tree().get_nodes_in_group("monsters").filter(
			func(m: Node) -> bool: return not m.has_evolved)
	if not unevolved.is_empty():
		unevolved.pick_random().evolve_random()


func _on_monster_died(_monster: SwarmMonster, killer_player_id: int) -> void:
	kill_counts[killer_player_id] = kill_counts.get(killer_player_id, 0) + 1
	ScoreManager.award_bonus(killer_player_id, "PVE", "swarm_kill")
	monster_killed.emit(killer_player_id, kill_counts[killer_player_id])


## Last-hit verb inheritance: the killing monster preemptively takes the
## victim's verb, overriding any pending random evolution.
func _on_player_died(player: Node, killer: Node) -> void:
	if killer is SwarmMonster:
		killer.assume_verb(player.assigned_verb)


func _round_score(player_id: int) -> float:
	return kill_counts.get(player_id, 0) * KILL_WEIGHT \
			+ survival_ticks.get(player_id, 0) * SURVIVAL_WEIGHT
