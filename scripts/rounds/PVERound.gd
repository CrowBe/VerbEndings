class_name PVERound
extends ExperimentController
## Adaptive Containment Experiment controller.
##
## Each wave stages through the Compound's authored specimen column, perimeter
## pens, vents, or wall cavities. Bait machinery diverts active Residuals,
## emergency shutters remove linked entries from selection, and the defensive
## power node temporarily slows the active encounter. Spawn cadence and
## per-Residual strength continue to grow over the round.
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
const FACILITY_ENTRY_REVEAL_SECONDS: float = 0.15
const POWER_NODE_SLOW_FACTOR: float = 0.35

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
var _compound: Compound = null
var _entry_openings: Array[Dictionary] = []
var _containment_tools: Dictionary = {}


## Game injects the persistent facility boundary before this controller enters
## the tree. Tests and other composition roots use the same public seam.
func configure_compound(compound: Compound) -> void:
	_disconnect_containment_tools()
	_compound = compound
	_entry_openings = compound.get_residual_entry_openings() \
			if compound != null else []
	_containment_tools.clear()
	if compound == null:
		return
	for tool: ContainmentTool in compound.get_containment_tools():
		_containment_tools[tool.name] = tool
		if NetworkSession.can_simulate():
			tool.reset()
		if not tool.activated.is_connected(_on_containment_tool_activated):
			tool.activated.connect(_on_containment_tool_activated)


func _exit_tree() -> void:
	if NetworkSession.can_simulate():
		for tool: ContainmentTool in _containment_tools.values():
			if is_instance_valid(tool):
				tool.reset()
	_disconnect_containment_tools()


func _default_protocol() -> ExperimentProtocol:
	return preload("res://resources/protocols/adaptive_containment.tres")


func _physics_process(delta: float) -> void:
	if not NetworkSession.can_simulate():
		return
	elapsed += delta

	_spawn_timer += delta
	if _spawn_timer >= _current_spawn_interval():
		_spawn_timer = 0.0
		spawn_wave()

	_survival_timer += delta
	if _survival_timer >= SURVIVAL_TICK_SECONDS:
		_survival_timer = 0.0
		_award_survival_ticks()

## Placements blend Residuals Destabilised with survival time.
func get_performance(player_id: int) -> float:
	return destabilisation_counts.get(player_id, 0) * DESTABILISATION_WEIGHT \
			+ survival_ticks.get(player_id, 0) * SURVIVAL_WEIGHT


## One Residual per stable Subject, each crossing an available facility opening.
func spawn_wave() -> void:
	refresh_subjects()
	var available_openings: Array[Dictionary] = _available_entry_openings()
	if available_openings.is_empty():
		return
	for body: Node in SubjectRoster.bodies():
		if body.is_destabilised:
			continue
		var opening: Dictionary = available_openings[
				_residual_sequence % available_openings.size()]
		var residual: Residual = RESIDUAL_SCENE.instantiate()
		residual.name = "NetworkResidual%d" % _residual_sequence
		residual.setup(_current_strength_multiplier(), grammar_seed + _residual_sequence)
		_residual_sequence += 1
		residual.residual_destabilised.connect(_on_residual_destabilised)
		add_child(residual)
		residual.set_meta("entry_kind", opening.kind)
		residual.begin_facility_entry(
				opening.id,
				(opening.staging_transform as Transform3D).origin,
				(opening.threshold_transform as Transform3D).origin,
				FACILITY_ENTRY_REVEAL_SECONDS)
		var bait: ContainmentTool = _active_tool(ContainmentTool.EFFECT_BAIT)
		if bait != null:
			residual.lure_to(bait.global_position, bait.active_time_remaining)
		var power_node: ContainmentTool = _active_tool(ContainmentTool.EFFECT_POWER)
		if power_node != null:
			residual.apply_slow(
					POWER_NODE_SLOW_FACTOR, power_node.active_time_remaining)


func available_entry_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for opening: Dictionary in _available_entry_openings():
		ids.append(opening.id)
	return ids


func _available_entry_openings() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for opening: Dictionary in _entry_openings:
		var blocker_name: StringName = opening.blocked_by
		if not blocker_name.is_empty():
			var blocker: ContainmentTool = _containment_tools.get(blocker_name)
			if blocker != null and blocker.is_active():
				continue
		available.append(opening)
	return available


func _active_tool(effect_id: StringName) -> ContainmentTool:
	for tool: ContainmentTool in _containment_tools.values():
		if tool.effect_id == effect_id and tool.is_active():
			return tool
	return null


func _on_containment_tool_activated(tool: ContainmentTool) -> void:
	if tool.effect_id == ContainmentTool.EFFECT_BAIT:
		for residual: Node in get_tree().get_nodes_in_group("residuals"):
			if residual is Residual:
				residual.lure_to(tool.global_position, tool.active_seconds)
	elif tool.effect_id == ContainmentTool.EFFECT_POWER:
		for residual: Node in get_tree().get_nodes_in_group("residuals"):
			if residual is Residual:
				residual.apply_slow(POWER_NODE_SLOW_FACTOR, tool.active_seconds)


func _disconnect_containment_tools() -> void:
	for tool: ContainmentTool in _containment_tools.values():
		if is_instance_valid(tool) \
				and tool.activated.is_connected(_on_containment_tool_activated):
			tool.activated.disconnect(_on_containment_tool_activated)


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
