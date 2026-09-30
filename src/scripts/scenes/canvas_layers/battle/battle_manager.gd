class_name BattleManager extends CanvasLayer

enum AIFlag {
	BASIC=1,
	EVALUATE_ATTACK=2,
	EXPERT=4,
	SETUP_FIRST_TURN=8,
	RISKY=16,
	PRIORITIZE_EXTREMES=32,
	BATON_PASS=64,
	TAG_STRATEGY=128,
	CHECK_HP=256,
	WEATHER=512,
	HARRASSMENT=1024
}

enum CommandType {
	UseMove, UseItem, Switch
}

var STATUS_INDEX := PackedStringArray([
	"None", "Poison", "Burn", "Paralyze", "Freeze", "Toxic"
])

const STATUS_CURE_LINES := {
	"Sleep": "%s woke up!",
	"Poison": "%s was cured of it's poisoning!",
	"Burn": "%s was cured from it's burn!",
	"Paralyze": "%s is no longer paralyzed!",
	"Freeze": "%s is no longer frozen!",
	"Toxic": "%s was cured of it's poisoning!"
}

const STATUS_APPLY_LINES = {
	"Sleep": "%s fell asleep!",
	"Poison": "%s was poisoned!",
	"Burn": "%s was burned!",
	"Paralyze": "%s was paralyzed! It may not be able to move!",
	"Freeze": "%s was frozen solid!",
	"Toxic": "%s was badly poisoned!"
}

class Command extends RefCounted:
	var type: CommandType
	var user: Battler
	## -1: The users side[br]
	## -2: The foes side[br]
	## 0: The user[br]
	## 1: First foe[br]
	## 2: User ally[br]
	## 3: Second foe[br]
	var target_index: Array[int]
	var move: BattleMove
	var item: String
	var auto_fail := false
	# For multi turn moves, set this to true on the final turn
	var charged := false
	
	func _to_string() -> String:
		return "Command(%s, %s, %s, %s, %s, %s)" % [
			type, user, target_index, move, item, auto_fail
		]

class Field extends RefCounted:
	pass

class BattleSide extends RefCounted:
	pass

signal battle_ended(victory: bool)
signal foe_command_submitted(command: Command)
signal _input_skip

#@export var ai_battler: AIBattler

var ally_side: BattleSide
var command_pool: Array[Command] = []
var enemy_side: BattleSide
var enemy_trainer: Trainer
var field: Field
var victory := false
var wild_battle := true

var _message_paused := false
# why does 'preload' not work with the template meowth,
# but does with the template bulbasaur?
var _template_wild: Battler = load("uid://e1pgwrho2mte")

func _ready() -> void:
	if get_tree().current_scene == self:
		GameData.trainer_party.assign(GameData.template_party.duplicate(true))
		init_wild_battle(_template_wild.duplicate())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Accept") or event.is_action_pressed("Cancel"):
		if _message_paused:
			get_viewport().set_input_as_handled()
			_input_skip.emit()

func init_wild_battle(wild: Battler) -> void:
	wild_battle = true
	enemy_trainer = Trainer.new()
	enemy_trainer.party.append(wild)
	enemy_trainer.dummy_wild_trainer = true
	setup_battle()

func setup_battle() -> void:
	field = Field.new()
	ally_side = BattleSide.new()
	enemy_side = BattleSide.new()
	
	$DataboxAlly.battler = GameData.get_first_party_member()
	$DataboxEnemy.battler = enemy_trainer.party[0]
	$DataboxAlly.update()
	$DataboxEnemy.update()
	
	%EnemySprite.texture = load(SpeciesManager.get_species_front_sprite($DataboxEnemy.battler.species_id))
	%AllySprite.texture = load(SpeciesManager.get_species_back_sprite($DataboxAlly.battler.species_id))
	
	$StateManager.change_state($StateManager/Intro)
	TransitionManager.fade_out()

# TODO: DialogueManager might be able to do this better, will see
func display_message(text: String, wait_time := 0.0, input_skip := true) -> void:
	%MessageBox/Label.text = text
	if wait_time > 0.0:
		var t := get_tree().create_timer(wait_time * 2)
		t.timeout.connect(func()->void:_input_skip.emit())
	elif not input_skip:
		return
	_message_paused = true
	await _input_skip
	_message_paused = false

func get_current_battler() -> Battler:
	# TODO: For use in double battles
	return $DataboxAlly.battler

func get_target(index: int) -> Battler:
	match index:
		0: return $DataboxAlly.battler
		1: return $DataboxEnemy.battler
	return null

func is_battler_ally(battler: Battler) -> bool:
	return battler == $DataboxAlly.battler

func get_side(battler: Battler) -> BattleSide:
	if battler == $DataboxAlly.battler:
		return ally_side
	return enemy_side

