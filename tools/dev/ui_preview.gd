extends SceneTree
## Plays a Duo co-op Match with the real client UI and saves a screenshot of
## every kind of screen. The local player ("Ann") is driven only through
## keyboard events, so this also exercises keyboard control; the second
## player is a MatchBot. Needs a display (use xvfb-run on servers):
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 -s tools/dev/ui_preview.gd -- --out=build/ui --seed=7
##
## Options: --out=DIR  --seed=N  --speed=X (game seconds per real second)
##          --scale=1.2 (text size)  --reduced-motion
##          --class=assassin (every Class Encounter teaches that Class)
##          --setup-only (capture Room and Character setup, then exit)
##          --resolution=1920x1080 (window size; the UI stretches from 1280x720)

var out_dir := "build/ui"
var speed := 10.0
const MAX_RUN_FRAMES := 60 * 60 * 15
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
var _setup_only := false
var _language := "th"
var _sprite_idle_after := 0.0
var _used_focus := false
var _used_item := false


func _initialize() -> void:
	var seed_value := 7
	var scale := 1.0
	var reduced := false
	var only_class := ""
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
		elif arg == "--setup-only":
			_setup_only = true
		elif arg.begins_with("--class="):
			only_class = arg.trim_prefix("--class=")
		elif arg.begins_with("--resolution="):
			var parts := arg.trim_prefix("--resolution=").split("x")
			if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
				DisplayServer.window_set_size(Vector2i(int(parts[0]), int(parts[1])))
		elif arg.begins_with("--lang="):
			_language = arg.trim_prefix("--lang=")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var overrides := {}
	if not only_class.is_empty():
		overrides = {"journey": {"sites": {"class": [{"id": "only", "name": "Training Ground",
				"hint": "Someone waits to teach you.", "classes": {only_class: 1}}]}},
				"rules": {"ai_class_cap": 5}}
	harness = MatchHarness.new(seed_value, overrides)
	app = ClientApp.new()
	app.configure({"name": "Ann", "lang": _language})
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
		# Play now offers Story or Multiplayer; the preview drives the Multiplayer form.
		app.use_connection(local)
		local.start()
		(app._current as TitleScreen)._show_multiplayer()
		(app._current as TitleScreen)._create()
		return false
	if frame == 25:
		friend = harness.server.open_session()
		harness.server.command(friend, {"type": "join_room", "code": _code(), "name": "Bob"})
		friend_bot = MatchBot.new(harness, [friend])
		friend_bot.choose_route = _preview_route
		return false
	if frame == 40:
		app._toast_until = 0.0
		_shot("02_lobby")
		(app._current as LobbyScreen)._open_setup()
		return false
	if frame == 45:
		_shot("02a_setup_class")
		(app._current as LobbyScreen)._setup._cycle_class(-1)
		(app._current as LobbyScreen)._setup._switch_tab("Races")
		(app._current as LobbyScreen)._setup._race = "Dwarf"
		(app._current as LobbyScreen)._setup._render()
		return false
	if frame == 50:
		_shot("02b_setup_races")
		(app._current as LobbyScreen)._setup._switch_tab("Boons")
		return false
	if frame == 55:
		_shot("02c_setup_boons")
		(app._current as LobbyScreen)._setup._select_boon("Alert")
		return false
	if frame == 60:
		_shot("02d_setup_boons_equipped")
		var chosen: Dictionary = (app._current as LobbyScreen)._setup._own_loadout()
		if chosen.get("class", "") != "guardian" or not chosen.get("boons", []).has("Alert"):
			printerr("ui_preview: Character setup did not reach the room snapshot")
			quit(1)
			return true
		(app._current as LobbyScreen)._setup._finish.call()
		return false
	if frame == 65:
		_shot("02e_lobby_loadout")
		if _setup_only:
			return true
		app.confirm_leave()
		return false
	if frame == 68:
		_shot("02f_confirm_leave")
		for node in app._overlay_holder.get_children():
			if node is ConfirmDialog:
				node.close()
		app.open_settings()
		return false
	if frame == 69:
		_shot("02g_settings")
		for node in app._overlay_holder.get_children():
			if node is SettingsPanel:
				node.queue_free()
		app.send({"type": "start_match"})
		return false
	if frame < 70:
		return false
	harness.clock.advance(delta * speed)
	harness.server.update()
	friend_bot.act(friend)
	if _done_at > 0:
		return frame > _done_at
	_drive()
	if frame > MAX_RUN_FRAMES:
		printerr("ui_preview: no Summary screen after %d frames" % frame)
		quit(1)
		return true
	return false


