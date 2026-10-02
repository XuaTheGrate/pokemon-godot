class_name Trainer
extends Resource

@export var type: String
@export var name: String
@export var lose_text: String
@export var base_money: int = 0
@export var items: Array[String] = []
@export var skill_level: int = 0
@export var flags: Array[String] = []
@export var intro_bgm_override: String = ""
@export var battle_bgm_override: String = ""
@export var victory_bgm_override: String = ""

@export var party: Array[TrainerPartyMember] = []

static func create(data: Dictionary) -> Trainer:
	var t := Trainer.new()
	t.type = data["type"]
	t.name = data["name"]
	t.lose_text = data["lose_text"]
	t.base_money = data.get("base_money", 0)
	t.items.assign(data.get("items", []))
	t.skill_level = data.get("skill_level", 0)
	t.flags.assign(data.get("flags", []))
	t.intro_bgm_override = data.get("intro_bgm_override", "")
	t.battle_bgm_override = data.get("battle_bgm_override", "")
	t.victory_bgm_override = data.get("victory_bgm_override", "")
	
	for p: Dictionary in data['party']:
		t.party.append(TrainerPartyMember.create(p))
	
	return t
