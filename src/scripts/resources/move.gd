class_name Move
extends Resource

const ALL_FLAGS = ["Sound", "CanMirrorMove", "Pulse", "Powder", "TramplesMinimize", "Contact", "CanProtect", "Punching", "Dance", "CannotMetronome", "Bomb", "HighCriticalHitRate", "Biting", "ThawsUser"]
const ALL_CATEGORIES = ["Physical", "Special", "Status"]
const ALL_TARGETS = [
	"NearAlly", "AllNearOthers", "UserSide", "FoeSide", "UserOrNearAlly",
	"RandomNearFoe", "NearFoe", "None", "AllNearFoes", "NearOther",
	"BothSides", "AllAllies", "Other", "User", "UserAndAllies", "AllBattlers"]

@export var name: String
@export var type: String
@export_enum("Physical", "Special", "Status") var category: String
@export_range(0, 255, 1) var power: int
@export_range(0, 100, 1) var accuracy: int
@export var pp: int
@export var target: String
@export var flags: Array[String]
@export var function: String
@export var effect_chance: int
@export var priority: int
@export var description: String
@export var animation: String = "hit_generic"

static func create(data: Dictionary) -> Move:
	var r := Move.new()
	
	r.name = data.get("name", "???")
	r.type = data.get("type", "UNDEFINED")
	r.category = data.get("category", "Status")
	r.power = data.get("power", 0)
	r.accuracy = data.get("accuracy", 0)
	r.pp = data.get("pp", 5)
	r.target = data.get("target", "None")
	r.flags.assign(data.get("flags", []))
	r.function = data.get("function", "nop")
	r.effect_chance = data.get("effect_chance", 0)
	r.priority = data.get("priority", 0)
	r.description = data.get("description", "???")
	r.animation = data.get("animation", "hit_generic")
	
	return r
