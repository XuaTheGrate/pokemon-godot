extends Node

const CRITICAL_RATIO: Array[float] = [
	1/24.0,
	1/8.0,
	1/2.0,
	1.0
]

const ABILITIES_CANCEL_CRIT: Array[String] = [
	"BATTLEARMOR", "SHELLARMOR"
]

const MOVES_ALWAYS_CRIT: Array[String] = [
	"STORMTHROW", "FROSTBREATH"
]

func proundf(f: float) -> float:
	if f >= 0.5: return ceilf(f)
	return floorf(f)

func proundi(f: float) -> int:
	if f >= 0.5: return ceili(f)
	return floori(f)

func chain_modifiers(mods: Array[int]) -> int:
	var old := 4096.0
	for m in mods:
		old = roundf((old * m) / 4096.0)
	return roundi(old)

func get_accuracy(move: Move, user: Battler, target: Battler, field: BattleManager.Field) -> int:
	if move.accuracy == 0: return 100
	# Gravity
	
	# Tangled Feet
	# Hustle
	# Sand Veil
	# Snow Cloak
	# Victory Star
	# Compound Eyes
	
	# Bright Powder
	# Lax Incense
	# Wide Lens
	# Zoom Lens
	var modifier := 4096.0 / 4096.0
	
	# Accuracy/evasion stages
	var stage_sum := clampi(user.stat_stages.accuracy + (-target.stat_stages.evasion), -6, 6)
	var stage := 1.0
	if stage_sum < 0:
		stage = 3.0 / (3.0 + (-stage_sum))
	if stage_sum > 0:
		stage = (3.0 + stage_sum) / 3.0
	
	# Micle berry
	var micle := 1.0
	
	var m := move.accuracy * modifier * stage * micle
	return roundi(m)

func get_speed_modifiers(battler: Battler, field: BattleManager.Field, side: BattleManager.BattleSide, move_calc := false) -> int:
	var base := battler.stats.speed
	var boost := 1.0
	if battler.stat_stages.speed < 0:
		boost = (2.0 / (2.0 + -battler.stat_stages.speed))
	elif battler.stat_stages.speed > 0:
		boost = (2.0 + battler.stat_stages.speed) / 2.0
	base = floori(base * boost)
	if base >= 65536:
		base %= 65536
	
	var mods: Array[int] = []
	
	var ability := SpeciesManager.get_species_ability(battler.species_id, battler.ability_index)
	match ability:
		"CHLOROPHYLL":
			# TODO: check field weather
			pass
		"SWIFTSWIM":
			pass
		"SANDRUSH":
			pass
		"SLUSHRUSH":
			pass
		"SURGESURFER":
			# TODO: check field terrain
			pass
		"UNBURDEN":
			# TODO: check if held item was consumed
			pass
		"QUICKFEET":
			if battler.status != "None":
				mods.append(6144)
		"SLOWSTART":
			# TODO
			pass
	
	# Quick Powder (if non-transformed Ditto)
	# Choice Scarf
	# Iron Ball / Macho Brace / Power EV items
	# Tailwind
	# Pledge Swamp
	
	base = proundi((base * chain_modifiers(mods)) / 4096.0)
	
	if battler.status == "Paralyze" and ability != "QUICKFEET":
		base = floori(base * 0.5)
	
	if base >= 65536:
		base %= 65536
	if base > 10000:
		base = 10000
	
	if move_calc:
		return base
	
	# Trick Room
	# base = 10000 - base
	
	if base >= 8192:
		base -= 8192
	
	return base

func get_weight_modifiers(battler: Battler) -> float:
	var base := SpeciesManager.species[battler.species_id].weight
	# Autotomize
	# base = maxf(base - (100 * battler.autotomize_count), 0.1)
	var ability := SpeciesManager.get_species_ability(battler.species_id, battler.ability_index)
	if ability  == "HEAVYMETAL":
		base *= 2.0
	
	# Light Metal/Float stone
	
	return snappedf(base, 0.1)

