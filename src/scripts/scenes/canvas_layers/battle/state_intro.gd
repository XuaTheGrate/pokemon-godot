extends BattleStateBase

@export var player: AnimationPlayer
@export var command_state: BattleStateBase

func enter() -> BattleStateBase:
	return command_state

func exit() -> void:
	%MessageBox.visible = false

func _play_enemy_cry() -> void:
	pass
