class_name Item
extends Resource

@export var name: Array[String] = ["???", "???"]
@export var pocket_id: int = 0
@export var price: int = 0
@export var overworld_use: String = "NONE"
@export var battle_use: String = "NONE"
@export var description: String = "???"

@export var fling: int = 0
@export var fossil: String = ""
@export var move_id: String = ""
@export var natural_gift: Array = []

@export var repel := false
@export var evolution_stone := false
@export var berry := false

static func create(data: Dictionary) -> Item:
	var i := Item.new()
	i.name.assign(data.get("name", i.name))
	i.pocket_id = data.get("pocket_id", i.pocket_id)
	i.price = data.get("price", i.price)
	i.overworld_use = data.get("overworld_use", i.overworld_use)
	i.battle_use = data.get("battle_use", i.battle_use)
	i.description = data.get("description", i.description)
	
	i.fling = data.get("fling", i.fling)
	i.fossil = data.get("fossil", i.fossil)
	i.move_id = data.get("move_id", i.move_id)
	i.natural_gift.assign(data.get("natural_gift", i.natural_gift))
	
	i.repel = data.get("repel", i.repel)
	i.evolution_stone = data.get("evolution_stone", i.evolution_stone)
	i.berry = data.get("berry", i.berry)
	return i
