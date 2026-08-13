extends Node
## Server-authoritative, seeded presentation state for the persistent Compound.

signal transition_recorded(entry: Dictionary)
signal ledger_reset
signal ledger_replicated

const ROUND_STAGES: Array[StringName] = [
	&"controlled", &"questionable", &"containment_failure",
]
const EXPERIMENT_LIFECYCLES: Array[StringName] = [
	&"idle", &"brief", &"entry", &"live", &"resolve", &"recall",
]
const STRUCTURAL_KINDS: Array[StringName] = [&"wall", &"floor"]

var trial_seed: int = 0
var transition_sequence: int = 0
var laboratories: Dictionary = {}
var transition_history: Array[Dictionary] = []


func reset_for_trial(seed_value: int) -> void:
	trial_seed = seed_value
	transition_sequence = 0
	transition_history.clear()
	for laboratory_id: StringName in laboratories:
		var laboratory: Dictionary = laboratories[laboratory_id]
		laboratory.round_stage = &"controlled"
		laboratory.experiment_lifecycle = &"idle"
		laboratory.active_objective = &""
		laboratory.event_overlays.clear()
		laboratory.overlay_channels.clear()
		laboratory.persistent_state.clear()
		for surface_id: StringName in laboratory.structural_surfaces:
			laboratory.structural_surfaces[surface_id].cosmetic_state = &"pristine"
		for prop_id: StringName in laboratory.props:
			laboratory.props[prop_id].threshold_index = 0
	ledger_reset.emit()


func register_laboratory(laboratory_id: StringName,
		route_ids: Array[StringName]) -> bool:
	if laboratory_id.is_empty() or route_ids.is_empty():
		return false
	if laboratories.has(laboratory_id):
		var existing: Dictionary = laboratories[laboratory_id]
		for route_id: StringName in route_ids:
			existing.routes[route_id] = true
		return true
	var routes: Dictionary = {}
	for route_id: StringName in route_ids:
		if route_id.is_empty():
			return false
		routes[route_id] = true
	laboratories[laboratory_id] = {
		"round_stage": &"controlled",
		"persistent_state": {},
		"experiment_lifecycle": &"idle",
		"active_objective": &"",
		"event_overlays": {},
		"overlay_channels": {},
		"structural_surfaces": {},
		"props": {},
		"routes": routes,
	}
	return true


func register_structural_surface(laboratory_id: StringName,
		surface_id: StringName, kind: StringName) -> bool:
	var laboratory := _laboratory(laboratory_id)
	if laboratory.is_empty() or surface_id.is_empty() or kind not in STRUCTURAL_KINDS:
		return false
	laboratory.structural_surfaces[surface_id] = {
		"kind": kind,
		"cosmetic_state": &"pristine",
	}
	return true


func register_prop(laboratory_id: StringName, prop_id: StringName,
		thresholds: Array[StringName], collision_by_threshold: Dictionary = {},
		blocked_routes_by_threshold: Dictionary = {}) -> bool:
	var laboratory := _laboratory(laboratory_id)
	if laboratory.is_empty() or prop_id.is_empty() or thresholds.is_empty() \
			or thresholds[0] != &"pristine":
		return false
	var seen: Dictionary = {}
	for threshold: StringName in thresholds:
		if threshold.is_empty() or seen.has(threshold):
			return false
		seen[threshold] = true
		for route_id: StringName in blocked_routes_by_threshold.get(threshold, []):
			if not laboratory.routes.has(route_id):
				return false
	laboratory.props[prop_id] = {
		"thresholds": thresholds.duplicate(),
		"threshold_index": 0,
		"collision_by_threshold": collision_by_threshold.duplicate(true),
		"blocked_routes_by_threshold": blocked_routes_by_threshold.duplicate(true),
	}
	return true


func set_round_stage(laboratory_id: StringName, stage: StringName,
		transition_name: StringName) -> bool:
	if not _can_author_transition(transition_name) or stage not in ROUND_STAGES:
		return false
	var laboratory := _laboratory(laboratory_id)
	if laboratory.is_empty():
		return false
	if laboratory.round_stage == stage:
		return true
	laboratory.round_stage = stage
	_record(laboratory_id, &"round_stage", transition_name,
			{"stage": stage})
	return true


