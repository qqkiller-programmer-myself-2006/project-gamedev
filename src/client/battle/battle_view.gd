class_name BattleView
extends Control
## Full-screen battle for Combats, Class Challenges and the Guardian Boss,
## laid out after docs/references/aac_rogue/ (04-07, 11): the initiative
## timeline on the left, the Party (left) facing the enemies (right) on a
## 2D stage, Region/Layer top-right, and at the bottom a HUD with your
## character, the Action window countdown, Gold, HP, Energy and the
## Attack / Skill / Defend / Item buttons. Skill and Item open a grid of
## cards above the HUD; targets are picked on the stage. Everything shown
## comes from the server's snapshot and events.
##
## Keys: A Attack, S Skill, D Defend, I Item, 1-9 pick a card or target,
## Esc back. Tokens and cards are buttons, so Tab/arrows + Enter work too.

## Where one-time tips appear while the battle is on screen.
var tips: VBoxContainer

var _screen: MatchScreen
var _app: ClientApp
var _combat: Dictionary = {}
var _me := ""
var _deadline: Variant = null
var _countdown: Label
## Action window as a draining bar under the countdown (cosmetic: the server
## enforces the deadline and Defends for you when it passes).
var _window_bar: ProgressBar
var _window_seconds := 15.0
## Actor shown last time, so the timeline only animates when the turn moves.
var _last_actor := ""
## Callables for keys 1-9 in the current list (cards or targets).
var _choices: Array[Callable] = []
## Token id -> [x, y] fraction of the stage for its top-left corner.
var _spots: Dictionary = {}
var _tokens: Dictionary = {}

var _stage: Control
var _timeline: VBoxContainer
var _region: Label
var _region_sub: Label
var _header: VBoxContainer
var _bottom: VBoxContainer
var _rewards: VBoxContainer
var _log: Label
var _log_lines: Array[String] = []
var _center_text: Label
var _banner: PanelContainer
var _banner_label: Label
var _banner_tween: Tween = null


func setup(screen: MatchScreen, app: ClientApp) -> void:
	_screen = screen
	_app = app
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var backdrop := BattleBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.resized.connect(_place_tokens)
	add_child(_stage)

	var left := MarginContainer.new()
	left.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left.offset_top = 52
	left.offset_bottom = -170
	left.custom_minimum_size = Vector2(212, 0)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_timeline = UiKit.vbox(4)
	_timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_timeline)
	left.add_child(scroll)
	add_child(left)

	var corner := UiKit.hbox(6)
	corner.position = Vector2(10, 10)
	corner.add_child(_small_button("Clues [C]", screen.toggle_clues))
	corner.add_child(_small_button("Settings [F2]", app.open_settings))
	corner.add_child(_small_button("Leave", func() -> void:
		app.send({"type": "leave_room"})
		app.disconnect_from_server()))
	add_child(corner)

	var region_box := UiKit.vbox(2)
	region_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	region_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	region_box.offset_right = -14
	region_box.offset_top = 6
	region_box.alignment = BoxContainer.ALIGNMENT_END
	_region = UiKit.pixel_label("", "title")
	_region.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_region.add_theme_color_override("font_outline_color", Color.BLACK)
	_region.add_theme_constant_override("outline_size", 6)
	region_box.add_child(_region)
	_region_sub = UiKit.pixel_label("", "small")
	var sub_panel := UiKit.panel(_region_sub, "HudPanel")
	sub_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	region_box.add_child(sub_panel)
	add_child(region_box)
	tips = UiKit.vbox(6)
	tips.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tips.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tips.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tips.offset_right = -10
	tips.offset_bottom = -10
	tips.custom_minimum_size = Vector2(220, 0)
	add_child(tips)

	_header = UiKit.vbox(6)
	_header.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_header.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_header.offset_top = 10
	_header.custom_minimum_size = Vector2(520, 0)
	_header.offset_left = -260
	_header.offset_right = 260
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_header)

	_center_text = UiKit.pixel_label("", "huge")
	_center_text.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_center_text.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_center_text.grow_vertical = Control.GROW_DIRECTION_BOTH
	_center_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_text.add_theme_color_override("font_outline_color", Color.BLACK)
	_center_text.add_theme_constant_override("outline_size", 10)
	add_child(_center_text)

	var bottom_left := UiKit.vbox(2)
	bottom_left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom_left.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom_left.offset_left = 14
	bottom_left.offset_bottom = -10
	bottom_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rewards = UiKit.vbox(0)
	bottom_left.add_child(_rewards)
	_log = UiKit.label("", "small", UiKit.TEXT_DIM)
	_log.custom_minimum_size = Vector2(220, 0)
	_log.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.max_lines_visible = 4
	_log.add_theme_color_override("font_outline_color", Color.BLACK)
	_log.add_theme_constant_override("outline_size", 3)
	bottom_left.add_child(_log)
	add_child(bottom_left)

	_bottom = UiKit.vbox(6)
	_bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bottom.offset_bottom = -8
	_bottom.alignment = BoxContainer.ALIGNMENT_END
	add_child(_bottom)

	_banner = PanelContainer.new()
	_banner.add_theme_stylebox_override("panel", UiKit.flat_box(Color(0.16, 0.16, 0.17, 0.78), Color(0, 0, 0, 0), 0, 8))
	_banner.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	_banner.anchor_top = 0.71
	_banner.anchor_bottom = 0.71
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_label = UiKit.pixel_label("", "title")
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_label)
	_banner.visible = false
	add_child(_banner)


