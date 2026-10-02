class_name TrainerPartyMember
extends Resource

@export var species_id: String
@export var level: int
@export var nickname: String = ""
@export var gender: int = 2
@export var ivs: Array[int] = [10, 10, 10, 10, 10, 10]
@export var evs: Array[int] = [0, 0, 0, 0, 0, 0]
@export var ability: int = -1
@export var moves: Array[String] = []
@export var item: String = ""
@export var shiny := false
@export var ball := "POKEBALL"

var generate_moves_by_level := false
var randomize_shiny := false

static func create(d: Dictionary) -> TrainerPartyMember:
	var r := TrainerPartyMember.new()
	r.species_id = d['species']
	r.level = d['level']
	
	if d.has("nickname"):
		r.nickname = d['nickname']
		
	if d.has("gender"):
		r.gender = d['gender']
		
	if d.has("ivs"):
		r.ivs.clear()
		r.ivs.assign(d['ivs'])
		
	if d.has("evs"):
		r.evs.clear()
		r.evs.assign(d['evs'])
		
	if d.has("ability"):
		r.ability = d['ability']
		
	if d.has("moves"):
		r.moves.assign(d['moves'])
	else:
		r.generate_moves_by_level = true
		
	if d.has("item"):
		r.item = d['item']
		
	if d.has("shiny"):
		r.shiny = d['shiny']
	else:
		r.randomize_shiny = true
		
	if d.has("ball"):
		r.ball = d['ball']
	return r
