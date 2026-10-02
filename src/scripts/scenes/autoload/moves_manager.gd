extends Node

const FILE_LOCATION := "res://src/resources/data/moves.toml"

var flag_recompile := false
var flag_valid := true
var moves: Dictionary[String, Move]

func _init() -> void:
	if FileAccess.file_exists("user://data.res"):
		var md5 := CompiledResource.hash_file(FILE_LOCATION)
		var res: CompiledResource = load("user://data.res")
		if md5 != res.moves_hash:
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
		var move := Move.create(data)
		moves[key] = move
	validate()
	print("Loaded %d moves from file" % moves.size())

func init_compiled(data: CompiledResource) -> void:
	moves.assign(data.moves)
	print("Loaded %d moves from compiled resource" % moves.size())

func validate() -> void:
	for m: String in moves.keys():
		var errors := []
		var move: Move = moves[m]
		
		if not TypesManager.types.has(move.type):
			errors.append("Type '%s' is invalid" % move.type)
		
		if not Move.ALL_CATEGORIES.has(move.category):
			errors.append("Move category '%s' is invalid" % move.category)
		
		if move.category == "Status" and move.power > 0:
			errors.append("Status moves cannot have a power above 0")
		
		if move.power < 0:
			errors.append("Move power must be >= 0, not %d" % move.power)
		
		if move.accuracy < 0 or move.accuracy > 100:
			errors.append("Move accuracy must be >= 0 and <= 100, not %d" % move.accuracy)
		
		if move.pp <= 0:
			errors.append("Move pp must be > 0, not %d" % move.pp)
		
		if not Move.ALL_TARGETS.has(move.target):
			errors.append("Move target '%s' is invalid" % move.target)
		
		for flag in move.flags:
			if not Move.ALL_FLAGS.has(flag):
				errors.append("Move flag '%s' is invalid" % flag)
		
		# TODO: check functions
		
		if errors.size() > 0:
			flag_valid = false
			moves.erase(m)
			GameData.display_error("Error in move '%s'\n- %s" % [m, "\n- ".join(errors)], "MovesManager")
			
	if not flag_valid:
		print("MovesManager validation failure")

func get_move_animation(move_id: String) -> String:
	return moves[move_id].animation

#region Move callbacks

# Some functions are seperated out to better support things like multi-hit moves
# Multi-Hit moves do not check accuracy for each individual strike
func _accuracy_check(move: Move, user: Battler, target: Battler, field: BattleManager.Field) -> bool:
	var acc := Calculator.get_accuracy(move, user, target, field)
	var odds := GameData.rand.randf() * 100.0
	print("Accuracy: %f, odds: %f" % [acc, odds])
	return odds < acc

# returns [bool, float, bool]
# [fainted?, effectiveness, critical?]
func _process_damage(manager: BattleManager, bmove: BattleMove, user: Battler, target: Battler, field: BattleManager.Field, user_side: BattleManager.BattleSide, target_side: BattleManager.BattleSide) -> Array:
	# TODO: should this be done here? maybe elsewhere idk
	var ally := manager.is_battler_ally(target)
	await manager.play_animation(get_move_animation(bmove.move_id) + ("_ally" if ally else "_foe"))
	
	var r: Array = [false, 1.0, false]
	var crit_chance := Calculator.get_critical_chance(
		bmove, user, target, target_side
	)
	var crit := false
	if crit_chance == 1.0: crit = true
	elif crit_chance == 0.0: crit = false
	else:
		var rand := GameData.rand.randf()
		crit = rand < crit_chance
	
	r[2] = crit
	var damage := Calculator.get_damage(
		bmove, user, target, field,
		user_side, target_side,
		crit, false, false
	)
	r[1] = Calculator.get_effectiveness(bmove, user, target, field)
	# play attack animation
	r[0] = await manager.animate_damage(target, damage, r[1])
	return r