func get_move_power(move: BattleMove, user: Battler, target: Battler, field: BattleManager.Field, user_side: BattleManager.BattleSide, target_side: BattleManager.BattleSide) -> int:
	var ref := MovesManager.moves[move.move_id]
	var power := maxi(ref.power, 1)
	
	match move.move_id:
		"GYROBALL":
			pass
		"ELECTROBALL":
			pass
		"LOWKICK", "GRASSKNOT":
			pass
		"HEAVYSLAM", "HEATCRASH":
			pass
		"ERUPTION", "WATERSPOUT":
			pass
		"FLAIL", "REVERSAL":
			pass
		"CRUSHGRIP", "WRINGOUT":
			pass
		"RETURN":
			pass
		"FRUSTRATION":
			pass
		"FURYCUTTER":
			pass
		"ROLLOUT", "ICEBALL":
			pass
		"SPITUP":
			pass
		"STOREDPOWER", "POWERTRIP":
			pass
		"PUNISHMENT":
			pass
		"ACROATICS":
			pass
		"ASSURANCE":
			pass
		"AVALANCHE", "REVENGE":
			pass
		"GRASSPLEDGE", "FIREPLEDGE", "WATERPLEDGE":
			pass
		"GUST", "TWISTER":
			pass
		"HEX":
			pass
		"PAYBACK":
			pass
		"PURSUIT":
			pass
		"ROUND":
			pass
		"SMELLINGSALTS":
			pass
		"STOMPINGTANTRUM":
			pass
		"WAKEUPSLAP":
			pass
		"WEATHERBALL":
			pass
		"WATERSHURIKEN":
			pass
		"FLING":
			pass
		"NATURALGIFT":
			pass
		"BEATUP":
			pass
		"ECHOEDVOICE":
			pass
		"HIDDENPOWER":
			pass
		"MAGNITUDE":
			pass
		"PRESENT":
			pass
		"TRIPLEKICK":
			pass
		"TRUMPCARD":
			pass
	
	var mods: Array[int] = []
	
	# Aura Break
	# Rivalry
	# Galvanize, Aerilate, Pixilate, Refrigerate, Normalize, Iron Fist, Reckless
	# Battery
	# Sheer Force, Sand Force, Analytic, Tough Claws
	# Fairy Aura, Dark Aura
	# Technician, Flare Boost, Toxic Boost, Strong Jaw, Mega Launcher
	# Heatproof
	# Dry Skin
	# Muscle Band, Wise Glasses
	# Plate/Type boosting items/incenses
	# Adamant, Lustrous, Griseous Orbs
	# Soul Dew
	# Normal Gem
	# Solar Beam, Solar Blade
	# Me First
	# Knock Off
	# Helping Hand
	# Charge
	# Facade, Brine, Venoshock, Retaliate, Fusion Bolt / Fusion Flare
	# Grassy Terrain, Misty Terrain (defense)
	# Electric Terrain, Grassy Terrain, Psychic Terrain (offense)
	# Mud Sport, Water Sport
	
	power = proundi((power * chain_modifiers(mods)) / 4096.0)
	if power < 1:
		power = 1
	if power >= 65536:
		power %= 65536
	
	return power

func get_attack_modifiers(user: Battler, target: Battler, special := false, critical := false, foul_play := false) -> int:
	var base := user.stats.special_attack if special else user.stats.attack
	if foul_play:
		base = target.stats.special_attack if special else target.stats.attack
	
	if SpeciesManager.get_species_ability(target.species_id, target.ability_index) != "UNAWARE":
		var stages := target.stat_stages if foul_play else user.stat_stages
		if special:
			if stages.special_attack < 0 and not critical:
				base = floori(base * (2.0 / (2.0 + -stages.special_attack)))
			elif stages.special_attack > 0:
				base = floori(base * ((2.0 + stages.special_attack) / 2.0))
		else:
			if stages.attack < 0 and not critical:
				base = floori(base * (2.0 / (2.0 + -stages.attack)))
			elif stages.attack > 0:
				base = floori(base * ((2.0 + stages.attack) / 2.0))
	
	if base >= 65536:
		base %= 65536
	
	# Hustle, handled outside of regular chain modifiers
	
	var mods: Array[int] = []
	# Slow Start, Defeatist
	# Flower Gift
	# Guts, Overgrow, Blaze, Torrent, Swarm, Flash Fire, Solar Power, Plus, Minus, Steelworker
	# Huge Power, Pure Power, Water Bubble, Stakeout
	# Thick Fat, Water Bubble
	# Choice Band, Choice Specs
	# Thick Club, Deep Sea Tooth, Light Ball
	base = proundi((base * chain_modifiers(mods)) / 4096.0)
	if base < 1:
		base = 1
	if base >= 65536:
		base %= 65536
	
	return base

