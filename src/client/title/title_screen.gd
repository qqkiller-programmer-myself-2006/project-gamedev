class_name TitleScreen
extends Control

var _app: ClientApp
var _name: LineEdit
var _server: LineEdit
var _code: LineEdit
var _status: Label
var _content: Control
var _view := "menu"
var _story_picks: Array[OptionButton] = []
var _story_preview_portrait: TextureRect
var _story_preview_name: Label
var _story_preview_class: Label
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
		_app.start_dev_playtest(str(app.options.get("seed", "")), str(app.options.get("jump", "journey")),
				str(app.options.get("class", "")))

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
	var subtitle := UiKit.label("Forest to Cave - a co-op journey", "heading")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	subtitle.position.y = 70
	logo.add_child(subtitle)
	add_child(logo)
	var build := UiKit.label("BUILD 0.10  |  FOREST TO CAVE", "small", UiKit.TEXT_DIM)
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
	body.add_child(UiKit.label("WELCOME, TRAVELLER", "heading", UiKit.ACCENT))
	body.add_child(UiKit.para("Choose your path into the forest.", "dim"))
	var play := UiKit.primary("Play", _show_play, true)
	Icons.apply_to_button(play, "play", _app.settings.text_scale)
	play.set_meta("focus_id", "play")
	body.add_child(play)
	var settings := UiKit.button("Settings [F2]", _app.open_settings, true)
	Icons.apply_to_button(settings, "settings", _app.settings.text_scale)
	settings.set_meta("focus_id", "settings")
	body.add_child(settings)
	var credits := UiKit.button("Credits", _show_credits, true)
	Icons.apply_to_button(credits, "credits", _app.settings.text_scale)
	credits.set_meta("focus_id", "credits")
	body.add_child(credits)
	if not OS.has_feature("web"):
		var quit := UiKit.button("Quit", func() -> void: _app.stop_dev_playtest(); get_tree().quit(), true)
		Icons.apply_to_button(quit, "quit", _app.settings.text_scale)
		body.add_child(quit)
	_content = _attach_narrow_panel(body, 390, 150.0)
	UiKit.focus_first(body)

func _show_play() -> void:
	_view = "play"
	_clear_content()
	var body := UiKit.vbox(12)
	body.custom_minimum_size = Vector2(420, 0)
	body.add_child(UiKit.label("CHOOSE YOUR JOURNEY", "heading", UiKit.ACCENT))
	body.add_child(UiKit.label("Story · offline, control all five", "body"))
	body.add_child(UiKit.para("Story uses an isolated profile: Human only, with no online Races, Boons, or class-tree bonuses.", "dim"))
	_status = UiKit.para("", "body", UiKit.WARN)
	_status.visible = false
	body.add_child(_status)
	var has_save: bool = _app.story_save.has_save()
	if has_save:
		var resume := UiKit.primary("Continue Story", func() -> void: _app.start_story([], _app.story_save.load()))
		Icons.apply_to_button(resume, "story_mode", _app.settings.text_scale)
		resume.set_meta("focus_id", "continue_story")
		body.add_child(resume)
	var story := UiKit.button("New Story", _show_story_setup, true, "secondary" if has_save else "primary")
	Icons.apply_to_button(story, "story_mode", _app.settings.text_scale)
	story.set_meta("focus_id", "new_story")
	body.add_child(story)
	body.add_child(HSeparator.new())
	body.add_child(UiKit.label("Multiplayer · create or join a room", "body"))
	var multiplayer_button := UiKit.button("Multiplayer", _show_multiplayer, true)
	Icons.apply_to_button(multiplayer_button, "multiplayer", _app.settings.text_scale)
	multiplayer_button.set_meta("focus_id", "multiplayer")
	body.add_child(multiplayer_button)
	var back := UiKit.button("Back [Esc]", _show_menu)
	Icons.apply_to_button(back, "back", _app.settings.text_scale)
	body.add_child(back)
	_content = _attach_narrow_panel(body, 460, 175.0)
	UiKit.focus_first(body)

