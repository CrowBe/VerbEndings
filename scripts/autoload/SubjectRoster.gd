extends Node
## SubjectRoster (autoload singleton)
##
## The single binding between a Subject id and its live body. Domain services
## ask this module for Subjects instead of walking the scene tree, so the
## physical binding — Subject bodies joining the "players" group — stays in
## one place and Overdrive has one owner.
##
## NETWORK: this module holds no authoritative state. It resolves bodies and
## applies already-decided outcomes to them.

const SUBJECT_GROUP: StringName = &"players"

var _body_cache: Dictionary = {}


## Every live Subject body, in scene-tree order.
func bodies() -> Array[Node]:
	var live: Array[Node] = []
	for body: Node in get_tree().get_nodes_in_group(SUBJECT_GROUP):
		if is_instance_valid(body):
			live.append(body)
	return live


## Subject ids for every live body.
func ids() -> Array[int]:
	var subject_ids: Array[int] = []
	for body: Node in bodies():
		subject_ids.append(body.get_multiplayer_authority())
	return subject_ids


## The live body owning this Subject id, or null when it has no body. Bodies
## are cached by id and revalidated on every lookup.
func body_of(player_id: int) -> Node:
	var cached: Node = _body_cache.get(player_id)
	if is_instance_valid(cached) and cached.is_inside_tree() \
			and cached.get_multiplayer_authority() == player_id:
		return cached
	_body_cache.erase(player_id)
	for body: Node in get_tree().get_nodes_in_group(SUBJECT_GROUP):
		if is_instance_valid(body) and body.get_multiplayer_authority() == player_id:
			_body_cache[player_id] = body
			return body
	return null


func has_subject(player_id: int) -> bool:
	return body_of(player_id) != null


## --- Chain state --------------------------------------------------------
##
## Overdrive belongs to this module. A Subject enters it by being Self-Chained
## or by surviving into the Collapse, and never by any other route.

## Self-Chain: the Subject is its own Partner and gains Overdrive.
func set_self_chained(player_id: int) -> bool:
	var body: Node = body_of(player_id)
	if body == null:
		return false
	body.enter_overdrive(player_id)
	return true


## Normal Pair: the Subject has a Partner and no Overdrive.
func set_partnered(player_id: int, partner_id: int) -> bool:
	var body: Node = body_of(player_id)
	if body == null:
		return false
	body.exit_overdrive(partner_id)
	return true


## No Chain: neither Partner nor Overdrive.
func set_unpaired(player_id: int) -> bool:
	var body: Node = body_of(player_id)
	if body == null:
		return false
	body.exit_overdrive()
	return true


func set_unpaired_all() -> void:
	for body: Node in bodies():
		body.exit_overdrive()


## Collapse: every Pair is dissolved, so the Subject is Solo and in Overdrive.
func set_solo_overdrive(player_id: int) -> bool:
	var body: Node = body_of(player_id)
	if body == null:
		return false
	body.enter_overdrive()
	return true


## --- Stability ----------------------------------------------------------

## Applies the surviving Partner's Severance Loss. Returns whether a body
## took it.
func apply_severance_loss(player_id: int) -> bool:
	var body: Node = body_of(player_id)
	if body == null:
		return false
	body.apply_severance_loss()
	return true


func restabilise(player_id: int) -> bool:
	var body: Node = body_of(player_id)
	if body == null:
		return false
	body.restabilise()
	return true


## Recall restores every Subject to baseline Stability at the end of an
## Experiment, including the Subjects it Eliminated.
func recall_all() -> void:
	for body: Node in bodies():
		if body.has_method("restabilise"):
			body.restabilise()


## Subject ids that are still standing, in roster order.
func stable_ids() -> Array[int]:
	var stable: Array[int] = []
	for body: Node in bodies():
		if not body.get("is_destabilised"):
			stable.append(body.get_multiplayer_authority())
	return stable


func stable_count() -> int:
	return stable_ids().size()


## --- Lifecycle ----------------------------------------------------------

## Removes an Eliminated Subject from play during the Collapse. Elimination
## is permanent there, so the body stops processing and rendering.
func remove_from_play(player_id: int) -> void:
	var body: Node = body_of(player_id)
	if body == null:
		return
	body.process_mode = Node.PROCESS_MODE_DISABLED
	if body is Node3D:
		(body as Node3D).visible = false


## Connects a handler to every Subject's `destabilised` signal, skipping
## bodies already connected. Returns the number of new connections.
func connect_destabilised(handler: Callable) -> int:
	var connected: int = 0
	for body: Node in bodies():
		if not body.has_signal("destabilised"):
			continue
		if body.destabilised.is_connected(handler):
			continue
		body.destabilised.connect(handler)
		connected += 1
	return connected


func disconnect_destabilised(handler: Callable) -> void:
	for body: Node in bodies():
		if body.has_signal("destabilised") \
				and body.destabilised.is_connected(handler):
			body.destabilised.disconnect(handler)