func set_experiment_lifecycle(laboratory_id: StringName,
		lifecycle: StringName, transition_name: StringName) -> bool:
	if not _can_author_transition(transition_name) \
			or lifecycle not in EXPERIMENT_LIFECYCLES:
		return false
	var laboratory := _laboratory(laboratory_id)
	if laboratory.is_empty():
		return false
	if laboratory.experiment_lifecycle == lifecycle:
		return true
	laboratory.experiment_lifecycle = lifecycle
	_record(laboratory_id, &"experiment_lifecycle", transition_name,
			{"lifecycle": lifecycle})
	return true


func set_active_objective(laboratory_id: StringName, objective: StringName,
		transition_name: StringName) -> bool:
	if not _can_author_transition(transition_name):
		return false
	var laboratory := _laboratory(laboratory_id)
	if laboratory.is_empty():
		return false
	if laboratory.active_objective == objective:
		return true
	for overlay: Dictionary in laboratory.event_overlays.values():
		if objective in overlay.blocked_objectives:
			return false
	laboratory.active_objective = objective
	_record(laboratory_id, &"experiment_lifecycle", transition_name,
			{"objective": objective})
	return true


func set_structural_cosmetic_state(laboratory_id: StringName,
		surface_id: StringName, cosmetic_state: StringName,
		transition_name: StringName) -> bool:
	if not _can_author_transition(transition_name) or cosmetic_state.is_empty():
		return false
	var laboratory := _laboratory(laboratory_id)
	if laboratory.is_empty() \
			or not laboratory.structural_surfaces.has(surface_id):
		return false
	if laboratory.structural_surfaces[surface_id].cosmetic_state == cosmetic_state:
		return true
	laboratory.structural_surfaces[surface_id].cosmetic_state = cosmetic_state
	_record(laboratory_id, &"persistent_state", transition_name, {
		"surface_id": surface_id,
		"cosmetic_state": cosmetic_state,
		"collision_changed": false,
	})
	return true


func transition_prop(laboratory_id: StringName, prop_id: StringName,
		threshold: StringName, transition_name: StringName) -> bool:
	if not _can_author_transition(transition_name):
		return false
	var laboratory := _laboratory(laboratory_id)
	if laboratory.is_empty() or not laboratory.props.has(prop_id):
		return false
	var prop: Dictionary = laboratory.props[prop_id]
	var next_index: int = prop.thresholds.find(threshold)
	if next_index <= prop.threshold_index:
		return false
	if not _overlays_allow_prop_threshold(laboratory, prop_id, threshold):
		return false
	if not _retains_valid_route(laboratory, prop_id, next_index):
		return false
	var old_threshold: StringName = prop.thresholds[prop.threshold_index]
	var old_collision: Variant = prop.collision_by_threshold.get(old_threshold, null)
	var new_collision: Variant = prop.collision_by_threshold.get(threshold, old_collision)
	prop.threshold_index = next_index
	laboratory.persistent_state[prop_id] = threshold
	_record(laboratory_id, &"persistent_state", transition_name, {
		"prop_id": prop_id,
		"threshold": threshold,
		"collision_changed": old_collision != new_collision,
		"collision_active": new_collision,
	})
	return true


func activate_event_overlay(laboratory_id: StringName,
		overlay_name: StringName, channels: Array[StringName],
		compatible_prop_states: Dictionary, blocked_objectives: Array[StringName],
		transition_name: StringName, repairs_state: bool = false) -> bool:
	if not _can_author_transition(transition_name) or overlay_name.is_empty() \
			or channels.is_empty() or repairs_state:
		return false
	var laboratory := _laboratory(laboratory_id)
	if laboratory.is_empty() or laboratory.event_overlays.has(overlay_name) \
			or laboratory.active_objective in blocked_objectives:
		return false
	for channel: StringName in channels:
		if channel.is_empty() or laboratory.overlay_channels.has(channel):
			return false
	for prop_id: StringName in compatible_prop_states:
		if not laboratory.props.has(prop_id):
			return false
		var prop: Dictionary = laboratory.props[prop_id]
		var current_threshold: StringName = prop.thresholds[prop.threshold_index]
		if current_threshold not in compatible_prop_states[prop_id]:
			return false
	laboratory.event_overlays[overlay_name] = {
		"channels": channels.duplicate(),
		"compatible_prop_states": compatible_prop_states.duplicate(true),
		"blocked_objectives": blocked_objectives.duplicate(),
	}
	for channel: StringName in channels:
		laboratory.overlay_channels[channel] = overlay_name
	_record(laboratory_id, &"event_overlay", transition_name, {
		"overlay": overlay_name,
		"active": true,
	})
	return true


