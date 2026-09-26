extends BattleStateBase

func enter() -> BattleStateBase:
	manager.end_battle()
	return null
