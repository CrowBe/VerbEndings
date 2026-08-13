extends CharacterBody3D
## Third-person player controller for Verb Endings (Fall Guys-style blob).
##
## Movement: camera orbits via a yaw pivot (CameraRig) + pitched SpringArm3D;
## WASD is camera-relative and the presentation turns to face travel.
## Combat: a comical BIG FIST punch (left mouse) is the universal Impact —
## it destabilises residuals, affects Subjects in PVP rounds, and drives
## environment apparatus. Verb Expression (right mouse, 5s cooldown) fires the Verb's
## unique move and spends Stability.
## A loose "Tether Check" penalizes drifting too far from the chain partner.
##
## Network sessions use host simulation with explicit state snapshots. The
## owning client submits input intent; it never writes gameplay state.

## Fired when an external Impact reduces Stability to zero.
## NETWORK: replication boundary — server decides, then broadcasts.
signal destabilised(player: Node, source: Node)
signal critical_stability_changed(is_critical: bool)
signal material_absorbed(amount: float)
## NETWORK: replication boundary — broadcast so remote peers play the
## punch/Expression animation on their copy of this body.
signal hit_performed
signal verb_expressed(verb: Enums.VerbType)

const MATERIAL_SCENE: PackedScene = preload("res://scenes/Material.tscn")
const MOUSE_SENSITIVITY: float = 0.003
const CAMERA_PITCH_MIN: float = deg_to_rad(-75.0)
const CAMERA_PITCH_MAX: float = deg_to_rad(25.0)
const BLOB_TURN_SPEED: float = 10.0

const WALK_SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5

## Distance from the paired partner beyond which the tether starts to strain.
const TETHER_RANGE: float = 15.0
## Movement speed multiplier while the tether is strained.
const TETHER_SPEED_PENALTY: float = 0.6
## chain_sync drain per second while out of range, and regen rate in range.
const CHAIN_SYNC_DRAIN_RATE: float = 0.25
const CHAIN_SYNC_REGEN_RATE: float = 0.10

const BASELINE_STABILITY: float = 100.0
const CRITICAL_STABILITY_MAX: float = 9.0
## Percentage of baseline Stability restored each second. This is balance
## data and may be overridden per Subject.
@export_range(0.0, 100.0, 0.1) var stabilisation_rate: float = 1.0
## Stability lost when this Subject's Partner is Eliminated during an
## Experiment. Severance Loss is balance data and cannot Destabilise.
@export_range(0.0, 100.0, 0.1) var severance_loss: float = 15.0
## Material shed by a Subject Impact is balance data. Destabilisation makes
## one additional shed roll because it is the strongest possible Impact.
@export_range(0.0, 100.0, 0.1) var material_shed_amount: float = 10.0
@export_range(0.0, 1.0, 0.01) var material_shed_probability: float = 0.35
@export_range(0.0, 1.0, 0.01) var destabilise_shed_probability: float = 1.0

## Basic hit: the big fist.
const HIT_COOLDOWN: float = 0.6
const HIT_IMPACT_STRENGTH: float = 10.0
## Reach for driving environment apparatus with a punch.
const APPARATUS_REACH: float = 4.0

## Verb Expression: deliberately low cooldown so Verbs stay the core loop.
const VERB_COOLDOWN: float = 5.0
## Base Expression Costs are balance data and can be overridden per Subject.
@export var expression_costs: Dictionary = {
	Enums.VerbType.BURN: 10.0,
	Enums.VerbType.SHIELD: 10.0,
	Enums.VerbType.GROW: 10.0,
	Enums.VerbType.STRETCH: 10.0,
	Enums.VerbType.ROLL: 10.0,
	Enums.VerbType.JUMP: 10.0,
	Enums.VerbType.BOUNCE: 10.0,
	Enums.VerbType.FREEZE: 10.0,
	Enums.VerbType.REWIND: 10.0,
}
## Overdrive changes exactly one value: Verb Expression cooldown.
const OVERDRIVE_COOLDOWN_MULTIPLIER: float = 0.5
## How long timed verb buffs (SHIELD/GROW/ROLL) last.
const BUFF_DURATION: float = 3.0
## Radius for area verb effects (BURN nova, FREEZE ring).
const VERB_AREA_RADIUS: float = 4.0
const BURN_NOVA_IMPACT_STRENGTH: float = 14.0
const FREEZE_SLOW_FACTOR: float = 0.45
const STRETCH_LUNGE_SPEED: float = 12.0
const REWIND_SECONDS: float = 4.0

