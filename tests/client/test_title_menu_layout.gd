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
