class_name Residual
extends CharacterBody3D
## Basic PVE swarm enemy. Chases the nearest living player and bites on
## contact. Spawned by PVERound at a ring around each player and scaled by
## the round's strength multiplier.
##
## Residuals start without grammar. Survival develops one seeded Adverb,
## while Destabilising a Subject may grant that Subject's Verb. These are
## independent, capped states: neither can replace or grant the other.
##
## NETWORK: Residuals are server-owned. Spawns, evolutions, hits, and deaths
## all originate server-side and broadcast via the RPC hooks below.

## NETWORK: @rpc replication hook — broadcast; PVERound scores the kill.
signal residual_died(residual: Residual, killer_player_id: int)
## NETWORK: @rpc replication hook — broadcast for evolution VFX/nameplate.
signal adverb_developed(residual: Residual, adverb: AdverbType)
signal verb_assumed(residual: Residual, verb: Enums.VerbType)

enum AdverbType {
	NONE,
	QUICKLY,
	VIOLENTLY,
	RELENTLESSLY,
}

const MATERIAL_SCENE: PackedScene = preload("res://scenes/Material.tscn")
const BASE_HEALTH: float = 20.0
const BASE_DAMAGE: float = 6.0
const BASE_SPEED: float = 3.0
const ATTACK_RANGE: float = 1.6
const ATTACK_COOLDOWN: float = 1.2

@export_range(0.0, 100.0, 0.1) var material_shed_amount: float = 10.0
@export_range(0.0, 1.0, 0.01) var material_shed_probability: float = 0.35
@export_range(0.0, 1.0, 0.01) var destabilise_shed_probability: float = 1.0
## Seeded survival window and Adverb magnitudes are balance data.
@export_range(0.0, 600.0, 1.0) var adverb_survival_time_min: float = 75.0
@export_range(0.0, 600.0, 1.0) var adverb_survival_time_max: float = 105.0
@export_range(0.1, 5.0, 0.05) var quickly_speed_multiplier: float = 1.45
@export_range(0.1, 5.0, 0.05) var quickly_action_speed_multiplier: float = 1.25
@export_range(0.1, 5.0, 0.05) var violently_speed_multiplier: float = 1.1
@export_range(0.1, 5.0, 0.05) var violently_damage_multiplier: float = 1.6
@export_range(0.1, 5.0, 0.05) var relentlessly_speed_multiplier: float = 1.2
@export_range(0.1, 5.0, 0.05) var relentlessly_action_speed_multiplier: float = 1.5

## Stat mutations applied when a residual takes on a verb.
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
## NETWORK: @rpc replication hook — sync for behavioural overlay/nameplate.
var adverb: AdverbType = AdverbType.NONE
var adverb_development_time: float = INF

var _attack_timer: float = 0.0
var _survival_time: float = 0.0
var _rng := RandomNumberGenerator.new()
## Movement slow from a player's FREEZE activation (1.0 = full speed).
## NETWORK: @rpc replication hook — sync for a frost-tint shader later.
var _slow_factor: float = 1.0
var _slow_timer: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


## Configure at spawn, before add_child.
@onready var _verb_treatment: MeshInstance3D = $VerbTreatment
@onready var _adverb_overlay: MeshInstance3D = $AdverbOverlay


func setup(p_strength_multiplier: float, grammar_seed: int = 0) -> void:
	strength_multiplier = p_strength_multiplier
	health = BASE_HEALTH * strength_multiplier
	_rng.seed = grammar_seed
	var lower := minf(adverb_survival_time_min, adverb_survival_time_max)
	var upper := maxf(adverb_survival_time_min, adverb_survival_time_max)
	adverb_development_time = _rng.randf_range(lower, upper)


func _physics_process(delta: float) -> void:
	# NETWORK: AI runs on the server only; clients interpolate transforms.
	_survival_time += delta
	if adverb == AdverbType.NONE and _survival_time >= adverb_development_time:
		develop_adverb()
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
			_attack_timer = ATTACK_COOLDOWN / _adverb_action_speed()
			target.apply_impact(get_damage(), self)
	move_and_slide()


## Damage from a player's verb attack.
## NETWORK: @rpc replication hook — server applies, then broadcasts.
func take_hit(amount: float, attacker_player_id: int) -> void:
	if health <= 0.0:
		return
	health -= amount
	_shed_material(material_shed_probability)
	if health <= 0.0:
		_shed_material(destabilise_shed_probability)
		residual_died.emit(self, attacker_player_id)
		queue_free()


## FREEZE control effect: multiply speed down for a duration. Stacking
## applications keep the strongest slow and refresh the timer.
## NETWORK: @rpc replication hook — server applies, broadcast for VFX.
func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = minf(_slow_factor, factor)
	_slow_timer = maxf(_slow_timer, duration)


