extends BattleStateBase

@export var messages_state: BattleStateBase

var _foe_command: BattleManager.Command = null

func enter() -> BattleStateBase:
	_foe_command = null
	 # TODO: different logic for network battles
	manager.request_foe_action()
	return null

func _on_battle_manager_foe_command_submitted(command: BattleManager.Command) -> void:
	print("RECEIVED ", command)
	_foe_command = command
	manager.command_pool.append(_foe_command)

func process(_delta: float) -> BattleStateBase:
	if _foe_command != null:
		print("RETURN MESSAGES")
		return messages_state
	print("RETURN NONE")
	return null
