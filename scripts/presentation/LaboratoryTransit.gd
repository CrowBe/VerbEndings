class_name LaboratoryTransit
extends Node
## Physical presentation controller for Laboratory Entry, Drop, and Recall.
##
## The Compound owns every socket. This controller temporarily owns Subject
## placement and processing: it presents the internal tube journey as a cut,
## waits for independent Release, hands descent back to normal movement for
## steering, and returns each Subject through a floor aperture during Recall.

signal entry_completed
signal recall_completed

const AUTOMATIC_RELEASE_DELAY: float = 3.0
const AUTOMATIC_RELEASE_STAGGER: float = 0.04
const DROP_INITIAL_SPEED: float = 2.5
const LANDING_HEIGHT_M: float = 1.1
const RECALL_DURATION: float = 0.65

enum Mode { IDLE, ENTRY, RECALL }

var mode: Mode = Mode.IDLE
var laboratory_id: StringName = &""
var _compound: Compound = null
var _subjects: Dictionary = {}
var _released: Dictionary = {}
var _landed: Dictionary = {}
var _recall_starts: Dictionary = {}
var _elapsed: float = 0.0


func _ready() -> void:
	set_physics_process(false)
	if not NetworkSession.release_requested.is_connected(request_release):
		NetworkSession.release_requested.connect(request_release)


func _exit_tree() -> void:
	if NetworkSession.release_requested.is_connected(request_release):
		NetworkSession.release_requested.disconnect(request_release)
	_restore_subject_processing()


func begin_entry(
	compound: Compound,
	selected_laboratory_id: StringName,
	subjects: Array[Node3D],
) -> bool:
	if compound == null or subjects.is_empty():
		return false
	_compound = compound
	laboratory_id = selected_laboratory_id
	_subjects.clear()
	_released.clear()
	_landed.clear()
	_elapsed = 0.0
	for subject: Node3D in subjects:
		if not is_instance_valid(subject):
			continue
		var subject_id: int = subject.get_multiplayer_authority()
		var tube_index: int = LobbyManager.get_dispensing_line_tube(subject_id)
		if tube_index < 0:
			continue
		_subjects[subject_id] = subject
		_released[subject_id] = false
		_landed[subject_id] = false
		subject.set_physics_process(false)
		subject.set("velocity", Vector3.ZERO)
		# The opaque internal tube journey is a presentation cut from the
		# Assignment Deck socket to the Laboratory's overhead Drop socket.
		_place_subject(subject, _compound.get_drop_socket_transform(
				laboratory_id, tube_index))
	mode = Mode.ENTRY
	set_physics_process(not _subjects.is_empty())
	return not _subjects.is_empty()


## A Release affects only its owning Subject. Partners may coordinate timing,
## but neither Subject can hold or average the other's steering input.
func request_release(subject_id: int) -> bool:
	if mode != Mode.ENTRY or not _subjects.has(subject_id) \
			or _released.get(subject_id, false):
		return false
	var subject: Node3D = _subjects[subject_id]
	_released[subject_id] = true
	subject.set_physics_process(true)
	subject.set("velocity", Vector3.DOWN * DROP_INITIAL_SPEED)
	return true


func begin_recall(
	compound: Compound,
	selected_laboratory_id: StringName,
	subjects: Array[Node3D],
) -> bool:
	if compound == null or subjects.is_empty():
		return false
	_compound = compound
	laboratory_id = selected_laboratory_id
	_subjects.clear()
	_recall_starts.clear()
	_elapsed = 0.0
	for subject: Node3D in subjects:
		if not is_instance_valid(subject):
			continue
		var subject_id: int = subject.get_multiplayer_authority()
		var tube_index: int = LobbyManager.get_dispensing_line_tube(subject_id)
		if tube_index < 0:
			continue
		_subjects[subject_id] = subject
		subject.set_physics_process(false)
		subject.set("velocity", Vector3.ZERO)
		var aperture: Transform3D = _compound.get_recall_aperture_transform(
				laboratory_id, tube_index)
		_place_subject(subject, aperture)
		_recall_starts[subject_id] = aperture
	mode = Mode.RECALL
	set_physics_process(not _subjects.is_empty())
	return not _subjects.is_empty()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if mode == Mode.ENTRY:
		_process_entry()
	elif mode == Mode.RECALL:
		_process_recall()


