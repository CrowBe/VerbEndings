extends Node

const PLAYER_SCENE := preload("res://scenes/Player.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var first := _spawn_player(11, Enums.VerbType.BURN)
	var second := _spawn_player(12, Enums.VerbType.SHIELD)

	VerbChainManager.register_player(11, Enums.VerbType.BURN)
	VerbChainManager.register_player(12, Enums.VerbType.SHIELD)

	VerbChainManager.establish_verb_chain(11, 11)
	_expect(first.is_overdrive, "Self-Chain enables Overdrive")
	_expect(is_equal_approx(
			first.get_verb_cooldown(),
			first.VERB_COOLDOWN * 0.5),
			"Overdrive cooldown is exactly half the baseline")
	_expect(is_equal_approx(first.health, first.MAX_HEALTH),
			"Self-Chain does not change survivability")

	VerbChainManager.establish_verb_chain(11, 12)
	_expect(not first.is_overdrive and not second.is_overdrive,
			"normal Pair restores the baseline state")
	_expect(is_equal_approx(first.get_verb_cooldown(), first.VERB_COOLDOWN),
			"normal Pair restores the baseline cooldown")

	SuddenDeathManager.trigger_sudden_death([11, 12])
	_expect(first.is_overdrive and second.is_overdrive,
			"Collapse enables Overdrive for every survivor")
	_expect(first.paired_partner_id == null and second.paired_partner_id == null,
			"Collapse dissolves Pair membership")

	SuddenDeathManager.eliminate_player(12)
	_expect(not first.is_overdrive and not second.is_overdrive,
			"Collapse resolution clears Overdrive")

	first.queue_free()
	second.queue_free()
	VerbChainManager.active_players.clear()
	VerbChainManager.dissolve_all_chains()
	SuddenDeathManager.surviving_players.clear()

	if _failures.is_empty():
		print("Overdrive tests passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _spawn_player(player_id: int, verb: Enums.VerbType) -> Node:
	var player := PLAYER_SCENE.instantiate()
	player.set_multiplayer_authority(player_id)
	get_tree().root.add_child(player)
	player.set_character_identity(verb)
	return player


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
