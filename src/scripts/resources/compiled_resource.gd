class_name CompiledResource
extends Resource

@export var types: Dictionary[String, Type]
@export var types_hash: String

#@export var abilities: Dictionary[String, Ability]
#@export var abilities_hash: String

@export var moves: Dictionary[String, Move]
@export var moves_hash: String

@export var species: Dictionary[String, Species]
@export var species_hash: String

static func hash_file(path: String) -> String:
	if not FileAccess.file_exists(path): return ""
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	var file := FileAccess.open(path, FileAccess.READ)
	while file.get_position() < file.get_length():
		var remaining := file.get_length() - file.get_position()
		ctx.update(file.get_buffer(min(remaining, 1024)))
	var res := ctx.finish()
	file.close()
	return res.hex_encode()
