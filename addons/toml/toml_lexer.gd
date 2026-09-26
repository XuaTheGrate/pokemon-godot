## TOML Lexer.
##
## Emits a list of tokens with a valid TOML meaning.
## It also performs values conversions and validations
## since it already has to iterate through them to identify them.

enum TokenizationMode {
	KEY,
	VALUE
}

enum TokenizationContext {
	ARRAY,
	INLINE_TABLE,
}


#region Constants
## They are safe to continue the tokenization from after an error
const TOKEN_END_CHARACTERS := [" ", "\r", "\n", ",", "]", "}", "=", "#"]

const WHITESPACE_CHARACTERS := [" ", "\t"]
const QUOTE_CHARACTERS := ["\"", "'"]

const NEWLINE_CHARACTERS := ["\r", "\n"]

const VALID_ESCAPE_SEQUENCES_TO_CODES: Dictionary = {
	"b": 0x0008,   # backspace
	"t": 0x0009,   # tab
	"n": 0x000A,   # linefeed
	"f": 0x000C,   # form feed
	"r": 0x000D,   # carriage return
	"e": 0x001B,   # escape
	"\"": 0x0022,  # quote
	"\\": 0x005C   # backslash
}

## Doesn't include tab
const CONTROL_CHARACTERS_CODES := [
	# 0x0000 - 0x0008
	0x0000, 0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007, 0x0008,
	# 0x000A - 0x001F
	0x000A, 0x000B, 0x000C, 0x000D, 0x000E, 0x000F, 0x0010, 0x0011, 0x0012,
	0x0013, 0x0014, 0x0015, 0x0016, 0x0017, 0x0018, 0x0019, 0x001A, 0x001B,
	0x001C, 0x001D, 0x001E, 0x001F,
	
	0x007F
]

const REPLACEMENT_CHARACTER_CODE := 0xFFFD
#endregion


#region Members
## String input from [method tokenize].
var _source: String
## Token Array built during tokenization.
var _tokens: Array[TOMLToken]
## If [code]true[/code], the lexer reported an error during tokenization.
var _had_error: bool = false

## Start position on [member _source] for the next token.
var _start: int
## Start line number from [member _source] for the next token.
var _start_line: int
## Start column number from [member _source] for the next token.
var _start_column: int

## Current position on [member _source].
var _current: int
## Current line number from [member _source]
var _line: int
## Current column number from [member _source]
var _column: int

## Represents the next token clean lexeme.
var _lexeme_buffer: String

## Represents the current tokenization mode of the lexer (Keys or Values).
var _tokenization_mode: TokenizationMode
## Represents the current context stack (Arrays or InlineTables).
var _tokenization_context_stack: Array[TokenizationContext]
#endregion


## Tokenizes a TOML document text String, returning an Array of tokens.
## A TOML file ([param source_text]) must be a valid UTF-8 encoded Unicode document.
func tokenize(source_text: String) -> Array[TOMLToken]:
	_source = source_text
	_tokens.clear()
	_had_error = false
	
	_current = 0
	_line = 1
	_column = 1
	
	_tokenization_mode = TokenizationMode.KEY
	_tokenization_context_stack = []
	
	while not _is_at_end():
		_start = _current
		_start_line = _line
		_start_column = _column
		_lexeme_buffer = ""
		_tokenize_next()
	
	_add_token(TOMLToken.TokenType.EOF)
	return _tokens


## Returns [code]true[/code] if the lexer reported an error during tokenization.
func had_error() -> bool:
	return _had_error


## Reports a lexer error.
func _error(line: int, column: int, msg: String) -> void:
	push_error("TOML Lexer Error at (%d, %d): %s" % [line, column, msg])
	_had_error = true


#region Source navigation
## Returns the next character at [member _current] + [param offset].
## Doesn't move the current position.
func _peek(offset: int = 0) -> String:
	if _is_at_end(offset):
		return char(REPLACEMENT_CHARACTER_CODE)
	return char(_source.unicode_at(_current + offset))


## Moves the [member _current] pointer to a safe-to-continue position.
## Used to consume characters after an error was reported.
func _synchronize() -> void:
	while not _is_at_end():
		if _peek() in TOKEN_END_CHARACTERS:
			return
		
		_advance(false)


## Returns the next character and moves the current position forward by one.
func _advance(to_buffer: bool = true) -> String:
	if _is_at_end():
		return char(REPLACEMENT_CHARACTER_CODE)
	var c := char(_source.unicode_at(_current))
	_current += 1
	_column += 1
	if to_buffer:
		_lexeme_buffer += c
	return c


## Returns [code]true[/code] if the current position is at the end of the [member _source] string.
func _is_at_end(offset: int = 0) -> bool:
	return _current + offset >= _source.length()
