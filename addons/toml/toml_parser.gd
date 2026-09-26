## TOML Recursive Descendant Parser.
##
## Parses a list of valid TOML tokens into a Dictionary[Variant, Variant].

enum ParserContext {
	ARRAY,
	INLINE_TABLE,
}

const TOMLLexer = preload("uid://cangnbsyvnbnj")
const TOMLToken = TOMLLexer.TOMLToken

const VALID_VALUE_TOKENS: Array[TOMLToken.TokenType] = [
	TOMLToken.TokenType.BASIC_STRING,
	TOMLToken.TokenType.MULTILINE_BASIC_STRING,
	TOMLToken.TokenType.LITERAL_STRING,
	TOMLToken.TokenType.MULTILINE_LITERAL_STRING,
	TOMLToken.TokenType.INTEGER,
	TOMLToken.TokenType.FLOAT,
	TOMLToken.TokenType.BOOL,
	TOMLToken.TokenType.DATETIME,
]


#region Members
## Tokens input Array.
var _tokens: Array[TOMLToken]
## If [code]true[/code], the parser reported an error during parsing.
var _had_error: bool

## Current token position on [member _tokens]
var _current: int
## The complete table representing the whole TOML parsed document.
var _toml_root: TOMLTable
## Current TOML table that is being parsed. Updated after a table header.
var _current_table: TOMLTable
#endregion


## Parses a TOML token list and returns a Godot [class Dictionary[Variant, Variant]][br]
## Returns an empty dictionary if an error occured during parsing.
## Use [method had_error] to check for errors after parsing.
func parse(p_tokens: Array[TOMLToken]) -> Dictionary[Variant, Variant]:
	_tokens = p_tokens
	_had_error = false
	
	_current = 0
	_toml_root = TOMLTable.new(true, true)
	_current_table = _toml_root
	
	_parse_toml()
	
	if _had_error:
		return {}
	return _toml_root.get_content()


## Returns [code]true[/code] if the parser reported an error during parsing.
func had_error() -> bool:
	return _had_error


## Reports a parser error.
func _error(line: int, column: int, msg: String) -> void:
	push_error("TOML Parser error at (%d:%d): %s" % [line, column, msg])
	_had_error = true


#region Token navigation
#region Token skipping and synchronization
## Returns [code]true[/code] if the following sequence is a valid table header.
func _is_valid_table_header_ahead() -> bool:
	if not _check(TOMLToken.TokenType.L_BRACKET):
		return false
	
	var idx: int = 1
	var has_content: bool = false
	
	while not _is_at_end():
		if _check(TOMLToken.TokenType.BARE_KEY, idx) or _check(TOMLToken.TokenType.QUOTED_KEY, idx) or _check(TOMLToken.TokenType.DOT, idx):
			has_content = true
			idx += 1
		elif _check(TOMLToken.TokenType.R_BRACKET, idx) and _check(TOMLToken.TokenType.NEWLINE, idx + 1):
			return has_content
		else:
			return false
	return false


## Skips until the next COMMA token.
func _skip_until(token_type: TOMLToken.TokenType) -> void:
	while not _is_at_end():
		if _check(token_type):
			break
		_advance()


## Skips tokens until reaching a safe-to-continue state.
func _synchronize() -> void:
	_advance()
	
	while not _is_at_end():
		if _is_valid_table_header_ahead():
			return
		
		if _check(TOMLToken.TokenType.NEWLINE):
			_advance()
			# If the next line starts with a key
			if _check(TOMLToken.TokenType.BARE_KEY) or _check(TOMLToken.TokenType.QUOTED_KEY):
				return
			
			continue
		
		_advance()


## Skip all following NEWLINE tokens until a different one is reached.
## Useful when inside data structures that can extend over several lines.
func _skip_newlines() -> void:
	while not _is_at_end():
		if not _match(TOMLToken.TokenType.NEWLINE):
			break
#endregion


## Returns [code]true[/code] if the [member _current] pointer reached the EOF token.
func _is_at_end(offset: int = 0) -> bool:
	if _current + offset >= _tokens.size():
		return true
	return _tokens[_current + offset].type == TOMLToken.TokenType.EOF


## Returns [code]true[/code] if the [_param current] + [param offset] token
## is of the specified type.
func _check(type: TOMLToken.TokenType, offset: int = 0) -> bool:
	if _is_at_end(offset):
		return false
	return _tokens[_current + offset].type == type


## Returns the next [member _current] + [param offset] token,
## without advancing the pointer.
func _peek(offset: int = 0) -> TOMLToken:
	if _current + offset >= _tokens.size():
		return null
	return _tokens[_current + offset]


## Advances the [member _current] pointer by one.
func _advance() -> TOMLToken:
	if not _is_at_end():
		_current += 1
	return _tokens[_current - 1]


