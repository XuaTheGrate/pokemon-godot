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
	await manager.display_message("%s used %s!" % [cmd.user.display_name, move.name], 1.0, false)
	
	if cmd.auto_fail:
		await _process_command_failure()
		return
	
	for idx in cmd.target_index:
		var target := manager.get_target(idx)
		var acc := Calculator.get_accuracy(move, cmd.user, target, manager.field)
		var odds := GameData.rand.randf() * 100.0
		print("Accuracy: %f, odds: %f" % [acc, odds])
		if odds >= acc:
			await _process_move_missed(target)
			continue
		
		var faint := false
		
		if move.category != "Status":
			var crit_chance := Calculator.get_critical_chance(
				cmd.move, cmd.user, target, manager.get_side(target)
			)
			var crit := false
			if crit_chance == 1.0: crit = true
			elif crit_chance == 0.0: crit = false
			else:
				var rand := GameData.rand.randf()
				crit = rand < crit_chance
			
			var damage := Calculator.get_damage(
				cmd.move, cmd.user, target, manager.field,
				manager.get_side(cmd.user), manager.get_side(target),
				crit, false, false
			)
			
			# play attack animation
			var effectiveness := Calculator.get_effectiveness(cmd.move, cmd.user, target, manager.field)
			# play damage animation
			faint = await manager.animate_damage(target, damage)
			
			if effectiveness < 1.0:
				await manager.display_message("It wasn't very effective.", 1.0, false)
			elif effectiveness > 1.0:
				await manager.display_message("It's super effective!", 1.0, false)
			
			if crit:
				await manager.display_message("A critical hit!", 1.0, false)
		
		if faint:
			await manager.faint_target(target)
		
		var callback := move.function
		if not MovesManager.has_method(callback):
			GameData.display_error("No callback '%s' defined" % callback, "BattleManager")
			callback = "nop"
		
		print("Calling '", callback, "' for move '", cmd.move.move_id, "'")
		await MovesManager.call(callback, manager, cmd.user, target, manager.field, manager.get_side(cmd.user), manager.get_side(target))
		
		if faint:
			_next_state = force_switch_state if manager.is_battler_ally(target) else wait_foe_switch_state

func _process_item(cmd: BattleManager.Command) -> void:
	pass

func _process_switch(cmd: BattleManager.Command) -> void:
	pass

func _process_command_failure() -> void:
	await manager.display_message("But it failed!", 1.0, false)

func _process_move_missed(target: Battler) -> void:
	await manager.display_message("%s avoided the attack!" % target.display_name, 1.0, false)

func process(_delta: float) -> BattleStateBase:
	return _next_state