#endregion


#region Character validation
## Returns [code]true[/code] if the given caracter is inside [A-Za-z]
func _is_alpha(c: String) -> bool:
	if c.length() != 1:
		push_error("TOML Lexer ERROR, _is_alpha() should only be called on a single character: '%c'" % c)
	var code: int = ord(c)
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122)


## Return [code]true[/code] if the given character is inside [0-9]
func _is_digit(c: String) -> bool:
	if c.length() != 1:
		push_error("TOML Lexer ERROR, _is_digit() should only be called on a single character: '%c'" % c)
	var code: int = ord(c)
	return code >= 48 and code <= 57


## Returns [code]true[/code] if the char is inside [01].
func _is_binary_digit(c: String) -> bool:
	if c.length() > 1:
		push_error("TOML Lexer ERROR, _is_binary_digit() should only be called on a single character: '%c'" % c)
	var code: int = c.unicode_at(0)
	return code in [48, 49]


## Returns [code]true[/code] if the char is inside [0-7].
func _is_oct_digit(c: String) -> bool:
	if c.length() > 1:
		push_error("TOML Lexer ERROR, _is_oct_digit() should only be called on a single character: '%c'" % c)
	var code: int = c.unicode_at(0)
	return code >= 48 and code <= 55


## Returns [code]true[/code] if the char is inside [0-9a-fA-F].
func _is_hex_digit(c: String) -> bool:
	if c.length() > 1:
		push_error("TOML Lexer ERROR, _is_hex_digit() should only be called on a single character: '%c'" % c)
	var code: int = c.unicode_at(0)
	return (
		_is_digit(c) or
		(code >= 97 and code <= 102) or
		(code >= 65 and code <= 70)
	)


## Returns [code]true[/code] if the given character can be part of a bare key.
func _is_bare_key(c: String) -> bool:
	return _is_alpha(c) or _is_digit(c) or c in ["_", "-"]
#endregion


#region Lexem to literal methods
## Calidates and creates the literal value for a date while consuming the characters.
## Returns a [Dictionary] with the [code]year, month, day[/code] entries.
func _date_literal() -> Dictionary[StringName, int]:
	var date: Dictionary[StringName, int] = {
		&"year": -1,
		&"month": -1,
		&"day": -1
	}
	
	var year_s: String = ""
	for _u in 4:
		if not _is_digit(_peek()):
			_error(_line, _column, "Invalid character in Date's year: '%c'." % _peek())
			_synchronize()
			return {}
		year_s += _advance()
	date[&"year"] = year_s.to_int()
	
	if _peek() != "-":
		_error(_line, _column, "Invalid year-month separator in Date: '%c'." % _peek())
		_synchronize()
		return {}
	_advance()
	
	var month_s: String = ""
	for _u in 2:
		var n := _peek()
		if not _is_digit(n):
			_error(_line, _column, "Invalid character in Date's month: '%c'." % n)
			_synchronize()
			return {}
		month_s += _advance()
	date[&"month"] = month_s.to_int()
	
	# Validation: Month
	if date[&"month"] <= 0 or date[&"month"] > 12:
		_error(_line, _column, "Date's month has to be between 1 and 12.")
		_synchronize()
		return {}
	
	if _peek() != "-":
		_error(_line, _column, "Invalid month-day separator in Date: '%c'." % _peek())
		_synchronize()
		return {}
	_advance()
	
	var day_s: String = ""
	for _u in 2:
		var n := _peek()
		if not _is_digit(n):
			_error(_line, _column, "Invalid character in Date's day: '%c'." % n)
			_synchronize()
			return {}
		day_s += _advance()
	date[&"day"] = day_s.to_int()
	
	# Validation: Day
	if date[&"month"] in [1, 3, 5, 7, 8, 10, 12]:
		if(date[&"day"] < 1 or date[&"day"] > 31):
			_error(_line, _column, "Date's day has to be between 1 and 31.")
			_synchronize()
			return {}
	elif date[&"month"] != 2:
		if (date[&"day"] < 1 or date[&"day"] > 30):
			_error(_line, _column, "Date's day has to be between 1 and 30.")
			_synchronize()
			return {}
	else:
		# Validation: February days
		if (date[&"year"] % 4 == 0 and (date[&"year"] % 100 != 0 or date[&"year"] % 400 == 0)):
			# Leap year
			if (date[&"day"] < 1 or date[&"day"] > 29):
				_error(_line, _column, "Date's day has to be between 1 and 29 (February on leap year).")
				_synchronize()
				return {}
		else:
			if (date[&"day"] < 1 or date[&"day"] > 28):
				_error(_line, _column, "Date's day has to be between 1 and 28 (February).")
				_synchronize()
				return {}
	
	return date


