extends Node

const FILE_LOCATION := "res://src/resources/data/moves.toml"

var flag_recompile := false
var flag_valid := true
var moves: Dictionary[String, Move]

func _init() -> void:
	if FileAccess.file_exists("user://data.res"):
		var md5 := CompiledResource.hash_file(FILE_LOCATION)
		var res: CompiledResource = load("user://data.res")
		if md5 != res.moves_hash:
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
		var move := Move.create(data)
		moves[key] = move
	validate()
	print("Loaded %d moves from file" % moves.size())

func init_compiled(data: CompiledResource) -> void:
	moves.assign(data.moves)
	print("Loaded %d moves from compiled resource" % moves.size())

func validate() -> void:
	for m: String in moves.keys():
		var errors := []
		var move: Move = moves[m]
		
		if not TypesManager.types.has(move.type):
			errors.append("Type '%s' is invalid" % move.type)
		
		if not Move.ALL_CATEGORIES.has(move.category):
			errors.append("Move category '%s' is invalid" % move.category)
		
		if move.category == "Status" and move.power > 0:
			errors.append("Status moves cannot have a power above 0")
		
		if move.power < 0:
			errors.append("Move power must be >= 0, not %d" % move.power)
		
		if move.accuracy < 0 or move.accuracy > 100:
			errors.append("Move accuracy must be >= 0 and <= 100, not %d" % move.accuracy)
		
		if move.pp <= 0:
			errors.append("Move pp must be > 0, not %d" % move.pp)
		
		if not Move.ALL_TARGETS.has(move.target):
			errors.append("Move target '%s' is invalid" % move.target)
		
		for flag in move.flags:
			if not Move.ALL_FLAGS.has(flag):
				errors.append("Move flag '%s' is invalid" % flag)
		
		# TODO: check functions
		
		if errors.size() > 0:
			flag_valid = false
			moves.erase(m)
			GameData.display_error("Error in move '%s'\n- %s" % [m, "\n- ".join(errors)], "MovesManager")
			
	if not flag_valid:
		print("MovesManager validation failure")

#region Move callbacks

## Default function. Does nothing
func nop(_manager: BattleManager, _user: Battler, _target: Battler, _field: BattleManager.Field, _user_side: BattleManager.BattleSide, _target_side: BattleManager.BattleSide) -> void:
	pass

#endregion
