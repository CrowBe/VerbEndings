extends Node
## LobbyManager (autoload singleton)
##
## Round 1 lobby flow:
##   1. Players enter with NO verb (VerbType.NONE).
##   2. Verb selection opens: a simple filterable list of unclaimed verbs.
##      Each player's time-to-choose is recorded.
##   3. Draft: the SLOWEST verb-pickers choose their pair first. Turns skip
##      anyone who has already been drafted by an earlier chooser.
##
## Later-Round lobby flow:
##   - Verbs/Character Identities carry over unchanged from Round 1.
##   - The previous Round's Pairs dissolve; Subjects draft new Pairs in order of
##     LEAST Trial Score to most (ScoreManager totals, which persist
##     across rounds).
##
## Both lobbies end at the Synced Insertion Vector: a complete partnership
## must stand on the same platform to launch into the round together.
##
## NETWORK: All drafting decisions are server-authoritative. NetworkSession
## binds client requests to their RPC sender and validates them here before
## state changes; results return in authoritative snapshots.

## NETWORK: replication boundary — broadcast roster changes.
signal lobby_joined(player_id: int)
## NETWORK: replication boundary — tells clients to show the verb list.
signal verb_selection_opened
## NETWORK: replication boundary — broadcast each claim so lists refresh.
signal verb_selected(player_id: int, verb: Enums.VerbType, seconds_taken: float)
## NETWORK: replication boundary — broadcast the full draft order for UI.
signal draft_started(round_index: int, draft_order: Array)
## NETWORK: replication boundary — tells everyone whose pick it is.
signal draft_turn_started(chooser_id: int)
## NETWORK: replication boundary — broadcast each locked pairing.
signal pair_locked(chooser_id: int, target_id: int, chain: Dictionary)
## NETWORK: replication boundary — the lobby may proceed to the platforms.
signal draft_completed
## Both partners are aboard the same Insertion Vector — launch the pod.
## NETWORK: replication boundary — server confirms, then broadcasts.
signal insertion_vector_launched(vector_id: int, player_ids: Array)

## Everyone currently in the lobby.
## NETWORK: replication boundary — sync to all peers.
var lobby_players: Array[int] = []
## Remaining draft turns, front = next chooser.
## NETWORK: replication boundary — sync to all peers.
var draft_queue: Array[int] = []
## Whose pick it is right now (-1 = no draft running).
## NETWORK: replication boundary — sync to all peers.
var current_chooser_id: int = -1

## Character Identity registry: VerbType -> claiming player_id. Enforces
## that each verb-named character exists at most once per Trial.
## NETWORK: server-authoritative; replicate on change.
var _claimed_identities: Dictionary = {}
## Ticks (msec) when selection opened; -1 = selection closed.
var _selection_open_msec: int = -1
## player_id -> seconds they took to lock a verb.
var _verb_pick_seconds: Dictionary = {}
## Insertion Vector occupancy: vector_id -> Array of player_ids aboard.
## NETWORK: server-authoritative; derived from replicated player positions.
var _vector_occupants: Dictionary = {}


## Clears local Trial state before rebuilding a roster.
func reset() -> void:
	lobby_players.clear()
	draft_queue.clear()
	current_chooser_id = -1
	_claimed_identities.clear()
	_selection_open_msec = -1
	_verb_pick_seconds.clear()
	_vector_occupants.clear()


## A player enters the lobby with no verb selected yet.
## NETWORK: replication boundary — server-side, on peer connect.
func join_lobby(player_id: int) -> void:
	if player_id in lobby_players:
		return
	lobby_players.append(player_id)
	VerbChainManager.register_player(player_id, Enums.VerbType.NONE)
	lobby_joined.emit(player_id)


## Removes a leaving player: identity, roster slot, and any queued turn.
## NETWORK: replication boundary — server-side, on peer disconnect.
func release_player(player_id: int) -> void:
	lobby_players.erase(player_id)
	draft_queue.erase(player_id)
	_verb_pick_seconds.erase(player_id)
	for verb: Enums.VerbType in _claimed_identities.keys():
		if _claimed_identities[verb] == player_id:
			_claimed_identities.erase(verb)
			break
	VerbChainManager.unregister_player(player_id)
	if current_chooser_id == player_id:
		_advance_draft_turn()


