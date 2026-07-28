class_name Compound
extends Node3D
## Persistent Compound greybox and normal-Round confinement boundary.

const KIT_PIECE_SCENE: PackedScene = preload(
		"res://scenes/environment/EnvironmentKitPiece.tscn")

const LABORATORY_IDS: Array[StringName] = [
	&"AppliedCausality",
	&"CompetitiveStress",
	&"AdaptiveContainment",
]
const LABORATORY_NODE_NAMES: Dictionary = {
	&"AppliedCausality": &"AppliedCausalityLaboratory",
	&"CompetitiveStress": &"CompetitiveStressLaboratory",
	&"AdaptiveContainment": &"AdaptiveContainmentLaboratory",
}
const LABORATORY_APPARATUS: Dictionary = {
	&"AppliedCausality": &"RaisedResultReceiver",
	&"CompetitiveStress": &"ReinforcedImpactCrucible",
	&"AdaptiveContainment": &"SpecimenDeliveryColumn",
}
const PLANNING_GRID_M: float = 2.0
const DETAIL_INCREMENT_M: float = 1.0
const RADIAL_MODULE_DEGREES: float = 30.0
const TEST_FLOOR_SPAN_M: float = 52.0
const MAIN_PATH_WIDTH_M: float = 6.0
const SECONDARY_PATH_WIDTH_M: float = 3.0
const DOOR_CLEAR_WIDTH_M: float = 4.0
const DOOR_CLEAR_HEIGHT_M: float = 4.5
const BARRIER_HEIGHT_M: float = 1.2
const SUBJECT_CAPACITY: int = 24
const CRITICAL_CUE_ROTATION_SPEED: float = 2.4

const COLOUR_FLOOR := Color("c8ced1")
const COLOUR_STRUCTURE := Color("66727a")
const COLOUR_HEAVY := Color("273238")
const COLOUR_PANEL := Color("f1eee6")
const COLOUR_CUE := Color("f4c95d")

var active_laboratory_id: StringName = &""
var _piece_sequence: int = 0


func _ready() -> void:
	_build_central_core()
	_build_assignment_deck()
	_build_laboratories()
	_build_separator_spines()
	_build_perimeter_route()
	_build_dome_shell()
	select_active_laboratory(&"AppliedCausality")
	set_process(false)


func _process(delta: float) -> void:
	var has_active_cue: bool = false
	for laboratory_id: StringName in LABORATORY_IDS:
		var laboratory: Node3D = get_laboratory(laboratory_id)
		if not laboratory.get_meta("critical_state_active", false):
			continue
		has_active_cue = true
		var motion_hook: Node3D = laboratory.get_node(
				"CriticalCueHooks/MotionStateHook")
		motion_hook.rotation.y = wrapf(
				motion_hook.rotation.y + CRITICAL_CUE_ROTATION_SPEED * delta,
				0.0, TAU)
	if not has_active_cue:
		set_process(false)


func select_active_laboratory(laboratory_id: StringName) -> bool:
	if not LABORATORY_IDS.has(laboratory_id):
		push_warning("Compound: unknown Laboratory '%s'." % laboratory_id)
		return false
	active_laboratory_id = laboratory_id
	for candidate_id: StringName in LABORATORY_IDS:
		var laboratory: Node3D = get_laboratory(candidate_id)
		var is_active: bool = candidate_id == laboratory_id
		laboratory.set_meta("round_active", is_active)
		var round_content: Node3D = laboratory.get_node("RoundContent")
		round_content.process_mode = Node.PROCESS_MODE_INHERIT \
				if is_active else Node.PROCESS_MODE_DISABLED
		# Normal Rounds keep both connections physically closed. Selecting a
		# Laboratory changes authority/process ownership, never authored state.
		for shutter: Node in laboratory.get_node("Connections").get_children():
			if shutter is EnvironmentKitPiece:
				shutter.set_collision_active(true)
	return true


func get_laboratory(laboratory_id: StringName) -> Node3D:
	var node_name: StringName = LABORATORY_NODE_NAMES.get(laboratory_id, &"")
	return get_node_or_null("Laboratories/%s" % node_name) as Node3D


func get_laboratory_anchor_transform(laboratory_id: StringName) -> Transform3D:
	var laboratory: Node3D = get_laboratory(laboratory_id)
	if laboratory == null:
		return Transform3D.IDENTITY
	return laboratory.transform


func get_round_content(laboratory_id: StringName) -> Node3D:
	var laboratory: Node3D = get_laboratory(laboratory_id)
	if laboratory == null:
		return null
	return laboratory.get_node("RoundContent") as Node3D


