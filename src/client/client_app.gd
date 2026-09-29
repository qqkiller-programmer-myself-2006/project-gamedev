class_name ClientApp
extends Control
## The game client (PC and browser builds share it). It only sends commands
## and shows what the authoritative server says: every screen is rendered
## from the latest snapshot, and events drive feedback (log lines, floating
## numbers, sounds and banners).
##
## Command-line / URL options: --url=ws://host:port --name=Ann --join=CODE
## (--auto joins right away, or creates a room when no code is given).

signal snapshot_changed

const DEFAULT_URL := "ws://127.0.0.1:8910"
const TOKEN_PATH := "user://player_token.txt"
const CONNECT_TIMEOUT_SECONDS := 8.0

var settings: ClientSettings
var connection: ServerConnection
var snapshot: Dictionary = {}
var sounds: SoundBank
var options: Dictionary = {}
var player_token := ""

var _snapshot_server_time := 0.0
var _snapshot_local_time := 0.0
var _pending_action: Callable = Callable()
var _connect_deadline := -1.0
var _screen_holder: Control
var _current: Control = null
var _current_name := ""
var _toast: PanelContainer
var _toast_label: Label
var _toast_until := 0.0
var _overlay_holder: Control
var _banner: PanelContainer
var _banner_label: Label
var _banner_until := 0.0
var _embedded_server: GameServer = null
var _dev_playtest := false
var _dev_jump: Dictionary = {}
var _dev_tag: PanelContainer = null
var story_launcher: StoryLauncher = null
var story_save := StorySave.new()
var _story_classes: Array = []
var _story_restore: Dictionary = {}


func configure(launch_options: Dictionary) -> void:
	options = launch_options


func _ready() -> void:
	settings = ClientSettings.load_saved()
	player_token = _load_player_token()
	if options.has("name"):
		settings.player_name = str(options["name"])
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = UiKit.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_screen_holder = Control.new()
	_screen_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_screen_holder)
	_build_banner()
	_build_toast()
	_overlay_holder = Control.new()
	_overlay_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_holder)
	_build_dev_tag()
	sounds = SoundBank.new()
	add_child(sounds)
	apply_settings()
	_show_screen("title")


func _process(_delta: float) -> void:
	poll_connection()
	if _current != null and _current.has_method("tick"):
		_current.tick(self)
	var now := _local_now()
	_toast.visible = now < _toast_until
	_banner.visible = now < _banner_until


# --- Server clock ------------------------------------------------------------

## The server clock right now, estimated from the last snapshot.
func server_now() -> float:
	return _snapshot_server_time + (_local_now() - _snapshot_local_time)


func seconds_left(deadline: Variant) -> float:
	if deadline == null:
		return 0.0
	return maxf(0.0, float(deadline) - server_now())


# --- Connection ---------------------------------------------------------------

func server_url() -> String:
	if options.has("url"):
		return str(options["url"])
	if not settings.server_url.is_empty():
		return settings.server_url
	if OS.has_feature("web"):
		# Staging serves the page and the server behind one reverse proxy,
		# with the server on /ws of the same host (see deploy/Caddyfile).
		var https = JavaScriptBridge.eval("window.location.protocol === 'https:'", true)
		var host = JavaScriptBridge.eval("window.location.host", true)
		if typeof(host) == TYPE_STRING and not str(host).is_empty():
			return "%s://%s/ws" % ["wss" if https else "ws", host]
	return DEFAULT_URL


## Runs `action` once connected, connecting to `url` first if needed.
## `transport` is injectable so the lifecycle can be tested without a socket.
func connect_and(url: String, action: Callable, transport: ServerConnection = null) -> void:
	if connection != null and connection.is_open():
		action.call()
		return
	var client: ServerConnection = transport if transport != null else NetClient.new()
	_use_connection(client)
	_pending_action = action
	_connect_deadline = _local_now() + float(options.get("connect_timeout_seconds", CONNECT_TIMEOUT_SECONDS))
	if client.connect_to(url) != OK:
		_on_closed("cannot_connect")
	else:
		toast(UiText.LABELS["connecting"] % url, 3.0)


