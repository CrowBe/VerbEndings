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

## NETWORK: @rpc replication hook — broadcast so every client swaps to the
## Collapse presentation and severs its local chain VFX.
signal collapse_triggered(participant_ids: Array)
## NETWORK: @rpc replication hook — broadcast each Elimination for the feed.
signal player_eliminated(player_id: int, survivors_left: int)
## NETWORK: @rpc replication hook — broadcast the Trial result.
signal ultimate_winner_decided(player_id: int)

## True while The Collapse is running.
## NETWORK: @rpc replication hook — sync to all peers.
var is_active: bool = false
## Subjects not yet Eliminated from the Collapse.
## NETWORK: @rpc replication hook — sync to all peers.
var surviving_players: Array[int] = []


## Resolves First Place from individual Trial Scores after Round Three.
## NETWORK: @rpc replication hook — server-side, from the results screen.
func resolve_trial_end() -> bool:
	if RoundManager.current_round_index < RoundManager.TOTAL_ROUNDS:
		push_warning("CollapseManager: Trial resolution requires three completed Rounds.")
		return false
	return resolve_trial_scores(ScoreManager.player_points)


## The Collapse fires only when two or more Subjects share First Place.
## Ties below First Place do not affect Trial resolution.
## NETWORK: @rpc replication hook — server-side, from the results screen.
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
## NETWORK: @rpc replication hook — server executes, then broadcasts the
## solo-state assignments to every peer.
func trigger_collapse(participant_ids: Array[int]) -> void:
	is_active = true
	surviving_players = participant_ids.duplicate()
	surviving_players.sort()

	# No Pair survives into the Collapse.
	VerbChainManager.dissolve_all_chains()

	# Force every participant's body into Solo Overdrive. Bodies register
	# in the "players" group (see Player.tscn).
	for body: Node in get_tree().get_nodes_in_group("players"):
		var peer_id: int = body.get_multiplayer_authority()
		if peer_id not in surviving_players:
			continue
		body.enter_overdrive()

	collapse_triggered.emit(surviving_players.duplicate())


## Template hazard callback: connect Collapse hazard Area3D body_entered
## signals here (hazard floors, crushers, failing routes).
## Eliminates the fallen Subject; the last Subject standing wins outright.
## NETWORK: @rpc replication hook — hazards overlap on the server only;
## the resulting elimination is broadcast.
func _on_player_fall_into_hazard(body: Node3D) -> void:
	if not is_active or not body.is_in_group("players"):
		return
	eliminate_player(body.get_multiplayer_authority())


## Removes a Subject from the Collapse and crowns the winner when one remains.
func eliminate_player(player_id: int) -> void:
	if not is_active or player_id not in surviving_players:
		return
	surviving_players.erase(player_id)
	player_eliminated.emit(player_id, surviving_players.size())

	if surviving_players.size() == 1:
		is_active = false
		ultimate_winner_decided.emit(surviving_players[0])
		for body: Node in get_tree().get_nodes_in_group("players"):
			body.exit_overdrive()
