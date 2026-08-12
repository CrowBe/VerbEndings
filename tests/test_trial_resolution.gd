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
	ScoreManager.add_points(1, 40, "ENVIRONMENT", "test")
	ScoreManager.add_points(2, 20, "ENVIRONMENT", "test")
	RoundManager.current_round_index = 2
	ScoreManager.add_points(1, 10, "PVE", "test")
	_expect(ScoreManager.get_round_score(1, 1) == 40,
			"Round Score is retained separately")
	_expect(ScoreManager.get_total(1) == 50,
			"Trial Score accumulates across Rounds")
	_expect(ScoreManager.get_trial_ranking()[0].player_id == 1,
			"Trial Ranking orders individual Trial Scores")

	_test_chain_shared_placement()
	_test_self_chain_single_payment()
	_test_eliminated_partner_receives_shared_placement()
	_test_protocol_authored_bonus_sharing()

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


func _test_chain_shared_placement() -> void:
	_reset_scoring_roster({
		1: Enums.VerbType.BURN,
		2: Enums.VerbType.FREEZE,
		3: Enums.VerbType.GROW,
		4: Enums.VerbType.SHIELD,
	})
	VerbChainManager.establish_verb_chain(1, 2)
	VerbChainManager.establish_verb_chain(3, 4)
	var protocol: ExperimentProtocol = load(
			"res://resources/protocols/sustained_exposure.tres")
	ScoreManager.award_protocol_placements(protocol, [1, 3, 2, 4])
	_expect(ScoreManager.get_total(1) == 198 and ScoreManager.get_total(2) == 198,
			"chain-shared placement pays both Partners with authored Synergy")
	_expect(ScoreManager.get_total(3) == 85 and ScoreManager.get_total(4) == 85,
			"placement order contains each Verb Chain exactly once")
	_expect(ScoreManager.get_trial_ranking().size() == 4,
			"shared rewards remain four individual Trial Scores")


func _test_self_chain_single_payment() -> void:
	_reset_scoring_roster({5: Enums.VerbType.GROW})
	VerbChainManager.establish_verb_chain(5, 5)
	var protocol: ExperimentProtocol = load(
			"res://resources/protocols/sustained_exposure.tres")
	ScoreManager.award_protocol_placements(protocol, [5])
	_expect(ScoreManager.get_total(5) == 110,
			"a Self-Chain receives one unscaled placement award")


func _test_eliminated_partner_receives_shared_placement() -> void:
	_reset_scoring_roster({
		6: Enums.VerbType.BURN,
		7: Enums.VerbType.FREEZE,
		8: Enums.VerbType.ROLL,
		9: Enums.VerbType.BOUNCE,
	})
	VerbChainManager.establish_verb_chain(6, 7)
	VerbChainManager.establish_verb_chain(8, 9)
	_expect(VerbChainManager.sever_chain_for(7),
			"an Eliminated Partner Severs its active Verb Chain")
	var protocol: ExperimentProtocol = load(
			"res://resources/protocols/sustained_exposure.tres")
	# Subject 7 was Eliminated, so only its surviving Partner appears in the
	# performance order. The Round's Verb Chain still owns the shared reward.
	ScoreManager.award_protocol_placements(protocol, [6, 8, 9])
	_expect(ScoreManager.get_total(7) == ScoreManager.get_total(6),
			"an Eliminated Partner still receives its Verb Chain's placement")


func _test_protocol_authored_bonus_sharing() -> void:
	_reset_scoring_roster({
		10: Enums.VerbType.BURN,
		11: Enums.VerbType.FREEZE,
	})
	VerbChainManager.establish_verb_chain(10, 11)
	var protocol: ExperimentProtocol = load(
			"res://resources/protocols/adaptive_containment.tres")
	ScoreManager.award_protocol_bonus(10, protocol, "swarm_kill")
	_expect(ScoreManager.get_total(10) == 14 and ScoreManager.get_total(11) == 14,
			"an authored cooperative bonus credits both Partners with Synergy")
	ScoreManager.award_protocol_bonus(10, protocol, "survival_tick")
	_expect(ScoreManager.get_total(10) == 17 and ScoreManager.get_total(11) == 14,
			"a bonus not nominated as cooperative remains Subject-owned")


func _reset_scoring_roster(roster: Dictionary) -> void:
	ScoreManager.reset()
	VerbChainManager.dissolve_all_chains()
	VerbChainManager.active_players = roster
	for player_id: int in roster:
		ScoreManager.register_player(player_id)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
