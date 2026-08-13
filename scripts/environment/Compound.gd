class_name Compound
extends Node3D
## Persistent Compound greybox and normal-Round confinement boundary.

const KIT_PIECE_SCENE: PackedScene = preload(
		"res://scenes/environment/EnvironmentKitPiece.tscn")
const CONTAINMENT_TOOL_SCENE: PackedScene = preload(
		"res://scenes/environment/ContainmentTool.tscn")

const LABORATORY_IDS: Array[StringName] = [
	&"AppliedAttrition",
	&"CompetitiveStress",
	&"AdaptiveContainment",
]
const LABORATORY_NODE_NAMES: Dictionary = {
	&"AppliedAttrition": &"AppliedAttritionLaboratory",
	&"CompetitiveStress": &"CompetitiveStressLaboratory",
	&"AdaptiveContainment": &"AdaptiveContainmentLaboratory",
}
const LABORATORY_APPARATUS: Dictionary = {
	&"AppliedAttrition": &"ElevatedDispensingArmature",
	&"CompetitiveStress": &"ReinforcedImpactCrucible",
	&"AdaptiveContainment": &"SpecimenDeliveryColumn",
}
const PLANNING_GRID_M: float = 2.0
const DETAIL_INCREMENT_M: float = 1.0
const RADIAL_MODULE_DEGREES: float = 30.0
const TEST_FLOOR_SPAN_M: float = 52.0
const MAIN_PATH_WIDTH_M: float = 6.0
const SECONDARY_PATH_WIDTH_M: float = 3.0
const ASSIGNMENT_DECK_RADIUS_M: float = 17.0
const PERIMETER_ROUTE_RADIUS_M: float = 73.0
const DOOR_CLEAR_WIDTH_M: float = 4.0
const DOOR_CLEAR_HEIGHT_M: float = 4.5
const BARRIER_HEIGHT_M: float = 1.2
const SUBJECT_CAPACITY: int = 24
const DISPENSING_TUBE_COLUMNS: int = 8
const DISPENSING_TUBE_SPACING_M: float = 2.0
const CRITICAL_CUE_ROTATION_SPEED: float = 2.4

const COLOUR_FLOOR := Color("c8ced1")
const COLOUR_STRUCTURE := Color("66727a")
const COLOUR_HEAVY := Color("273238")
const COLOUR_PANEL := Color("f1eee6")
const COLOUR_CUE := Color("f4c95d")
const COLOUR_SYSTEM := Color("56d6d2")
const COLOUR_DANGER := Color("ee625f")

var active_laboratory_id: StringName = &""
var _piece_sequence: int = 0
var _sightline_targets: Dictionary = {}


func _ready() -> void:
	_build_central_core()
	_build_assignment_deck()
	_build_collapse_deck_seals()
	_build_dispensing_line()
	_build_laboratories()
	_build_collapse_entry_sockets()
	_build_collapse_hazards()
	_build_separator_spines()
	_build_perimeter_route()
	_build_dome_shell()
	_register_facility_state_contracts()
	if not FacilityStateLedger.transition_recorded.is_connected(
			_on_facility_transition_recorded):
		FacilityStateLedger.transition_recorded.connect(
				_on_facility_transition_recorded)
	if not FacilityStateLedger.ledger_reset.is_connected(_on_facility_ledger_reset):
		FacilityStateLedger.ledger_reset.connect(_on_facility_ledger_reset)
	if not FacilityStateLedger.ledger_replicated.is_connected(
			_apply_replicated_facility_ledger):
		FacilityStateLedger.ledger_replicated.connect(
				_apply_replicated_facility_ledger)
	select_active_laboratory(&"AppliedAttrition")
	set_process(false)


func _exit_tree() -> void:
	if FacilityStateLedger.transition_recorded.is_connected(
			_on_facility_transition_recorded):
		FacilityStateLedger.transition_recorded.disconnect(
				_on_facility_transition_recorded)
	if FacilityStateLedger.ledger_reset.is_connected(_on_facility_ledger_reset):
		FacilityStateLedger.ledger_reset.disconnect(_on_facility_ledger_reset)
	if FacilityStateLedger.ledger_replicated.is_connected(
			_apply_replicated_facility_ledger):
		FacilityStateLedger.ledger_replicated.disconnect(
				_apply_replicated_facility_ledger)


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


## Composes the initial protected Collapse state. Every Laboratory becomes
## playable, the Assignment Deck is sealed, and Subjects occupy fair sockets
## while the service connections remain closed for orientation.
func begin_collapse(entry_assignments: Dictionary,
		subjects: Array[Node3D], surviving_ids: Array = []) -> bool:
	if entry_assignments.is_empty():
		return false
	active_laboratory_id = &""
	$AssignmentDeck.set_meta("access_sealed", true)
	_set_collapse_deck_seals(true)
	$PerimeterMaintenanceRoute.set_meta("collapse_open", false)
	$SeparatorSpines.set_meta("collapse_open", false)
	$CentralCore.set_meta("collapse_shortcuts_open", false)
	for laboratory_id: StringName in LABORATORY_IDS:
		var laboratory: Node3D = get_laboratory(laboratory_id)
		laboratory.set_meta("round_active", true)
		laboratory.set_meta("collapse_active", true)
		laboratory.get_node("RoundContent").process_mode = Node.PROCESS_MODE_INHERIT
		_set_connection_open(laboratory, &"PerimeterShutter4m", false)
		_set_connection_open(laboratory, &"SeparatorShutter4m", false)
		_set_connection_open(laboratory, &"CoreShutter4m", false)
	for subject: Node3D in subjects:
		var subject_id: int = subject.get_multiplayer_authority()
		if not entry_assignments.has(subject_id) \
				or subject_id not in surviving_ids:
			subject.visible = false
			subject.process_mode = Node.PROCESS_MODE_DISABLED
			continue
		var assignment: Dictionary = entry_assignments[subject_id]
		subject.global_transform = get_collapse_entry_transform(
				assignment.laboratory_id, assignment.socket_index)
		subject.visible = true
		subject.process_mode = Node.PROCESS_MODE_DISABLED
	return true


