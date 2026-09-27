extends UIState

@export var player: Player

var current_state: UIState = self

func _ready() -> void:
	if TransitionManager.transitioned_in:
		TransitionManager.fade_out()

func change_state(new_state: UIState) -> void:
	if new_state != null:
		var old_state := current_state
		current_state = null
		await old_state.exit(new_state == self)
		await new_state.enter(old_state == self)
		current_state = new_state

func _input(event: InputEvent) -> void:
	if current_state != null:
		var new_state := await current_state.input(event)
		change_state(new_state)

func input(event: InputEvent) -> UIState:
	if event.is_action_pressed("Pause"):
		if player != null and player.is_moving(): return
		
		get_viewport().set_input_as_handled()
		return $PauseMenu
	return null

func _process(delta: float) -> void:
	if current_state != null:
		var new_state := current_state.process(delta)
		change_state(new_state)