## Polls the active transport and fails a connection attempt that never opens.
func poll_connection() -> void:
	if connection == null:
		return
	connection.poll()
	if connection != null and _connect_deadline >= 0.0 and not connection.is_open() and _local_now() >= _connect_deadline:
		var timed_out := connection
		connection = null
		timed_out.close("connect_timeout")
		_on_closed("connect_timeout")


## Plugs in an already-built connection (LocalConnection for tools).
func use_connection(new_connection: ServerConnection) -> void:
	_use_connection(new_connection)


func send(cmd: Dictionary) -> void:
	if connection == null or not connection.is_open():
		toast(UiText.error("connection_lost"))
		return
	var outgoing := cmd
	if str(cmd.get("type", "")) in ["create_room", "join_room"]:
		outgoing = cmd.duplicate()
		outgoing["token"] = player_token
	connection.send_command(outgoing)
	sounds.play("click")


func _load_player_token() -> String:
	if FileAccess.file_exists(TOKEN_PATH):
		var saved := FileAccess.get_file_as_string(TOKEN_PATH).strip_edges().to_lower()
		if saved.length() == 32 and saved.is_valid_hex_number():
			return saved
	var created := Crypto.new().generate_random_bytes(16).hex_encode()
	var file := FileAccess.open(TOKEN_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(created)
	return created


func disconnect_from_server() -> void:
	_pending_action = Callable()
	_connect_deadline = -1.0
	if connection != null:
		var old := connection
		connection = null
		old.close("left")
	snapshot = {}
	_stop_owned_servers()
	_show_screen("title")


func can_playtest() -> bool:
	return not OS.has_feature("web") and (OS.is_debug_build() or options.has("dev"))


## Starts a single-player Playtest on an embedded server. `target` is a DevJump
## target ("journey" = normal start); `class_id` optionally sets the player's Class.
func start_dev_playtest(seed_text: String = "", target: String = "journey", class_id: String = "") -> void:
	if not can_playtest():
		return
	if connection != null or _embedded_server != null:
		disconnect_from_server()
	_dev_jump = {}
	if target != "journey" or not class_id.is_empty():
		_dev_jump = {"type": "dev_jump", "target": target, "class": class_id}
	var server_options := {}
	if not seed_text.strip_edges().is_empty() and seed_text.is_valid_int():
		server_options["seed"] = int(seed_text)
	var server := GameServer.new()
	server.name = "EmbeddedGameServer"
	server.configure(server_options)
	var port := -1
	for candidate in range(8911, 8931):
		if server.listen_embedded(candidate):
			port = candidate
			break
	if port < 0:
		server.free()
		toast("DEV PLAYTEST: ports 8911-8930 are all busy. Close other game windows and try again.")
		return
	_embedded_server = server
	_dev_playtest = true
	_dev_tag.visible = true
	add_child(server)
	connect_and("ws://127.0.0.1:%d" % port, func() -> void:
		send({"type": "create_room", "name": "Tester"}))


func stop_dev_playtest() -> void:
	_dev_playtest = false
	_dev_jump = {}
	if _dev_tag != null:
		_dev_tag.visible = false
	if _embedded_server != null:
		# Release the port now, not at the end of the frame, so a new Playtest can reuse it at once.
		_embedded_server.transport.stop()
		_embedded_server.queue_free()
		_embedded_server = null


## True while the Story Match being opened comes from a save (Continue).
func is_story_restore() -> bool:
	return story_launcher != null and not _story_restore.is_empty()


func start_story(classes: Array = [], restore: Dictionary = {}, seed_value: int = 0) -> void:
	_pending_action = Callable()
	_connect_deadline = -1.0
	if connection != null:
		disconnect_from_server()
	_story_classes = classes.duplicate()
	_story_restore = restore.duplicate(true)
	story_launcher = StoryLauncher.new()
	story_launcher.start(self, seed_value if seed_value != 0 else int(restore.get("seed", 0)))
	send({"type": "create_room", "name": settings.player_name if not settings.player_name.is_empty() else "Traveller", "story": true})


func _use_connection(new_connection: ServerConnection) -> void:
	_pending_action = Callable()
	_connect_deadline = -1.0
	if connection != null:
		var old := connection
		connection = null
		old.close("replaced")
	connection = new_connection
	connection.opened.connect(_on_opened)
	connection.closed.connect(_on_closed.bind(connection))
	connection.update_received.connect(_on_update)
	connection.result_received.connect(_on_result)
	connection.server_error.connect(func(code: String) -> void: toast(UiText.error(code)))


func _on_opened(_session: int) -> void:
	_connect_deadline = -1.0
	if _pending_action.is_valid():
		var action := _pending_action
		_pending_action = Callable()
		action.call()


func _on_closed(reason: String, which: ServerConnection = null) -> void:
	if which != null and which != connection:
		return
	connection = null
	_connect_deadline = -1.0
	_pending_action = Callable()
	_stop_owned_servers()
	snapshot = {}
	_show_screen("title")
	_show_connection_error(reason)


func _show_connection_error(reason: String) -> void:
	if _current is TitleScreen:
		_current._show_multiplayer()
		_current.show_error(UiText.error(reason))
	else:
		toast(UiText.error(reason))


func _on_update(events: Array, snap: Dictionary) -> void:
	_pending_action = Callable()
	_connect_deadline = -1.0
	if snap.has("time"):
		_snapshot_server_time = float(snap["time"])
		_snapshot_local_time = _local_now()
	snapshot = snap
	if story_launcher != null:
		for event in events:
			if event.get("type", "") == "story_layer_started":
				story_save.save(story_launcher.server.export_story(int(snap.get("session", 0))))
			elif event.get("type", "") == "match_ended":
				story_save.clear()
	_publish_for_web(snap)
	var wanted := _screen_for(snap)
	if wanted != _current_name:
		_show_screen(wanted)
	if _current != null and _current.has_method("refresh"):
		_current.refresh(self)
	if _current != null and _current.has_method("show_events") and not events.is_empty():
		_current.show_events(self, events)
	snapshot_changed.emit()


func _on_result(_id: int, _cmd: Dictionary, result: Dictionary) -> void:
	_pending_action = Callable()
	if not result.get("ok", false):
		if story_launcher != null and str(_cmd.get("type", "")) in ["create_room", "restore_story"]:
			var msg := UiText.error(str(result.get("error", "")))
			story_save.clear()
			story_launcher.stop()
			story_launcher = null
			if _current is TitleScreen:
				if _current.has_method("_show_play"):
					_current._show_play()
				_current.show_error(msg)
			else:
				toast(msg)
			return
		
		var message := UiText.error(str(result.get("error", "")))
		if _current is TitleScreen:
			_current.show_error(message)
		else:
			toast(message)
	elif story_launcher != null and str(_cmd.get("type", "")) == "create_room" and _cmd.get("story", false):
		if not _story_restore.is_empty():
			send({"type": "restore_story", "save": _story_restore})
		else:
			for i in _story_classes.size():
				send({"type": "set_loadout", "slot": i, "class": str(_story_classes[i]), "race": "Human", "boons": []})
			send({"type": "start_match"})
	elif _dev_playtest and str(_cmd.get("type", "")) == "create_room":
		send({"type": "start_match"})
	elif _dev_playtest and str(_cmd.get("type", "")) == "start_match" and not _dev_jump.is_empty():
		var jump := _dev_jump
		_dev_jump = {}
		send(jump)


# --- Screens ------------------------------------------------------------------

func _screen_for(snap: Dictionary) -> String:
	var room = snap.get("room")
	if room == null:
		return "title"
	if room["state"] == "lobby" and snap.get("match") == null:
		return "lobby"
	return "match"


func _show_screen(screen: String) -> void:
	if screen == "title" and not _current_name.is_empty() and _current_name != "title":
		_stop_owned_servers(true)
	if _current != null:
		_screen_holder.remove_child(_current)
		_current.queue_free()
	match screen:
		"title":
			_current = TitleScreen.new()
		"lobby":
			_current = LobbyScreen.new()
		_:
			_current = MatchScreen.new()
	_current_name = screen
	_current.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_holder.add_child(_current)
	fade_in(_current, 0.25)
	if _current.has_method("setup"):
		_current.setup(self)
	if not snapshot.is_empty() and _current.has_method("refresh"):
		_current.refresh(self)


# --- Feedback -----------------------------------------------------------------

func toast(message: String, seconds: float = 4.0) -> void:
	_toast_label.text = message
	_toast_until = _local_now() + seconds
	_toast.visible = true


## A big announcement across the screen (the visual twin of sound cues).
func banner(message: String, seconds: float = 2.5, cue: String = "") -> void:
	_banner_label.text = message
	_banner_until = _local_now() + seconds
	_banner.visible = true
	if not cue.is_empty():
		sounds.play(cue)
	if not settings.reduced_motion:
		_banner.modulate.a = 0.0
		create_tween().tween_property(_banner, "modulate:a", 1.0, 0.2)
	else:
		_banner.modulate.a = 1.0


## Hides the banner now (e.g. when a screen with its own banner takes over).
func clear_banner() -> void:
	_banner_until = 0.0
	_banner.visible = false


## Fades a control in (skipped with Reduced motion).
func fade_in(node: CanvasItem, seconds: float = 0.2, slide: Vector2 = Vector2.ZERO) -> void:
	if settings.reduced_motion:
		return
	node.modulate.a = 0.0
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "modulate:a", 1.0, seconds)
	if slide != Vector2.ZERO and node is Control:
		var control := node as Control
		var target := control.position
		control.position = target + slide
		tween.tween_property(control, "position", target, seconds)


