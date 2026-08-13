extends Node
## CollapseManager (autoload singleton)
##
## After Round Three, the Collapse begins only when multiple Subjects share
## the highest individual Trial Score.
## Every previous Pair is dissolved — participants are forced into a Solo
## state (paired_partner_id = null) and enter Overdrive, which halves Verb
## Expression cooldown and changes nothing else. Elimination is permanent for
## the remainder of the Trial and the last Subject standing is Trial Winner.
##
## NETWORK: Everything here is server-authoritative. Eliminations and the
## final winner are broadcast via the RPC hooks noted on the signals.

## NETWORK: replication boundary — broadcast so every client swaps to the
## Collapse presentation and severs its local chain VFX.
signal collapse_triggered(participant_ids: Array)
signal collapse_stage_changed(stage: Stage, laboratory_id: StringName)
signal collapse_state_replicated
## NETWORK: replication boundary — broadcast each Elimination for the feed.
signal player_eliminated(player_id: int, survivors_left: int)
## NETWORK: replication boundary — broadcast the Trial result.
signal ultimate_winner_decided(player_id: int)

enum Stage {
	INACTIVE,
	PROTECTED_ORIENTATION,
	PERIMETER_ROUTES_OPEN,
	CORE_SHORTCUTS_OPEN,
	FAILURE_TELEGRAPH,
	FAILURE_ACTIVE,
	COMPLETE,
}

const LABORATORY_IDS: Array[StringName] = [
	&"AppliedAttrition", &"CompetitiveStress", &"AdaptiveContainment",
]
const ENTRY_SOCKET_COUNT_PER_LABORATORY: int = 8
const ORIENTATION_SECONDS: float = 3.0
const CORE_SHORTCUT_SECONDS: float = 8.0
const FIRST_FAILURE_TELEGRAPH_SECONDS: float = 12.0
const FAILURE_WARNING_SECONDS: float = 2.0
const FAILURE_INTERVAL_SECONDS: float = 6.0

## True while The Collapse is running.
## NETWORK: replication boundary — sync to all peers.
var is_active: bool = false
## Subjects not yet Eliminated from the Collapse.
## NETWORK: replication boundary — sync to all peers.
var surviving_players: Array[int] = []
## Seeded fair socket assignment for each eligible Subject.
var entry_assignments: Dictionary = {}
## Seeded Laboratory order for authored failures.
var failure_order: Array[StringName] = []
var stage: Stage = Stage.INACTIVE
var elapsed_seconds: float = 0.0
var _next_failure_index: int = 0
var telegraphed_laboratory: StringName = &""
var _queued_eliminations: Dictionary = {}
var _elimination_resolution_queued: bool = false


func _process(delta: float) -> void:
	if is_active and NetworkSession.can_simulate():
		advance_timeline(delta)


## Clears Collapse state when a Trial is replayed in the same process.
func reset() -> void:
	_disconnect_subjects()
	is_active = false
	surviving_players.clear()
	entry_assignments.clear()
	failure_order.clear()
	stage = Stage.INACTIVE
	elapsed_seconds = 0.0
	_next_failure_index = 0
	telegraphed_laboratory = &""
	_queued_eliminations.clear()
	_elimination_resolution_queued = false


## Resolves First Place from individual Trial Scores after Round Three.
## NETWORK: replication boundary — server-side, from the results screen.
func resolve_trial_end() -> bool:
	if RoundManager.current_round_index < RoundManager.TOTAL_ROUNDS:
		push_warning("CollapseManager: Trial resolution requires three completed Rounds.")
		return false
	return resolve_trial_scores(ScoreManager.player_points)


## The Collapse fires only when two or more Subjects share First Place.
## Ties below First Place do not affect Trial resolution.
## NETWORK: replication boundary — server-side, from the results screen.
func resolve_trial_scores(trial_scores: Dictionary) -> bool:
	if trial_scores.is_empty():
		return false
	var best_score: float = -INF
	for score: float in trial_scores.values():
		best_score = maxf(best_score, score)
	var tied_players: Array[int] = []
	for player_id: int in trial_scores.keys():
		if is_equal_approx(trial_scores[player_id], best_score):
			tied_players.append(player_id)
	if tied_players.size() < 2:
		# One Subject alone at the top: the only path to victory that
		# skips The Collapse.
		if tied_players.size() == 1:
			ultimate_winner_decided.emit(tied_players[0])
		return false
	trigger_collapse(tied_players)
	return true