## Validates and creates the literal value for a time while consuming the characters.
## Returns a [Dictionary] with the [code]hours, minutes, seconds, nanoseconds[/code] entries.
func _time_literal(accepts_offset: bool) -> Dictionary[StringName, Variant]:
	var time: Dictionary[StringName, Variant] = {
		&"hours": -1,
		&"minutes": -1,
		&"seconds": -1,
		&"nanoseconds": -1,
		
		&"offset_sign": "",
		&"offset_hours": -1,
		&"offset_minutes": -1,
	}
	
	var hours_s: String = ""
	for _u in 2:
		if not _is_digit(_peek()):
			_error(_line, _column, "Invalid character in Time's hours: '%c'." % _peek())
			_synchronize()
			return {}
		hours_s += _advance()
	time[&"hours"] = hours_s.to_int()
	
	# Validation: Hours
	if time[&"hours"] < 0 or time[&"hours"] > 23:
		_error(_line, _column, "Time's hours have to be between 0 and 23.")
		_synchronize()
		return {}
	
	if _peek() != ":":
		_error(_line, _column, "Invalid hours-minutes separator in Time: '%c'." % _peek())
		_synchronize()
		return {}
	_advance()
	
	var minutes_s: String = ""
	for _u in 2:
		var n := _peek()
		if not _is_digit(n):
			_error(_line, _column, "Invalid character in Time's minutes: '%c'." % n)
			_synchronize()
			return {}
		minutes_s += _advance()
	time[&"minutes"] = minutes_s.to_int()
	
	# Validation: Minutes
	if time[&"minutes"] < 0 or time[&"minutes"] > 59:
		_error(_line, _column, "Time's minutes have to be between 0 and 59.")
		_synchronize()
		return {}
	
	if _peek() not in TOKEN_END_CHARACTERS:
		# There are seconds or timezone
		if _peek() not in [":", "+", "-"] and _is_digit(_peek(1)):
			_error(_line, _column, "Invalid character after minutes Time: '%c'. Expected ':' or '+/-'." % _peek())
			_synchronize()
			return {}
		
		if _peek() == ":":
			_advance()
			# Calculate seconds
			var seconds_s: String = ""
			for _u in 2:
				var n := _peek()
				if not _is_digit(n):
					_error(_line, _column, "Invalid character in Time's seconds: '%c'." % n)
					_synchronize()
					return {}
				seconds_s += _advance()
			time[&"seconds"] = seconds_s.to_int()
			
			# Validation: Seconds
			if time[&"seconds"] < 0 or time[&"seconds"] > 59:
				_error(_line, _column, "Time's seconds have to be between 0 and 59.")
				_synchronize()
				return {}
			
			if _peek() == ".":
				var seconds_fraction_s: String = ""
				seconds_fraction_s += _advance()
				while _is_digit(_peek()):
					seconds_fraction_s += _advance()
				if seconds_fraction_s.is_empty() or seconds_fraction_s == ".":
					_error(_line, _column, "Expected subseconds fraction after '.'.")
					_synchronize()
					return {}
				# Calculate nanoseconds
				var f: float = seconds_fraction_s.to_float()
				time[&"nanoseconds"] = int(f * 1e9)
			
		
		if _peek() in ["+", "-", "Z", "z"]:
			# Offset
			if not accepts_offset:
				_error(_line, _column, "Invalid offset on Time only Date-Time.")
				_synchronize()
				return {}
			
			var sign: String = _advance()
			time[&"offset_sign"] = sign
			if sign in ["Z", "z"]:
				# Often spoken "Zulu", denotes a UTC offset of 00:00
				time[&"offset_hours"] = 0
				time[&"offset_minutes"] = 0
			else:
				# Calculate offset
				var offset_hours_s: String = ""
				for _u in 2:
					var n := _peek()
					if not _is_digit(n):
						_error(_line, _column, "Invalid character in Time's offset hours: '%c'." % n)
						_synchronize()
						return {}
					offset_hours_s += _advance()
				time[&"offset_hours"] = offset_hours_s.to_int()
				
				# Validation: Offset hours
				if time[&"offset_hours"] < 0 or time[&"offset_hours"] > 23:
					_error(_line, _column, "Time's offset hours have to be between 0 and 23.")
					_synchronize()
					return {}
				
				if _peek() != ":":
					_error(_line, _column, "Expected offset's hours-minutes separator.")
					_synchronize()
					return {}
				_advance()
				
				var offset_minutes_s: String = ""
				for _u in 2:
					var n := _peek()
					if not _is_digit(n):
						_error(_line, _column, "Invalid character in Time's offset minutes: '%c'." % n)
						_synchronize()
						return {}
					offset_minutes_s += _advance()
				time[&"offset_minutes"] = offset_minutes_s.to_int()
				
				# Validation: Offset minutes
				if time[&"offset_minutes"] < 0 or time[&"offset_minutes"] > 59:
					_error(_line, _column, "Time's offset minutes have to be between 0 and 59.")
					_synchronize()
					return {}
	
	return time


