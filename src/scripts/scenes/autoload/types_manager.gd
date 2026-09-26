extends Node

const FILE_LOCATION := "res://src/resources/data/types.toml"

var flag_recompile := false
var flag_valid := true
var types: Dictionary[String, Type]

func _init() -> void:
	if FileAccess.file_exists("user://data.res"):
		var md5 := CompiledResource.hash_file(FILE_LOCATION)
		var res: CompiledResource = load("user://data.res")
		if md5 != res.types_hash:
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
		var type := Type.create(data)
		types[key] = type
	validate()
	print("Loaded %d types from file" % types.size())

func init_compiled(data: CompiledResource) -> void:
	types.assign(data.types)
	print("Loaded %d types from compiled resource" % types.size())

func validate() -> void:
	for t: String in types.keys():
		var errors := []
		var type: Type = types[t]
		for w: String in type.weaknesses:
			if w not in types:
				errors.append("Weakness Type '%s' was not found in keys" % w)
		for r: String in type.resistances:
			if r not in types:
				errors.append("Resistance Type '%s' was not found in keys" % r)
		for i: String in type.immunities:
			if i not in types:
				errors.append("Immunity Type '%s' was not found in keys" % i)
		if errors:
			flag_valid = false
			types.erase(t)
			GameData.display_error("Error(s) with type '%s'\n- %s" % [t, '\n- '.join(errors)], "TypesManager")
	if not flag_valid:
		print("TypesManager validation failure")