## Consumes the following token and returns [code]true[/code]
## if it matches [param type].
func _match(type: TOMLToken.TokenType) -> bool:
	if _peek().type == type:
		_advance()
		return true
	return false


## Creates tables on [param root] recursively following a [param table_path].
## If [param is_for_value], it checks for invalid overwriting of explicitly defined tables.
func _create_tables_recursive(root: TOMLTable, table_path: Array[StringName], is_for_value: bool) -> TOMLTable:
	# TOML is not nested, all paths are absolute -> We start from the root
	var target_table: TOMLTable = root
	var path_idx: int = 0
	while path_idx < table_path.size() - 1:
		var key: StringName = table_path[path_idx]
		
		if target_table.content.has(key):
			var existing: Variant = target_table.content[key]
			# Check if its an Array of Tables (We use GDScript's typing system for the check)
			# Array[TOMLTable] == valid Array of Tables
			# Array[Variant] == static array defined in a key-val
			if existing is Array[TOMLTable]:
				if is_for_value:
					return null
				target_table = existing.back()
				
			# Continue through table
			elif existing is TOMLTable:
				if existing.was_defined_explicitly and is_for_value:
					# Validation: We can't traverse through a explicitly defined table to append
					# a table or value
					return null
				target_table = existing
			
			# Can't traverse a value (Anything apart from Array of Tables or Table)
			else:
				return null
		# Create a new table if it doesn't exist
		else:
			# If we are creating tables for a value -> not created_from_header
			var new_table := TOMLTable.new(false, not is_for_value)
			target_table.content[key] = new_table
			target_table = new_table
		
		path_idx += 1
	
	return target_table
#endregion


#region Recursive Descendent Parsing methods
## Parses an Array of any TOML values (Including other arrays or inline tables).
func _parse_array() -> Array[Variant]:
	var r: Array[Variant] = []
	
	# Validation: Array opening
	if not _match(TOMLToken.TokenType.L_BRACKET):
		_error(_peek().line, _peek().column, "Invalid array opening, expecting '['.")
		_synchronize()
		return [null]
	
	while not _is_at_end():
		_skip_newlines()
		
		if _check(TOMLToken.TokenType.R_BRACKET):
			break
		
		# Validation: Valid value
		var next_value: Variant = _parse_value()
		if next_value == null:
			_error(_peek().line, _peek().column, "Invalid value inside array.")
			_skip_until(TOMLToken.TokenType.COMMA)
		
		r.append(next_value)
		
		_skip_newlines()
		
		if not _match(TOMLToken.TokenType.COMMA):
			break
		
		_skip_newlines()
	
	_skip_newlines()
	
	# Validation: Array closing
	if not _match(TOMLToken.TokenType.R_BRACKET):
		_error(_peek().line, _peek().column, "Invalid array closing, expecting ']'.")
		_synchronize()
		return [null]
	
	return r


## Parses an inline table. Similar to parsing a normal table, but locally.
func _parse_inline_table() -> Dictionary[Variant, Variant]:
	var r: TOMLTable = TOMLTable.new(false, true)
	
	# Validation: Inline table opening
	if not _match(TOMLToken.TokenType.L_BRACE):
		_error(_peek().line, _peek().column, "Invalid inline table opening, expecting '{'.")
		_synchronize()
		return {null: null}
	
	while not _is_at_end():
		_skip_newlines()
		
		if _check(TOMLToken.TokenType.R_BRACE):
			break
		
		_parse_key_value(r)
		
		if not _match(TOMLToken.TokenType.COMMA):
			break
	
	_skip_newlines()
	
	# Validation: Inline table closing
	if not _match(TOMLToken.TokenType.R_BRACE):
		_error(_peek().line, _peek().column, "Invalid inline table closing, expecting '}'.")
		_synchronize()
		return {null: null}
	
	return r.get_content()


## Parses any valid TOML value and returns it.
## Returns [code]null[/code] on error.
func _parse_value() -> Variant:
	# Check for Inline Table
	if _check(TOMLToken.TokenType.L_BRACE):
		var r: Dictionary[Variant, Variant] = _parse_inline_table()
		if r == {null: null}:
			return null
		return r
	# Check for Array
	elif _check(TOMLToken.TokenType.L_BRACKET):
		var r: Array[Variant] = _parse_array()
		if r == [null]:
			return null
		return r
	# If it is not Inline Table or Array -> Literal
	else:
		# Verify the token type is valid for a value
		if not _peek().type in VALID_VALUE_TOKENS:
			return null
		return _advance().literal


