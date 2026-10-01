extends UIState

const THEME_UNSELECTED = &""
const THEME_SELECTED = &"YellowLabel"
const THEME_VALUE_SELECTED = &"RedLabel2"

const OPTIONS_FILE := "user://options.tres"

@export_file("*.tscn") var main_menu: String
@export var return_state: UIState

var option_descriptions: Array[String]:
	get: return [
		tr("Adjust the volume of the background music."),
		tr("Adjust the volume of sound effects."),
		tr("Choose the speed at which text appears."),
		tr("Choose whether you wish to see move animations in battle."),
		tr("Choose whether you can switch Pokémon when an opponent's Pokémon faints."),
		tr("Choose your movement speed. Hold Cancel while moving to move at the other speed."),
		tr("Choose whether caught Pokémon are sent to your Boxes when your party is full."),
		tr("Choose whether you can give a nickname to a Pokémon when you obtain it."),
		tr("Choose the appearance of dialogue boxes."),
		tr("Choose the appearance of menu boxes."),
		tr("Choose how you want to enter text."),
		tr("Choose the size of the game window."),
		tr("Close the screen.")
	]

var current: HBoxContainer:
	get: return %OptionsList.get_child(index)

var index := 0

var options: OptionsResource = null

func _ready() -> void:
	if get_tree().current_scene == self:
		_load_options_resource()
		update()
		TransitionManager.fade_out()

func enter(_default := false) -> void:
	_load_options_resource()
	update()
	TransitionManager.fade_out()
	visible = true

func exit(_default := false) -> void:
	TransitionManager.fade_in()
	ResourceSaver.save(options, OPTIONS_FILE)
	await TransitionManager.animation_finished
	visible = false

func _load_options_resource() -> void:
	if ResourceLoader.exists(OPTIONS_FILE, "OptionsResource"):
		options = ResourceLoader.load(OPTIONS_FILE)
	else:
		options = OptionsResource.new()

func _input(event: InputEvent) -> void:
	if TransitionManager.transitioning: return
	
	if get_tree().current_scene == self:
		var s := input(event)
		if s == self:
			_quit()

func input(event: InputEvent) -> UIState:
	if event.is_action_pressed(&"Down"):
		get_viewport().set_input_as_handled()
		$UISelect.play()
		index = wrapi(index + 1, 0, %OptionsList.get_child_count())
		update()
	if event.is_action_pressed(&"Up"):
		get_viewport().set_input_as_handled()
		$UISelect.play()
		index = wrapi(index - 1, 0, %OptionsList.get_child_count())
		update()
	if event.is_action_pressed(&"Cancel"):
		get_viewport().set_input_as_handled()
		$UIClose.play()
		return _get_return_state()
	if event.is_action_pressed(&"Accept") and current.name == "Close":
		get_viewport().set_input_as_handled()
		$UIClose.play()
		return _get_return_state()
	
	if event.is_action_pressed(&"Left"):
		get_viewport().set_input_as_handled()
		decrement()
		update()
	if event.is_action_pressed(&"Right"):
		get_viewport().set_input_as_handled()
		increment()
		update()
	
	return null

func _get_return_state() -> UIState:
	if return_state == null and get_tree().current_scene == self:
		return self
	return return_state

func _quit() -> void:
	var c := get_tree().change_scene_to_file.call_deferred.bind(main_menu)
	TransitionManager.fade_in()
	TransitionManager.animation_finished.connect(func(_c):c.call(), CONNECT_ONE_SHOT)

