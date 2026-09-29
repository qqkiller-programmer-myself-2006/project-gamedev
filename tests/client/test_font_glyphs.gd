extends "res://tests/test_case.gd"
## Pixelify Sans is the only font in the web build (no system fallback), so
## every non-ASCII character in client code and content must exist in it, or
## players see empty boxes (client review C9).


func test_client_text_only_uses_glyphs_the_pixel_font_has() -> void:
	var font := UiKit.pixel_font()
	assert_true(font != null, "pixel font loads")
	var seen := {}
	for path in _files("res://src/client", ".gd") + _files("res://content", ".json"):
		var source := FileAccess.get_file_as_string(path)
		for i in source.length():
			var code := source.unicode_at(i)
			if code > 127 and not seen.has(code):
				seen[code] = path
		var escapes := RegEx.create_from_string("\\\\u([0-9a-fA-F]{4})")
		for hit in escapes.search_all(source):
			var code := hit.get_string(1).hex_to_int()
			if code > 127 and not seen.has(code):
				seen[code] = path
	for code in seen:
		assert_true(font.has_char(code), "Pixelify Sans has U+%04X (used in %s)" % [code, seen[code]])


func _files(dir: String, extension: String) -> Array[String]:
	var files: Array[String] = []
	var access := DirAccess.open(dir)
	if access == null:
		return files
	for entry in access.get_files():
		if entry.ends_with(extension):
			files.append(dir.path_join(entry))
	for sub in access.get_directories():
		files.append_array(_files(dir.path_join(sub), extension))
	return files
