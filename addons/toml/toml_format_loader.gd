@tool
class_name ResourceFormatLoaderTOML
extends ResourceFormatLoader
## Custom [ResourceFormatLoader] for .toml files.

const TOMLLexer := preload("uid://cangnbsyvnbnj")
const TOMLParser := preload("uid://c4wdtytw660k5")


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["toml"])


func _get_resource_script_class(path: String) -> String:
	if path.get_extension().to_lower() in _get_recognized_extensions():
		return "TOML"
	return ""


func _get_resource_type(path: String) -> String:
	if path.get_extension().to_lower() in _get_recognized_extensions():
		return "Resource"
	return ""


func _handles_type(type: StringName) -> bool:
	return type == &"Resource"


func _load(path: String, _original_path: String, _use_sub_threads: bool, _cache_mode: int) -> Variant:
	var source: String = FileAccess.get_file_as_string(path)
	# Check malformed UTF-8
	if not source.to_utf8_buffer() == FileAccess.get_file_as_bytes(path):
		return ERR_FILE_CORRUPT
	
	var toml_lexer := TOMLLexer.new()
	var toml_parser := TOMLParser.new()
	
	var tokens: Array[TOMLLexer.TOMLToken] = toml_lexer.tokenize(source)
	if toml_lexer.had_error():
		return ERR_INVALID_DATA
	
	var data: Dictionary[Variant, Variant] = toml_parser.parse(tokens)
	if toml_parser.had_error():
		return ERR_PARSE_ERROR
	
	var new_toml_res := TOML.new()
	new_toml_res.data = data
	
	return new_toml_res
