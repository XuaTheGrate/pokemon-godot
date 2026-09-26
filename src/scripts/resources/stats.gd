class_name Stats extends Resource

@export var hp: int
@export var attack: int
@export var defense: int
@export var special_attack: int
@export var special_defense: int
@export var speed: int
@export var accuracy: int
@export var evasion: int

func _to_string() -> String:
	return "Stats(HP:%d ATK:%d DEF:%d SPA:%d SPD:%d SPE:%d)" % [hp, attack, defense, special_attack, special_defense, speed]

func get_calculated(level: int, nature: String, ivs: Stats, evs: Stats) -> Stats:
	var r := Stats.new()
	
	var n: Array = GameData.NATURES[nature]
	var mod := [0.0, 1.0 + (0.1 * n[1]), 1.0 + (0.1 * n[2]), 1.0 + (0.1 * n[3]), 1.0 + (0.1 * n[4]), 1.0 + (0.1 * n[5])]
	
	r.hp = floori(((2 * hp + ivs.hp + floori(evs.hp / 4.0)) * level) / 100.0) + level + 10
	r.attack = floori((floori(((2 * attack + ivs.attack + floori(evs.attack / 4.0)) * level) / 100.0) + 5) * mod[1])
	r.defense = floori((floori(((2 * defense + ivs.defense + floori(evs.defense / 4.0)) * level) / 100.0) + 5) * mod[2])
	r.special_attack = floori((floori(((2 * special_attack + ivs.special_attack + floori(evs.special_attack / 4.0)) * level) / 100.0) + 5) * mod[3])
	r.special_defense = floori((floori(((2 * special_defense + ivs.special_defense + floori(evs.special_defense / 4.0)) * level) / 100.0) + 5) * mod[4])
	r.speed = floori((floori(((2 * speed + ivs.speed + floori(evs.speed / 4.0)) * level) / 100.0) + 5) * mod[5])
	
	return r

static func create(array: Array) -> Stats:
	var r := Stats.new()
	r.hp = array[0]
	r.attack = array[1]
	r.defense = array[2]
	r.special_attack = array[3]
	r.special_defense = array[4]
	r.speed = array[5]
	
	if array.size() > 6:
		r.accuracy = array[6]
	if array.size() > 7:
		r.evasion = array[7]
	
	return r