## Starts the Collapse. Dissolves all Pairs, forces every participant Solo,
## and puts each of them into Overdrive.
## NETWORK: replication boundary — server executes, then broadcasts the
## solo-state assignments to every peer.
func trigger_collapse(participant_ids: Array[int]) -> void:
	if participant_ids.size() > LABORATORY_IDS.size() \
			* ENTRY_SOCKET_COUNT_PER_LABORATORY:
		push_warning("CollapseManager: participant count exceeds authored sockets.")
		return
	is_active = true
	surviving_players = participant_ids.duplicate()
	surviving_players.sort()
	elapsed_seconds = 0.0
	_next_failure_index = 0
	telegraphed_laboratory = &""
	stage = Stage.PROTECTED_ORIENTATION
	_build_seeded_plan(FacilityStateLedger.trial_seed)

	# No Pair survives into the Collapse.
	VerbChainManager.dissolve_all_chains()

	# Force every participant's body into Solo Overdrive.
	for peer_id: int in surviving_players:
		SubjectRoster.set_solo_overdrive(peer_id)
	SubjectRoster.connect_destabilised(_on_subject_destabilised)

	for laboratory_id: StringName in LABORATORY_IDS:
		FacilityStateLedger.set_experiment_lifecycle(laboratory_id, &"live",
				&"collapse_survive_begins")
		FacilityStateLedger.set_active_objective(laboratory_id, &"SURVIVE",
				&"collapse_survive_objective")

	collapse_triggered.emit(surviving_players.duplicate())
	collapse_stage_changed.emit(stage, &"")


## Advances the deterministic authored sequence. Tests call the same public
## seam with explicit deltas; runtime authority advances it from `_process`.
func advance_timeline(delta: float) -> void:
	if not is_active or delta < 0.0:
		return
	elapsed_seconds += delta
	if stage == Stage.PROTECTED_ORIENTATION \
			and elapsed_seconds >= ORIENTATION_SECONDS:
		stage = Stage.PERIMETER_ROUTES_OPEN
		collapse_stage_changed.emit(stage, &"")
	if stage == Stage.PERIMETER_ROUTES_OPEN \
			and elapsed_seconds >= CORE_SHORTCUT_SECONDS:
		stage = Stage.CORE_SHORTCUTS_OPEN
		collapse_stage_changed.emit(stage, &"")
	_process_failures()


func snapshot() -> Dictionary:
	return {
		"is_active": is_active,
		"surviving_players": surviving_players.duplicate(),
		"entry_assignments": entry_assignments.duplicate(true),
		"failure_order": failure_order.duplicate(),
		"stage": stage,
		"elapsed_seconds": elapsed_seconds,
		"next_failure_index": _next_failure_index,
		"telegraphed_laboratory": telegraphed_laboratory,
	}


func apply_replicated_state(state: Dictionary) -> void:
	is_active = state.get("is_active", false)
	surviving_players.assign(state.get("surviving_players", []))
	entry_assignments = state.get("entry_assignments", {}).duplicate(true)
	failure_order.assign(state.get("failure_order", []))
	stage = state.get("stage", Stage.INACTIVE)
	elapsed_seconds = state.get("elapsed_seconds", 0.0)
	_next_failure_index = state.get("next_failure_index", 0)
	telegraphed_laboratory = state.get("telegraphed_laboratory", &"")
	collapse_state_replicated.emit()


