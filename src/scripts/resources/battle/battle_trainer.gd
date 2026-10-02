class_name BattleTrainer
extends Resource

@export var trainer_id: String
@export var party: Array[Battler]

func has_valid_switch_target() -> bool:
	return party.any(func(b):return not b.is_faint())
