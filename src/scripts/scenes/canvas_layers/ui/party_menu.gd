class_name PartyMenu
extends UIState

@export var return_state: UIState

func enter(_default := false) -> void:
	%Party1.grab_focus()
	visible = true

func exit(_default := false) -> void:
	get_viewport().gui_release_focus()
	visible = false

func input(event: InputEvent) -> UIState:
	if event.is_action_pressed(&"Accept"):
		get_viewport().set_input_as_handled()
		var current := get_viewport().gui_get_focus_owner()
		if current == %CancelButton:
			return return_state
	if event.is_action_pressed(&"Cancel"):
		get_viewport().set_input_as_handled()
		return return_state
	return null