# wow
func update() -> void:
	if index > 3:
		%Scroller.scroll_vertical = 32.0 * (index - 3)
	else:
		%Scroller.scroll_vertical = 0.0
	
	for child in %OptionsList.get_children():
		child.get_node("Cursor").modulate.a = 0.0
		child.get_node("RichTextLabel").theme_type_variation = THEME_UNSELECTED
	
	%OptionsList.get_child(index).get_node("Cursor").modulate.a = 1.0
	%OptionsList.get_child(index).get_node("RichTextLabel").theme_type_variation = THEME_SELECTED
	
	%OptionDescription.text = option_descriptions[index]
	
	%MusicVolume/HSlider.value = options.music_volume
	%MusicVolume/Value.text = str(options.music_volume)
	
	%SEVolume/HSlider.value = options.se_volume
	%SEVolume/Value.text = str(options.se_volume)
	
	for child in %TextSpeed/HBoxContainer.get_children():
		child.theme_type_variation = THEME_UNSELECTED
	%TextSpeed/HBoxContainer.get_child(options.text_speed).theme_type_variation = THEME_VALUE_SELECTED
	
	%BattleEffects/HBoxContainer/On.theme_type_variation = THEME_VALUE_SELECTED if options.battle_effects == 0 else THEME_UNSELECTED
	%BattleEffects/HBoxContainer/Off.theme_type_variation = THEME_VALUE_SELECTED if options.battle_effects == 1 else THEME_UNSELECTED
	
	%BattleStyle/HBoxContainer/Switch.theme_type_variation = THEME_VALUE_SELECTED if options.battle_style == 0 else THEME_UNSELECTED
	%BattleStyle/HBoxContainer/Set.theme_type_variation = THEME_VALUE_SELECTED if options.battle_style == 1 else THEME_UNSELECTED
	
	%DefaultMovement/HBoxContainer/Walking.theme_type_variation = THEME_VALUE_SELECTED if options.default_movement == 0 else THEME_UNSELECTED
	%DefaultMovement/HBoxContainer/Running.theme_type_variation = THEME_VALUE_SELECTED if options.default_movement == 1 else THEME_UNSELECTED
	
	%SendtoBoxes/HBoxContainer/Manual.theme_type_variation = THEME_VALUE_SELECTED if options.send_to_boxes == 0 else THEME_UNSELECTED
	%SendtoBoxes/HBoxContainer/Automatic.theme_type_variation = THEME_VALUE_SELECTED if options.send_to_boxes == 1 else THEME_UNSELECTED
	
	%GiveNicknames/HBoxContainer/Give.theme_type_variation = THEME_VALUE_SELECTED if options.give_nicknames == 0 else THEME_UNSELECTED
	%GiveNicknames/HBoxContainer/DontGive.theme_type_variation = THEME_VALUE_SELECTED if options.give_nicknames == 1 else THEME_UNSELECTED
	
	%TextEntry/HBoxContainer/Cursor.theme_type_variation = THEME_VALUE_SELECTED if options.text_entry == 0 else THEME_UNSELECTED
	%TextEntry/HBoxContainer/Keyboard.theme_type_variation = THEME_VALUE_SELECTED if options.text_entry == 1 else THEME_UNSELECTED
	
	for child in %ScreenSize/HBoxContainer.get_children():
		child.theme_type_variation = THEME_UNSELECTED
	%ScreenSize/HBoxContainer.get_child(options.screen_size).theme_type_variation = THEME_VALUE_SELECTED

func decrement() -> void:
	match current.name:
		&"MusicVolume": options.music_volume = clampi(options.music_volume - 5, 0, 100)
		&"SEVolume": options.se_volume = clampi(options.se_volume - 5, 0, 100)
		&"TextSpeed": options.text_speed = clampi(options.text_speed - 1, 0, 3)
		&"BattleEffects": options.battle_effects = 0
		&"BattleStyle": options.battle_style = 0
		&"DefaultMovement": options.default_movement = 0
		&"SendtoBoxes": options.send_to_boxes = 0
		&"GiveNicknames": options.give_nicknames = 0
		&"SpeechFrame": pass
		&"MenuFrame": pass
		&"TextEntry": options.text_entry = 0
		&"ScreenSize": options.screen_size = clampi(options.screen_size - 1, 0, 4)

func increment() -> void:
	match current.name:
		&"MusicVolume": options.music_volume = clampi(options.music_volume + 5, 0, 100)
		&"SEVolume": options.se_volume = clampi(options.se_volume + 5, 0, 100)
		&"TextSpeed": options.text_speed = clampi(options.text_speed + 1, 0, 3)
		&"BattleEffects": options.battle_effects = 1
		&"BattleStyle": options.battle_style = 1
		&"DefaultMovement": options.default_movement = 1
		&"SendtoBoxes": options.send_to_boxes = 1
		&"GiveNicknames": options.give_nicknames = 1
		&"SpeechFrame": pass
		&"MenuFrame": pass
		&"TextEntry": options.text_entry = 1
		&"ScreenSize": options.screen_size = clampi(options.screen_size + 1, 0, 4)
