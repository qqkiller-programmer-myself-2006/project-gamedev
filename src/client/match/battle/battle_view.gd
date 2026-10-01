class_name BattleView
extends Control
## Full-screen battle for Combats, Class Challenges and the Guardian Boss,
## laid out after docs/references/aac_assassin/ (04-07, 11): the initiative
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
var _view: Dictionary = {}
var _content: Dictionary = {}
static var _forest_content: Dictionary = {}
static var forest_parse_count := 0
var _me := ""
var _deadline: Variant = null
var _countdown: Label
var _window_seconds := 15.0
## Actor shown last time, so the timeline only animates when the turn moves.
var _last_actor := ""
## Callables for keys 1-9 in the current list (cards or targets).
var _choices: Array[Callable] = []
## Token id -> [x, y] fraction of the stage for its top-left corner.
var _spots: Dictionary = {}
var _tokens: Dictionary = {}
var _previous_tokens: Dictionary = {}

var _stage: Control
var _backdrop: BattleBackdrop
var _timeline: VBoxContainer
var _timeline_scroll: ScrollContainer
var _enemy_plates: Control
var _turn_banner: PanelContainer
var _region: Label
var _region_sub: Label
var _header: VBoxContainer
var _bottom: VBoxContainer
var _rewards: VBoxContainer
var _log: RichTextLabel
var _log_lines: Array[String] = []
var _center_text: Label
var _turn_notice: Label
var _banner: PanelContainer
var _banner_label: Label
var _banner_tween: Tween = null
var _menu_panel: PanelContainer
var _combat_grid: Control
var _skill_marks: Control


func setup(screen: MatchScreen, app: ClientApp) -> void:
	_screen = screen
	_app = app
	_content = _load_forest_content()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_backdrop = BattleBackdrop.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.resized.connect(_place_tokens)
	add_child(_stage)

	var left := MarginContainer.new()
	left.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left.offset_left = 16
	left.offset_top = 108
	left.offset_bottom = -190
	left.custom_minimum_size = Vector2(224, 0)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scroll := ScrollContainer.new()
	_timeline_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_timeline = UiKit.vbox(4)
	_timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_timeline)
	left.add_child(scroll)
	add_child(left)
	var turn_label := UiKit.pixel_label("Turn 1", "body", UiKit.GOLD)
	turn_label.add_theme_font_size_override("font_size", int(18 * _app.settings.text_scale))
	_turn_banner = UiKit.panel(turn_label, "OrnamentPanel")
	_turn_banner.add_theme_stylebox_override("panel", UiKit.flat_box(UiKit.HUD_BG, UiKit.GOLD, 2, 5))
	_turn_banner.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_turn_banner.offset_left = 20
	_turn_banner.offset_top = 57
	_turn_banner.custom_minimum_size = Vector2(208, 43)
	add_child(_turn_banner)
	_enemy_plates = Control.new()
	_enemy_plates.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_enemy_plates.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemy_plates.z_index = 4
	add_child(_enemy_plates)

	_menu_panel = screen.build_corner_menu(self)
	_menu_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_menu_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_menu_panel.offset_top = 82
	_menu_panel.offset_right = -10

	var region_box := UiKit.vbox(2)
	_region = UiKit.number_label("", "title")
	_region.add_theme_font_size_override("font_size", int(23 * _app.settings.text_scale))
	_region.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_region.add_theme_color_override("font_outline_color", UiKit.BG)
	_region.add_theme_constant_override("outline_size", 6)
	region_box.add_child(_region)
	_region_sub = UiKit.pixel_label("", "small")
	_region_sub.visible = false
	var sub_panel := UiKit.panel(_region_sub, "HudPanel")
	sub_panel.visible = false
	sub_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	region_box.add_child(sub_panel)
	var region_frame := UiKit.panel(region_box, "OrnamentPanel")
	region_frame.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	region_frame.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	region_frame.offset_right = -14
	region_frame.offset_top = 6
	region_frame.custom_minimum_size = Vector2(188, 52)
	add_child(region_frame)
	tips = UiKit.vbox(6)
	tips.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tips.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tips.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tips.offset_right = -10
	# Keep tips above the action HUD rather than behind or on top of its buttons.
	tips.offset_bottom = -190 * _app.settings.text_scale
	tips.custom_minimum_size = Vector2(220, 0)
	tips.z_index = 50
	tips.visible = true
	add_child(tips)
	_header = UiKit.vbox(6)
	_header.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_header.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_header.offset_top = 15
	_header.custom_minimum_size = Vector2(520, 0)
	_header.offset_left = -260
	_header.offset_right = 260
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_header)

	_center_text = UiKit.pixel_label("", "huge")
	_center_text.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_center_text.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_center_text.offset_top = 470
	_center_text.offset_bottom = 520
	_center_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_text.add_theme_color_override("font_outline_color", Color.BLACK)
	_center_text.add_theme_constant_override("outline_size", 10)
	add_child(_center_text)
	_turn_notice = UiKit.number_label("", "body", UiKit.ACCENT)
	_turn_notice.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_turn_notice.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_turn_notice.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_turn_notice.offset_top = -240
	_turn_notice.offset_bottom = -200
	_turn_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_notice.add_theme_color_override("font_outline_color", Color.BLACK)
	_turn_notice.add_theme_constant_override("outline_size", 4)
	_turn_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn_notice.visible = false
	add_child(_turn_notice)

	# Keep the log below the hero lane and clear of the centered action HUD.
	var bottom_left := UiKit.vbox(2)
	bottom_left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom_left.grow_horizontal = Control.GROW_DIRECTION_END
	bottom_left.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom_left.offset_left = 250
	bottom_left.offset_bottom = -140 if _app.settings.text_scale <= 1.0 else -185
	bottom_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log = RichTextLabel.new()
	_log.bbcode_enabled = false
	_log.scroll_following = true
	var log_lines := 3 if _app.settings.text_scale <= 1.0 else 2
	var log_width := maxf(110.0, 245.0 - 300.0 * (_app.settings.text_scale - 1.0))
	_log.custom_minimum_size = Vector2(log_width, 22.0 * log_lines * maxf(1.0, _app.settings.text_scale))
	_log.scroll_active = false
	_log.fit_content = false
	_log.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_log.focus_mode = Control.FOCUS_NONE
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.add_theme_color_override("default_color", UiKit.TEXT_DIM)
	_log.add_theme_color_override("font_outline_color", Color.BLACK)
	_log.add_theme_constant_override("outline_size", 3)
	var log_panel := UiKit.panel(_log, "HudPanel")
	log_panel.custom_minimum_size = Vector2(log_width, 0)
	_rewards = UiKit.vbox(0)
	bottom_left.add_child(_rewards)
	bottom_left.add_child(log_panel)
	add_child(bottom_left)

	_bottom = UiKit.vbox(6)
	_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom.offset_left = 29
	_bottom.offset_right = -29
	_bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bottom.offset_bottom = -8
	_bottom.alignment = BoxContainer.ALIGNMENT_END
	add_child(_bottom)

	_banner = PanelContainer.new()
	_banner.theme_type_variation = "BannerPanel"
	_banner.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_banner.offset_left = 930
	_banner.offset_right = 1170
	_banner.offset_top = 200
	_banner.offset_bottom = 222
	_banner.resized.connect(func() -> void: _banner.pivot_offset = _banner.size * 0.5)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_label = UiKit.pixel_label("", "tiny")
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_label)
	_banner.visible = false
	add_child(_banner)


