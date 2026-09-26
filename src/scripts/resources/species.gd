class_name Species
extends Resource

@export var name: String
@export var types: Array[String]
@export var base_stats: Stats
@export var gender_ratio: String
@export var growth_rate: String
@export var base_exp: int
@export var evs: Stats
@export var catch_rate: int
@export var base_happiness: int
@export var abilities: Array[String]
@export var hidden_abilities: Array[String]
@export var level_moves: Array[LevelMove]
@export var tutor_moves: Array[String]
@export var egg_moves: Array[String]
@export var egg_groups: Array[String]
@export var hatch_cycles: int
@export var height: float
@export var weight: float
@export var color: String
@export var shape: String
@export var category: String
@export var pokedex: String
@export var evolutions: Array[Evolution]

static func create(data: Dictionary) -> Species:
	var r := Species.new()
	r.name = data.get("name", "???")
	r.types.append_array(data.get('types', ['UNKNOWN']))
	r.base_stats = Stats.create(data.get("base_stats", [0, 0, 0, 0, 0, 0]))
	r.gender_ratio = data.get("gender_ratio", "Genderless")
	r.growth_rate = data.get("growth_rate", "Slow")
	r.base_exp = data.get("base_exp", 0)
	r.evs = Stats.create(data.get("evs", [0, 0, 0, 0, 0, 0]))
	r.catch_rate = data.get("catch_rate", 1)
	r.base_happiness = data.get("base_happiness", 0)
	r.abilities.append_array(data.get("abilities", []))
	r.hidden_abilities.append_array(data.get("hidden_abilities", []))
	for m: Array in data['level_moves']:
		var level: int = m[0]
		var move: String = m[1]
		var l := LevelMove.create(level, move)
		r.level_moves.append(l)
	r.tutor_moves.assign(data.get("tutor_moves", []))
	r.egg_moves.assign(data.get("egg_moves", []))
	r.egg_groups.assign(data.get("egg_groups", []))
	r.hatch_cycles = data.get("hatch_cycles", 1)
	r.height = data.get("height", 0.0)
	r.weight = data.get("weight", 0.0)
	r.color = data.get("color", "White")
	r.shape = data.get("shape", "Bipedal")
	r.category = data.get("category", "???")
	r.pokedex = data.get("pokedex", "???")
	
	for evo: Array in data.get("evolutions", []):
		var species: String = evo[0]
		var type: String = evo[1]
		var extra: Variant = null
		if evo.size() > 2:
			extra = evo[2]
		r.evolutions.append(Evolution.create(species, type, extra))
	
	return r