## Parses the tokens (BARE/QUOTED_KEY and DOT) from a key.
## Separates keys using the DOT token.
func _parse_key_components() -> Array[StringName]:
	# Validation: Key paths can't start with a dot
	if _check(TOMLToken.TokenType.DOT):
		_error(_peek().line, _peek().column, "Key can't start with a dot.")
		return []
	
	var has_trailing_dot: bool = false
	var keys: Array[StringName] = []
	while not _is_at_end():
		if not _peek().type in [TOMLToken.TokenType.BARE_KEY, TOMLToken.TokenType.QUOTED_KEY]:
			break
		
		keys.append(_advance().literal)
		has_trailing_dot = false
		
		if not _match(TOMLToken.TokenType.DOT):
			break
		has_trailing_dot = true
	
	# Validation: Key paths can't have a trailing dot
	if has_trailing_dot:
		_error(_peek().line, _peek().column, "Invalid trailing dot in key.")
		return []
	
	return keys


## Parses a [code]KEY = VALUE[/code] pair and adds the value to [param root_table].
func _parse_key_value(root_table: TOMLTable) -> void:
	var keys: Array[StringName] = _parse_key_components()
	
	# Validation: Invalid empty key
	if keys.is_empty():
		_error(_peek().line, _peek().column, "Empty value key.")
		_synchronize()
		return
	
	var target_table: TOMLTable = _create_tables_recursive(root_table, keys, true)
	
	# Validation: Invalid table path
	if target_table == null:
		_error(_peek().line, _peek().column, "Cannot traverse value or explicitly defined table to append values.")
		_synchronize()
		return
	
	# If it was defined explicitly, all its data should be defined under its header
	# Validation: Appending to a explicitly defined table (via dotted key) is not allowed
	if _current_table != target_table and target_table.was_defined_explicitly:
		_error(_peek().line, _peek().column, "Can't extend explicitly defined table.")
		_synchronize()
		return
	
	# Validation: Values can't be overwriten
	if target_table.content.has(keys.back()):
		_error(_peek().line, _peek().column, "Key \"%s\" is already defined." % keys.back())
		_synchronize()
		return
	
	# Validation: Expected EQUAL token between key and value
	if not _match(TOMLToken.TokenType.EQUAL):
		_error(_peek().line, _peek().column, "Expected '=' after key.")
		_synchronize()
		return
	
	# Validation: Valid value
	var value: Variant = _parse_value()
	if value == null:
		_error(_peek().line, _peek().column, "Invalid value.")
		_synchronize()
		return
	
	target_table.content[keys.back()] = value


## Parses an array of tables header defined as [[<key>]],
## setting [member _current_table] to a new table.
func _parse_array_of_tables_header() -> void:
	if not (_check(TOMLToken.TokenType.L_BRACKET) and _check(TOMLToken.TokenType.L_BRACKET, 1)):
		_error(_peek().line, _peek().column, "Invalid Array of Tables, expected opening \"[[\".")
		_synchronize()
		return
	
	# Validation: Both opening brackets can't be separated be spaces
	if not _peek().column + 1 == _peek(1).column:
		_error(_peek().line, _peek().column, "Array of tables opening brackets can't have whitespaces in between.")
		_synchronize()
		return
		
	
	_advance(); _advance()
	
	var array_path: Array[StringName] = _parse_key_components()
	
	# Validation: Invalid empty Array of Tables key
	if array_path.is_empty():
		_error(_peek().line, _peek().column, "Invalid array of tables key.")
		_synchronize()
		return
	
	var target_table: TOMLTable = _create_tables_recursive(_toml_root, array_path, false)
	
	# Validation: Array of Tables path must be valid
	if target_table == null:
		_error(_peek().line, _peek().column, "Cannot extend values.")
		_synchronize()
		return
	
	var new_table := TOMLTable.new(true, true)
	
	if target_table.content.has(array_path.back()):
		if target_table.content[array_path.back()] is not Array[TOMLTable]:
			_error(_peek().line, _peek().column, "Key is already defined and is not an array of tables.")
			_synchronize()
			return
		
		# Array of tables exists -> We append to it
		(target_table.content[array_path.back()] as Array[TOMLTable]).append(new_table)
	else:
		# Array of tables DOESN'T exists -> We create it together with the new table
		var new_array_of_tables: Array[TOMLTable] = [new_table]
		target_table.content[array_path.back()] = new_array_of_tables
	
	_current_table = new_table
	
	# Validation: Array of Tables closing
	if not (_check(TOMLToken.TokenType.R_BRACKET) and _check(TOMLToken.TokenType.R_BRACKET, 1)):
		_error(_peek().line, _peek().column, "Invalid Array of Tables closing, expected \"]]\".")
		_synchronize()
		return
	
	# Validation: Both closing brackets can't be separated by spaces
	if not _peek().column + 1 == _peek(1).column:
		_error(_peek().line, _peek().column, "Array of tables closing brackets can't have whitespaces in between.")
		_synchronize()
		return
	
	_advance(); _advance()


