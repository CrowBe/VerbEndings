extends Node

const COMPOUND_SCENE: PackedScene = preload(
		"res://scenes/environment/Compound.tscn")
const GAME_SCENE: PackedScene = preload("res://scenes/core/Game.tscn")
const PLAYER_CAPSULE_RADIUS_M: float = 0.5
const PLAYER_CAPSULE_HEIGHT_M: float = 1.8
const ANNULAR_SAMPLE_STEP_DEGREES: float = 2.0
const MAXIMUM_SEAM_GAP_M: float = 0.01


func _ready() -> void:
	var failures: Array[String] = []
	var compound := COMPOUND_SCENE.instantiate() as Compound
	add_child(compound)
	_test_macro_topology(compound, failures)
	await _test_annular_traversal(compound, failures)
	_test_environment_kit(compound, failures)
	_test_laboratory_contracts(compound, failures)
	_test_confinement_and_retained_state(compound, failures)
	await _test_game_composition(failures)
	compound.queue_free()

	if failures.is_empty():
		print("Compound topology and spatial-contract tests passed.")
		get_tree().quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	get_tree().quit(1)


func _test_macro_topology(compound: Compound, failures: Array[String]) -> void:
	_expect(compound.has_node("CentralCore"),
			"Compound must contain the Central Core", failures)
	_expect(compound.has_node("AssignmentDeck/ResearcherBoothReserved"),
			"Assignment Deck must reserve the Researcher booth", failures)
	_expect(compound.get_node("AssignmentDeck").get_child_count() >= 25,
			"Assignment Deck must be an elevated annulus with safe rails", failures)
	_expect(compound.has_node("DomeShell"),
			"Compound must contain a dome shell", failures)
	var shell: Node3D = compound.get_node("DomeShell")
	_expect(shell.get_meta("shape") == &"faceted_hemisphere",
			"dome shell must declare the faceted hemispherical contract", failures)
	_expect(is_equal_approx(shell.get_meta("radial_module_degrees"), 30.0),
			"dome shell must use repeatable 30-degree radial modules", failures)
	_expect(compound.get_node("SeparatorSpines").get_child_count() == 3,
			"three separator spines must divide the Laboratories", failures)
	var route: Node3D = compound.get_node("PerimeterMaintenanceRoute")
	_expect(route.get_meta("dependable_connection", false),
			"perimeter route must be a dependable connection", failures)
	_expect(route.get_meta("laboratories_connected", []).size() == 3,
			"perimeter route must connect all three Laboratories", failures)
	_expect(route.get_child_count() == 12,
			"perimeter route must close through twelve annular modules", failures)


func _test_annular_traversal(
	compound: Compound,
	failures: Array[String],
) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var route: Node3D = compound.get_node("PerimeterMaintenanceRoute")
	var route_segments: Array[EnvironmentKitPiece] = []
	for child: Node in route.get_children():
		if child is EnvironmentKitPiece:
			route_segments.append(child)
	_test_annular_segment_transforms(
			route_segments, "perimeter maintenance route", failures)
	_test_perimeter_laboratory_connections(
			compound, route_segments, failures)
	_test_player_sized_support(
			compound, route_segments, 0.0, "perimeter maintenance route", failures)

	var deck: Node3D = compound.get_node("AssignmentDeck")
	var deck_segments: Array[EnvironmentKitPiece] = []
	for child: Node in deck.get_children():
		if child is EnvironmentKitPiece \
				and child.kind == EnvironmentKitPiece.Kind.ANNULAR_FLOOR_SEGMENT:
			deck_segments.append(child)
	_test_annular_segment_transforms(
			deck_segments, "Assignment Deck annulus", failures)
	_test_player_sized_support(
			compound, deck_segments, 6.0, "Assignment Deck annulus", failures)


