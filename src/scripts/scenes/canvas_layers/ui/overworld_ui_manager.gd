extends UIState

@export var player: Player

var current_state: UIState = self

func change_state(new_state: UIState) -> void:
	if new_state != null:
		#prints("Change state", current_state, "->", new_state)
		current_state.exit(new_state == self)
		new_state.enter(current_state == self)
		current_state = new_state

func _input(event: InputEvent) -> void:
	var new_state := current_state.input(event)
	change_state(new_state)

func input(event: InputEvent) -> UIState:
	if event.is_action_pressed("Pause"):
		if player != null and player.is_moving(): return
		
		get_viewport().set_input_as_handled()
		return $PauseMenu
	return null

func _process(delta: float) -> void:
	var new_state := current_state.process(delta)
	change_state(new_state)