## Calculates an integer value from any kind of TOML integer literal.
## Doesn't do validations.
func _integer_literal(s: String) -> int:
	if s.is_empty():
		return -1
	
	var sign_mult: int = 1
	var start_idx: int = 0
	
	# Sign
	var first_char: String = s[0]
	if first_char == "-":
		sign_mult = -1
		start_idx = 1
	elif first_char == "+":
		start_idx = 1
	
	var base: int = 10
	# Modify base for binary, octal or hexadecimal numbers
	if start_idx + 1 < s.length() and s[start_idx] == "0":
		var prefix: String = s[start_idx + 1]
		if prefix in ["b", "B"]:
			base = 2
			start_idx += 2
		elif prefix in ["o", "O"]:
			base = 8
			start_idx += 2
		elif prefix in ["x","X"]:
			base = 16
			start_idx += 2
	
	var result := 0
	for i in range(start_idx, s.length()):
		var c: String = s[i]
		var c_code: int = ord(c)
		
		# Ignore separators
		if c == "_":
			continue
		
		# ASCII to int
		var digit_val: int = 0
		if c_code >= ord("0") and c_code <= ord("9"):
			digit_val = c_code - ord("0")
		elif c_code >= ord("a") and c_code <= ord("f"):
			digit_val = c_code - ord("a") + 10
		elif c_code >= ord("A") and c_code <= ord("F"):
			digit_val = c_code - ord("A") + 10
		
		# Add value
		result = (result * base) + digit_val

	return result * sign_mult
#endregion


#region Tokenization
## Adds a token to the current [member _tokens] list.
## Uses [member _lexeme_buffer] as the token lexeme and literal value.
func _add_token(type: TOMLToken.TokenType) -> void:
	_tokens.append(TOMLToken.new(type, _lexeme_buffer, _lexeme_buffer, _start_line, _start_column))


## Same as [method _add_token] but with a specific literal value.
func _add_token_literal(type: TOMLToken.TokenType, literal: Variant) -> void:
	_tokens.append(TOMLToken.new(type, _lexeme_buffer, literal, _start_line, _start_column))


