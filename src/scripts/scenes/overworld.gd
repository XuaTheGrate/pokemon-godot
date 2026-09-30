class_name OverworldManager
extends Node2D

@export_file("*.tscn") var battle_manager: String

@export_file("*.tscn") var default_map: String
@export var default_position := Vector2.ZERO
@export var default_wild_music: AudioStream

@onready var player: Player = $Player

static var instance: OverworldManager

var _current_map: String
var _loaded_maps: Dictionary[String, Map]
var _map_bounds := Rect2(Vector2.ZERO, Vector2.ZERO)

var _temp_map_id: String
var _temp_map_pos := Vector2.ZERO

func _init() -> void:
	if instance != null and is_instance_valid(instance):
		GameData.display_error("OverworldManager already instanced", "OverworldManager")
		queue_free()
		return
	
	instance = self

func _ready() -> void:
	if _temp_map_id != "":
		load_map_connected(_temp_map_id, _temp_map_pos)
	else:
		load_map_connected(default_map, default_position)
	TransitionManager.fade_out()

func get_current_map() -> Map:
	return _loaded_maps[_current_map]

func get_map_uid(map: Map) -> String:
	var path := map.scene_file_path
	var uid := ResourceLoader.get_resource_uid(path)
	return ResourceUID.id_to_text(uid)

func set_continue_map_data(map_id: String, pos := Vector2.ZERO) -> void:
	_temp_map_id = map_id
	_temp_map_pos = pos

func load_map_connected(
	map: String,
	player_position: Variant = null,
	player_rotation := Vector2.ZERO
) -> void:
	_current_map = map
	
	var new_map: Map
	if _loaded_maps.has(map):
		new_map = _loaded_maps[map]
	else:
		new_map = load(map).instantiate()
		add_child(new_map)
		_loaded_maps[map] = new_map
	
	var keep_maps: Array[String] = []
	for i in new_map.map_connections:
		keep_maps.append(i.map)
	
	for c in get_children():
		if c is Map:
			var uid := get_map_uid(c)
			if not keep_maps.has(uid) and uid != map:
				c.queue_free()
				_loaded_maps.erase(uid)
	
	for i in new_map.map_connections:
		if not _loaded_maps.has(i.map):
			var connected_map: Map = load(i.map).instantiate()
			connected_map.global_position = new_map.global_position + i.offset
			add_child(connected_map)
			_loaded_maps[i.map] = connected_map
	
	_map_bounds = new_map.get_bounds()
	if player_position != null and typeof(player_position) == TYPE_VECTOR2:
		player.global_position = player_position
	
	if new_map.show_name_popup:
		$TownPopup.show_text(new_map.map_name)
	
	if new_map.track != null:
		MusicPlayer.play_stream(new_map.track, 0.5)

# i hate this function.
func queue_map_transfer(map: String, pos: Vector2, rot: Vector2, door_path: String = "") -> void:
	var state: PlayerState = player.get_node("State/Interaction")
	state.override = true
	
	# play the tststs sound
	TransitionManager.fade_in()
	await TransitionManager.animation_finished
	load_map_connected(map, pos, rot)
	TransitionManager.fade_out()
	
	if door_path == "":
		player.visible = true
		state.override = false
		return
	
	player.visible = false
	var sprite: AnimatedSprite2D = get_current_map().get_node(door_path)
	sprite.play(&"opened")
	await TransitionManager.animation_finished
	player.visible = true
	state.start_walk(Vector2.DOWN)
	await player.end_step
	sprite.play(&"close")
	await sprite.animation_finished
	state.override = false

func _on_player_end_step() -> void:
	if _map_bounds.has_point(player.global_position): return
	
	# out of bounds, check for new maps
	for i in _loaded_maps.keys():
		var map := _loaded_maps[i]
		if map.get_bounds().has_point(player.global_position):
			load_map_connected(i)
			return
	
	push_error("No map to load, out of bounds")

func start_wild_battle(species: String, level: int) -> void:
	var battler := BattleManager.generate_wild_battler(species, level)
	if battler == null: return
	
	get_tree().paused = true
	
	var battle: BattleManager = load(battle_manager).instantiate()
	battle.name = "BattleManager"
	battle.battle_ended.connect(_on_battle_ended, CONNECT_ONE_SHOT)
	
	MusicPlayer.play_stream(
		get_current_map().wild_battle_track
		if get_current_map().wild_battle_track != null
		else default_wild_music
	)
	
	TransitionManager.custom(&"wild_battle_in")
	TransitionManager.animation_finished.connect((func(_b):
		add_child(battle)
		battle.init_wild_battle(battler)),
		CONNECT_ONE_SHOT
	)

func _on_battle_ended(victory: bool) -> void:
	TransitionManager.fade_in()
	await TransitionManager.animation_finished
	$BattleManager.queue_free()
	TransitionManager.fade_out()
	MusicPlayer.play_stream(get_current_map().track, 0.5)
	TransitionManager.animation_finished.connect(func(_a):get_tree().paused=false, CONNECT_ONE_SHOT)
