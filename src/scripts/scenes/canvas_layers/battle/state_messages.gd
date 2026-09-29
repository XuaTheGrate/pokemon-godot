extends BattleStateBase

@export var command_state: BattleStateBase
@export var wait_foe_switch_state: BattleStateBase
@export var force_switch_state: BattleStateBase
@export var end_battle_state: BattleStateBase

var _next_state: BattleStateBase = null

func enter() -> BattleStateBase:
	_next_state = null
	%MessageBox.visible = true
	manager.sort_command_pool()
	process_action()
	return null

func exit() -> void:
	%MessageBox.visible = false

func process_action() -> void:
	if manager.command_pool.is_empty():
		_next_state = command_state
		return
	
	var cmd: BattleManager.Command = manager.command_pool.pop_front()
	match cmd.type:
		BattleManager.CommandType.UseMove:
			await _process_move(cmd)
		BattleManager.CommandType.UseItem:
			await _process_item(cmd)
		BattleManager.CommandType.Switch:
			await _process_switch(cmd)
	
	if _next_state == null:
		await process_action()

func _process_move(cmd: BattleManager.Command) -> void:
	var move := MovesManager.moves[cmd.move.move_id]
	
	if move.function != "TwoTurnAttack" or cmd.charged:
		await manager.display_message("%s used %s!" % [cmd.user.display_name, move.name], 1.0, false)
	
	if cmd.auto_fail:
		await _process_command_failure()
		return
	
	for idx in cmd.target_index:
		var target := manager.get_target(idx)
		
		var callback := move.function
		if not MovesManager.has_method(callback):
			GameData.display_error("No callback '%s' defined" % callback, "BattleManager")
			callback = "nop"
		
		print("Calling '", callback, "' for move '", cmd.move.move_id, "'")
		await MovesManager.call(callback, manager, cmd, target)
		
		if target.is_faint():
			_next_state = force_switch_state if manager.is_battler_ally(target) else wait_foe_switch_state

func _process_item(cmd: BattleManager.Command) -> void:
	pass

func _process_switch(cmd: BattleManager.Command) -> void:
	pass

func _process_command_failure() -> void:
	await manager.display_message("But it failed!", 1.0, false)

func process(_delta: float) -> BattleStateBase:
	return _next_state