## Validates and tokenizes a string.[br]
## [param is_key] indicates if the string has to be tokenized as a QUOTED_KEY token.
func _string(is_key: bool = false) -> void:
	var quote_type: String = _advance(false)
	var is_multiline: bool = false
	var is_basic: bool = quote_type == "\""
	
	# Detect multiline string quote
	if _peek(0) + _peek(1) == quote_type.repeat(2):
		if is_key:
			_error(_start_line, _start_column, "Multiline strings can't be used as quoted keys.")
			_synchronize()
			return
		is_multiline = true
		_advance(false); _advance(false)
		if _peek() == "\r":
			if not _peek(1) == "\n":
				_error(_line, _column, "Carriage return is only allowed as part of a newline sequence.")
				_synchronize()
				return
			_advance(false)
		if _peek() == "\n":
			# On multiline strings if the first character after
			# the triple quote is a newline, it gets trimmed
			_advance(false)
			_line += 1
			_column = 1
	
	while not _is_at_end():
		var n: String = _peek()
		
		# Validation: Escape sequences in basic string
		if n == "\\" and is_basic:
			_advance(false)
			var backslash_loc := Vector2i(_line, _column - 1)
			var escaped_char: String = _advance(false)
			
			# We check for a escaped NEWLINE in a multiline string
			# the string continues on the next non whitespace/newline character
			if is_multiline and escaped_char in WHITESPACE_CHARACTERS + NEWLINE_CHARACTERS:
				var is_escaping_newline: bool = false
				var first: int = 0
				if escaped_char == "\r":
					if not _peek() == "\n":
						_error(_line, _column, "Carriage return is only allowed as part of a newline sequence.")
						_synchronize()
						return
				elif escaped_char == "\n":
					_line += 1
					_column = 1
					is_escaping_newline = true
				
				while not _is_at_end() and (_peek() in WHITESPACE_CHARACTERS + NEWLINE_CHARACTERS):
					if _peek() == "\r":
						if not _peek(1) == "\n":
							_error(_line, _column, "Carriage return is only allowed as part of a newline sequence.")
							_synchronize()
							return
					elif _peek() == "\n":
						_line += 1
						_column = 1
						is_escaping_newline = true
					
					_advance(false)
				
				if not is_escaping_newline:
					# It was an unescaped backslash
					_error(backslash_loc.x, backslash_loc.y, "Unescaped backslash in multiline basic string.")
					_synchronize()
					return
				continue
			
			elif escaped_char in VALID_ESCAPE_SEQUENCES_TO_CODES:
				# Inyect escaped sequence literal character
				_lexeme_buffer += char(VALID_ESCAPE_SEQUENCES_TO_CODES[escaped_char])
				continue
			
			elif escaped_char in ["x", "u", "U"]:
				var expected_len: int = 2 if escaped_char == "x" else (4 if escaped_char == "u" else 8)
				var hex_str: String = ""
				# Peek for hex number string
				for i in range(expected_len):
					if _peek() == "\n":
						_error(_line, _column, "Truncated unicode escape sequence.")
						_synchronize()
						return
					hex_str += _advance(false)
				
				if not hex_str.is_valid_hex_number(false):
					_error(_line, _column - hex_str.length(), "Invalid unicode escape sequence: '\\%s%s'" % [escaped_char, hex_str])
					_synchronize()
					return
				
				# Validation: Valid Unicode escalar value (0x0000 to 0xD7FF and 0xE000 to 0x10FFFF both ends inclusive)
				var codepoint: int = hex_str.hex_to_int()
				if not ((codepoint >= 0x0000 and codepoint <= 0xD7FF) or (codepoint >= 0xE000 and codepoint <= 0x10FFFF)):
					_error(_line, _column - hex_str.length(), "Escaped unicode value out of range U+%04X" % codepoint)
					_synchronize()
					return
				
				# Finished HEX validation succesfully
				# Inyect valid unicode character
				_lexeme_buffer += char(codepoint)
				continue
			
			# If escape sequence is not validated
			_error(_line, _column, "Invalid escape sequence: '\\u%04X'" % ord(escaped_char))
			_synchronize()
			return
		
		# Validation: Control characters (excluding tab) must appear escaped
		if ord(n) in CONTROL_CHARACTERS_CODES:
			if not n in NEWLINE_CHARACTERS:
				_error(_line, _column, "Invalid character in %s string '\\u%X'" % ["basic" if is_basic else "literal", ord(n)])
				_synchronize()
				return
		
		if is_multiline:
			if n == quote_type:
				var consecutive_quotes: int = 0
				while _peek() == quote_type:
					_advance(false)
					consecutive_quotes += 1
				
				if consecutive_quotes <= 2:
					# One or two quotes adjacent are valid in multiline strings
					_lexeme_buffer += quote_type.repeat(consecutive_quotes)
					continue
				elif consecutive_quotes > 2 and consecutive_quotes <= 5:
					# Close sequence and maybe up to 2 extra quotes
					_lexeme_buffer += quote_type.repeat(consecutive_quotes - 3)
					
					_add_token(TOMLToken.TokenType.MULTILINE_BASIC_STRING if is_basic else TOMLToken.TokenType.MULTILINE_LITERAL_STRING)
					return
				else:
					# Validation: More than 6 consecutive quotes is not valid
					_error(_line, _column - consecutive_quotes, "Only 5 unsecaped consecutive quotes are allowed in a multiline string.")
					_synchronize()
					return
			
			if n == "\r":
				# Validation: An unescaped carriage return is only valid before line feed
				if not _peek(1) == "\n":
					_error(_line, _column, "Carriage return is only allowed as part of a newline sequence.")
					_synchronize()
					return
				_advance()
			if n == "\n":
				_advance()
				_line += 1
				_column = 1
				continue
		else:
			# String end
			if n == quote_type:
				_advance(false)
				if is_key:
					_add_token_literal(TOMLToken.TokenType.QUOTED_KEY, StringName(_lexeme_buffer))
				else:
					_add_token(TOMLToken.TokenType.BASIC_STRING if is_basic else TOMLToken.TokenType.LITERAL_STRING)
				return
			
			# Validation: Newlines are not valid in single quote strings.
			if n in NEWLINE_CHARACTERS:
				_error(_line, _column, "Newline in single quote %s string." % ("basic" if is_basic else "literal"))
				_synchronize()
				return
		
		# Valid regular acharacters
		_advance()
	
	_error(_line, _column, "File ended before closing %s %s string." % ["multiline" if is_multiline else "", "basic" if is_basic else "literal"])


