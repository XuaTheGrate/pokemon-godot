class_name Player
extends Node2D

const GENDER_M = 0
const GENDER_F = 1

@export var speed := 3.5
@export var run_multiplier := 2.0

var current_direction := Vector2.DOWN:
	set(value):
		current_direction = value
		shapecast.target_position = Vector2(32.0, 32.0) * value

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shapecast: ShapeCast2D = $ShapeCast2D

signal end_step

func _ready() -> void:
	match GameData.trainer_gender:
		GENDER_M:
			$AnimatedSprite2D.sprite_frames = load("uid://clr1mn8he7uwv")
		GENDER_F:
			$AnimatedSprite2D.sprite_frames = load("uid://cfmyy4ww4hwpi")

func is_blocked() -> bool:
	shapecast.force_shapecast_update()
	return shapecast.is_colliding()

func is_moving() -> bool:
	# TODO: support surfing
	return $State.current_state.name == "Walk"

func play_animation(anim: StringName) -> void:
	sprite.play(anim)

func _on_dialogue_finished(_res: DialogueResource) -> void:
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_home"):
		var res: DialogueResource = load("res://src/resources/dialogue/generic.dialogue")
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
		DialogueManager.show_dialogue_balloon(res, "start")
		get_tree().paused = true