## Rebuilds everything that depends on the snapshot.
func build(view: Dictionary, combat: Dictionary) -> void:
	_combat = combat
	_me = "p%d" % _screen.your_slot()
	var mode_key := "%d-%s-%s-%d" % [int(view.get("layer", 0)), str(view.get("phase")), combat.get("actor", ""),
			int(combat.get("round", 0))]
	if _screen.combat_mode_key != mode_key:
		_screen.combat_mode_key = mode_key
		_screen.combat_mode = ""
	_deadline = combat.get("deadline")
	_window_seconds = maxf(1.0, float(combat.get("window_seconds", 15.0)))
	_choices.clear()
	_build_region(view)
	_build_header(view)
	_build_timeline(view)
	_build_stage(view)
	_build_bottom(view)
	_build_result()
	tick()


func tick() -> void:
	if _countdown == null or not is_instance_valid(_countdown):
		return
	if _deadline == null:
		_countdown.text = ""
		return
	var left := _app.seconds_left(_deadline)
	_countdown.text = "%ds" % ceili(left)
	_countdown.add_theme_color_override("font_color", UiKit.WARN if left <= 5.0 else UiKit.TEXT)
	if _window_bar != null and is_instance_valid(_window_bar):
		_window_bar.value = clampf(left / _window_seconds, 0.0, 1.0) * _window_bar.max_value
		_window_bar.add_theme_stylebox_override("fill", UiKit.flat_box(UiKit.WARN if left <= 5.0 else UiKit.GOOD,
				Color(0, 0, 0, 0), 0, 0))
	if _combat.get("your_turn", false):
		_screen.warn_if_short(_deadline, left)


func handle_key(key: int) -> bool:
	if not _combat.get("your_turn", false):
		return false
	var choices: Dictionary = _combat.get("choices", {})
	match key:
		KEY_A:
			_set_mode("attack")
			return true
		KEY_S:
			if not choices.get("skills", {}).is_empty():
				_set_mode("skills")
			else:
				_app.toast(UiText.error("skill_unavailable"))
			return true
		KEY_D:
			_send({"action": "defend"})
			return true
		KEY_I:
			_set_mode("items")
			return true
		KEY_ESCAPE, KEY_BACKSPACE:
			if not _screen.combat_mode.is_empty():
				_set_mode("")
				return true
	var index := key - KEY_1
	if index >= 0 and index < _choices.size():
		_choices[index].call()
		return true
	return false