func _show_story_setup() -> void:
	_view = "story_setup"
	_clear_content()
	_story_picks.clear()
	_story_preview_portrait = null
	_story_preview_name = null
	_story_preview_class = null
	var body := UiKit.vbox(8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.name = "StorySetupScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	scroll.add_child(body)
	var panel := UiKit.panel(scroll)
	# Responsive: stretch across the viewport (capped) so the roster and the
	# framed preview sit side-by-side at 1280x720 and wrap at narrow widths.
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.anchor_bottom = 1.0
	var margin := 88.0
	var vw := get_viewport_rect().size.x
	if vw > 0.0:
		margin = maxf(24.0, minf(88.0, (vw - 1020.0) / 2.0))
	panel.offset_left = margin
	panel.offset_right = -margin
	panel.offset_top = _top(175)
	panel.offset_bottom = -24
	panel.set_meta("base_y", 175.0)
	add_child(panel)
	_content = panel
	body.add_child(UiKit.label("STORY PARTY", "heading", UiKit.ACCENT))
	body.add_child(UiKit.para("Choose a Class for every traveller.", "dim"))
	var columns := UiKit.flow(12)
	columns.set_meta("story_columns", true)
	body.add_child(columns)
	var roster := UiKit.vbox(8)
	roster.custom_minimum_size = Vector2(420, 0)
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(roster)
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
		pick.set_meta("story_index", i)
		_story_picks.append(pick)
		row.add_child(pick)
		roster.add_child(row)
		var row_index := i
		pick.item_selected.connect(_on_story_pick_changed.bind(row_index))
		pick.focus_entered.connect(_on_story_pick_focused.bind(row_index))
		pick.mouse_entered.connect(_on_story_pick_focused.bind(row_index))
	var preview_body := UiKit.vbox(8)
	preview_body.custom_minimum_size = Vector2(260, 0)
	preview_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var preview_panel := UiKit.panel(preview_body, "HighlightPanel")
	preview_panel.name = "StoryPreview"
	preview_panel.custom_minimum_size = Vector2(280, 0)
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(preview_panel)
	_story_preview_name = UiKit.pixel_label(STORY_NAMES[0], "heading", UiKit.ACCENT)
	_story_preview_name.name = "StoryPreviewName"
	_story_preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_body.add_child(_story_preview_name)
	_story_preview_portrait = TextureRect.new()
	_story_preview_portrait.name = "StoryPreviewPortrait"
	_story_preview_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_story_preview_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_story_preview_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_story_preview_portrait.custom_minimum_size = Vector2(220, 220)
	_story_preview_portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_story_preview_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_body.add_child(_story_preview_portrait)
	_story_preview_class = UiKit.pixel_label("", "body")
	_story_preview_class.name = "StoryPreviewClass"
	_story_preview_class.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_body.add_child(_story_preview_class)
	var begin := UiKit.primary("Begin Story", _begin_story)
	Icons.apply_to_button(begin, "story_mode", _app.settings.text_scale)
	body.add_child(begin)
	var back := UiKit.button("Back [Esc]", _show_play)
	Icons.apply_to_button(back, "back", _app.settings.text_scale)
	body.add_child(back)
	_update_story_preview(0)
	UiKit.focus_first(body)

static func _story_portrait_path(class_id: String) -> String:
	return "res://assets/heroes/%s/portrait.png" % class_id

func _on_story_pick_changed(_selected: int, row: int) -> void:
	_update_story_preview(row)

func _on_story_pick_focused(row: int) -> void:
	_update_story_preview(row)

func _update_story_preview(row: int) -> void:
	if _story_picks.is_empty():
		return
	var index := clampi(row, 0, _story_picks.size() - 1)
	var pick := _story_picks[index]
	if not is_instance_valid(pick):
		return
	var class_id: String = STORY_CLASSES[clampi(pick.selected, 0, STORY_CLASSES.size() - 1)]
	if is_instance_valid(_story_preview_name):
		_story_preview_name.text = STORY_NAMES[index]
	if is_instance_valid(_story_preview_class):
		_story_preview_class.text = class_id.capitalize()
	if is_instance_valid(_story_preview_portrait):
		var path := _story_portrait_path(class_id)
		if ResourceLoader.exists(path):
			_story_preview_portrait.texture = load(path)
		else:
			_story_preview_portrait.texture = null

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
	body.add_child(UiKit.label("ENTER THE FOREST", "heading", UiKit.ACCENT))
	body.add_child(UiKit.label("Your name (shown to other players)", "dim"))
	_name = _line_edit(_app.settings.player_name, "e.g. Arin", 16)
	body.add_child(_name)
	var create := UiKit.primary("Create a room", _create)
	Icons.apply_to_button(create, "multiplayer", _app.settings.text_scale)
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
	Icons.apply_to_button(join, "multiplayer", _app.settings.text_scale)
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
	Icons.apply_to_button(back, "back", _app.settings.text_scale)
	back.set_meta("focus_id", "back")
	body.add_child(back)
	_content = _attach_narrow_panel(body, 560, 150.0)
	create.grab_focus.call_deferred()
	if _app.options.has("auto") and not _name.text.is_empty():
		(_join if not _code.text.is_empty() else _create).call_deferred()

func _show_credits() -> void:
	_view = "credits"
	_clear_content()
	var body := UiKit.vbox(14)
	body.custom_minimum_size = Vector2(420, 0)
	body.add_child(UiKit.label("BEYOND THE WORLD'S END", "title", UiKit.ACCENT))
	body.add_child(UiKit.label("Made with Godot 4.7", "heading"))
	body.add_child(UiKit.para("Font: Pixelify Sans, OFL\nCharacter art by the project owner.", "body"))
	body.add_child(UiKit.para("Audio: Kenney, Zane Little Music, MintoDog, JaggedStone, artisticdude and Brian MacIntosh (CC0); YannZ and leohpaz (CC-BY 4.0). Full credits: assets/audio/CREDITS.md", "dim"))
	var back := UiKit.primary("Back [Esc]", _show_menu, false)
	Icons.apply_to_button(back, "back", _app.settings.text_scale)
	body.add_child(back)
	_content = _attach_narrow_panel(body, 470, 150.0)
	UiKit.focus_first(body)

## Panels start lower with bigger text so they clear the logo's subtitle.
func _top(y: float) -> float:
	return y + 50.0 * maxf(0.0, _app.settings.text_scale - 1.0)


## Centre narrow title panels while preserving a clear strip for the camp scene.
## Oversized content scrolls inside its panel, and follow_focus keeps keyboard
## navigation visible when the text scale is increased.
func _attach_narrow_panel(body: Control, width: float, base_y: float) -> PanelContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	scroll.add_child(body)
	var panel := UiKit.panel(scroll)
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -width * 0.5
	panel.offset_right = width * 0.5
	panel.set_meta("base_y", base_y)
	panel.set_meta("panel_width", width - 32.0)
	panel.set_meta("narrow_title_panel", true)
	add_child(panel)
	_layout_narrow_panel(panel)
	# Fonts and icons settle after the first frame; measure again so the panel hugs its buttons.
	_layout_narrow_panel.call_deferred(panel)
	return panel


func _layout_narrow_panel(panel: PanelContainer) -> void:
	if not is_instance_valid(panel) or panel.get_child_count() == 0:
		return
	var scroll := panel.get_child(0) as ScrollContainer
	var body := scroll.get_child(0) as Control
	var top := _top(float(panel.get_meta("base_y", 150.0)))
	var viewport_height := get_viewport_rect().size.y if is_inside_tree() else size.y
	# The menu needs room for all four actions at large text sizes. It can cover
	# the campfire scene, but must stay below the title and subtitle.
	var max_panel_height := viewport_height - top - 24.0 if _view == "menu" else maxf(180.0, viewport_height * 0.64 - top)
	var scroll_height := minf(body.get_combined_minimum_size().y, max_panel_height - 32.0)
	scroll.custom_minimum_size = Vector2(float(panel.get_meta("panel_width", 0.0)), scroll_height)
	panel.offset_top = top
	panel.offset_bottom = top + scroll_height + 32.0

func _notification(what: int) -> void:
	# The text size can change while the title is open (Settings).
	if what == NOTIFICATION_THEME_CHANGED and _app != null and is_instance_valid(_content):
		if _content.has_meta("narrow_title_panel"):
			_layout_narrow_panel(_content as PanelContainer)
			# Children resize after their parent hears about the new theme, so measure again.
			_layout_narrow_panel.call_deferred(_content as PanelContainer)
		elif _view == "story_setup":
			var top := _top(float(_content.get_meta("base_y", 150.0)))
			# Story setup panel is anchored TOP_WIDE with a finite height
			# (offset_bottom stays at -24); only move the top so text-scale
			# changes keep it anchored without collapsing it.
			_content.offset_top = top
		else:
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
			"play", "credits", "playtest":
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
