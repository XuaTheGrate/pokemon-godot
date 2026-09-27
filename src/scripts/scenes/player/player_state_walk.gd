extends PlayerState

@export var idle_state: PlayerState
@export var interaction_state: PlayerState

var _origin := Vector2.ZERO
var _target := Vector2.ZERO
var _walk_time := 0.0
var _running := false

func enter() -> PlayerState:
	return _start_walk(player.current_direction)

func physics_process(delta: float) -> PlayerState:
	var speed := player.speed * (player.run_multiplier if _running else 1.0)
	var step_time := 1.0 / speed
	_walk_time += delta / step_time
	
	if _walk_time >= 1.0:
		_walk_time = 1.0
		player.position = _target
		player.end_step.emit()
		
		var next := get_input_direction()
		if next != Vector2.ZERO:
			player.current_direction = next
			return _start_walk(next)
		return idle_state
	
	player.position = _origin.lerp(_target, _walk_time)
	return null

func get_animation(dir: Vector2) -> StringName:
	var prefix := "walk"
	if Input.is_action_pressed(&"Cancel"):
		prefix = "run"
	
	match dir:
		Vector2.UP: return prefix + "_up"
		Vector2.DOWN: return prefix + "_down"
		Vector2.LEFT: return prefix + "_left"
		Vector2.RIGHT: return prefix + "_right"
	
	return &"idle_down"

func _start_walk(dir: Vector2) -> PlayerState:
	var offset := dir * 32.0
	_target = player.position + offset
	if player.is_blocked():
		var interaction := player.get_interaction()
		if interaction != null and interaction.bump:
			idle_state.prepare_interaction_queue(interaction)
			return interaction_state
		return idle_state
	
	_origin = player.position
	_walk_time = 0.0
	_running = Input.is_action_pressed(&"Cancel")
	player.play_animation(get_animation(dir))
	return null
