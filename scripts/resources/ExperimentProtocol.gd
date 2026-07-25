class_name ExperimentProtocol
extends Resource
## Authored rules selected by the Semantic Engine for one Experiment.

@export var protocol_id: StringName
@export var display_name: String
@export_multiline var objective: String
@export var hazards: Array[String] = []
@export var scoring_rules: Dictionary = {}
@export_multiline var completion_condition: String
## Internal development/marketing classification. Never show this to Players.
@export_enum("PVP", "PVE", "PUZZLE") var classification: String = "PUZZLE"


func experiment_brief() -> String:
	return "EXPERIMENT PROTOCOL: %s\nOBJECTIVE: %s" % [display_name, objective]