func open_collapse_perimeter_routes(subjects: Array[Node3D],
		surviving_ids: Array = []) -> void:
	$PerimeterMaintenanceRoute.set_meta("collapse_open", true)
	$SeparatorSpines.set_meta("collapse_open", true)
	for spine: Node in $SeparatorSpines.get_children():
		if spine is EnvironmentKitPiece:
			spine.set_collision_active(false)
	for laboratory_id: StringName in LABORATORY_IDS:
		_set_connection_open(get_laboratory(laboratory_id),
				&"PerimeterShutter4m", true)
		_set_connection_open(get_laboratory(laboratory_id),
				&"SeparatorShutter4m", true)
	for subject: Node3D in subjects:
		if subject.get_multiplayer_authority() in surviving_ids:
			subject.process_mode = Node.PROCESS_MODE_INHERIT


func open_collapse_core_shortcuts() -> void:
	$CentralCore.set_meta("collapse_shortcuts_open", true)
	for laboratory_id: StringName in LABORATORY_IDS:
		_set_connection_open(get_laboratory(laboratory_id),
				&"CoreShutter4m", true)


func telegraph_collapse_failure(laboratory_id: StringName) -> void:
	set_laboratory_critical_state(laboratory_id, true)
	var hazard: Area3D = $CollapseHazards.get_node_or_null(
			NodePath("%sFailure" % laboratory_id)) as Area3D
	if hazard != null:
		hazard.set_meta("telegraphed", true)
		var warning_visual := hazard.get_node_or_null(
				"WarningVisual") as MeshInstance3D
		if warning_visual != null:
			warning_visual.visible = true


func apply_collapse_failure(laboratory_id: StringName) -> void:
	var hazard: Area3D = $CollapseHazards.get_node_or_null(
			NodePath("%sFailure" % laboratory_id)) as Area3D
	if hazard != null:
		hazard.monitoring = true
		hazard.set_meta("active", true)


func reset_collapse(subjects: Array[Node3D] = []) -> void:
	$AssignmentDeck.set_meta("access_sealed", false)
	_set_collapse_deck_seals(false)
	$PerimeterMaintenanceRoute.set_meta("collapse_open", false)
	$SeparatorSpines.set_meta("collapse_open", false)
	for spine: Node in $SeparatorSpines.get_children():
		if spine is EnvironmentKitPiece:
			spine.set_collision_active(true)
	$CentralCore.set_meta("collapse_shortcuts_open", false)
	for laboratory_id: StringName in LABORATORY_IDS:
		var laboratory: Node3D = get_laboratory(laboratory_id)
		laboratory.set_meta("collapse_active", false)
		set_laboratory_critical_state(laboratory_id, false)
		var hazard: Area3D = $CollapseHazards.get_node_or_null(
				NodePath("%sFailure" % laboratory_id)) as Area3D
		if hazard != null:
			hazard.monitoring = false
			hazard.set_meta("active", false)
			hazard.set_meta("telegraphed", false)
			var warning_visual := hazard.get_node_or_null(
					"WarningVisual") as MeshInstance3D
			if warning_visual != null:
				warning_visual.visible = false
	for subject: Node3D in subjects:
		subject.visible = true
		subject.process_mode = Node.PROCESS_MODE_INHERIT


func get_collapse_entry_transform(laboratory_id: StringName,
		socket_index: int) -> Transform3D:
	var socket := $CollapseEntrySockets.get_node_or_null(
			"%sSocket%02d" % [laboratory_id, socket_index]) as Marker3D
	return socket.global_transform if socket != null else Transform3D.IDENTITY


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


## Authored Adaptive Containment openings. Each entry exposes a concealed
## staging transform and a visible Test Floor threshold; PVERound never invents
## a positional fallback when this contract is unavailable.
func get_residual_entry_openings() -> Array[Dictionary]:
	var openings: Array[Dictionary] = []
	var laboratory: Node3D = get_laboratory(&"AdaptiveContainment")
	if laboratory == null:
		return openings
	var container := laboratory.get_node_or_null(
			"RoundContent/ResidualEntryOpenings") as Node3D
	if container == null:
		return openings
	for child: Node in container.get_children():
		if not child is Node3D or not child.has_node("Staging") \
				or not child.has_node("Threshold"):
			continue
		var opening := child as Node3D
		openings.append({
			"id": StringName(opening.get_meta("entry_id", opening.name)),
			"kind": StringName(opening.get_meta("entry_kind", &"")),
			"blocked_by": StringName(opening.get_meta("blocked_by", &"")),
			"staging_transform": (opening.get_node("Staging") as Marker3D).global_transform,
			"threshold_transform": (opening.get_node("Threshold") as Marker3D).global_transform,
			"node": opening,
		})
	return openings


