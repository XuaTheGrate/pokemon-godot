extends Node

@export var default_state: BattleStateBase

var current_state: BattleStateBase

func _ready() -> void:
	default_state.enter()
	current_state = default_state

func change_state(new_state: BattleStateBase) -> void:
	if current_state != null:
		current_state.exit()
	new_state.manager = get_parent()
	current_state = new_state
	
	var new_new_state := new_state.enter()
	if new_new_state != null: # Rare case where sometimes we want to immediately exit (see Intro)
		change_state(new_new_state)

func _input(event: InputEvent) -> void:
	if current_state == null: return
	
	var new_state := current_state.input(event)
	if new_state != null:
		change_state(new_state)

func _process(delta: float) -> void:
	if current_state != null:
		var new_state := current_state.process(delta)
		if new_state != null:
			change_state(new_state)
