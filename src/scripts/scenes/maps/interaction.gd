class_name Interaction
extends Area2D

## Whether this interaction can be triggered by "bumping" into it with the player.
@export var bump := false
## Whether this interaction can be triggered by pressing &"Accept" when facing it.
@export var button := false
## Whether this interaction can be triggered by walking over it.
## Must not block physics. Ensure mask 2 is set to check for the player walking over it.
@export var touch := false

var _entry_point := Vector2.ZERO

func _ready() -> void:
	prints("Touch?", touch, self)
	if touch:
		area_entered.connect(_on_area_entered)
		area_exited.connect(_on_area_exited)

func _trigger_interactions(pos: Vector2) -> void:
	var point: Vector2 = $CollisionShape2D.shape.size / 2.0
	var dist := _entry_point - pos
	
	if abs(dist.y) > point.y:
		for c in get_children():
			if c is InteractionComponent:
				await c.interact()

func _on_area_entered(area: Area2D) -> void:
	prints("Area entered", area)
	if area.get_parent() is Player:
		_entry_point = area.get_parent().global_position

func _on_area_exited(area: Area2D) -> void:
	prints("Area exited", area)
	if area.get_parent() is Player:
		_trigger_interactions(area.get_parent().global_position)