## A short flash on a card that was hit or healed (skipped with Reduced motion).
func flash(node: CanvasItem, color: Color) -> void:
	if settings.reduced_motion or not is_instance_valid(node):
		return
	var tween := create_tween()
	tween.tween_property(node, "modulate", color, 0.08)
	tween.tween_property(node, "modulate", Color.WHITE, 0.25)


## Shows a one-time tutorial hint unless the player has seen it already.
func hint(key: String) -> void:
	if settings.seen_hints.has(key) or not UiText.HINTS.has(key):
		return
	# Keep the first unread hint visible. Later hints can be offered again after
	# the player explicitly closes this one and a fresh snapshot is rendered.
	if _has_open_hint():
		return
	var box := UiKit.vbox(4)
	var head := UiKit.hbox(8)
	head.add_child(UiKit.label("Tip", "body", UiKit.ACCENT))
	head.add_child(UiKit.spacer())
	box.add_child(head)
	var width := 430.0
	if _current != null and _current.has_method("tip_width"):
		width = _current.tip_width()
	var text := UiKit.para(UiText.HINTS[key], "small", UiKit.TEXT, width)
	box.add_child(text)
	var panel := UiKit.panel(box, "HighlightPanel")
	panel.set_meta("hint", true)
	panel.set_meta("hint_key", key)
	var close := UiKit.button(UiText.LABELS["got_it"], func() -> void: _dismiss_hint(panel), false, "small")
	head.add_child(close)
	if _current != null and _current.has_method("tip_slot"):
		_current.tip_slot().add_child(panel)
		return
	_overlay_holder.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)


