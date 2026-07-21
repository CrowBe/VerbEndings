class_name SwarmMonster
extends CharacterBody3D
## Basic PVE swarm enemy. Chases the nearest living player and bites on
## contact. Spawned by PVERound at a ring around each player and scaled by
## the round's strength multiplier.
##
## Verbs: monsters start verbless. After the round's evolution timer they
## may evolve a random verb — but a monster that lands the LAST HIT on a
## player preemptively takes the victim's verb instead, locking out the
## random roll. A verb applies the stat mutation from VERB_MUTATIONS.
##
## NETWORK: Monsters are server-owned. Spawns, evolutions, hits, and deaths
## all originate server-side and broadcast via the RPC hooks below.

## NETWORK: @rpc replication hook — broadcast; PVERound scores the kill.
signal monster_died(monster: SwarmMonster, killer_player_id: int)
## NETWORK: @rpc replication hook — broadcast for evolution VFX/nameplate.
signal evolved(monster: SwarmMonster, verb: Enums.VerbType)

const BASE_HEALTH: float = 20.0
const BASE_DAMAGE: float = 6.0
const BASE_SPEED: float = 3.0
const ATTACK_RANGE: float = 1.6
const ATTACK_COOLDOWN: float = 1.2

## Stat mutations applied when a monster takes on a verb.
const VERB_MUTATIONS: Dictionary = {
	Enums.VerbType.NONE: {"health": 1.0, "damage": 1.0, "speed": 1.0},
	Enums.VerbType.BURN: {"health": 1.0, "damage": 1.5, "speed": 1.1},
	Enums.VerbType.SHIELD: {"health": 1.8, "damage": 0.9, "speed": 0.9},
	Enums.VerbType.GROW: {"health": 1.6, "damage": 1.3, "speed": 0.8},
	Enums.VerbType.STRETCH: {"health": 1.0, "damage": 1.2, "speed": 1.2},
	Enums.VerbType.ROLL: {"health": 1.1, "damage": 1.1, "speed": 1.5},
	Enums.VerbType.JUMP: {"health": 1.0, "damage": 1.1, "speed": 1.3},
	Enums.VerbType.BOUNCE: {"health": 1.2, "damage": 1.0, "speed": 1.4},
	Enums.VerbType.FREEZE: {"health": 1.3, "damage": 1.2, "speed": 1.0},
	Enums.VerbType.REWIND: {"health": 1.4, "damage": 1.2, "speed": 1.1},
}

## Difficulty scale at spawn time (grows over the round).
## NETWORK: @rpc replication hook — set at spawn, sync once.
var strength_multiplier: float = 1.0
## NETWORK: @rpc replication hook — sync for health bars.
var health: float = BASE_HEALTH
## NETWORK: @rpc replication hook — sync for verb glow/nameplate.
var verb: Enums.VerbType = Enums.VerbType.NONE
## True once a verb is locked in (random roll OR last-hit inheritance).
var has_evolved: bool = false

var _attack_timer: float = 0.0
## Movement slow from a player's FREEZE activation (1.0 = full speed).
## NETWORK: @rpc replication hook — sync for a frost-tint shader later.
var _slow_factor: float = 1.0
var _slow_timer: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


## Configure at spawn, before add_child.
func setup(p_strength_multiplier: float) -> void:
	strength_multiplier = p_strength_multiplier
	health = BASE_HEALTH * strength_multiplier


func _physics_process(delta: float) -> void:
	# NETWORK: AI runs on the server only; clients interpolate transforms.
	if not is_on_floor():
		velocity.y -= _gravity * delta
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 1.0

	var target: Node3D = _nearest_living_player()
	if target == null:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	if distance > ATTACK_RANGE:
		var chase: Vector3 = to_target.normalized() * get_speed()
		velocity.x = chase.x
		velocity.z = chase.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_timer == 0.0:
			_attack_timer = ATTACK_COOLDOWN
			target.take_damage(get_damage(), self)
	move_and_slide()


## Damage from a player's verb attack.
## NETWORK: @rpc replication hook — server applies, then broadcasts.
func take_hit(amount: float, attacker_player_id: int) -> void:
	if health <= 0.0:
		return
	health -= amount
	if health <= 0.0:
		monster_died.emit(self, attacker_player_id)
		queue_free()


## FREEZE control effect: multiply speed down for a duration. Stacking
## applications keep the strongest slow and refresh the timer.
## NETWORK: @rpc replication hook — server applies, broadcast for VFX.
func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = minf(_slow_factor, factor)
	_slow_timer = maxf(_slow_timer, duration)


## Random evolution roll (PVERound calls this after the evolution timer).
## A monster that already inherited a verb via last hit is locked out.
func evolve_random() -> void:
	if has_evolved:
		return
	var candidates: Array = Enums.VerbType.values().filter(
			func(v: Enums.VerbType) -> bool: return v != Enums.VerbType.NONE)
	_take_on_verb(candidates.pick_random())


## Last-hit inheritance: this monster killed a player, so it preemptively
## takes the victim's verb — overriding and locking out the random roll.
## NETWORK: @rpc replication hook — server-side, from PVERound's death hook.
func assume_verb(victim_verb: Enums.VerbType) -> void:
	if victim_verb == Enums.VerbType.NONE:
		return
	_take_on_verb(victim_verb)


func get_damage() -> float:
	return BASE_DAMAGE * strength_multiplier * _mutation().damage


func get_speed() -> float:
	return BASE_SPEED * strength_multiplier * _mutation().speed * _slow_factor


func _take_on_verb(new_verb: Enums.VerbType) -> void:
	verb = new_verb
	has_evolved = true
	# Health mutation applies to the remaining pool, not a full heal.
	health *= _mutation().health
	evolved.emit(self, verb)


func _mutation() -> Dictionary:
	return VERB_MUTATIONS.get(verb, VERB_MUTATIONS[Enums.VerbType.NONE])


func _nearest_living_player() -> Node3D:
	var best: Node3D = null
	var best_distance: float = INF
	for body: Node in get_tree().get_nodes_in_group("players"):
		if not body.is_alive:
			continue
		var distance: float = global_position.distance_to(body.global_position)
		if distance < best_distance:
			best_distance = distance
			best = body
	return best
