extends CharacterBody3D
## Third-person player controller for Verb Endings (Fall Guys-style blob).
##
## Movement: camera orbits via a yaw pivot (CameraRig) + pitched SpringArm3D;
## WASD is camera-relative and the blob mesh turns to face travel.
## Combat: a comical BIG FIST punch (left mouse) is the universal move — it
## damages residuals, damages players (PVP rounds only), and drives puzzle
## units. Verb activation (right mouse, 5s cooldown) fires the verb's unique
## move with its own placeholder animation; not all of them deal damage.
## A loose "Tether Check" penalizes drifting too far from the chain partner.
##
## All "animations" here are procedural Tween gags on the graybox meshes —
## replace with an AnimationPlayer once real character art exists.
##
## NETWORK: This scene will be spawned once per peer via MultiplayerSpawner.
## Variables marked with "@rpc replication hook" are the ones that need
## MultiplayerSynchronizer entries (or explicit RPCs) once netcode lands.

## Fired on death. `killer` is the Node that landed the last hit (a residual,
## another player, or null for environment hazards). PVERound listens to
## this to hand the killing residual the victim's verb.
## NETWORK: @rpc replication hook — server decides deaths, then broadcasts.
signal died(player: Node, killer: Node)
## NETWORK: @rpc replication hook — broadcast so remote peers play the
## punch/activation animation on their copy of this body.
signal hit_performed
signal verb_activated(verb: Enums.VerbType)

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

const MAX_HEALTH: float = 100.0

## Basic hit: the big fist.
const HIT_COOLDOWN: float = 0.6
const HIT_DAMAGE: float = 10.0
## Reach for driving puzzle units with a punch.
const PUZZLE_REACH: float = 4.0

## Verb activation: deliberately low cooldown so verbs stay the core loop.
const VERB_COOLDOWN: float = 5.0
## Overdrive changes exactly one value: Verb Expression cooldown.
const OVERDRIVE_COOLDOWN_MULTIPLIER: float = 0.5
## How long timed verb buffs (SHIELD/GROW/ROLL) last.
const BUFF_DURATION: float = 3.0
## Radius for area verb effects (BURN nova, FREEZE ring).
const VERB_AREA_RADIUS: float = 4.0
const BURN_NOVA_DAMAGE: float = 14.0
const FREEZE_SLOW_FACTOR: float = 0.45
const STRETCH_LUNGE_SPEED: float = 12.0
const REWIND_SECONDS: float = 4.0

## The verb this player wields. Set via set_character_identity() so the
## Character Identity name stays in lockstep with the verb.
## NETWORK: @rpc replication hook — server-assigned, sync to all peers.
var assigned_verb: Enums.VerbType = Enums.VerbType.NONE

## Character Identity: display name derived from the verb (e.g. "Burn").
## Uniqueness is enforced by LobbyManager.claim_character_identity().
## NETWORK: @rpc replication hook — sync to all peers for nameplates.
var character_name: String = ""

## Peer id of the chained partner. Deliberately untyped:
##   int  = partner's peer id (own id = Self-Chain)
##   -1   = not yet paired
##   null = forced Solo state (Sudden Death severed all partnerships)
## NETWORK: @rpc replication hook — server-assigned, sync to all peers.
var paired_partner_id = -1

## How "in sync" this chain is, 0.0 (severed) to 1.0 (fully linked).
## NETWORK: @rpc replication hook — server-computed, sync to all peers.
var chain_sync: float = 1.0

## True while a Self-Chain or the Collapse grants Overdrive.
## NETWORK: @rpc replication hook — server-assigned, sync to all peers.
var is_overdrive: bool = false

## NETWORK: @rpc replication hook — server-authoritative, sync to all peers.
var health: float = MAX_HEALTH
## NETWORK: @rpc replication hook — server-authoritative, sync to all peers.
var is_alive: bool = true