## Parses a TOML DateTime value as a DATETIME token.
func _datetime() -> void:
	var date: Dictionary[StringName, int] = {}
	var time: Dictionary[StringName, Variant] = {}
	
	# Check for Date
	if _peek(4) == "-":
		date = _date_literal()
	
	if not date.is_empty():
		if _peek() in ["T", "t"] or (_peek() == " " and _is_digit(_peek(1))):
			var s: String = _advance()
			# Validation: Time appears after "T" or " " separator
			if not _peek(2) == ":":
				_error(_line, _column, "Expected time after Date-Time separator '%c'." % s)
				_synchronize()
				return
		elif _peek(2) == ":":
			# Validation: Fail if the separator is absent and time is present
			_error(_line, _column, "Expected Date-Time separator.")
			_synchronize()
			return
			
	
	# Check for Time
	if _peek(2) == ":":
		time = _time_literal(not date.is_empty())
	
	var datetime_literal := TOML.DateTime.new(
		date.get(&"year", -1), date.get(&"month", -1), date.get(&"day", -1),
		time.get(&"hours", -1), time.get(&"minutes", -1), time.get(&"seconds", -1), time.get(&"nanoseconds", -1),
		time.get(&"offset_sign", ""), time.get(&"offset_hours", -1), time.get(&"offset_minutes", -1),
		_lexeme_buffer
	)
	_add_token_literal(TOMLToken.TokenType.DATETIME, datetime_literal)


## Tokenizes what could be a binary, octal, or hexademical integer literal.
func _binary_octal_hexadecimal() -> void:
	var literal: int = 0
	
	# Validation: Special integer literals can't have a sign
	if _peek() in ["+", "-"]:
		if _peek() == "-":
			_error(_line, _column, "Negative integers can't be expressed as binary, octal or hexadecimal literals.")
		else:
			_error(_line, _column, "Leading '+' is not allowed on binary, octal and hexadecimal literals.")
		_synchronize()
		return
	
	# Validation: Valid special integer literal prefix
	if not _peek() + _peek(1) in ["0b", "0o", "0x"]:
		_error(_line, _column, "Integer prefix should start with \"0b\", \"0o\", or \"0x\".")
		_synchronize()
		return
	
	var prefix: String = _advance() + _advance()
	var number_name: String = "Binary" if prefix == "0b" else ("Octal" if prefix == "0o" else "Hexadecimal")
	var digit_validator: Callable = _is_binary_digit if prefix == "0b" else (_is_oct_digit if prefix == "0o" else _is_hex_digit)
	
	while not _is_at_end() and _peek() not in TOKEN_END_CHARACTERS:
		var c: String = _peek()
		# Validation: Number separator
		if c == "_":
			if _lexeme_buffer.length() == 0:
				_error(_line, _column, "Number's can't start with '_'.")
				_synchronize()
				return
			if not (digit_validator.call(_lexeme_buffer[-1]) and digit_validator.call(_peek(1))):
				_error(_line, _column, "Number's '_' separator must be surrounded by at least one digit on each side.")
				_synchronize()
				return
			_advance(false)
			continue
		# Validation: Invalid special integer literal digit character
		elif not digit_validator.call(c):
			_error(_line, _column, "Invalid %s character: '%c'" % [number_name.to_lower(), c])
			_synchronize()
			return
		
		_advance()
	
	# Validation: No empty number after prefix
	if _lexeme_buffer.length() <= 2:
		_error(_line, _column, "Invalid integer literal, incomplete %s." % number_name.to_lower())
		_synchronize()
		return
	
	_add_token_literal(TOMLToken.TokenType.INTEGER, _integer_literal(_lexeme_buffer))


## Tokenizes a valid TOML normal integer literal.
func _integer() -> void:
	if _peek() in ["+", "-"]:
		_advance()
	
	# Validation: No leading zeros
	if _peek() + _peek(1) == "00":
		_error(_line, _column, "Integer number can't have leading zeros.")
		_synchronize()
		return
	
	while not _is_at_end() and _peek() not in TOKEN_END_CHARACTERS:
		# Validation: Number separator
		if _peek() == "_":
			if _lexeme_buffer.length() == 0:
				_error(_line, _column, "Integer numbers can't start with '_'.")
				_synchronize()
				return
			elif not (_is_digit(_lexeme_buffer[-1]) and _is_digit(_peek(1))):
				_error(_line, _column, "Number's '_' separator must be surrounded by at least one digit on each side.")
				_synchronize()
				return
			_advance(false)
			continue
		
		elif not _is_digit(_peek()):
			_error(_line, _column, "Invalid character in integer: '%c'." % _peek())
			_synchronize()
			return
		
		_advance()
	
	var clean_integer = _lexeme_buffer
	
	# Validation: Integer conversion
	if not clean_integer.is_valid_int():
		_error(_start_line, _start_column, "Invalid integer.")
		_synchronize()
		return
	
	_add_token_literal(TOMLToken.TokenType.INTEGER, clean_integer.to_int())


