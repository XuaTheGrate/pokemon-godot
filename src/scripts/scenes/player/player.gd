class_name Player
extends Node2D

const GENDER_M = 0
const GENDER_F = 1

@export var speed := 3.5
@export var run_multiplier := 2.0

var current_direction := Vector2.DOWN:
	set(value):
		current_direction = value
		movement_cast.target_position = Vector2(32.0, 32.0) * value
		interaction_cast.target_position = Vector2(32.0, 32.0) * value

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var movement_cast: ShapeCast2D = $MovementCast
@onready var interaction_cast: ShapeCast2D = $InteractionCast

signal end_step

func _ready() -> void:
	match GameData.trainer_gender:
		GENDER_M:
			$AnimatedSprite2D.sprite_frames = load("uid://clr1mn8he7uwv")
		GENDER_F:
			$AnimatedSprite2D.sprite_frames = load("uid://cfmyy4ww4hwpi")

func is_blocked() -> bool:
	movement_cast.force_shapecast_update()
	return movement_cast.is_colliding()

func is_moving() -> bool:
	# TODO: support surfing
	return $State.current_state.name == "Walk"

func get_interaction() -> Interaction:
	interaction_cast.force_shapecast_update()
	if not interaction_cast.is_colliding(): return null
	
	var collider := interaction_cast.get_collider(0)
	return collider

func play_animation(anim: StringName) -> void:
	sprite.play(anim)

func _on_dialogue_finished(_res: DialogueResource) -> void:
	get_tree().paused = false
