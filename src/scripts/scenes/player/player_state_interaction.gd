extends PlayerState

@export var idle_state: PlayerState

var _origin := Vector2.ZERO
var target := Vector2.ZERO
var target_direction := Vector2.DOWN:
	set(value):
		target_direction = value
var _walk_time := 0.0
var _walking := false

var override := false

var interaction_queue: Array[InteractionComponent] = []

func enter() -> PlayerState:
	_play_queue()
	return null

func _play_queue() -> void:
	while not interaction_queue.is_empty():
		var component: InteractionComponent = interaction_queue[0]
		await component.interact()
		interaction_queue.pop_front()

func process(_delta: float) -> PlayerState:
	if interaction_queue.is_empty() and not override:
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
		_origin = Vector2.ZERO
		_walking = false
		var anim := get_animation(target_direction, "idle")
		player.play_animation(anim)
		target_direction = Vector2.ZERO
		return null
	
	player.position = _origin.lerp(target, _walk_time)
	return null

func get_animation(dir: Vector2, prefix := "walk") -> StringName:
	if dir.x > 0: return prefix + "_right"
	if dir.x < 0: return prefix + "_left"
	if dir.y < 0: return prefix + "_up"
	if dir.y > 0: return prefix + "_down"
	
	return &"idle_down"

func start_walk(dir: Vector2) -> PlayerState:
	var offset := dir * 32.0
	target = player.position + offset
	target_direction = dir
	_origin = player.position
	_walk_time = 0.0
	player.play_animation(get_animation(dir))
	_walking = true
	return null
