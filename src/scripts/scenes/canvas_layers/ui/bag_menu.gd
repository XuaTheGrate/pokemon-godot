extends UIState

@export var return_state: UIState

var pocket_index := 0

func enter(_default := false) -> void:
	_load_bag_data()
	visible = true
	TransitionManager.fade_out()
	await TransitionManager.animation_finished

func exit(_default := false) -> void:
	get_viewport().gui_release_focus()
	if not TransitionManager.transitioned_in:
		TransitionManager.fade_in()
		await TransitionManager.animation_finished
	visible = false

func input(event: InputEvent) -> UIState:
	if event.is_action_pressed(&"ui_home"):
		get_viewport().set_input_as_handled()
		GameData.bag = _generate_template_bag()
		return return_state
	
	if event.is_action_pressed(&"Left"):
		get_viewport().set_input_as_handled()
		$UIFocus.play()
		pocket_index = wrapi(pocket_index - 1, 0, 8)
		_update()
		
	if event.is_action_pressed(&"Right"):
		get_viewport().set_input_as_handled()
		$UIFocus.play()
		pocket_index = wrapi(pocket_index + 1, 0, 8)
		_update()
	
	if event.is_action_pressed(&"Cancel"):
		get_viewport().set_input_as_handled()
		$UICancel.play()
		return return_state
	
	$Tabs.get_current_tab_control().input(event)
	
	return null

func _input(event: InputEvent) -> void:
	if get_tree().current_scene == self:
		input(event)

func _ready() -> void:
	if get_tree().current_scene == self:
		TransitionManager.fade_out()
		GameData.bag = _generate_template_bag()
		_load_bag_data()

## For testing uses
func _generate_template_bag() -> Dictionary:
	var bag: Dictionary = {}
	for pocket_id in 8:
		bag[pocket_id] = []
		for item in ItemsManager.get_pocket_items(pocket_id):
			var count := GameData.rand.randi_range(0, 999)
			if pocket_id == 7:
				count = mini(count, 1)
			if count > 0:
				bag[pocket_id].append([item, count])
	return bag

func _load_bag_data() -> void:
	for pocket_id in $Tabs.get_child_count():
		var pocket: Control = $Tabs.get_child(pocket_id)
		var template: HBoxContainer = pocket.get_node("ScrollContainer/VBoxContainer/Template")
		for item in GameData.bag[pocket_id]:
			var new := template.duplicate()
			new.get_node("Name").text = ItemsManager.items[item[0]].name[0]
			if pocket_id != 7:
				new.get_node("Count").text = "x%d" % item[1]
			else:
				new.get_node("Count").queue_free()
			new.visible = true
			pocket.get_node("ScrollContainer/VBoxContainer").add_child(new)
		pocket.enter_highlight.call_deferred()
	_update()

func _update() -> void:
	$Tabs.current_tab = pocket_index
	var sc: ScrollContainer = $Tabs.get_current_tab_control().get_node("ScrollContainer")
	$VScrollBar.unshare()
	sc.get_v_scroll_bar().share($VScrollBar)
	$BagCursor.texture.region.position.x = 28.0 * pocket_index
	$BagCursor.offset_transform_position.x = 22.0 * pocket_index
	$PocketName.text = $Tabs.get_current_tab_control().name
	$Tabs.get_current_tab_control().enter_highlight()

func _on_item_highlighted(index: int) -> void:
	var i: Array = GameData.bag[pocket_index][index]
	var item_id: String = i[0]
	var item := ItemsManager.items[item_id]
	$ItemDescription.text = item.description
	if ResourceLoader.exists("res://assets/graphics/items/%s.png" % item_id):
		$ItemIcon.texture = load("res://assets/graphics/items/%s.png" % item_id)
	else:
		$ItemIcon.texture = load("res://assets/graphics/items/000.png")
