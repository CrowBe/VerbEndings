extends Node
## VerbChainManager (autoload singleton)
##
## Server-authoritative registry of players, their assigned VerbType, and the
## verb chains (pairs) linking them. Registered as an autoload in
## project.godot so it exists on every peer.
##
## NETWORK: All mutating functions in this script are intended to run on the
## server only, then be replicated to clients via RPC hooks (see the
## "@rpc replication hook" comments below).

## Emitted whenever a chain is created or recalculated.
signal verb_chain_established(chain: Dictionary)
## Emitted when a lone player is paired with themselves.
signal self_chain_triggered(player_id: int)

## Baseline power rating before synergy/versatility modifiers are applied.
const BASE_POWER_RATING: float = 10.0

## Multiplier applied to the Synergy Coefficient when a player self-chains.
## Self-Chains are intentionally weaker than a two-Subject Pair.
const SELF_CHAIN_SYNERGY_PENALTY: float = 0.5

## Synergy matrix: how well two verbs amplify each other, as a coefficient.
## Keyed by [VerbType, VerbType] with the lower enum value first (see
## _synergy_key). Pairs not listed fall back to DEFAULT_SYNERGY.
## NETWORK: constant table — identical on every peer, never replicated.
const SYNERGY_MATRIX: Dictionary = {
	[Enums.VerbType.BURN, Enums.VerbType.FREEZE]: 1.8,   # thermal shock
	[Enums.VerbType.BURN, Enums.VerbType.GROW]: 0.4,     # fire vs foliage
	[Enums.VerbType.BURN, Enums.VerbType.SHIELD]: 1.3,   # flaming aegis
	[Enums.VerbType.SHIELD, Enums.VerbType.FREEZE]: 1.5, # ice wall
	[Enums.VerbType.GROW, Enums.VerbType.STRETCH]: 1.6,  # elastic overgrowth
	[Enums.VerbType.GROW, Enums.VerbType.SHIELD]: 1.4,   # bark armor
	[Enums.VerbType.ROLL, Enums.VerbType.BOUNCE]: 1.7,   # kinetic loop
	[Enums.VerbType.ROLL, Enums.VerbType.STRETCH]: 1.2,  # slingshot
	[Enums.VerbType.JUMP, Enums.VerbType.BOUNCE]: 1.6,   # double launch
	[Enums.VerbType.JUMP, Enums.VerbType.STRETCH]: 1.3,  # grapple vault
	[Enums.VerbType.FREEZE, Enums.VerbType.ROLL]: 1.4,   # ice skating
	[Enums.VerbType.REWIND, Enums.VerbType.BURN]: 1.5,   # un-burn ignition
	[Enums.VerbType.REWIND, Enums.VerbType.JUMP]: 1.4,   # replayed leap
	[Enums.VerbType.REWIND, Enums.VerbType.REWIND]: 0.2, # paradox lockout
}
const DEFAULT_SYNERGY: float = 1.0

## Versatility Index weights per verb: how flexibly a verb applies across
## traversal, offense, and defense. Averaged across the pair.
const VERSATILITY_WEIGHTS: Dictionary = {
	Enums.VerbType.NONE: 0.0,
	Enums.VerbType.BURN: 0.9,
	Enums.VerbType.SHIELD: 0.7,
	Enums.VerbType.GROW: 1.1,
	Enums.VerbType.STRETCH: 1.3,
	Enums.VerbType.ROLL: 1.0,
	Enums.VerbType.JUMP: 1.0,
	Enums.VerbType.BOUNCE: 1.1,
	Enums.VerbType.FREEZE: 0.8,
	Enums.VerbType.REWIND: 1.4,
}

## Active players: peer_id (int) -> VerbType.
## NETWORK: server-authoritative; replicate on change via a future
## @rpc("authority", "call_local", "reliable") sync function.
var active_players: Dictionary = {}

## Established chains: chain_id (int) -> chain Dictionary (see _build_chain).
## NETWORK: server-authoritative; replicate alongside active_players.
var verb_chains: Dictionary = {}

## Reverse lookup: peer_id -> chain_id, so a player's chain is O(1) to find.
## NETWORK: derived state — rebuild locally from verb_chains, do not replicate.
var _player_to_chain: Dictionary = {}

## The authored Verb Chain for each Subject in the current Round. A Severed
## Chain remains here until scheduled dissolution so shared rewards still
## reach both Partners after one has been Eliminated.
var _round_chains: Dictionary = {}
var _player_to_round_chain: Dictionary = {}

