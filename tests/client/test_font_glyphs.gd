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


func test_pixel_font_ligatures_are_disabled() -> void:
	UiKit.pixel_font()
	var loaded_font := load(UiKit.PIXEL_FONT_PATH)
	assert_true(loaded_font is Font, "imported pixel font loads")
	assert_eq(_glyph_count("fi", loaded_font), 2, "imported pixel font does not shape fi as a ligature")
	assert_eq(_glyph_count("fi", UiKit.pixel_font()), 2, "pixel font variation does not shape fi as a ligature")

	var font := UiKit.pixel_font()
	assert_true(font is FontVariation, "pixel font is a FontVariation")
	var variation := font as FontVariation
	assert_eq(variation.opentype_features.get("liga", -1), 0, "standard ligatures are disabled")
	assert_eq(variation.opentype_features.get("clig", -1), 0, "contextual ligatures are disabled")
	assert_eq(variation.opentype_features.get("dlig", -1), 0, "discretionary ligatures are disabled")


func test_numeric_style_uses_digit_safe_font() -> void:
	var title := UiKit.label("-12", "title")
	assert_eq(title.get_theme_font("font"), UiKit.number_font(), "numeric title labels use the digit-safe body font")
	var heading := UiKit.label("Gold: 34", "heading")
	assert_eq(heading.get_theme_font("font"), UiKit.number_font(), "numeric heading labels use the digit-safe body font")
	var plain_heading := UiKit.label("Profile", "heading")
	assert_false(plain_heading.has_theme_font_override("font"), "word heading labels keep the themed pixel font")

	var numeric := UiKit.pixel_label("Lvl 5 · 70/70", "heading")
	assert_eq(numeric.get_theme_font("font"), UiKit.number_font(), "numeric labels use the digit-safe body font")
	var numeric_button := UiKit.button("Reset Skills 50 Gems", func() -> void: pass)
	assert_eq(numeric_button.get_theme_font("font"), UiKit.number_font(), "numeric buttons use the digit-safe body font")
	var words := UiKit.pixel_label("Profile", "heading")
	assert_eq(words.theme_type_variation, "PixelHeadingLabel", "word labels keep the pixel font")


func _glyph_count(text: String, font: Font) -> int:
	var line := TextLine.new()
	line.add_string(text, font, 32)
	return TextServerManager.get_primary_interface().shaped_text_get_glyph_count(line.get_rid())


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