func set_laboratory_critical_state(
	laboratory_id: StringName,
	active: bool,
) -> bool:
	var laboratory: Node3D = get_laboratory(laboratory_id)
	if laboratory == null:
		push_warning("Compound: unknown Laboratory '%s'." % laboratory_id)
		return false
	laboratory.set_meta("critical_state_active", active)
	var cues: Node3D = laboratory.get_node("CriticalCueHooks")
	cues.visible = active
	var geometry_hook: Node3D = cues.get_node("GeometryStateHook")
	geometry_hook.scale = Vector3(1.0, 1.35, 1.0) if active else Vector3.ONE
	if active:
		set_process(true)
	return true


func get_environment_kit_contract() -> Dictionary:
	return {
		"planning_grid_m": PLANNING_GRID_M,
		"detail_increment_m": DETAIL_INCREMENT_M,
		"radial_module_degrees": RADIAL_MODULE_DEGREES,
		"main_path_width_m": MAIN_PATH_WIDTH_M,
		"secondary_path_width_m": SECONDARY_PATH_WIDTH_M,
		"door_clear_width_m": DOOR_CLEAR_WIDTH_M,
		"door_clear_height_m": DOOR_CLEAR_HEIGHT_M,
		"barrier_height_m": BARRIER_HEIGHT_M,
		"piece_kinds": EnvironmentKitPiece.KIND_NAMES.duplicate(),
		"origin_contract": &"floor_centred",
		"collision_owner": &"GodotScene",
	}


func _build_central_core() -> void:
	var core: Node3D = $CentralCore
	_add_piece(core, &"PrimaryMachineryColumn", EnvironmentKitPiece.Kind.COLUMN,
			Vector3(18.0, 30.0, 18.0), Vector3.ZERO, 0.0, COLOUR_HEAVY)
	for index: int in 6:
		var angle: float = deg_to_rad(index * 60.0)
		_add_piece(core, &"CorePanel", EnvironmentKitPiece.Kind.PANEL,
				Vector3(4.0, 6.0, 0.5),
				Vector3(sin(angle) * 10.0, 2.0, -cos(angle) * 10.0),
				angle, COLOUR_PANEL, false)


func _build_assignment_deck() -> void:
	var deck: Node3D = $AssignmentDeck
	for index: int in 12:
		var angle: float = deg_to_rad(index * RADIAL_MODULE_DEGREES)
		var tangent_rotation: float = angle
		_add_piece(deck, &"AnnularFloorSegment",
				EnvironmentKitPiece.Kind.ANNULAR_FLOOR_SEGMENT,
				Vector3(9.0, 0.5, 6.0),
				Vector3(sin(angle) * 17.0, 5.5, -cos(angle) * 17.0),
				tangent_rotation, COLOUR_FLOOR)
		for radius: float in [13.5, 20.5]:
			_add_piece(deck, &"DeckRail", EnvironmentKitPiece.Kind.DECK_RAIL,
					Vector3(9.0, BARRIER_HEIGHT_M, 0.25),
					Vector3(sin(angle) * radius, 6.0, -cos(angle) * radius),
					tangent_rotation, COLOUR_STRUCTURE)
	for access_index: int in 3:
		var access_angle: float = deg_to_rad(access_index * 120.0)
		_add_piece(deck, &"RadialAccessSegment",
				EnvironmentKitPiece.Kind.RADIAL_FLOOR_SEGMENT,
				Vector3(MAIN_PATH_WIDTH_M, 0.5, 6.0),
				Vector3(sin(access_angle) * 22.0, 5.5,
						-cos(access_angle) * 22.0),
				access_angle, COLOUR_FLOOR)
	var booth: Node3D = deck.get_node("ResearcherBoothReserved")
	_add_piece(booth, &"BoothFloor", EnvironmentKitPiece.Kind.FLOOR_BAY,
			Vector3(6.0, 0.5, 4.0), Vector3(0.0, -0.5, 0.0), 0.0,
			COLOUR_CUE)
	_add_piece(booth, &"BoothBack", EnvironmentKitPiece.Kind.WALL_BAY,
			Vector3(6.0, 3.0, 0.5), Vector3(0.0, 0.0, -2.0), 0.0,
			COLOUR_PANEL)