## Parses a table defined as [<key>], setting [member _current_table] to a new table.
func _parse_table_header() -> void:
	var table: Dictionary[Variant, Variant] = {}
	
	# Validation: Table header opening
	if not _match(TOMLToken.TokenType.L_BRACKET):
		_error(_peek().line, _peek().column, "Invalid table key opening: \"%s\"" % _peek().lexeme)
		_synchronize()
		return
	
	# Validation: Invalid empty Table key
	var table_path: Array[StringName] = _parse_key_components()
	if table_path.is_empty():
		_error(_peek().line, _peek().column, "Invalid table key.")
		_synchronize()
		return
	
	var target_table: TOMLTable = _create_tables_recursive(_toml_root, table_path, false)
	
	# Validation: Table path must be valid
	if target_table == null:
		_error(_peek().line, _peek().column, "Cannot extend values.")
		_synchronize()
		return
	
	# Validation: Can't redefine explicitly defined Tables or Arrays of Tables
	if target_table.content.has(table_path.back()):
		if target_table.content[table_path.back()] is not TOMLTable:
			_error(_peek().line, _peek().column, "Cannot redefine array of tables as table header")
			_synchronize()
			return
		
		var existing_table: TOMLTable = target_table.content[table_path.back()]
		if existing_table.was_defined_explicitly:
			# It exists and was defined explicitly already
			_error(_peek().line, _peek().column, "Cannot redefine table \"%s\"." % table_path.back())
			_synchronize()
			return
		if not existing_table.was_created_from_header:
			# It was created as a parent for another table AND from a dotted key
			_error(_peek().line, _peek().column, "Cannot redefine parent table \"%s\"." % table_path.back())
			_synchronize()
			return
		
		# It was created as a parent for another table AND from header -> Valid
		# Now it is defined explicitly
		existing_table.was_defined_explicitly = true
		_current_table = existing_table
	else:
		# New table created from header
		var new_table := TOMLTable.new(true, true)
		target_table.content[table_path.back()] = new_table
		_current_table = new_table
	
	# Validation: Table header closing
	if not _match(TOMLToken.TokenType.R_BRACKET):
		_error(_peek().line, _peek().column, "Invalid table key closing: \"%s\"" % _peek().lexeme)
		_synchronize()
		return


## Executes the token parsing loop for the TOML document.
func _parse_toml() -> void:
	# Skip first in case it is an empty document
	# This way EOF is reached and the loop is not executed
	_skip_newlines()
	
	while not _is_at_end():
		var n: TOMLToken = _peek()
		var newline_expected: bool = true
		
		match n.type:
			TOMLToken.TokenType.L_BRACKET:
				if _check(TOMLToken.TokenType.L_BRACKET, 1):
					# Double brackets -> Array of Tables
					_parse_array_of_tables_header()
				else:
					_parse_table_header()
			TOMLToken.TokenType.DOT, TOMLToken.TokenType.BARE_KEY, TOMLToken.TokenType.QUOTED_KEY:
				_parse_key_value(_current_table)
			_:
				_error(n.line, n.column, "Unexpected token: %s" % n)
				_synchronize()
				newline_expected = false
		
		# Validation: New line after previous statement
		if newline_expected and not _is_at_end():
			if not _match(TOMLToken.TokenType.NEWLINE):
				if not _had_error:
					_error(_peek().line, _peek().column, "Expected end of line after statement.")
				_synchronize()
		
		# Skip extra new lines between statements
		_skip_newlines()
#endregion


## TOML Table helper class.
##
## Contains metadata required for the correct validation of several
## table related operations.
## The [method get_content] method returns the raw [Dictionary] from tables recursively.
class TOMLTable:
	## The raw [Dictionary] holding the relevant parsed TOML data.
	var content: Dictionary[Variant, Variant]
	## If [code]true[/code] the table was defined explicitly (Not as a parent table)
	var was_defined_explicitly: bool
	## If [code]true[/code] the table was created through a TOML table header
	## ([<key>]) rather than from a dotted value key (<parent.parent2.value> = ...)
	var was_created_from_header: bool
	
	
	func _init(p_is_defined_explicitly: bool, p_is_created_from_header) -> void:
		content = {}
		was_defined_explicitly = p_is_defined_explicitly
		was_created_from_header = p_is_created_from_header
	
	
	## Returns the table's raw [Dictionary] without metadata
	## by calling this method recursively over other [TOMLTable]s.
	func get_content() -> Dictionary[Variant, Variant]:
		var result: Dictionary[Variant, Variant] = content
		for k in result:
			# recursively get subtables contents
			if result[k] is TOMLTable:
				result[k] = (result[k] as TOMLTable).get_content()
			# recursively get arrays of tables contents
			elif result[k] is Array[TOMLTable]:
				var result_array: Array[Dictionary] = []
				for t in result[k] as Array[TOMLTable]:
					result_array.append(t.get_content())
				result[k] = result_array
		
		return result