## Rebuilds everything that depends on the snapshot.
func _backdrop_name(view: Dictionary, encounter: Dictionary) -> String:
	if str(encounter.get("kind", "")) == "boss":
		return str(encounter.get("backdrop", _content.get("boss", {}).get("backdrop", "")))
	return str(_content.get("journey", {}).get("backdrops", {}).get(str(view.get("layer", 1)), ""))

static func _load_forest_content() -> Dictionary:
	if _forest_content.is_empty():
		var content_file := FileAccess.open("res://content/forest.json", FileAccess.READ)
		if content_file != null:
			var parsed = JSON.parse_string(content_file.get_as_text())
			if parsed is Dictionary:
				_forest_content = parsed
				forest_parse_count += 1
	return _forest_content


func build(view: Dictionary, combat: Dictionary) -> void:
	_view = view
	_combat = combat
	var encounter: Dictionary = view.get("encounter", {}) if view.get("encounter") is Dictionary else {}
	_backdrop.set_backdrop(_backdrop_name(view, encounter))
	_me = str(combat.get("actor", "")) if _screen.room_view().get("story", false) and str(combat.get("actor", "")).begins_with("p") else "p%d" % _screen.your_slot()
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


func refresh_action_panel() -> void:
	_choices.clear()
	for token_value in _tokens.values():
		var token := token_value as BattleToken
		token.set_target(0, Callable())
	var targets := _current_targets()
	for i in targets.size():
		var target := str(targets[i])
		var token := _tokens.get(target) as BattleToken
		if token == null:
			continue
		var command := _target_command(target)
		var pick := func() -> void: _send(command)
		token.set_target(i + 1, pick)
		_choices.append(pick)
	_build_bottom(_view)
	if not targets.is_empty():
		focus_default()