## Opens the Round 1 verb-selection phase and starts the clock.
## NETWORK: replication boundary — server-side, when the lobby fills.
func open_verb_selection() -> void:
	_selection_open_msec = Time.get_ticks_msec()
	_verb_pick_seconds.clear()
	verb_selection_opened.emit()


## The simple filterable list: unclaimed verbs whose name contains
## `filter_text` (case-insensitive; empty = all). Returns entries of
## {verb: VerbType, name: String} ready for a UI list.
func get_selectable_verbs(filter_text: String = "") -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var needle: String = filter_text.to_lower()
	for verb: Enums.VerbType in Enums.VerbType.values():
		if verb == Enums.VerbType.NONE or _claimed_identities.has(verb):
			continue
		var verb_name: String = Enums.verb_name(verb).capitalize()
		if needle.is_empty() or verb_name.to_lower().contains(needle):
			results.append({"verb": verb, "name": verb_name})
	return results


## A player locks in their Verb. First-come first-served
## on uniqueness; time-to-choose is recorded and later decides draft order
## (slowest picks their pair first). One pick per player, no re-picks.
## NetworkSession exposes this through a reliable sender-bound request; the
## host clock stamps the pick, never the client's.
func select_verb(player_id: int, verb: Enums.VerbType) -> bool:
	var seconds_taken: float = (Time.get_ticks_msec() - _selection_open_msec) / 1000.0
	return _select_verb(player_id, verb, seconds_taken)


## Trusted local-development seam. Quick-start Subjects have no human pick
## latency, so they all receive the same authored duration and deterministic
## Subject-id tie-break instead of inheriting machine scheduling jitter.
func select_verb_for_local_playtest(
	player_id: int,
	verb: Enums.VerbType,
) -> bool:
	return _select_verb(player_id, verb, 0.0)


func _select_verb(
	player_id: int,
	verb: Enums.VerbType,
	seconds_taken: float,
) -> bool:
	if _selection_open_msec < 0:
		push_warning("LobbyManager: verb selection is not open.")
		return false
	if player_id not in lobby_players:
		push_warning("LobbyManager: player %d is not in the lobby." % player_id)
		return false
	if _verb_pick_seconds.has(player_id):
		push_warning("LobbyManager: player %d already picked a verb." % player_id)
		return false
	if verb not in Enums.VerbType.values() or verb == Enums.VerbType.NONE \
			or _claimed_identities.has(verb):
		push_warning("LobbyManager: verb '%s' is unavailable."
				% Enums.verb_name(verb).capitalize())
		return false

	_claimed_identities[verb] = player_id
	VerbChainManager.register_player(player_id, verb)
	_verb_pick_seconds[player_id] = seconds_taken
	verb_selected.emit(player_id, verb, seconds_taken)
	return true


## Closes verb selection and starts the Round 1 draft. Draft order is
## SLOWEST pick first. Players who never picked get a random leftover verb
## and are treated as slowest of all (they head the queue).
## NETWORK: replication boundary — server-side, on selection timer expiry.
func begin_round_one_draft() -> void:
	_selection_open_msec = -1
	_auto_assign_stragglers()
	var order: Array[int] = lobby_players.duplicate()
	order.sort_custom(func(a: int, b: int) -> bool:
		var time_a: float = _verb_pick_seconds.get(a, INF)
		var time_b: float = _verb_pick_seconds.get(b, INF)
		if time_a != time_b:
			return time_a > time_b
		return a < b)
	_start_draft(1, order)


## Starts a Round Two or Three draft with the same Verbs and fresh Pairs.
## NETWORK: replication boundary — server-side, at the next Pair Draft.
func begin_subsequent_round_draft(round_index: int) -> void:
	if round_index < 2 or round_index > RoundManager.TOTAL_ROUNDS:
		push_warning("LobbyManager: subsequent draft requires Round 2 or 3.")
		return
	VerbChainManager.dissolve_all_chains()
	_start_draft(
			round_index,
			ScoreManager.get_draft_order_by_trial_score(lobby_players))


## Deterministic local-host fallback used when no Pair Draft UI is present.
## It follows the live draft queue and therefore exercises the same validation,
## signals, and forced odd-roster Self-Chain path as player choices.
func complete_draft_automatically() -> void:
	while current_chooser_id != -1:
		var chooser_id: int = current_chooser_id
		var target_id: int = -1
		for candidate_id: int in lobby_players:
			if candidate_id != chooser_id and not _is_paired(candidate_id):
				target_id = candidate_id
				break
		if target_id == -1:
			target_id = chooser_id
		if not request_pairing(chooser_id, target_id):
			return


