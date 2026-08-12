extends Node
## ScoreManager (autoload singleton)
##
## Subject-owned Round Score and cumulative Trial Score. Each development
## classification has its own reward tables, but points always belong to one
## Subject.
##
## NETWORK: The server is the only writer. Clients receive ranking updates
## via the RPC hooks on the signals below.

## NETWORK: @rpc replication hook — broadcast each award for score-feed UI.
signal points_awarded(player_id: int, amount: int, round_type: String, reason: String)
## NETWORK: @rpc replication hook — broadcast the re-sorted Trial Ranking.
signal trial_ranking_updated(trial_ranking: Array)

## Placement points per round type, index 0 = 1st place. Placements beyond
## the table earn the final entry (participation points).
const PLACEMENT_TABLES: Dictionary = {
	"PVP": [100, 80, 60, 45, 30, 15],
	"PVE": [90, 75, 60, 45, 30, 15],
	"ENVIRONMENT": [110, 85, 60, 40, 25, 10],
}

## Bonus events per round type: reason -> points.
const BONUS_EVENTS: Dictionary = {
	"PVP": {"knockout": 15, "final_blow": 25, "flawless": 20},
	"PVE": {
		"objective_cleared": 20,
		"partner_revive": 10,
		"boss_stagger": 15,
		"swarm_kill": 8,
		"survival_tick": 3,
	},
	"ENVIRONMENT": {},
}

## Cumulative totals: player_id -> points. Never reset between rounds.
## NETWORK: @rpc replication hook — sync to all peers.
var player_points: Dictionary = {}
## Round index -> {player_id -> Round Score}.
var round_scores: Dictionary = {}


## Enrols a Subject at zero so the scoring and ranking service recognises the
## complete roster before the first award.
func register_player(player_id: int) -> void:
	if player_points.has(player_id):
		return
	player_points[player_id] = 0
	trial_ranking_updated.emit(get_trial_ranking())


## Awards placement points for a finished round. `ordered_player_ids` is
## finish order, winner first.
## NETWORK: @rpc replication hook — server-side, at round end.
func award_placements(round_type: String, ordered_player_ids: Array) -> void:
	var reward_table: Array = PLACEMENT_TABLES.get(round_type, [])
	if reward_table.is_empty():
		push_warning("ScoreManager: unknown round type '%s'." % round_type)
		return
	for placement: int in ordered_player_ids.size():
		var amount: int = reward_table[mini(placement, reward_table.size() - 1)]
		add_points(ordered_player_ids[placement], amount, round_type,
				"placement_%d" % (placement + 1))


## Applies the Protocol's authored placement policy to a Subject performance
## order. Chain-shared Protocols collapse that order to each Verb Chain's best
## placed member before awarding points to both Partners.
func award_protocol_placements(protocol: ExperimentProtocol,
		ordered_player_ids: Array) -> void:
	var sharing: String = protocol.scoring_rules.get(
			"placement_sharing", "individual")
	if sharing != "verb_chain":
		award_placements(protocol.classification, ordered_player_ids)
		return
	award_chain_placements(protocol.classification,
			get_ordered_chain_ids(ordered_player_ids),
			protocol.scoring_rules.get("shared_reward_synergy", false))


## Collapses a Subject performance order to unique active Verb Chains. The
## first member encountered determines the Chain's placement, so an Eliminated
## Partner may be absent without losing the shared result.
func get_ordered_chain_ids(ordered_player_ids: Array) -> Array[int]:
	var ordered_chain_ids: Array[int] = []
	for player_id: int in ordered_player_ids:
		var chain: Dictionary = VerbChainManager.get_chain_for_player(player_id)
		if chain.is_empty() or ordered_chain_ids.has(chain.chain_id):
			continue
		ordered_chain_ids.append(chain.chain_id)
	return ordered_chain_ids


## Awards placement points to whole chains at once (partners always place
## together). `ordered_chain_ids` is finish order, winning chain first;
## both members receive the full placement award. A Self-Chain's lone
## player is only paid once.
## NETWORK: @rpc replication hook — server-side, at round end.
func award_chain_placements(round_type: String, ordered_chain_ids: Array,
		apply_synergy: bool = false) -> void:
	var reward_table: Array = PLACEMENT_TABLES.get(round_type, [])
	if reward_table.is_empty():
		push_warning("ScoreManager: unknown round type '%s'." % round_type)
		return
	for placement: int in ordered_chain_ids.size():
		var chain: Dictionary = VerbChainManager.verb_chains.get(
				ordered_chain_ids[placement], {})
		if chain.is_empty():
			continue
		var base_amount: int = reward_table[mini(placement, reward_table.size() - 1)]
		var amount: int = _shared_reward_amount(base_amount, chain, apply_synergy)
		var reason: String = "placement_%d" % (placement + 1)
		add_points(chain.player_a_id, amount, round_type, reason)
		if not chain.is_self_chain:
			add_points(chain.player_b_id, amount, round_type, reason)


