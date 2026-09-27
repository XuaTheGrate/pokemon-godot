extends InteractionComponent

var player: Player:
	get: return OverworldManager.instance.player

## Vector direction to move in.
@export var direction: Vector2
## Steps to take. Value is multiplied by 32 for total walk length.
@export var steps: int

func interact() -> void:
	var state: PlayerState = player.get_node("State/Interaction")
	for i in steps:
		state.start_walk(direction)
		await player.end_step
