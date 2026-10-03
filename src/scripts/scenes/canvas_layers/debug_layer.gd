extends CanvasLayer

const REFRESH_RATE := 10

const LEFT_STATES = ["PauseMenu", "BagMenu"]

func _init() -> void:
	visible = OS.has_feature("editor")

func _physics_process(_delta: float) -> void:
	if Engine.get_physics_frames() % REFRESH_RATE != 0: return
		
	var fps := Engine.get_frames_per_second()
	var color: Color
	if fps < 30:
		color = Color.RED
	elif fps < 60:
		color = Color.YELLOW
	else:
		color = Color.GREEN
	
	%FPS.text = "[color=#%s]FPS: %s[/color]" % [color.to_html(), Engine.get_frames_per_second()]
	
	if get_tree().paused:
		%Paused.text = "[color=red]Paused[/color]"
	else:
		%Paused.text = "[color=green]Unpaused[/color]"
	
	var player: Player = get_tree().get_first_node_in_group(&"Player")
	if player != null:
		var state: Node = player.get_node("State").current_state
		if state != null:
			%PlayerState.text = "PlayerState: %s" % state.name
		else:
			%PlayerState.text = "[color=red]PlayerState: null[/color]"
	else:
		%PlayerState.text = "[color=gray]PlayerState: N/A[/color]"
	
	var owui: UIState = get_tree().get_first_node_in_group(&"OverworldUIManager")
	if owui != null:
		
		var state: UIState = owui.current_state
		if state != null:
			%UIState.text = "UIState: %s" % state.name
			$HBoxContainer.alignment = HBoxContainer.ALIGNMENT_BEGIN if LEFT_STATES.has(state.name) else HBoxContainer.ALIGNMENT_END
		else:
			%UIState.text = "[color=red]UIState: null[/color]"
	else:
		%UIState.text = "[color=gray]UIState: N/A[/color]"
	
	var battle: BattleManager = get_tree().get_first_node_in_group(&"BattleManager")
	if battle != null:
		var state: Node = battle.get_node("StateManager").current_state
		if state != null:
			%BattleState.text = "BattleState: %s" % state.name
		else:
			%BattleState.text = "[color=red]BattleState: null[/color]"
	else:
		%BattleState.text = "[color=darkgray]BattleState: N/A[/color]"
