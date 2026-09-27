extends InteractionComponent

@export var sprite: AnimatedSprite2D
@export var directions: Dictionary[Vector2, StringName] = {
	Vector2.LEFT: &"idle_left",
	Vector2.RIGHT: &"idle_right",
	Vector2.UP: &"idle_up",
	Vector2.DOWN: &"idle_down"
}

var player: Player:
	get: return OverworldManager.instance.player

func interact() -> void:
	var dir: Vector2 = (player.global_position - get_parent().global_position).normalized()
	var anim: StringName = directions.get(dir, &"default")
	sprite.play(anim)
