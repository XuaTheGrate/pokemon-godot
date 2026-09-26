class_name PlayerState
extends Node

var player: Player

func enter() -> PlayerState:
	return null

func exit() -> PlayerState:
	return null

func process(_delta: float) -> PlayerState:
	return null

func physics_process(_delta: float) -> PlayerState:
	return null

func input(_event: InputEvent) -> PlayerState:
	return null

func get_input_direction() -> Vector2:
	if Input.is_action_pressed(&"Down"):
		return Vector2.DOWN
	if Input.is_action_pressed(&"Up"):
		return Vector2.UP
	if Input.is_action_pressed(&"Right"):
		return Vector2.RIGHT
	if Input.is_action_pressed(&"Left"):
		return Vector2.LEFT
	return Vector2.ZERO
