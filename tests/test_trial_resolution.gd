extends Node

var _failures: Array[String] = []
var _winner_id: int = -1


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	CollapseManager.ultimate_winner_decided.connect(
			func(player_id: int) -> void: _winner_id = player_id)

	_expect(not CollapseManager.resolve_trial_scores({1: 300, 2: 200}),
			"a sole First Place skips the Collapse")
	_expect(_winner_id == 1, "the sole First Place Subject wins the Trial")

	_reset_collapse()
	_expect(CollapseManager.resolve_trial_scores({1: 300, 2: 300, 3: 200}),
			"a two-way First Place tie triggers the Collapse")
	_expect(CollapseManager.surviving_players == [1, 2],
			"only Subjects tied for First Place enter the Collapse")

	_reset_collapse()
	_expect(CollapseManager.resolve_trial_scores({3: 150, 1: 150, 2: 150}),
			"a multi-way First Place tie triggers the Collapse")
	_expect(CollapseManager.surviving_players == [1, 2, 3],
			"Collapse participants are deterministic")

	ScoreManager.reset()
	RoundManager.current_round_index = 1
	ScoreManager.add_points(1, 40, "PUZZLE", "test")
	ScoreManager.add_points(2, 20, "PUZZLE", "test")
	RoundManager.current_round_index = 2
	ScoreManager.add_points(1, 10, "PVE", "test")
	_expect(ScoreManager.get_round_score(1, 1) == 40,
			"Round Score is retained separately")
	_expect(ScoreManager.get_total(1) == 50,
			"Trial Score accumulates across Rounds")
	_expect(ScoreManager.get_trial_ranking()[0].player_id == 1,
			"Trial Ranking orders individual Trial Scores")

	VerbChainManager.active_players = {
		1: Enums.VerbType.BURN,
		2: Enums.VerbType.SHIELD,
		3: Enums.VerbType.GROW,
	}
	VerbChainManager.auto_pair_all_players()
	_expect(VerbChainManager.get_partner_id(3) == 3,
			"an odd roster creates one deterministic Self-Chain")
	VerbChainManager.dissolve_all_chains()

	_reset_collapse()
	ScoreManager.reset()
	VerbChainManager.active_players.clear()
	if _failures.is_empty():
		print("Trial resolution tests passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _reset_collapse() -> void:
	CollapseManager.is_active = false
	CollapseManager.surviving_players.clear()
	_winner_id = -1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
