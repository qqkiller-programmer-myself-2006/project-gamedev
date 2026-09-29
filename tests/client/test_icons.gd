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
