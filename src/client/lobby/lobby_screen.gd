class_name LobbyScreen
extends Control
## The room before a Match: Room code to share, the five Player slots with
## owner and human/AI control, and the Host's Start button.

var _app: ClientApp
var _body: VBoxContainer
var _digest := ""
var _setup: CharacterSetup


func setup(app: ClientApp) -> void:
	_app = app
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var center := CenterContainer.new()
	margin.add_child(center)
	_body = UiKit.vbox(14)
	_body.custom_minimum_size = Vector2(760, 0)
	center.add_child(_body)


func show_events(app: ClientApp, events: Array) -> void:
	for event in events:
		match str(event["type"]):
			"player_joined":
				app.toast(Tr.t("%s joined the room." % event["name"]))
				app.sounds.play("good")
			"player_left":
				app.toast(Tr.t("%s left. Their slot is AI controlled now." % event["name"]))
			"host_changed":
				app.toast(Tr.t("%s is now the Host." % event["name"]))
			"profile_unavailable":
				app.toast(UiText.error("profile_unavailable"), 6.0)


func refresh(app: ClientApp, force: bool = false) -> void:
	var room: Dictionary = app.snapshot.get("room", {})
	if is_instance_valid(_setup):
		_setup.refresh(app)
	var digest := JSON.stringify(room)
	if digest == _digest and not force:
		return
	var focus_id := _focused_id()
	_digest = digest
	UiKit.clear(_body)
	var you: int = room.get("your_slot", -1)
	var is_host: bool = you == room.get("host_slot", -2)

	var heading := UiKit.flow(12)
	heading.add_child(UiKit.label("Room code", "heading"))
	var code := UiKit.label(str(room.get("code", "")), "huge", UiKit.ACCENT)
	heading.add_child(code)
	var copy := UiKit.button("Copy code", func() -> void:
		DisplayServer.clipboard_set(str(room.get("code", "")))
		app.toast(Tr.t("Room code copied.")))
	copy.set_meta("focus_id", "copy")
	heading.add_child(copy)
	_body.add_child(heading)
	_body.add_child(UiKit.para("Share the code with friends. Anyone on PC or in a browser can join until the Host starts.", "dim"))

	var list := UiKit.vbox(8)
	_body.add_child(UiKit.panel(list))
	list.add_child(UiKit.label("Party - always 5 characters. Empty slots are played by AI.", "heading"))
	for slot in room.get("slots", []):
		list.add_child(_slot_row(slot))

	var actions := UiKit.flow(12)
	var setup_button := UiKit.button("Character Setup", _open_setup, true, "secondary" if is_host else "primary")
	Icons.apply_to_button(setup_button, "settings", app.settings.text_scale)
	setup_button.set_meta("focus_id", "setup")
	actions.add_child(setup_button)
	if is_host:
		var start := UiKit.primary("Start the Match", func() -> void: app.send({"type": "start_match"}))
		Icons.apply_to_button(start, "play", app.settings.text_scale)
		start.set_meta("focus_id", "start")
		actions.add_child(start)
	else:
		var host_name := ""
		for slot in room.get("slots", []):
			if slot["is_host"]:
				host_name = slot["owner_name"]
		actions.add_child(UiKit.label("Waiting for %s (Host) to start the Match..." % host_name, "heading"))
	var leave := UiKit.button("Leave room [Esc]", app.confirm_leave, true, "danger")
	Icons.apply_to_button(leave, "back", app.settings.text_scale)
	leave.set_meta("focus_id", "leave")
	actions.add_child(leave)
	var settings := UiKit.button("Settings [F2]", app.open_settings, true)
	Icons.apply_to_button(settings, "settings", app.settings.text_scale)
	actions.add_child(settings)
	_body.add_child(actions)
	if not _restore_focus(focus_id) and not _restore_focus("start") and not _restore_focus("setup"):
		UiKit.focus_first(_body)


func _slot_row(slot: Dictionary) -> Control:
	var row := UiKit.hbox(10)
	row.add_child(UiKit.label("Slot %d" % (int(slot["index"]) + 1), "dim"))
	var character := UiKit.label(str(slot["character_name"]), "heading")
	character.custom_minimum_size = Vector2(110, 0)
	row.add_child(character)
	if slot["controller"] == "human":
		row.add_child(UiKit.badge("PLAYER", UiKit.ALLY))
		row.add_child(UiKit.label(str(slot["owner_name"])))
		var loadout: Dictionary = slot.get("loadout", {})
		if not loadout.is_empty():
			row.add_child(UiKit.label("%s / %s" % [str(loadout.get("class", "")).capitalize(), str(loadout.get("race", ""))], "small", UiKit.ACCENT))
	else:
		row.add_child(UiKit.badge("AI", UiKit.TEXT_DIM))
		row.add_child(UiKit.label("AI controlled", "dim"))
	row.add_child(UiKit.spacer())
	if slot["is_host"]:
		row.add_child(UiKit.badge("HOST", UiKit.ACCENT))
	if slot["is_you"]:
		row.add_child(UiKit.badge("YOU", UiKit.GOOD))
	var card := UiKit.panel(row, "HighlightPanel" if slot["is_you"] else "CardPanel")
	return card


func _open_setup() -> void:
	if is_instance_valid(_setup):
		return
	_body.visible = false
	_setup = CharacterSetup.new()
	_setup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_setup)
	_setup.setup(_app, func() -> void:
		_setup.queue_free()
		_setup = null
		_body.visible = true
		refresh(_app, true))


func handle_key(_app_ref: ClientApp, keycode: int) -> bool:
	if is_instance_valid(_setup):
		return _setup.handle_key(keycode)
	if keycode == KEY_ESCAPE:
		_app.confirm_leave()
		return true
	return false


func _focused_id() -> String:
	var focused := get_viewport().gui_get_focus_owner()
	return str(focused.get_meta("focus_id", "")) if focused != null else ""


func _restore_focus(focus_id: String) -> bool:
	if focus_id.is_empty():
		return false
	return _find_and_focus(_body, focus_id)


static func _find_and_focus(node: Node, focus_id: String) -> bool:
	for child in node.get_children():
		if child is Control and child.get_meta("focus_id", "") == focus_id and child.focus_mode != Control.FOCUS_NONE:
			child.grab_focus()
			return true
		if _find_and_focus(child, focus_id):
			return true
	return false
