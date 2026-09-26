class_name SaveFile
extends Resource

@export var trainer_name: String = "null"
@export var trainer_gender: int = -1
@export var party: Array[Battler] = []
@export var money: int = -1
@export var bag: Array = []

@export var map_id: String = "uid://0"
@export var map_position: Vector2 = Vector2.ZERO

@export var playtime: int = -1

@export var data: Dictionary = {}
