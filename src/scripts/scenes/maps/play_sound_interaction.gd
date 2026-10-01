extends InteractionComponent

@export var player: AudioStreamPlayer
@export var wait := false

func interact() -> void:
	player.play()
	if wait:
		await player.finished