func tick() -> void:
	if _countdown == null or not is_instance_valid(_countdown):
		return
	if not _combat.get("your_turn", false):
		_countdown.text = _waiting_text()
		_countdown.remove_theme_color_override("font_color")
		return
	if _deadline == null or float(_deadline) < 0.0:
		_countdown.text = ""
		return
	var left := _app.seconds_left(_deadline)
	_countdown.text = "%ds" % ceili(left)
	var next_color := UiKit.WARN if left <= 5.0 else UiKit.TEXT
	if _countdown.get_theme_color("font_color") != next_color:
		_countdown.add_theme_color_override("font_color", next_color)
	if _combat.get("your_turn", false):
		_screen.warn_if_short(_deadline, left)


func handle_key(key: int) -> bool:
	# Esc: close the menu, else step back out of target picking, else open the menu.
	if key == KEY_ESCAPE and (_menu_panel.visible or _screen.combat_mode.is_empty()
			or not _combat.get("your_turn", false)):
		_menu_panel.visible = not _menu_panel.visible
		if _menu_panel.visible:
			UiKit.focus_first(_menu_panel)
		return true
	if not _combat.get("your_turn", false):
		return false
	var choices: Dictionary = _combat.get("choices", {})
	match key:
		KEY_F:
			_set_mode("skills")
			return true
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
		KEY_O:
			if choices.get("focus", false):
				_send({"action": "focus"})
			else:
				_app.toast(UiText.WHY["focus_unavailable"])
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
	if not str(_combat.get("result", "")).is_empty():
		return
	if text == "Your turn!":
		_turn_notice.text = text
		_turn_notice.visible = true
		var notice_tween := create_tween()
		notice_tween.tween_interval(1.5 if _app.settings.reduced_motion else 1.2)
		notice_tween.tween_callback(func() -> void: _turn_notice.visible = false)
		return
	_banner_label.text = text
	_banner.visible = true
	_banner.rotation_degrees = -1.0
	if _banner_tween != null:
		_banner_tween.kill()
	_banner.modulate.a = 1.0
	if is_inside_tree():
		_banner_tween = create_tween()
		_banner_tween.tween_interval(0.9 if _app.settings.reduced_motion else 0.6)
		if not _app.settings.reduced_motion:
			_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.3)
		_banner_tween.tween_callback(func() -> void:
			_banner.visible = false
			if _combat_grid != null and is_instance_valid(_combat_grid):
				_combat_grid.visible = true
		)


func _set_action_row_visible(visible: bool) -> void:
	if _bottom == null:
		return
	for node in _bottom.find_children("*", "Control", true, false):
		if node.has_meta("combat_action_row"):
			node.visible = visible


func add_log(line: String) -> void:
	_log_lines.append(line)
	while _log_lines.size() > 3:
		_log_lines.pop_front()
	_log.clear()
	_log.append_text("\n".join(_log_lines))
	_log.scroll_to_line(_log.get_line_count())

## Apply a server event to the existing token animations. The server event is
## the source of truth; this method never infers an action from local input.
func handle_event(event: Dictionary) -> void:
	if str(event.get("type", "")) != "action_resolved":
		return
	var actor := str(event.get("actor", ""))
	var actor_token: BattleToken = _tokens.get(actor)
	if actor_token != null:
		actor_token.play_animation("attack")
	for result in event.get("results", []):
		var target := str(result.get("target", ""))
		var token: BattleToken = _tokens.get(target)
		if token == null:
			continue
		if result.has("damage"):
			if bool(result.get("down", false)):
				token.play_animation("dead")
			else:
				token.play_animation("hurt")
		elif bool(result.get("revived", false)):
			token.play_animation("revive")


# --- Parts --------------------------------------------------------------------

func _build_region(view: Dictionary) -> void:
	var phase := str(view.get("phase", ""))
	var total := int(view.get("layers_total", 5))
	var encounter = view.get("encounter")
	_region.text = "%s (%d/%d)" % [UiText.region_of(view), int(view.get("layer", 0)), total]
	var sub := "\"%s\"" % _encounter_title(view)
	if _combat.get("trial", false):
		sub = "Challenge  %d/%d" % [int(_combat.get("round", 1)), int(_combat.get("round_limit", 3))]
	_region_sub.text = sub
	_region.tooltip_text = sub.replace("\n", " - ")


func _encounter_title(view: Dictionary) -> String:
	var encounter: Dictionary = view.get("encounter", {}) if view.get("encounter") != null else {}
	var title := str(encounter.get("name", encounter.get("title", "Encounter")))
	if encounter.get("kind", "") == "boss":
		var boss: Dictionary = encounter.get("boss", {})
		title = str(boss.get("name", boss.get("title", "Guardian")))
	return title.replace("\"", "")


