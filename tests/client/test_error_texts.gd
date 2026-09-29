extends "res://tests/test_case.gd"
## Every error code the server or transport can send a player has text in
## UiText.ERRORS (client review C17), so nobody sees "Something went wrong".

const SOURCE_DIRS := ["res://src/match", "res://src/net", "res://src/profile", "res://src/server"]

## Words returned by the same helpers that are not error codes.
const NOT_ERRORS := ["in_match"]


func test_every_server_error_code_has_player_text() -> void:
	var codes := _error_codes()
	assert_true(codes.size() > 30, "scan found the server error codes (%d)" % codes.size())
	for code in codes:
		assert_true(UiText.ERRORS.has(code), "UiText.ERRORS has text for '%s' (%s)" % [code, ", ".join(codes[code])])


func test_error_texts_are_full_sentences() -> void:
	for code in UiText.ERRORS:
		var text: String = UiText.ERRORS[code]
		assert_true(text.length() > 8 and text.ends_with("."), "'%s' text is a sentence: %s" % [code, text])
		assert_false(text.contains("(%s)" % code) or text.contains("_"), "'%s' text does not show the raw code" % code)


func _error_codes() -> Dictionary:
	var patterns := [
		'"error"\\s*:\\s*"([a-z_]+)"',
		'_reject\\("([a-z_]+)"\\)',
		'_drop\\([^"\\n]*"([a-z_]+)"\\)',
		'reason\\s*=[^\\n]*"([a-z_]+)"',
		'^\\s*(?:return|error\\s*=)\\s*"([a-z]+_[a-z_]+)"\\s*$',
	]
	var regexes: Array[RegEx] = []
	for pattern in patterns:
		var regex := RegEx.new()
		regex.compile("(?m)" + pattern)
		regexes.append(regex)
	var found := {}
	for dir in SOURCE_DIRS:
		for path in _gd_files(dir):
			var source := FileAccess.get_file_as_string(path)
			for regex in regexes:
				for hit in regex.search_all(source):
					var code := hit.get_string(1)
					if NOT_ERRORS.has(code):
						continue
					if not found.has(code):
						found[code] = []
					if not found[code].has(path.get_file()):
						found[code].append(path.get_file())
	return found


func _gd_files(dir: String) -> Array[String]:
	var files: Array[String] = []
	var access := DirAccess.open(dir)
	if access == null:
		return files
	for entry in access.get_files():
		if entry.ends_with(".gd"):
			files.append(dir.path_join(entry))
	for sub in access.get_directories():
		files.append_array(_gd_files(dir.path_join(sub)))
	return files
