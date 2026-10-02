extends BattleStateBase

@export var command_state: BattleStateBase
@export var end_battle_state: BattleStateBase

var _target_state: BattleStateBase = null

func enter() -> BattleStateBase:
	_target_state = null
	
	if manager.enemy_trainer.has_valid_switch_target():
		var targets: Array[Battler] = manager.enemy_trainer.party.filter(func(b:Battler)->bool:
			return not b.is_faint()
		)
		var i := GameData.rand.randi_range(0, targets.size() - 1)
		await manager.queue_enemy_switch(targets[i])
		_target_state = command_state
	else:
		manager.victory = true
		_target_state = end_battle_state
	return null

func process(_delta: float) -> BattleStateBase:
	return _target_state
