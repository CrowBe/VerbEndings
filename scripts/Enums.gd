class_name Enums
## Shared enumerations for Verb Endings.
##
## Kept in a script-level class_name so every script (and future RPC payload)
## references the same integer values. Enum values are serialized as ints over
## the network, so NEVER reorder existing entries — append new verbs at the end.

enum VerbType {
	NONE,
	BURN,
	SHIELD,
	GROW,
	STRETCH,
	ROLL,
	JUMP,
	BOUNCE,
	FREEZE,
	REWIND,
}


## Human-readable name for UI / debug output.
static func verb_name(verb: VerbType) -> String:
	return VerbType.keys()[verb]