func get_defense_modifiers(target: Battler, user: Battler, field: BattleManager.Field, special := false, critical := false, unaware := false, psyshock := false, wonder_room := false) -> int:
	var base: int
	if psyshock and wonder_room:
		base = target.stats.special_defense
	elif psyshock:
		base = target.stats.defense
	elif wonder_room:
		base = target.stats.defense if special else target.stats.special_defense
	else:
		base = target.stats.special_defense if special else target.stats.defense
	
	if not unaware:
		var stages := target.stat_stages
		if special and not psyshock:
			if stages.special_defense < 0:
				base = floori(base * (2.0 / (2.0 + -stages.special_defense)))
			elif stages.special_defense > 0 and not critical:
				base = floori(base * ((2.0 + stages.special_defense) / 2.0))
		else:
			if stages.defense < 0:
				base = floori(base * (2.0 / (2.0 + -stages.defense)))
			elif stages.defense > 0 and not critical:
				base = floori(base * ((2.0 + stages.defense) / 2.0))
	
	var target_spdef := (psyshock and wonder_room) or (wonder_room and not special) or special
	# handle rock type spdef boost in sandstorm
	
	var mods: Array[int] = []
	# Flower Gift
	# Marvel Scale, Grass Pelt
	# Fur Coat
	# Eviolite, Assault Vest
	# Deep Sea Scale, Metal Powder
	base = proundi((base * chain_modifiers(mods)) / 4096.0)
	if base < 1: base = 1
	if base >= 65536: base %= 65536
	return base

func get_critical_chance(move: BattleMove, user: Battler, target: Battler, target_side: BattleManager.BattleSide) -> float:
	var target_ability := SpeciesManager.get_species_ability(target.species_id, target.ability_index)
	if ABILITIES_CANCEL_CRIT.has(target_ability): return 0.0
	# if target_side.lucky_chant_turns > 0: return 0.0
	
	if MOVES_ALWAYS_CRIT.has(move.move_id): return 1.0
	# if user.is_laser_focused: return 1.0
	var user_ability := SpeciesManager.get_species_ability(user.species_id, user.ability_index)
	if user_ability == "MERCILESS" and target.status_is_poison(): return 1.0
	
	var move_ref := MovesManager.moves[move.move_id]
	var stage := 0
	if "HighCriticalHitRate" in move_ref.flags:
		stage += 1
	# Holding Scope Lens / Razor Claw
	if user_ability == "SUPERLUCK":
		stage += 1
	# 10,000,000 volt thunderbolt
	# Stick/Lucky Punch
	# Focus Energy, Z-Foresight, Z-Sleep Talk, Z-Tailwind, Z-Acupressure, Z-Heart Swap, Lansat Berry
	if stage >= CRITICAL_RATIO.size(): return 1.0
	return CRITICAL_RATIO[stage]

func get_effectiveness(move: BattleMove, user: Battler, target: Battler, field: BattleManager.Field) -> float:
	var move_ref := MovesManager.moves[move.move_id]
	var target_species := SpeciesManager.species[target.species_id]
	var user_ability := SpeciesManager.get_species_ability(user.species_id, user.ability_index)
	var matchup := 1.0
	
	# if target.held_item == "IRONBALL" and target_species.types.has("FLYING") and not target.is_grounded:
	# return 1.0
	
	# if move.move_id == "THOUSANDARROWS" and target_species.types.has("FLYING") and not target.is_grounded:
	# return 1.0
	
	var n := 1
	var d := 1
	for t in target_species.types:
		var dtype := TypesManager.types[t]
		if dtype.weaknesses.has(move_ref.type):
			# if not field.strong_winds
			n += 1
		elif dtype.resistances.has(move_ref.type):
			if move.move_id == "FREEZEDRY" and t == "WATER":
				n += 1
			else:
				d += 1
		elif dtype.immunities.has(move_ref.type):
			# if target.held_item == "RINGTARGET"
			if user_ability == "SCRAPPY" and (move_ref.type == "NORMAL" or move_ref.type == "FIGHTING") and t == "GHOST":
				pass
			else:
				matchup = 0.0
	
	if move.move_id == "FLYINGPRESS":
		for t in target_species.types:
			var dtype := TypesManager.types[t]
			if dtype.weakness.has("FLYING"):
				n += 1
			elif dtype.resistances.has("FLYING"):
				d += 1
			elif dtype.immunities.has("FLYING"):
				# if target.held_item == "RINGTARGET"
				matchup = 0.0
	
	if matchup == 0.0: return 0.0
	return (1 << n) / float(1 << d)

