extends CanvasLayer

var fading := false

signal animation_finished(out: bool)

func fade_in() -> void:
	$AnimationPlayer.play(&"fade_in")
	fading = true

func fade_out() -> void:
	$AnimationPlayer.play(&"fade_out")
	fading = true

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	animation_finished.emit(anim_name.ends_with("_out"))
	fading = false