## The screen-wide band announcing a Skill, Item or Boss move (06).
func announce(text: String) -> void:
	_banner_label.text = text
	_banner.visible = true
	if _banner_tween != null:
		_banner_tween.kill()
	_banner.modulate.a = 1.0
	_banner_tween = create_tween()
	if _app.settings.reduced_motion:
		_banner_tween.tween_interval(1.4)
	else:
		_banner.modulate.a = 0.0
		_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.15)
		_banner_tween.tween_interval(1.1)
		_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.3)
	_banner_tween.tween_callback(func() -> void: _banner.visible = false)


func add_log(line: String) -> void:
	_log_lines.append(line)
	while _log_lines.size() > 3:
		_log_lines.pop_front()
	_log.text = "\n".join(_log_lines)


# --- Parts --------------------------------------------------------------------

func _build_region(view: Dictionary) -> void:
	var phase := str(view.get("phase", ""))
	var total := int(view.get("layers_total", 5))
	var encounter = view.get("encounter")
	if phase == "boss" or (encounter != null and encounter.get("kind") == "boss"):
		_region.text = "Forest (Boss)"
	else:
		_region.text = "Forest (%d/%d)" % [int(view.get("layer", 0)), total]
	var sub := "Round %d" % int(_combat.get("round", 1))
	if _combat.get("trial", false):
		sub = "Challenge  %d/%d" % [int(_combat.get("round", 1)), int(_combat.get("round_limit", 3))]
	_region_sub.text = sub


func _build_header(view: Dictionary) -> void:
	UiKit.clear(_header)
	var encounter: Dictionary = view.get("encounter", {}) if view.get("encounter") != null else {}
	if encounter.get("kind") == "boss":
		var boss: Dictionary = encounter["boss"]
		var head := UiKit.vbox(2)
		head.add_child(_centered(UiKit.pixel_label("%s, %s" % [boss["name"], boss["title"]], "heading", UiKit.ENEMY)))
		head.add_child(_centered(UiKit.pixel_label("Phase %d/%d: %s" % [int(boss["phase"]), int(boss["phases_total"]),
				boss["phase_name"]], "small", UiKit.WARN)))
		_header.add_child(UiKit.panel(head, "HudPanel"))
		var telegraph: Dictionary = boss.get("telegraph", {})
		if not telegraph.is_empty():
			var box := UiKit.vbox(2)
			var target := "the whole Party" if telegraph["target"] == "all" else _screen.name_of(str(telegraph["target"]))
			box.add_child(UiKit.para("WARNING: %s next turn, aimed at %s!" % [telegraph["name"], target], "body", UiKit.WARN))
			var advice := "Defend [D] to halve it"
			advice += ", or raise Shield Wall." if telegraph["target"] == "all" else ", or have a Guardian Protect them."
			box.add_child(UiKit.para(advice, "small"))
			var warn := UiKit.panel(box, "HudPanel")
			warn.add_theme_stylebox_override("panel", UiKit.flat_box(UiKit.HUD_BG, UiKit.WARN, 2, 8))
			_header.add_child(warn)
		_app.hint("boss")
	elif encounter.get("kind") == "class":
		var info: Dictionary = encounter.get("class_info", {})
		var class_name_text := str(info.get("name", str(encounter.get("class", "")).capitalize()))
		var head := UiKit.vbox(2)
		head.add_child(_centered(UiKit.pixel_label("Challenge: %s" % class_name_text, "heading", UiKit.ACCENT)))
		head.add_child(UiKit.para("Beat the trainer within %d rounds to learn the %s Class. Nobody can fall here." %
				[int(_combat.get("round_limit", 3)), class_name_text], "small"))
		_header.add_child(UiKit.panel(head, "HudPanel"))


