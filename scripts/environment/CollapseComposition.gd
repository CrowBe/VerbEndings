class_name CollapseComposition
extends RefCounted
## Composes the Collapse across the persistent Compound.
##
## One mapping from Collapse stage to facility state, used three ways: the
## host applies each stage as CollapseManager announces it, a client applies
## the stage its replicated snapshot has already reached, and tests drive the
## same composition without a composition root.
##
## Every operation is idempotent, so applying a stage twice — or catching up
## to a state whose earlier stages are already composed — is safe.


## Applies one announced stage transition.
static func apply_stage(compound: Compound, stage: CollapseManager.Stage,
		laboratory_id: StringName) -> void:
	if compound == null:
		return
	match stage:
		CollapseManager.Stage.PROTECTED_ORIENTATION:
			_begin(compound)
		CollapseManager.Stage.PERIMETER_ROUTES_OPEN:
			_open_perimeter(compound)
		CollapseManager.Stage.CORE_SHORTCUTS_OPEN:
			compound.open_collapse_core_shortcuts()
		CollapseManager.Stage.FAILURE_TELEGRAPH:
			compound.telegraph_collapse_failure(laboratory_id)
		CollapseManager.Stage.FAILURE_ACTIVE:
			compound.apply_collapse_failure(laboratory_id)


## Composes every stage the Collapse has already reached. Clients call this
## on each replicated snapshot, and the composition root calls it when it
## enters the Collapse phase mid-sequence.
static func apply_current_state(compound: Compound) -> void:
	if compound == null or not CollapseManager.is_active \
			or CollapseManager.entry_assignments.is_empty():
		return
	_begin(compound)
	if CollapseManager.stage >= CollapseManager.Stage.PERIMETER_ROUTES_OPEN:
		_open_perimeter(compound)
	if CollapseManager.stage >= CollapseManager.Stage.CORE_SHORTCUTS_OPEN:
		compound.open_collapse_core_shortcuts()
	# Failures before the next index have already run to completion.
	for failure_index: int in mini(CollapseManager.next_failure_index,
			CollapseManager.failure_order.size()):
		var laboratory_id: StringName = CollapseManager.failure_order[failure_index]
		compound.telegraph_collapse_failure(laboratory_id)
		compound.apply_collapse_failure(laboratory_id)
	if not CollapseManager.telegraphed_laboratory.is_empty():
		compound.telegraph_collapse_failure(CollapseManager.telegraphed_laboratory)


static func _begin(compound: Compound) -> void:
	compound.begin_collapse(CollapseManager.entry_assignments,
			_subject_bodies(), CollapseManager.surviving_players)


static func _open_perimeter(compound: Compound) -> void:
	compound.open_collapse_perimeter_routes(_subject_bodies(),
			CollapseManager.surviving_players)


static func _subject_bodies() -> Array[Node3D]:
	var subjects: Array[Node3D] = []
	for body: Node in SubjectRoster.bodies():
		if body is Node3D:
			subjects.append(body as Node3D)
	return subjects