## Screenshots each new situation once, then acts like a player.
func _drive() -> void:
	var view = app.snapshot.get("match")
	if view == null:
		return
	var screen := _screen()
	var battle = screen._battle if screen != null else null
	if battle != null:
		_capture_sprite_frames(battle)
		for child in battle.tips.get_children():
			if child.has_meta("hint") and not child.is_queued_for_deletion():
				if not shots.has("04_combat_hint"):
					_shot("04_combat_hint")
				_press(KEY_H)
				return
	if battle != null and battle._banner != null and battle._banner.visible and not shots.has("06_action_banner"):
		_shot("06_action_banner")
	if battle != null and str(battle._combat.get("result", "")) == "victory" and not shots.has("11_combat_reward"):
		_shot("11_combat_reward")
	var key := _situation(view)
	if key.is_empty():
		return
	if key != _last_key:
		_last_key = key
		# The preview clock advances at --speed, so the usual reaction pause can
		# consume the entire vote timer at high speed and miss keyboard input.
		_think_until = Time.get_ticks_msec() / 1000.0 + (0.1 if key == "03_vote" else 0.6)
		return
	if Time.get_ticks_msec() / 1000.0 < _think_until:
		return
	if not shots.has(key):
		_shot(key)
	_act(key, view)
	_think_until = Time.get_ticks_msec() / 1000.0 + 0.5


func _capture_sprite_frames(battle: BattleView) -> void:
	for token in battle._tokens.values():
		if token.sprite_set == null:
			continue
		var state: String = token.animation
		if state == "idle" and not shots.has("sprite_idle"):
			if _sprite_idle_after == 0.0:
				_sprite_idle_after = Time.get_ticks_msec() / 1000.0 + 0.8
			if Time.get_ticks_msec() / 1000.0 < _sprite_idle_after:
				continue
		if state != "idle" and token.animation_frame == 0:
			continue
		if state == "attack" and token.animation_frame != token.animation_frames.size() - 1:
			continue
		if state == "dead" and token.animation_frame != token.animation_frames.size() - 1:
			continue
		var name := "sprite_" + state
		if not shots.has(name):
			_shot(name)


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
				if mode == "skills":
					return prefix + "_skills"
				if mode == "items":
					return prefix + "_items"
				return prefix + ("_targets" if mode == "attack" or mode.begins_with("skill:") or mode.begins_with("item:") else "_turn")
			return ""
		"class":
			if encounter["stage"] == "challenge":
				if not encounter["trial"]["your_turn"]:
					return ""
				var mode := _screen().combat_mode if _screen() != null else ""
				if mode == "skills":
					return "05_class_challenge_skills"
				return "05_class_challenge_targets" if mode == "attack" or mode.begins_with("skill:") else "05_class_challenge_turn"
			return "05_class_offer" if encounter["offer"]["you_can_decide"] else ""
		"merchant":
			return "08_merchant" if not encounter["you_are_ready"] else ""
		"story":
			if encounter["stage"] == "choosing":
				return "09_story_choice" if not encounter["vote"]["voted_slots"].has(0) else ""
			return "09_story_outcome" if not encounter["you_are_ready"] else ""
		"rest":
			return "10_rest" if not encounter["you_are_ready"] else ""
		"treasure":
			return "10_treasure" if not shots.has("10_treasure") else ""
	return ""