func _build_header(view: Dictionary) -> void:
	UiKit.clear(_header)
	var encounter: Dictionary = view.get("encounter", {}) if view.get("encounter") != null else {}
	if encounter.get("kind") == "boss":
		var boss: Dictionary = encounter["boss"]
		var head := UiKit.vbox(2)
		head.add_child(_centered(UiKit.pixel_label("Phase %d/%d: %s" % [int(boss["phase"]), int(boss["phases_total"]),
				boss["phase_name"]], "small", UiKit.WARN)))
		_header.add_child(UiKit.panel(head, "HudPanel"))
		var telegraph: Dictionary = boss.get("telegraph", {})
		if not telegraph.is_empty():
			var box := UiKit.vbox(2)
			var target := "the whole Party" if telegraph["target"] == "all" else _screen.name_of(str(telegraph["target"]))
			box.add_child(UiKit.para("WARNING: %s next turn, aimed at %s!" % [telegraph["name"], target], "body", UiKit.WARN))
			var advice := "Guard to halve it"
			advice += ", or raise Shield Wall." if telegraph["target"] == "all" else ", or have a Guardian Protect them."
			box.add_child(UiKit.para(advice, "small"))
			_header.add_child(UiKit.panel(box, "HudWarnPanel"))
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
	var remaining: Array = _combat.get("turn_order", [])
	var actor := str(_combat.get("actor", ""))
	_turn_banner.get_child(0).text = "Turn %d" % int(_combat.get("round", 1))
	for character in view.get("party", []):
		var id := "p%d" % int(character.get("slot", 0))
		var unit := _unit(view, str(id))
		if unit.is_empty():
			continue
		var entry := UiKit.hbox(5)
		entry.custom_minimum_size = Vector2(208, 60)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(38, 38)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.size = Vector2(38, 38)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if str(id).begins_with("p"):
			portrait.texture = SpriteSet.portrait(str(unit.get("class", "classless")))
		else:
			continue
		entry.add_child(portrait)
		var details := UiKit.vbox(1)
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var acted := not remaining.has(id)
		var is_actor: bool = id == actor
		var tag := _controller_tag(str(id), unit)
		var color := UiKit.ACCENT if is_actor else (UiKit.TEXT_DIM if acted else UiKit.TEXT)
		var name_label := UiKit.pixel_label(("> " if is_actor else "") + "%s  Lv %d - %s" % [
				_screen.name_of(str(id)), int(unit.get("level", 1)), tag[0]], "tiny", color)
		name_label.clip_text = true
		details.add_child(name_label)
		var hp := int(unit.get("hp", 0))
		var hp_bar := UiKit.stat_bar(hp, int(unit.get("max_hp", 1)), UiKit.BAR_HP,
				"DOWN" if hp <= 0 else "%d/%d" % [hp, int(unit.get("max_hp", 1))], 16, "tiny")
		details.add_child(hp_bar)
		if unit.has("energy"):
			var energy_bar := UiKit.stat_bar(int(unit["energy"]), int(unit.get("energy_max", 6)), UiKit.BAR_ENERGY,
				"%d/%d" % [int(unit["energy"]), int(unit.get("energy_max", 6))], 12, "tiny")
			details.add_child(energy_bar)
		entry.add_child(details)
		var card := UiKit.panel(entry, "OrnamentHighlightPanel" if is_actor else "HudPanel")
		card.add_theme_stylebox_override("panel", UiKit.flat_box(UiKit.HUD_BG, UiKit.GOLD if is_actor else UiKit.HUD_BORDER,
				2 if is_actor else 1, 5))
		card.set_meta("actor_id", str(id))
		card.modulate = Color(0.55, 0.55, 0.55, 0.85) if hp <= 0 else Color.WHITE
		card.tooltip_text = "%s (%s) - %s - Speed %d - HP %d/%d%s%s" % [tag[0], _screen.name_of(str(id)), tag[2],
				int(unit.get("spd", 0)), hp, int(unit.get("max_hp", 1)),
				(", Energy %d/%d" % [int(unit["energy"]), int(unit.get("energy_max", 6))]) if unit.has("energy") else "",
				" (already acted this round)" if acted else (" - acting now" if is_actor else "")]
		_timeline.add_child(card)
		if is_actor and actor != _last_actor:
			_app.fade_in(card, 0.3)
	_last_actor = actor
	_build_enemy_plates(view)
	# Layout is resolved at the end of the frame; scroll only after the new
	# cards have their final sizes (including the selected text scale).
	if is_inside_tree():
		call_deferred("_show_current_actor")