func _build_seeded_plan(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x43_4f_4c_4c
	var laboratory_order: Array[StringName] = LABORATORY_IDS.duplicate()
	_shuffle(laboratory_order, rng)
	var socket_orders: Dictionary = {}
	for laboratory_id: StringName in LABORATORY_IDS:
		var order: Array[int] = []
		for socket_index: int in ENTRY_SOCKET_COUNT_PER_LABORATORY:
			order.append(socket_index)
		_shuffle(order, rng)
		socket_orders[laboratory_id] = order
	entry_assignments.clear()
	for participant_index: int in surviving_players.size():
		var laboratory_id: StringName = laboratory_order[
				participant_index % laboratory_order.size()]
		var laboratory_slot: int = participant_index / laboratory_order.size()
		entry_assignments[surviving_players[participant_index]] = {
			"laboratory_id": laboratory_id,
			"socket_index": socket_orders[laboratory_id][laboratory_slot],
			"hazard_exposure": 1.0,
			"exit_count": 2,
		}
	failure_order = LABORATORY_IDS.duplicate()
	_shuffle(failure_order, rng)


func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index: int in range(values.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var value: Variant = values[index]
		values[index] = values[other]
		values[other] = value


func _process_failures() -> void:
	while _next_failure_index < failure_order.size():
		var telegraph_time: float = FIRST_FAILURE_TELEGRAPH_SECONDS \
				+ _next_failure_index * FAILURE_INTERVAL_SECONDS
		var failure_time: float = telegraph_time + FAILURE_WARNING_SECONDS
		var laboratory_id: StringName = failure_order[_next_failure_index]
		if telegraphed_laboratory.is_empty():
			if elapsed_seconds < telegraph_time:
				return
			_telegraph_failure(laboratory_id)
		if elapsed_seconds < failure_time:
			return
		_apply_failure(laboratory_id)
		_next_failure_index += 1
		telegraphed_laboratory = &""


func _telegraph_failure(laboratory_id: StringName) -> void:
	telegraphed_laboratory = laboratory_id
	stage = Stage.FAILURE_TELEGRAPH
	var apparatus_id: StringName = _apparatus_id(laboratory_id)
	FacilityStateLedger.set_round_stage(laboratory_id, &"questionable",
			&"collapse_failure_warning")
	FacilityStateLedger.set_structural_cosmetic_state(laboratory_id,
			&"TestFloor", &"collapse_warning", &"collapse_floor_warning")
	FacilityStateLedger.activate_event_overlay(laboratory_id,
			&"collapse_failure_warning", [&"environmental"], {
				apparatus_id: [&"pristine", &"stressed", &"breached", &"destroyed"],
			}, [], &"collapse_failure_telegraph")
	collapse_stage_changed.emit(stage, laboratory_id)


func _apply_failure(laboratory_id: StringName) -> void:
	var apparatus_id: StringName = _apparatus_id(laboratory_id)
	FacilityStateLedger.deactivate_event_overlay(laboratory_id,
			&"collapse_failure_warning", &"collapse_warning_cleared")
	FacilityStateLedger.set_round_stage(laboratory_id, &"containment_failure",
			&"collapse_containment_failure")
	FacilityStateLedger.set_structural_cosmetic_state(laboratory_id,
			&"TestFloor", &"failed", &"collapse_floor_failure")
	FacilityStateLedger.transition_prop(laboratory_id, apparatus_id,
			&"breached", &"collapse_apparatus_failure")
	stage = Stage.FAILURE_ACTIVE
	collapse_stage_changed.emit(stage, laboratory_id)


func _apparatus_id(laboratory_id: StringName) -> StringName:
	match laboratory_id:
		&"AppliedAttrition":
			return &"ElevatedDispensingArmature"
		&"CompetitiveStress":
			return &"ReinforcedImpactCrucible"
		_:
			return &"SpecimenDeliveryColumn"


## Collapse hazard callback used by authored Laboratory failure volumes.
## Eliminates the fallen Subject; the last Subject standing wins outright.
## NETWORK: replication boundary — hazards overlap on the server only;
## the resulting elimination is broadcast.
func _on_player_fall_into_hazard(body: Node3D) -> void:
	if not is_active or not body.is_in_group("players"):
		return
	queue_elimination(body.get_multiplayer_authority())


func _on_subject_destabilised(subject: Node, _source: Node) -> void:
	if is_active:
		queue_elimination(subject.get_multiplayer_authority())


## Batches all Eliminations reported in one frame so simultaneous final
## failures resolve by survival time, then lowest stable Subject id.
func queue_elimination(player_id: int) -> void:
	if not is_active or player_id not in surviving_players:
		return
	_queued_eliminations[player_id] = elapsed_seconds
	if not _elimination_resolution_queued:
		_elimination_resolution_queued = true
		call_deferred("_resolve_queued_eliminations")


func _resolve_queued_eliminations() -> void:
	_elimination_resolution_queued = false
	var eliminations: Array[Dictionary] = []
	for player_id: int in _queued_eliminations:
		eliminations.append({
			"player_id": player_id,
			"survival_seconds": _queued_eliminations[player_id],
		})
	_queued_eliminations.clear()
	eliminate_players(eliminations)


## Removes a Subject from the Collapse and crowns the winner when one remains.
func eliminate_player(player_id: int) -> void:
	if not is_active or player_id not in surviving_players:
		return
	eliminate_players([{
		"player_id": player_id,
		"survival_seconds": elapsed_seconds,
	}])


func eliminate_players(eliminations: Array[Dictionary]) -> void:
	if not is_active or eliminations.is_empty():
		return
	var valid: Array[Dictionary] = []
	var seen: Dictionary = {}
	for elimination: Dictionary in eliminations:
		var player_id: int = elimination.get("player_id", -1)
		if player_id in surviving_players and not seen.has(player_id):
			seen[player_id] = true
			valid.append({
				"player_id": player_id,
				"survival_seconds": float(elimination.get(
						"survival_seconds", elapsed_seconds)),
			})
	if valid.is_empty():
		return
	var remaining: Array[int] = surviving_players.duplicate()
	for elimination: Dictionary in valid:
		remaining.erase(elimination.player_id)
	if remaining.is_empty():
		valid.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if not is_equal_approx(a.survival_seconds, b.survival_seconds):
				return a.survival_seconds > b.survival_seconds
			return a.player_id < b.player_id)
		var tie_winner: int = valid[0].player_id
		remaining.append(tie_winner)
		seen.erase(tie_winner)
	surviving_players = remaining
	surviving_players.sort()
	for elimination: Dictionary in valid:
		if not seen.has(elimination.player_id):
			continue
		_remove_subject_from_play(elimination.player_id)
		player_eliminated.emit(elimination.player_id, surviving_players.size())
	if surviving_players.size() == 1:
		_finish_with_winner(surviving_players[0])


func _remove_subject_from_play(player_id: int) -> void:
	SubjectRoster.remove_from_play(player_id)


func _finish_with_winner(player_id: int) -> void:
	is_active = false
	stage = Stage.COMPLETE
	_disconnect_subjects()
	ultimate_winner_decided.emit(player_id)
	SubjectRoster.set_unpaired_all()


func _disconnect_subjects() -> void:
	SubjectRoster.disconnect_destabilised(_on_subject_destabilised)