var _next_chain_id: int = 1


## Clears local Trial state before a quick-start replay or return to menu.
func reset() -> void:
	dissolve_all_chains()
	active_players.clear()
	_next_chain_id = 1


## Adds a player to the roster with their assigned verb.
## NETWORK: @rpc replication hook — server calls this, then broadcasts.
func register_player(player_id: int, verb: Enums.VerbType) -> void:
	active_players[player_id] = verb


## Removes a player and dissolves any chain they were part of.
## NETWORK: @rpc replication hook — call on peer disconnect (server-side).
func unregister_player(player_id: int) -> void:
	_dissolve_chain_for(player_id)
	_dissolve_round_chain_for(player_id)
	active_players.erase(player_id)


## Pairs two players into a verb chain and computes its power rating.
## Passing the same id twice creates a Self-Chain.
## Returns the chain Dictionary, or an empty Dictionary on invalid input.
## NETWORK: @rpc replication hook — server-authoritative; result must be
## broadcast to all peers so HUDs can display chain stats.
func establish_verb_chain(player_a_id: int, player_b_id: int) -> Dictionary:
	if not active_players.has(player_a_id) or not active_players.has(player_b_id):
		push_warning("VerbChainManager: cannot chain unregistered players %d/%d"
				% [player_a_id, player_b_id])
		return {}

	# Re-pairing dissolves any existing chains first.
	_dissolve_chain_for(player_a_id)
	_dissolve_chain_for(player_b_id)
	_dissolve_round_chain_for(player_a_id)
	_dissolve_round_chain_for(player_b_id)

	var chain: Dictionary = _build_chain(player_a_id, player_b_id)
	verb_chains[chain.chain_id] = chain
	_player_to_chain[player_a_id] = chain.chain_id
	_player_to_chain[player_b_id] = chain.chain_id
	_round_chains[chain.chain_id] = chain
	_player_to_round_chain[player_a_id] = chain.chain_id
	_player_to_round_chain[player_b_id] = chain.chain_id

	if chain.is_self_chain:
		self_chain_triggered.emit(player_a_id)
	verb_chain_established.emit(chain)
	_sync_player_overdrive(chain)
	return chain


## Pairs the whole roster. With an odd player count, the leftover player is
## chained with themselves (Self-Chain).
## NETWORK: @rpc replication hook — server runs this at Trial start.
func auto_pair_all_players() -> void:
	var ids: Array = active_players.keys()
	ids.sort()
	while ids.size() >= 2:
		establish_verb_chain(ids.pop_front(), ids.pop_front())
	if ids.size() == 1:
		establish_verb_chain(ids[0], ids[0])


## Returns the chain a player belongs to, or an empty Dictionary.
func get_chain_for_player(player_id: int) -> Dictionary:
	var chain_id: int = _player_to_chain.get(player_id, -1)
	return verb_chains.get(chain_id, {})


## Returns the partner's id, or -1 if unchained. Self-chained players are
## their own partner.
func get_partner_id(player_id: int) -> int:
	var chain: Dictionary = get_chain_for_player(player_id)
	if chain.is_empty():
		return -1
	return chain.player_b_id if chain.player_a_id == player_id else chain.player_a_id


## Returns the Verb Chain authored for this Subject's current Round. Unlike
## get_chain_for_player(), this still returns a Chain after Severance so Round
## scoring retains its symmetric reward policy.
func get_round_chain_for_player(player_id: int) -> Dictionary:
	var chain_id: int = _player_to_round_chain.get(player_id, -1)
	return _round_chains.get(chain_id, {})


func get_round_chain(chain_id: int) -> Dictionary:
	return _round_chains.get(chain_id, {})


## Ends a two-Subject Chain early because one Partner was Eliminated. The
## surviving Subject pays its configured Severance Loss once and receives no
## Overdrive. Returns whether a live Chain was Severed.
## NETWORK: @rpc replication hook — server-side, broadcast the Severance and
## resulting Stability update.
func sever_chain_for(eliminated_player_id: int) -> bool:
	var chain_id: int = _player_to_chain.get(eliminated_player_id, -1)
	if chain_id == -1:
		return false
	var chain: Dictionary = verb_chains[chain_id]
	if chain.is_self_chain:
		return false
	var surviving_player_id: int = chain.player_b_id \
			if chain.player_a_id == eliminated_player_id else chain.player_a_id
	_remove_active_chain(chain)
	for body: Node in get_tree().get_nodes_in_group("players"):
		if body.get_multiplayer_authority() == surviving_player_id:
			body.apply_severance_loss()
			break
	return true


