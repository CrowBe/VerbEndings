extends Node

const COMPOUND_SCENE: PackedScene = preload(
		"res://scenes/environment/Compound.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")


func _ready() -> void:
	var failures: Array[String] = []
	_prepare_roster(5)
	_test_tube_assignments(failures)
	await _test_physical_transit(failures)
	if failures.is_empty():
		print("Laboratory Entry, Drop, and Recall tests passed.")
		get_tree().quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	get_tree().quit(1)


func _prepare_roster(subject_count: int) -> void:
	LobbyManager.reset()
	VerbChainManager.reset()
	ScoreManager.reset()
	for index: int in subject_count:
		var subject_id: int = index + 1
		LobbyManager.join_lobby(subject_id)
		ScoreManager.register_player(subject_id)
	LobbyManager.open_verb_selection()
	for index: int in subject_count:
		LobbyManager.select_verb_for_local_playtest(
				index + 1, Enums.VerbType.values()[index + 1])
	LobbyManager.begin_round_one_draft()
	LobbyManager.complete_draft_automatically()


func _test_tube_assignments(failures: Array[String]) -> void:
	_expect(LobbyManager.dispensing_line_tubes.size() == 5,
			"every drafted Subject must receive exactly one tube", failures)
	var used_tubes: Dictionary = {}
	for subject_id: int in LobbyManager.lobby_players:
		var tube_index: int = LobbyManager.get_dispensing_line_tube(subject_id)
		_expect(tube_index >= 0 and tube_index < Compound.SUBJECT_CAPACITY,
				"tube assignments must stay within the Compound capacity", failures)
		used_tubes[tube_index] = true
		var partner_id: int = VerbChainManager.get_partner_id(subject_id)
		if partner_id != subject_id:
			_expect(abs(tube_index \
					- LobbyManager.get_dispensing_line_tube(partner_id)) == 1,
					"Partners must receive adjacent Dispensing Line tubes", failures)
	_expect(used_tubes.size() == 5,
			"tube assignment must never duplicate a Subject slot", failures)


func _test_physical_transit(failures: Array[String]) -> void:
	var compound := COMPOUND_SCENE.instantiate() as Compound
	add_child(compound)
	var subjects: Array[Node3D] = []
	for subject_id: int in [1, 2]:
		var subject := PLAYER_SCENE.instantiate() as Node3D
		subject.name = "TransitSubject%d" % subject_id
		subject.set_multiplayer_authority(subject_id)
		subject.set("accepts_local_input", false)
		add_child(subject)
		subjects.append(subject)
	var transit := LaboratoryTransit.new()
	add_child(transit)
	var entry_finished: Array[bool] = [false]
	var recall_finished: Array[bool] = [false]
	transit.entry_completed.connect(func() -> void: entry_finished[0] = true)
	transit.recall_completed.connect(func() -> void: recall_finished[0] = true)
	_expect(transit.begin_entry(compound, &"AppliedAttrition", subjects),
			"Laboratory Entry must accept assigned Subjects", failures)
	for subject: Node3D in subjects:
		var tube_index: int = LobbyManager.get_dispensing_line_tube(
				subject.get_multiplayer_authority())
		_expect(subject.global_transform.is_equal_approx(
				compound.get_drop_socket_transform(&"AppliedAttrition", tube_index)),
				"the internal tube cut must finish at the assigned Drop socket",
				failures)
		_expect(not subject.is_physics_processing(),
				"a Subject must be held until its own Release", failures)
	_expect(transit.request_release(1),
			"the first Subject can Release independently", failures)
	_expect(subjects[0].is_physics_processing() \
			and not subjects[1].is_physics_processing(),
			"one Partner's Release must not release the other", failures)
	var laboratory: Node3D = compound.get_laboratory(&"AppliedAttrition")
	subjects[0].global_position = laboratory.to_global(Vector3(0.0, 1.0, 0.0))
	transit.call("_physics_process", 0.1)
	_expect(not entry_finished[0],
			"Laboratory Entry must wait for every Subject to Land", failures)
	_expect(transit.request_release(2),
			"the second Partner retains an independent Release", failures)
	subjects[1].global_position = laboratory.to_global(Vector3(2.0, 1.0, 0.0))
	transit.call("_physics_process", 0.1)
	_expect(entry_finished[0],
			"Landing every Subject must complete Laboratory Entry", failures)

	_expect(transit.begin_recall(compound, &"AppliedAttrition", subjects),
			"Recall must accept the Experiment roster", failures)
	for subject: Node3D in subjects:
		var tube_index: int = LobbyManager.get_dispensing_line_tube(
				subject.get_multiplayer_authority())
		_expect(subject.global_transform.is_equal_approx(
				compound.get_recall_aperture_transform(
						&"AppliedAttrition", tube_index)),
				"Recall must begin at the Subject's floor aperture", failures)
	transit.call("_physics_process", LaboratoryTransit.RECALL_DURATION)
	_expect(recall_finished[0],
			"reversed pressure must complete Recall", failures)
	for subject: Node3D in subjects:
		var tube_index: int = LobbyManager.get_dispensing_line_tube(
				subject.get_multiplayer_authority())
		_expect(subject.global_transform.is_equal_approx(
				compound.get_dispensing_line_tube_transform(tube_index)),
				"Recall must return every Subject to the Assignment Deck tube",
				failures)
	transit.queue_free()
	for subject: Node3D in subjects:
		subject.queue_free()
	compound.queue_free()
	await get_tree().process_frame


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
