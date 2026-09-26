extends TextureRect

var battler: Battler

func update() -> void:
	if battler == null: return
	
	$Name.text = battler.display_name
	
	$GenderMarker.text = "♂" if battler.gender == 0 else "♀"
	$GenderMarker.visible = battler.gender != -1
	$GenderMarker.theme_type_variation = &"GenderMale" if battler.gender == 0 else &"GenderFemale"
	
	$Level/NumHundred.visible = battler.level >= 100
	$Level/NumTen.visible = battler.level >= 10
	$Level/NumHundred.texture.region.position.x = 16.0 * floori(battler.level / 100.0)
	$Level/NumTen.texture.region.position.x = 16.0 * floori(battler.level % 100 / 10.0)
	$Level/NumOne.texture.region.position.x = 16.0 * (battler.level % 10)
	
	$HPBar.max_value = battler.stats.hp
	$HPBar.value = battler.current_hp
	
	# TODO: Caught
	$Caught.visible = false
	# TODO: Status
	$Status.visible = false
	# TODO: Shiny
	$Shiny.visible = false

func animate_damage(amount: int) -> bool:
	var old_hp := battler.current_hp
	battler._damage_sustained += amount
	var t := create_tween()
	t.tween_method(_update_hp, old_hp, battler.current_hp, 0.5)
	await t.finished
	
	return battler.is_faint()

func _update_hp(value: int) -> void:
	var perc: float = value / float(battler.stats.hp)
	$HPBar.value = value
	if perc < 0.2:
		$HPBar.texture_progress.region.position.y = 12.0
	elif perc < 0.5:
		$HPBar.texture_progress.region.position.y = 6.0
	else:
		$HPBar.texture_progress.region.position.y = 0.0
