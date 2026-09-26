class_name AIBattler
extends Resource

@export_flags(
	"PredictMoveFailure", "ScoreMoves",
	"PreferMultiTargetMoves", "HPAware",
	"ConsiderSwitching", "UsePokemonInOrder",
	"ReserveLastPokemon"
) var skill_flags: int
@export var skill_level: int