func request_foe_action() -> void:
	var command := Command.new()
	command.type = CommandType.UseMove
	var user: Battler = $DataboxEnemy.battler
	command.user = user
	
	if user.queued_two_turn_move != "":
		var move_index := user.moves.find_custom(func(m):return m.move_id==user.queued_two_turn_move)
		command.move = user.moves[move_index]
		command.target_index.assign(user.queued_two_turn_targets)
		command.charged = true
		foe_command_submitted.emit(command)
		return
	
	command.move = user.moves.pick_random()
	command.target_index.assign(_get_enemy_targets(command.move))
	if command.target_index.is_empty():
		command.auto_fail = true
	foe_command_submitted.emit(command)

func sort_command_pool() -> void:
	var c := func(a: Command, b: Command) -> bool:
		if MovesManager.moves[a.move.move_id].priority > MovesManager.moves[b.move.move_id].priority:
			return true
		if MovesManager.moves[a.move.move_id].priority < MovesManager.moves[b.move.move_id].priority:
			return false
		# TODO: support other forms of speed modifiers
		return a.user.stats.speed > b.user.stats.speed
	
	command_pool.sort_custom(c)

## returns true if the target fainted, or false otherwise
func animate_damage(target: Battler, amount: int) -> bool:
	if target == $DataboxAlly.battler:
		return await $DataboxAlly.animate_damage(amount)
	else:
		return await $DataboxEnemy.animate_damage(amount)

func faint_target(target: Battler) -> void:
	# play cry
	if target == $DataboxEnemy.battler:
		%EnemySprite.visible = false
	else:
		%AllySprite.visible = false
	await get_tree().create_timer(0.5).timeout

func end_battle() -> void:
	battle_ended.emit(false)

func _get_enemy_targets(move: BattleMove) -> Array[int]:
	match MovesManager.moves[move.move_id].target:
		"AllBattlers":
			return [0, 1]
		"AllAllies", "User", "UserAndAllies", "UserOrNearAlly":
			return [1]
		"RandomNearFoe", "NearFoe", "AllNearFoes", "NearOther", "Other", "AllNearOthers":
			return [0]
		"UserSide":
			return [-2]
		"FoeSide":
			return [-1]
		"BothSides":
			return [-1, -2]
		"NearAlly":
			return []
		"None":
			return []
		var t:
			GameData.display_error("Unknown target type '%s'" % t)
			return []

func apply_status(status: String, target: Battler) -> void:
	var old_status := target.status
	target.status = status
	
	var pos := STATUS_INDEX.find(status)
	
	if target == %DataboxAlly.battler:
		%DataboxAlly/Status.visible = pos != -1
		%DataboxAlly/Status.texture.region.position.y = 16.0 * pos
	elif target == %DataboxEnemy.battler:
		%DataboxEnemy/Status.visible = pos != -1
		%DataboxEnemy/Status.texture.region.position.y = 16.0 * pos
	
	if status == "None":
		if old_status == "None": return
		var msg: String = STATUS_CURE_LINES[status] % target.display_name
		await display_message(msg, 1.0, false)
	else:
		if old_status == status: return
		var msg: String = STATUS_APPLY_LINES[status] % target.display_name
		await display_message(msg, 1.0, false)

func try_raise_stat(target: Battler, stat: String, stages: int) -> void:
	var current_stage: int = target.stat_stages.get(stat)
	var change := clampi(current_stage + stages, -6, 6)
	var actual_change = change - current_stage
	target.stat_stages.set(stat, change)
	
	var msg: String = ""
	match actual_change:
		-6, -5, -4, -3: msg = "%s's %s severely fell!"
		-2: msg = "%s's %s harshly fell!"
		-1: msg = "%s's %s fell!"
		0: msg = "%s's %s won't go any " + ("lower" if stages < 0 else "higher") + "!"
		1: msg = "%s's %s rose!"
		2: msg = "%s's %s rose sharply!"
		3, 4, 5, 6: msg = "%s's %s rose drastically!"
	await display_message(msg % [target.display_name, stat], 1.0, false)

static func generate_wild_battler(species_id: String, level: int = 20) -> Battler:
	var species: Species = SpeciesManager.species.get(species_id)
	if species == null:
		GameData.display_error("Unknown species id '%s'" % species_id)
		return null
	
	var b := Battler.new()
	b.species_id = species_id
	b.level = level
	b.nature = "HARDY"
	b.ability_index = 0
	b.ivs = Stats.new()
	b.evs = Stats.new()
	
	for l in species.level_moves:
		if l.level <= level:
			var bm := BattleMove.new()
			bm.move_id = l.move_id
			b.moves.append(bm)
	
	if b.moves.size() == 0:
		push_error("0 level moves available at level %s for species '%s'" % [level, species_id])
		var bm := BattleMove.new()
		bm.move_id = "POUND"
		b.moves.append(bm)
	
	return b
