class_name LocalPlaytestConfig
extends Resource
## Developer-facing configuration for the deterministic local quick start.
##
## One Subject accepts local input. Additional Subjects are registered and
## spawned as stationary participants so Pair behaviour can be inspected
## without pretending that local multiplayer transport exists.

@export_enum("PVP", "PVE", "PUZZLE") var protocol_classification: String = "PUZZLE"
@export var trial_seed: int = 1
@export_range(1, 9, 1) var subject_count: int = 1
@export var initial_verbs: Array[Enums.VerbType] = [Enums.VerbType.BURN]


func verb_for_subject(subject_index: int) -> Enums.VerbType:
	if subject_index < initial_verbs.size():
		var configured: Enums.VerbType = initial_verbs[subject_index]
		if configured != Enums.VerbType.NONE:
			return configured
	# Deterministic fallback follows the canonical enum order.
	return (subject_index % (Enums.VerbType.size() - 1)) + 1 as Enums.VerbType
