class_name PlayerStateMachine extends Node

@export var default_state: PlayerState

var current_state: PlayerState = null

func _ready() -> void:
	for state: PlayerState in get_children():
		state.player = get_parent()
	
	current_state = default_state
	default_state.call_deferred("enter")

func _process(delta: float) -> void:
	if TransitionManager.fading: return
	
	var new_state := current_state.process(delta)
	if new_state != null:
		change_state(new_state)

func _physics_process(delta: float) -> void:
	if TransitionManager.fading: return
	
	var new_state := current_state.physics_process(delta)
	if new_state != null:
		change_state(new_state)

func _input(event: InputEvent) -> void:
	if TransitionManager.fading: return
	
	var new_state := current_state.input(event)
	if new_state != null:
		change_state(new_state)

func change_state(new_state: PlayerState) -> void:
	if current_state != null:
		current_state.exit()
	
	new_state.enter()
	current_state = new_state