func close_hints(mark_seen: bool = true) -> bool:
	var closed := false
	for holder in _hint_holders():
		for child in holder.get_children():
			if child.has_meta("hint"):
				if mark_seen:
					_dismiss_hint(child)
				else:
					child.queue_free()
				closed = true
	return closed


func _dismiss_hint(panel: Control) -> void:
	var key := str(panel.get_meta("hint_key", ""))
	if not key.is_empty() and not settings.seen_hints.has(key):
		settings.seen_hints.append(key)
		settings.save()
	panel.queue_free()


func _has_open_hint() -> bool:
	for holder in _hint_holders():
		for child in holder.get_children():
			if child.has_meta("hint") and not child.is_queued_for_deletion():
				return true
	return false


func _hint_holders() -> Array:
	var holders: Array = []
	if is_instance_valid(_overlay_holder):
		holders.append(_overlay_holder)
	if _current != null and _current.has_method("tip_slot"):
		var slot = _current.tip_slot()
		if is_instance_valid(slot):
			holders.append(slot)
	return holders


func open_settings() -> void:
	for child in _overlay_holder.get_children():
		if child is SettingsPanel:
			return
	var panel := SettingsPanel.new()
	_overlay_holder.add_child(panel)
	panel.setup(self)


## Asks before a destructive action (`key` in UiText.CONFIRM; `args` fill
## the text's %s / %d).
func confirm(key: String, on_confirm: Callable, args: Array = []) -> void:
	for child in _overlay_holder.get_children():
		if child is ConfirmDialog:
			return
	var texts: Array = UiText.CONFIRM[key]
	var dialog := ConfirmDialog.new()
	_overlay_holder.add_child(dialog)
	dialog.setup(str(texts[0]), str(texts[1]) % args if not args.is_empty() else str(texts[1]), str(texts[2]), on_confirm)


