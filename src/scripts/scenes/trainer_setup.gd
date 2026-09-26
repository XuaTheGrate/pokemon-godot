extends Control

const START_KEY = "setup_start"

@export_file("*.tscn") var start_map: String
@export var start_position: Vector2

var dialogue: DialogueResource = preload("res://src/resources/dialogue/trainer_setup.dialogue")
var temp_name := "PLACEHOLDR"
var temp_gender := -1

func _ready() -> void:
	$NameInput.visible = false
	for b in get_children():
		if b.name != "Bg" and b is TextureRect:
			b.modulate.a = 0.0
	
	if TransitionManager.transitioned_in:
		TransitionManager.fade_out()
		await TransitionManager.animation_finished
	
	var t := create_tween()
	t.tween_interval(1)
	t.tween_property($Base, "modulate:a", 1.0, 0.5)
	t.parallel().tween_property($Oak, "modulate:a", 1.0, 0.5)
	await t.finished
	DialogueManager.show_dialogue_balloon(dialogue, START_KEY, [self, {"Setup": self}])

func show_marill():
	var t := create_tween()
	t.tween_property($Oak, "modulate:a", 0.0, 0.5)
	t.tween_property($Marill, "modulate:a", 1.0, 0.5)
	await t.finished

func show_oak():
	var t := create_tween()
	t.tween_property($Marill, "modulate:a", 0.0, 0.5)
	t.tween_property($Oak, "modulate:a", 1.0, 0.5)
	await t.finished

func hide_all():
	var t := create_tween()
	t.tween_property($Oak, "modulate:a", 0.0, 0.5)
	t.parallel().tween_property($Base, "modulate:a", 0.0, 0.5)
	await t.finished

func show_boy():
	temp_gender = 0
	var t := create_tween()
	t.tween_property($Base, "modulate:a", 1.0, 0.5)
	t.parallel().tween_property($Boy, "modulate:a", 1.0, 0.5)
	await t.finished

func show_girl():
	temp_gender = 1
	var t := create_tween()
	t.tween_property($Base, "modulate:a", 1.0, 0.5)
	t.parallel().tween_property($Girl, "modulate:a", 1.0, 0.5)
	await t.finished

func get_name_input():
	$NameInput.visible = true
	temp_name = ""
	while temp_name == "":
		$NameInput.grab_focus()
		temp_name = await $NameInput.text_submitted
	$NameInput.visible = false

func finalize() -> void:
	GameData.trainer_name = temp_name
	GameData.trainer_gender = temp_gender
	TransitionManager.fade_in()
	TransitionManager.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(_out: bool) -> void:
	var ow: OverworldManager = load("res://src/scenes/overworld.tscn").instantiate()
	ow.set_continue_map_data(start_map, start_position)
	get_tree().change_scene_to_node.call_deferred(ow)
