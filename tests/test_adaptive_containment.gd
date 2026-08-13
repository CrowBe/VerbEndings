extends Node

const COMPOUND_SCENE: PackedScene = preload(
		"res://scenes/environment/Compound.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const ROUND_SCENE: PackedScene = preload("res://scenes/rounds/PVERound.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	NetworkSession.shutdown()
	VerbChainManager.reset()
	ScoreManager.reset()
	RoundManager.current_round_index = 1
	RoundManager.current_round_type = "PVE"

	var fixture := Node3D.new()
	fixture.name = "AdaptiveContainmentFixture"
	add_child(fixture)
	var compound := COMPOUND_SCENE.instantiate() as Compound
	fixture.add_child(compound)
	compound.select_active_laboratory(&"AdaptiveContainment")
	_add_subject(fixture, 1, Enums.VerbType.BURN)
	_add_subject(fixture, 2, Enums.VerbType.FREEZE)

	var containment_round := ROUND_SCENE.instantiate() as PVERound
	containment_round.transform = compound.get_laboratory_anchor_transform(
			&"AdaptiveContainment")
	containment_round.configure_compound(compound)
	fixture.add_child(containment_round)
	containment_round.set_physics_process(false)

	_test_physical_entry_contract(compound)
	_test_facility_staged_wave(containment_round, compound)
	_test_subject_operated_tools(containment_round, compound)
	_test_configurable_pressure(containment_round)

	fixture.queue_free()
	await get_tree().process_frame
	if _failures.is_empty():
		print("Adaptive Containment tests passed.")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	get_tree().quit(1)


func _add_subject(
	fixture: Node3D,
	player_id: int,
	verb: Enums.VerbType,
) -> void:
	VerbChainManager.register_player(player_id, verb)
	ScoreManager.register_player(player_id)
	var subject: Node = PLAYER_SCENE.instantiate()
	subject.name = "Subject%d" % player_id
	subject.set_multiplayer_authority(player_id)
	subject.accepts_local_input = false
	subject.stabilisation_rate = 0.0
	fixture.add_child(subject)


func _test_physical_entry_contract(compound: Compound) -> void:
	var openings: Array[Dictionary] = compound.get_residual_entry_openings()
	_expect(openings.size() == 7,
			"Adaptive Containment exposes seven authored facility entries")
	var kinds: Dictionary = {}
	for opening: Dictionary in openings:
		kinds[opening.kind] = true
		var opening_node := opening.node as Node3D
		_expect(opening_node.get_meta("physical_opening", false),
				"every Residual entry declares a physical opening")
		_expect(opening_node.get_child_count() >= 7,
				"every Residual entry has visible fixture geometry and path markers")
		_expect((opening.staging_transform as Transform3D).origin.distance_to(
				(opening.threshold_transform as Transform3D).origin) >= 4.0,
				"every Residual entry crosses from concealed staging to the Test Floor")
	for required_kind: StringName in [
		&"specimen_column", &"perimeter_pen", &"vent", &"wall_cavity",
	]:
		_expect(kinds.has(required_kind),
				"Adaptive Containment includes a %s entry" % required_kind)


func _test_facility_staged_wave(
	containment_round: PVERound,
	compound: Compound,
) -> void:
	var openings_by_id: Dictionary = {}
	for opening: Dictionary in compound.get_residual_entry_openings():
		openings_by_id[opening.id] = opening
	containment_round.spawn_wave()
	var residuals: Array[Node] = get_tree().get_nodes_in_group("residuals")
	_expect(residuals.size() == 2,
			"one Residual is staged per stable Subject in a wave")
	for residual_node: Node in residuals:
		var residual := residual_node as Residual
		residual.set_physics_process(false)
		_expect(not residual.entry_opening_id.is_empty()
				and openings_by_id.has(residual.entry_opening_id),
				"every Residual names an authored physical entry")
		if not openings_by_id.has(residual.entry_opening_id):
			continue
		var opening: Dictionary = openings_by_id[residual.entry_opening_id]
		_expect(not residual.entry_complete and not residual.visible,
				"a Residual begins concealed behind its opening")
		_expect(residual.global_position.distance_to(
				(opening.staging_transform as Transform3D).origin) <= 0.01,
				"a Residual begins at the opening's staging marker")
		residual.call("_advance_facility_entry", 0.2)
		_expect(residual.visible,
				"a Residual becomes visible only while crossing the fixture threshold")


func _test_subject_operated_tools(
	containment_round: PVERound,
	compound: Compound,
) -> void:
	var tools: Array[ContainmentTool] = compound.get_containment_tools()
	var effects: Dictionary = {}
	var tools_by_name: Dictionary = {}
	for tool: ContainmentTool in tools:
		effects[tool.effect_id] = true
		tools_by_name[tool.name] = tool
		_expect(tool.get_meta("subject_operated", false)
				and tool.is_in_group("environment_apparatus")
				and tool.has_method("interact"),
				"every encounter tool uses the Subject apparatus interaction seam")
	for effect_id: StringName in [
		ContainmentTool.EFFECT_BAIT,
		ContainmentTool.EFFECT_SHUTTER,
		ContainmentTool.EFFECT_POWER,
	]:
		_expect(effects.has(effect_id),
				"Adaptive Containment provides the %s encounter tool" % effect_id)

	var west_shutter: ContainmentTool = tools_by_name.get(&"EmergencyShutterWest")
	if west_shutter == null:
		_expect(false, "the west emergency shutter is present")
		return
	var entries_before: Array[StringName] = containment_round.available_entry_ids()
	west_shutter.interact(Enums.VerbType.BURN)
	_expect(west_shutter.is_active(),
			"a Subject interaction activates an emergency shutter")
	var entries_during: Array[StringName] = containment_round.available_entry_ids()
	for linked_id: StringName in west_shutter.linked_opening_ids:
		_expect(linked_id in entries_before and linked_id not in entries_during,
				"an active emergency shutter blocks its linked Residual entry")
	_expect(not entries_during.is_empty(),
			"emergency shutters retain at least one physical entry route")

	var residuals: Array[Node] = get_tree().get_nodes_in_group("residuals")
	if residuals.is_empty():
		_expect(false, "encounter tools require at least one staged Residual")
		return
	var bait: ContainmentTool = tools_by_name.get(&"BaitMachinery")
	if bait == null:
		_expect(false, "bait machinery is present")
		return
	bait.interact(Enums.VerbType.BURN)
	_expect(bait.is_active(), "a Subject interaction activates bait machinery")
	for residual_node: Node in residuals:
		_expect((residual_node as Residual).is_lured(),
				"bait machinery diverts every active Residual")

	var power_node: ContainmentTool = tools_by_name.get(&"DefensivePowerNode")
	if power_node == null:
		_expect(false, "the defensive power node is present")
		return
	var speed_before: float = (residuals[0] as Residual).get_speed()
	power_node.interact(Enums.VerbType.BURN)
	_expect(power_node.is_active(),
			"a Subject interaction activates the defensive power node")
	_expect((residuals[0] as Residual).get_speed() < speed_before,
			"the defensive power node slows the active encounter")


func _test_configurable_pressure(containment_round: PVERound) -> void:
	containment_round.elapsed = 0.0
	var opening_interval: float = containment_round.call(
			"_current_spawn_interval")
	var opening_strength: float = containment_round.call(
			"_current_strength_multiplier")
	containment_round.elapsed = 60.0
	_expect(containment_round.call("_current_spawn_interval") < opening_interval,
			"facility entry cadence still tightens over the Experiment")
	_expect(containment_round.call("_current_strength_multiplier") > opening_strength,
			"Residual strength still grows over the Experiment")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