func _build_laboratories() -> void:
	for laboratory_id: StringName in LABORATORY_IDS:
		var laboratory: Node3D = get_laboratory(laboratory_id)
		laboratory.set_meta("laboratory_id", laboratory_id)
		laboratory.set_meta("test_floor_span_m", TEST_FLOOR_SPAN_M)
		laboratory.set_meta("subject_capacity", SUBJECT_CAPACITY)
		laboratory.set_meta("landing_strategy_count", 3)
		laboratory.set_meta("valid_exit_count", 2)
		laboratory.set_meta("mandatory_choke_count", 0)
		laboratory.set_meta("dominant_apparatus",
				LABORATORY_APPARATUS[laboratory_id])
		laboratory.set_meta("other_layer_visibility", &"AssignmentDeck")
		laboratory.set_meta("critical_cue_channels",
				PackedStringArray(["geometry", "icon", "motion"]))
		_add_piece(laboratory, &"TestFloor", EnvironmentKitPiece.Kind.FLOOR_BAY,
				Vector3(TEST_FLOOR_SPAN_M, 0.5, TEST_FLOOR_SPAN_M),
				Vector3(0.0, -0.5, 0.0), 0.0, COLOUR_FLOOR)
		_build_lab_edges(laboratory)
		_build_landing_strategies(laboratory)
		_build_lab_apparatus(laboratory_id, laboratory)
		_build_lab_cue_hooks(laboratory)


func _build_lab_edges(laboratory: Node3D) -> void:
	for edge_data: Dictionary in [
		{"name": &"WestWall", "size": Vector3(1.0, 8.0, 52.0),
				"position": Vector3(-26.0, 0.0, 0.0), "rotation": 0.0},
		{"name": &"EastWall", "size": Vector3(1.0, 8.0, 52.0),
				"position": Vector3(26.0, 0.0, 0.0), "rotation": 0.0},
		{"name": &"OuterWallWest", "size": Vector3(32.0, 8.0, 1.0),
				"position": Vector3(-10.0, 0.0, -26.0), "rotation": 0.0},
		{"name": &"OuterWallEast", "size": Vector3(16.0, 8.0, 1.0),
				"position": Vector3(18.0, 0.0, -26.0), "rotation": 0.0},
		{"name": &"InnerWallWest", "size": Vector3(16.0, 8.0, 1.0),
				"position": Vector3(-18.0, 0.0, 26.0), "rotation": 0.0},
		{"name": &"InnerWallEast", "size": Vector3(32.0, 8.0, 1.0),
				"position": Vector3(10.0, 0.0, 26.0), "rotation": 0.0},
	]:
		_add_piece(laboratory, edge_data.name, EnvironmentKitPiece.Kind.WALL_BAY,
				edge_data.size, edge_data.position, edge_data.rotation,
				COLOUR_PANEL)
	var connections: Node3D = laboratory.get_node("Connections")
	_add_piece(connections, &"CoreDoorFrame4m",
			EnvironmentKitPiece.Kind.DOOR_FRAME_4M,
			Vector3(DOOR_CLEAR_WIDTH_M, DOOR_CLEAR_HEIGHT_M, 1.0),
			Vector3(-8.0, 0.0, 25.5), 0.0, COLOUR_STRUCTURE)
	_add_piece(connections, &"PerimeterDoorFrame4m",
			EnvironmentKitPiece.Kind.DOOR_FRAME_4M,
			Vector3(DOOR_CLEAR_WIDTH_M, DOOR_CLEAR_HEIGHT_M, 1.0),
			Vector3(8.0, 0.0, -25.5), 0.0, COLOUR_STRUCTURE)
	_add_piece(connections, &"CoreShutter4m",
			EnvironmentKitPiece.Kind.SHUTTER_4M,
			Vector3(DOOR_CLEAR_WIDTH_M, DOOR_CLEAR_HEIGHT_M, 0.5),
			Vector3(-8.0, 0.0, 25.5), 0.0, COLOUR_HEAVY)
	_add_piece(connections, &"PerimeterShutter4m",
			EnvironmentKitPiece.Kind.SHUTTER_4M,
			Vector3(DOOR_CLEAR_WIDTH_M, DOOR_CLEAR_HEIGHT_M, 0.5),
			Vector3(8.0, 0.0, -25.5), 0.0, COLOUR_HEAVY)


