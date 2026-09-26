extends CanvasLayer

@export var label: RichTextLabel

func show_text(text: String) -> void:
	label.text = text
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.stop()
	$AnimationPlayer.play(&"show")

func _process(_delta: float) -> void:
	if $AnimationPlayer.is_playing() and get_tree().paused:
		$AnimationPlayer.stop()
