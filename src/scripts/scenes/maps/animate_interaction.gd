extends InteractionComponent

## The sprite to animate
@export var sprite: AnimatedSprite2D
## The animation to play
@export var animation: StringName
## Whether to wait for the animation to finish before returning.
## Must not be looping or this will hang forever.
@export var wait := true

func interact() -> void:
	sprite.play(animation)
	if wait:
		await sprite.animation_finished
