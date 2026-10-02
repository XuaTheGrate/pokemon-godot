extends Node

const TRAINER_TYPES := [
	"CAMPER", "LEADER_Brock"
]

const FILE_LOCATION := "res://src/resources/data/trainers.toml"

var flag_recompile := false
var flag_valid := true
var trainers: Dictionary[StringName, Trainer] = {}

func _init() -> void:
	if FileAccess.file_exists("user://data.res"):
		var md5 := CompiledResource.hash_file(FILE_LOCATION)
		var res: CompiledResource = load("user://data.res")
		if md5 != res.trainers_hash:
			init_new()
		else:
			init_compiled(res)
	else:
		init_new()
	
	# for internal use, don't use for actual trainers
	trainers["WILD"] = Trainer.create({
		"type": "WILD",
		"name": "WILD",
		"lose_text": "",
		"skill_level": 0,
	})

func init_new() -> void:
	flag_recompile = true
	var file: TOML = load(FILE_LOCATION)
	for key: StringName in file.data.keys():
		var data: Dictionary = file.data[key]
		var trainer := Trainer.create(data)
		trainers[key] = trainer
	validate()
	print("Loaded %d trainers from file" % trainers.size())

func init_compiled(data: CompiledResource) -> void:
	trainers.assign(data.trainers)
	print("Loaded %d trainers from compiled resource" % trainers.size())

func validate() -> void:
	for s: String in trainers.keys():
		var errors := []
		var trainer := trainers[s]
		
		if not TRAINER_TYPES.has(trainer.type):
			errors.append("Unknown trainer type '%s'" % trainer.type)
		
		for i in trainer.party.size():
			var m: TrainerPartyMember = trainer.party[i]
			if not SpeciesManager.species.has(m.species_id):
				errors.append("party[%d]: Unknown species '%s'" % [i, m.species_id])
			var specie := SpeciesManager.species[m.species_id]
			
			if m.level < 1 or m.level > GameData.MAX_LEVEL:
				errors.append("party[%d]: Level must be between 0 and %d, not %d" % [i, GameData.MAX_LEVEL, m.level])
				
			if m.nickname != "" and m.nickname.length() > GameData.MAX_NICKNAME_LENGTH:
				errors.append("party[%d]: Nickname cannot be more than %d characters" % [i, GameData.MAX_NICKNAME_LENGTH])
				
			for iv in m.ivs:
				if iv < 0 or iv > 31:
					errors.append("party[%d].ivs: IV must be between 0 and 31, not %d" % [i, iv])
					
			for ev in m.evs:
				if ev < 0 or ev > 252:
					errors.append("party[%d].evs: EV must be between 0 and 252, not %d" % [i, ev])
			
			if m.ability != -1 and m.ability >= (specie.abilities.size() + specie.hidden_abilities.size()):
				errors.append("party[%d].ability: Index out of bounds" % i)
			
			for move in m.moves:
				if not MovesManager.moves.has(move):
					errors.append("party[%d].moves: Unknown move id '%s'" % [i, move])
			
			# TODO: item
			# TODO: pokeball
		
		if errors.size() > 0:
			flag_valid = false
			trainers.erase(s)
			GameData.display_error("Error in trainer '%s'\n- %s" % [s, "\n- ".join(errors)], "TrainersManager")
	
	if not flag_valid:
		prints("TrainersManager validation failure")