# All functions should have a parameter for the following order:
# BattleManager, BattleMove, Battler, Battler, Field, BattleSide, BattleSide

func _process_move_missed(manager: BattleManager, target: Battler) -> void:
	await manager.display_message("%s avoided the attack!" % target.display_name, 1.0, false)
	
func _process_command_failure(manager: BattleManager) -> void:
	await manager.display_message("But it failed!", 1.0, false)

func _process_damage_immune(manager: BattleManager, target: Battler) -> void:
	await manager.display_message("It doesn't affect the opposing %s..." % target.display_name, 1.0, false)

## Default function. All other callbacks can call this instead of writing it's own.
func nop(manager: BattleManager, command: BattleManager.Command, target: Battler) -> void:
	var move := MovesManager.moves[command.move.move_id]
	if not _accuracy_check(move, command.user, target, manager.field):
		await _process_move_missed(manager, target)
		return
	
	var _effectiveness := Calculator.get_effectiveness(command.move, command.user, target, manager.field)
	if _effectiveness == 0.0:
		await _process_damage_immune(manager, target)
		return
	
	var faint := false
	
	if move.category != "Status":
		var ar := await _process_damage(manager, command.move, command.user, target, manager.field, manager.get_side(command.user), manager.get_side(target))
		faint = ar[0]
		var effectiveness: float = ar[1]
		var crit: bool = ar[2]
		
		if effectiveness < 1.0:
			await manager.display_message("It wasn't very effective.", 1.0, false)
		elif effectiveness > 1.0:
			await manager.display_message("It's super effective!", 1.0, false)
		
		if crit:
			await manager.display_message("A critical hit!", 1.0, false)
	
	if faint:
		await manager.faint_target(target)

## Double Slap
func HitTwoToFiveTimes(manager: BattleManager, command: BattleManager.Command, target: Battler) -> void:
	var move := MovesManager.moves[command.move.move_id]
	if not _accuracy_check(move, command.user, target, manager.field):
		await _process_move_missed(manager, target)
		return
	
	var _effectiveness := Calculator.get_effectiveness(command.move, command.user, target, manager.field)
	if _effectiveness == 0.0:
		await _process_damage_immune(manager, target)
		return
	
	var weights := PackedFloat32Array([35.0, 35.0, 15.0, 15.0])
	var hit_count := GameData.rand.rand_weighted(weights) + 2
	var actual_count := 0
	
	var faint := false
	var effectiveness := 1.0
	
	for _i in hit_count:
		prints("Hit!")
		var ar := await _process_damage(manager, command.move, command.user, target, manager.field, manager.get_side(command.user), manager.get_side(target))
		actual_count += 1
		faint = ar[0]
		
		if ar[2]: # critical
			await manager.display_message("A critical hit!", 1.0, false)
		
		if faint:
			break
	
	if effectiveness > 1.0:
		await manager.display_message("It's super effective!", 1.0, false)
	elif effectiveness < 1.0:
		await manager.display_message("It wasn't very effective.", 1.0, false)
	
	await manager.display_message("Hit %d times!" % actual_count, 1.0, false)
	
	if faint:
		await manager.faint_target(target)

## Pay Day
func AddMoneyGainedFromBattle(manager: BattleManager, command: BattleManager.Command, target: Battler) -> void:
	push_error("TODO")
	await nop(manager, command, target)
	await manager.display_message("Coins were scattered on the ground!", 1.0, false)

## Flamethrower, Will-O-Wisp
func BurnTarget(manager: BattleManager, command: BattleManager.Command, target: Battler) -> void:
	await nop(manager, command, target)
	prints(target.is_faint(), target.status)
	if target.is_faint(): return
	
	if "FIRE" in target.get_active_types():
		await _process_damage_immune(manager, target)
		return
	
	var odds := MovesManager.moves[command.move.move_id].effect_chance
	prints("Effect chance:", odds)
	
	if target.status != "None":
		if odds <= 0.0 or odds >= 100.0:
			await _process_command_failure(manager)
		return
	
	var c := false
	if odds <= 0.0 or odds >= 100.0: c = true
	else:
		var r := GameData.rand.randf() * 100.0
		c = r < odds
		prints("Roll:", r)
	prints("Applying burn:", c)
	if not c: return
	
	await manager.apply_status("Burn", target)

