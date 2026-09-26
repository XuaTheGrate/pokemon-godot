extends Node

const MAX_LEVEL := 100
const NATURES := {
	"HARDY":   [0, 0, 0, 0, 0, 0],
	"LONELY":  [0, 1, -1, 0, 0, 0],
	"BRAVE":   [0, 1, 0, 0, 0, -1],
	"ADAMANT": [0, 1, 0, -1, 0, 0],
	"NAUGHTY": [0, 1, 0, 0, -1, 0],
	
	"BOLD":    [0, -1, 1, 0, 0, 0],
	"DOCILE":  [0, 0, 0, 0, 0, 0],
	"RELAXED": [0, 0, 1, 0, 0, -1],
	"IMPISH":  [0, 0, 1, -1, 0 ,0],
	"LAX":     [0, 0, 1, 0, -1, 0],
	
	"TIMID":   [0, -1, 0, 0, 0, 1],
	"HASTY":   [0, 0, -1, 0, 0, 1],
	"SERIOUS": [0, 0, 0, 0, 0, 0],
	"JOLLY":   [0, 0, 0, -1, 0, 1],
	"NAIVE":   [0, 0, 0, 0, -1, 1],
	
	"MODEST":  [0, -1, 0, 1, 0, 0],
	"MILD":    [0, 0, -1, 1, 0, 0],
	"QUIET":   [0, 0, 0, 1, 0, -1],
	"BASHFUL": [0, 0, 0, 0, 0, 0],
	"RASH":    [0, 0, 0, 1, -1, 0],
	
	"CALM":    [0, -1, 0, 0, 1, 0],
	"GENTLE":  [0, 0, -1, 0, 1, 0],
	"SASSY":   [0, 0, 0, 0, 1, -1],
	"CAREFUL": [0, 0, 0, -1, 1, 0],
	"QUIRKY":  [0, 0, 0, 0, 0, 0]
}

var template_party: Array[Battler] = [
	preload("res://src/resources/player/template_bulbasaur.tres")
]

var rand: RandomNumberGenerator

#region Trainer Info
var trainer_gender := 0
var trainer_name := "PLACEHOLDER"
var trainer_party: Array[Battler] = []
var trainer_money: int = 0
var save_playtime: int = 0

## This function returns the first party member that can fight
## i.e. excluding eggs and fainted party members
func get_first_party_member() -> Battler:
	for b: Battler in trainer_party:
		if not b.is_faint(): # and not b.is_egg()
			return b
	return null

func has_valid_switch_target() -> bool:
	return trainer_party.any(func(b:Battler)->bool:
		return not b.is_faint()
	)
#endregion

func _ready() -> void:
	rand = RandomNumberGenerator.new()
	
	if OS.has_feature("editor") and trainer_party.is_empty():
		trainer_party.assign(template_party)
	
	var _recompile := TypesManager.flag_recompile \
		or MovesManager.flag_recompile \
		or SpeciesManager.flag_recompile
	var _valid := TypesManager.flag_valid \
		and MovesManager.flag_valid \
		and SpeciesManager.flag_valid
	
	if _recompile:
		if not _valid:
			print("Not compiling new resource due to validation failure")
			return
		print("Compiling new data resource")
		var res := CompiledResource.new()
		res.types.assign(TypesManager.types)
		res.types_hash = CompiledResource.hash_file(TypesManager.FILE_LOCATION)
		
		res.moves.assign(MovesManager.moves)
		res.moves_hash = CompiledResource.hash_file(MovesManager.FILE_LOCATION)
		
		res.species.assign(SpeciesManager.species)
		res.species_hash = CompiledResource.hash_file(SpeciesManager.FILE_LOCATION)
		
		ResourceSaver.save(res, "user://data.res")

func display_error(text: String, title := "Alert!") -> void:
	OS.alert(text, title)
	push_error(text)
