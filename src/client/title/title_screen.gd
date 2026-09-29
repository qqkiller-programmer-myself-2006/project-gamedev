class_name TitleScreen
extends Control

var _app: ClientApp
var _name: LineEdit
var _server: LineEdit
var _code: LineEdit
var _status: Label
var _seed: LineEdit
var _content: Control
var _view := "menu"
var _story_picks: Array[OptionButton] = []
const STORY_CLASSES := ["swordsman", "archer", "mage", "guardian", "assassin"]
const STORY_NAMES := ["Arin", "Bram", "Cora", "Dain", "Wren"]

func setup(app: ClientApp) -> void:
	_app = app
	var backdrop := HomeBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.setup(app.settings.reduced_motion)
	add_child(backdrop)
	_build_chrome()
	_show_menu()
	if _app.options.has("auto"):
		_show_multiplayer()
	if app.options.has("playtest") and app.can_playtest():
		_app.start_dev_playtest("")

func _build_chrome() -> void:
	var logo := UiKit.vbox(0)
	logo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	logo.position = Vector2(0, 28)
	logo.offset_bottom = 118
	var title := UiKit.pixel_label("BEYOND THE WORLD'S END", "huge", UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.add_theme_color_override("font_outline_color", UiKit.BG)
	title.add_theme_constant_override("outline_size", 10)
	logo.add_child(title)
	var subtitle := UiKit.label("Forest - a co-op journey", "heading")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	subtitle.position.y = 70
	logo.add_child(subtitle)
	add_child(logo)
	var build := UiKit.label("BUILD 0.10  |  FOREST SLICE", "small", UiKit.TEXT_DIM)
	build.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	build.autowrap_mode = TextServer.AUTOWRAP_OFF
	build.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	build.offset_left = 24
	build.offset_right = -24
	build.offset_top = -40
	build.offset_bottom = -12
	add_child(build)

func _show_menu() -> void:
	_view = "menu"
	_clear_content()
	var body := UiKit.vbox(10)
	body.custom_minimum_size = Vector2(340, 0)
	var panel := UiKit.panel(body)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.set_meta("base_y", 150.0)
	panel.position = Vector2(88, _top(150))
	panel.size = Vector2(390, 0)
	add_child(panel)
	_content = panel
	body.add_child(UiKit.label("WELCOME, TRAVELLER", "heading", UiKit.ACCENT))
	body.add_child(UiKit.para("Choose your path into the forest.", "dim"))
	var play := UiKit.primary("Play", _show_play)
	play.set_meta("focus_id", "play")
	body.add_child(play)
	if _app.can_playtest():
		var dev_row := UiKit.hbox(6)
		var dev := UiKit.button("[DEV] Playtest  >", func() -> void: _app.start_dev_playtest(_seed.text if is_instance_valid(_seed) else ""), true)
		dev.set_meta("focus_id", "playtest")
		dev.set_meta("dev", true)
		dev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dev.tooltip_text = "DEV: embedded server, single-player fast path"
		dev.add_theme_color_override("font_color", UiKit.WARN)
		dev_row.add_child(dev)
		var options := UiKit.button("Seed", _toggle_playtest_options)
		options.set_meta("dev", true)
		options.tooltip_text = "Playtest options: fixed seed"
		options.custom_minimum_size = Vector2(72, 0)
		dev_row.add_child(options)
		body.add_child(dev_row)
		_seed = _line_edit("", "Playtest seed (optional number)", 12)
		_seed.custom_minimum_size.y = 34
		_seed.tooltip_text = "Same seed = same route and fights"
		_seed.visible = false
		body.add_child(_seed)
	var settings := UiKit.button("Settings [F2]", _app.open_settings)
	settings.set_meta("focus_id", "settings")
	body.add_child(settings)
	var credits := UiKit.button("Credits", _show_credits)
	credits.set_meta("focus_id", "credits")
	body.add_child(credits)
	if not OS.has_feature("web"):
		body.add_child(UiKit.button("Quit", func() -> void: _app.stop_dev_playtest(); get_tree().quit()))
	UiKit.focus_first(body)

func _toggle_playtest_options() -> void:
	if is_instance_valid(_seed):
		_seed.visible = not _seed.visible
		if _seed.visible:
			_seed.grab_focus()

func _show_play() -> void:
	_view = "play"
	_clear_content()
	var body := UiKit.vbox(12)
	body.custom_minimum_size = Vector2(420, 0)
	var panel := UiKit.panel(body)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.set_meta("base_y", 175.0)
	panel.position = Vector2(88, _top(175))
	panel.size = Vector2(460, 0)
	add_child(panel)
	_content = panel
	body.add_child(UiKit.label("CHOOSE YOUR JOURNEY", "heading", UiKit.ACCENT))
	body.add_child(UiKit.label("Story · offline, control all five", "body"))
	var has_save: bool = _app.story_save.has_save()
	if has_save:
		var resume := UiKit.primary("Continue Story", func() -> void: _app.start_story([], _app.story_save.load()))
		resume.set_meta("focus_id", "continue_story")
		body.add_child(resume)
	var story := UiKit.button("New Story", _show_story_setup, true, "secondary" if has_save else "primary")
	story.set_meta("focus_id", "new_story")
	body.add_child(story)
	body.add_child(HSeparator.new())
	body.add_child(UiKit.label("Multiplayer · create or join a room", "body"))
	var multiplayer_button := UiKit.button("Multiplayer", _show_multiplayer, true)
	multiplayer_button.set_meta("focus_id", "multiplayer")
	body.add_child(multiplayer_button)
	body.add_child(UiKit.button("Back [Esc]", _show_menu))
	UiKit.focus_first(body)

func _show_story_setup() -> void:
	_view = "story_setup"
	_clear_content()
	_story_picks.clear()
	var body := UiKit.vbox(8)
	body.custom_minimum_size = Vector2(450, 0)
	var panel := UiKit.panel(body)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.set_meta("base_y", 175.0)
	panel.position = Vector2(88, _top(175))
	panel.size = Vector2(490, 0)
	add_child(panel)
	_content = panel
	body.add_child(UiKit.label("STORY PARTY", "heading", UiKit.ACCENT))
	body.add_child(UiKit.para("Choose a Class for every traveller.", "dim"))
	for i in STORY_NAMES.size():
		var row := UiKit.hbox(10)
		var name_label := UiKit.label(STORY_NAMES[i], "body")
		name_label.custom_minimum_size.x = 100
		row.add_child(name_label)
		var pick := OptionButton.new()
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for class_id in STORY_CLASSES:
			pick.add_item(class_id.capitalize())
		pick.select(i)
		_story_picks.append(pick)
		row.add_child(pick)
		body.add_child(row)
	body.add_child(UiKit.primary("Begin Story", _begin_story))
	body.add_child(UiKit.button("Back [Esc]", _show_play))
	UiKit.focus_first(body)

func _begin_story() -> void:
	var classes := []
	for pick in _story_picks:
		classes.append(STORY_CLASSES[pick.selected])
	_app.start_story(classes)

func _show_multiplayer() -> void:
	_view = "multiplayer"
	_clear_content()
	var body := UiKit.vbox(10)
	body.custom_minimum_size = Vector2(520, 0)
	var panel := UiKit.panel(body)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.set_meta("base_y", 150.0)
	panel.position = Vector2(88, _top(150))
	panel.size = Vector2(560, 0)
	add_child(panel)
	_content = panel
	body.add_child(UiKit.label("ENTER THE FOREST", "heading", UiKit.ACCENT))
	body.add_child(UiKit.label("Your name (shown to other players)", "dim"))
	_name = _line_edit(_app.settings.player_name, "e.g. Arin", 16)
	body.add_child(_name)
	var create := UiKit.primary("Create a room", _create)
	create.set_meta("focus_id", "create")
	body.add_child(create)
	body.add_child(HSeparator.new())
	body.add_child(UiKit.label("Have a Room code? Letters and numbers, case does not matter.", "dim"))
	var row := UiKit.hbox(8)
	_code = _line_edit(str(_app.options.get("join", "")), "Room code", 12)
	_code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_code.text_submitted.connect(func(_t: String) -> void: _join())
	row.add_child(_code)
	var join := UiKit.button("Join room", _join)
	join.tooltip_text = "Type the Room code, then press Enter or click here"
	join.set_meta("focus_id", "join")
	row.add_child(join)
	body.add_child(row)
	var advanced := CheckButton.new()
	advanced.text = "Advanced connection options"
	advanced.toggled.connect(func(on: bool) -> void: _server.visible = on)
	body.add_child(advanced)
	_server = _line_edit(_app.server_url(), ClientApp.DEFAULT_URL, 200)
	_server.visible = false
	_server.tooltip_text = "WebSocket server address"
	body.add_child(_server)
	_status = UiKit.para("", "body", UiKit.WARN)
	_status.visible = false
	body.add_child(_status)
	var back := UiKit.button("Back [Esc]", _show_play)
	back.set_meta("focus_id", "back")
	body.add_child(back)
	create.grab_focus.call_deferred()
	if _app.options.has("auto") and not _name.text.is_empty():
		(_join if not _code.text.is_empty() else _create).call_deferred()

func _show_credits() -> void:
	_view = "credits"
	_clear_content()
	var body := UiKit.vbox(14)
	body.custom_minimum_size = Vector2(420, 0)
	var panel := UiKit.panel(body)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.set_meta("base_y", 150.0)
	panel.position = Vector2(88, _top(150))
	panel.size = Vector2(470, 0)
	add_child(panel)
	_content = panel
	body.add_child(UiKit.label("BEYOND THE WORLD'S END", "title", UiKit.ACCENT))
	body.add_child(UiKit.label("Made with Godot 4.7", "heading"))
	body.add_child(UiKit.para("Font: Pixelify Sans, OFL\nCharacter art by the project owner.", "body"))
	body.add_child(UiKit.primary("Back [Esc]", _show_menu, false))
	UiKit.focus_first(body)

## Panels start lower with bigger text so they clear the logo's subtitle.
func _top(y: float) -> float:
	return y + 50.0 * maxf(0.0, _app.settings.text_scale - 1.0)

func _notification(what: int) -> void:
	# The text size can change while the title is open (Settings).
	if what == NOTIFICATION_THEME_CHANGED and _app != null and is_instance_valid(_content):
		_content.position.y = _top(float(_content.get_meta("base_y", 150.0)))

func _clear_content() -> void:
	if is_instance_valid(_content):
		_content.queue_free()
	_content = null

func show_error(message: String) -> void:
	if _status == null:
		return
	_status.text = message
	_status.visible = true

func _create() -> void:
	if not _remember():
		return
	var display_name := _name.text.strip_edges()
	_app.connect_and(_server.text.strip_edges(), func() -> void: _app.send({"type": "create_room", "name": display_name}))

func _join() -> void:
	if not _remember():
		return
	if _code.text.strip_edges().is_empty():
		show_error(UiText.error("invalid_code"))
		_code.grab_focus()
		return
	var display_name := _name.text.strip_edges()
	_app.connect_and(_server.text.strip_edges(), func() -> void: _app.send({"type": "join_room", "code": _code.text.strip_edges(), "name": display_name}))

func _remember() -> bool:
	if _name.text.strip_edges().is_empty():
		show_error(UiText.error("invalid_name"))
		_name.grab_focus()
		return false
	_status.visible = false
	_app.settings.player_name = _name.text.strip_edges()
	_app.settings.server_url = _server.text.strip_edges()
	_app.settings.save()
	return true

func handle_key(app: ClientApp, keycode: int) -> bool:
	if keycode == KEY_ESCAPE:
		# Esc does what the Back button of the current view does.
		match _view:
			"story_setup", "multiplayer":
				_show_play()
			"play", "credits":
				_show_menu()
			_:
				app.stop_dev_playtest()
		return true
	return false

static func _line_edit(text: String, placeholder: String, max_length: int) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = text
	edit.placeholder_text = placeholder
	edit.max_length = max_length
	edit.custom_minimum_size = Vector2(0, 42)
	return edit
