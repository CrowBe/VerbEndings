extends Node

const GAME_SCENE: PackedScene = preload("res://scenes/core/Game.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = GAME_SCENE.instantiate()
	var config := LocalPlaytestConfig.new()
	config.trial_seed = 21021
	config.subject_count = 3
	game.local_playtest_config = config
	add_child(game)
	await get_tree().process_frame
	var presentation: TrialPresentation = game.get_node("TrialPresentation")
	var snapshot := presentation.presentation_snapshot()
	_expect(snapshot.screen == TrialPresentation.SCREEN_MAIN_MENU,
			"the runtime opens at the main menu")
	_expect(snapshot.lifecycle_text.contains("LOCAL TRIAL") \
			and snapshot.lifecycle_text.contains("HOST SESSION") \
			and snapshot.lifecycle_text.contains("JOIN SESSION"),
			"the main menu exposes local, host, and join flows")
	_expect(snapshot.diagnostics_strip_text.contains("BUILD mvp-playtest.1") \
			and snapshot.diagnostics_strip_text.contains("SEED 21021"),
			"the non-intrusive diagnostics strip identifies the build and Trial seed")
	presentation.toggle_diagnostics()
	snapshot = presentation.presentation_snapshot()
	_expect(snapshot.diagnostics_visible \
			and snapshot.diagnostics_text.contains("\"build_identifier\"") \
			and snapshot.diagnostics_text.contains("\"trial_seed\": 21021"),
			"F8 diagnostics exposes the copyable privacy-safe session summary")
	presentation._hide_lifecycle_panel()
	_expect(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
			"phase transitions keep the mouse usable while diagnostics remains open")
	presentation.toggle_diagnostics()

	game.open_local_lobby()
	await get_tree().process_frame
	snapshot = presentation.presentation_snapshot()
	_expect(snapshot.screen == TrialPresentation.SCREEN_VERB_SELECTION,
			"the local lobby opens timed Verb Selection")
	_expect(snapshot.lifecycle_text.contains("SELECTION CLOSES IN"),
			"Verb Selection presents its enforced clock")
	_expect(presentation.choose_verb(Enums.VerbType.BURN),
			"Subject 1 can claim a unique Verb")
	_expect(presentation.choose_verb(Enums.VerbType.SHIELD),
			"Subject 2 can claim a different Verb")
	_expect(presentation.choose_verb(Enums.VerbType.GROW),
			"Subject 3 can claim a different Verb")
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(TrialCoordinator.current_phase == TrialCoordinator.Phase.PAIR_DRAFT,
			"completed Verb Selection starts the interactive Pair Draft")
	_expect(LobbyManager.current_chooser_id == 1,
			"the Round One equal-time tie uses stable Subject order")
	_expect(presentation.content.get_node_or_null("PartnerChoicesScroll") \
			is ScrollContainer,
			"dense Partner choices use a viewport-bounded scroll container")
	_expect(presentation.choose_partner(2),
			"the current chooser can form a Pair through the UI seam")
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(VerbChainManager.get_partner_id(3) == 3,
			"the odd Subject receives a presented Self-Chain")
	_expect(TrialCoordinator.current_phase == TrialCoordinator.Phase.EXPERIMENT_BRIEF,
			"the interactive Trial pauses on the Experiment Brief")
	snapshot = presentation.presentation_snapshot()
	_expect(snapshot.lifecycle_text.contains("OBJECTIVE") \
			and snapshot.lifecycle_text.contains("ENTER LABORATORY") \
			and snapshot.lifecycle_text.contains("Self-Chain") \
			and snapshot.lifecycle_text.contains("Overdrive"),
			"the Brief presents authored objectives before Laboratory Entry")
	_expect(not snapshot.lifecycle_text.contains("PVP") \
			and not snapshot.lifecycle_text.contains("PVE") \
			and not snapshot.lifecycle_text.contains("ENVIRONMENT"),
			"development classifications do not reach the Brief")

	RoundManager.current_round_index = 1
	ScoreManager.add_points(1, 25, "ENVIRONMENT", "test")
	game.local_player.stability = 5.0
	game.local_player._verb_timer = 2.4
	presentation._on_phase_changed(TrialCoordinator.Phase.EXPERIMENT, 1,
			RoundManager.current_protocol)
	presentation._refresh_hud()
	snapshot = presentation.presentation_snapshot()
	_expect(snapshot.hud_text.contains("STABILITY 5") \
			and snapshot.hud_text.contains("VERB EXPRESSION 2.4s") \
			and snapshot.hud_text.contains("ROUND SCORE 25") \
			and snapshot.hud_text.contains("TIME REMAINING"),
			"the HUD presents live Stability, Expression cooldown, and individual score")
	_expect(snapshot.critical_cue_visible \
			and snapshot.critical_cue_text.contains("CRITICAL STABILITY") \
			and snapshot.critical_cue_text.contains("◆"),
			"Critical Stability uses text and shape as non-colour cues")

	presentation._show_result(1, ScoreManager.get_trial_ranking())
	await get_tree().process_frame
	snapshot = presentation.presentation_snapshot()
	_expect(snapshot.lifecycle_text.to_upper().contains("TRIAL RANKING") \
			and snapshot.lifecycle_text.contains("ROUND SCORE 25") \
			and snapshot.lifecycle_text.contains("TRIAL SCORE 25"),
			"Result Announcement separates Round Score from Trial Ranking")
	NetworkSession.mode = NetworkSession.Mode.CLIENT
	presentation._on_phase_changed(TrialCoordinator.Phase.RESULT_ANNOUNCEMENT,
			1, RoundManager.current_protocol)
	snapshot = presentation.presentation_snapshot()
	_expect(snapshot.screen == TrialPresentation.SCREEN_RESULT \
			and snapshot.lifecycle_text.contains("Waiting for the host") \
			and not snapshot.lifecycle_text.contains("CONTINUE"),
			"clients receive Result Announcements without advancing host state")
	NetworkSession.mode = NetworkSession.Mode.LOCAL

	var viewport_rect := get_viewport().get_visible_rect()
	var panel_rect := presentation.panel.get_global_rect()
	_expect(panel_rect.position.x >= viewport_rect.position.x \
			and panel_rect.position.y >= viewport_rect.position.y \
			and panel_rect.end.x <= viewport_rect.end.x \
			and panel_rect.end.y <= viewport_rect.end.y,
			"the lifecycle panel remains inside the visible viewport")

	game.queue_free()
	TrialCoordinator.reset()
	LobbyManager.reset()
	VerbChainManager.reset()
	ScoreManager.reset()
	RoundManager.reset()
	if _failures.is_empty():
		print("Trial presentation tests passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
