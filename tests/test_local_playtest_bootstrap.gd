extends Node

const GAME_SCENE: PackedScene = preload("res://scenes/core/Game.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = GAME_SCENE.instantiate()
	game.auto_start_greybox = false
	var config := LocalPlaytestConfig.new()
	config.protocol_classification = "PVE"
	config.trial_seed = 7319
	config.subject_count = 3
	config.initial_verbs = [
		Enums.VerbType.BURN,
		Enums.VerbType.BURN,
		Enums.VerbType.GROW,
	]
	game.local_playtest_config = config
	add_child(game)
	game.start_local_playtest()

	_expect(game.active_seed == 7319, "the configured Trial seed is active")
	_expect(RoundManager.current_round_type == "PVE", "the configured Protocol starts")
	_expect(LobbyManager.lobby_players == [1, 2, 3], "all Subjects use the lobby roster")
	_expect(game.local_subjects.size() == 3, "the configured Subject count spawns")
	_expect(VerbChainManager.active_players.size() == 3, "all Subjects reach Verb services")
	_expect(ScoreManager.player_points.keys() == [1, 2, 3],
			"all Subjects reach the scoring service under the same identities")
	_expect(VerbChainManager.active_players[1] == Enums.VerbType.BURN,
			"the first configured Verb is retained")
	_expect(VerbChainManager.active_players[2] == Enums.VerbType.SHIELD,
			"a duplicate configured Verb receives the deterministic fallback")
	_expect(VerbChainManager.get_partner_id(1) == 2, "two Subjects form a Pair")
	_expect(not game.local_subjects[0].is_overdrive and not game.local_subjects[1].is_overdrive,
			"a normal Pair retains normal cooldown state")
	_expect(game.local_subjects[0].paired_partner_id == 2 \
			and game.local_subjects[1].paired_partner_id == 1,
			"the Pair shares reciprocal Partner state")
	_expect(VerbChainManager.get_partner_id(3) == 3, "the odd Subject Self-Chains")
	_expect(game.local_subjects[0].accepts_local_input, "one Subject accepts local input")
	_expect(not game.local_subjects[1].accepts_local_input,
			"additional Subjects remain stationary")
	_expect(game.local_subjects[2].is_overdrive, "the Self-Chain receives Overdrive")

	var first_verbs: Dictionary = VerbChainManager.active_players.duplicate()
	game.restart_local_playtest(false)
	_expect(game.active_seed == 7319, "same-seed restart retains the seed")
	_expect(VerbChainManager.active_players == first_verbs,
			"same-seed restart reproduces Verb assignment")
	_expect(game.local_subjects.size() == 3, "restart retains one active roster")

	game.restart_local_playtest(true)
	_expect(game.active_seed == 7320, "new-seed restart advances the seed")
	_expect(game.local_subjects.size() == 3, "new-seed restart retains one active roster")
	_expect(ScoreManager.player_points == {1: 0, 2: 0, 3: 0},
			"restart resets and re-enrols scoring state")

	game.queue_free()
	if _failures.is_empty():
		print("Local playtest bootstrap tests passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
