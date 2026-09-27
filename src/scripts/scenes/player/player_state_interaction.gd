extends PlayerState

@export var idle_state: PlayerState

var _origin := Vector2.ZERO
var target := Vector2.ZERO
var target_direction := Vector2.DOWN
var _walk_time := 0.0
var _walking := false

var interaction_queue: Array[InteractionComponent] = []

func enter() -> PlayerState:
	_play_queue()
	return null

func _play_queue() -> void:
	while not interaction_queue.is_empty():
		var component: InteractionComponent = interaction_queue.pop_front()
		prints("Playing component", component)
		await component.interact()

func process(_delta: float) -> PlayerState:
	if interaction_queue.is_empty():
		return idle_state
	return null

func physics_process(delta: float) -> PlayerState:
	if not _walking: return
	
	var speed := player.speed
	var step_time := 1.0 / speed
	_walk_time += delta / step_time
	
	if _walk_time >= 1.0:
		_walk_time = 1.0
		player.position = target
		player.end_step.emit()
		target = Vector2.ZERO
		target_direction = Vector2.ZERO
		_origin = Vector2.ZERO
		_walking = false
		return null
	
	player.position = _origin.lerp(target, _walk_time)
	return null

func get_animation(dir: Vector2) -> StringName:
	var prefix := "walk"
	
	match dir:
		Vector2.UP: return prefix + "_up"
		Vector2.DOWN: return prefix + "_down"
		Vector2.LEFT: return prefix + "_left"
		Vector2.RIGHT: return prefix + "_right"
	
	return &"idle_down"

func start_walk(dir: Vector2) -> PlayerState:
	var offset := dir * 32.0
	target = player.position + offset
	_origin = player.position
	_walk_time = 0.0
	player.play_animation(get_animation(dir))
	_walking = true
	return null