## Awards a named bonus event (e.g. "knockout" in PVP).
## NETWORK: @rpc replication hook — server-side, from gameplay systems.
func award_bonus(player_id: int, round_type: String, event: String) -> void:
	var events: Dictionary = BONUS_EVENTS.get(round_type, {})
	if not events.has(event):
		push_warning("ScoreManager: unknown bonus '%s' for %s." % [event, round_type])
		return
	add_points(player_id, events[event], round_type, event)


## Applies the Protocol's authored bonus-sharing policy. Cooperative events
## credit both Partners separately; all other events remain individual.
func award_protocol_bonus(player_id: int, protocol: ExperimentProtocol,
		event: String) -> void:
	var shared_events: Array = protocol.scoring_rules.get("shared_bonus_events", [])
	if not shared_events.has(event):
		award_bonus(player_id, protocol.classification, event)
		return
	var chain: Dictionary = VerbChainManager.get_chain_for_player(player_id)
	if chain.is_empty():
		award_bonus(player_id, protocol.classification, event)
		return
	var events: Dictionary = BONUS_EVENTS.get(protocol.classification, {})
	if not events.has(event):
		push_warning("ScoreManager: unknown bonus '%s' for %s."
				% [event, protocol.classification])
		return
	var amount: int = _shared_reward_amount(events[event], chain,
			protocol.scoring_rules.get("shared_reward_synergy", false))
	add_points(chain.player_a_id, amount, protocol.classification, event)
	if not chain.is_self_chain:
		add_points(chain.player_b_id, amount, protocol.classification, event)


func _shared_reward_amount(base_amount: int, chain: Dictionary,
		apply_synergy: bool) -> int:
	if not apply_synergy or chain.is_self_chain:
		return base_amount
	return roundi(base_amount * float(chain.synergy_coefficient))


## Low-level award. All point mutations funnel through here so replication
## has a single choke point.
## NETWORK: @rpc replication hook — server-side only.
func add_points(player_id: int, amount: int, round_type: String, reason: String) -> void:
	player_points[player_id] = get_total(player_id) + amount
	var current_round_scores: Dictionary = round_scores.get_or_add(
			RoundManager.current_round_index, {})
	current_round_scores[player_id] = current_round_scores.get(player_id, 0) + amount
	points_awarded.emit(player_id, amount, round_type, reason)
	trial_ranking_updated.emit(get_trial_ranking())


func get_total(player_id: int) -> int:
	return player_points.get(player_id, 0)


func get_round_score(round_index: int, player_id: int) -> int:
	return round_scores.get(round_index, {}).get(player_id, 0)


## Trial Ranking: Array of {player_id, trial_score, rank}, best first.
## Tied totals share a rank (competition ranking: 1, 2, 2, 4...).
func get_trial_ranking() -> Array[Dictionary]:
	var ids: Array = player_points.keys()
	ids.sort_custom(func(a: int, b: int) -> bool:
		if player_points[a] != player_points[b]:
			return player_points[a] > player_points[b]
		return a < b)
	var trial_ranking: Array[Dictionary] = []
	var rank: int = 0
	var previous_points: int = -1
	for i: int in ids.size():
		if player_points[ids[i]] != previous_points:
			rank = i + 1
			previous_points = player_points[ids[i]]
		trial_ranking.append({
			"player_id": ids[i],
			"trial_score": player_points[ids[i]],
			"rank": rank,
		})
	return trial_ranking


## Later-Round Pair Draft order: least Trial Score first. Ties break by
## Player id so the order is deterministic on every peer.
func get_draft_order_by_trial_score(player_ids: Array) -> Array[int]:
	var order: Array[int] = []
	for player_id: int in player_ids:
		order.append(player_id)
	order.sort_custom(func(a: int, b: int) -> bool:
		if get_total(a) != get_total(b):
			return get_total(a) < get_total(b)
		return a < b)
	return order


## Full wipe, for returning to the main menu — NOT between rounds (the
## Trial Score deliberately persists across all three Rounds).
func reset() -> void:
	player_points.clear()
	round_scores.clear()
	trial_ranking_updated.emit(get_trial_ranking())
