extends TextureRect

const UNSELECTED = &""
const SELECTED = &"YellowLabel"

signal item_highlighted(index: int)

var _index := 1
var _max_count: int:
	get: return $ScrollContainer/VBoxContainer.get_child_count()

func input(event: InputEvent) -> void:
	if get_parent().get_current_tab_control() != self: return
	
	if event.is_action_pressed(&"Up", true):
		get_viewport().set_input_as_handled()
		%UIFocus.play()
		_index = wrapi(_index - 1, 1, _max_count)
		enter_highlight()
	if event.is_action_pressed(&"Down", true):
		get_viewport().set_input_as_handled()
		%UIFocus.play()
		_index = wrapi(_index + 1, 1, _max_count)
		enter_highlight()

func enter_highlight() -> void:
	for child in $ScrollContainer/VBoxContainer.get_children():
		var n := child.get_node("Name")
		n.theme_type_variation = UNSELECTED
	
	if _index >= _max_count: return
	
	var target: Control = $ScrollContainer/VBoxContainer.get_child(_index).get_node("Name")
	target.theme_type_variation = SELECTED
	$ScrollContainer/VBoxContainer.get_child(_index).grab_focus()
	$ScrollContainer.set_deferred("scroll_vertical", snappedi($ScrollContainer.scroll_vertical, 32))
	if get_parent().get_current_tab_control() == self:
		item_highlighted.emit(_index-1)