func _process_entry() -> void:
	_prune_invalid_subjects()
	if _subjects.is_empty():
		_finish_entry()
		return
	var laboratory: Node3D = _compound.get_laboratory(laboratory_id)
	if laboratory == null:
		return
	var floor_height: float = laboratory.to_global(Vector3.ZERO).y + LANDING_HEIGHT_M
	for subject_id: int in _subjects:
		var tube_index: int = LobbyManager.get_dispensing_line_tube(subject_id)
		if not _released[subject_id] and _elapsed >= \
				AUTOMATIC_RELEASE_DELAY + tube_index * AUTOMATIC_RELEASE_STAGGER:
			request_release(subject_id)
		if not _released[subject_id] or _landed[subject_id]:
			continue
		var subject: Node3D = _subjects[subject_id]
		var local_position: Vector3 = laboratory.to_local(subject.global_position)
		var within_test_floor: bool = absf(local_position.x) <= 25.0 \
				and absf(local_position.z) <= 25.0
		if bool(subject.call("is_on_floor")) \
				or subject.global_position.y <= floor_height and within_test_floor:
			_landed[subject_id] = true
	if not _landed.is_empty() and not false in _landed.values():
		_finish_entry()


func _process_recall() -> void:
	_prune_invalid_subjects()
	if _subjects.is_empty():
		_finish_recall()
		return
	var progress: float = clampf(_elapsed / RECALL_DURATION, 0.0, 1.0)
	var eased: float = smoothstep(0.0, 1.0, progress)
	for subject_id: int in _subjects:
		var subject: Node3D = _subjects[subject_id]
		var tube_index: int = LobbyManager.get_dispensing_line_tube(subject_id)
		var start: Transform3D = _recall_starts[subject_id]
		var tube: Transform3D = _compound.get_dispensing_line_tube_transform(tube_index)
		# Reversed pressure lifts the Subject clear before the internal tube cut.
		var lift_target: Vector3 = start.origin + Vector3.UP * 5.0
		var lifted := subject.global_transform
		lifted.origin = start.origin.lerp(lift_target, eased)
		_place_subject(subject, lifted)
		if progress >= 1.0:
			_place_subject(subject, tube)
			subject.set("velocity", Vector3.ZERO)
			subject.set_physics_process(true)
	if progress >= 1.0:
		_finish_recall()


func _place_subject(subject: Node3D, placement: Transform3D) -> void:
	subject.global_transform = placement
	var camera_rig := subject.get_node_or_null("CameraRig") as Node3D
	if camera_rig != null:
		camera_rig.global_position = placement.origin + Vector3.UP * 1.2


func _prune_invalid_subjects() -> void:
	for subject_id: int in _subjects.keys():
		if is_instance_valid(_subjects[subject_id]):
			continue
		_subjects.erase(subject_id)
		_released.erase(subject_id)
		_landed.erase(subject_id)
		_recall_starts.erase(subject_id)


func _finish_entry() -> void:
	mode = Mode.IDLE
	set_physics_process(false)
	entry_completed.emit()


func _finish_recall() -> void:
	mode = Mode.IDLE
	set_physics_process(false)
	recall_completed.emit()


func _restore_subject_processing() -> void:
	for subject: Node3D in _subjects.values():
		if is_instance_valid(subject):
			subject.set_physics_process(true)


func cancel() -> void:
	_restore_subject_processing()
	_subjects.clear()
	_released.clear()
	_landed.clear()
	_recall_starts.clear()
	mode = Mode.IDLE
	set_physics_process(false)
