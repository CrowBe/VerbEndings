class_name ExperimentProtocol
extends Resource
## Authored rules selected by the Semantic Engine for one Experiment.

@export var protocol_id: StringName
@export var display_name: String
@export_multiline var objective: String
@export var hazards: Array[String] = []
@export var scoring_rules: Dictionary = {}
## Authored Subject-facing affordances keyed by canonical Verb name. Round
## controllers may expose these as guidance without revealing classifications.
@export var verb_answers: Dictionary = {}
@export_multiline var completion_condition: String
## Machine-readable lifecycle data consumed by TrialCoordinator. The prose
## condition remains the player-facing explanation used by Experiment Briefs.
@export_range(1.0, 3600.0, 1.0) var duration_seconds: float = 180.0
@export_enum("TIMER", "TIMER_OR_ONE_ELIGIBLE", "TIMER_OR_ALL_OBJECTIVES") \
var completion_mode: String = "TIMER"
@export var includes_thematic_moment: bool = false
## Internal development/marketing classification. Never show this to Players.
@export_enum("PVP", "PVE", "ENVIRONMENT") var classification: String = "ENVIRONMENT"


func experiment_brief() -> String:
	return "EXPERIMENT PROTOCOL: %s\nOBJECTIVE: %s" % [display_name, objective]
