# Maybe update the player trainer to also work in this class instead of GameData?
class_name Trainer
extends Resource

@export var trainer_name: String
@export var cls: String
@export var party: Array[Battler]
@export var reward_money: int

var dummy_wild_trainer := false

# TODO: make sure eggs don't count
func has_valid_switch_target() -> bool:
	return party.any(func(b:Battler)->bool:
		return not b.is_faint()
	)