## Initiative tracker: everyone in this round's turn order (Speed, highest
## first), the active combatant marked by an arrow, a NOW tag and a border
## (not colour alone), who controls each Party character, and HP (and
## Energy) from the latest server snapshot.
func _build_timeline(view: Dictionary) -> void:
	UiKit.clear(_timeline)
	var title := UiKit.pixel_label("Turn %d" % int(_combat.get("round", 1)), "title")
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	_timeline.add_child(title)
	var remaining: Array = _combat.get("turn_order", [])
	var order: Array = _combat.get("round_order", remaining)
	var actor := str(_combat.get("actor", ""))
	for id in order:
		var unit := _unit(view, str(id))
		if unit.is_empty():
			continue
		var entry := UiKit.vbox(1)
		var acted := not remaining.has(id)
		var is_actor: bool = id == actor
		var head := UiKit.hbox(4)
		var tag := _controller_tag(str(id), unit)
		head.add_child(UiKit.pixel_label(("> " if is_actor else "") + tag[0], "small", tag[1]))
		var color := UiKit.ACCENT if is_actor else (UiKit.TEXT_DIM if acted else UiKit.TEXT)
		var name_label := UiKit.pixel_label(_screen.name_of(str(id)), "small", color)
		name_label.clip_text = true
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(name_label)
		var hp := int(unit.get("hp", 0))
		head.add_child(UiKit.pixel_label("DOWN" if hp <= 0 else str(hp), "small", UiKit.TEXT_DIM if hp <= 0 else UiKit.TEXT))
		entry.add_child(head)
		entry.add_child(UiKit.stat_bar(hp, int(unit.get("max_hp", 1)), UiKit.BAR_HP, "", 6))
		if unit.has("energy"):
			entry.add_child(UiKit.stat_bar(int(unit["energy"]), int(unit.get("energy_max", 6)), UiKit.BAR_ENERGY, "", 4))
		var card := UiKit.panel(entry, "HudPanel")
		if is_actor:
			card.add_theme_stylebox_override("panel", UiKit.flat_box(UiKit.HUD_BG, UiKit.ACCENT, 2, 6))
		card.modulate = Color(1, 1, 1, 0.55) if hp <= 0 or acted else Color.WHITE
		card.tooltip_text = "%s (%s) - Speed %d - HP %d/%d%s%s" % [_screen.name_of(str(id)), tag[2],
				int(unit.get("spd", 0)), hp, int(unit.get("max_hp", 1)),
				(", Energy %d/%d" % [int(unit["energy"]), int(unit.get("energy_max", 6))]) if unit.has("energy") else "",
				" (already acted this round)" if acted else (" - acting now" if is_actor else "")]
		_timeline.add_child(card)
		if is_actor and actor != _last_actor:
			_app.fade_in(card, 0.3)
	_last_actor = actor


## [short tag, colour, long name] for who controls a timeline entry.
func _controller_tag(id: String, unit: Dictionary) -> Array:
	if not id.begins_with("p"):
		return ["FOE", UiKit.ENEMY, "enemy"]
	if id == _me:
		return ["YOU", UiKit.ACCENT, "you"]
	if str(unit.get("controller", "")) == "ai":
		return ["AI", UiKit.TEXT_DIM, "AI"]
	return ["P%d" % (int(id.substr(1)) + 1), UiKit.ALLY, "player"]


