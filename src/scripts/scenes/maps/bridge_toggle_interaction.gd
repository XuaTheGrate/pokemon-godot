extends InteractionComponent

## TileMapLayer of the bridge appearing above the player.[br]
## Must have a single TileMapLayer child denoting hidden physics. Can be invisible.
@export var bridge_above: TileMapLayer
## TileMapLayer of the bridge appearing below the player.[br]
## Must have a single TileMapLayer child denoting hidden physics. Can be invisible.
@export var bridge_below: TileMapLayer

func interact() -> void:
	bridge_above.enabled = not bridge_above.enabled
	bridge_above.get_child(0).enabled = bridge_above.enabled
	
	bridge_below.enabled = not bridge_below.enabled
	bridge_below.get_child(0).enabled = bridge_below.enabled
