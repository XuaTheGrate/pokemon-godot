extends BattleStateBase

@export var command_state: BattleStateBase
@export var end_battle_state: BattleStateBase

var _target_state: BattleStateBase = null

func enter() -> BattleStateBase:
	# display the switch ui then await an input
	_target_state = end_battle_state
	return null

func process(_delta: float) -> BattleStateBase:
	return _target_state
