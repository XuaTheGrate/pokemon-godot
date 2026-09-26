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

class Command extends RefCounted:
	var type: CommandType
	var user: Battler
	## -1: The users side
	## -2: The foes side
	## 0: The user
	## 1: First foe
	## 2: User ally
	## 3: Second foe
	var target_index: Array[int]
	var move: BattleMove
	var item: String
	var auto_fail := false
	
	func _to_string() -> String:
		return "Command(%s, %s, %s, %s, %s, %s)" % [
			type, user, target_index, move, item, auto_fail
		]

class Field extends RefCounted:
	pass

class BattleSide extends RefCounted:
	pass

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
var _template_wild: Battler = preload("res://src/resources/player/template_bulbasaur.tres")

func _ready() -> void:
	if get_parent() == get_tree().root:
		init_wild_battle(_template_wild.duplicate())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Accept") or event.is_action_pressed("Cancel"):
		if _message_paused:
			get_viewport().set_input_as_handled()
			_input_skip.emit()

func init_wild_battle(wild: Battler) -> void:
	wild_battle = true
	enemy_trainer = Trainer.new()
	enemy_trainer.party = [wild]
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

# TODO: DialogueManager might be able to do this better, will see
func display_message(text: String, wait_time := 0.0, input_skip := true) -> void:
	%MessageBox/Label.text = text
	if wait_time > 0.0:
		var t := get_tree().create_timer(wait_time)
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
	var user: Battler = $DataboxAlly.battler
	command.user = user
	command.move = user.moves.pick_random()
	command.target_index.assign(_get_enemy_targets(command.move))
	if command.target_index.is_empty():
		command.auto_fail = true
	foe_command_submitted.emit(command)

func sort_command_pool() -> void:
	var c := func(a: Command, b: Command) -> bool:
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
	pass

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

#region Move scoring

#endregion
