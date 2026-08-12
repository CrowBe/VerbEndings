class_name TrialPresentation
extends CanvasLayer
## Player-facing menu, lobby, lifecycle presentation, and in-Experiment HUD.
## Domain services remain authoritative; this layer only submits validated
## choices and acknowledges presentation boundaries.

const SCREEN_MAIN_MENU := &"main_menu"
const SCREEN_VERB_SELECTION := &"verb_selection"
const SCREEN_PAIR_DRAFT := &"pair_draft"
const SCREEN_EXPERIMENT_BRIEF := &"experiment_brief"
const SCREEN_HUD := &"hud"
const SCREEN_RESULT := &"result_announcement"
const SCREEN_COMPLETE := &"trial_complete"
const VERB_SELECTION_SECONDS: float = 30.0

var current_screen: StringName = SCREEN_MAIN_MENU
var game: Node = null

var backdrop: ColorRect
var panel: PanelContainer
var content: VBoxContainer
var banner_panel: PanelContainer
var banner_label: Label
var hud_panel: PanelContainer
var phase_label: Label
var objective_label: Label
var stability_label: Label
var cooldown_label: Label
var score_label: Label
var critical_label: Label
var address_edit: LineEdit
var port_spin: SpinBox
var selection_timer_label: Label
var _banner_timer: float = 0.0
var _selection_deadline_msec: int = -1


func _ready() -> void:
	layer = 20
	game = get_parent()
	_build_shell()
	_connect_signals()
	_show_main_menu()


func _process(delta: float) -> void:
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			banner_panel.hide()
	if current_screen == SCREEN_HUD:
		_refresh_hud()
	elif current_screen == SCREEN_VERB_SELECTION and not _all_verbs_selected():
		_refresh_selection_timer()


