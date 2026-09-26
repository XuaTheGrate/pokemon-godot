extends TextureRect

func _on_focus_entered() -> void:
	texture.region.position.y = 48.0

func _on_focus_exited() -> void:
	texture.region.position.y = 0.0
