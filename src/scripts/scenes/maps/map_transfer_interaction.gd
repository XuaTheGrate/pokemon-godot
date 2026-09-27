extends InteractionComponent

@export_file("*.tscn") var map: String
@export var player_position: Vector2
@export var player_rotation := Vector2.DOWN

func interact() -> void:
	OverworldManager.instance.queue_map_transfer(map, player_position, player_rotation)