## Select exactly one Adverb from this Residual's seeded stream.
func develop_adverb() -> void:
	if adverb != AdverbType.NONE:
		return
	var candidates: Array[AdverbType] = [
		AdverbType.QUICKLY,
		AdverbType.VIOLENTLY,
		AdverbType.RELENTLESSLY,
	]
	adverb = candidates[_rng.randi_range(0, candidates.size() - 1)]
	_apply_adverb_overlay()
	adverb_developed.emit(self, adverb)


## Assumption only occurs on a Subject's Destabilisation and never replaces
## an already assumed Verb.
## NETWORK: @rpc replication hook — server-side, from PVERound's death hook.
func assume_verb(victim_verb: Enums.VerbType) -> void:
	if victim_verb == Enums.VerbType.NONE or verb != Enums.VerbType.NONE:
		return
	_take_on_verb(victim_verb)


func get_damage() -> float:
	return BASE_DAMAGE * strength_multiplier * _mutation().damage \
			* _adverb_damage()


func get_speed() -> float:
	return BASE_SPEED * strength_multiplier * _mutation().speed \
			* _adverb_speed() * _slow_factor


func _take_on_verb(new_verb: Enums.VerbType) -> void:
	verb = new_verb
	# Health mutation applies to the remaining pool, not a full heal.
	health *= _mutation().health
	_apply_verb_treatment()
	verb_assumed.emit(self, verb)


func _mutation() -> Dictionary:
	return VERB_MUTATIONS.get(verb, VERB_MUTATIONS[Enums.VerbType.NONE])


func _adverb_speed() -> float:
	match adverb:
		AdverbType.QUICKLY:
			return quickly_speed_multiplier
		AdverbType.VIOLENTLY:
			return violently_speed_multiplier
		AdverbType.RELENTLESSLY:
			return relentlessly_speed_multiplier
	return 1.0


func _adverb_damage() -> float:
	return violently_damage_multiplier if adverb == AdverbType.VIOLENTLY else 1.0


func _adverb_action_speed() -> float:
	match adverb:
		AdverbType.QUICKLY:
			return quickly_action_speed_multiplier
		AdverbType.RELENTLESSLY:
			return relentlessly_action_speed_multiplier
	return 1.0


func _apply_verb_treatment() -> void:
	if not is_node_ready():
		return
	var colours: Dictionary = {
		Enums.VerbType.BURN: Color("#ff6a3d"),
		Enums.VerbType.SHIELD: Color("#35bceb"),
		Enums.VerbType.GROW: Color("#66c95a"),
		Enums.VerbType.STRETCH: Color("#d45ac7"),
		Enums.VerbType.ROLL: Color("#4169d8"),
		Enums.VerbType.JUMP: Color("#f2c94c"),
		Enums.VerbType.BOUNCE: Color("#ff7db5"),
		Enums.VerbType.FREEZE: Color("#a8e8e8"),
		Enums.VerbType.REWIND: Color("#8067d8"),
	}
	var treatment := StandardMaterial3D.new()
	treatment.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	treatment.albedo_color = colours.get(verb, Color.WHITE) * Color(1, 1, 1, 0.38)
	treatment.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_verb_treatment.material_override = treatment
	_verb_treatment.visible = true


func _apply_adverb_overlay() -> void:
	if not is_node_ready():
		return
	var overlay := StandardMaterial3D.new()
	overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Neutral monochrome bands remain distinct from every saturated Verb cue.
	overlay.albedo_color = {
		AdverbType.QUICKLY: Color(0.95, 0.95, 0.95, 0.7),
		AdverbType.VIOLENTLY: Color(0.15, 0.15, 0.15, 0.8),
		AdverbType.RELENTLESSLY: Color(0.55, 0.55, 0.55, 0.75),
	}.get(adverb, Color.TRANSPARENT)
	_adverb_overlay.material_override = overlay
	_adverb_overlay.visible = true


func _nearest_living_player() -> Node3D:
	var best: Node3D = null
	var best_distance: float = INF
	for body: Node in get_tree().get_nodes_in_group("players"):
		if body.is_destabilised:
			continue
		var distance: float = global_position.distance_to(body.global_position)
		if distance < best_distance:
			best_distance = distance
			best = body
	return best


func _shed_material(probability: float) -> void:
	if material_shed_amount <= 0.0 or randf() > clampf(probability, 0.0, 1.0):
		return
	var material_resource: MaterialResource = MATERIAL_SCENE.instantiate()
	material_resource.absorb_amount = material_shed_amount
	get_parent().add_child(material_resource)
	material_resource.global_position = global_position
