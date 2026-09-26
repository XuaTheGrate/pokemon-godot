extends Control

@export_file("*.tscn") var overworld: String

var _temp_save_file: SaveFile = null

func _ready() -> void:
	_setup_continue()
	%Debug.visible = OS.has_feature("editor")
	TransitionManager.fade_out()

func _input(event: InputEvent) -> void:
	if TransitionManager.fading: return
	
	if event.is_action_pressed(&"Down") or event.is_action_pressed(&"Up"):
		#accept_event()
		$GUIFocus.play()
	if event.is_action_pressed(&"Accept"):
		accept_event()
		$GUISelect.play()
		_handle_selection(get_viewport().gui_get_focus_owner())

func _setup_continue() -> void:
	var ext: String = ProjectSettings.get_setting("global/save_file_extension", ".res")
	if not FileAccess.file_exists("user://save%s" % ext):
		print("No save file to load.")
		%Continue.visible = false
		%NewGame.grab_focus.call_deferred()
		return
	
	%Continue.grab_focus.call_deferred()
	_temp_save_file = ResourceLoader.load("user://save%s" % ext)
	
	%PlayerName.text = _temp_save_file.trainer_name
	if _temp_save_file.trainer_gender == 0:
		%PlayerIcon.texture.atlas = load("res://assets/graphics/player/player_m_walk.png")
		%PlayerName.theme_type_variation = &"BlueLabel"
	else:
		%PlayerIcon.texture.atlas = load("res://assets/graphics/player/player_m_walk.png")
		%PlayerName.theme_type_variation = &"RedLabel"
	
	var map: PackedScene = load(_temp_save_file.map_id)
	var state := map.get_state()
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == "map_name":
			%LocationLabel.text = state.get_node_property_value(0, i)

func _handle_selection(node: Control) -> void:
	prints("HANDLE", node)
	match node.name:
		"Continue": _handle_continue()
		"NewGame": pass
		"SaveFiles": pass
		"Options": pass
		"Debug": pass
		"QuitGame":
			get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
			get_tree().quit(0)

func _handle_continue() -> void:
	TransitionManager.fade_in()
	await TransitionManager.animation_finished
	var ow: OverworldManager = load(overworld).instantiate()
	ow.set_continue_map_data(_temp_save_file.map_id, _temp_save_file.map_position)
	get_tree().change_scene_to_node(ow)
