class_name MaterialResource
extends Area3D
## Material shed by an Impact or dispensed by the Semantic Engine.
## A live Subject absorbs it on contact to Restabilise, capped at baseline.

@export_range(0.0, 100.0, 0.1) var absorb_amount: float = 10.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.has_method("absorb_material") and body.absorb_material(absorb_amount):
		queue_free()