func _build_shell() -> void:
	backdrop = ColorRect.new()
	backdrop.name = "LifecycleBackdrop"
	backdrop.color = Color(0.025, 0.04, 0.065, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	panel = PanelContainer.new()
	panel.name = "LifecyclePanel"
	panel.custom_minimum_size = Vector2(650.0, 420.0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -325.0
	panel.offset_top = -210.0
	panel.offset_right = 325.0
	panel.offset_bottom = 210.0
	panel.add_theme_stylebox_override("panel", _panel_style(
			Color(0.055, 0.085, 0.13, 0.98), Color(0.22, 0.72, 0.92), 3))
	add_child(panel)
	content = VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	banner_panel = PanelContainer.new()
	banner_panel.name = "RoundBanner"
	banner_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_panel.offset_left = -310.0
	banner_panel.offset_top = 28.0
	banner_panel.offset_right = 310.0
	banner_panel.custom_minimum_size = Vector2(620.0, 0.0)
	banner_panel.add_theme_stylebox_override("panel", _panel_style(
			Color(0.03, 0.05, 0.09, 0.96), Color(0.31, 0.83, 0.98), 2))
	add_child(banner_panel)
	banner_label = Label.new()
	banner_label.name = "BannerText"
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_label.add_theme_font_size_override("font_size", 22)
	banner_label.add_theme_color_override("font_color", Color(0.84, 0.96, 1.0))
	banner_panel.add_child(banner_label)
	banner_panel.hide()

	hud_panel = PanelContainer.new()
	hud_panel.name = "ExperimentHUD"
	hud_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_panel.offset_left = 18.0
	hud_panel.offset_top = 18.0
	hud_panel.offset_right = -18.0
	hud_panel.custom_minimum_size.y = 118.0
	hud_panel.add_theme_stylebox_override("panel", _panel_style(
			Color(0.025, 0.045, 0.075, 0.90), Color(0.18, 0.54, 0.75), 2))
	add_child(hud_panel)
	var hud := VBoxContainer.new()
	hud.add_theme_constant_override("separation", 6)
	hud_panel.add_child(hud)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 22)
	hud.add_child(top_row)
	phase_label = _hud_label("Phase", 20)
	stability_label = _hud_label("Stability", 20)
	cooldown_label = _hud_label("Verb Expression", 20)
	score_label = _hud_label("Round Score", 20)
	for label: Label in [phase_label, stability_label, cooldown_label, score_label]:
		top_row.add_child(label)
	critical_label = _hud_label("◆ CRITICAL STABILITY ◆", 18)
	critical_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	critical_label.add_theme_color_override("font_outline_color", Color(0.4, 0.02, 0.02))
	critical_label.add_theme_constant_override("outline_size", 6)
	critical_label.hide()
	hud.add_child(critical_label)
	objective_label = _hud_label("Objective", 17)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(objective_label)
	hud_panel.hide()


func _connect_signals() -> void:
	TrialCoordinator.phase_changed.connect(_on_phase_changed)
	TrialCoordinator.round_result_announced.connect(_on_round_result_announced)
	TrialCoordinator.trial_completed.connect(_on_trial_completed)
	RoundManager.round_banner_requested.connect(_on_banner_requested)
	LobbyManager.verb_selection_opened.connect(_on_verb_selection_opened)
	LobbyManager.verb_selected.connect(_on_verb_selected)
	LobbyManager.draft_started.connect(_on_draft_started)
	LobbyManager.draft_turn_started.connect(_on_draft_turn_started)
	LobbyManager.pair_locked.connect(_on_pair_locked)
	NetworkSession.authoritative_state_received.connect(_on_authoritative_state)
	NetworkSession.session_joined.connect(func(_peer_id: int) -> void:
		_show_status("Connected. Waiting for the host roster."))
	NetworkSession.session_closed.connect(_on_session_closed)


func _show_main_menu() -> void:
	current_screen = SCREEN_MAIN_MENU
	_show_lifecycle_panel()
	_clear_content()
	_add_heading("ULTIMATE LEXICAL TRIAL PROGRAMME",
			"Form a Verb Chain. Survive three Experiments. Keep your form.")
	var local_button := _add_button("LOCAL TRIAL", func() -> void:
		game.open_local_lobby())
	local_button.tooltip_text = "Start the configured local roster and choose unique Verbs."
	var network_title := Label.new()
	network_title.text = "HOST OR JOIN"
	network_title.add_theme_font_size_override("font_size", 18)
	network_title.add_theme_color_override("font_color", Color(0.45, 0.82, 0.96))
	content.add_child(network_title)
	var connection_row := HBoxContainer.new()
	connection_row.add_theme_constant_override("separation", 10)
	content.add_child(connection_row)
	address_edit = LineEdit.new()
	address_edit.name = "HostAddress"
	address_edit.placeholder_text = "Host address"
	address_edit.text = "127.0.0.1"
	address_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	connection_row.add_child(address_edit)
	port_spin = SpinBox.new()
	port_spin.name = "SessionPort"
	port_spin.min_value = 1024
	port_spin.max_value = 65535
	port_spin.value = NetworkSession.DEFAULT_PORT
	connection_row.add_child(port_spin)
	_add_button("HOST SESSION", _host_session)
	_add_button("JOIN SESSION", _join_session)
	_add_body("WASD move • Space jumps or Releases during a Drop • "
			+ "Left mouse creates an Impact • Right mouse Expresses your Verb • Esc releases the mouse")


func _host_session() -> void:
	var error: Error = game.host_session(int(port_spin.value),
			NetworkSession.DEFAULT_MAX_CLIENTS, game.local_playtest_config.trial_seed)
	if error != OK:
		_show_status("Unable to host session (error %d)." % error)
		return
	_show_verb_selection()


func _join_session() -> void:
	var error: Error = game.join_session(address_edit.text.strip_edges(),
			int(port_spin.value))
	if error != OK:
		_show_status("Unable to join session (error %d)." % error)
		return
	_show_status("Connecting to %s:%d…" % [address_edit.text, int(port_spin.value)])


func _show_verb_selection() -> void:
	current_screen = SCREEN_VERB_SELECTION
	if _selection_deadline_msec < 0 \
			and NetworkSession.mode == NetworkSession.Mode.CLIENT:
		_selection_deadline_msec = Time.get_ticks_msec() \
				+ roundi(VERB_SELECTION_SECONDS * 1000.0)
	_show_lifecycle_panel()
	_clear_content()
	var subject_id := _selection_subject_id()
	if subject_id == -1:
		_add_heading("VERB SELECTION", "Waiting for the roster…")
		return
	if _all_verbs_selected():
		_add_heading("VERB SELECTION COMPLETE", _roster_summary())
		if NetworkSession.mode == NetworkSession.Mode.LOCAL:
			if TrialCoordinator.current_phase == TrialCoordinator.Phase.IDLE \
					and not game.start_interactive_local_trial():
				_add_body("The Trial cannot start until every Subject has a unique Verb.")
			elif TrialCoordinator.current_phase != TrialCoordinator.Phase.IDLE:
				_add_body("The Semantic Engine is preparing the Pair Draft.")
		elif NetworkSession.is_host():
			_add_button("START TRIAL", func() -> void: game.start_hosted_trial())
		else:
			_add_body("Waiting for the host to start the Trial.")
		return
	_add_heading("VERB SELECTION",
			"Subject %d — claim one unique Verb" % subject_id)
	_add_body("Every Subject keeps this Verb for the complete three-Round Trial.")
	selection_timer_label = _add_body("")
	_refresh_selection_timer()
	var grid := GridContainer.new()
	grid.name = "VerbChoices"
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	var claimed: Array = VerbChainManager.active_players.values()
	for verb: Enums.VerbType in Enums.VerbType.values():
		if verb == Enums.VerbType.NONE or verb in claimed:
			continue
		var choice := Button.new()
		choice.text = Enums.verb_name(verb).to_upper()
		choice.custom_minimum_size = Vector2(0.0, 52.0)
		choice.pressed.connect(func() -> void: choose_verb(verb))
		grid.add_child(choice)
	_add_body("Available Verbs update immediately when another Subject claims one.")


func choose_verb(verb: Enums.VerbType) -> bool:
	var subject_id := _selection_subject_id()
	if subject_id == -1:
		return false
	if NetworkSession.mode == NetworkSession.Mode.LOCAL:
		return game.select_local_lobby_verb(subject_id, verb)
	NetworkSession.request_verb(verb)
	return true


func _on_verb_selection_opened() -> void:
	_selection_deadline_msec = Time.get_ticks_msec() \
			+ roundi(VERB_SELECTION_SECONDS * 1000.0)
	_show_verb_selection()


func _refresh_selection_timer() -> void:
	if selection_timer_label == null or not is_instance_valid(selection_timer_label):
		return
	if _selection_deadline_msec < 0:
		selection_timer_label.text = "Selection clock synchronising…"
		return
	var remaining := maxf((_selection_deadline_msec - Time.get_ticks_msec()) / 1000.0, 0.0)
	selection_timer_label.text = "SELECTION CLOSES IN %02d SECONDS" % ceili(remaining)
	if is_zero_approx(remaining) and NetworkSession.mode != NetworkSession.Mode.CLIENT:
		_selection_deadline_msec = -1
		game.complete_timed_verb_selection()


func _show_pair_draft() -> void:
	current_screen = SCREEN_PAIR_DRAFT
	_show_lifecycle_panel()
	_clear_content()
	var chooser_id: int = LobbyManager.current_chooser_id
	_add_heading("PAIR DRAFT — ROUND %d" % (RoundManager.current_round_index + 1),
			_draft_order_explanation())
	if chooser_id == -1:
		_add_body("The Semantic Engine is assigning the Dispensing Line.")
		return
	var local_can_choose := NetworkSession.mode == NetworkSession.Mode.LOCAL \
			or chooser_id == multiplayer.get_unique_id()
	_add_body("Subject %d chooses a Partner.%s" % [chooser_id,
			"" if local_can_choose else " Waiting for their choice."])
	if not local_can_choose:
		return
	var choices_scroll := ScrollContainer.new()
	choices_scroll.name = "PartnerChoicesScroll"
	choices_scroll.custom_minimum_size.y = 230.0
	choices_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choices_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(choices_scroll)
	var choices := VBoxContainer.new()
	choices.name = "PartnerChoices"
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation", 8)
	choices_scroll.add_child(choices)
	for target_id: int in LobbyManager.lobby_players:
		if target_id == chooser_id or VerbChainManager.get_partner_id(target_id) != -1:
			continue
		var verb: Enums.VerbType = VerbChainManager.active_players.get(
				target_id, Enums.VerbType.NONE)
		var choice := Button.new()
		choice.text = "SUBJECT %d — %s" % [target_id,
				Enums.verb_name(verb).to_upper()]
		choice.custom_minimum_size.y = 48.0
		choice.pressed.connect(func() -> void: choose_partner(target_id))
		choices.add_child(choice)


func choose_partner(target_id: int) -> bool:
	var chooser_id: int = LobbyManager.current_chooser_id
	if chooser_id == -1:
		return false
	if NetworkSession.mode == NetworkSession.Mode.LOCAL:
		return LobbyManager.request_pairing(chooser_id, target_id)
	NetworkSession.request_pairing(target_id)
	return true


func _show_experiment_brief(protocol: ExperimentProtocol) -> void:
	current_screen = SCREEN_EXPERIMENT_BRIEF
	_show_lifecycle_panel()
	_clear_content()
	if protocol == null:
		_add_heading("EXPERIMENT BRIEF", "Awaiting Protocol details…")
		return
	_add_heading("EXPERIMENT BRIEF — ROUND %d" % RoundManager.current_round_index,
			protocol.display_name.to_upper())
	_add_body("VERB CHAINS\n%s" % _verb_chain_summary())
	_add_body("OBJECTIVE\n%s" % protocol.objective)
	_add_body("CONDITIONS\n%s" % protocol.completion_condition)
	if not protocol.hazards.is_empty():
		_add_body("HAZARDS\n• %s" % "\n• ".join(protocol.hazards))
	if NetworkSession.mode != NetworkSession.Mode.CLIENT:
		_add_button("ENTER LABORATORY", func() -> void:
			TrialCoordinator.complete_experiment_brief())
	else:
		_add_body("Waiting for the host to continue.")


func _show_result(round_index: int, ranking: Array) -> void:
	current_screen = SCREEN_RESULT
	_show_lifecycle_panel()
	_clear_content()
	_add_heading("RESULT ANNOUNCEMENT — ROUND %d" % round_index,
			"Individual Round Scores and Trial Ranking")
	for entry: Dictionary in ranking:
		var player_id: int = entry.player_id
		_add_body("%d. SUBJECT %d   ROUND SCORE %d   TRIAL SCORE %d" % [
				entry.rank, player_id,
				ScoreManager.get_round_score(round_index, player_id),
				entry.trial_score])
	if NetworkSession.mode != NetworkSession.Mode.CLIENT:
		_add_button("CONTINUE", func() -> void:
			TrialCoordinator.complete_result_announcement())
	else:
		_add_body("Waiting for the host to continue.")


func _show_complete(winner_id: int) -> void:
	current_screen = SCREEN_COMPLETE
	_show_lifecycle_panel()
	_clear_content()
	_add_heading("TRIAL COMPLETE", "SUBJECT %d IS THE TRIAL WINNER" % winner_id)
	_add_body(_ranking_text(ScoreManager.get_trial_ranking()))
	_add_button("MAIN MENU", func() -> void:
		game.return_to_main_menu()
		_show_main_menu())


func _on_phase_changed(phase: TrialCoordinator.Phase, _round_index: int,
		protocol: ExperimentProtocol) -> void:
	match phase:
		TrialCoordinator.Phase.VERB_SELECTION:
			_show_verb_selection()
		TrialCoordinator.Phase.PAIR_DRAFT:
			_show_pair_draft()
		TrialCoordinator.Phase.EXPERIMENT_BRIEF:
			_show_experiment_brief(protocol)
		TrialCoordinator.Phase.LABORATORY_ENTRY:
			_hide_lifecycle_panel()
			_on_banner_requested("LABORATORY ENTRY\nSPACE TO RELEASE • WASD TO STEER THE DROP")
		TrialCoordinator.Phase.EXPERIMENT:
			current_screen = SCREEN_HUD
			_hide_lifecycle_panel()
			hud_panel.show()
		TrialCoordinator.Phase.RECALL:
			_hide_lifecycle_panel()
			_on_banner_requested("RECALL\nRETURNING SUBJECTS TO THE ASSIGNMENT DECK")
		TrialCoordinator.Phase.RESULT_ANNOUNCEMENT:
			_show_result(RoundManager.current_round_index,
					ScoreManager.get_trial_ranking())
		TrialCoordinator.Phase.COLLAPSE:
			current_screen = SCREEN_HUD
			_hide_lifecycle_panel()
			hud_panel.show()
			_on_banner_requested("SURVIVE\nALL SURVIVING SUBJECTS ARE IN OVERDRIVE")
		TrialCoordinator.Phase.COMPLETE:
			_show_complete(TrialCoordinator.get_winner_id())


func _on_round_result_announced(round_index: int, _ordered_ids: Array,
		ranking: Array) -> void:
	_show_result(round_index, ranking)


func _on_trial_completed(winner_id: int) -> void:
	_show_complete(winner_id)


func _on_banner_requested(text: String) -> void:
	banner_label.text = text
	banner_panel.show()
	_banner_timer = 4.0


func _on_verb_selected(_player_id: int, _verb: Enums.VerbType,
		_seconds_taken: float) -> void:
	if current_screen == SCREEN_VERB_SELECTION:
		call_deferred("_refresh_verb_selection_if_active")


func _on_draft_started(_round_index: int, _draft_order: Array) -> void:
	call_deferred("_refresh_pair_draft_if_active")


func _on_draft_turn_started(_chooser_id: int) -> void:
	call_deferred("_refresh_pair_draft_if_active")


func _on_pair_locked(_chooser_id: int, _target_id: int, _chain: Dictionary) -> void:
	call_deferred("_refresh_pair_draft_if_active")


func _refresh_verb_selection_if_active() -> void:
	if TrialCoordinator.current_phase == TrialCoordinator.Phase.IDLE \
			or TrialCoordinator.current_phase == TrialCoordinator.Phase.VERB_SELECTION:
		_show_verb_selection()


func _refresh_pair_draft_if_active() -> void:
	if TrialCoordinator.current_phase == TrialCoordinator.Phase.PAIR_DRAFT:
		_show_pair_draft()


func _on_authoritative_state(_snapshot: Dictionary) -> void:
	if TrialCoordinator.current_phase == TrialCoordinator.Phase.IDLE \
			and NetworkSession.mode == NetworkSession.Mode.CLIENT:
		_show_verb_selection()
	elif TrialCoordinator.current_phase == TrialCoordinator.Phase.PAIR_DRAFT:
		_show_pair_draft()


func _on_session_closed() -> void:
	if current_screen != SCREEN_MAIN_MENU and TrialCoordinator.current_phase \
			== TrialCoordinator.Phase.IDLE:
		_show_main_menu()


func _refresh_hud() -> void:
	var subject: Node = game.local_player
	var protocol: ExperimentProtocol = RoundManager.current_protocol
	phase_label.text = "ROUND %d • %s" % [RoundManager.current_round_index,
			TrialCoordinator.phase_name().to_upper()]
	var objective: String = protocol.objective \
			if protocol != null else "Survive the Collapse."
	var remaining_seconds := ceili(TrialCoordinator.experiment_seconds_remaining)
	objective_label.text = "OBJECTIVE: %s   •   TIME REMAINING %02d:%02d" % [
			objective, floori(remaining_seconds / 60.0), remaining_seconds % 60]
	if subject == null:
		stability_label.text = "STABILITY —"
		cooldown_label.text = "VERB EXPRESSION —"
		score_label.text = "ROUND SCORE —"
		critical_label.hide()
		return
	var player_id: int = subject.get_multiplayer_authority()
	stability_label.text = "STABILITY %d / %d" % [roundi(subject.stability),
			roundi(subject.BASELINE_STABILITY)]
	var remaining: float = subject.get_verb_cooldown_remaining()
	cooldown_label.text = "VERB EXPRESSION %s" % (
			"READY" if remaining <= 0.0 else "%.1fs" % remaining)
	score_label.text = "ROUND SCORE %d" % ScoreManager.get_round_score(
			RoundManager.current_round_index, player_id)
	critical_label.visible = subject.stability >= 1.0 \
			and subject.stability <= subject.CRITICAL_STABILITY_MAX
	if critical_label.visible:
		critical_label.modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() / 120.0)


