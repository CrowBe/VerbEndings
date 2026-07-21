extends Node
## SuddenDeathManager (autoload singleton) — "The Collapse"
##
## After Round 3, a final Survival Race tiebreaker fires for everyone tied
## at the top of the ladder — and partners always tie with each other, so
## even a single winning pair goes to Sudden Death: they duel each other for
## the crown. Only a Self-Chained solo player can win outright without it.
## CRITICAL RULE: every previous partnership is broken —
## all survivors are forced into a Solo state (paired_partner_id = null) and
## each one's verb enters Self-Chain OVERDRIVE (a per-verb multiplier far
## stronger than the normal self-chain penalty). Last blob standing wins.
##
## NETWORK: Everything here is server-authoritative. Eliminations and the
## final winner are broadcast via the RPC hooks noted on the signals.

## NETWORK: @rpc replication hook — broadcast so every client swaps to the
## Collapse arena and severs its local chain VFX.
signal sudden_death_triggered(participant_ids: Array)
## NETWORK: @rpc replication hook — broadcast each knockout for the feed.
signal player_eliminated(player_id: int, survivors_left: int)
## NETWORK: @rpc replication hook — broadcast the match result.
signal ultimate_winner_decided(player_id: int)

## Self-Chain OVERDRIVE profiles: what each verb becomes when its owner is
## forced Solo during The Collapse. "multiplier" feeds directly into
## Player.overdrive_multiplier; "effect" is flavor for the HUD/design docs.
const OVERDRIVE_PROFILES: Dictionary = {
	Enums.VerbType.NONE: {"multiplier": 1.0, "effect": "no verb, no overdrive"},
	Enums.VerbType.BURN: {"multiplier": 1.5, "effect": "trailing wildfire wake"},
	Enums.VerbType.SHIELD: {"multiplier": 1.2, "effect": "unbreakable second skin"},
	Enums.VerbType.GROW: {"multiplier": 1.4, "effect": "titan mass advantage"},
	Enums.VerbType.STRETCH: {"multiplier": 1.6, "effect": "slingshot self-launch"},
	Enums.VerbType.ROLL: {"multiplier": 1.8, "effect": "exponential momentum stacking"},
	Enums.VerbType.JUMP: {"multiplier": 1.5, "effect": "chained triple-leap"},
	Enums.VerbType.BOUNCE: {"multiplier": 1.7, "effect": "perfect-restitution ricochet"},
	Enums.VerbType.FREEZE: {"multiplier": 1.3, "effect": "frictionless ice sprint"},
	Enums.VerbType.REWIND: {"multiplier": 1.6, "effect": "one free fall undo"},
}

## True while The Collapse is running.
## NETWORK: @rpc replication hook — sync to all peers.
var is_active: bool = false
## Players still alive in the Survival Race.
## NETWORK: @rpc replication hook — sync to all peers.
var surviving_players: Array[int] = []


## Builds the final scoreboard from the persistent ladder (a chain's score
## is its members' combined ScoreManager totals) and runs the tiebreaker.
## Call this once when Round 3 ends.
## NETWORK: @rpc replication hook — server-side, from the results screen.
func resolve_match_end() -> bool:
	var team_scores: Dictionary = {}
	for chain_id: int in VerbChainManager.verb_chains.keys():
		var chain: Dictionary = VerbChainManager.verb_chains[chain_id]
		var score: float = float(ScoreManager.get_total(chain.player_a_id))
		if not chain.is_self_chain:
			score += float(ScoreManager.get_total(chain.player_b_id))
		team_scores[chain_id] = score
	return check_for_tiebreaker(team_scores)


## Checks the final scoreboard for a tie at the top. `team_scores` maps
## chain_id -> final score. EVERY player inside a top-scoring chain counts
## as tied — partners share their chain's score, so a lone winning pair
## still collapses into a one-versus-one Sudden Death. The Collapse fires
## whenever two or more players are tied at the top; only a top-scoring
## Self-Chain (one solo player, nobody level with them) wins outright.
## Only the TOP of the ladder is contested: ties further down (2nd vs 3rd,
## etc.) stand as-is on the final standings and are never sent to Sudden
## Death — The Collapse decides the winner, nothing else.
## NETWORK: @rpc replication hook — server-side, from the results screen.
func check_for_tiebreaker(team_scores: Dictionary) -> bool:
	if team_scores.is_empty():
		return false
	var best_score: float = -INF
	for score: float in team_scores.values():
		best_score = maxf(best_score, score)
	var tied_players: Array[int] = []
	for chain_id: int in team_scores.keys():
		if not is_equal_approx(team_scores[chain_id], best_score):
			continue
		var chain: Dictionary = VerbChainManager.verb_chains.get(chain_id, {})
		if chain.is_empty():
			continue
		if chain.player_a_id not in tied_players:
			tied_players.append(chain.player_a_id)
		if chain.player_b_id not in tied_players:
			tied_players.append(chain.player_b_id)
	if tied_players.size() < 2:
		# A Self-Chained solo player alone at the top: the only path to
		# victory that skips The Collapse.
		if tied_players.size() == 1:
			ultimate_winner_decided.emit(tied_players[0])
		return false
	trigger_sudden_death(tied_players)
	return true


## Starts the Survival Race. Breaks ALL partnerships (the critical rule),
## forces every participant Solo, and arms their Self-Chain overdrive.
## NETWORK: @rpc replication hook — server executes, then broadcasts the
## solo-state assignments to every peer.
func trigger_sudden_death(participant_ids: Array[int]) -> void:
	is_active = true
	surviving_players = participant_ids.duplicate()
	surviving_players.sort()

	# CRITICAL RULE: no partnerships survive into The Collapse.
	VerbChainManager.dissolve_all_chains()

	# Force every participant's body into Solo overdrive. Bodies register
	# in the "players" group (see Player.tscn).
	for body: Node in get_tree().get_nodes_in_group("players"):
		var peer_id: int = body.get_multiplayer_authority()
		if peer_id not in surviving_players:
			continue
		body.enter_solo_state(get_overdrive_multiplier(body.assigned_verb))

	sudden_death_triggered.emit(surviving_players.duplicate())


## Overdrive multiplier for a verb (e.g. ROLL -> 1.8, its exponential
## momentum stacking profile).
func get_overdrive_multiplier(verb: Enums.VerbType) -> float:
	return OVERDRIVE_PROFILES.get(verb, {"multiplier": 1.0}).multiplier


## HUD flavor line for a verb's overdrive.
func get_overdrive_effect(verb: Enums.VerbType) -> String:
	return OVERDRIVE_PROFILES.get(verb, {"effect": ""}).effect


## Template hazard callback: connect Survival Race hazard Area3D
## body_entered signals here (kill floors, crushers, the collapsing edge).
## Eliminates the fallen player; the last blob standing wins outright.
## NETWORK: @rpc replication hook — hazards overlap on the server only;
## the resulting elimination is broadcast.
func _on_player_fall_into_hazard(body: Node3D) -> void:
	if not is_active or not body.is_in_group("players"):
		return
	eliminate_player(body.get_multiplayer_authority())


## Removes a player from the race and crowns the winner when one remains.
func eliminate_player(player_id: int) -> void:
	if not is_active or player_id not in surviving_players:
		return
	surviving_players.erase(player_id)
	player_eliminated.emit(player_id, surviving_players.size())

	if surviving_players.size() == 1:
		is_active = false
		ultimate_winner_decided.emit(surviving_players[0])
