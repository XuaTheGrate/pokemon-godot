class_name TOML
extends Resource
## Helper class for parsing TOML data.
##
## This class enables any valid TOML file to be parsed to a [Dictionary].
## It supports the complete TOML specification (v1.1.0) and can convert
## any valid TOML type to a Godot type.[br][br]
## The only TOML type that doesn't have a native counterpart in GDScript is [i]DateTime[/i], but a helper
## class ([TOML.DateTime]) is provided.

const TOMLLexer := preload("uid://cangnbsyvnbnj")
const TOMLParser := preload("uid://c4wdtytw660k5")

## The loaded TOML file as a [code]Dictionary[Variant, Variant][/code].
var data: Dictionary[Variant, Variant] = {}


## Attempts to parse the provided [param toml_string] and returns a [code]Dictionary[Variant, Variant][/code]
## on success. Returns [code]null[/code] if parsing failed.
static func parse_string(toml_string: String) -> Variant:
	var lexer := TOMLLexer.new()
	var parser := TOMLParser.new()
	
	var tokens: Array[TOMLLexer.TOMLToken] = lexer.tokenize(toml_string)
	if lexer.had_error():
		return null
	
	var result: Dictionary[Variant, Variant] = parser.parse(tokens)
	if parser.had_error():
		return null
	
	return result


## TOML DateTime helper class.
##
## Supports nanosecond precision and conversion to RFC3339 and ISO8601 formats.
##[br][br]
## By default the string representation is in RFC3339 format. Use [method to_iso8601]
## for a ISO8601 format DateTime string, compatible with the methods from the [Time] class.
class DateTime:
	
	# Date
	## A date's year
	var year: int
	## A date's month
	var month: Time.Month
	## A date's day
	var day: int
	
	# Time
	## A time's hours
	var hours: int
	## A time's minutes
	var minutes: int
	## A time's seconds
	var seconds: int
	# TOML requires at least millisecond precision
	## A time's milliseconds
	var milliseconds: float:
		get:
			if nanoseconds == -1:
				return -1
			return nanoseconds / 1e+6
	# This implementation uses nanoseconds as the highest precision magnitude
	## A time's nanoseconds
	var nanoseconds: int
	
	## It can be [code]"+"[/code] or [code]"-"[/code] to represent a
	## positive or negative offset respectively, or [code]"Z"[/code] to represent a
	## Zulu offset (00:00).[br]
	## An empty string if no offset is specified.
	var offset_sign: String
	## The offset hours
	var offset_hours: int
	## The offset minutes
	var offset_minutes: int
	
	## Raw DateTime string as it was found in the TOML file.
	var raw: String
	
	
	func _init(
		p_year: int, p_month: Time.Month, p_day: int,
		p_hours: int, p_minutes: int, p_seconds: int, p_nanoseconds: int,
		p_offset_sign: String, p_offset_hours: int, p_offset_minutes: int,
		p_raw: String
	) -> void:
		year = p_year
		month = p_month
		day = p_day
		
		hours = p_hours
		minutes = p_minutes
		seconds = p_seconds
		nanoseconds = p_nanoseconds
		
		offset_sign = p_offset_sign.to_upper()
		offset_hours = p_offset_hours
		offset_minutes = p_offset_minutes
		
		raw = p_raw
	
	
	func _to_string() -> String:
		return (
			(("%04d-%02d-%02d" % [year, month, day]) if year != -1 else "") +
			("T" if (year != -1 and hours != -1) else "") + 
			(("%02d:%02d" % [hours, minutes]) if hours != -1 else "") +
			((":%02d" % [seconds if seconds != -1 else 0]) if hours != -1 else "") +
			((".%s" % [str(milliseconds / 1000.0).trim_prefix("0.")]) if milliseconds != -1 else "") +
			(("%s" % [offset_sign]) if offset_sign != "" else "") +
			(("%02d:%02d" % [offset_hours, offset_minutes]) if (offset_hours != -1 and offset_sign != "Z") else "")
		)
	
	
	## Returns the ISO8601 representation of this DateTime.
	## Compatible with the methods from the [Time] class.[br]
	## If [param use_space] is [code]true[/code], the Date and Time parts are separated with a space
	## instead of the letter [code]"T"[/code].
	func to_iso8601(use_space: bool = false) -> String:
		return (
			(("%04d-%02d-%02d" % [year, month, day]) if year != -1 else "") +
			((" " if use_space else "T") if (year != -1 and hours != -1) else "") + 
			(("%02d:%02d" % [hours, minutes]) if hours != -1 else "") +
			((":%02d" % [seconds if seconds != -1 else 0]) if hours != -1 else "")
			)
