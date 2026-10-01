extends TestCase

var _title: TitleScreen
var _app: ClientApp


func after_each() -> void:
	if _title != null and is_instance_valid(_title):
		_title.free()
	_title = null
	if _app != null and is_instance_valid(_app):
		_app.free()
	_app = null


func test_title_menu_is_centered_at_common_resolutions() -> void:
	_app = ClientApp.new()
	_app.settings = ClientSettings.new()
	_app.options = {}
	_title = TitleScreen.new()
	_title.setup(_app)

	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		_title.size = Vector2(resolution)
		var panel := _title._content as PanelContainer
		_title._layout_narrow_panel(panel)
		var center_x := _title.size.x * panel.anchor_left + (panel.offset_left + panel.offset_right) * 0.5
		assert_true(absf(center_x - resolution.x * 0.5) <= 2.0,
				"menu centre stays within 2 px at %s" % resolution)

	var buttons := _title.find_children("*", "Button", true, false)
	assert_true(not buttons.is_empty(), "title menu has buttons")
	assert_eq(str(buttons[0].get_meta("focus_id", "")), "play", "Play remains the first focused button")
	for button in buttons:
		assert_false(str(button.text).contains("Playtest"), "title menu has no on-screen Playtest button")


func test_title_menu_buttons_fit_at_large_text_scale() -> void:
	_app = ClientApp.new()
	_app.settings = ClientSettings.new()
	_app.settings.text_scale = 1.4
	_app.options = {}
	_app.apply_settings()
	_title = TitleScreen.new()
	_title.theme = _app.theme
	_title.setup(_app)
	_app.add_child(_title)

	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		_title.size = Vector2(resolution)
		_title._layout_narrow_panel(_title._content as PanelContainer)
		var viewport := Rect2(Vector2.ZERO, Vector2(resolution))
		var panel := _title._content as PanelContainer
		var scroll := panel.get_child(0) as ScrollContainer
		var body := scroll.get_child(0) as Control
		var panel_rect := Rect2(Vector2(panel.offset_left + resolution.x * panel.anchor_left, panel.offset_top),
				Vector2(panel.offset_right - panel.offset_left, panel.offset_bottom - panel.offset_top))
		assert_true(viewport.encloses(panel_rect), "large-text menu panel fits inside %s" % resolution)
		assert_true(scroll.custom_minimum_size.y >= body.get_combined_minimum_size().y,
				"all menu content fits without scrolling at %s" % resolution)
		for button_name in ["Play", "Settings [F2]", "Credits", "Quit"]:
			var button := _find_button(button_name)
			assert_true(button != null, "%s button exists at %s" % [button_name, resolution])


func _find_button(button_text: String) -> Button:
	for node in _title.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text == button_text:
			return button
	return null