## The verb this player wields. Set via set_character_identity() so the
## Character Identity name stays in lockstep with the verb.
## NETWORK: replication boundary — server-assigned, sync to all peers.
var assigned_verb: Enums.VerbType = Enums.VerbType.NONE

## Character Identity: display name derived from the verb (e.g. "Burn").
## Uniqueness is enforced by LobbyManager.select_verb().
## NETWORK: replication boundary — sync to all peers for nameplates.
var character_name: String = ""

## Only one Subject consumes keyboard and mouse input in local quick start.
## Network authority replaces this flag when multiplayer transport lands.
var accepts_local_input: bool = true

## Peer id of the chained partner. Deliberately untyped:
##   int  = partner's peer id (own id = Self-Chain)
##   -1   = not yet paired
##   null = Solo state (the Collapse dissolved every Pair)
## NETWORK: replication boundary — server-assigned, sync to all peers.
var paired_partner_id = -1

## How "in sync" this chain is, 0.0 (severed) to 1.0 (fully linked).
## NETWORK: replication boundary — server-computed, sync to all peers.
var chain_sync: float = 1.0

## True while a Self-Chain or the Collapse grants Overdrive.
## NETWORK: replication boundary — server-assigned, sync to all peers.
var is_overdrive: bool = false

## NETWORK: replication boundary — server-authoritative, sync to all peers.
var stability: float = BASELINE_STABILITY
## NETWORK: replication boundary — server-authoritative, sync to all peers.
var is_destabilised: bool = false
var is_critical_stability: bool = false

## SHIELD Expression: absorbs external Stability loss while true.
## NETWORK: replication boundary — server-authoritative, sync to peers.
var shield_active: bool = false

## Cached reference to the partner's body. Local-only; never replicated.
var _partner_body: Node3D = null

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

## Combat timers/buffs. Server-authoritative; cooldown remainder is synced
## only to the owning peer for its HUD.
var _hit_timer: float = 0.0
var _verb_timer: float = 0.0
var _buff_time_left: float = 0.0
var _speed_buff: float = 1.0
var _power_buff: float = 1.0
## BOUNCE Expression: landings re-launch while charges remain.
var _bounce_charges: int = 0
var _was_on_floor: bool = true
## Position breadcrumbs for REWIND: [{time, pos}], trimmed to a few seconds.
var _position_history: Array[Dictionary] = []

@onready var camera_rig: Node3D = $CameraRig
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D
@onready var animation_adapter: AnimationAdapter = $AnimationAdapter
@onready var hit_box: Area3D = $HitBox


func _ready() -> void:
	if accepts_local_input:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = accepts_local_input
	# The rig is top-level so orbiting the camera never twists the body.
	camera_rig.top_level = true
	animation_adapter.basic_hit_impact.connect(_resolve_hit)


func _unhandled_input(event: InputEvent) -> void:
	if not accepts_local_input:
		return
	# NETWORK: input handling must run only on the authority peer.
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_rig.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		spring_arm.rotation.x = clampf(
				spring_arm.rotation.x - event.relative.y * MOUSE_SENSITIVITY,
				CAMERA_PITCH_MIN, CAMERA_PITCH_MAX)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)