func _test_annular_segment_transforms(
	segments: Array[EnvironmentKitPiece],
	route_name: String,
	failures: Array[String],
) -> void:
	_expect(segments.size() == 12,
			"%s must contain twelve floor segments" % route_name, failures)
	if segments.size() != 12:
		return
	for segment: EnvironmentKitPiece in segments:
		var radial: Vector3 = Vector3(
				segment.global_position.x, 0.0, segment.global_position.z).normalized()
		var expected_tangent := Vector3(-radial.z, 0.0, radial.x)
		var actual_tangent: Vector3 = segment.global_basis.x.normalized()
		_expect(actual_tangent.dot(expected_tangent) >= 0.999,
				"%s segment %s must be tangent to its radial centre"
				% [route_name, segment.name], failures)
		var visual := segment.get_node_or_null("Visual") as MeshInstance3D
		var collision: CollisionShape3D = null
		var collision_body := segment.get_node_or_null(
				"GameplayCollision") as StaticBody3D
		if collision_body != null:
			for child: Node in collision_body.get_children():
				if child is CollisionShape3D:
					collision = child
					break
		_expect(visual != null and visual.mesh != null,
				"%s segment %s must expose rendered floor geometry"
				% [route_name, segment.name], failures)
		_expect(collision != null and collision.shape != null,
				"%s segment %s must expose supporting gameplay collision"
				% [route_name, segment.name], failures)
	for index: int in segments.size():
		var segment: EnvironmentKitPiece = segments[index]
		var next_segment: EnvironmentKitPiece = segments[
				(index + 1) % segments.size()]
		var rendered_shared_vertices: int = _count_shared_vertices(
				_top_rendered_vertices(segment),
				_top_rendered_vertices(next_segment))
		var collision_shared_vertices: int = _count_shared_vertices(
				_top_collision_vertices(segment),
				_top_collision_vertices(next_segment))
		_expect(rendered_shared_vertices >= 2,
				"%s rendered floor edges must meet at join %d"
				% [route_name, index], failures)
		_expect(collision_shared_vertices >= 2,
				"%s gameplay collision edges must meet at join %d"
				% [route_name, index], failures)


func _top_rendered_vertices(piece: EnvironmentKitPiece) -> Array[Vector3]:
	var output: Array[Vector3] = []
	var visual := piece.get_node("Visual") as MeshInstance3D
	for vertex: Vector3 in visual.mesh.get_faces():
		var piece_local_vertex: Vector3 = visual.transform * vertex
		if is_equal_approx(piece_local_vertex.y, piece.dimensions.y):
			_append_unique_vertex(output, piece.to_global(piece_local_vertex))
	return output


func _top_collision_vertices(piece: EnvironmentKitPiece) -> Array[Vector3]:
	var output: Array[Vector3] = []
	var collision_body := piece.get_node("GameplayCollision") as StaticBody3D
	var collision := collision_body.get_child(0) as CollisionShape3D
	var local_vertices := PackedVector3Array()
	if collision.shape is ConcavePolygonShape3D:
		local_vertices = collision.shape.get_faces()
	elif collision.shape is BoxShape3D:
		var half_size: Vector3 = collision.shape.size * 0.5
		for x_sign: float in [-1.0, 1.0]:
			for z_sign: float in [-1.0, 1.0]:
				local_vertices.append(Vector3(
						x_sign * half_size.x,
						half_size.y,
						z_sign * half_size.z))
	for vertex: Vector3 in local_vertices:
		var piece_local_vertex: Vector3 = collision.transform * vertex
		if is_equal_approx(piece_local_vertex.y, piece.dimensions.y):
			_append_unique_vertex(output, piece.to_global(piece_local_vertex))
	return output


func _append_unique_vertex(vertices: Array[Vector3], candidate: Vector3) -> void:
	for existing: Vector3 in vertices:
		if existing.distance_to(candidate) <= MAXIMUM_SEAM_GAP_M:
			return
	vertices.append(candidate)


func _count_shared_vertices(
	first: Array[Vector3],
	second: Array[Vector3],
) -> int:
	var shared_count: int = 0
	for first_vertex: Vector3 in first:
		for second_vertex: Vector3 in second:
			if first_vertex.distance_to(second_vertex) <= MAXIMUM_SEAM_GAP_M:
				shared_count += 1
				break
	return shared_count


