extends UIState

const DIALOGUE_KEY = "initiate_save"

@export var default_state: UIState
@export var return_state: UIState

var _dialogue: DialogueResource = preload("res://src/resources/dialogue/generic.dialogue")
var _return_state: UIState = null

func enter(_default := false) -> void:
	_return_state = null
	
	%TownName.text = OverworldManager.instance.get_current_map().map_name
	%TrainerName.text = GameData.trainer_name
	%Playtime.text = "???m"
	%BadgeCount.text = "0"
	%PokedexCount.text = "0"
	
	var theme := &"RedLabel" if GameData.trainer_gender == 1 else &"BlueLabel"
	%TrainerName.theme_type_variation = theme
	%Playtime.theme_type_variation = theme
	%BadgeCount.theme_type_variation = theme
	%PokedexCount.theme_type_variation = theme
	
	visible = true
	DialogueManager.show_dialogue_balloon(_dialogue, DIALOGUE_KEY, [self, {"SaveUI":self}])

func exit(_default := false) -> void:
	visible = false

func process(_delta: float) -> UIState:
	return _return_state

func commit_save() -> void:
	var ext: String = ProjectSettings.get_setting("global/save_file_extension", ".res")
	
	if FileAccess.file_exists("user://save%s" % ext):
		var err := DirAccess.remove_absolute("user://save%s.bak" % ext)
		if err != OK:
			push_error("Failed to delete backup file (errno %d)" % err)
		err = DirAccess.rename_absolute("user://save%s" % ext, "user://save%s.bak" % ext)
		if err != OK:
			GameData.display_error("Failed to backup save data (errno %d)" % err, "SaveScreen")
			return
		
	var save := SaveFile.new()
	save.trainer_name = GameData.trainer_name
	save.trainer_gender = GameData.trainer_gender
	save.money = GameData.trainer_money
	save.party.assign(GameData.trainer_party)
	save.playtime = GameData.save_playtime
	
	save.map_id = OverworldManager.instance.get_map_uid(OverworldManager.instance.get_current_map())
	
	var offset_pos: Vector2 = Vector2(
		OverworldManager.instance.player.global_position.x + (-OverworldManager.instance.get_current_map().global_position.x),
		OverworldManager.instance.player.global_position.y + (-OverworldManager.instance.get_current_map().global_position.y)
	)
	save.map_position = offset_pos
	
	# TODO
	# save.bag
	
	ResourceSaver.save(save, "user://save%s" % ext)

func finish_save() -> void:
	_return_state = default_state
	get_tree().paused = false

func cancel_save() -> void:
	_return_state = return_state
