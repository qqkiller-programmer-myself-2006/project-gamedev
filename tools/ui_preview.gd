extends SceneTree
## Plays a Duo co-op Match with the real client UI and saves a screenshot of
## every kind of screen. The local player ("Ann") is driven only through
## keyboard events, so this also exercises keyboard control; the second
## player is a MatchBot. Needs a display (use xvfb-run on servers):
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 -s tools/ui_preview.gd -- --out=build/ui --seed=7
##
## Options: --out=DIR  --seed=N  --speed=X (game seconds per real second)
##          --scale=1.2 (text size)  --reduced-motion

var out_dir := "build/ui"
var speed := 4.0
var harness: MatchHarness
var app: ClientApp
var local: LocalConnection
var friend := 0
var friend_bot: MatchBot
var shots: Dictionary = {}
var frame := 0
var _think_until := 0.0
var _last_key := ""
var _done_at := -1


func _initialize() -> void:
	var seed_value := 7
	var scale := 1.0
	var reduced := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--seed="):
			seed_value = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--speed="):
			speed = float(arg.trim_prefix("--speed="))
		elif arg.begins_with("--scale="):
			scale = float(arg.trim_prefix("--scale="))
		elif arg == "--reduced-motion":
			reduced = true
	DirAccess.make_dir_recursive_absolute(out_dir)
	harness = MatchHarness.new(seed_value)
	app = ClientApp.new()
	app.configure({"name": "Ann"})
	root.add_child(app)
	set_meta("scale", scale)
	set_meta("reduced", reduced)
	local = LocalConnection.new(harness.server)


func _process(delta: float) -> bool:
	frame += 1
	if frame == 2:
		app.settings.text_scale = get_meta("scale")
		app.settings.reduced_motion = get_meta("reduced")
		app.settings.seen_hints = []
		app.apply_settings()
	if frame == 15:
		_shot("01_title")
		# Already "connected" in-process; Enter on the focused Create button
		# sends create_room just like a real player would.
		app.use_connection(local)
		local.start()
		_press(KEY_ENTER)
		return false
	if frame == 25:
		friend = harness.server.open_session()
		harness.server.command(friend, {"type": "join_room", "code": _code(), "name": "Bob"})
		friend_bot = MatchBot.new(harness, [friend])
		friend_bot.choose_route = MatchBot.sensible_route
		return false
	if frame == 40:
		_shot("02_lobby")
		_press(KEY_ENTER)
		return false
	if frame < 45:
		return false
	harness.clock.advance(delta * speed)
	harness.server.update()
	friend_bot.act(friend)
	if _done_at > 0:
		return frame > _done_at
	_drive()
	if frame > 60 * 60 * 8:
		printerr("ui_preview: gave up after %d frames" % frame)
		return true
	return false


## Screenshots each new situation once, then acts like a player.
func _drive() -> void:
	var view = app.snapshot.get("match")
	if view == null:
		return
	var key := _situation(view)
	if key.is_empty():
		return
	if key != _last_key:
		_last_key = key
		_think_until = Time.get_ticks_msec() / 1000.0 + 0.6
		return
	if Time.get_ticks_msec() / 1000.0 < _think_until:
		return
	if not shots.has(key):
		_shot(key)
	_act(key, view)
	_think_until = Time.get_ticks_msec() / 1000.0 + 0.5


func _situation(view: Dictionary) -> String:
	var phase := str(view["phase"])
	if phase in ["victory", "defeat"]:
		return "90_summary_" + phase
	if phase == "voting":
		return "03_vote" if not view["vote"]["voted_slots"].has(0) else ""
	var encounter = view.get("encounter")
	if encounter == null:
		return ""
	match str(encounter["kind"]):
		"combat", "boss":
			var prefix := "06_boss" if encounter["kind"] == "boss" else "04_combat"
			if encounter.get("boss", {}).get("telegraph", {}).size() > 0 and not shots.has("07_boss_warning"):
				return "07_boss_warning"
			if encounter["your_turn"]:
				var mode := _screen().combat_mode if _screen() != null else ""
				return prefix + ("_targets" if mode == "attack" else "_turn")
			return ""
		"class":
			if encounter["stage"] == "challenge":
				return "05_class_challenge" if encounter["trial"]["your_turn"] else ""
			return "05_class_offer" if encounter["offer"]["you_can_decide"] else ""
		"merchant":
			return "08_merchant" if not encounter["you_are_ready"] else ""
		"story":
			if encounter["stage"] == "choosing":
				return "09_story_choice" if not encounter["vote"]["voted_slots"].has(0) else ""
			return "09_story_outcome" if not encounter["you_are_ready"] else ""
		"rest", "treasure":
			return "10_" + str(encounter["kind"]) if not shots.has("10_" + str(encounter["kind"])) else ""
	return ""


func _act(key: String, view: Dictionary) -> void:
	if key.begins_with("90_summary"):
		_done_at = frame + 30
	elif key == "03_vote":
		var options: Array = view["vote"]["options"]
		_press(KEY_1 + MatchBot.sensible_route(options, 0, view))
	elif key.ends_with("_turn") or key == "05_class_challenge":
		var encounter: Dictionary = view["encounter"]
		var combat: Dictionary = MatchScreen.combat_of(encounter)
		var threat: Dictionary = combat.get("boss", {}).get("telegraph", {})
		if threat.get("target", "") == "p0":
			_press(KEY_D)
		elif not combat["choices"]["skills"].is_empty() and frame % 2 == 0:
			_press(KEY_S)
		else:
			_press(KEY_A)
	elif key.ends_with("_targets"):
		_press(KEY_1)
	elif key == "05_class_offer":
		_press(KEY_Y)
	elif key == "08_merchant":
		_press(KEY_1)
		_press(KEY_R)
	elif key == "09_story_choice":
		_press(KEY_1)
	elif key == "09_story_outcome":
		_press(KEY_ENTER)
	if app.connection != null:
		app.connection.poll()


func _press(keycode: int) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.pressed = pressed
		Input.parse_input_event(event)


func _shot(name: String) -> void:
	shots[name] = true
	var image := root.get_viewport().get_texture().get_image()
	image.save_png(out_dir.path_join(name + ".png"))
	print("screenshot ", name)


func _code() -> String:
	var room = app.snapshot.get("room")
	return str(room["code"]) if room != null else ""


func _screen() -> MatchScreen:
	for child in app.get_children():
		for grandchild in child.get_children():
			if grandchild is MatchScreen:
				return grandchild
	return null
