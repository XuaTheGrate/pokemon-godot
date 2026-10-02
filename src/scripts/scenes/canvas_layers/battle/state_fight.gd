extends BattleStateBase

## For when a move is confirmed
@export var waiting_state: BattleStateBase
## For when the selection was cancelled
@export var command_state: BattleStateBase

var _selected := Vector2i.ZERO

func enter() -> BattleStateBase:
	_init_fight_box()
	%FightBox.visible = true
	return null

func exit() -> void:
	%FightBox.visible = false

func input(event: InputEvent) -> BattleStateBase:
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
	
	if event.is_action_pressed(&"Accept"):
		# TODO: (Doubles) go to targetselect, if applicable
		var battler: Battler = %DataboxAlly.battler
		var command := create_move_command_singles(battler.moves[_selected.x + (_selected.y * 2)])
		manager.command_pool.append(command)
		%UISelect.play()
		return waiting_state
	
	if event.is_action_pressed(&"Cancel"):
		get_viewport().set_input_as_handled()
		return command_state
	return null

func create_move_command_singles(move: BattleMove) -> BattleManager.Command:
	var cmd := BattleManager.Command.new()
	cmd.type = BattleManager.CommandType.UseMove
	cmd.move = move
	cmd.user = %DataboxAlly.battler
	
	match MovesManager.moves[move.move_id].target:
		"AllBattlers":
			cmd.target_index.assign([0, 1])
		"AllAllies", "User", "UserAndAllies", "UserOrNearAlly":
			cmd.target_index.append(0)
		"RandomNearFoe", "NearFoe", "AllNearFoes", "NearOther", "Other", "AllNearOthers":
			cmd.target_index.append(1)
		"UserSide":
			cmd.target_index.append(-1)
		"FoeSide":
			cmd.target_index.append(-2)
		"BothSides":
			cmd.target_index.assign([-1, -2])
		"NearAlly":
			cmd.auto_fail = true
		"None":
			pass
		var t:
			GameData.display_error("Unknown target type '%s'" % t)
			cmd.auto_fail = true
	
	return cmd

func _init_fight_box() -> void:
	var battler := manager.get_current_battler()
	for i in 4:
		var target: TextureRect = %MovesContainer.get_child(i)
		if i >= battler.moves.size():
			target.visible = false
		else:
			var move := MovesManager.moves[battler.moves[i].move_id]
			target.visible = true
			target.get_node("MarginContainer/RichTextLabel").text = move.name
			var type := TypesManager.types[move.type]
			target.texture.region.position.y = 46.0 * type.index
	_update()

func _update() -> void:
	for child: TextureRect in %MovesContainer.get_children():
		child.texture.region.position.x = 0.0
		child.z_index = 0
	
	var index := _selected.x + (_selected.y * 2)
	var target: TextureRect = %MovesContainer.get_child(index)
	target.texture.region.position.x = target.texture.region.size.x
	var battler := manager.get_current_battler()
	var move := battler.moves[index]
	var type := TypesManager.types[MovesManager.moves[move.move_id].type]
	%MoveType.texture.region.position.y = 28.0 * type.index
	%MovePP.text = "PP: %d/%d" % [move.current_pp, move.max_pp]
