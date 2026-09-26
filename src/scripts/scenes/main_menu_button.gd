extends TextureRect

func _init() -> void:
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

func _on_focus_entered() -> void:
	texture.region.position.y += texture.region.size.y

func _on_focus_exited() -> void:
	texture.region.position.y -= texture.region.size.y
