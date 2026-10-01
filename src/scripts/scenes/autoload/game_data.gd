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

const OPTIONS_FILE := "user://options.tres"

const TEXT_SPEED := [4/80.0, 2/80.0, 1/80.0, 0.0]

const RESOLUTION_BASE := Vector2i(512, 384)
const RESOLUTION_SCALE := [0.5, 1.0, 1.5, 2.0]

var template_party: Array[Battler] = [
	preload("res://src/resources/player/template_bulbasaur.tres")
]

var rand: RandomNumberGenerator

var options: OptionsResource

#region Trainer Info
var trainer_gender := 0
var trainer_name := "PLACEHOLDE"
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
		
		ResourceSaver.save(res, "user://data.res", ResourceSaver.FLAG_COMPRESS)
	
	_load_options()

func _load_options() -> void:
	if ResourceLoader.exists(OPTIONS_FILE, "OptionsResource"):
		options = ResourceLoader.load(OPTIONS_FILE)
	else:
		options = OptionsResource.new()
	
	AudioServer.set_bus_volume_linear(1, options.music_volume / 100.0)
	AudioServer.set_bus_volume_linear(2, options.se_volume / 100.0)
	
	if options.screen_size != 4:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var size: Vector2i = RESOLUTION_BASE * RESOLUTION_SCALE[options.screen_size]
		DisplayServer.window_set_size(size)
		var screen_index := DisplayServer.get_keyboard_focus_screen()
		var new_size := DisplayServer.screen_get_size(screen_index)
		new_size -= size
		new_size /= 2
		DisplayServer.window_set_position(new_size)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func display_error(text: String, title := "Alert!") -> void:
	OS.alert(text, title)
	push_error(text)