func _test_perimeter_laboratory_connections(
	compound: Compound,
	segments: Array[EnvironmentKitPiece],
	failures: Array[String],
) -> void:
	if segments.is_empty():
		return
	var route_radius: float = Vector2(
			segments[0].global_position.x,
			segments[0].global_position.z).length()
	var route_inner_radius: float = route_radius - segments[0].dimensions.z * 0.5
	for laboratory_id: StringName in Compound.LABORATORY_IDS:
		var laboratory: Node3D = compound.get_laboratory(laboratory_id)
		var floor: EnvironmentKitPiece = null
		for child: Node in laboratory.get_children():
			if child is EnvironmentKitPiece \
					and child.kind == EnvironmentKitPiece.Kind.FLOOR_BAY:
				floor = child
				break
		if floor == null:
			continue
		var laboratory_outer_radius: float = Vector2(
				laboratory.global_position.x,
				laboratory.global_position.z).length() + floor.dimensions.z * 0.5
		_expect(is_equal_approx(route_inner_radius, laboratory_outer_radius),
				"perimeter route must meet %s Test Floor collision at its radial edge"
				% laboratory_id, failures)


func _test_player_sized_support(
	compound: Compound,
	segments: Array[EnvironmentKitPiece],
	surface_y: float,
	route_name: String,
	failures: Array[String],
) -> void:
	if segments.is_empty():
		return
	var radius: float = Vector2(
			segments[0].global_position.x,
			segments[0].global_position.z).length()
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_CAPSULE_RADIUS_M
	capsule.height = PLAYER_CAPSULE_HEIGHT_M
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var unsupported_samples: int = 0
	var first_unsupported_angle: float = -1.0
	var sample_count: int = int(360.0 / ANNULAR_SAMPLE_STEP_DEGREES)
	var safe_radial_offset: float = (
			segments[0].dimensions.z * 0.5 - PLAYER_CAPSULE_RADIUS_M)
	for radial_offset: float in [
		-safe_radial_offset, 0.0, safe_radial_offset,
	]:
		for sample_index: int in sample_count:
			var angle: float = deg_to_rad(
					sample_index * ANNULAR_SAMPLE_STEP_DEGREES)
			var sample_radius: float = radius + radial_offset
			query.transform = Transform3D(
					Basis.IDENTITY,
					Vector3(
							sin(angle) * sample_radius,
							surface_y + PLAYER_CAPSULE_HEIGHT_M * 0.5 - 0.05,
							-cos(angle) * sample_radius))
			var hits: Array[Dictionary] = compound.get_world_3d() \
					.direct_space_state.intersect_shape(query, 8)
			var has_route_support: bool = false
			for hit: Dictionary in hits:
				var collider := hit.get("collider") as Node
				if collider != null and _is_descendant_of_any(collider, segments):
					has_route_support = true
					break
			if not has_route_support:
				unsupported_samples += 1
				if first_unsupported_angle < 0.0:
					first_unsupported_angle = rad_to_deg(angle)
	_expect(
			unsupported_samples == 0,
			("%s must support a Player-sized capsule across its complete safe "
			+ "width; %d/%d samples unsupported (first at %.1f degrees)") % [
				route_name,
				unsupported_samples,
				sample_count * 3,
				first_unsupported_angle,
			],
			failures)


func _is_descendant_of_any(
	node: Node,
	ancestors: Array[EnvironmentKitPiece],
) -> bool:
	var candidate: Node = node
	while candidate != null:
		for ancestor: EnvironmentKitPiece in ancestors:
			if candidate == ancestor:
				return true
		candidate = candidate.get_parent()
	return false