func _build_landing_strategies(laboratory: Node3D) -> void:
	var landing_areas: Node3D = laboratory.get_node("LandingAreas")
	var strategies: Array[Dictionary] = [
		{"name": &"ApparatusApproach", "position": Vector3(-14.0, 0.0, -10.0),
				"trade_off": &"fast_objective_exposed"},
		{"name": &"PerimeterShelter", "position": Vector3(15.0, 0.0, -8.0),
				"trade_off": &"protected_long_route"},
		{"name": &"ServiceAccess", "position": Vector3(0.0, 0.0, 17.0),
				"trade_off": &"route_choice_delayed_objective"},
	]
	for strategy: Dictionary in strategies:
		var area := Marker3D.new()
		area.name = strategy.name
		area.position = strategy.position
		area.set_meta("landing_strategy", strategy.trade_off)
		area.set_meta("recoverable", true)
		area.set_meta("route_width_m", MAIN_PATH_WIDTH_M)
		area.set_meta("exit_options", 2)
		landing_areas.add_child(area)
		_add_piece(area, &"LandingPad", EnvironmentKitPiece.Kind.PANEL,
				Vector3(8.0, 0.1, 8.0), Vector3.ZERO, 0.0, COLOUR_CUE, false)


func _build_lab_apparatus(
	laboratory_id: StringName,
	laboratory: Node3D,
) -> void:
	var apparatus: Node3D = laboratory.get_node("DominantApparatus")
	apparatus.name = LABORATORY_APPARATUS[laboratory_id]
	if laboratory_id == &"AppliedCausality":
		_add_piece(apparatus, &"ReceiverPlinth", EnvironmentKitPiece.Kind.COLUMN,
				Vector3(10.0, 3.0, 10.0), Vector3.ZERO, 0.0, COLOUR_HEAVY)
		_add_piece(apparatus, &"ResultReceiver",
				EnvironmentKitPiece.Kind.PANEL, Vector3(14.0, 2.0, 8.0),
				Vector3(0.0, 6.0, 0.0), 0.0, COLOUR_CUE)
		_add_piece(apparatus, &"TransferTruss", EnvironmentKitPiece.Kind.TRUSS,
				Vector3(4.0, 1.0, 22.0), Vector3(0.0, 9.0, -5.0),
				0.0, COLOUR_STRUCTURE)
	elif laboratory_id == &"CompetitiveStress":
		for segment: Dictionary in [
			{"position": Vector3(0.0, 0.0, -10.0),
					"size": Vector3(22.0, BARRIER_HEIGHT_M, 1.0)},
			{"position": Vector3(0.0, 0.0, 10.0),
					"size": Vector3(22.0, BARRIER_HEIGHT_M, 1.0)},
			{"position": Vector3(-10.0, 0.0, 0.0),
					"size": Vector3(1.0, BARRIER_HEIGHT_M, 18.0)},
			{"position": Vector3(10.0, 0.0, 0.0),
					"size": Vector3(1.0, BARRIER_HEIGHT_M, 18.0)},
		]:
			_add_piece(apparatus, &"CrucibleBarrier",
					EnvironmentKitPiece.Kind.DECK_RAIL, segment.size,
					segment.position, 0.0, COLOUR_HEAVY)
		for pylon_position: Vector3 in [
			Vector3(-13.0, 0.0, -13.0), Vector3(13.0, 0.0, -13.0),
			Vector3(-13.0, 0.0, 13.0), Vector3(13.0, 0.0, 13.0),
		]:
			_add_piece(apparatus, &"MeasurementPylon",
					EnvironmentKitPiece.Kind.COLUMN, Vector3(1.5, 7.0, 1.5),
					pylon_position, 0.0, COLOUR_CUE)
	else:
		_add_piece(apparatus, &"SpecimenColumn",
				EnvironmentKitPiece.Kind.COLUMN, Vector3(8.0, 14.0, 8.0),
				Vector3.ZERO, 0.0, COLOUR_HEAVY)
		for vent_index: int in 4:
			var angle: float = deg_to_rad(vent_index * 90.0)
			_add_piece(apparatus, &"SpecimenVent",
					EnvironmentKitPiece.Kind.VENT, Vector3(4.0, 3.0, 2.0),
					Vector3(sin(angle) * 12.0, 0.0, -cos(angle) * 12.0),
					angle, COLOUR_CUE)