## Ice Beam
func FreezeTarget(manager: BattleManager, command: BattleManager.Command, target: Battler) -> void:
	await nop(manager, command, target)
	prints(target.is_faint(), target.status)
	if target.is_faint(): return
	
	if "ICE" in target.get_active_types():
		await _process_damage_immune(manager, target)
		return
	
	var odds := MovesManager.moves[command.move.move_id].effect_chance
	prints("Effect chance:", odds)
	
	if target.status != "None":
		if odds <= 0.0 or odds >= 100.0:
			await _process_command_failure(manager)
		return
	
	var c := false
	if odds <= 0.0 or odds >= 100.0: c = true
	else:
		var r := GameData.rand.randf() * 100.0
		c = r < odds
		prints("Roll:", r)
	prints("Applying freeze:", c)
	if not c: return
	
	await manager.apply_status("Freeze", target)

## Thunder Wave, Thunderbolt
func ParalyzeTarget(manager: BattleManager, command: BattleManager.Command, target: Battler) -> void:
	await nop(manager, command, target)
	prints(target.is_faint(), target.status)
	if target.is_faint(): return
	
	if "ELECTRIC" in target.get_active_types():
		await _process_damage_immune(manager, target)
		return
	
	var odds := MovesManager.moves[command.move.move_id].effect_chance
	prints("Effect chance:", odds)
	
	if target.status != "None":
		if odds <= 0.0 or odds >= 100.0:
			await _process_command_failure(manager)
		return
	
	var c := false
	if odds <= 0.0 or odds >= 100.0: c = true
	else:
		var r := GameData.rand.randf() * 100.0
		c = r < odds
		prints("Roll:", r)
	prints("Applying paralyze:", c)
	if not c: return
	
	await manager.apply_status("Paralyze", target)

## Guillotine, Fissure
func OHKO(manager: BattleManager, command: BattleManager.Command, target: Battler) -> void:
	# TODO: support for No Guard/Lock-On
	
	var effectiveness := Calculator.get_effectiveness(command.move, command.user, target, command.field)
	if effectiveness == 0.0:
		await _process_damage_immune(manager, target)
		return
	
	if command.user.level < target.level:
		await _process_command_failure(manager)
		return
	
	var move := MovesManager.moves[command.move.move_id]
	var base := move.accuracy
	var chance: int = (command.user.level - target.level) + base
	var roll := GameData.rand.randf() * 100.0
	prints("Chance:", chance, "Roll:", roll)
	if roll >= chance:
		await _process_command_failure(manager)
		return
	
	await manager.animate_damage(target, target.current_hp)
	await manager.display_message("It's a one-hot KO!", 1.0, false)
	await manager.faint_target(target)

## Razor Wind
func TwoTurnAttack(manager: BattleManager, command: BattleManager.Command, target: Battler) -> void:
	prints(command.charged, command.user.queued_two_turn_move, manager.is_battler_ally(command.user))
	if command.charged:
		prints("Command charged, clearing")
		command.user.queued_two_turn_move = ""
		command.user.queued_two_turn_targets.clear()
		
		await nop(manager, command, target)
		return
	
	command.user.queued_two_turn_move = command.move.move_id
	command.user.queued_two_turn_targets.assign(command.target_index)
	await manager.display_message("%s whipped up a whirlwind!" % command.user.display_name, 1.0, false)

## Swords Dance
func RaiseUserAttack2(manager: BattleManager, command: BattleManager.Command, target: Battler) -> void:
	await manager.try_raise_stat(command.user, "attack", 2)
#endregion