func _build_stage(view: Dictionary) -> void:
	for child in _stage.get_children():
		_stage.remove_child(child)
		child.queue_free()
	_tokens.clear()
	_spots.clear()
	var statuses: Dictionary = _combat.get("statuses", {})
	var party: Array = view.get("party", [])
	## Three staggered columns, clear of the header and the HUD.
	var formation := {0: [0.31, 0.18], 1: [0.20, 0.25], 2: [0.31, 0.44], 3: [0.20, 0.51], 4: [0.42, 0.31]}
	for character in party:
		var slot := int(character["slot"])
		var id := "p%d" % slot
		var data := {
			"id": id, "side": "party", "name": character["name"], "kind": character["class"],
			"hp": character["hp"], "max_hp": character["max_hp"],
			"energy": character.get("energy", 0), "energy_max": character.get("energy_max", 6),
			"statuses": statuses.get(id, []), "acting": _combat.get("actor", "") == id,
			"controller": character["controller"], "you": id == _me,
			"tooltip": "%s - Lv %d %s\nATK %d  DEF %d  MAG %d  RES %d  SPD %d" % [character["name"],
					int(character["level"]), character["class_name"], int(character["atk"]), int(character["def"]),
					int(character["mag"]), int(character["res"]), int(character["spd"])],
		}
		_spots[id] = formation.get(slot, [0.25, 0.3])
		_add_token(data)
	var enemies: Array = _combat.get("enemies", [])
	var fronts: Array = enemies.filter(func(e): return e["row"] == "front")
	var backs: Array = enemies.filter(func(e): return e["row"] != "front")
	var boss: bool = view.get("encounter") != null and view["encounter"].get("kind") == "boss"
	for group in [[fronts, 0.57], [backs, 0.73]]:
		var list: Array = group[0]
		for i in list.size():
			var enemy: Dictionary = list[i]
			var id := str(enemy["id"])
			var weakness: Array = enemy.get("weakness", [])
			var data := {
				"id": id, "side": "boss" if boss else "enemy", "name": _screen.name_of(id), "kind": enemy["kind"],
				"hp": enemy["hp"], "max_hp": enemy["max_hp"], "statuses": statuses.get(id, enemy.get("statuses", [])),
				"acting": _combat.get("actor", "") == id,
				"tooltip": "%s\n%s%s" % [_screen.name_of(id), enemy.get("description", ""),
						("\nWeak to: " + ", ".join(weakness)) if not weakness.is_empty() else ""],
			}
			var y := 0.32 if list.size() == 1 else 0.16 + i * (0.36 / float(list.size() - 1))
			_spots[id] = [float(group[1]) - (0.03 if boss else 0.0), 0.23 if boss else y]
			_add_token(data)
	var targets := _current_targets()
	for i in targets.size():
		var token: BattleToken = _tokens.get(str(targets[i]))
		if token == null:
			continue
		var cmd := _target_command(str(targets[i]))
		var pick := func() -> void: _send(cmd)
		token.set_target(i + 1, pick)
		_choices.append(pick)
	_place_tokens()


func _add_token(data: Dictionary) -> void:
	var token := BattleToken.new()
	token.setup(data)
	_stage.add_child(token)
	_tokens[data["id"]] = token
	_screen.anchors[data["id"]] = token


func _place_tokens() -> void:
	var area := _stage.size
	for id in _tokens:
		var token: BattleToken = _tokens[id]
		var spot: Array = _spots.get(id, [0.5, 0.3])
		token.position = Vector2(area.x * float(spot[0]), area.y * float(spot[1]))