## SHIELD activation: absorbs all damage while true.
## NETWORK: @rpc replication hook — server-authoritative, sync to peers.
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
## BOUNCE activation: landings re-launch while charges remain.
var _bounce_charges: int = 0
var _was_on_floor: bool = true
## Position breadcrumbs for REWIND: [{time, pos}], trimmed to a few seconds.
var _position_history: Array[Dictionary] = []

@onready var camera_rig: Node3D = $CameraRig
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D
@onready var blob_mesh: MeshInstance3D = $BlobMesh
@onready var fist_pivot: Node3D = $BlobMesh/FistPivot
@onready var fist_mesh: MeshInstance3D = $BlobMesh/FistPivot/FistMesh
@onready var hit_box: Area3D = $BlobMesh/HitBox


func _ready() -> void:
	# NETWORK: gate this on is_multiplayer_authority() once peers exist —
	# only the local player captures the mouse and keeps an active camera.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# The rig is top-level so orbiting the camera never twists the body.
	camera_rig.top_level = true


func _unhandled_input(event: InputEvent) -> void:
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

	if not is_alive:
		return

	_tick_combat_timers(delta)
	_record_rewind_breadcrumb()

	# NETWORK: movement is authority-side; remote peers will interpolate
	# replicated transforms instead of simulating this block.
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("basic_hit"):
		basic_hit()
	if Input.is_action_just_pressed("verb_activate"):
		activate_verb()

	var speed: float = WALK_SPEED * _speed_buff * _tether_check(delta)

	# Camera-relative movement: input is rotated by the rig's yaw.
	var input_dir: Vector2 = Input.get_vector(
			"move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = camera_rig.global_transform.basis * Vector3(
			input_dir.x, 0.0, input_dir.y)
	direction.y = 0.0
	direction = direction.normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		# Turn the blob to face where it's headed (Fall Guys waddle).
		blob_mesh.rotation.y = lerp_angle(
				blob_mesh.rotation.y, atan2(direction.x, direction.z),
				BLOB_TURN_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

	# BOUNCE: while charges remain, every landing re-launches the blob.
	if _bounce_charges > 0 and is_on_floor() and not _was_on_floor:
		velocity.y = JUMP_VELOCITY * 1.1
		_bounce_charges -= 1
	_was_on_floor = is_on_floor()


## Assigns this player's verb and the matching Character Identity name.
## Call through LobbyManager.claim_character_identity() so uniqueness holds.
## NETWORK: @rpc replication hook — server assigns, then broadcasts.
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


## Applies damage from any source. Player-on-player damage is silently
## ignored outside PVP rounds — RoundManager.is_pvp_enabled() is the single
## gate that turns PVP off for PUZZLE and PVE. An active SHIELD absorbs
## everything.
## NETWORK: @rpc replication hook — server-side only; clients request hits,
## the server validates and applies, then broadcasts health.
func take_damage(amount: float, source: Node = null) -> void:
	if not is_alive or shield_active:
		return
	if source != null and source.is_in_group("players") \
			and not RoundManager.is_pvp_enabled():
		return
	health = maxf(health - amount, 0.0)
	if health == 0.0:
		is_alive = false
		died.emit(self, source)


## Restores the player for the next round.
## NETWORK: @rpc replication hook — server-side, at round transitions.
func revive() -> void:
	health = MAX_HEALTH
	is_alive = true
	_clear_buffs()


## --- Basic hit: the BIG FIST -------------------------------------------

## Comical punch: an oversized fist pops out of the blob, damage lands at
## full extension, then it snaps back in. One move drives everything —
## residuals take damage, players take PVP-gated damage, and the nearest
## puzzle unit within reach gets a verb-scaled interaction.
## NETWORK: @rpc replication hook — authority requests, server resolves
## the hit, hit_performed replicates the animation to remote peers.
func basic_hit() -> void:
	if _hit_timer > 0.0 or not is_alive:
		return
	_hit_timer = HIT_COOLDOWN
	hit_performed.emit()
	_play_fist_animation()


## Damage/interaction resolution, fired by the animation at full extension.
func _resolve_hit() -> void:
	if not is_alive:
		return
	var facing: Vector3 = blob_mesh.global_transform.basis * Vector3(0, 0, 1)
	for body: Node3D in hit_box.get_overlapping_bodies():
		if body == self:
			continue
		if body.is_in_group("residuals"):
			body.take_hit(HIT_DAMAGE * _power_buff, get_multiplayer_authority())
		elif body.is_in_group("players"):
			body.take_damage(HIT_DAMAGE * _power_buff, self)
	var unit: PuzzleUnit = _nearest_puzzle_unit()
	if unit != null:
		unit.interact(get_multiplayer_authority(), assigned_verb, facing)


## Placeholder comic punch animation: fist inflates with overshoot, shoots
## forward, resolves the hit, then deflates back into the blob.
func _play_fist_animation() -> void:
	fist_mesh.visible = true
	fist_mesh.scale = Vector3.ONE * 0.2
	fist_pivot.position.z = 0.3
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(fist_mesh, "scale", Vector3.ONE * 1.6, 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(fist_pivot, "position:z", 1.2, 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(_resolve_hit)
	tween.tween_interval(0.08)
	tween.set_parallel(true)
	tween.tween_property(fist_mesh, "scale", Vector3.ONE * 0.2, 0.15)
	tween.tween_property(fist_pivot, "position:z", 0.3, 0.15)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void: fist_mesh.visible = false)


## --- Verb activation ---------------------------------------------------

## Fires this player's verb move (5s cooldown). Effects are deliberately
## mixed — some damage, some buff, some reposition — and each has its own
## placeholder animation.
## NETWORK: @rpc replication hook — authority requests, server validates
## cooldown and resolves; verb_activated replicates the animation.
func activate_verb() -> void:
	if _verb_timer > 0.0 or not is_alive:
		return
	if assigned_verb == Enums.VerbType.NONE:
		return
	_verb_timer = get_verb_cooldown()
	verb_activated.emit(assigned_verb)
	_play_verb_animation(assigned_verb)

	match assigned_verb:
		Enums.VerbType.BURN:
			# Damaging: flame nova around the blob.
			_area_hit(BURN_NOVA_DAMAGE)
		Enums.VerbType.SHIELD:
			# Not damaging: brief total damage immunity.
			shield_active = true
			_buff_time_left = BUFF_DURATION
		Enums.VerbType.GROW:
			# Not damaging: bulk up — punches hit twice as hard (puzzle
			# shoves already get GROW's top-tier static assist).
			_power_buff = 2.0
			_buff_time_left = BUFF_DURATION
		Enums.VerbType.STRETCH:
			# Not damaging: elastic lunge along facing.
			var facing: Vector3 = blob_mesh.global_transform.basis * Vector3(0, 0, 1)
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


## Damage every residual (and player, PVP-gated) inside the verb radius.
func _area_hit(damage: float) -> void:
	for residual: Node in get_tree().get_nodes_in_group("residuals"):
		if _in_verb_radius(residual):
			residual.take_hit(damage, get_multiplayer_authority())
	for body: Node in get_tree().get_nodes_in_group("players"):
		if body != self and _in_verb_radius(body):
			body.take_damage(damage, self)


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
	blob_mesh.scale = Vector3.ONE


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


func _nearest_puzzle_unit() -> PuzzleUnit:
	var best: PuzzleUnit = null
	var best_distance: float = INF
	for unit: Node in get_tree().get_nodes_in_group("puzzle_units"):
		var distance: float = global_position.distance_to(unit.global_position)
		if distance <= PUZZLE_REACH and distance < best_distance:
			best_distance = distance
			best = unit
	return best


## --- Verb animations (procedural placeholders) -------------------------

## One unique transform gag per verb. All of these are stand-ins for real
## AnimationPlayer clips; they only touch blob_mesh scale/rotation so they
## can never fight the movement code.
func _play_verb_animation(verb: Enums.VerbType) -> void:
	var tween: Tween = create_tween()
	match verb:
		Enums.VerbType.BURN:
			# Double flare pulse.
			tween.tween_property(blob_mesh, "scale", Vector3.ONE * 1.35, 0.08)
			tween.tween_property(blob_mesh, "scale", Vector3.ONE * 1.05, 0.08)
			tween.tween_property(blob_mesh, "scale", Vector3.ONE * 1.45, 0.10)
			tween.tween_property(blob_mesh, "scale", Vector3.ONE, 0.15)
		Enums.VerbType.SHIELD:
			# Squash into a dome and hold for the buff.
			tween.tween_property(blob_mesh, "scale", Vector3(1.4, 0.55, 1.4), 0.12) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_interval(BUFF_DURATION - 0.3)
			tween.tween_property(blob_mesh, "scale", Vector3.ONE, 0.18)
		Enums.VerbType.GROW:
			# Bulk up and stay big while the buff lasts.
			tween.tween_property(blob_mesh, "scale", Vector3.ONE * 1.6, 0.25) \
					.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tween.tween_interval(BUFF_DURATION - 0.5)
			tween.tween_property(blob_mesh, "scale", Vector3.ONE, 0.25)
		Enums.VerbType.STRETCH:
			# Taffy snap along the lunge.
			tween.tween_property(blob_mesh, "scale", Vector3(0.6, 0.7, 2.4), 0.10)
			tween.tween_property(blob_mesh, "scale", Vector3.ONE, 0.30) \
					.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		Enums.VerbType.ROLL:
			# Full forward somersault.
			tween.tween_property(blob_mesh, "rotation:x", TAU, 0.5) \
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_callback(func() -> void: blob_mesh.rotation.x = 0.0)
		Enums.VerbType.JUMP:
			# Anticipation squash, then a launch stretch.
			tween.tween_property(blob_mesh, "scale", Vector3(1.3, 0.6, 1.3), 0.08)
			tween.tween_property(blob_mesh, "scale", Vector3(0.8, 1.5, 0.8), 0.15)
			tween.tween_property(blob_mesh, "scale", Vector3.ONE, 0.25)
		Enums.VerbType.BOUNCE:
			# Three diminishing rubber squashes.
			tween.tween_property(blob_mesh, "scale", Vector3(1.3, 0.7, 1.3), 0.10)
			tween.tween_property(blob_mesh, "scale", Vector3.ONE, 0.10)
			tween.tween_property(blob_mesh, "scale", Vector3(1.2, 0.8, 1.2), 0.08)
			tween.tween_property(blob_mesh, "scale", Vector3.ONE, 0.08)
			tween.tween_property(blob_mesh, "scale", Vector3(1.1, 0.9, 1.1), 0.06)
			tween.tween_property(blob_mesh, "scale", Vector3.ONE, 0.06)
		Enums.VerbType.FREEZE:
			# Brittle shiver.
			tween.tween_property(blob_mesh, "rotation:z", 0.12, 0.05)
			tween.tween_property(blob_mesh, "rotation:z", -0.12, 0.05)
			tween.tween_property(blob_mesh, "rotation:z", 0.08, 0.04)
			tween.tween_property(blob_mesh, "rotation:z", -0.08, 0.04)
			tween.tween_property(blob_mesh, "rotation:z", 0.0, 0.04)
		Enums.VerbType.REWIND:
			# Frantic reverse spin.
			tween.tween_property(blob_mesh, "rotation:y", -TAU * 2.0, 0.4) \
					.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.tween_callback(func() -> void: blob_mesh.rotation.y = 0.0)


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
	if paired_partner_id == multiplayer.get_unique_id():
		return self  # Self-Chain
	if _partner_body == null or not is_instance_valid(_partner_body):
		# NETWORK: partner bodies will live under a shared "players" group
		# once the MultiplayerSpawner exists; find ours by peer id.
		for body: Node in get_tree().get_nodes_in_group("players"):
			if body != self and body.get_multiplayer_authority() == paired_partner_id:
				_partner_body = body
				break
	return _partner_body