func _test_environment_kit(compound: Compound, failures: Array[String]) -> void:
	var contract: Dictionary = compound.get_environment_kit_contract()
	_expect(is_equal_approx(contract.planning_grid_m, 2.0),
			"environment kit must expose the 2 m planning grid", failures)
	_expect(is_equal_approx(contract.detail_increment_m, 1.0),
			"environment kit must expose the 1 m detail increment", failures)
	_expect(is_equal_approx(contract.main_path_width_m, 6.0),
			"main circulation must be within the 4-6 m contract", failures)
	_expect(is_equal_approx(contract.secondary_path_width_m, 3.0),
			"secondary circulation must be within the 2.5-3 m contract", failures)
	_expect(contract.door_clear_width_m >= 4.0
			and contract.door_clear_height_m >= 4.5,
			"door and shutter openings must meet the clear-opening contract",
			failures)
	_expect(contract.barrier_height_m >= 1.1
			and contract.barrier_height_m <= 1.3,
			"barriers must meet the 1.1-1.3 m contract", failures)
	_expect(contract.collision_owner == &"GodotScene",
			"gameplay collision must remain in Godot scenes", failures)
	for required_kind: StringName in [
		&"FloorBay", &"WallBay", &"RadialFloorSegment",
		&"AnnularFloorSegment", &"DomeShellBay", &"SpineJunction",
		&"DoorFrame4m", &"Shutter4m", &"DeckRail", &"Column", &"Truss",
		&"Vent", &"Panel",
	]:
		_expect(contract.piece_kinds.has(required_kind),
				"environment kit must catalogue %s" % required_kind, failures)

	var pieces: Array[EnvironmentKitPiece] = []
	_collect_pieces(compound, pieces)
	_expect(pieces.size() >= 100,
			"Compound must be assembled from a reusable kit, not monolithic geometry",
			failures)
	var names: Dictionary = {}
	var kinds_present: Dictionary = {}
	for piece: EnvironmentKitPiece in pieces:
		_expect(not piece.name.contains(" "),
				"kit instance names must be stable and space-free", failures)
		_expect(not names.has(piece.name),
				"kit instance names must be globally predictable and unique", failures)
		names[piece.name] = true
		kinds_present[piece.get_meta("kit_kind")] = true
		_expect(piece.get_meta("origin_contract") == &"floor_centred",
				"kit origins must use the floor-centred contract", failures)
		if piece.collision_enabled:
			_expect(piece.has_node("GameplayCollision"),
					"collidable kit pieces must own Godot collision", failures)
	for required_placed_kind: StringName in [
		&"FloorBay", &"WallBay", &"RadialFloorSegment",
		&"AnnularFloorSegment", &"DomeShellBay", &"SpineJunction",
		&"DoorFrame4m", &"Shutter4m", &"DeckRail", &"Column", &"Truss",
		&"Vent", &"Panel",
	]:
		_expect(kinds_present.has(required_placed_kind),
				"Compound must place a %s kit instance" % required_placed_kind,
				failures)


