class_name Battler
extends Resource

@export var species_id: String
@export var nickname: String
@export var moves: Array[BattleMove]
@export var level: int
@export var nature: String
@export var ability_index: int # TODO
@export var ivs: Stats
@export var evs: Stats
@export var gender: int
@export_enum("None", "Sleep", "Burn", "Paralyze", "Frozen", "Poison", "Toxic") var status: String = "None"

var display_name: String:
	get: return nickname if nickname != "" else SpeciesManager.species[species_id].name

var _damage_sustained := 0

var stats: Stats:
	get: # TODO
		return SpeciesManager.species[species_id].base_stats.get_calculated(level, nature, ivs, evs)

var current_hp: int:
	get: return maxi(stats.hp - _damage_sustained, 0)

#region Volatile battle data
# clears after battle
var stat_stages: Stats
var queued_two_turn_move: String = ""
var queued_two_turn_targets: Array[int] = []
#endregion

func _init() -> void:
	stat_stages = Stats.new()

# TODO: Support for Forest's Curse
func get_active_types() -> Array[String]:
	return SpeciesManager.species[species_id].types

func is_faint() -> bool:
	return current_hp == 0

func status_is_poison() -> bool:
	return status == "Poison" or status == "Toxic"
