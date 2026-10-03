extends BattleStateBase

@export var command_state: BattleStateBase

var _return: BattleStateBase = null

func enter() -> BattleStateBase:
	%AnimationPlayer.play(&"opening_wild")
	return null

func exit() -> void:
	%MessageBox.visible = false

func process(_delta: float) -> BattleStateBase:
	return _return

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	var wild := manager.enemy_trainer.party[0].display_name
	var player := GameData.get_first_party_member().display_name
	if anim_name == &"opening_wild":
		await manager.display_message("Oh! A wild %s appeared!" % wild, 3.0, true)
		manager.display_message("Go! %s!" % player, 0.0, false)
		%AnimationPlayer.play(&"opening_player_send")
	elif anim_name == &"opening_player_send":
		_return = command_state
