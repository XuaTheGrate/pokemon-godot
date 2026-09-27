extends InteractionComponent

var player: Player:
	get: return OverworldManager.instance.player

## Whether to show or hide the player
@export var hide := true

func interact() -> void:
	player.visible = not hide
