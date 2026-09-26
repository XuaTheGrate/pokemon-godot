class_name LevelMove 
extends Resource

@export var level: int
@export var move_id: String

static func create(_level: int, _move_id: String) -> LevelMove:
	var r := LevelMove.new()
	r.level = _level
	r.move_id = _move_id
	return r