func _test_laboratory_contracts(
	compound: Compound,
	failures: Array[String],
) -> void:
	var expected_apparatus: Dictionary = {
		&"AppliedCausality": &"RaisedResultReceiver",
		&"CompetitiveStress": &"ReinforcedImpactCrucible",
		&"AdaptiveContainment": &"SpecimenDeliveryColumn",
	}
	var laboratory_positions: Array[Vector3] = []
	for laboratory_id: StringName in Compound.LABORATORY_IDS:
		var laboratory: Node3D = compound.get_laboratory(laboratory_id)
		_expect(laboratory != null,
				"%s Laboratory must exist" % laboratory_id, failures)
		if laboratory == null:
			continue
		laboratory_positions.append(laboratory.global_position)
		var inward_direction: Vector3 = Vector3(
				-laboratory.global_position.x, 0.0,
				-laboratory.global_position.z).normalized()
		var local_inward: Vector3 = laboratory.global_basis.z.normalized()
		_expect(local_inward.dot(inward_direction) >= 0.999,
				"%s local +Z must face the Central Core" % laboratory_id,
				failures)
		var sightline: Marker3D = laboratory.get_node(
				"SightlineToAssignmentDeck")
		_expect(sightline.global_position.length()
				< laboratory.global_position.length(),
				"%s sightline marker must project towards the Assignment Deck"
				% laboratory_id, failures)
		_expect(laboratory.get_meta("test_floor_span_m") >= 48.0
				and laboratory.get_meta("test_floor_span_m") <= 56.0,
				"%s Test Floor must span 48-56 m" % laboratory_id, failures)
		_expect(laboratory.get_meta("subject_capacity") == 24,
				"%s must expose the viable 24-Subject path" % laboratory_id,
				failures)
		_expect(laboratory.get_meta("dominant_apparatus")
				== expected_apparatus[laboratory_id],
				"%s must declare its Drop-readable apparatus" % laboratory_id,
				failures)
		var apparatus: Node3D = laboratory.get_node(
				str(expected_apparatus[laboratory_id]))
		_expect(apparatus.get_child_count() >= 3,
				"%s apparatus must have a dominant multi-part silhouette"
				% laboratory_id, failures)
		var landing_areas: Node3D = laboratory.get_node("LandingAreas")
		_expect(landing_areas.get_child_count() == 3,
				"%s must provide three distinct Landing strategies"
				% laboratory_id, failures)
		var trade_offs: Dictionary = {}
		for area: Node in landing_areas.get_children():
			trade_offs[area.get_meta("landing_strategy")] = true
			_expect(area.get_meta("recoverable", false),
					"%s Landing areas must not create traps" % laboratory_id,
					failures)
			_expect(area.get_meta("exit_options", 0) >= 2,
					"%s Landing areas must retain route choice" % laboratory_id,
					failures)
			_expect(area.get_meta("route_width_m", 0.0) >= 4.0,
					"%s Landing circulation must use broad paths" % laboratory_id,
					failures)
		_expect(trade_offs.size() == 3,
				"%s Landing strategies must have meaningful trade-offs"
				% laboratory_id, failures)
		_expect(laboratory.get_meta("mandatory_choke_count") == 0,
				"%s must not contain a mandatory choke" % laboratory_id, failures)
		_expect(laboratory.get_meta("valid_exit_count") >= 2,
				"%s must have route redundancy" % laboratory_id, failures)
		_expect(laboratory.has_node("SightlineToAssignmentDeck"),
				"%s must expose another Compound layer" % laboratory_id, failures)
		var cue_hooks: Node3D = laboratory.get_node("CriticalCueHooks")
		for hook_name: String in [
			"GeometryStateHook", "IconStateHook", "MotionStateHook",
		]:
			_expect(cue_hooks.has_node(hook_name),
					"%s must provide the non-colour %s" % [laboratory_id, hook_name],
					failures)
			_expect(cue_hooks.get_node(hook_name).get_child_count() > 0,
					"%s %s must contain a visible cue, not an empty marker"
					% [laboratory_id, hook_name], failures)
		var floor_area_per_subject: float = pow(
				laboratory.get_meta("test_floor_span_m"), 2.0) \
				/ laboratory.get_meta("subject_capacity")
		_expect(floor_area_per_subject >= 100.0,
				"%s must provide broad 24-Subject-capable floor area"
				% laboratory_id, failures)
	_expect(laboratory_positions.size() == 3,
			"Compound must expose all three Laboratory centres", failures)
	for index: int in laboratory_positions.size():
		var position: Vector3 = laboratory_positions[index]
		_expect(is_equal_approx(position.length(), 44.0),
				"Laboratory centres must sit on the 44 m radial module",
				failures)
		var next_position: Vector3 = laboratory_positions[
				(index + 1) % laboratory_positions.size()]
		_expect(position.normalized().dot(next_position.normalized()) < -0.49
				and position.normalized().dot(next_position.normalized()) > -0.51,
				"Laboratory centres must maintain 120-degree radial separation",
				failures)

	var cue_laboratory: Node3D = compound.get_laboratory(&"AppliedCausality")
	_expect(compound.set_laboratory_critical_state(&"AppliedCausality", true),
			"critical-state cue activation must accept a valid Laboratory",
			failures)
	var active_cues: Node3D = cue_laboratory.get_node("CriticalCueHooks")
	_expect(active_cues.visible,
			"critical-state cues must become visible when active", failures)
	var motion_before: float = active_cues.get_node("MotionStateHook").rotation.y
	compound.call("_process", 0.5)
	_expect(not is_equal_approx(
			active_cues.get_node("MotionStateHook").rotation.y, motion_before),
			"critical-state motion cue must visibly move", failures)
	compound.set_laboratory_critical_state(&"AppliedCausality", false)
	_expect(not active_cues.visible,
			"critical-state cues must hide when inactive", failures)
	for repeat: int in 5:
		compound.set_laboratory_critical_state(&"AppliedCausality", true)
		compound.set_laboratory_critical_state(&"AppliedCausality", false)
	_expect(not active_cues.visible,
			"repeated critical-state changes must settle inactive", failures)