func presentation_snapshot() -> Dictionary:
	return {
		"screen": current_screen,
		"lifecycle_text": _control_text(content),
		"banner_text": banner_label.text,
		"hud_text": _control_text(hud_panel),
		"critical_cue_visible": critical_label.is_visible_in_tree(),
		"critical_cue_text": critical_label.text,
	}


func _selection_subject_id() -> int:
	if NetworkSession.mode == NetworkSession.Mode.LOCAL:
		for player_id: int in LobbyManager.lobby_players:
			if VerbChainManager.active_players.get(player_id, Enums.VerbType.NONE) \
					== Enums.VerbType.NONE:
				return player_id
		return LobbyManager.lobby_players[0] if not LobbyManager.lobby_players.is_empty() else -1
	var own_id: int = multiplayer.get_unique_id()
	return own_id if own_id in LobbyManager.lobby_players else -1


func _all_verbs_selected() -> bool:
	if LobbyManager.lobby_players.is_empty():
		return false
	for player_id: int in LobbyManager.lobby_players:
		if VerbChainManager.active_players.get(player_id, Enums.VerbType.NONE) \
				== Enums.VerbType.NONE:
			return false
	return true


func _draft_order_explanation() -> String:
	if RoundManager.current_round_index == 0:
		return "Slowest Verb claim chooses first. Each Subject belongs to one Verb Chain."
	return "Lowest Trial Score chooses first. Every Round creates new Pairs."