func _build_lab_cue_hooks(laboratory: Node3D) -> void:
	var cues: Node3D = laboratory.get_node("CriticalCueHooks")
	cues.position = Vector3(0.0, 0.0, -18.0)
	var geometry_hook := Node3D.new()
	geometry_hook.name = "GeometryStateHook"
	geometry_hook.set_meta("cue_channel", &"geometry")
	cues.add_child(geometry_hook)
	_add_piece(geometry_hook, &"RaisedWarningFin",
			EnvironmentKitPiece.Kind.PANEL, Vector3(1.0, 6.0, 3.0),
			Vector3(-3.0, 0.0, 0.0), 0.0, COLOUR_CUE, false)
	_add_piece(geometry_hook, &"RaisedWarningFin",
			EnvironmentKitPiece.Kind.PANEL, Vector3(1.0, 6.0, 3.0),
			Vector3(3.0, 0.0, 0.0), 0.0, COLOUR_CUE, false)

	var icon_hook := Node3D.new()
	icon_hook.name = "IconStateHook"
	icon_hook.set_meta("cue_channel", &"icon")
	cues.add_child(icon_hook)
	_add_piece(icon_hook, &"AlertStem", EnvironmentKitPiece.Kind.PANEL,
			Vector3(1.5, 4.0, 0.6), Vector3(0.0, 3.0, 0.0), 0.0,
			COLOUR_PANEL, false)
	_add_piece(icon_hook, &"AlertPoint", EnvironmentKitPiece.Kind.PANEL,
			Vector3(1.5, 1.5, 0.6), Vector3(0.0, 0.5, 0.0), 0.0,
			COLOUR_PANEL, false)

	var motion_hook := Node3D.new()
	motion_hook.name = "MotionStateHook"
	motion_hook.set_meta("cue_channel", &"motion")
	motion_hook.set_meta("motion", &"continuous_rotation")
	cues.add_child(motion_hook)
	_add_piece(motion_hook, &"WarningSweep", EnvironmentKitPiece.Kind.TRUSS,
			Vector3(12.0, 0.5, 0.5), Vector3(0.0, 7.0, 0.0), 0.0,
			COLOUR_STRUCTURE, false)
	laboratory.set_meta("critical_state_active", false)
	cues.visible = false


func _build_separator_spines() -> void:
	var spines: Node3D = $SeparatorSpines
	for index: int in 3:
		var angle: float = deg_to_rad(60.0 + index * 120.0)
		var junction: EnvironmentKitPiece = _add_piece(
				spines, &"SpineJunction", EnvironmentKitPiece.Kind.SPINE_JUNCTION,
				Vector3(8.0, 8.0, 54.0),
				Vector3(sin(angle) * 42.0, 0.0, -cos(angle) * 42.0),
				angle, COLOUR_STRUCTURE)
		junction.set_meta("contains_shutter", true)
		junction.set_meta("secondary_path_width_m", SECONDARY_PATH_WIDTH_M)


func _build_perimeter_route() -> void:
	var route: Node3D = $PerimeterMaintenanceRoute
	route.set_meta("dependable_connection", true)
	route.set_meta("route_width_m", MAIN_PATH_WIDTH_M)
	route.set_meta("laboratories_connected", LABORATORY_IDS.duplicate())
	for index: int in 12:
		var angle: float = deg_to_rad(index * RADIAL_MODULE_DEGREES)
		_add_piece(route, &"PerimeterAnnularSegment",
				EnvironmentKitPiece.Kind.ANNULAR_FLOOR_SEGMENT,
				Vector3(38.0, 0.5, MAIN_PATH_WIDTH_M),
				Vector3(sin(angle) * 74.0, -0.5, -cos(angle) * 74.0),
				angle, COLOUR_STRUCTURE)


func _build_dome_shell() -> void:
	var shell: Node3D = $DomeShell
	shell.set_meta("shape", &"faceted_hemisphere")
	shell.set_meta("radial_module_degrees", RADIAL_MODULE_DEGREES)
	for index: int in 12:
		var angle: float = deg_to_rad(index * RADIAL_MODULE_DEGREES)
		var bay: EnvironmentKitPiece = _add_piece(
				shell, &"DomeShellBay", EnvironmentKitPiece.Kind.DOME_SHELL_BAY,
				Vector3(4.0, 1.0, 82.0),
				Vector3(sin(angle) * 38.0, 18.0, -cos(angle) * 38.0),
				angle, COLOUR_STRUCTURE, false)
		bay.rotation.x = deg_to_rad(-25.0)
	_add_piece(shell, &"ApexServiceRing", EnvironmentKitPiece.Kind.TRUSS,
			Vector3(20.0, 2.0, 20.0), Vector3(0.0, 40.0, 0.0), 0.0,
			COLOUR_HEAVY, false)


func _add_piece(
	parent: Node,
	base_name: StringName,
	kind: EnvironmentKitPiece.Kind,
	dimensions: Vector3,
	position: Vector3,
	rotation_y: float,
	colour: Color,
	with_collision: bool = true,
) -> EnvironmentKitPiece:
	var piece := KIT_PIECE_SCENE.instantiate() as EnvironmentKitPiece
	piece.configure(kind, dimensions, colour, with_collision)
	piece.name = "%s_%03d" % [base_name, _piece_sequence]
	_piece_sequence += 1
	piece.position = position
	piece.rotation.y = rotation_y
	parent.add_child(piece)
	return piece
