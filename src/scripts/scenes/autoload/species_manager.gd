extends Node

const ALL_EGG_GROUPS = ["Amorphous", "Bug", "Ditto", "Dragon", "Fairy", "Field", "Flying", "Grass", "Humanlike", "Mineral", "Monster", "Undiscovered", "Water1", "Water2", "Water3"]
const ALL_SHAPES = ["Bipedal", "BipedalTail", "Finned", "Head", "HeadArms", "HeadBase", "HeadLegs", "Insectoid", "MultiBody", "MultiWinged", "Multiped", "Quadruped", "Serpentine", "Winged"]
const ALL_COLORS = ["Black", "Blue", "Brown", "Gray", "Green", "Pink", "Purple", "Red", "White", "Yellow"]
const ALL_GROWTH_RATES = ["Erratic", "Fast", "Fluctuating", "Medium", "Parabolic", "Slow"]
const ALL_EVO_TYPES = ["AtkDefEqual", "AttackGreater", "Beauty", "Cascoon", "DayHoldItem", "DefenseGreater", "Event", "Happiness", "HappinessDay", "HappinessMoveType", "HappinessNight", "HasInParty", "HasMove", "HoldItem", "Item", "ItemFemale", "ItemMale", "Level", "LevelDarkInParty", "LevelDay", "LevelFemale", "LevelMale", "LevelNight", "LevelRain", "LocationFlag", "NightHoldItem", "Ninjask", "None", "Shedinja", "Silcoon", "Trade", "TradeItem", "TradeSpecies"]
const ALL_GENDER_RATIO = ["AlwaysFemale", "AlwaysMale", "Female25Percent", "Female50Percent", "Female75Percent", "FemaleOneEighth", "FemaleSevenEighths", "Genderless"]

const ICON_SHINY_PATH := "res://assets/graphics/pokemon/icons_shiny/%s.png"
const ICON_DEFAULT_PATH := "res://assets/graphics/pokemon/icons/%s.png"
const FRONT_SHINY_PATH := "res://assets/graphics/pokemon/front_shiny/%s.png"
const FRONT_DEFAULT_PATH := "res://assets/graphics/pokemon/front/%s.png"
const BACK_SHINY_PATH := "res://assets/graphics/pokemon/back_shiny/%s.png"
const BACK_DEFAULT_PATH := "res://assets/graphics/pokemon/back/%s.png"

const CRY_PATH := "res://assets/audio/sounds/cries/%s.ogg"

const FILE_LOCATION := "res://src/resources/data/species.toml"

var flag_recompile := false
var flag_valid := true
var species: Dictionary[StringName, Species] = {}

func _init() -> void:
	if FileAccess.file_exists("user://data.res"):
		var md5 := CompiledResource.hash_file(FILE_LOCATION)
		var res: CompiledResource = load("user://data.res")
		if md5 != res.species_hash:
			init_new()
		else:
			init_compiled(res)
	else:
		init_new()

func init_new() -> void:
	flag_recompile = true
	var file: TOML = load(FILE_LOCATION)
	for key: StringName in file.data.keys():
		var data: Dictionary = file.data[key]
		var specie := Species.create(data)
		species[key] = specie
	validate()
	print("Loaded %d species from file" % species.size())

func init_compiled(data: CompiledResource) -> void:
	species.assign(data.species)
	print("Loaded %d species from compiled resource" % species.size())

