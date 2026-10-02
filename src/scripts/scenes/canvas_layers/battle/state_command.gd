extends BattleStateBase

@export var fight_state: BattleStateBase
@export var bag_state: BattleStateBase
@export var switch_state: BattleStateBase
@export var waiting_state: BattleStateBase

var _selected := Vector2i.ZERO

func enter() -> BattleStateBase:
	var battler: Battler = %DataboxAlly.battler
	if battler.queued_two_turn_move != "":
		prints("Skipping Command state due to queued two turn move", battler.queued_two_turn_move)
		var move_index: int = battler.moves.find_custom(func(m:BattleMove):return m.move_id == battler.queued_two_turn_move)
		var command: BattleManager.Command = fight_state.create_move_command_singles(battler.moves[move_index])
		command.charged = true
		manager.command_pool.append(command)
		return waiting_state
	
	%CommandBox.visible = true
	%CommandBox/Label.text = "What will %s do?" % manager.get_current_battler().display_name
	_update()
	return null

func exit() -> void:
	%CommandBox.visible = false

func input(event: InputEvent) -> BattleStateBase:
	if event.is_action_pressed(&"Up") and _selected.y != 0:
		get_viewport().set_input_as_handled()
		_selected.y = 0
		%UIFocus.play()
		_update()
	if event.is_action_pressed(&"Down") and _selected.y != 1:
		get_viewport().set_input_as_handled()
		_selected.y = 1
		%UIFocus.play()
		_update()
	if event.is_action_pressed(&"Left") and _selected.x != 0:
		get_viewport().set_input_as_handled()
		_selected.x = 0
		%UIFocus.play()
		_update()
	if event.is_action_pressed(&"Right") and _selected.x != 1:
		get_viewport().set_input_as_handled()
		_selected.x = 1
		%UIFocus.play()
		_update()
	if event.is_action_pressed(&"Accept"):
		get_viewport().set_input_as_handled()
		%UISelect.play()
		match _selected:
			Vector2i(0, 0): return fight_state
			Vector2i(1, 0): return bag_state
			Vector2i(0, 1): return switch_state
			Vector2i(1, 1): return _try_run()
	
	return null

func _update() -> void:
	for child in %CommandGrid.get_children():
		child.z_index = 0
		child.texture.region.position.x = 0.0
	
	var sel := %CommandGrid.get_child(_selected.x + (_selected.y * 2))
	sel.z_index = 1
	sel.texture.region.position.x = 130.0

func _try_run() -> BattleStateBase:
	return null