func _physics_process(delta: float) -> void:
	# The top-level rig follows the body's position but keeps its own yaw.
	camera_rig.global_position = global_position + Vector3.UP * 1.2
	if NetworkSession.is_client():
		if accepts_local_input:
			var client_input := Input.get_vector(
					"move_left", "move_right", "move_forward", "move_back")
			NetworkSession.submit_movement(client_input,
					Input.is_action_just_pressed("jump"))
			if Input.is_action_just_pressed("basic_hit"):
				NetworkSession.request_basic_hit()
			if Input.is_action_just_pressed("verb_expression"):
				NetworkSession.request_verb_expression()
		return

	if is_destabilised:
		return

	_apply_stabilisation(delta)
	_tick_combat_timers(delta)
	_record_rewind_breadcrumb()

	if not is_on_floor():
		velocity.y -= _gravity * delta

	var network_jump: bool = NetworkSession.consume_jump_intent(
			get_multiplayer_authority()) if NetworkSession.is_host() else false
	if (accepts_local_input and Input.is_action_just_pressed("jump") \
			or network_jump) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animation_adapter.play_jump_start()
	if accepts_local_input and Input.is_action_just_pressed("basic_hit"):
		basic_hit()
	if accepts_local_input and Input.is_action_just_pressed("verb_expression"):
		express_verb()

	var speed: float = WALK_SPEED * _speed_buff * _tether_check(delta)

	# Camera-relative movement: input is rotated by the rig's yaw.
	var input_dir: Vector2 = Vector2.ZERO
	if accepts_local_input:
		input_dir = Input.get_vector(
				"move_left", "move_right", "move_forward", "move_back")
	elif NetworkSession.is_host():
		input_dir = NetworkSession.get_movement_intent(get_multiplayer_authority())
	var direction: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y)
	if accepts_local_input:
		direction = camera_rig.global_transform.basis * direction
	direction.y = 0.0
	direction = direction.normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		animation_adapter.face_direction(direction, BLOB_TURN_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()
	animation_adapter.update_locomotion(
			Vector2(velocity.x, velocity.z).length(), is_on_floor())

	# BOUNCE: while charges remain, every landing re-launches the blob.
	if _bounce_charges > 0 and is_on_floor() and not _was_on_floor:
		velocity.y = JUMP_VELOCITY * 1.1
		_bounce_charges -= 1
	elif is_on_floor() and not _was_on_floor:
		animation_adapter.play_land()
	_was_on_floor = is_on_floor()


## Assigns this player's verb and the matching Character Identity name.
## Call through LobbyManager.select_verb() so uniqueness holds.
## NETWORK: replication boundary — server assigns, then broadcasts.
func set_character_identity(verb: Enums.VerbType) -> void:
	assigned_verb = verb
	character_name = Enums.verb_name(verb).capitalize()


## Enables canonical Overdrive without changing movement, Stability, cost,
## or Verb Effect strength. Self-Chains pass their own id; the Collapse
## passes null after dissolving all Pairs.
func enter_overdrive(partner_id = null) -> void:
	paired_partner_id = partner_id
	is_overdrive = true
	chain_sync = 1.0
	_partner_body = null


## Restores the normal cooldown at Round/Pair lifecycle boundaries.
func exit_overdrive(partner_id = -1) -> void:
	paired_partner_id = partner_id
	is_overdrive = false
	chain_sync = 1.0
	_partner_body = null


## Applies external Stability loss. Subject-on-Subject Impacts are ignored
## outside Competitive Stress Experiments. Expression spend uses a separate
## path and can never Destabilise a Subject.
func apply_impact(
	amount: float,
	source: Node = null,
	allow_material_shed: bool = true,
) -> void:
	if is_destabilised or shield_active:
		return
	if source != null and source.is_in_group("players") \
			and not RoundManager.is_pvp_enabled():
		return
	_set_stability(maxf(stability - amount, 0.0))
	if allow_material_shed:
		_shed_material(material_shed_probability)
	if stability == 0.0:
		is_destabilised = true
		animation_adapter.play_destabilise()
		if allow_material_shed:
			_shed_material(destabilise_shed_probability)
		destabilised.emit(self, source)


## Protocol hazards use the external Stability Loss path without creating
## Impact-shed Material.
func apply_hazard_stability_loss(amount: float, source: Node = null) -> void:
	apply_impact(amount, source, false)


## Restabilises a Subject during normal Experiment Recall.
## NETWORK: replication boundary — server-side, at round transitions.
func restabilise() -> void:
	is_destabilised = false
	_set_stability(BASELINE_STABILITY)
	_clear_buffs()


## Applies the canonical non-Destabilising cost of losing a Partner.
## VerbChainManager calls this once while it removes the active Chain.
func apply_severance_loss() -> void:
	_set_stability(maxf(stability - maxf(severance_loss, 0.0), 1.0))


## Absorbs Material while this Subject is active and below baseline.
## Returns whether any Material was consumed.
func absorb_material(amount: float) -> bool:
	if is_destabilised or stability >= BASELINE_STABILITY or amount <= 0.0:
		return false
	var restored_amount: float = minf(amount, BASELINE_STABILITY - stability)
	_set_stability(stability + restored_amount)
	material_absorbed.emit(restored_amount)
	return true


## Applies the universal, always-on Restabilisation as a percentage of
## baseline per second. Destabilised Subjects recover only through Recall.
func _apply_stabilisation(delta: float) -> void:
	if is_destabilised or stability >= BASELINE_STABILITY:
		return
	var recovery: float = BASELINE_STABILITY * maxf(stabilisation_rate, 0.0) \
			* 0.01 * delta
	_set_stability(stability + recovery)


## --- Basic hit: the BIG FIST -------------------------------------------

## Comical punch: an oversized fist pops out of the blob, the Impact lands
## at full extension, then it snaps back in. One move drives everything —
## residuals take hits, Subjects take PVP-gated Stability loss, and the nearest
## environment apparatus within reach gets a Verb-scaled interaction.
## NETWORK: replication boundary — authority requests, server resolves
## the hit, hit_performed replicates the animation to remote peers.
func basic_hit() -> void:
	if _hit_timer > 0.0 or is_destabilised:
		return
	_hit_timer = HIT_COOLDOWN
	hit_performed.emit()
	animation_adapter.play_basic_hit()


## Impact/interaction resolution, fired by the animation at full extension.
func _resolve_hit() -> void:
	if is_destabilised:
		return
	var facing: Vector3 = animation_adapter.get_facing_direction()
	for body: Node3D in hit_box.get_overlapping_bodies():
		if body == self:
			continue
		if body.is_in_group("residuals"):
			body.take_hit(HIT_IMPACT_STRENGTH * _power_buff, get_multiplayer_authority())
		elif body.is_in_group("players"):
			body.apply_impact(HIT_IMPACT_STRENGTH * _power_buff, self)
		elif body.has_method("take_hit"):
			body.take_hit(HIT_IMPACT_STRENGTH * _power_buff, self)
	var unit: PuzzleUnit = _nearest_apparatus()
	if unit != null:
		unit.interact(assigned_verb, facing)


## --- Verb Expression ---------------------------------------------------

## Fires this Subject's Verb move (5s cooldown). Effects are deliberately
## mixed — some Impacts, some buffs, some reposition — and each has its own
## placeholder animation.
## NETWORK: replication boundary — authority requests, server validates
## cooldown and resolves; verb_expressed replicates the animation.
func express_verb() -> void:
	if _verb_timer > 0.0 or is_destabilised:
		return
	if assigned_verb == Enums.VerbType.NONE:
		return
	_spend_expression_cost()
	_verb_timer = get_verb_cooldown()
	verb_expressed.emit(assigned_verb)
	animation_adapter.play_verb_expression(Enums.verb_name(assigned_verb))

	match assigned_verb:
		Enums.VerbType.BURN:
			# Damaging: flame nova around the blob.
			_area_hit(BURN_NOVA_IMPACT_STRENGTH)
		Enums.VerbType.SHIELD:
			# Brief immunity to external Stability loss.
			shield_active = true
			_buff_time_left = BUFF_DURATION
		Enums.VerbType.GROW:
			# Not damaging: bulk up — punches hit twice as hard (apparatus
			# shoves already get GROW's top-tier static assist).
			_power_buff = 2.0
			_buff_time_left = BUFF_DURATION
		Enums.VerbType.STRETCH:
			# Not damaging: elastic lunge along facing.
			var facing: Vector3 = animation_adapter.get_facing_direction()
			velocity += facing * STRETCH_LUNGE_SPEED
		Enums.VerbType.ROLL:
			# Not damaging: momentum burst — sustained speed buff.
			_speed_buff = 1.8
			_buff_time_left = BUFF_DURATION
		Enums.VerbType.JUMP:
			# Not damaging: super leap.
			velocity.y = JUMP_VELOCITY * 2.2
		Enums.VerbType.BOUNCE:
			# Not damaging: the next three landings re-launch the blob.
			_bounce_charges = 3
		Enums.VerbType.FREEZE:
			# Control: frost ring slows every residual in the radius.
			for residual: Node in get_tree().get_nodes_in_group("residuals"):
				if _in_verb_radius(residual):
					residual.apply_slow(FREEZE_SLOW_FACTOR, BUFF_DURATION)
		Enums.VerbType.REWIND:
			# Not damaging: snap back to where you were 4 seconds ago.
			_teleport_to_breadcrumb()


## Impact every residual (and player, PVP-gated) inside the verb radius.
func _area_hit(impact_strength: float) -> void:
	for residual: Node in get_tree().get_nodes_in_group("residuals"):
		if _in_verb_radius(residual):
			residual.take_hit(impact_strength, get_multiplayer_authority())
	for body: Node in get_tree().get_nodes_in_group("players"):
		if body != self and _in_verb_radius(body):
			body.apply_impact(impact_strength, self)
	for receiver: Node in get_tree().get_nodes_in_group("impact_receivers"):
		if receiver is Node3D and _in_verb_radius(receiver) \
				and receiver.has_method("take_hit"):
			receiver.take_hit(impact_strength, self)


func get_expression_cost() -> float:
	return maxf(float(expression_costs.get(assigned_verb, 0.0)), 0.0)


func _spend_expression_cost() -> void:
	_set_stability(maxf(stability - get_expression_cost(), 1.0))


func _set_stability(value: float) -> void:
	var previous_stability: float = stability
	stability = clampf(value, 0.0, BASELINE_STABILITY)
	if stability < previous_stability:
		animation_adapter.play_stability_loss()
	var was_critical := is_critical_stability
	is_critical_stability = stability >= 1.0 and stability <= CRITICAL_STABILITY_MAX
	if is_critical_stability != was_critical:
		critical_stability_changed.emit(is_critical_stability)


func _shed_material(probability: float) -> void:
	if material_shed_amount <= 0.0 or randf() > clampf(probability, 0.0, 1.0):
		return
	var material_resource: MaterialResource = MATERIAL_SCENE.instantiate()
	material_resource.absorb_amount = material_shed_amount
	get_parent().add_child(material_resource)
	material_resource.global_position = global_position


func _in_verb_radius(body: Node3D) -> bool:
	return global_position.distance_to(body.global_position) <= VERB_AREA_RADIUS


func _tick_combat_timers(delta: float) -> void:
	_hit_timer = maxf(_hit_timer - delta, 0.0)
	_verb_timer = maxf(_verb_timer - delta, 0.0)
	if _buff_time_left > 0.0:
		_buff_time_left -= delta
		if _buff_time_left <= 0.0:
			_clear_buffs()


func _clear_buffs() -> void:
	_buff_time_left = 0.0
	shield_active = false
	_speed_buff = 1.0
	_power_buff = 1.0
	_bounce_charges = 0


## Remaining verb cooldown for the HUD (0 = ready).
func get_verb_cooldown_remaining() -> float:
	return _verb_timer


func get_verb_cooldown() -> float:
	return VERB_COOLDOWN * (
			OVERDRIVE_COOLDOWN_MULTIPLIER if is_overdrive else 1.0)


func _record_rewind_breadcrumb() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	_position_history.append({"time": now, "pos": global_position})
	while not _position_history.is_empty() \
			and now - _position_history[0].time > REWIND_SECONDS + 0.5:
		_position_history.pop_front()


func _teleport_to_breadcrumb() -> void:
	if _position_history.is_empty():
		return
	global_position = _position_history[0].pos
	velocity = Vector3.ZERO


func _nearest_apparatus() -> PuzzleUnit:
	var best: PuzzleUnit = null
	var best_distance: float = INF
	for unit: Node in get_tree().get_nodes_in_group("environment_apparatus"):
		var distance: float = global_position.distance_to(unit.global_position)
		if distance <= APPARATUS_REACH and distance < best_distance:
			best_distance = distance
			best = unit
	return best


## --- Tether ------------------------------------------------------------

## Loose Tether Check: while more than TETHER_RANGE meters from the paired
## partner, drain chain_sync and dampen movement speed. Within range,
## chain_sync slowly recovers. Returns the speed multiplier for this frame.
## Collapse participants and Self-Chained players never strain.
func _tether_check(delta: float) -> float:
	if paired_partner_id == null:
		return 1.0
	var partner: Node3D = _resolve_partner()
	if partner == null or partner == self:
		return 1.0

	var distance: float = global_position.distance_to(partner.global_position)
	if distance > TETHER_RANGE:
		chain_sync = maxf(chain_sync - CHAIN_SYNC_DRAIN_RATE * delta, 0.0)
		return TETHER_SPEED_PENALTY
	chain_sync = minf(chain_sync + CHAIN_SYNC_REGEN_RATE * delta, 1.0)
	return 1.0


func _resolve_partner() -> Node3D:
	if paired_partner_id == null or paired_partner_id == -1:
		return null
	if paired_partner_id == get_multiplayer_authority():
		return self  # Self-Chain
	if _partner_body == null or not is_instance_valid(_partner_body):
		# NETWORK: partner bodies will live under a shared "players" group
		# once the MultiplayerSpawner exists; find ours by peer id.
		for body: Node in get_tree().get_nodes_in_group("players"):
			if body != self and body.get_multiplayer_authority() == paired_partner_id:
				_partner_body = body
				break
	return _partner_body
