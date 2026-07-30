extends Node
## Root scene coordinator for the playable greybox.
##
## Game is the composition root: it owns bootstrap, Round scene loading, and
## temporary local-player spawning until multiplayer spawning is implemented.
## It does not drive the three-Round Trial lifecycle; RoundManager owns
## Protocol selection and Game adopts the selected Protocol only when its
## classification matches the requested Round.

const DEFAULT_PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const ROUND_SCENES: Dictionary = {
	"PVP": preload("res://scenes/rounds/PVPRound.tscn"),
	"PVE": preload("res://scenes/rounds/PVERound.tscn"),
	"PUZZLE": preload("res://scenes/rounds/PuzzleRound.tscn"),
}

@export var auto_start_graybox: bool = true
@export var debug_round_type: String = "PUZZLE"
@export var player_scene: PackedScene = DEFAULT_PLAYER_SCENE

@onready var world_root: Node3D = $World
@onready var players_root: Node3D = $World/Players
@onready var round_root: Node3D = $World/Round

var current_round: Node3D = null
var local_player: Node3D = null


func _ready() -> void:
	if auto_start_graybox:
		start_graybox_match(debug_round_type)


## Starts a local single-player smoke test. The networked version should keep
## this public API but swap spawn_local_player() for MultiplayerSpawner output.
func start_graybox_match(round_type: String) -> void:
	_spawn_local_player()
	load_round(round_type)


func load_round(round_type: String) -> Node3D:
	if current_round != null:
		current_round.queue_free()
		current_round = null
	var round_scene: PackedScene = ROUND_SCENES.get(round_type)
	if round_scene == null:
		push_warning("Game: no scene registered for round type '%s'." % round_type)
		return null
	current_round = round_scene.instantiate() as Node3D
	if current_round == null:
		push_warning("Game: round scene for '%s' must instantiate a Node3D root." % round_type)
		return null
	if RoundManager.current_protocol != null \
			and RoundManager.current_protocol.classification == round_type:
		current_round.set("protocol", RoundManager.current_protocol)
	round_root.add_child(current_round)
	RoundManager.current_round_type = round_type
	return current_round


func _spawn_local_player() -> Node3D:
	if local_player != null:
		return local_player
	local_player = player_scene.instantiate() as Node3D
	if local_player == null:
		push_warning("Game: player_scene must instantiate a Node3D root.")
		return null
	players_root.add_child(local_player)
	local_player.name = "LocalPlayer"
	local_player.global_position = Vector3.ZERO
	return local_player
