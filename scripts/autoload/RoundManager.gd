extends Node
## RoundManager (autoload singleton)
##
## Drives the three-round "Blind Round" structure. The full round order is
## secretly shuffled at Trial start; players only learn what was eliminated
## as rounds transition:
##   Round 1 — selected randomly (queue slot 0), no reveal.
##   Round 2 — UI announces which type was just eliminated (Round 1's type),
##             then plays queue slot 1: because the queue was uniformly
##             shuffled, slot 1 is a uniform random pick of the remaining two.
##   Round 3 — forced: the one type left in the queue.
##
## NETWORK: The secret queue must exist ONLY on the server. Clients receive
## just the current round type and elimination banners via the RPC hooks
## noted below — never the full queue, or the "blind" part breaks.

## Fired when the secret queue is locked in. Carries no queue contents.
signal round_queue_locked
## Fired at each transition that reveals an eliminated type (Rounds 2 & 3).
## NETWORK: @rpc replication hook — server broadcasts to all peers for UI.
signal round_type_eliminated(round_index: int, eliminated_type: String)
## Fired when a round actually begins.
## NETWORK: @rpc replication hook — server broadcasts to all peers.
signal round_started(round_index: int, protocol: ExperimentProtocol)
## Fired after Round 3 completes; carries the played order for the recap.
signal all_rounds_completed(played_order: Array)
## UI layer hook: request a banner (elimination notice / round intro).
## NETWORK: local-only — each peer renders banners from replicated signals.
signal round_banner_requested(text: String)

## The pool of round types available at Trial start.
const PROTOCOLS: Array[ExperimentProtocol] = [
	preload("res://resources/protocols/competitive_stress.tres"),
	preload("res://resources/protocols/adaptive_containment.tres"),
	preload("res://resources/protocols/sustained_exposure.tres"),
]
const TOTAL_ROUNDS: int = 3

## 1-based index of the round in progress (0 = Trial not started).
## NETWORK: @rpc replication hook — sync to all peers.
var current_round_index: int = 0
## Type of the round in progress ("" between rounds).
## NETWORK: @rpc replication hook — sync to all peers.
var current_round_type: String = ""
var current_protocol: ExperimentProtocol = null
## Types already played, in order.
## NETWORK: @rpc replication hook — safe to sync (already revealed).
var round_history: Array[String] = []

## The shuffled secret order for all three rounds.
## NETWORK: SERVER-ONLY SECRET — never replicate this array to clients.
var _secret_protocol_queue: Array[ExperimentProtocol] = []


## Shuffles the round pool into a secret queue. Call once at Trial start,
## on the server only.
## NETWORK: @rpc replication hook — server-side; clients only get the
## round_queue_locked notification, not the contents.
func secretly_queue_rounds(seed: int = 0) -> void:
	_secret_protocol_queue = PROTOCOLS.duplicate()
	var random := RandomNumberGenerator.new()
	random.seed = seed
	for i: int in range(_secret_protocol_queue.size() - 1, 0, -1):
		var swap_index: int = random.randi_range(0, i)
		var protocol: ExperimentProtocol = _secret_protocol_queue[i]
		_secret_protocol_queue[i] = _secret_protocol_queue[swap_index]
		_secret_protocol_queue[swap_index] = protocol
	current_round_index = 0
	current_round_type = ""
	current_protocol = null
	round_history.clear()
	round_queue_locked.emit()


## Builds the same seeded queue while placing a configured Protocol first.
## This is the local quick-start seam; the canonical Trial still uses the
## blind queue above.
func queue_local_protocol(protocol_classification: String, seed: int) -> bool:
	secretly_queue_rounds(seed)
	var selected_index: int = -1
	for index: int in _secret_protocol_queue.size():
		if _secret_protocol_queue[index].classification == protocol_classification:
			selected_index = index
			break
	if selected_index == -1:
		push_warning("RoundManager: unknown local Protocol '%s'." % protocol_classification)
		return false
	var selected: ExperimentProtocol = _secret_protocol_queue[selected_index]
	_secret_protocol_queue.remove_at(selected_index)
	_secret_protocol_queue.push_front(selected)
	return true


## Advances the Trial to the next round, handling the reveal rules for each
## transition. Returns the new round type, or "" when the Trial is over.
## NETWORK: @rpc replication hook — server drives this; the resulting
## round_started / round_type_eliminated signals are what get broadcast.
func advance_to_next_round() -> String:
	if _secret_protocol_queue.is_empty():
		push_warning("RoundManager: call secretly_queue_rounds() before advancing.")
		return ""
	if current_round_index >= TOTAL_ROUNDS:
		all_rounds_completed.emit(round_history.duplicate())
		return ""

	current_round_index += 1
	current_protocol = _secret_protocol_queue[current_round_index - 1]
	current_round_type = current_protocol.classification

	match current_round_index:
		1:
			# Round 1: random selection, nothing revealed yet.
			_display_banner("ROUND 1\n%s" % current_protocol.experiment_brief())
		2:
			# Round 2: reveal that Round 1's type is out of the pool, then
			# play a (pre-shuffled, therefore random) pick of the last two.
			var eliminated: String = round_history[0]
			round_type_eliminated.emit(2, eliminated)
			_display_banner("PREVIOUS EXPERIMENT PROTOCOL COMPLETE")
			_display_banner("ROUND 2\n%s" % current_protocol.experiment_brief())
		3:
			# Round 3: no choice left — the final remaining type is forced.
			var eliminated: String = round_history[1]
			round_type_eliminated.emit(3, eliminated)
			_display_banner("PREVIOUS EXPERIMENT PROTOCOL COMPLETE")
			_display_banner("FINAL ROUND\n%s" % current_protocol.experiment_brief())

	round_history.append(current_round_type)
	round_started.emit(current_round_index, current_protocol)
	return current_round_type


## Round types still hidden in the queue (server-side helper for tooling).
func get_remaining_pool() -> Array[String]:
	var remaining: Array[String] = []
	for protocol: ExperimentProtocol in _secret_protocol_queue.slice(current_round_index):
		remaining.append(protocol.classification)
	return remaining


func is_trial_complete() -> bool:
	return current_round_index >= TOTAL_ROUNDS


## Subject-versus-Subject Impacts are only legal during a PVP round; ENVIRONMENT
## and PVE rounds disable all Subject-on-Subject interference. Impact systems
## (see Player.apply_impact) consult this before applying anything.
func is_pvp_enabled() -> bool:
	return current_round_type == "PVP"


## Placeholder UI dispatch: emits the banner signal for a future HUD scene
## and mirrors it to the console so headless runs stay observable.
func _display_banner(text: String) -> void:
	round_banner_requested.emit(text)
	print("[RoundManager] %s" % text)
