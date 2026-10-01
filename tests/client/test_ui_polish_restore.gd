extends "res://tests/test_case.gd"


func _has_text(node: Node, wanted: String) -> bool:
	if node is Label and str(node.text).contains(wanted):
		return true
	if node is Button and str(node.text).contains(wanted):
		return true
	for child in node.get_children():
		if _has_text(child, wanted):
			return true
	return false


func test_personal_gold_hud_and_reward_share_are_for_the_viewer() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app.snapshot = {"room": {"your_slot": 1}, "match": {"party": [
		{"slot": 0, "gold": 8, "race": "Human"},
		{"slot": 1, "gold": 7, "race": "Human"},
	]}}
	var screen := MatchScreen.new()
	screen.app = app
	assert_eq(screen.personal_gold_share(11), 5)
	screen._top = UiKit.hbox(4)
	screen._build_top(app.snapshot["match"])
	assert_true(_has_text(screen._top, "Your Gold: 7"))
	assert_false(_has_text(screen._top, "Gold: 15"))
	app.snapshot["room"]["your_slot"] = 0
	app.snapshot["match"]["party"][0]["race"] = "Kobold"
	assert_eq(screen.personal_gold_share(11), 7)
	assert_eq(UiText.error("not_enough_gold"), "You do not have enough Gold.")
	screen.free()
	app.free()


func test_dot_tip_describes_only_the_visible_stack_count() -> void:
	var tip: String = UiText.HINTS["dot"]
	assert_true(tip.contains("stack count"))
	assert_true(tip.contains("hover"))
	assert_false(tip.contains("(t)"))


func test_escape_on_list_screens_opens_the_match_menu_first() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app._overlay_holder = Control.new()
	app.add_child(app._overlay_holder)
	var screen := MatchScreen.new()
	screen.app = app
	screen._list_menu = screen.build_corner_menu(screen, false)
	assert_true(screen.handle_key(app, KEY_ESCAPE))
	assert_true(screen._list_menu.visible)
	assert_eq(app._overlay_holder.get_child_count(), 0)
	assert_true(screen.handle_key(app, KEY_ESCAPE))
	assert_false(screen._list_menu.visible)
	var items := screen._list_menu.get_child(0)
	var leave: Button
	for item in items.get_children():
		if item is Button and str(item.text).contains("Leave"):
			leave = item
			break
	assert_true(leave != null)
	leave.pressed.emit()
	assert_true(app._overlay_holder.get_child(0) is ConfirmDialog)
	screen.free()
	app.free()


func test_open_story_dialogue_receives_live_accessibility_settings() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	var screen := MatchScreen.new()
	app._current = screen
	app.add_child(screen)
	var director := StoryDirector.new()
	var dialogue := DialoguePanel.new([{"speaker": "narrator", "text": "A long enough line to exercise the live layout."}], 1.0, false)
	director.current = dialogue
	screen._story_director = director
	app.settings.text_scale = 1.45
	app.settings.reduced_motion = true
	app.apply_settings()
	assert_eq(dialogue.text_scale, 1.45)
	assert_true(dialogue.reduced_motion)
	assert_eq(dialogue._text_label.visible_characters, -1)
	assert_eq(dialogue._speaker, "NARRATOR")
	dialogue.free()
	director.free()
	app.free()


func test_story_dialogue_grows_to_fit_wrapped_content() -> void:
	var short := DialoguePanel.new([{"speaker": "narrator", "text": "Short."}], 1.0, true)
	short.size = Vector2(1280, 720)
	short._layout()
	var short_height := -short.offset_top
	var long_text := "A long passage that wraps over several lines. ".repeat(18)
	var long := DialoguePanel.new([{"speaker": "narrator", "text": long_text}], 1.0, true)
	long.size = Vector2(1280, 720)
	long._layout()
	assert_true(-long.offset_top > short_height, "dialogue panel grows for wrapped lines")
	assert_eq(long._speaker, "NARRATOR")
	short.free()
	long.free()


func test_story_escape_stays_with_the_open_presentation() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app._overlay_holder = Control.new()
	app.add_child(app._overlay_holder)
	var screen := MatchScreen.new()
	screen.app = app
	screen._list_menu = screen.build_corner_menu(screen, false)
	var director := StoryDirector.new()
	director.current = DialoguePanel.new([{"speaker": "narrator", "text": "Hello"}], 1.0, false)
	screen._story_director = director
	assert_true(screen.handle_key(app, KEY_ESCAPE))
	assert_false(screen._list_menu.visible)
	assert_eq(app._overlay_holder.get_child_count(), 0)
	director.current.free()
	director.free()
	screen.free()
	app.free()


class DummyScreen extends Control:
	var received_key := -1
	func handle_key(_client, key: int) -> bool:
		received_key = key
		return true


func test_banner_allows_escape_to_screen_and_f2_to_settings() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app._overlay_holder = Control.new()
	app.add_child(app._overlay_holder)
	app._build_banner()
	app._banner.visible = true
	var screen := DummyScreen.new()
	app._current = screen
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	app._unhandled_key_input(escape)
	assert_eq(screen.received_key, KEY_ESCAPE)
	var f2 := InputEventKey.new()
	f2.pressed = true
	f2.keycode = KEY_F2
	app._banner.visible = true
	app._unhandled_key_input(f2)
	assert_true(app._overlay_holder.get_child_count() > 0)
	assert_true(app._overlay_holder.get_child(0) is SettingsPanel)
	screen.free()
	app.free()


func test_lobby_toast_uses_the_top_right_safe_area() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app._current = LobbyScreen.new()
	app._toast = PanelContainer.new()
	app._toast_label = Label.new()
	app._toast.add_child(app._toast_label)
	app.add_child(app._toast)
	app.toast("Room code copied")
	assert_eq(app._toast.anchor_top, 0.0)
	assert_eq(app._toast.anchor_right, 1.0)
	assert_true(app._toast.offset_right < 0.0)
	app.free()


func test_character_class_pager_uses_drawn_dots() -> void:
	var script := load("res://src/client/lobby/character_setup.gd")
	assert_true(script.source_code.contains("class PagerDots extends Control"))
	assert_true(script.source_code.contains("draw_circle(Vector2(x, size.y * 0.5)"))
	assert_false(script.source_code.contains("_center(\"O \""))
