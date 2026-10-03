extends Node

const FILE_LOCATION := "res://src/resources/data/items.toml"

const OVERWORLD_USES = ["TR", "HM", "TM", "OnPokemon", "Direct", "OnMove", "NONE"]
const BATTLE_USES = ["OnFoe", "OnPokemon", "OnMove", "Direct", "OnBattler", "NONE"]

var flag_recompile := false
var flag_valid := true
var items: Dictionary[StringName, Item] = {}

func _init() -> void:
	if FileAccess.file_exists("user://data.res"):
		var md5 := CompiledResource.hash_file(FILE_LOCATION)
		var res: CompiledResource = load("user://data.res")
		if md5 != res.items_hash:
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
		var item := Item.create(data)
		items[key] = item
	validate()
	print("Loaded %d items from file" % items.size())

func init_compiled(data: CompiledResource) -> void:
	items.assign(data.items)
	print("Loaded %d items from compiled resource" % items.size())

func validate() -> void:
	for s: String in items.keys():
		var errors := []
		var item := items[s]
		
		if item.name.size() != 2:
			errors.append("name must be array of two items, one singular and one plural")
		
		if item.pocket_id < 0 or item.pocket_id > 7:
			errors.append("pocket_id must be between 0 and 7")
		
		if item.price < 0:
			errors.append("price cannot be below 0")
		
		if not OVERWORLD_USES.has(item.overworld_use):
			errors.append("Unknown overworld_use '%s'" % item.overworld_use)
		
		if not BATTLE_USES.has(item.battle_use):
			errors.append("Unknown battle_use '%s'" % item.battle_use)
		
		if item.fling < 0:
			errors.append("fling cannot be blow 0")
		elif item.fling > 0 and item.pocket_id == 7:
			errors.append("Key items cannot have a fling value (they cannot be held)")
		
		if item.fossil != "":
			if not SpeciesManager.species.has(item.fossil):
				errors.append("Unknown fossil species '%s'" % item.fossil)
		
		if item.move_id != "":
			if not ["TM", "HM", "TR"].has(item.overworld_use):
				errors.append("Only TRs, TMs and HMs can have a move_id")
			if not MovesManager.moves.has(item.move_id):
				errors.append("Unknown move_id '%s'" % item.move_id)
		
		if item.natural_gift.size() > 0:
			if item.natural_gift.size() != 2:
				errors.append("natural_gift must be an array of two elements: [TYPE:str, power:int]")
			else:
				if typeof(item.natural_gift[0]) != TYPE_STRING:
					errors.append("natural_gift[0]: must be a str")
				elif typeof(item.natural_gift[1]) != TYPE_INT:
					errors.append("natural_gift[1]: must be an int")
				else:
					if not TypesManager.types.has(item.natural_gift[0]):
						errors.append("natural_gift[0]: unknown type '%s'" % item.natural_gift[0])
					if item.natural_gift[1] < 1:
						errors.append("natural_gift[1]: must be at least 1")
		
		# TODO: check for valid berry plants?
		
		if errors.size() > 0:
			flag_valid = false
			items.erase(s)
			GameData.display_error("Error in item '%s'\n- %s" % [s, "\n- ".join(errors)], "ItemsManager")
	
	if not flag_valid:
		prints("ItemsManager validation failure")

func get_pocket_items(pocket_id: int) -> Array[String]:
	return items.keys().filter(func(i):
		return items[i].pocket_id == pocket_id
	)
