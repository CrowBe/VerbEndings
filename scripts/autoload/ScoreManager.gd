extends Node
## ScoreManager (autoload singleton)
##
## Basic points system and ranking ladder. Each round type (PVP / PVE /
## PUZZLE) has its own placement ladder and bonus-event table, but all
## points flow into ONE cumulative total per player — the ranking ladder
## carries across all three rounds and seeds the Round 2 draft order.
##
## NETWORK: The server is the only writer. Clients receive ladder updates
## via the RPC hooks on the signals below.

## NETWORK: @rpc replication hook — broadcast each award for kill-feed UI.
signal points_awarded(player_id: int, amount: int, round_type: String, reason: String)
## NETWORK: @rpc replication hook — broadcast the re-sorted ladder.
signal ladder_updated(ladder: Array)

## Placement points per round type, index 0 = 1st place. Placements beyond
## the table earn the final entry (participation points).
const PLACEMENT_LADDERS: Dictionary = {
	"PVP": [100, 80, 60, 45, 30, 15],
	"PVE": [90, 75, 60, 45, 30, 15],
	"PUZZLE": [110, 85, 60, 40, 25, 10],
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
	"PUZZLE": {
		"mechanism_solved": 15,
		"no_hint_clear": 30,
		"speed_bonus": 20,
		"unit_complete": 10,
	},
}

## Cumulative totals: player_id -> points. Never reset between rounds.
## NETWORK: @rpc replication hook — sync to all peers.
var player_points: Dictionary = {}


## Awards placement points for a finished round. `ordered_player_ids` is
## finish order, winner first.
## NETWORK: @rpc replication hook — server-side, at round end.
func award_placements(round_type: String, ordered_player_ids: Array) -> void:
	var ladder: Array = PLACEMENT_LADDERS.get(round_type, [])
	if ladder.is_empty():
		push_warning("ScoreManager: unknown round type '%s'." % round_type)
		return
	for placement: int in ordered_player_ids.size():
		var amount: int = ladder[mini(placement, ladder.size() - 1)]
		add_points(ordered_player_ids[placement], amount, round_type,
				"placement_%d" % (placement + 1))


## Awards placement points to whole chains at once (partners always place
## together). `ordered_chain_ids` is finish order, winning chain first;
## both members receive the full placement award. A Self-Chain's lone
## player is only paid once.
## NETWORK: @rpc replication hook — server-side, at round end.
func award_chain_placements(round_type: String, ordered_chain_ids: Array) -> void:
	var ladder: Array = PLACEMENT_LADDERS.get(round_type, [])
	if ladder.is_empty():
		push_warning("ScoreManager: unknown round type '%s'." % round_type)
		return
	for placement: int in ordered_chain_ids.size():
		var chain: Dictionary = VerbChainManager.verb_chains.get(
				ordered_chain_ids[placement], {})
		if chain.is_empty():
			continue
		var amount: int = ladder[mini(placement, ladder.size() - 1)]
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


## Low-level award. All point mutations funnel through here so replication
## has a single choke point.
## NETWORK: @rpc replication hook — server-side only.
func add_points(player_id: int, amount: int, round_type: String, reason: String) -> void:
	player_points[player_id] = get_total(player_id) + amount
	points_awarded.emit(player_id, amount, round_type, reason)
	ladder_updated.emit(get_ladder())


func get_total(player_id: int) -> int:
	return player_points.get(player_id, 0)


## The ranking ladder: Array of {player_id, points, rank}, best first.
## Tied totals share a rank (competition ranking: 1, 2, 2, 4...).
func get_ladder() -> Array[Dictionary]:
	var ids: Array = player_points.keys()
	ids.sort_custom(func(a: int, b: int) -> bool:
		if player_points[a] != player_points[b]:
			return player_points[a] > player_points[b]
		return a < b)
	var ladder: Array[Dictionary] = []
	var rank: int = 0
	var previous_points: int = -1
	for i: int in ids.size():
		if player_points[ids[i]] != previous_points:
			rank = i + 1
			previous_points = player_points[ids[i]]
		ladder.append({"player_id": ids[i], "points": player_points[ids[i]], "rank": rank})
	return ladder


## Draft order for Round 2: least points first (ties broken by player id so
## the order is deterministic on every peer).
func get_draft_order_by_points(player_ids: Array) -> Array[int]:
	var order: Array[int] = []
	for player_id: int in player_ids:
		order.append(player_id)
	order.sort_custom(func(a: int, b: int) -> bool:
		if get_total(a) != get_total(b):
			return get_total(a) < get_total(b)
		return a < b)
	return order


## Full wipe, for returning to the main menu — NOT between rounds (the
## ladder deliberately persists across all three rounds).
func reset() -> void:
	player_points.clear()
	ladder_updated.emit(get_ladder())