func _build_bottom(view: Dictionary) -> void:
	UiKit.clear(_bottom)
	_countdown = null
	var me := _unit(view, _me)
	var mode := _screen.combat_mode
	var your_turn: bool = _combat.get("your_turn", false) and str(_combat.get("result", "")).is_empty()
	var choices: Dictionary = _combat.get("choices", {})
	if your_turn and mode in ["skills", "items"]:
		_bottom.add_child(_card_grid(mode, choices))
	elif your_turn and not mode.is_empty():
		var caption := UiKit.pixel_label("Choose a target on the field (1-%d), Esc to go back" % _choices.size(), "body", UiKit.ACCENT)
		caption.add_theme_color_override("font_outline_color", Color.BLACK)
		caption.add_theme_constant_override("outline_size", 5)
		_bottom.add_child(_centered(caption))

	var hud := UiKit.vbox(6)
	hud.custom_minimum_size = Vector2(600, 0)
	var info := UiKit.hbox(12)
	if not me.is_empty():
		var exp_text := "(%d/%d)" % [int(me.get("exp", 0)), int(me.get("exp_next", 0))] if int(me.get("exp_next", 0)) > 0 else "(MAX)"
		info.add_child(UiKit.pixel_label("%s Lvl %d %s" % [me.get("class_name", ""), int(me.get("level", 1)), exp_text], "heading"))
	info.add_child(UiKit.spacer())
	_countdown = UiKit.pixel_label("", "heading")
	info.add_child(_countdown)
	info.add_child(UiKit.spacer())
	info.add_child(UiKit.pixel_label("%d Gold" % int(view.get("gold", 0)), "heading", UiKit.ACCENT))
	hud.add_child(info)
	_window_bar = null
	if _deadline != null:
		_window_bar = UiKit.stat_bar(1000, 1000, UiKit.GOOD, "", 6)
		_window_bar.tooltip_text = "Action window: when it runs out you Defend automatically."
		hud.add_child(_window_bar)
	if not me.is_empty():
		var bars := UiKit.hbox(10)
		var hp := UiKit.stat_bar(int(me["hp"]), int(me["max_hp"]), UiKit.BAR_HP, "%d/%d" % [int(me["hp"]), int(me["max_hp"])], 24, "body")
		hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bars.add_child(hp)
		var energy := UiKit.energy_segments(int(me.get("energy", 0)), int(me.get("energy_max", 6)), 24, "body")
		energy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		energy.tooltip_text = "Energy pays for Skills. You start each Combat with 1 and regain 1 every later turn (max 6)."
		bars.add_child(energy)
		hud.add_child(bars)
	if your_turn:
		var actions := UiKit.hbox(8)
		var has_skills: bool = not choices.get("skills", {}).is_empty()
		actions.add_child(_action_button("Attack [A]", "attack", func() -> void: _set_mode("attack"), mode == "attack"))
		var skill := _action_button("Skill [S]", "skill", func() -> void: _set_mode("skills"), mode == "skills" or mode.begins_with("skill:"))
		if not has_skills:
			skill.disabled = true
			skill.tooltip_text = UiText.error("skill_unavailable")
		actions.add_child(skill)
		actions.add_child(_action_button("Defend [D]", "defend", func() -> void: _send({"action": "defend"}), false))
		var item := _action_button("Item [I]", "item", func() -> void: _set_mode("items"), mode == "items" or mode.begins_with("item:"))
		item.disabled = choices.get("items", {}).is_empty()
		actions.add_child(item)
		hud.add_child(actions)
		_app.hint("combat")
		if has_skills:
			_app.hint("energy")
	else:
		hud.add_child(_centered(UiKit.pixel_label(_waiting_text(), "body", UiKit.TEXT_DIM)))
	if not _combat.get("statuses", {}).is_empty():
		_app.hint("dot")
	var row := UiKit.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UiKit.panel(hud, "HudPanel"))
	if your_turn and not choices.get("skills", {}).is_empty():
		var squares := UiKit.hbox(4)
		squares.size_flags_vertical = Control.SIZE_SHRINK_END
		for skill_id in choices["skills"]:
			var info_skill: Dictionary = choices["skills"][skill_id]
			var left := int(info_skill["cooldown"])
			var mark := UiKit.vbox(0)
			var initial := UiKit.pixel_label(str(info_skill["name"]).substr(0, 1), "small", UiKit.TEXT_DIM)
			initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mark.add_child(initial)
			var affordable := bool(info_skill.get("affordable", true))
			var state := "OK"
			var state_color := UiKit.GOOD
			if left > 0:
				state = str(left)
				state_color = UiKit.TEXT
			elif not affordable:
				state = "E%d" % int(info_skill.get("energy", 0))
				state_color = UiKit.BAR_ENERGY
			var count := UiKit.pixel_label(state, "body", state_color)
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mark.add_child(count)
			var square := UiKit.panel(mark, "HudPanel")
			square.custom_minimum_size = Vector2(40, 0)
			var why := "ready"
			if left > 0:
				why = "%d turn(s) of cooldown left" % left
			elif not affordable:
				why = "needs %d Energy" % int(info_skill.get("energy", 0))
			square.tooltip_text = "%s: %s" % [info_skill["name"], why]
			squares.add_child(square)
		row.add_child(squares)
	_bottom.add_child(row)