## Synergy Coefficient for a verb pair, from the compatibility matrix.
func get_synergy_coefficient(verb_a: Enums.VerbType, verb_b: Enums.VerbType) -> float:
	return SYNERGY_MATRIX.get(_synergy_key(verb_a, verb_b), DEFAULT_SYNERGY)


## Versatility Index for a verb pair: average flexibility, with a small bonus
## for bringing two different verbs to the chain.
func get_versatility_index(verb_a: Enums.VerbType, verb_b: Enums.VerbType) -> float:
	var average: float = (
		VERSATILITY_WEIGHTS.get(verb_a, 1.0) + VERSATILITY_WEIGHTS.get(verb_b, 1.0)
	) / 2.0
	var diversity_bonus: float = 1.1 if verb_a != verb_b else 1.0
	return average * diversity_bonus


func _build_chain(player_a_id: int, player_b_id: int) -> Dictionary:
	var verb_a: Enums.VerbType = active_players[player_a_id]
	var verb_b: Enums.VerbType = active_players[player_b_id]
	var is_self_chain: bool = player_a_id == player_b_id

	var synergy: float = get_synergy_coefficient(verb_a, verb_b)
	if is_self_chain:
		synergy *= SELF_CHAIN_SYNERGY_PENALTY
	var versatility: float = get_versatility_index(verb_a, verb_b)
	var modified_power_rating: float = BASE_POWER_RATING * synergy * versatility

	var chain_id: int = _next_chain_id
	_next_chain_id += 1
	return {
		"chain_id": chain_id,
		"player_a_id": player_a_id,
		"player_b_id": player_b_id,
		"verb_a": verb_a,
		"verb_b": verb_b,
		"is_self_chain": is_self_chain,
		"synergy_coefficient": synergy,
		"versatility_index": versatility,
		"modified_power_rating": modified_power_rating,
	}


func _dissolve_chain_for(player_id: int) -> void:
	var chain_id: int = _player_to_chain.get(player_id, -1)
	if chain_id == -1:
		return
	var chain: Dictionary = verb_chains[chain_id]
	_remove_active_chain(chain)
	_remove_round_chain(chain)


func _remove_active_chain(chain: Dictionary) -> void:
	_player_to_chain.erase(chain.player_a_id)
	_player_to_chain.erase(chain.player_b_id)
	verb_chains.erase(chain.chain_id)
	_clear_player_overdrive(chain.player_a_id)
	if not chain.is_self_chain:
		_clear_player_overdrive(chain.player_b_id)


func _remove_round_chain(chain: Dictionary) -> void:
	_player_to_round_chain.erase(chain.player_a_id)
	_player_to_round_chain.erase(chain.player_b_id)
	_round_chains.erase(chain.chain_id)


func _dissolve_round_chain_for(player_id: int) -> void:
	var chain_id: int = _player_to_round_chain.get(player_id, -1)
	if chain_id == -1:
		return
	_remove_round_chain(_round_chains[chain_id])


## Severs every Verb Chain. No Pair survives into the Collapse.
## Players stay registered in active_players — only the pairings die.
## NETWORK: @rpc replication hook — server-side, broadcast the wipe.
func dissolve_all_chains() -> void:
	for player_id: int in _player_to_chain.keys():
		_clear_player_overdrive(player_id)
	verb_chains.clear()
	_player_to_chain.clear()
	_round_chains.clear()
	_player_to_round_chain.clear()


func _sync_player_overdrive(chain: Dictionary) -> void:
	for body: Node in get_tree().get_nodes_in_group("players"):
		var player_id: int = body.get_multiplayer_authority()
		if player_id == chain.player_a_id:
			if chain.is_self_chain:
				body.enter_overdrive(player_id)
			else:
				body.exit_overdrive(chain.player_b_id)
		elif player_id == chain.player_b_id:
			body.exit_overdrive(chain.player_a_id)


func _clear_player_overdrive(player_id: int) -> void:
	for body: Node in get_tree().get_nodes_in_group("players"):
		if body.get_multiplayer_authority() == player_id:
			body.exit_overdrive()
			return


## Canonical dictionary key for an unordered verb pair.
func _synergy_key(verb_a: Enums.VerbType, verb_b: Enums.VerbType) -> Array:
	return [mini(verb_a, verb_b), maxi(verb_a, verb_b)]
