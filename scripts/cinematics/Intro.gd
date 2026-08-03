extends Control
## Temporary generated-video intro. Replace the stream without changing startup flow.

const GAME_SCENE: String = "res://scenes/core/Game.tscn"
const FADE_SECONDS: float = 0.45

@onready var fade: ColorRect = $Fade

var _leaving: bool = false


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		_open_game.call_deferred()
		return
	fade.modulate.a = 1.0
	create_tween().tween_property(fade, "modulate:a", 0.0, FADE_SECONDS)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") \
			or event.is_action_pressed("ui_accept"):
		_finish_intro()


func _on_video_finished() -> void:
	_finish_intro()


func _finish_intro() -> void:
	if _leaving:
		return
	_leaving = true
	$SkipHint.hide()
	var tween: Tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_callback(_open_game)


func _open_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