func validate() -> void:
	for s: String in species.keys():
		var errors := []
		var specie := species[s]
		
		for t in specie.types:
			if not TypesManager.types.has(t):
				errors.append("Unknown type '%s'" % t)
		
		if specie.base_stats.accuracy > 0 or specie.base_stats.evasion > 0:
			errors.append("Cannot have accuracy or evasion as a base stat")
		
		if not ALL_GENDER_RATIO.has(specie.gender_ratio):
			errors.append("Invalid gender_ratio '%s'" % specie.gender_ratio)
		
		if not ALL_GROWTH_RATES.has(specie.growth_rate):
			errors.append("Invalid growth_rate '%s'" % specie.growth_rate)
		
		if specie.base_exp < 0:
			errors.append("base_exp must be > 0, not %d" % specie.base_exp)
		
		if specie.evs.evasion > 0 or specie.evs.accuracy > 0:
			errors.append("Cannot have accuracy or evasion ev yield")
		
		if specie.catch_rate <= 0:
			errors.append("catch_rate must be > 0, not %d" % specie.catch_rate)
		
		if specie.base_happiness < 0:
			errors.append("base_happiness must be >= 0, not %d" % specie.base_happiness)
		
		# TODO: abilities, hidden abilities
		
		for move: LevelMove in specie.level_moves:
			if not MovesManager.moves.has(move.move_id):
				errors.append("Unknown level up move id '%s'" % move.move_id)
		
		for move: String in specie.tutor_moves:
			if not MovesManager.moves.has(move):
				errors.append("Unknown tutor move id '%s'" % move)
		
		for move: String in specie.egg_moves:
			if not MovesManager.moves.has(move):
				errors.append("Unknown egg move id '%s'" % move)
		
		if specie.height <= 0.0:
			errors.append("Species height must be > 0.0, not %f" % specie.height)
		
		if specie.weight <= 0.0:
			errors.append("Species weight must be > 0.0, not %f" % specie.weight)
		
		if not ALL_COLORS.has(specie.color):
			errors.append("Invalid color '%s'" % specie.color)
		
		if not ALL_SHAPES.has(specie.shape):
			errors.append("Invalid shape '%s'" % specie.shape)
		
		for evo: Evolution in specie.evolutions:
			if not species.has(evo.species):
				errors.append("Invalid evolution species '%s'" % evo.species)
			
			match evo.type:
				# Numbers that must be between 1 and 255
				"AtkDefEqual", "AttackGreater", "Beauty", "DefenseGreater":
					if typeof(evo.extra) != TYPE_INT:
						errors.append("Invalid evolution.extra for species '%s'" % evo.species)
					if evo.extra <= 0 or evo.extra >= 255:
						errors.append("'%s'.evolution.extra must be between 1-255, not %d" % [evo.species, evo.extra])
					# Level evolutions
				"Cascoon", "Event", "Level", "LevelDarkInParty", "LevelDay", "LevelNight", "LevelMale", "LevelFemale", "LevelRain", "Ninjask", "Shedinja", "Silcoon":
					if typeof(evo.extra) != TYPE_INT:
						errors.append("Invalid evolution.extra for species '%s'" % evo.species)
					if evo.extra <= 0 or evo.extra > GameData.MAX_LEVEL:
						errors.append("'%s'.evolution.extra must be between 1-%d, not %d" % [evo.species, GameData.MAX_LEVEL, evo.extra])
				# Item related evolutions
				"DayHoldItem", "HoldItem", "Item", "ItemFemale", "ItemMale", "NightHoldItem", "TradeItem":
					if typeof(evo.extra) != TYPE_STRING:
						errors.append("Invalid evolution.extra for species '%s'" % evo.species)
					# TODO: compare against ItemsManager
				# Species related evolutions
				"HasInParty", "TradeSpecies":
					if typeof(evo.extra) != TYPE_STRING:
						errors.append("Invalid evolution.extra for species '%s'" % evo.species)
					if not species.has(evo.extra):
						errors.append("Unknown species '%s' for '%s'.evolution.extra" % [evo.extra, evo.species])
				# Type related evolutions
				"HappinessMoveType":
					if typeof(evo.extra) != TYPE_STRING:
						errors.append("Invalid evolution.extra for species '%s'" % evo.species)
					if not TypesManager.types.has(evo.extra):
						errors.append("Unknown type '%s' for '%s'.evolution.extra" % [evo.extra, evo.species])
				# Move related evolutions
				"HasMove":
					if typeof(evo.extra) != TYPE_STRING:
						errors.append("Invalid evolution.extra for species '%s'" % evo.species)
					if not MovesManager.moves.has(evo.extra):
						errors.append("Unknown move '%s' for '%s'.evolution.extra" % [evo.extra, evo.species])
				# Location related evolutions
				"LocationFlag":
					if typeof(evo.extra) != TYPE_STRING:
						errors.append("Invalid evolution.extra for species '%s'" % evo.species)
					# TODO
				# Other
				"Happiness", "HappinessDay", "HappinessNight", "None", "Trade":
					pass # just ignore extra
				_:
					errors.append("Unknown evolution type '%s' for species '%s'" % [evo.type, evo.species])
		
		if errors.size() > 0:
			flag_valid = false
			species.erase(s)
			GameData.display_error("Error in species '%s'\n- %s" % [s, "\n- ".join(errors)], "SpeciesManager")
	
	if not flag_valid:
		print("SpeciesManager validation failure")

func get_species_front_sprite(species_id: String, shiny := false) -> String:
	if shiny:
		if ResourceLoader.exists(FRONT_SHINY_PATH % species_id):
			return FRONT_SHINY_PATH % species_id
		push_warning("No shiny front sprite for '%s' found" % species_id)
	
	if ResourceLoader.exists(FRONT_DEFAULT_PATH % species_id):
		return FRONT_DEFAULT_PATH % species_id
	
	GameData.display_error("Missing front sprite for '%s'" % species_id, "SpeciesManager")
	return ""

func get_species_back_sprite(species_id: String, shiny := false) -> String:
	if shiny:
		if ResourceLoader.exists(BACK_SHINY_PATH % species_id):
			return BACK_SHINY_PATH % species_id
		push_warning("No shiny back sprite for '%s' found" % species_id)
	
	if ResourceLoader.exists(BACK_DEFAULT_PATH % species_id):
		return BACK_DEFAULT_PATH % species_id
	
	GameData.display_error("Missing back sprite for '%s'" % species_id, "SpeciesManager")
	return ""

func get_species_icon(species_id: String, shiny := false) -> String:
	if shiny:
		if ResourceLoader.exists(ICON_SHINY_PATH % species_id):
			return ICON_SHINY_PATH % species_id
		push_warning("No shiny icon for '%s' found" % species_id)
	
	if ResourceLoader.exists(ICON_DEFAULT_PATH % species_id):
		return ICON_DEFAULT_PATH % species_id
	
	GameData.display_error("Missing icon for '%s'" % species_id, "SpeciesManager")
	return ""

func get_species_ability(species_id: String, index: int) -> String:
	var s := species[species_id]
	var all_abilities := s.abilities.duplicate()
	all_abilities.append_array(s.hidden_abilities)
	return all_abilities[index]

func get_species_cry(species_id: String) -> String:
	# TODO: Add option for cry overrides?
	return CRY_PATH % species_id
