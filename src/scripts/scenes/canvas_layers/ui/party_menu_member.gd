extends TextureRect

@export var first := false
@export var battler: Battler

func update() -> void:
	if not first:
		texture.region.position.x = 256.0
	
	if battler == null:
		texture.region.position.x = 512.0
		$Base.visible = false
		focus_mode = Control.FOCUS_NONE
		return
	
	$Base.visible = true
	focus_mode = Control.FOCUS_ALL
	texture.region.position.x = 0.0
	%NameLabel.text = battler.display_name
	%LvNum.text = str(battler.level)
	%HPBar.max_value = battler.stats.hp
	%HPBar.value = battler.current_hp
	%HPLabel.text = "%d / %d" % [battler.stats.hp, battler.current_hp]
	%GenderMarker.theme_type_variation = &"GenderMale" if battler.gender == 0 else &"GenderFemale"
	%GenderMarker.text = "♂" if battler.gender == 0 else "♀" if battler.gender == 1 else ""
	%Icon.texture.atlas = load(SpeciesManager.get_species_icon(battler.species_id))

func _on_focus_entered() -> void:
	texture.region.position.y = 98.0
	%Ball.texture.region.position.x = 44.0
	%IconAnim.play(&"focused")

func _on_focus_exited() -> void:
	texture.region.position.y = 0.0
	%Ball.texture.region.position.x = 0.0
	%IconAnim.play(&"default")
