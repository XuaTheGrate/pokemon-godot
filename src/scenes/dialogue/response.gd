extends HBoxContainer

var response: DialogueResponse:
	set(value):
		response = value
		$Text.text = value.text


func _on_focus_entered() -> void:
	$Cursor.modulate.a = 1.0

func _on_focus_exited() -> void:
	$Cursor.modulate.a = 0.0