## Grid of cards for Skills (with Attack and Defend first, like the
## reference's Strike and Guard) or Items (05).
func _card_grid(mode: String, choices: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	if mode == "skills":
		grid.add_child(_card("Attack", "Cost: 0 | Cooldown: 0", "A", UiKit.TEXT, true,
				"A basic attack.", func() -> void: _set_mode("attack")))
		grid.add_child(_card("Defend", "Cost: 0 | Cooldown: 0", "D", UiKit.TEXT, true,
				"Halve damage until your next turn.", func() -> void: _send({"action": "defend"})))
		for skill_id in choices.get("skills", {}):
			var info: Dictionary = choices["skills"][skill_id]
			var cooldown := int(info["cooldown"])
			var affordable := bool(info.get("affordable", true))
			var usable: bool = cooldown == 0 and affordable and not info["targets"].is_empty()
			var sub := "Cost: %d | Cooldown: %d" % [int(info.get("energy", 0)), cooldown]
			var why := ""
			if cooldown > 0:
				why = "Cooling down: %d more turn(s)." % cooldown
			elif not affordable:
				why = "Needs %d Energy." % int(info.get("energy", 0))
			elif info["targets"].is_empty():
				why = "No valid target."
			var tip := str(info.get("description", ""))
			if not why.is_empty():
				tip = why + "\n" + tip
			var pick := func() -> void: _pick_skill(skill_id, info)
			grid.add_child(_card(str(info["name"]), sub, str(info["name"]).substr(0, 1), UiKit.BAR_ENERGY, usable, tip, pick))
	else:
		for item_id in choices.get("items", {}):
			var info: Dictionary = choices["items"][item_id]
			var usable: bool = not info["targets"].is_empty()
			var pretty: String = item_id.replace("_", " ").capitalize()
			var pick := func() -> void: _pick_item(item_id, info)
			grid.add_child(_card("%s x%d" % [pretty, int(info["count"])], _item_description(item_id), pretty.substr(0, 1),
					UiKit.GOOD, usable, _item_description(item_id), pick))
	var holder := UiKit.panel(grid, "HudPanel")
	return _centered(holder)


func _card(title: String, sub: String, icon: String, icon_color: Color, usable: bool, tip: String, pick: Callable) -> Button:
	var number := _choices.size() + 1
	var button := Button.new()
	button.theme_type_variation = "HudButton"
	button.custom_minimum_size = Vector2(236, 58)
	button.focus_mode = Control.FOCUS_ALL
	button.disabled = not usable
	button.tooltip_text = tip
	button.set_meta("focus_id", "card_%s" % title)
	button.pressed.connect(pick)
	var row := UiKit.hbox(8)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	row.offset_right = -6
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glyph := UiKit.pixel_label(icon, "heading", icon_color)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var icon_box := UiKit.panel(glyph)
	icon_box.add_theme_stylebox_override("panel", UiKit.flat_box(Color(0.08, 0.08, 0.09, 0.9), icon_color, 2, 2))
	icon_box.custom_minimum_size = Vector2(40, 40)
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_box)
	var text := UiKit.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := UiKit.pixel_label("[%d] %s" % [number, title], "body", UiKit.TEXT if usable else UiKit.TEXT_DIM)
	name_label.clip_text = true
	text.add_child(name_label)
	var sub_label := UiKit.pixel_label(sub, "small", UiKit.TEXT_DIM)
	sub_label.clip_text = true
	text.add_child(sub_label)
	row.add_child(text)
	button.add_child(row)
	_choices.append(pick if usable else func() -> void: _app.toast(tip.get_slice("\n", 0)))
	return button


func _build_result() -> void:
	UiKit.clear(_rewards)
	var outcome := str(_combat.get("result", ""))
	_center_text.text = ""
	match outcome:
		"victory":
			_center_text.text = "Challenge won!" if _combat.get("trial", false) else "Victory!"
			_center_text.add_theme_color_override("font_color", UiKit.GOOD)
			var rewards: Dictionary = _combat.get("rewards", {})
			if not _combat.get("trial", false) and not rewards.is_empty():
				for item in rewards.get("items", {}):
					_rewards.add_child(_reward_line("%s%s" % [item.replace("_", " ").capitalize(),
							" x%d" % int(rewards["items"][item]) if int(rewards["items"][item]) > 1 else ""], UiKit.TEXT))
				_rewards.add_child(_reward_line("+%d Gold" % int(rewards.get("gold", 0)), UiKit.ACCENT))
				_rewards.add_child(_reward_line("%d EXP" % int(rewards.get("exp", 0)), UiKit.TEXT))
				if rewards.has("clue"):
					_rewards.add_child(_reward_line("Clue: %s" % rewards["clue"]["title"], UiKit.ALLY))
		"timeout":
			_center_text.text = "Time is up!"
			_center_text.add_theme_color_override("font_color", UiKit.WARN)
		"defeat":
			_center_text.text = "The Party has fallen..."
			_center_text.add_theme_color_override("font_color", UiKit.ENEMY)


