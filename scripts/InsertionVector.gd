extends Area3D
## Synced Insertion Vector — an elevator platform that launches a chained
## pair into the next round, but only once BOTH partners stand on it
## (a Self-Chained player launches alone).
##
## The platform itself is dumb: it only reports players stepping on and off
## to LobbyManager, which owns the sync rules and fires the launch.
##
## NETWORK: Runs server-side off authoritative player positions. Clients see
## the platform move via replicated transforms, not local overlap events.

## Distinguishes multiple platforms in one lobby.
@export var vector_id: int = 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		LobbyManager.notify_vector_entered(vector_id, body.get_multiplayer_authority())


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("players"):
		LobbyManager.notify_vector_exited(vector_id, body.get_multiplayer_authority())