func _roster_summary() -> String:
	var lines: Array[String] = []
	for player_id: int in LobbyManager.lobby_players:
		lines.append("Subject %d — %s" % [player_id, Enums.verb_name(
				VerbChainManager.active_players.get(player_id, Enums.VerbType.NONE)).to_upper()])
	return "\n".join(lines)


func _ranking_text(ranking: Array) -> String:
	var lines: Array[String] = []
	for entry: Dictionary in ranking:
		lines.append("%d. Subject %d — %d Trial Score" % [
				entry.rank, entry.player_id, entry.trial_score])
	return "\n".join(lines)


func _verb_chain_summary() -> String:
	var lines: Array[String] = []
	var chain_ids: Array = VerbChainManager.verb_chains.keys()
	chain_ids.sort()
	for chain_id: int in chain_ids:
		var chain: Dictionary = VerbChainManager.verb_chains[chain_id]
		if chain.is_self_chain:
			lines.append("Subject %d forms a Self-Chain — Overdrive active" \
					% chain.player_a_id)
		else:
			lines.append("Subject %d + Subject %d" % [
					chain.player_a_id, chain.player_b_id])
	return "\n".join(lines) if not lines.is_empty() else "Assignment pending"


func _show_status(message: String) -> void:
	_show_lifecycle_panel()
	_clear_content()
	_add_heading("SESSION", message)
	_add_button("MAIN MENU", _show_main_menu)


func _show_lifecycle_panel() -> void:
	backdrop.show()
	panel.show()
	hud_panel.hide()
	banner_panel.hide()
	_banner_timer = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _hide_lifecycle_panel() -> void:
	backdrop.hide()
	panel.hide()
	hud_panel.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _clear_content() -> void:
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()


func _add_heading(title: String, subtitle: String) -> void:
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.76, 0.94, 1.0))
	content.add_child(title_label)
	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 17)
	subtitle_label.add_theme_color_override("font_color", Color(0.74, 0.79, 0.84))
	content.add_child(subtitle_label)


func _add_body(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.88, 0.91, 0.94))
	content.add_child(label)
	return label


func _add_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 46.0
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(callback)
	content.add_child(button)
	return button


func _hud_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.88, 0.95, 0.98))
	return label


func _panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(10)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	return style


func _control_text(root: Node) -> String:
	var parts: Array[String] = []
	if root is Label or root is Button:
		parts.append(root.text)
	for child: Node in root.get_children():
		var child_text := _control_text(child)
		if not child_text.is_empty():
			parts.append(child_text)
	return "\n".join(parts)
