extends CanvasLayer

@export_file("*.tscn") var main_menu: String

var _can_skip := false
var _current_splash := 0

func _ready() -> void:
	$Splash1.visible = true
	$Splash2.visible = false
	$Title.visible = false
	
	TransitionManager.animation_finished.connect(_on_fade_complete)
	TransitionManager.fade_out()

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed(&"Accept") or event.is_action_pressed(&"Cancel")):
		if not TransitionManager.transitioning:
			next_splash()

func _on_timer_timeout() -> void:
	next_splash()

func next_splash() -> void:
	if not _can_skip: return
	_can_skip = false
	$Timer.stop()
	TransitionManager.fade_in()
	_current_splash += 1
	
	if _current_splash >= 3:
		TransitionManager.animation_finished.disconnect(_on_fade_complete)
		TransitionManager.animation_finished.connect(_goto_main)

func _on_fade_complete(out: bool) -> void:
	if out:
		if _current_splash < 2:
			$Timer.start()
		_can_skip = true
		return
	
	$Splash1.visible = _current_splash == 0
	$Splash2.visible = _current_splash == 1
	$Title.visible = _current_splash == 2
	TransitionManager.fade_out()

func _goto_main(_out: bool):
	get_tree().change_scene_to_file(main_menu)
