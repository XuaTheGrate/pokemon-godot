class_name Type extends Resource

@export var name: String
@export var index: int
@export var weaknesses: Array[String]
@export var resistances: Array[String]
@export var immunities: Array[String]

static func create(data: Dictionary) -> Type:
	var r := Type.new()
	r.name = data.get("name", "???")
	r.index = data.get("index", -1)
	r.weaknesses.assign(data.get("weaknesses", []))
	r.resistances.assign(data.get("resistances", []))
	r.immunities.assign(data.get("immunities", []))
	return r