## Leaves the room or Match after asking.
func confirm_leave() -> void:
	var in_match := _current_name == "match"
	confirm("leave_match" if in_match else "leave_room", func() -> void:
		send({"type": "leave_room"})
		disconnect_from_server())


func apply_settings() -> void:
	theme = UiKit.make_theme(settings.text_scale)
	SoundBank.set_volume(settings.volume)
	if _current != null and _current.has_method("refresh") and not snapshot.is_empty():
		_current.refresh(self, true)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if _has_open_hint():
		if event.keycode == KEY_H:
			close_hints()
		get_viewport().set_input_as_handled()
		return
	for overlay in _overlay_holder.get_children():
		if overlay.is_queued_for_deletion():
			continue
		if overlay is SettingsPanel:
			if event.keycode == KEY_ESCAPE:
				overlay.queue_free()
			get_viewport().set_input_as_handled()
			return
		if overlay is ConfirmDialog:
			if event.keycode == KEY_ESCAPE:
				overlay.close()
			get_viewport().set_input_as_handled()
			return
	if _banner.visible:
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_F2 or (event.keycode == KEY_COMMA and event.ctrl_pressed):
		open_settings()
		get_viewport().set_input_as_handled()
		return
	if _current != null and _current.has_method("handle_key") and _current.handle_key(self, event.keycode):
		get_viewport().set_input_as_handled()


## Stops only servers owned by this client. When returning to title from an
## embedded mode, also close its client connection so no local work survives.
func _stop_owned_servers(close_owned_connection: bool = false) -> void:
	var owned_connection: ServerConnection = null
	if story_launcher != null:
		owned_connection = story_launcher.connection
		var launcher := story_launcher
		story_launcher = null
		if close_owned_connection and connection == owned_connection:
			connection = null
		launcher.stop()
	if _dev_playtest and close_owned_connection and connection != null:
		var old := connection
		connection = null
		old.close("returned_to_title")
	stop_dev_playtest()


func _exit_tree() -> void:
	_pending_action = Callable()
	_connect_deadline = -1.0
	if connection != null:
		var old := connection
		connection = null
		old.close("client_closed")
	_stop_owned_servers()


func _build_toast() -> void:
	# Toasts always appear at the top centre, on every screen.
	_toast_label = UiKit.label("")
	_toast = UiKit.panel(_toast_label, "ToastPanel")
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_END
	_toast.offset_top = 12
	_toast.offset_bottom = 12
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	add_child(_toast)


func _build_banner() -> void:
	_banner_label = UiKit.label("", "title", UiKit.ACCENT)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Banners sit below the Match top bar so they never hide its buttons.
	_banner = UiKit.panel(_banner_label, "HighlightPanel")
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_END
	_banner.offset_top = 90
	_banner.offset_bottom = 90
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	add_child(_banner)


func _build_dev_tag() -> void:
	var label := UiKit.pixel_label("DEV PLAYTEST", "small", UiKit.WARN)
	_dev_tag = UiKit.panel(label, "HighlightPanel")
	_dev_tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_dev_tag.position = Vector2(-24, 20)
	_dev_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dev_tag.visible = false
	add_child(_dev_tag)


## Browser builds expose a small summary of the client state as
## window.__forest so automated cross-platform smoke tests can follow along.
func _publish_for_web(snap: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	var room = snap.get("room")
	var run = snap.get("match")
	var controllers := []
	if room != null:
		for slot in room.get("slots", []):
			controllers.append(slot["controller"])
	var state := {
		"session": snap.get("session", 0),
		"code": room.get("code", "") if room != null else "",
		"room_state": room.get("state", "") if room != null else "",
		"your_slot": room.get("your_slot", -1) if room != null else -1,
		"controllers": controllers,
		"phase": run.get("phase", "") if run != null else "",
	}
	JavaScriptBridge.eval("window.__forest = %s;" % JSON.stringify(state), true)


static func _local_now() -> float:
	return Time.get_ticks_msec() / 1000.0