func get_final_modifiers(move: BattleMove, user: Battler, target: Battler, target_side: BattleManager.BattleSide, effectiveness: float, critical := false, doubles := false, friend_guard := false) -> Array[int]:
	# Screens
	var mods: Array[int] = []
	var move_ref := MovesManager.moves[move.move_id]
	var user_ability := SpeciesManager.get_species_ability(user.species_id, user.ability_index)
	var target_ability := SpeciesManager.get_species_ability(target.species_id, target.ability_index)
	if user_ability == "NEUROFORCE" and effectiveness > 1.0:
		mods.append(5120)
	if user_ability == "SNIPER" and critical:
		mods.append(6144)
	if user_ability == "TINTEDLENS" and effectiveness < 1.0:
		mods.append(8192)
	if target_ability == "MULTISCALE" or target_ability == "SHADOWSHIELD":
		if target.current_hp == target.stats.hp:
			mods.append(2048)
	if "Contact" in move_ref.flags and target_ability == "FLUFFY":
		mods.append(2048)
	if friend_guard:
		mods.append(3072)
	if target_ability == "SOLIDROCK" or target_ability == "FILTER" or target_ability == "PRISMARMOR":
		mods.append(3072)
	# Metronome
	if move_ref.type == "FIRE" and target_ability == "FLUFFY":
		mods.append(8192)
	# Expert Belt
	# Life Orb
	# Resistance Berries
	# Double Damage moves
	return mods

## Calculate damage
## - move: The move to calculate
## - user: The Pokémon using the move
## - target: The target Pokémon
## - field: The battle field
## - user_side: The user's side data
## - target_side: The target's side data
## - multi_target: Whether this move is targetting multiple Pokémon (double+ battles only)
## - parental_bond: Whether this is the SECOND hit of a Parental Bond user
func get_damage(
	move: BattleMove,
	user: Battler,
	target: Battler,
	field: BattleManager.Field,
	user_side: BattleManager.BattleSide,
	target_side: BattleManager.BattleSide,
	critical := false,
	multi_target := false,
	parental_bond := false
) -> int:
	var move_ref := MovesManager.moves[move.move_id]
	
	var base := get_move_power(move, user, target, field, user_side, target_side)
	var atk := get_attack_modifiers(user, target, move_ref.category == "Special", critical, move.move_id == "FOULPLAY")
	
	var user_ability := SpeciesManager.get_species_ability(user.species_id, user.ability_index)
	var unaware := user_ability == "UNAWARE" or move.move_id == "SACREDSWORD" or move.move_id == "CHIPAWAY"
	var psyshock := move.move_id == "PSYSHOCK" or move.move_id == "PSYSTRIKE" or move.move_id == "SECRETSWORD"
	var wonder_room := false # TODO
	var def := get_defense_modifiers(target, user, field, move_ref.category == "Special", critical, unaware, psyshock, wonder_room)
	
	base = floori(floori((floori(((2*user.level)/5.0)+2)*base*atk)/float(def))/50.0)+2
	
	if multi_target:
		base = proundi(base * (3072/4096.0))
	
	if parental_bond:
		base = proundi(base * (1024/4096.0))
	
	# Weather check
	
	if critical:
		base = proundi(base * (6144/4096.0))
	
	var rand := GameData.rand.randi_range(0, 15)
	base = floori((base * (100 - rand)) / 100.0)
	
	if SpeciesManager.species[user.species_id].types.has(move_ref.type):
		if user_ability == "ADAPTABILITY":
			base = proundi(base * (8192/4096.0))
		else:
			base = proundi(base * (6144/4096.0))
	
	var effectiveness := get_effectiveness(move, user, target, field)
	base = floori(base * effectiveness)
	
	if user.status == "Burn" and move_ref.category == "Physical":
		if move.move_id != "FACADE" and user_ability != "GUTS":
			base = proundi(base * (2048/4096.0))
	
	base = proundi((base * chain_modifiers(get_final_modifiers(move, user, target, target_side, effectiveness, critical, false, false))) / 4096.0)
	return base
