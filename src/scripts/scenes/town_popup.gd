extends CanvasLayer

@export var label: RichTextLabel

func show_text(text: String) -> void:
	label.text = text
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.stop()
	$AnimationPlayer.play(&"show")