func get_containment_tools() -> Array[ContainmentTool]:
	var tools: Array[ContainmentTool] = []
	var laboratory: Node3D = get_laboratory(&"AdaptiveContainment")
	if laboratory == null:
		return tools
	var container := laboratory.get_node_or_null(
			"RoundContent/EncounterTools") as Node3D
	if container == null:
		return tools
	for child: Node in container.get_children():
		if child is ContainmentTool:
			tools.append(child)
	return tools


func get_dispensing_line_tube_transform(tube_index: int) -> Transform3D:
	if tube_index < 0 or tube_index >= SUBJECT_CAPACITY:
		return Transform3D.IDENTITY
	var socket := $AssignmentDeck/DispensingLine.get_node_or_null(
			"Tube%02d" % tube_index) as Marker3D
	return socket.global_transform if socket != null else Transform3D.IDENTITY


func get_drop_socket_transform(
	laboratory_id: StringName,
	tube_index: int,
) -> Transform3D:
	return _laboratory_socket_transform(laboratory_id, &"DropSockets", tube_index)


func get_recall_aperture_transform(
	laboratory_id: StringName,
	tube_index: int,
) -> Transform3D:
	return _laboratory_socket_transform(laboratory_id, &"RecallApertures", tube_index)


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


func _register_facility_state_contracts() -> void:
	var thresholds: Array[StringName] = [
		&"pristine", &"stressed", &"breached", &"destroyed",
	]
	for laboratory_id: StringName in LABORATORY_IDS:
		FacilityStateLedger.register_laboratory(laboratory_id, [
			&"apparatus_approach", &"perimeter_shelter", &"service_access",
		])
		FacilityStateLedger.register_structural_surface(
				laboratory_id, &"TestFloor", &"floor")
		FacilityStateLedger.register_structural_surface(
				laboratory_id, &"StructuralWalls", &"wall")
		FacilityStateLedger.register_prop(laboratory_id,
				LABORATORY_APPARATUS[laboratory_id], thresholds,
				{
					&"pristine": true,
					&"stressed": true,
					&"breached": true,
					&"destroyed": false,
				}, {
					&"breached": [&"apparatus_approach"],
					&"destroyed": [&"apparatus_approach"],
				})


func _on_facility_transition_recorded(entry: Dictionary) -> void:
	var laboratory_id: StringName = entry.get("laboratory_id", &"")
	var laboratory: Node3D = get_laboratory(laboratory_id)
	if laboratory == null:
		return
	laboratory.set_meta("facility_round_stage",
			FacilityStateLedger.laboratories[laboratory_id].round_stage)
	laboratory.set_meta("facility_experiment_lifecycle",
			FacilityStateLedger.laboratories[laboratory_id].experiment_lifecycle)
	var details: Dictionary = entry.get("details", {})
	if details.has("surface_id"):
		laboratory.set_meta("%s_cosmetic_state" % details.surface_id,
				details.cosmetic_state)
	if not details.has("prop_id"):
		return
	var apparatus_name: StringName = LABORATORY_APPARATUS.get(laboratory_id, &"")
	if details.prop_id != apparatus_name:
		return
	laboratory.set_meta("authored_scene_state", details.threshold)
	var apparatus: Node3D = laboratory.get_node_or_null(
			NodePath(apparatus_name)) as Node3D
	if apparatus != null and details.collision_active != null:
		_set_descendant_collision_active(apparatus, details.collision_active)


func _on_facility_ledger_reset() -> void:
	for laboratory_id: StringName in LABORATORY_IDS:
		var laboratory: Node3D = get_laboratory(laboratory_id)
		laboratory.set_meta("facility_round_stage", &"controlled")
		laboratory.set_meta("facility_experiment_lifecycle", &"idle")
		laboratory.set_meta("authored_scene_state", &"pristine")
		laboratory.set_meta("TestFloor_cosmetic_state", &"pristine")
		laboratory.set_meta("StructuralWalls_cosmetic_state", &"pristine")
		var apparatus: Node3D = laboratory.get_node_or_null(
				NodePath(LABORATORY_APPARATUS[laboratory_id])) as Node3D
		if apparatus != null:
			_set_descendant_collision_active(apparatus, true)


func _apply_replicated_facility_ledger() -> void:
	for laboratory_id: StringName in LABORATORY_IDS:
		if not FacilityStateLedger.laboratories.has(laboratory_id):
			continue
		var state: Dictionary = FacilityStateLedger.laboratories[laboratory_id]
		var laboratory: Node3D = get_laboratory(laboratory_id)
		laboratory.set_meta("facility_round_stage", state.round_stage)
		laboratory.set_meta(
				"facility_experiment_lifecycle", state.experiment_lifecycle)
		for surface_id: StringName in state.structural_surfaces:
			laboratory.set_meta("%s_cosmetic_state" % surface_id,
					state.structural_surfaces[surface_id].cosmetic_state)
		var apparatus_name: StringName = LABORATORY_APPARATUS[laboratory_id]
		if not state.props.has(apparatus_name):
			continue
		var prop: Dictionary = state.props[apparatus_name]
		var threshold: StringName = prop.thresholds[prop.threshold_index]
		laboratory.set_meta("authored_scene_state", threshold)
		var apparatus: Node3D = laboratory.get_node_or_null(
				NodePath(apparatus_name)) as Node3D
		var collision_active: Variant = prop.collision_by_threshold.get(
				threshold, null)
		if apparatus != null and collision_active != null:
			_set_descendant_collision_active(apparatus, collision_active)


