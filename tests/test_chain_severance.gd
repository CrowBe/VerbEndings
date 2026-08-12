extends Node

const PLAYER_SCENE := preload("res://scenes/Player.tscn")

var _failures: Array[String] = []
var _subjects: Array[Node] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var first := _spawn_subject(1, Enums.VerbType.BURN)
	var second := _spawn_subject(2, Enums.VerbType.SHIELD)
	first.severance_loss = 23.0
	VerbChainManager.establish_verb_chain(1, 2)
	_expect(VerbChainManager.sever_chain_for(2),
			"a Partner's Elimination Severs the active Chain")
	_expect(is_equal_approx(first.stability, 77.0),
			"the survivor pays its configured Severance Loss")
	_expect(VerbChainManager.get_partner_id(1) == -1,
			"the survivor finishes the Experiment without a Partner")
	_expect(not first.is_overdrive,
			"an orphaned Subject receives no Overdrive")
	_expect(not VerbChainManager.sever_chain_for(2)
			and is_equal_approx(first.stability, 77.0),
			"Severance Loss applies once")

	VerbChainManager.establish_verb_chain(1, 2)
	first._set_stability(8.0)
	first.severance_loss = 30.0
	VerbChainManager.sever_chain_for(2)
	_expect(is_equal_approx(first.stability, 1.0) and not first.is_destabilised,
			"Severance Loss floors at 1 Stability without Destabilising")

	var self_chained := _spawn_subject(3, Enums.VerbType.GROW)
	VerbChainManager.establish_verb_chain(3, 3)
	_expect(not VerbChainManager.sever_chain_for(3)
			and is_equal_approx(self_chained.stability, self_chained.BASELINE_STABILITY),
			"a Self-Chain cannot be Severed")

	VerbChainManager.dissolve_all_chains()
	VerbChainManager.establish_verb_chain(1, 2)
	first._set_stability(64.0)
	VerbChainManager.dissolve_all_chains()
	_expect(is_equal_approx(first.stability, 64.0),
			"scheduled dissolution costs no Stability")

	VerbChainManager.establish_verb_chain(1, 2)
	first._set_stability(52.0)
	second._set_stability(61.0)
	CollapseManager.trigger_collapse([1, 2])
	_expect(is_equal_approx(first.stability, 52.0)
			and is_equal_approx(second.stability, 61.0),
			"entering the Collapse costs no Stability")
	_expect(first.is_overdrive and second.is_overdrive,
			"Collapse Overdrive remains independent of Severance")

	CollapseManager.reset()
	VerbChainManager.reset()
	for subject: Node in _subjects:
		subject.queue_free()
	if _failures.is_empty():
		print("Chain Severance tests passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _spawn_subject(player_id: int, verb: Enums.VerbType) -> Node:
	var subject := PLAYER_SCENE.instantiate()
	subject.set_multiplayer_authority(player_id)
	subject.accepts_local_input = false
	get_tree().root.add_child(subject)
	subject.set_character_identity(verb)
	VerbChainManager.register_player(player_id, verb)
	_subjects.append(subject)
	return subject


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