func _show_current_actor() -> void:
	if not is_instance_valid(_timeline_scroll):
		return
	var actor := str(_combat.get("actor", ""))
	for card in _timeline.get_children():
		if card.get_meta("actor_id", "") == actor:
			_timeline_scroll.ensure_control_visible(card)
			return


func _build_enemy_plates(view: Dictionary) -> void:
	for child in _enemy_plates.get_children():
		child.queue_free()
	var enemies: Array = _combat.get("enemies", [])
	if enemies.is_empty():
		return
	var is_boss := str(view.get("encounter", {}).get("kind", "")) == "boss"
	var columns := 1 if is_boss else mini(enemies.size(), 3)
	var width := 244.0 if not is_boss else 360.0
	var gap := 12.0
	var total := columns * width + (columns - 1) * gap
	var left := 760.0 if is_boss else (1280.0 - total) * 0.5
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		var row := UiKit.hbox(8)
		row.custom_minimum_size = Vector2(width - 20, 58)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(54, 54)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var path := "res://assets/enemies/%s/portrait.png" % str(enemy.get("sprite", ""))
		if ResourceLoader.exists(path):
			portrait.texture = load(path)
		row.add_child(portrait)
		var info := UiKit.vbox(2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name := UiKit.pixel_label("%s   Lv %d" % [_screen.name_of(str(enemy["id"])), int(enemy.get("level", 1))], "small")
		name.clip_text = true
		info.add_child(name)
		var hp := int(enemy.get("hp", 0))
		var max_hp := int(enemy.get("max_hp", 1))
		info.add_child(UiKit.stat_bar(hp, max_hp, UiKit.BAR_HP, "%d/%d" % [hp, max_hp], 18, "tiny"))
		if enemy.has("energy"):
			info.add_child(UiKit.stat_bar(int(enemy["energy"]), int(enemy.get("energy_max", 4)), UiKit.BAR_ENERGY,
					"%d/%d" % [int(enemy["energy"]), int(enemy.get("energy_max", 4))], 14, "tiny"))
		row.add_child(info)
		var plate := UiKit.panel(row, "HudHighlightPanel" if str(enemy["id"]) in _current_targets() else "HudPanel")
		plate.position = Vector2(left + (i if not is_boss else 0) * (width + gap), 119)
		plate.custom_minimum_size = Vector2(width, 76)
		plate.tooltip_text = str(enemy.get("description", ""))
		_enemy_plates.add_child(plate)


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
	_previous_tokens = _tokens.duplicate()
	_spots.clear()
	var statuses: Dictionary = _combat.get("statuses", {})
	var party: Array = view.get("party", [])
	## Fixed slots are expressed in the 1280x720 design coordinate system.
	## Add the back row last so it is painted on top of the front row.
	var party_front: Array = party.filter(func(c): return int(c.get("slot", 0)) < 3)
	var party_back: Array = party.filter(func(c): return int(c.get("slot", 0)) >= 3)
	for group in [party_front, party_back]:
		for character in group:
			var slot := int(character["slot"])
			var id := "p%d" % slot
			var data := {
				"id": id, "side": "party", "name": character["name"], "kind": character["class"],
				"hp": character["hp"], "max_hp": character["max_hp"],
				"energy": character.get("energy", 0), "energy_max": character.get("energy_max", 6),
				"statuses": statuses.get(id, []), "acting": _combat.get("actor", "") == id,
				"controller": character["controller"], "you": id == _me,
				"reduced_motion": _app.settings.reduced_motion, "show_plate": false,
				"tooltip": "%s - Lv %d %s\nATK %d  DEF %d  MAG %d  RES %d  SPD %d" % [character["name"],
						int(character["level"]), character["class_name"], int(character["atk"]), int(character["def"]),
						int(character["mag"]), int(character["res"]), int(character["spd"])],
			}
			var px: float = [340.0, 500.0, 660.0][slot] if slot < 3 else [420.0, 580.0][slot - 3]
			var py: float = (205.0 if slot < 3 else 265.0) if _screen.combat_mode in ["skills", "items"] else (300.0 if slot < 3 else 480.0)
			_spots[id] = [px / 1280.0, py / 720.0]
			_add_token(data)
	var enemies: Array = _combat.get("enemies", [])
	var fronts: Array = enemies.filter(func(e): return e["row"] == "front")
	var backs: Array = enemies.filter(func(e): return e["row"] != "front")
	var boss: bool = view.get("encounter") != null and view["encounter"].get("kind") == "boss"
	for group in [[fronts, [800.0, 960.0, 1120.0], 300.0], [backs, [880.0, 1040.0], 480.0]]:
		var list: Array = group[0]
		for i in list.size():
			var enemy: Dictionary = list[i]
			var id := str(enemy["id"])
			var weakness: Array = enemy.get("weakness", [])
			var sprite_name := str(enemy.get("sprite", ""))
			var data := {
				"id": id, "side": "boss" if boss else "enemy", "name": _screen.name_of(id), "kind": enemy["kind"],
				"hp": enemy["hp"], "max_hp": enemy["max_hp"],
				"energy": enemy["energy"] if enemy.has("energy") else null,
				"energy_max": enemy.get("energy_max", 4), "statuses": statuses.get(id, enemy.get("statuses", [])),
				"acting": _combat.get("actor", "") == id,
				"sprite": sprite_name, "sprite_variant": enemy.get("sprite_variant", ""), "show_plate": false,
				"tooltip": "%s\n%s%s" % [_screen.name_of(id), enemy.get("description", ""),
						("\nWeak to: " + ", ".join(weakness)) if not weakness.is_empty() else ""],
		}
			if not enemy.has("energy"):
				data.erase("energy")
			var ex := 960.0 if boss else float(group[1][i])
			var ey := (255.0 if _screen.combat_mode in ["skills", "items"] else 440.0) if boss else (265.0 if _screen.combat_mode in ["skills", "items"] and float(group[2]) > 400.0 else (205.0 if _screen.combat_mode in ["skills", "items"] else float(group[2])))
			_spots[id] = [ex / 1280.0, ey / 720.0]
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
	for id in _tokens.keys():
		if not _spots.has(id):
			var stale: BattleToken = _tokens[id]
			_stage.remove_child(stale)
			stale.queue_free()
			_tokens.erase(id)
	_place_tokens()
	_previous_tokens.clear()


func _add_token(data: Dictionary) -> void:
	var id := str(data["id"])
	var token: BattleToken = _tokens.get(id)
	if token == null or not is_instance_valid(token):
		token = BattleToken.new()
		token.text_scale = _app.settings.text_scale
		token.setup(data)
		_stage.add_child(token)
		_tokens[id] = token
	else:
		token.update_data(data)
	_screen.anchors[data["id"]] = token


func _place_tokens() -> void:
	var area := _stage.size
	for id in _tokens:
		var token: BattleToken = _tokens[id]
		var spot: Array = _spots.get(id, [0.5, 0.3])
		var feet_offset := float(token.badge_height + token.figure_height - 6.0)
		token.position = Vector2(area.x * float(spot[0]) - token.size.x * 0.5, area.y * float(spot[1]) - feet_offset)


func _build_bottom(view: Dictionary) -> void:
	UiKit.clear(_bottom)
	if _combat_grid != null and is_instance_valid(_combat_grid):
		_combat_grid.queue_free()
	_combat_grid = null
	_countdown = null
	if _skill_marks != null and is_instance_valid(_skill_marks):
		_skill_marks.queue_free()
	_skill_marks = null
	var me := _unit(view, _me)
	var mode := _screen.combat_mode
	var your_turn: bool = _combat.get("your_turn", false) and str(_combat.get("result", "")).is_empty()
	var choices: Dictionary = _combat.get("choices", {})
	_turn_notice.visible = not (your_turn and not mode.is_empty())
	if your_turn and mode in ["skills", "items"]:
		_combat_grid = _card_grid(mode, choices)
		_combat_grid.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_combat_grid.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_combat_grid.offset_left = -295
		_combat_grid.offset_right = 435
		_combat_grid.offset_top = 410
		_combat_grid.custom_minimum_size = Vector2(730, 0)
		_combat_grid.visible = not _banner.visible
		_combat_grid.z_index = 5
		add_child(_combat_grid)
	elif your_turn and not mode.is_empty():
		var caption := UiKit.pixel_label("Choose a target on the field (1-%d), Esc to go back" % _choices.size(), "small", UiKit.ACCENT)
		caption.add_theme_color_override("font_outline_color", Color.BLACK)
		caption.add_theme_constant_override("outline_size", 5)
		_bottom.add_child(_centered(caption))

	var hud := UiKit.hbox(12)
	hud.custom_minimum_size = Vector2(0, 104)
	var info := UiKit.hbox(6)
	info.custom_minimum_size = Vector2(390, 0)
	if not me.is_empty():
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(68, 68)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.texture = SpriteSet.portrait(str(me.get("class", "classless")))
		info.add_child(portrait)
		var details := UiKit.vbox(3)
		details.custom_minimum_size = Vector2(150, 0)
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var identity := UiKit.pixel_label(str(me.get("name", "")), "heading")
		identity.custom_minimum_size = Vector2(150, int(30 * _app.settings.text_scale))
		details.add_child(identity)
		details.add_child(UiKit.pixel_label("%s - Lv %d" % [me.get("class_name", ""), int(me.get("level", 1))], "small"))

		_countdown = UiKit.number_label("", "body")
		details.add_child(_countdown)
		var gold := int(me.get("gold", view.get("gold", 0)))
		details.add_child(Icons.with_text("gold", UiText.gold(gold), "small", _app.settings.text_scale, UiKit.ACCENT))
		info.add_child(details)
		var bars := UiKit.vbox(4)
		bars.custom_minimum_size = Vector2(200, 0)
		var hp := UiKit.stat_bar(int(me["hp"]), int(me["max_hp"]), UiKit.BAR_HP, "%d/%d" % [int(me["hp"]), int(me["max_hp"])], 26, "small")
		hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bars.add_child(hp)
		var energy := UiKit.stat_bar(int(me.get("energy", 0)), int(me.get("energy_max", 6)), UiKit.BAR_ENERGY,
				"%d/%d" % [int(me.get("energy", 0)), int(me.get("energy_max", 6))], 20, "small")
		energy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		energy.tooltip_text = "Energy pays for Skills. You start each Combat with 1 and regain 1 every later turn (max 6)."
		bars.add_child(energy)
		info.add_child(bars)
	else:
		_countdown = UiKit.number_label("", "heading")
		info.add_child(_countdown)
	hud.add_child(info)
	if your_turn:
		var actions := UiKit.hbox(8)
		actions.set_meta("combat_action_row", true)
		actions.custom_minimum_size = Vector2(0, 84)
		var has_skills: bool = not choices.get("skills", {}).is_empty()
		var fight := _action_button("Fight", "fight", func() -> void: _set_mode("skills"), mode == "skills" or mode == "attack" or mode.begins_with("skill:"))
		fight.tooltip_text = "Fight [F]"
		Icons.apply_to_button(fight, "fight", _app.settings.text_scale)
		actions.add_child(fight)
		var item := _action_button("Items", "items", func() -> void: _set_mode("items"), mode == "items" or mode.begins_with("item:"))
		item.tooltip_text = "Items [I]"
		Icons.apply_to_button(item, "items", _app.settings.text_scale)
		UiKit.disable(item, choices.get("items", {}).is_empty(), UiText.WHY["no_items"])
		actions.add_child(item)
		var focus := _action_button("Focus", "focus", func() -> void: _send({"action": "focus"}), false)
		Icons.apply_to_button(focus, "focus", _app.settings.text_scale)
		focus.disabled = not choices.get("focus", false)
		focus.tooltip_text = UiText.WHY["focus_unavailable"] if focus.disabled else UiText.WHY["focus_ready"]
		focus.tooltip_text += " [O]"
		actions.add_child(focus)
		for button in actions.get_children():
			button.custom_minimum_size = Vector2(0, 80)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hud.add_child(actions)
		_app.hint("combat_story" if _deadline == null or float(_deadline) < 0.0 else "combat")
		if has_skills:
			_app.hint("energy")
	else:
		# The non-actor HUD is intentionally only the compact header and bars.
		# Waiting text belongs in the event log, not in the bottom action area.
		pass
	if not _combat.get("statuses", {}).is_empty():
		_app.hint("dot")
	var row := UiKit.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var hud_panel := UiKit.panel(hud, "OrnamentPanel")
	hud_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hud_panel)
	if your_turn and not choices.get("skills", {}).is_empty():
		var squares := UiKit.hbox(4)
		squares.size_flags_vertical = Control.SIZE_SHRINK_END
		var text_scale: float = _app.settings.text_scale
		var hourglass := UiKit.panel(UiKit.pixel_label("Turn", "small", UiKit.TEXT_DIM), "HudPanel")
		hourglass.custom_minimum_size = Vector2(56 * text_scale, 42 * text_scale)
		hourglass.tooltip_text = UiText.LABELS["action_window"]
		squares.add_child(hourglass)
		for skill_id in choices["skills"]:
			var info_skill: Dictionary = choices["skills"][skill_id]
			var left := int(info_skill["cooldown"])
			var mark := UiKit.vbox(0)
			var initial := UiKit.pixel_label(str(info_skill["name"]).substr(0, 1), "small", UiKit.TEXT_DIM)
			initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mark.add_child(initial)
			var affordable := bool(info_skill.get("affordable", true))
			var state := "Ready"
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
			square.custom_minimum_size = Vector2(38 * text_scale, 42 * text_scale)
			var why := "Ready to use"
			if left > 0:
				why = "%d turn(s) of cooldown left" % left
			elif not affordable:
				why = "needs %d Energy" % int(info_skill.get("energy", 0))
			square.tooltip_text = "%s: %s" % [info_skill["name"], why]
			squares.add_child(square)
		_skill_marks = Control.new()
		_skill_marks.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		_skill_marks.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_skill_marks.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_skill_marks.offset_left = -20 - squares.get_combined_minimum_size().x
		_skill_marks.offset_right = -20
		_skill_marks.offset_top = -262
		_skill_marks.offset_bottom = -220
		_skill_marks.add_child(squares)
		squares.set_anchors_preset(Control.PRESET_FULL_RECT)
		squares.alignment = BoxContainer.ALIGNMENT_END
		add_child(_skill_marks)
	_bottom.add_child(row)