func _set_descendant_collision_active(node: Node,
		collision_active: bool) -> void:
	if node is EnvironmentKitPiece:
		(node as EnvironmentKitPiece).set_collision_active(collision_active)
	for child: Node in node.get_children():
		_set_descendant_collision_active(child, collision_active)


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
		var tangent_rotation: float = -angle
		_add_piece(deck, &"AnnularFloorSegment",
				EnvironmentKitPiece.Kind.ANNULAR_FLOOR_SEGMENT,
				Vector3(
						_annular_tangent_span(
								ASSIGNMENT_DECK_RADIUS_M, MAIN_PATH_WIDTH_M),
						0.5,
						MAIN_PATH_WIDTH_M),
				_radial_module_centre(ASSIGNMENT_DECK_RADIUS_M, 5.5, angle),
				tangent_rotation, COLOUR_FLOOR, true, ASSIGNMENT_DECK_RADIUS_M)
		for radius: float in [13.5, 20.5]:
			_add_piece(deck, &"DeckRail", EnvironmentKitPiece.Kind.DECK_RAIL,
					Vector3(
							_annular_tangent_span(radius, 0.25),
							BARRIER_HEIGHT_M,
							0.25),
					_radial_module_centre(radius, 6.0, angle),
					tangent_rotation, COLOUR_STRUCTURE, true, radius)
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
	var sightline_targets: Node3D = deck.get_node("SightlineTargets")
	for laboratory_index: int in LABORATORY_IDS.size():
		var laboratory_id: StringName = LABORATORY_IDS[laboratory_index]
		var angle: float = deg_to_rad(laboratory_index * 120.0)
		var fascia: EnvironmentKitPiece = _add_piece(
				sightline_targets,
				StringName("%sSightlineFascia" % laboratory_id),
				EnvironmentKitPiece.Kind.PANEL,
				Vector3(4.0, 2.0, 0.25),
				_radial_module_centre(
						ASSIGNMENT_DECK_RADIUS_M, 3.5, angle),
				-angle,
				COLOUR_CUE,
				false)
		fascia.set_meta("laboratory_id", laboratory_id)
		var target := Marker3D.new()
		target.name = "VisibilityTarget"
		target.position = Vector3(0.0, 1.0, -0.4)
		fascia.add_child(target)
		_sightline_targets[laboratory_id] = target


func _build_collapse_deck_seals() -> void:
	var seals: Node3D = $AssignmentDeck/CollapseSeals
	for access_index: int in 3:
		var angle: float = deg_to_rad(access_index * 120.0)
		var seal: EnvironmentKitPiece = _add_piece(
				seals, &"AssignmentDeckSeal", EnvironmentKitPiece.Kind.SHUTTER_4M,
				Vector3(DOOR_CLEAR_WIDTH_M, DOOR_CLEAR_HEIGHT_M, 0.5),
				Vector3(sin(angle) * 22.0, 5.5, -cos(angle) * 22.0),
				angle, COLOUR_HEAVY)
		seal.visible = false
		seal.set_collision_active(false)


func _set_collapse_deck_seals(active: bool) -> void:
	for seal: Node in $AssignmentDeck/CollapseSeals.get_children():
		if seal is EnvironmentKitPiece:
			seal.visible = active
			seal.set_collision_active(active)


## The Assignment Deck owns one visible overhead tube per supported Subject.
## Sequential indices are physically adjacent, which makes a Pair's canonical
## contiguous assignment visible without coupling either Subject's Release.
func _build_dispensing_line() -> void:
	var line: Node3D = $AssignmentDeck/DispensingLine
	line.set_meta("subject_capacity", SUBJECT_CAPACITY)
	line.set_meta("pair_tubes_adjacent", true)
	_add_piece(line, &"OverheadCarrier", EnvironmentKitPiece.Kind.TRUSS,
			Vector3(18.0, 1.0, 8.0), Vector3(0.0, 10.0, 0.0), 0.0,
			COLOUR_STRUCTURE, false)
	for tube_index: int in SUBJECT_CAPACITY:
		var row: int = tube_index / DISPENSING_TUBE_COLUMNS
		var raw_column: int = tube_index % DISPENSING_TUBE_COLUMNS
		var column: int = raw_column if row % 2 == 0 \
				else DISPENSING_TUBE_COLUMNS - 1 - raw_column
		var socket := Marker3D.new()
		socket.name = "Tube%02d" % tube_index
		socket.position = Vector3(
				(column - (DISPENSING_TUBE_COLUMNS - 1) * 0.5)
						* DISPENSING_TUBE_SPACING_M,
				7.0 + row * 0.15,
				(row - 1) * DISPENSING_TUBE_SPACING_M)
		socket.set_meta("tube_index", tube_index)
		line.add_child(socket)
		_add_piece(socket, &"TubeHousing", EnvironmentKitPiece.Kind.COLUMN,
				Vector3(1.4, 3.0, 1.4), Vector3(0.0, 0.0, 0.0), 0.0,
				COLOUR_PANEL, false)


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
		var sightline := laboratory.get_node(
				"SightlineToAssignmentDeck") as Marker3D
		var sightline_target := _sightline_targets[laboratory_id] as Marker3D
		sightline.set_meta(
				"target_node_path", sightline.get_path_to(sightline_target))
		_add_piece(laboratory, &"TestFloor", EnvironmentKitPiece.Kind.FLOOR_BAY,
				Vector3(TEST_FLOOR_SPAN_M, 0.5, TEST_FLOOR_SPAN_M),
				Vector3(0.0, -0.5, 0.0), 0.0, COLOUR_FLOOR)
		_build_lab_edges(laboratory)
		_build_landing_strategies(laboratory)
		_build_laboratory_transit(laboratory)
		_build_lab_apparatus(laboratory_id, laboratory)
		if laboratory_id == &"AdaptiveContainment":
			_build_adaptive_containment_infrastructure(laboratory)
		_build_lab_cue_hooks(laboratory)


