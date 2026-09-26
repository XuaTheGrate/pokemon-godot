extends CanvasLayer

var transitioning := false
var transitioned_in := true

signal animation_finished(out: bool)

func fade_in() -> void:
	$AnimationPlayer.play(&"fade_in")
	transitioning = true
	transitioned_in = true

func fade_out() -> void:
	$AnimationPlayer.play(&"fade_out")
	transitioning = true
	transitioned_in = false

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	animation_finished.emit(anim_name.ends_with("_out"))
	transitioning = false
