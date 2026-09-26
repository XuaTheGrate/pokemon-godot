class_name OverworldManager
extends Node2D

@export_file("*.tscn") var default_map: String
@export var default_position := Vector2.ZERO

@onready var player: Player = $Player

static var instance: OverworldManager

var _current_map: String
var _loaded_maps: Dictionary[String, Map]
var _map_bounds := Rect2(Vector2.ZERO, Vector2.ZERO)

func _init() -> void:
	if instance != null and is_instance_valid(instance):
		GameData.display_error("OverworldManager already instanced", "OverworldManager")
		queue_free()
		return
	
	instance = self

func _ready() -> void:
	if get_tree().root == get_parent():
		player.global_position = default_position
		load_map_connected(default_map)

func get_current_map() -> Map:
	return _loaded_maps[_current_map]

func get_map_uid(map: Map) -> String:
	var path := map.scene_file_path
	var uid := ResourceLoader.get_resource_uid(path)
	return ResourceUID.id_to_text(uid)

func load_map_connected(map: String, player_position: Variant = null) -> void:
	_current_map = map
	
	var new_map: Map
	if _loaded_maps.has(map):
		prints("Map", map, "already loaded")
		new_map = _loaded_maps[map]
	else:
		new_map = load(map).instantiate()
		add_child(new_map)
		_loaded_maps[map] = new_map
		prints("Loading new map", map)
	
	var keep_maps: Array[String] = []
	for i in new_map.map_connections:
		keep_maps.append(i.map)
	prints(keep_maps.size(), "map connections")
	
	for c in get_children():
		if c is Map:
			var uid := get_map_uid(c)
			if not keep_maps.has(uid) and uid != map:
				prints("Queueing", uid, "for deletion")
				c.queue_free()
				_loaded_maps.erase(uid)
	
	for i in new_map.map_connections:
		if not _loaded_maps.has(i.map):
			var connected_map: Map = load(i.map).instantiate()
			connected_map.global_position = new_map.global_position + i.offset
			add_child(connected_map)
			_loaded_maps[i.map] = connected_map
			prints("Loading connected map", i.map)
	
	_map_bounds = new_map.get_bounds()
	if player_position != null and typeof(player_position) == TYPE_VECTOR2:
		player.global_position = player_position
	
	if new_map.show_name_popup:
		$TownPopup.show_text(new_map.map_name)

func _on_player_end_step() -> void:
	if _map_bounds.has_point(player.global_position): return
	
	# out of bounds, check for new maps
	for i in _loaded_maps.keys():
		var map := _loaded_maps[i]
		if map.get_bounds().has_point(player.global_position):
			load_map_connected(i)
			return
	
	push_error("No map to load, out of bounds")