func _build_collapse_entry_sockets() -> void:
	var sockets: Node3D = $CollapseEntrySockets
	var local_positions: Array[Vector3] = [
		Vector3(-17.0, 0.5, -15.0), Vector3(0.0, 0.5, -17.0),
		Vector3(17.0, 0.5, -15.0), Vector3(-18.0, 0.5, 2.0),
		Vector3(18.0, 0.5, 2.0), Vector3(-15.0, 0.5, 17.0),
		Vector3(0.0, 0.5, 18.0), Vector3(15.0, 0.5, 17.0),
	]
	for laboratory_id: StringName in LABORATORY_IDS:
		var laboratory: Node3D = get_laboratory(laboratory_id)
		for socket_index: int in local_positions.size():
			var socket := Marker3D.new()
			socket.name = "%sSocket%02d" % [laboratory_id, socket_index]
			socket.transform = laboratory.transform * Transform3D(
					Basis.IDENTITY, local_positions[socket_index])
			socket.set_meta("laboratory_id", laboratory_id)
			socket.set_meta("hazard_exposure", 1.0)
			socket.set_meta("exit_count", 2)
			socket.set_meta("protected_orientation", true)
			sockets.add_child(socket)


func _build_collapse_hazards() -> void:
	var hazards: Node3D = $CollapseHazards
	for laboratory_id: StringName in LABORATORY_IDS:
		var laboratory: Node3D = get_laboratory(laboratory_id)
		var area := Area3D.new()
		area.name = "%sFailure" % laboratory_id
		area.transform = laboratory.transform * Transform3D(
				Basis.IDENTITY, Vector3(0.0, 0.5, 0.0))
		area.monitoring = false
		area.set_meta("authored_failure", true)
		area.set_meta("telegraphed", false)
		area.set_meta("active", false)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(14.0, 2.0, 14.0)
		shape.shape = box
		area.add_child(shape)
		var warning_visual := MeshInstance3D.new()
		warning_visual.name = "WarningVisual"
		var warning_mesh := BoxMesh.new()
		warning_mesh.size = Vector3(14.0, 0.12, 14.0)
		warning_visual.mesh = warning_mesh
		warning_visual.position.y = 0.08
		var warning_material := StandardMaterial3D.new()
		warning_material.albedo_color = Color(0.933, 0.384, 0.373, 0.42)
		warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		warning_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		warning_material.emission_enabled = true
		warning_material.emission = Color("ee625f")
		warning_mesh.material = warning_material
		warning_visual.visible = false
		area.add_child(warning_visual)
		area.body_entered.connect(CollapseManager.report_hazard_fall)
		hazards.add_child(area)


func _set_connection_open(laboratory: Node3D,
		shutter_prefix: StringName, is_open: bool) -> void:
	for connection: Node in laboratory.get_node("Connections").get_children():
		if connection is EnvironmentKitPiece \
				and String(connection.name).begins_with(shutter_prefix):
			connection.visible = not is_open
			connection.set_collision_active(not is_open)