func _reward_line(text: String, color: Color) -> Label:
	var line := UiKit.pixel_label(text, "title", color)
	line.add_theme_color_override("font_outline_color", Color.BLACK)
	line.add_theme_constant_override("outline_size", 6)
	return line


# --- Helpers ------------------------------------------------------------------

func _waiting_text() -> String:
	if not str(_combat.get("result", "")).is_empty():
		return "The fight is over."
	var actor := str(_combat.get("actor", ""))
	match str(_combat.get("actor_controller", "")):
		"human":
			return "Waiting for %s to act..." % _screen.name_of(actor)
		"ai":
			return "%s (AI) is acting..." % _screen.name_of(actor)
		"enemy":
			return "%s is acting..." % _screen.name_of(actor)
	return ""


## Party character or enemy view with the fields the timeline needs.
func _unit(view: Dictionary, id: String) -> Dictionary:
	if id.begins_with("p"):
		for character in view.get("party", []):
			if "p%d" % int(character["slot"]) == id:
				return character
		return {}
	for enemy in _combat.get("enemies", []):
		if enemy["id"] == id:
			return enemy
	return {}


func _current_targets() -> Array:
	var mode := _screen.combat_mode
	var choices: Dictionary = _combat.get("choices", {})
	if not _combat.get("your_turn", false) or choices.is_empty():
		return []
	if mode == "attack":
		return choices["attack"]["targets"]
	if mode.begins_with("skill:"):
		return choices["skills"].get(mode.trim_prefix("skill:"), {}).get("targets", [])
	if mode.begins_with("item:"):
		return choices["items"].get(mode.trim_prefix("item:"), {}).get("targets", [])
	return []


func _target_command(target: String) -> Dictionary:
	var mode := _screen.combat_mode
	if mode == "attack":
		return {"action": "attack", "target": target}
	var parts := mode.split(":")
	return {"action": parts[0], parts[0]: parts[1], "target": target}


func _pick_skill(skill_id: String, info: Dictionary) -> void:
	match str(info["target"]):
		"all_enemies", "all_allies":
			_send({"action": "skill", "skill": skill_id})
		"self":
			_send({"action": "skill", "skill": skill_id, "target": _me})
		_:
			_set_mode("skill:" + skill_id)


func _pick_item(item_id: String, info: Dictionary) -> void:
	if str(info["target"]) in ["all_enemies", "all_allies"]:
		_send({"action": "item", "item": item_id})
	else:
		_set_mode("item:" + item_id)


func _set_mode(mode: String) -> void:
	_screen.combat_mode = mode
	_screen.refresh(_app, true)


func _send(cmd: Dictionary) -> void:
	var full := {"type": "action"}
	full.merge(cmd)
	_app.send(full)


func _item_description(item_id: String) -> String:
	for entry in _screen.match_view().get("inventory", []):
		if entry["item"] == item_id:
			return str(entry["description"])
	return ""


func _action_button(text: String, id: String, callback: Callable, active: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = "HudButton"
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_meta("focus_id", "action_" + id)
	button.pressed.connect(callback)
	if active:
		button.add_theme_color_override("font_color", UiKit.ACCENT)
	return button


func _small_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = "HudButton"
	button.add_theme_font_size_override("font_size", int(UiKit.SIZES["small"] * _app.settings.text_scale))
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	return button


static func _centered(node: Control) -> Control:
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(node)
	return holder


## Focuses the first target on the field, else the first HUD button.
func focus_default() -> void:
	for id in _tokens:
		var token: BattleToken = _tokens[id]
		if token.target_number == 1:
			token.grab_focus()
			return
	UiKit.focus_first(_bottom)
