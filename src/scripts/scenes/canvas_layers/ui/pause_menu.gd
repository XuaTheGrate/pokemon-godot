class_name PauseMenu
extends UIState

const CURSOR_VISIBLE := Color(1, 1, 1, 1)
const CURSOR_INVISIBLE := Color(1, 1, 1, 0)

@export var ui_default: UIState
@export var ui_pokedex: UIState
@export var ui_pokemon: UIState
@export var ui_bag: UIState
@export var ui_pokegear: UIState
@export var ui_trainercard: UIState
@export var ui_save: UIState
@export var ui_options: UIState
@export var ui_debug: UIState

var _index := 0

@onready var container: VBoxContainer = $Panel/Margin/VBox
@onready var is_root := get_tree().root == get_parent()

var current: HBoxContainer:
	get: return container.get_child(_index)

func enter(default := false) -> void:
	# TODO: make certain options appear/disappear
	%Debug.visible = OS.has_feature("editor")
	update()
	visible = true
	if default:
		get_tree().paused = true
		$UIMenuOpen.play()

func exit(default := false) -> void:
	if default:
		$UIMenuClose.play()
		get_tree().paused = false
	visible = false

func _input(event: InputEvent) -> void:
	if is_root:
		input(event)

func input(event: InputEvent) -> UIState:
	if event.is_action_pressed(&"Down"):
		get_viewport().set_input_as_handled()
		_index = wrapi(_index + 1, 0, container.get_child_count())
		while not current.visible:
			_index = wrapi(_index + 1, 0, container.get_child_count())
		$UIFocus.play()
		update()
	
	if event.is_action_pressed(&"Up"):
		get_viewport().set_input_as_handled()
		_index = wrapi(_index - 1, 0, container.get_child_count())
		while not current.visible:
			_index = wrapi(_index - 1, 0, container.get_child_count())
		$UIFocus.play()
		update()
	
	if event.is_action_pressed(&"Accept"):
		get_viewport().set_input_as_handled()
		
		$UISelect.play()
		match _index:
			0: return ui_pokedex
			1: return ui_pokemon
			2: return ui_bag
			3: return ui_pokegear
			4: return ui_trainercard
			5: return ui_save
			6: return ui_options
			7: return ui_debug
			8: # QuitGame
				get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
				get_tree().quit(0)
				return null
	
	if event.is_action_pressed(&"Cancel"):
		get_viewport().set_input_as_handled()
		return ui_default
	
	return null

func update() -> void:
	for child in container.get_children():
		child.get_node("Cursor").modulate = CURSOR_INVISIBLE
	
	current.get_node("Cursor").modulate = CURSOR_VISIBLE
