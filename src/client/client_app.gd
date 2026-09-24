class_name ClientApp
extends Control
## The game client (PC and browser builds share it). It only sends commands
## and shows what the authoritative server says: every screen is rendered
## from the latest snapshot, and events drive feedback (log lines, floating
## numbers, sounds and banners).
##
## Command-line / URL options: --url=ws://host:port --name=Ann

signal snapshot_changed

const DEFAULT_URL := "ws://127.0.0.1:8910"

var settings: ClientSettings
var connection: ServerConnection
var snapshot: Dictionary = {}
var sounds: SoundBank
var options: Dictionary = {}

var _snapshot_server_time := 0.0
var _snapshot_local_time := 0.0
var _pending_action: Callable = Callable()
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


func configure(launch_options: Dictionary) -> void:
	options = launch_options


func _ready() -> void:
	settings = ClientSettings.load_saved()
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
	sounds = SoundBank.new()
	add_child(sounds)
	apply_settings()
	_show_screen("title")


func _process(_delta: float) -> void:
	if connection != null:
		connection.poll()
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
	return DEFAULT_URL


## Runs `action` once connected, connecting to `url` first if needed.
func connect_and(url: String, action: Callable) -> void:
	if connection != null and connection.is_open():
		action.call()
		return
	_pending_action = action
	var client := NetClient.new()
	_use_connection(client)
	if client.connect_to(url) != OK:
		_on_closed("cannot_connect")
	else:
		toast("Connecting to %s ..." % url, 3.0)


## Plugs in an already-built connection (LocalConnection for tools).
func use_connection(new_connection: ServerConnection) -> void:
	_use_connection(new_connection)


func send(cmd: Dictionary) -> void:
	if connection == null or not connection.is_open():
		toast(UiText.error("connection_lost"))
		return
	connection.send_command(cmd)
	sounds.play("click")


func disconnect_from_server() -> void:
	if connection != null:
		var old := connection
		connection = null
		old.close("left")
	snapshot = {}
	_show_screen("title")


func _use_connection(new_connection: ServerConnection) -> void:
	if connection != null:
		connection.close("replaced")
	connection = new_connection
	connection.opened.connect(_on_opened)
	connection.closed.connect(_on_closed.bind(connection))
	connection.update_received.connect(_on_update)
	connection.result_received.connect(_on_result)
	connection.server_error.connect(func(code: String) -> void: toast(UiText.error(code)))


func _on_opened(_session: int) -> void:
	if _pending_action.is_valid():
		var action := _pending_action
		_pending_action = Callable()
		action.call()


func _on_closed(reason: String, which: ServerConnection = null) -> void:
	if which != null and which != connection:
		return
	connection = null
	snapshot = {}
	_show_screen("title")
	if _current is TitleScreen:
		_current.show_error(UiText.error(reason))


func _on_update(events: Array, snap: Dictionary) -> void:
	if snap.has("time"):
		_snapshot_server_time = float(snap["time"])
		_snapshot_local_time = _local_now()
	snapshot = snap
	var wanted := _screen_for(snap)
	if wanted != _current_name:
		_show_screen(wanted)
	if _current != null and _current.has_method("refresh"):
		_current.refresh(self)
	if _current != null and _current.has_method("show_events") and not events.is_empty():
		_current.show_events(self, events)
	snapshot_changed.emit()


func _on_result(_id: int, _cmd: Dictionary, result: Dictionary) -> void:
	if not result.get("ok", false):
		var message := UiText.error(str(result.get("error", "")))
		if _current is TitleScreen:
			_current.show_error(message)
		else:
			toast(message)


# --- Screens ------------------------------------------------------------------

func _screen_for(snap: Dictionary) -> String:
	var room = snap.get("room")
	if room == null:
		return "title"
	if room["state"] == "lobby" and snap.get("match") == null:
		return "lobby"
	return "match"


func _show_screen(screen: String) -> void:
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


## Shows a one-time tutorial hint unless the player has seen it already.
func hint(key: String) -> void:
	if settings.seen_hints.has(key) or not UiText.HINTS.has(key):
		return
	close_hints()
	settings.seen_hints.append(key)
	settings.save()
	var box := UiKit.vbox(4)
	box.add_child(UiKit.label("Tip", "body", UiKit.ACCENT))
	var text := UiKit.para(UiText.HINTS[key], "small", Color(0, 0, 0, 0), 430)
	box.add_child(text)
	var panel := UiKit.panel(box, "HighlightPanel")
	panel.set_meta("hint", true)
	var close := UiKit.button("Got it [H]", func() -> void: panel.queue_free())
	box.add_child(close)
	if _current != null and _current.has_method("tip_slot"):
		_current.tip_slot().add_child(panel)
		return
	_overlay_holder.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)


func close_hints() -> bool:
	var closed := false
	var holders: Array = [_overlay_holder]
	if _current != null and _current.has_method("tip_slot"):
		holders.append(_current.tip_slot())
	for holder in holders:
		for child in holder.get_children():
			if child.has_meta("hint"):
				child.queue_free()
				closed = true
	return closed


func open_settings() -> void:
	for child in _overlay_holder.get_children():
		if child is SettingsPanel:
			return
	var panel := SettingsPanel.new()
	_overlay_holder.add_child(panel)
	panel.setup(self)


func apply_settings() -> void:
	theme = UiKit.make_theme(settings.text_scale)
	SoundBank.set_volume(settings.volume)
	if _current != null and _current.has_method("refresh") and not snapshot.is_empty():
		_current.refresh(self, true)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_H and close_hints():
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_F2 or (event.keycode == KEY_COMMA and event.ctrl_pressed):
		open_settings()
		get_viewport().set_input_as_handled()
		return
	if _current != null and _current.has_method("handle_key") and _current.handle_key(self, event.keycode):
		get_viewport().set_input_as_handled()


func _build_toast() -> void:
	_toast_label = UiKit.label("")
	_toast = UiKit.panel(_toast_label, "HighlightPanel")
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.position.y -= 24
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	add_child(_toast)


func _build_banner() -> void:
	_banner_label = UiKit.label("", "title", UiKit.ACCENT)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner = UiKit.panel(_banner_label, "HighlightPanel")
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.position.y += 4
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	add_child(_banner)


static func _local_now() -> float:
	return Time.get_ticks_msec() / 1000.0