func _test_confinement_and_retained_state(
	compound: Compound,
	failures: Array[String],
) -> void:
	var retained_laboratory: Node3D = compound.get_laboratory(
			&"AppliedCausality")
	retained_laboratory.set_meta("authored_scene_state", &"stressed")
	var retained_instance_id: int = retained_laboratory.get_instance_id()
	_expect(compound.select_active_laboratory(&"CompetitiveStress"),
			"normal Round confinement must accept a valid active Laboratory",
			failures)
	var active_count: int = 0
	for laboratory_id: StringName in Compound.LABORATORY_IDS:
		var laboratory: Node3D = compound.get_laboratory(laboratory_id)
		if laboratory.get_meta("round_active", false):
			active_count += 1
		_expect(laboratory.visible,
				"inactive Laboratories must remain visible", failures)
	_expect(active_count == 1,
			"normal confinement must select exactly one active Laboratory",
			failures)
	_expect(compound.get_laboratory(&"AppliedCausality").get_instance_id()
			== retained_instance_id,
			"Laboratory selection must not discard or recreate authored scenes",
			failures)
	_expect(compound.get_laboratory(&"AppliedCausality").get_meta(
			"authored_scene_state") == &"stressed",
			"inactive Laboratory authored state must be retained", failures)


func _test_game_composition(failures: Array[String]) -> void:
	var game: Node = GAME_SCENE.instantiate()
	game.auto_start_graybox = false
	add_child(game)
	var game_compound: Compound = game.get_node("World/Compound")
	var retained_lab: Node3D = game_compound.get_laboratory(&"AppliedCausality")
	var retained_id: int = retained_lab.get_instance_id()
	_expect(game.load_round("PVP") != null,
			"Game must load the Competitive Stress Round", failures)
	_expect(game_compound.active_laboratory_id == &"CompetitiveStress",
			"Game must select the Laboratory matching the Round", failures)
	_expect(game.get_node("World/Round").transform.is_equal_approx(
			game_compound.get_laboratory_anchor_transform(&"CompetitiveStress")),
			"Game must place Round-local content at the active Laboratory anchor",
			failures)
	var outgoing_round: Node3D = game.current_round
	_expect(game.load_round("PVE") != null,
			"Game must load the Adaptive Containment Round", failures)
	_expect(outgoing_round.get_parent() == null,
			"outgoing Round must detach before the shared root moves", failures)
	_expect(game.get_node("World/Round").get_child_count() == 1,
			"Round switch must never render outgoing and incoming Rounds together",
			failures)
	await get_tree().process_frame
	for round_type: String in ["PUZZLE", "PVP", "PVE", "PUZZLE", "PVP"]:
		_expect(game.load_round(round_type) != null,
				"repeated Round switching must load %s" % round_type, failures)
		_expect(game.get_node("World/Round").get_child_count() == 1,
				"repeated Round switching must keep one rendered Round",
				failures)
		await get_tree().process_frame
	_expect(game_compound.get_laboratory(&"AppliedCausality").get_instance_id()
			== retained_id,
			"Game Round changes must retain inactive Laboratory instances",
			failures)
	_expect(game.current_round.get_parent() == game.get_node("World/Round"),
			"Round-local responsibilities must remain under the Game Round root",
			failures)
	var player: Node3D = game.call("_spawn_local_player")
	game.call("_place_local_player_for_round", "PVE")
	_expect(player.global_position.is_equal_approx(
			game_compound.get_laboratory(&"AdaptiveContainment").to_global(
					Vector3(0.0, 1.0, 16.0))),
			"Game must place the local Subject in the rotated active Laboratory",
			failures)
	game.queue_free()


func _collect_pieces(node: Node, output: Array[EnvironmentKitPiece]) -> void:
	for child: Node in node.get_children():
		if child is EnvironmentKitPiece:
			output.append(child)
		_collect_pieces(child, output)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