## Tokenizes a valid TOML float number.
func _float() -> void:
	while not _is_at_end() and _peek() not in TOKEN_END_CHARACTERS:
		var n: String = _peek()
		# Validation: Leading or trailing dot
		if n == ".":
			if _lexeme_buffer.length() == 0:
				_error(_line, _column, "Float numbers can't start with '.'.")
				_synchronize()
				return
			elif not (_is_digit(_lexeme_buffer[-1]) and _is_digit(_peek(1))):
				_error(_line, _column, "Float's decimal point must be surrounded by at least one digit on each side.")
				_synchronize()
				return
		
		# Validation: Number separator
		elif n == "_":
			if _lexeme_buffer.length() == 0:
				_error(_line, _column, "Float numbers can't start with '_'.")
				_synchronize()
				return
			elif not (_is_digit(_lexeme_buffer[-1]) and _is_digit(_peek(1))):
				_error(_line, _column, "Number's '_' separator must be surrounded by at least one digit on each side.")
				_synchronize()
				return
			
			_advance(false)
			continue
		
		elif n not in ["+", "-", "e", "E"] and not _is_digit(n):
			_error(_line, _column, "Invalid character for float number: '%c'." % n)
			_synchronize()
			return
		
		_advance()
	
	var clean_float: String = _lexeme_buffer
	
	# Validation: No trailing exponent
	if clean_float.ends_with("-") or clean_float.ends_with("+") or clean_float.ends_with("e") or clean_float.ends_with("E"):
		_error(_line, _column, "Invalid trailing exponent on float number")
		_synchronize()
		return
	
	# Validation: Float conversion
	if not clean_float.is_valid_float():
		_error(_start_line, _start_column, "Invalid float.")
		_synchronize()
		return
	
	_add_token_literal(TOMLToken.TokenType.FLOAT, clean_float.to_float())


## Bifurcates the tokenization process towards a INTEGER or FLOAT token.
func _number() -> void:
	var sign: int = 0
	if _peek() in ["+", "-"]:
		sign = +1 if _peek() == "+" else -1
	
	var num_offset: int = 1 if sign != 0 else 0
	
	var nn: String = _peek(0 + num_offset) + _peek(1 + num_offset)
	if nn in ["0b", "0o", "0x"]:
		_binary_octal_hexadecimal()
		return
	
	var offset: int = num_offset
	var number_s: String = ""
	var is_float: bool = false
	while not _is_at_end(offset) and _peek(offset) not in TOKEN_END_CHARACTERS:
		var n: String = _peek(offset)
		if n in [".", "E", "e"]:
			is_float = true
			break
		number_s += n
		offset += 1
	
	# Validation: No leading zeros in decimal part of non bin/oct/hex number.
	if number_s.length() != 1 and number_s.begins_with("0"):
		_error(_line, _column, "Invalid leading zeros on number.")
		_synchronize()
		return
	
	if is_float:
		_float()
		return
	_integer()


## Bifurcates the tokenization process towards a DATETIME or number token.
func _date_or_number() -> void:
	
	var n: String = _peek()
	
	if (_is_digit(_peek(3)) and _peek(4) == "-") or _peek(2) == ":":
		_datetime()
		return
	
	# Check number keywords
	var kw: String = n + _peek(1) + _peek(2) + _peek(3)
	if kw.begins_with("nan"):
		_advance(); _advance(); _advance();
		_add_token_literal(TOMLToken.TokenType.FLOAT, NAN)
		return
	elif kw.begins_with("inf"):
		_advance(); _advance(); _advance()
		_add_token_literal(TOMLToken.TokenType.FLOAT, INF)
		return
	elif kw in ["+inf", "-inf"]:
		_advance(); _advance(); _advance(); _advance()
		_add_token_literal(TOMLToken.TokenType.FLOAT, (1 if kw[0] == "+" else -1) * INF)
		return
	elif kw in ["+nan", "-nan"]:
		_advance(); _advance(); _advance(); _advance()
		_add_token_literal(TOMLToken.TokenType.FLOAT, NAN)
		return
	
	if n in ["+", "-"] or _is_digit(n):
		_number()
		return
	
	_error(_line, _column, "Invalid TOML Date-Time or number.")
	_synchronize()


## Bifurcates the tokenization process towards a string, DATETIME, number, or BOOL token.
func _value() -> void:
	var c: String = _peek()
	if c in QUOTE_CHARACTERS:
		_string()
		return
	elif c in ["+", "-", "i", "n"] or _is_digit(c):
		_date_or_number()
		return
	else:
		var kw: String = c + _peek(1) + _peek(2) + _peek(3) + _peek(4)
		if kw.begins_with("true"):
			_advance(); _advance(); _advance(); _advance()
			_add_token_literal(TOMLToken.TokenType.BOOL, true)
			return
		elif kw.begins_with("false"):
			_advance(); _advance(); _advance(); _advance(); _advance()
			_add_token_literal(TOMLToken.TokenType.BOOL, false)
			return
		
	_error(_start_line, _start_column, "Invalid TOML value.")
	_synchronize()


