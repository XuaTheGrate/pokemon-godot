extends PlayerState

const WALK_PAUSE_TIME := 0.1

@export var walk_state: PlayerState
@export var interaction_state: PlayerState

var _walk_time := 0.0

func enter() -> PlayerState:
	player.play_animation(get_animation(player.current_direction))
	return null

func input(event: InputEvent) -> PlayerState:
	if TransitionManager.transitioning: return
	
	if event.is_action_pressed(&"Accept"):
		var interaction := player.get_interaction()
		if interaction != null and interaction.button:
			prepare_interaction_queue(interaction)
			return interaction_state
	return null

func prepare_interaction_queue(interaction: Interaction):
	for c in interaction.get_children():
		if c is InteractionComponent:
			interaction_state.interaction_queue.append(c)

func physics_process(delta: float) -> PlayerState:
	var dir := get_input_direction()
	if dir == Vector2.ZERO:
		_walk_time = 0.0
		return null
	
	if dir != player.current_direction:
		player.current_direction = dir
		player.play_animation(get_animation(dir))
		_walk_time = 0.0
		return null
	
	_walk_time += delta
	
	if _walk_time >= WALK_PAUSE_TIME:
		_walk_time = 0.0
		
		if player.is_blocked():
			var interaction := player.get_interaction()
			if interaction != null and interaction.bump:
				prepare_interaction_queue(interaction)
				return interaction_state
			return null
		
		return walk_state
	
	return null

func get_animation(direction: Vector2) -> StringName:
	match direction:
		Vector2.DOWN: return &"idle_down"
		Vector2.UP: return &"idle_up"
		Vector2.LEFT: return &"idle_left"
		Vector2.RIGHT: return &"idle_right"
	return &"default"