func deactivate_event_overlay(laboratory_id: StringName,
		overlay_name: StringName, transition_name: StringName) -> bool:
	if not _can_author_transition(transition_name):
		return false
	var laboratory := _laboratory(laboratory_id)
	if laboratory.is_empty() or not laboratory.event_overlays.has(overlay_name):
		return false
	var overlay: Dictionary = laboratory.event_overlays[overlay_name]
	for channel: StringName in overlay.channels:
		laboratory.overlay_channels.erase(channel)
	laboratory.event_overlays.erase(overlay_name)
	_record(laboratory_id, &"event_overlay", transition_name, {
		"overlay": overlay_name,
		"active": false,
	})
	return true


func current_prop_threshold(laboratory_id: StringName,
		prop_id: StringName) -> StringName:
	var laboratory := _laboratory(laboratory_id)
	if laboratory.is_empty() or not laboratory.props.has(prop_id):
		return &""
	var prop: Dictionary = laboratory.props[prop_id]
	return prop.thresholds[prop.threshold_index]


func snapshot(include_history: bool = true) -> Dictionary:
	var state := {
		"trial_seed": trial_seed,
		"transition_sequence": transition_sequence,
		"laboratories": laboratories.duplicate(true),
	}
	if include_history:
		state["transition_history"] = transition_history.duplicate(true)
	return state


func apply_replicated_snapshot(state: Dictionary) -> bool:
	if _is_authority():
		return false
	trial_seed = state.get("trial_seed", 0)
	transition_sequence = state.get("transition_sequence", 0)
	laboratories = state.get("laboratories", {}).duplicate(true)
	if state.has("transition_history"):
		transition_history.assign(state.transition_history)
	else:
		transition_history.clear()
	ledger_replicated.emit()
	return true


func _retains_valid_route(laboratory: Dictionary, changed_prop_id: StringName,
		next_index: int) -> bool:
	var available_routes: Dictionary = laboratory.routes.duplicate()
	for prop_id: StringName in laboratory.props:
		var prop: Dictionary = laboratory.props[prop_id]
		var threshold_index: int = next_index \
				if prop_id == changed_prop_id else prop.threshold_index
		var threshold: StringName = prop.thresholds[threshold_index]
		for route_id: StringName in prop.blocked_routes_by_threshold.get(threshold, []):
			available_routes.erase(route_id)
	return not available_routes.is_empty()


func _overlays_allow_prop_threshold(laboratory: Dictionary,
		prop_id: StringName, threshold: StringName) -> bool:
	for overlay: Dictionary in laboratory.event_overlays.values():
		if not overlay.compatible_prop_states.has(prop_id):
			continue
		if threshold not in overlay.compatible_prop_states[prop_id]:
			return false
	return true


func _record(laboratory_id: StringName, layer: StringName,
		transition_name: StringName, details: Dictionary) -> void:
	var entry := {
		"sequence": transition_sequence,
		"seed_token": hash("%d:%s:%d" % [
				trial_seed, transition_name, transition_sequence]) & 0x7fffffff,
		"laboratory_id": laboratory_id,
		"layer": layer,
		"transition_name": transition_name,
		"details": details.duplicate(true),
	}
	transition_sequence += 1
	transition_history.append(entry)
	transition_recorded.emit(entry.duplicate(true))


func _laboratory(laboratory_id: StringName) -> Dictionary:
	return laboratories.get(laboratory_id, {})


func _can_author_transition(transition_name: StringName) -> bool:
	return not transition_name.is_empty() and _is_authority()


func _is_authority() -> bool:
	return NetworkSession.can_simulate()
