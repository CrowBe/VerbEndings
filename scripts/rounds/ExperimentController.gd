class_name ExperimentController
extends Node3D
## Base controller for every Experiment Protocol.
##
## The lifecycle contract TrialCoordinator depends on lives here rather than
## in each Protocol's controller: Subject registration, Chain Severance when a
## Partner is Eliminated, canonical Elimination, placement ordering, and the
## award-then-announce sequence. A subclass supplies its authored Protocol and
## how that Protocol measures a Subject's performance.
##
## Elimination follows GLOSSARY.md: a Destabilised Subject is out of the
## Experiment and stays down. Recall restores every Subject to baseline at the
## end of the Round.
##
## NETWORK: controllers simulate on the authority peer only.

## The Experiment's final placements, best first. TrialCoordinator consumes
## this after the controller has submitted its scores.
signal round_finished(ordered_player_ids: Array)
## A Subject was Destabilised and is out for the rest of this Experiment.
signal subject_eliminated(player_id: int)

@export var protocol: ExperimentProtocol

## player_id -> Subject body, for every Subject registered this Experiment.
var _subjects: Dictionary = {}
var _eliminated: Dictionary = {}
var _finished: bool = false


func _ready() -> void:
	if protocol == null:
		protocol = _default_protocol()
	_configure_from_protocol()
	refresh_subjects()


## --- Contract for subclasses --------------------------------------------

## The authored Protocol resource this controller executes.
func _default_protocol() -> ExperimentProtocol:
	return null


## Reads authored balance values out of the Protocol. Called once, after the
## Protocol is resolved and before any Subject is registered.
func _configure_from_protocol() -> void:
	pass


## Per-Subject setup: measurement slots, signal connections, spawn state.
func _on_subject_registered(_player_id: int, _body: Node) -> void:
	pass


## Protocol-specific consequences of an Elimination — bonus events, Verb
## Assumption, elimination feeds. Runs before Chain Severance so a knockout
## bonus still sees the Chain that is about to end.
func _on_subject_eliminated(_player_id: int, _subject: Node, _source: Node) -> void:
	pass


## How this Protocol measures a Subject. Higher places better.
func get_performance(_player_id: int) -> float:
	return 0.0


## --- Roster -------------------------------------------------------------

## Registers any Subject not yet known to this Experiment. Safe to call every
## tick; Subjects are registered once.
func refresh_subjects() -> void:
	for body: Node in SubjectRoster.bodies():
		var player_id: int = body.get_multiplayer_authority()
		if _subjects.has(player_id):
			continue
		_subjects[player_id] = body
		if body.has_signal("destabilised") \
				and not body.destabilised.is_connected(_on_subject_destabilised):
			body.destabilised.connect(_on_subject_destabilised)
		_on_subject_registered(player_id, body)


## Subjects registered to this Experiment, Eliminated ones included.
func subject_bodies() -> Dictionary:
	return _subjects


func is_eliminated(player_id: int) -> bool:
	return _eliminated.has(player_id)


## --- Elimination --------------------------------------------------------

func _on_subject_destabilised(subject: Node, source: Node) -> void:
	var player_id: int = subject.get_multiplayer_authority()
	if _eliminated.has(player_id):
		return
	_eliminated[player_id] = true
	_on_subject_eliminated(player_id, subject, source)
	# No Pair survives into the Collapse, so there is no Chain left to Sever.
	if not CollapseManager.is_active:
		VerbChainManager.sever_chain_for(player_id)
	subject_eliminated.emit(player_id)
	_report_last_subject_standing()


## Reports the fact; the authored completion mode decides whether it ends the
## Experiment. TrialCoordinator rejects the condition for Protocols that run
## to their timer.
func _report_last_subject_standing() -> void:
	if SubjectRoster.stable_count() <= 1:
		TrialCoordinator.notify_completion_condition("one_eligible_subject")


## --- Resolution ---------------------------------------------------------

## Placements for this Experiment, best first. Exact ties resolve by stable
## Subject id so every peer orders them identically.
func get_ordered_placements() -> Array:
	var ordered: Array = VerbChainManager.active_players.keys()
	if ordered.is_empty():
		ordered.assign(SubjectRoster.ids())
	ordered.sort_custom(func(a: int, b: int) -> bool:
		var performance_a: float = get_performance(a)
		var performance_b: float = get_performance(b)
		if not is_equal_approx(performance_a, performance_b):
			return performance_a > performance_b
		return a < b)
	return ordered


## Submits placements through the Protocol's authored reward policy, then
## announces them. Scores must reach ScoreManager before TrialCoordinator
## reads the Trial Ranking, so this order is the contract and not a detail.
func end_round() -> void:
	if _finished:
		return
	_finished = true
	var ordered: Array = get_ordered_placements()
	ScoreManager.award_protocol_placements(protocol, ordered)
	round_finished.emit(ordered)
