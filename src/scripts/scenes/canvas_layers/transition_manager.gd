extends CanvasLayer

var transitioning := false
var transitioned_in := true

signal animation_finished(out: bool)

func fade_in() -> void:
	prints("FADING IN")
	$AnimationPlayer.play(&"fade_in")
	transitioning = true
	transitioned_in = true

func fade_out() -> void:
	prints("FADING OUT")
	$AnimationPlayer.play(&"fade_out")
	transitioning = true
	transitioned_in = false

func custom(anim: StringName) -> void:
	prints("CUSTOM", anim)
	$AnimationPlayer.play(anim)
	transitioning = true
	transitioned_in = anim.ends_with("_in")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	prints(anim_name)
	animation_finished.emit(anim_name.ends_with("_out"))
	transitioning = false
