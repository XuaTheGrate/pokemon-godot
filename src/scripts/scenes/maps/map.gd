class_name Map
extends Node2D

@export var map_name: String
@export var show_name_popup := true
@export var track: AudioStream

@export var map_connections: Array[MapConnector] = []

func get_bounds() -> Rect2:
	var biggest: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
	for t: TileMapLayer in $TileMapLayers.get_children():
		var rect := t.get_used_rect()
		rect.position = Vector2i(global_position)
		rect.size *= 32
		if rect.get_area() > biggest.get_area():
			biggest = rect
	return biggest
