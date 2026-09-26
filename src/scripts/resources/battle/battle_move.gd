class_name BattleMove
extends Resource

@export var move_id: String
@export_range(0, 3, 1) var pp_ups: int

var _pp_used: int = 0

var max_pp: int:
	get:
		@warning_ignore("narrowing_conversion")
		return MovesManager.moves[move_id].pp * (1 + (0.2 * pp_ups))

var current_pp: int:
	get: return maxi(max_pp - _pp_used, 0)