## Tokenizes a QUOTED_KEY tokn.
func _quoted_key() -> void:
	_string(true)


## Tokenizes a BARE_KEY token.
func _bare_key() -> void:
	while not _is_at_end() and _is_bare_key(_peek()):
		_advance()
	
	_add_token_literal(TOMLToken.TokenType.BARE_KEY, StringName(_lexeme_buffer))


## Tokenizes de next possible sequence of characters.
func _tokenize_next() -> void:
	var n: String = _peek()
	
	match n:
		".":
			if _is_digit(_peek(1)) and _tokenization_mode == TokenizationMode.VALUE:
				# Validation: Dot is not the start of a FLOAT token.
				_error(_line, _column, "Floats can't start with a dot.")
				_synchronize()
				return
			
			_advance()
			_add_token(TOMLToken.TokenType.DOT)
		",":
			_advance()
			_add_token(TOMLToken.TokenType.COMMA)
			if _tokenization_context_stack.back() == TokenizationContext.ARRAY:
				_tokenization_mode = TokenizationMode.VALUE
			else:
				_tokenization_mode = TokenizationMode.KEY
		"[", "{":
			_advance()
			_add_token(TOMLToken.TokenType.L_BRACKET if n == "[" else TOMLToken.TokenType.L_BRACE)
			if n == "{":
				_tokenization_context_stack.append(TokenizationContext.INLINE_TABLE)
				_tokenization_mode = TokenizationMode.KEY
			elif _tokenization_mode == TokenizationMode.VALUE:
				_tokenization_context_stack.append(TokenizationContext.ARRAY)
		"]", "}":
			_advance()
			_add_token(TOMLToken.TokenType.R_BRACKET if n == "]" else TOMLToken.TokenType.R_BRACE)
			_tokenization_context_stack.pop_back()
		"=":
			_advance()
			_add_token(TOMLToken.TokenType.EQUAL)
			# After an EQUAL -> ALWAYS tokenize as a value
			_tokenization_mode = TokenizationMode.VALUE
		"#":
			# Comment ignoring
			while not _is_at_end() and _peek() != "\n":
				var n_code: int = ord(_advance(false))
				# Validation: Invalid characters inside comment
				if n_code in CONTROL_CHARACTERS_CODES:
					if char(n_code) == "\r" and _peek() == "\n":
						continue
					_error(_line, _column, "Invalid character '\\u%04X' inside comment." % n_code)
		" ", "\t":
			_advance(false)
		"\r", "\n":
			if n == "\r":
				if not _peek(1) == "\n":
					# Validation: No carriage return without being part of a newline sequence
					# NOTE: Carriage returns are expected on Windows files, therefore this check
					_error(_line, _column, "Carriage return is only allowed as part of a newline sequence.")
					_advance(false) # Consume invalid carriage return so that synchronization can continue
					_synchronize()
					return
				_advance()
			_advance()
			_line += 1
			_column = 1
			_add_token(TOMLToken.TokenType.NEWLINE)
			# New line indicates new KEY if we are not inside a nested data structure
			if _tokenization_context_stack.is_empty():
				_tokenization_mode = TokenizationMode.KEY
		_:
			if _tokenization_mode == TokenizationMode.KEY:
				if n in QUOTE_CHARACTERS:
					_quoted_key()
					return
				elif _is_bare_key(n):
					_bare_key()
					return
			else:
				_value()
				return
			
			_error(_line, _column, "Unexpected character: '%c'" % n)
			_synchronize()
#endregion


## TOML Token helper class.
class TOMLToken:
	
	enum TokenType {
		# Document structure
		NEWLINE,
		EQUAL, COMMA, DOT,
		L_BRACKET, R_BRACKET,
		L_BRACE, R_BRACE,
		
		# Literals
		BARE_KEY, QUOTED_KEY,
		BASIC_STRING, MULTILINE_BASIC_STRING,
		LITERAL_STRING, MULTILINE_LITERAL_STRING,
		INTEGER, FLOAT, BOOL, DATETIME,
		
		# End of file
		EOF
	}
	
	
	var type: TokenType
	var lexeme: String
	var literal: Variant
	var line: int
	var column: int
	
	
	func _init(p_type: TokenType, p_lexeme: String, p_literal: Variant, p_line: int, p_column: int) -> void:
		type = p_type
		lexeme = p_lexeme
		literal = p_literal
		line = p_line
		column = p_column
	
	
	func _to_string() -> String:
		return "Token: [%-10s] | Lexeme: <%s> | Line: %d, Column: %d" % [TokenType.keys()[self.type], self.lexeme.replace("\n", "\\n"), self.line, self.column]