func _build_lab_edges(laboratory: Node3D) -> void:
	for edge_data: Dictionary in [
		{"name": &"WestWallNorth", "size": Vector3(1.0, 8.0, 24.0),
				"position": Vector3(-26.0, 0.0, -14.0), "rotation": 0.0},
		{"name": &"WestWallSouth", "size": Vector3(1.0, 8.0, 24.0),
				"position": Vector3(-26.0, 0.0, 14.0), "rotation": 0.0},
		{"name": &"EastWallNorth", "size": Vector3(1.0, 8.0, 24.0),
				"position": Vector3(26.0, 0.0, -14.0), "rotation": 0.0},
		{"name": &"EastWallSouth", "size": Vector3(1.0, 8.0, 24.0),
				"position": Vector3(26.0, 0.0, 14.0), "rotation": 0.0},
		{"name": &"OuterWallWest", "size": Vector3(32.0, 8.0, 1.0),
				"position": Vector3(-10.0, 0.0, -26.0), "rotation": 0.0},
		{"name": &"OuterWallEast", "size": Vector3(16.0, 8.0, 1.0),
				"position": Vector3(18.0, 0.0, -26.0), "rotation": 0.0},
		{"name": &"InnerWallWest", "size": Vector3(16.0, 8.0, 1.0),
				"position": Vector3(-18.0, 0.0, 26.0), "rotation": 0.0},
		{"name": &"InnerWallSightlineWest",
				"size": Vector3(4.0, 8.0, 1.0),
				"position": Vector3(-4.0, 0.0, 26.0), "rotation": 0.0},
		{"name": &"InnerWallSightlineSill",
				"size": Vector3(4.0, 2.5, 1.0),
				"position": Vector3(0.0, 0.0, 26.0), "rotation": 0.0},
		{"name": &"InnerWallSightlineHeader",
				"size": Vector3(4.0, 1.5, 1.0),
				"position": Vector3(0.0, 6.5, 26.0), "rotation": 0.0},
		{"name": &"InnerWallEast", "size": Vector3(24.0, 8.0, 1.0),
				"position": Vector3(14.0, 0.0, 26.0), "rotation": 0.0},
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
	for side: float in [-1.0, 1.0]:
		_add_piece(connections, &"SeparatorDoorFrame4m",
				EnvironmentKitPiece.Kind.DOOR_FRAME_4M,
				Vector3(DOOR_CLEAR_WIDTH_M, DOOR_CLEAR_HEIGHT_M, 1.0),
				Vector3(side * 25.5, 0.0, 0.0), PI * 0.5,
				COLOUR_STRUCTURE)
	_add_piece(connections, &"CoreShutter4m",
			EnvironmentKitPiece.Kind.SHUTTER_4M,
			Vector3(DOOR_CLEAR_WIDTH_M, DOOR_CLEAR_HEIGHT_M, 0.5),
			Vector3(-8.0, 0.0, 25.5), 0.0, COLOUR_HEAVY)
	_add_piece(connections, &"PerimeterShutter4m",
			EnvironmentKitPiece.Kind.SHUTTER_4M,
			Vector3(DOOR_CLEAR_WIDTH_M, DOOR_CLEAR_HEIGHT_M, 0.5),
			Vector3(8.0, 0.0, -25.5), 0.0, COLOUR_HEAVY)
	for side: float in [-1.0, 1.0]:
		_add_piece(connections, &"SeparatorShutter4m",
				EnvironmentKitPiece.Kind.SHUTTER_4M,
				Vector3(DOOR_CLEAR_WIDTH_M, DOOR_CLEAR_HEIGHT_M, 0.5),
				Vector3(side * 25.5, 0.0, 0.0), PI * 0.5,
				COLOUR_HEAVY)


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


func _build_laboratory_transit(laboratory: Node3D) -> void:
	var drop_sockets: Node3D = laboratory.get_node("DropSockets")
	var recall_apertures: Node3D = laboratory.get_node("RecallApertures")
	for tube_index: int in SUBJECT_CAPACITY:
		var row: int = tube_index / DISPENSING_TUBE_COLUMNS
		var column: int = tube_index % DISPENSING_TUBE_COLUMNS
		var lateral: float = (column - (DISPENSING_TUBE_COLUMNS - 1) * 0.5) * 3.0
		var depth: float = (row - 1) * 4.0
		var drop_socket := Marker3D.new()
		drop_socket.name = "Socket%02d" % tube_index
		drop_socket.position = Vector3(lateral, 16.0, depth)
		drop_socket.set_meta("independent_release", true)
		drop_sockets.add_child(drop_socket)

		var recall_aperture := Marker3D.new()
		recall_aperture.name = "Socket%02d" % tube_index
		recall_aperture.position = Vector3(lateral, 0.05, 18.0 + row * 2.0)
		recall_aperture.set_meta("reversed_pressure", true)
		recall_apertures.add_child(recall_aperture)
		_add_piece(recall_aperture, &"CollectionAperture",
				EnvironmentKitPiece.Kind.PANEL, Vector3(2.4, 0.08, 1.6),
				Vector3.ZERO, 0.0, COLOUR_HEAVY, false)


func _laboratory_socket_transform(
	laboratory_id: StringName,
	container_name: StringName,
	tube_index: int,
) -> Transform3D:
	if tube_index < 0 or tube_index >= SUBJECT_CAPACITY:
		return Transform3D.IDENTITY
	var laboratory: Node3D = get_laboratory(laboratory_id)
	if laboratory == null:
		return Transform3D.IDENTITY
	var socket := laboratory.get_node_or_null(
			"%s/Socket%02d" % [container_name, tube_index]) as Marker3D
	return socket.global_transform if socket != null else Transform3D.IDENTITY


func _build_lab_apparatus(
	laboratory_id: StringName,
	laboratory: Node3D,
) -> void:
	var apparatus: Node3D = laboratory.get_node("DominantApparatus")
	apparatus.name = LABORATORY_APPARATUS[laboratory_id]
	if laboratory_id == &"AppliedAttrition":
		_add_piece(apparatus, &"ArmatureSupport",
				EnvironmentKitPiece.Kind.COLUMN, Vector3(5.0, 12.0, 5.0),
				Vector3(0.0, 5.5, 0.0), 0.0, COLOUR_HEAVY)
		_add_piece(apparatus, &"MaterialDispenser",
				EnvironmentKitPiece.Kind.PANEL, Vector3(12.0, 2.0, 6.0),
				Vector3(0.0, 11.0, 0.0), 0.0, COLOUR_CUE)
		_add_piece(apparatus, &"DispensingTruss",
				EnvironmentKitPiece.Kind.TRUSS, Vector3(4.0, 1.0, 22.0),
				Vector3(0.0, 14.0, -5.0),
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


func _build_adaptive_containment_infrastructure(laboratory: Node3D) -> void:
	var openings: Node3D = laboratory.get_node(
			"RoundContent/ResidualEntryOpenings")
	_add_residual_entry_opening(openings, &"SpecimenColumnChute",
			&"specimen_column", Vector3(0.0, 0.0, -5.5), PI)
	_add_residual_entry_opening(openings, &"PerimeterPenWest",
			&"perimeter_pen", Vector3(-17.0, 0.0, -20.0), 0.0,
			&"EmergencyShutterWest")
	_add_residual_entry_opening(openings, &"PerimeterPenEast",
			&"perimeter_pen", Vector3(17.0, 0.0, -20.0), 0.0,
			&"EmergencyShutterEast")
	_add_residual_entry_opening(openings, &"WestVent",
			&"vent", Vector3(-22.0, 0.0, -8.0), PI * 0.5,
			&"EmergencyShutterWest")
	_add_residual_entry_opening(openings, &"EastVent",
			&"vent", Vector3(22.0, 0.0, -8.0), -PI * 0.5,
			&"EmergencyShutterEast")
	_add_residual_entry_opening(openings, &"WestWallCavity",
			&"wall_cavity", Vector3(-22.0, 0.0, 12.0), PI * 0.5,
			&"EmergencyShutterWest")
	_add_residual_entry_opening(openings, &"EastWallCavity",
			&"wall_cavity", Vector3(22.0, 0.0, 12.0), -PI * 0.5,
			&"EmergencyShutterEast")

	var tools: Node3D = laboratory.get_node("RoundContent/EncounterTools")
	_add_containment_tool(tools, &"BaitMachinery",
			ContainmentTool.EFFECT_BAIT, Vector3(-10.0, 0.0, 5.0), [], 8.0, 12.0)
	_add_containment_tool(tools, &"EmergencyShutterWest",
			ContainmentTool.EFFECT_SHUTTER, Vector3(-16.0, 0.0, -12.0), [
				&"PerimeterPenWest", &"WestVent", &"WestWallCavity",
			], 7.0, 12.0)
	_add_containment_tool(tools, &"EmergencyShutterEast",
			ContainmentTool.EFFECT_SHUTTER, Vector3(16.0, 0.0, -12.0), [
				&"PerimeterPenEast", &"EastVent", &"EastWallCavity",
			], 7.0, 12.0)
	_add_containment_tool(tools, &"DefensivePowerNode",
			ContainmentTool.EFFECT_POWER, Vector3(0.0, 0.0, 12.0), [], 6.0, 14.0)
	laboratory.set_meta("residual_entry_types", PackedStringArray([
		"specimen_column", "perimeter_pen", "vent", "wall_cavity",
	]))
	laboratory.set_meta("encounter_tools", PackedStringArray([
		"bait", "shutter", "power",
	]))


func _add_residual_entry_opening(
	parent: Node3D,
	entry_id: StringName,
	entry_kind: StringName,
	position: Vector3,
	rotation_y: float,
	blocked_by: StringName = &"",
) -> void:
	var opening := Node3D.new()
	opening.name = entry_id
	opening.position = position
	opening.rotation.y = rotation_y
	opening.set_meta("entry_id", entry_id)
	opening.set_meta("entry_kind", entry_kind)
	opening.set_meta("blocked_by", blocked_by)
	opening.set_meta("physical_opening", true)
	opening.set_meta("clear_width_m", DOOR_CLEAR_WIDTH_M)
	parent.add_child(opening)

	var staging := Marker3D.new()
	staging.name = "Staging"
	staging.position = Vector3(0.0, 0.0, -2.2)
	staging.set_meta("concealed", true)
	opening.add_child(staging)
	var threshold := Marker3D.new()
	threshold.name = "Threshold"
	threshold.position = Vector3(0.0, 0.0, 2.2)
	threshold.set_meta("on_test_floor", true)
	opening.add_child(threshold)

	_add_piece(opening, &"OpeningPost", EnvironmentKitPiece.Kind.COLUMN,
			Vector3(0.5, 3.4, 0.8), Vector3(-2.0, 0.0, 0.0), 0.0,
			COLOUR_STRUCTURE, false)
	_add_piece(opening, &"OpeningPost", EnvironmentKitPiece.Kind.COLUMN,
			Vector3(0.5, 3.4, 0.8), Vector3(2.0, 0.0, 0.0), 0.0,
			COLOUR_STRUCTURE, false)
	_add_piece(opening, &"OpeningHeader", EnvironmentKitPiece.Kind.TRUSS,
			Vector3(4.5, 0.6, 0.8), Vector3(0.0, 3.0, 0.0), 0.0,
			COLOUR_STRUCTURE, false)
	_add_piece(opening, &"ConcealmentBacking", EnvironmentKitPiece.Kind.PANEL,
			Vector3(4.5, 3.4, 0.4), Vector3(0.0, 0.0, -2.8), 0.0,
			COLOUR_HEAVY, false)
	var type_colour: Color = COLOUR_SYSTEM
	if entry_kind == &"perimeter_pen":
		type_colour = COLOUR_CUE
	elif entry_kind == &"wall_cavity":
		type_colour = COLOUR_DANGER
	_add_piece(opening, &"EntryTypePanel", EnvironmentKitPiece.Kind.PANEL,
			Vector3(2.5, 0.4, 0.2), Vector3(0.0, 2.4, 0.5), 0.0,
			type_colour, false)
	if entry_kind == &"specimen_column":
		_add_piece(opening, &"DeliveryChute", EnvironmentKitPiece.Kind.VENT,
				Vector3(3.2, 1.4, 2.8), Vector3(0.0, 1.0, -1.3), 0.0,
				COLOUR_HEAVY, false)
	elif entry_kind == &"perimeter_pen":
		for side: float in [-1.0, 1.0]:
			_add_piece(opening, &"PenRail", EnvironmentKitPiece.Kind.DECK_RAIL,
					Vector3(0.25, 1.4, 5.0), Vector3(side * 2.8, 0.0, -1.0),
					0.0, COLOUR_CUE, false)
	elif entry_kind == &"vent":
		for louvre_index: int in 3:
			_add_piece(opening, &"VentLouvre", EnvironmentKitPiece.Kind.PANEL,
					Vector3(3.4, 0.25, 0.35),
					Vector3(0.0, 0.8 + louvre_index * 0.7, -0.35),
					0.0, COLOUR_SYSTEM, false)
	elif entry_kind == &"wall_cavity":
		for side: float in [-1.0, 1.0]:
			_add_piece(opening, &"CavityCheek", EnvironmentKitPiece.Kind.WALL_BAY,
					Vector3(0.8, 3.4, 3.0), Vector3(side * 2.2, 0.0, -1.2),
					0.0, COLOUR_HEAVY, false)
	if not blocked_by.is_empty():
		var blade: EnvironmentKitPiece = _add_piece(opening,
				&"EmergencyShutterBlade", EnvironmentKitPiece.Kind.SHUTTER_4M,
				Vector3(3.6, 3.0, 0.25), Vector3(0.0, 0.0, 0.15), 0.0,
				COLOUR_DANGER, false)
		blade.visible = false


func _add_containment_tool(
	parent: Node3D,
	tool_name: StringName,
	effect_id: StringName,
	position: Vector3,
	linked_opening_ids: Array[StringName],
	active_seconds: float,
	cooldown_seconds: float,
) -> ContainmentTool:
	var tool := CONTAINMENT_TOOL_SCENE.instantiate() as ContainmentTool
	tool.name = tool_name
	tool.position = position
	tool.configure(effect_id, active_seconds, cooldown_seconds, linked_opening_ids)
	parent.add_child(tool)
	tool.active_state_changed.connect(_on_containment_tool_state_changed)
	tool.set_meta("subject_operated", true)
	tool.set_meta("encounter_effect", effect_id)
	if effect_id == ContainmentTool.EFFECT_BAIT:
		_add_piece(tool, &"BaitBeacon", EnvironmentKitPiece.Kind.COLUMN,
				Vector3(0.7, 4.5, 0.7), Vector3(0.0, 1.2, 0.0), 0.0,
				COLOUR_CUE, false)
	elif effect_id == ContainmentTool.EFFECT_SHUTTER:
		_add_piece(tool, &"ShutterControlArch", EnvironmentKitPiece.Kind.TRUSS,
				Vector3(3.5, 3.0, 0.5), Vector3(0.0, 0.0, 0.8), 0.0,
				COLOUR_DANGER, false)
	else:
		_add_piece(tool, &"PowerNodeCoil", EnvironmentKitPiece.Kind.COLUMN,
				Vector3(1.4, 3.5, 1.4), Vector3(0.0, 1.2, 0.0), 0.0,
				COLOUR_SYSTEM, false)
	return tool


func _on_containment_tool_state_changed(
	tool: ContainmentTool,
	active: bool,
) -> void:
	if tool.effect_id != ContainmentTool.EFFECT_SHUTTER:
		return
	var laboratory: Node3D = get_laboratory(&"AdaptiveContainment")
	var openings: Node3D = laboratory.get_node(
			"RoundContent/ResidualEntryOpenings")
	for opening_id: StringName in tool.linked_opening_ids:
		var opening := openings.get_node_or_null(NodePath(opening_id)) as Node3D
		if opening == null:
			continue
		for child: Node in opening.get_children():
			if child is EnvironmentKitPiece \
					and String(child.name).begins_with("EmergencyShutterBlade"):
				child.visible = active


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
				Vector3(
						_annular_tangent_span(
								PERIMETER_ROUTE_RADIUS_M, MAIN_PATH_WIDTH_M),
						0.5,
						MAIN_PATH_WIDTH_M),
				_radial_module_centre(PERIMETER_ROUTE_RADIUS_M, -0.5, angle),
				-angle, COLOUR_STRUCTURE, true, PERIMETER_ROUTE_RADIUS_M)


func _radial_module_centre(
	radius: float,
	height: float,
	angle: float,
) -> Vector3:
	return Vector3(sin(angle) * radius, height, -cos(angle) * radius)


func _annular_tangent_span(radius: float, radial_width: float) -> float:
	var half_module_angle: float = deg_to_rad(RADIAL_MODULE_DEGREES * 0.5)
	return 2.0 * (radius + radial_width * 0.5) * sin(half_module_angle)


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
	annular_radius_m: float = 0.0,
) -> EnvironmentKitPiece:
	var piece := KIT_PIECE_SCENE.instantiate() as EnvironmentKitPiece
	piece.configure(kind, dimensions, colour, with_collision)
	if annular_radius_m > 0.0:
		piece.configure_annular(annular_radius_m, RADIAL_MODULE_DEGREES)
	piece.name = "%s_%03d" % [base_name, _piece_sequence]
	_piece_sequence += 1
	piece.position = position
	piece.rotation.y = rotation_y
	parent.add_child(piece)
	return piece