## The current chooser drafts a Partner by player id
## (their own id = deliberate Self-Chain). Validates turn order and target
## availability, then locks the chain through VerbChainManager.
## NetworkSession exposes this through a reliable sender-bound request and
## verifies that the sender is the current chooser before this validation.
func request_pairing(chooser_id: int, target_id: int) -> bool:
	if chooser_id != current_chooser_id:
		push_warning("LobbyManager: it is not player %d's turn to choose." % chooser_id)
		return false
	if target_id not in lobby_players:
		push_warning("LobbyManager: target %d is not in the lobby." % target_id)
		return false
	if chooser_id != target_id and _is_paired(target_id):
		push_warning("LobbyManager: target %d is already chained." % target_id)
		return false

	var chain: Dictionary = VerbChainManager.establish_verb_chain(chooser_id, target_id)
	if chain.is_empty():
		return false
	pair_locked.emit(chooser_id, target_id, chain)
	_advance_draft_turn()
	return true


## --- Synced Insertion Vector -------------------------------------------
## Platforms (see scenes/InsertionVector.tscn) report bodies stepping on and
## off. When a full partnership stands on one platform, it launches.

## NETWORK: replication boundary — occupancy is derived server-side from
## authoritative positions; clients never report their own occupancy.
func notify_vector_entered(vector_id: int, player_id: int) -> void:
	var occupants: Array = _vector_occupants.get_or_add(vector_id, [])
	if player_id not in occupants:
		occupants.append(player_id)
	_check_synced_launch(vector_id)


func notify_vector_exited(vector_id: int, player_id: int) -> void:
	if _vector_occupants.has(vector_id):
		_vector_occupants[vector_id].erase(player_id)


## Launches the platform only when a complete chain is aboard: both partners
## for a normal chain, or the lone player for a Self-Chain.
func _check_synced_launch(vector_id: int) -> void:
	var occupants: Array = _vector_occupants.get(vector_id, [])
	for player_id: int in occupants:
		var partner_id: int = VerbChainManager.get_partner_id(player_id)
		if partner_id == -1:
			continue
		var synced: bool = partner_id == player_id or partner_id in occupants
		if synced:
			var pod: Array = [player_id] if partner_id == player_id \
					else [player_id, partner_id]
			for rider: int in pod:
				occupants.erase(rider)
			insertion_vector_launched.emit(vector_id, pod)
			return


## Any player who never locked a verb gets a random leftover. They forfeited
## the clock entirely, so they count as slowest (INF pick time keeps them at
## the head of the draft order).
func _auto_assign_stragglers() -> void:
	for player_id: int in lobby_players:
		if _verb_pick_seconds.has(player_id):
			continue
		var free_verbs: Array[Dictionary] = get_selectable_verbs()
		if free_verbs.is_empty():
			push_warning("LobbyManager: no verbs left for player %d." % player_id)
			continue
		var verb: Enums.VerbType = free_verbs.pick_random().verb
		_claimed_identities[verb] = player_id
		VerbChainManager.register_player(player_id, verb)
		verb_selected.emit(player_id, verb, INF)


func _start_draft(round_index: int, order: Array[int]) -> void:
	draft_queue = order.duplicate()
	draft_started.emit(round_index, order.duplicate())
	_advance_draft_turn()


## Pops the next turn, SKIPPING anyone already drafted as someone's pair.
## When the only unpaired player left is the chooser themself, they are
## auto Self-Chained; when nobody is left, the draft completes.
func _advance_draft_turn() -> void:
	current_chooser_id = -1
	while not draft_queue.is_empty():
		var candidate: int = draft_queue.pop_front()
		if _is_paired(candidate):
			continue  # Already selected as someone's pair — skipped.
		if _unpaired_count() == 1:
			# Odd player out: forced Self-Chain.
			var chain: Dictionary = VerbChainManager.establish_verb_chain(
					candidate, candidate)
			pair_locked.emit(candidate, candidate, chain)
			break
		current_chooser_id = candidate
		draft_turn_started.emit(candidate)
		return
	draft_queue.clear()
	draft_completed.emit()


func _is_paired(player_id: int) -> bool:
	return VerbChainManager.get_partner_id(player_id) != -1


func _unpaired_count() -> int:
	var count: int = 0
	for player_id: int in lobby_players:
		if not _is_paired(player_id):
			count += 1
	return count
