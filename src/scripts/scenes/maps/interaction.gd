class_name Interaction
extends Area2D

## Whether this interaction can be triggered by "bumping" into it with the player.
@export var bump := false
## Whether this interaction can be triggered by pressing &"Accept" when facing it.
@export var button := false

## Coroutine. Runs through every interaction in child order.
func interact() -> void:
	for c in get_children():
		if c is not InteractionComponent: continue
		await c.interact()
