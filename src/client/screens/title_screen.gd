class_name TitleScreen
extends Control
## First screen: display name, server address, create a room or join one by
## Room code. No account needed.

var _name: LineEdit
var _server: LineEdit
var _code: LineEdit
var _status: Label
var _app: ClientApp


func setup(app: ClientApp) -> void:
	_app = app
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := UiKit.vbox(14)
	column.custom_minimum_size = Vector2(560, 0)
	center.add_child(column)

	var title := UiKit.label("BEYOND THE WORLD'S END", "huge", UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle := UiKit.label("Forest - a co-op journey for 1 to 5 players", "heading")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)

	var form := UiKit.vbox(10)
	column.add_child(UiKit.panel(form))
	form.add_child(UiKit.label("Your name (shown to other players)", "dim"))
	_name = _line_edit(app.settings.player_name, "e.g. Arin", 16)
	form.add_child(_name)
	form.add_child(UiKit.label("Server address", "dim"))
	_server = _line_edit(app.server_url(), ClientApp.DEFAULT_URL, 200)
	form.add_child(_server)
	var create := UiKit.button("Create a room", _create, true)
	create.set_meta("focus_id", "create")
	form.add_child(create)
	form.add_child(HSeparator.new())
	form.add_child(UiKit.para("Have a Room code? Letters and numbers, case does not matter.", "dim"))
	var join_row := UiKit.hbox(8)
	_code = _line_edit("", "Room code", 12)
	_code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_code.text_submitted.connect(func(_t: String) -> void: _join())
	join_row.add_child(_code)
	join_row.add_child(UiKit.button("Join room", _join, true))
	form.add_child(join_row)
	_status = UiKit.para("", "body", UiKit.WARN)
	_status.visible = false
	form.add_child(_status)

	var footer := UiKit.hbox(8)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(UiKit.button("Settings [F2]", app.open_settings))
	column.add_child(footer)
	(_name if _name.text.is_empty() else create).grab_focus.call_deferred()


func show_error(message: String) -> void:
	_status.text = message
	_status.visible = true


func _create() -> void:
	if not _remember():
		return
	var display_name := _name.text.strip_edges()
	_app.connect_and(_server.text.strip_edges(), func() -> void:
		_app.send({"type": "create_room", "name": display_name}))


func _join() -> void:
	if not _remember():
		return
	if _code.text.strip_edges().is_empty():
		show_error(UiText.error("invalid_code"))
		_code.grab_focus()
		return
	var display_name := _name.text.strip_edges()
	var code := _code.text.strip_edges()
	_app.connect_and(_server.text.strip_edges(), func() -> void:
		_app.send({"type": "join_room", "code": code, "name": display_name}))


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


static func _line_edit(text: String, placeholder: String, max_length: int) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = text
	edit.placeholder_text = placeholder
	edit.max_length = max_length
	edit.custom_minimum_size = Vector2(0, 42)
	return edit
