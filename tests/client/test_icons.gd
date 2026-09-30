extends "res://tests/test_case.gd"


func test_all_icons_load_as_16_by_16_textures() -> void:
	for name in Icons.ICON_NAMES:
		var icon := Icons.texture(name)
		assert_true(icon != null, "%s loads" % name)
		assert_eq(icon.get_width(), 16, "%s width" % name)
		assert_eq(icon.get_height(), 16, "%s height" % name)


func test_unknown_icon_returns_visible_placeholder() -> void:
	var icon := Icons.texture("not_an_icon")
	assert_true(icon != null, "unknown icon has placeholder")
	assert_eq(icon.get_width(), 16, "placeholder width")
	assert_eq(icon.get_height(), 16, "placeholder height")
	assert_eq(icon.get_image().get_pixel(0, 0), Color.MAGENTA, "placeholder is visibly magenta")


func test_every_literal_client_icon_reference_exists() -> void:
	var patterns := [
		'Icons\\.(?:texture|rect|with_text)\\(\\s*"([a-z0-9_]+)"',
		'Icons\\.apply_to_button\\([^,]+,\\s*"([a-z0-9_]+)"',
	]
	var found := 0
	for path in _gd_files("res://src/client"):
		var file := FileAccess.open(path, FileAccess.READ)
		assert_true(file != null, "%s can be scanned" % path)
		if file == null:
			continue
		var source := file.get_as_text()
		for pattern in patterns:
			var regex := RegEx.new()
			assert_eq(regex.compile(pattern), OK, "icon-reference regex compiles")
			for result in regex.search_all(source):
				var name := result.get_string(1)
				found += 1
				assert_true(Icons.ICON_NAMES.has(name), "%s references known icon '%s'" % [path, name])
	assert_true(found > 0, "client icon references were scanned")


func test_camp_tab_labels_fit_with_icons_at_supported_text_scales() -> void:
	var labels := ["Stash", "Shop", "Craft", "Inventory", "Abilities"]
	for scale in [1.0, 1.5]:
		var theme := UiKit.make_theme(scale)
		for label in labels:
			var button := UiKit.button(label, func() -> void: pass)
			button.theme = theme
			var icon_size := Icons.size_for_scale(scale)
			var icon_image := Image.create(icon_size, icon_size, false, Image.FORMAT_RGBA8)
			button.icon = ImageTexture.create_from_image(icon_image)
			button.add_theme_font_override("font", UiKit.pixel_font())
			button.add_theme_font_size_override("font_size",
					maxi(16, int(UiKit.SIZES["small"] * scale)))
			button.clip_text = false
			var font_size := button.get_theme_font_size("font_size")
			var required_width := button.get_theme_stylebox("normal").get_minimum_size().x \
					+ icon_size + 8.0 \
					+ UiKit.pixel_font().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT,
							-1, font_size).x
			assert_true(CampView.tab_width_for_scale(scale) >= required_width,
					"%s fits with its icon at %.1fx text scale" % [label, scale])
			button.free()


static func _gd_files(root: String) -> Array[String]:
	var paths: Array[String] = []
	for file in DirAccess.get_files_at(root):
		if file.ends_with(".gd"):
			paths.append(root.path_join(file))
	for directory in DirAccess.get_directories_at(root):
		paths.append_array(_gd_files(root.path_join(directory)))
	return paths