func _act(key: String, view: Dictionary) -> void:
	if key.begins_with("90_summary"):
		_done_at = frame + 30
	elif key == "03_vote":
		var options: Array = view["vote"]["options"]
		var pick := MatchBot.sensible_route(options, 0, view)
		# Visit a Rest camp once so accessibility evidence always includes it.
		if not shots.has("10_rest"):
			for option in options:
				if option["type"] == "rest":
					pick = option["index"]
		print("ui_preview: vote options=", options, " selected=", pick)
		_press(KEY_1 + pick)
	elif key.ends_with("_turn"):
		var encounter: Dictionary = view["encounter"]
		var combat: Dictionary = MatchScreen.combat_of(encounter)
		var threat: Dictionary = combat.get("boss", {}).get("telegraph", {})
		var choices: Dictionary = combat.get("choices", {})
		if choices.get("focus", false) and not _used_focus and threat.is_empty():
			_used_focus = true
			_press(KEY_O)
		elif not choices.get("items", {}).is_empty() and not _used_item and threat.is_empty():
			_used_item = true
			_press(KEY_I)
		else:
			_press(KEY_F)
	elif key.ends_with("_skills"):
		# Fight [F] opens cards: 1 Strike, 2 Guard, then Skills.
		var combat: Dictionary = MatchScreen.combat_of(view["encounter"])
		var threat: Dictionary = combat.get("boss", {}).get("telegraph", {})
		if threat.get("target", "") in ["p0", "all"]:
			_press(KEY_2)
			return
		var skills: Dictionary = combat.get("choices", {}).get("skills", {})
		var picked := 1 # Strike is the safe fallback when no Skill is ready.
		var number := 3
		for skill in skills:
			if skills[skill]["cooldown"] == 0 and skills[skill].get("affordable", true) and not skills[skill]["targets"].is_empty():
				picked = number
				break
			number += 1
		_press(KEY_1 + picked - 1)
	elif key.ends_with("_items"):
		var items: Dictionary = MatchScreen.combat_of(view["encounter"]).get("choices", {}).get("items", {})
		_press(KEY_1 if not items.is_empty() else KEY_ESCAPE)
	elif key.ends_with("_targets"):
		_press(KEY_1)
	elif key == "05_class_offer":
		_press(KEY_Y)
	elif key == "08_merchant":
		_press(KEY_R)
	elif key == "10_rest":
		_press(KEY_R)
	elif key == "09_story_choice":
		_press(KEY_1)
	elif key == "09_story_outcome":
		_press(KEY_ENTER)
	if app.connection != null:
		app.connection.poll()


func _preview_route(options: Array, slot: int, view: Dictionary) -> int:
	# Align the preview bot with the local player until Rest evidence is captured,
	# so a tie cannot randomly send the run down another route.
	if not shots.has("10_rest"):
		for option in options:
			if str(option.get("type", "")) == "rest":
				return int(option["index"])
	return MatchBot.sensible_route(options, slot, view)


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
	if name.ends_with("_skills"):
		var battle := _screen()._battle
		for button in battle._bottom.find_children("*", "Button", true, false):
			if button.get_meta("focus_id", "") == "action_focus":
				print("focus choice=", battle._combat.get("choices", {}).get("focus", false),
						" button_disabled=", button.disabled)
				break
		for enemy in battle._combat.get("enemies", []):
			print("enemy energy ", enemy.get("id", "?"), "=", enemy.get("energy", "missing"))


func _code() -> String:
	var room = app.snapshot.get("room")
	return str(room["code"]) if room != null else ""


func _screen() -> MatchScreen:
	for child in app.get_children():
		for grandchild in child.get_children():
			if grandchild is MatchScreen:
				return grandchild
	return null
