class_name OptionsResource
extends Resource

@export_range(0, 100, 5) var music_volume: int = 100
@export_range(0, 100, 5) var se_volume: int = 100
@export_enum("Slow", "Mid", "Fast", "Inst") var text_speed := 1
@export_enum("On", "Off") var battle_effects := 0
@export_enum("Switch", "Set") var battle_style := 0
@export_enum("Walking", "Running") var default_movement := 0
@export_enum("Manual", "Automatic") var send_to_boxes := 0
@export_enum("Give", "Don't give") var give_nicknames := 0
@export var speech_frame := 0
@export var menu_frame := 0
@export_enum("Cursor", "Keyboard") var text_entry := 0
@export_enum("S", "M", "L", "XL", "Full") var screen_size := 1