## Grid of cards for Skills (with Attack and Defend first, like the
## reference's Strike and Guard) or Items (05).
func _card_grid(mode: String, choices: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	if mode == "skills":
		grid.add_child(_card("Strike", "Cost: 0 | Cooldown: 0", "strike", 0, true,
				"A basic attack.", func() -> void: _set_mode("attack")))
		grid.add_child(_card("Guard", "Cost: 0 | Cooldown: 0", "guard", 0, true,
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
			grid.add_child(_card(str(info["name"]), sub, "skill", int(info.get("energy", 0)), usable, tip, pick))
	else:
		for item_id in choices.get("items", {}):
			var info: Dictionary = choices["items"][item_id]
			var usable: bool = not info["targets"].is_empty()
			var pretty := UiText.item_name(str(item_id))
			var description := _item_description(item_id)
			var pick := func() -> void: _pick_item(item_id, info)
			grid.add_child(_card(pretty, "x%d | %s" % [int(info["count"]), description], "items",
					-1, usable, description, pick, true))
	var holder := UiKit.panel(grid, "HudPanel")
	return _centered(holder)


func _card(title: String, sub: String, icon_name: String, energy_cost: int, usable: bool, tip: String, pick: Callable,
		wrap_sub: bool = false) -> Button:
	var number := _choices.size() + 1
	var button := Button.new()
	button.theme_type_variation = "HudButton"
	button.custom_minimum_size = Vector2(232, 96 if wrap_sub else 50)
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
	var card_icon := Icons.rect(icon_name, Icons.size_for_scale(_app.settings.text_scale))
	var icon_box := UiKit.panel(card_icon, "IconPanel")
	icon_box.custom_minimum_size = Vector2(40, 40)
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_box)
	var text := UiKit.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if wrap_sub:
		text.custom_minimum_size.x = 150
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := UiKit.pixel_label("[%d] %s" % [number, title], "small" if wrap_sub else "body",
			UiKit.TEXT if usable else UiKit.TEXT_DIM)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap_sub else TextServer.AUTOWRAP_OFF
	name_label.clip_text = not wrap_sub
	text.add_child(name_label)
	var sub_row := UiKit.hbox(4)
	sub_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if wrap_sub:
		sub_row.custom_minimum_size.x = 150
	if energy_cost >= 0:
		sub_row.add_child(Icons.rect("energy", Icons.size_for_scale(_app.settings.text_scale)))
	var sub_label := UiKit.pixel_label(sub, "tiny", UiKit.TEXT_DIM)
	sub_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if wrap_sub:
		sub_label.custom_minimum_size.x = 150
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap_sub else TextServer.AUTOWRAP_OFF
	sub_label.clip_text = not wrap_sub
	sub_row.add_child(sub_label)
	text.add_child(sub_row)
	row.add_child(text)
	button.add_child(row)
	_choices.append(pick if usable else func() -> void: _app.toast(tip.get_slice("\n", 0)))
	return button


func _build_result() -> void:
	UiKit.clear(_rewards)
	var outcome := str(_combat.get("result", ""))
	_center_text.text = ""
	# Turn order is irrelevant after the fight and can crowd longer reward lists.
	_timeline.visible = outcome.is_empty()
	if not outcome.is_empty():
		_turn_notice.visible = false
		if _banner_tween != null:
			_banner_tween.kill()
		_banner.visible = false
	match outcome:
		"victory":
			_center_text.text = "Challenge won!" if _combat.get("trial", false) else "Victory!"
			_center_text.add_theme_color_override("font_color", UiKit.GOOD)
			var rewards: Dictionary = _combat.get("rewards", {})
			if not _combat.get("trial", false) and not rewards.is_empty():
				for item in rewards.get("items", {}):
					_rewards.add_child(_reward_line("%s%s" % [UiText.item_name(str(item)),
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
	var line := UiKit.pixel_label(text, "small", color)
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
	if not mode.is_empty() and _banner.visible:
		if _banner_tween != null:
			_banner_tween.kill()
		_banner.visible = false
	_screen.combat_mode = mode
	refresh_action_panel()


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
