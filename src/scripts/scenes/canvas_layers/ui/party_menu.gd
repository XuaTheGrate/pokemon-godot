class_name PartyMenu
extends UIState

@export var return_state: UIState

func enter(_default := false) -> void:
	for i in 6:
		var battler: Battler
		
		if i >= GameData.trainer_party.size():
			battler = null
		else:
			battler = GameData.trainer_party[i]
			
		var node := %PartyGrid.get_child(i)
		node.battler = battler
		node.update()
	
	%Party1.grab_focus()
	visible = true
	if TransitionManager.transitioned_in:
		TransitionManager.fade_out()
		await TransitionManager.animation_finished

func exit(_default := false) -> void:
	get_viewport().gui_release_focus()
	if not TransitionManager.transitioned_in:
		TransitionManager.fade_in()
		await TransitionManager.animation_finished
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
