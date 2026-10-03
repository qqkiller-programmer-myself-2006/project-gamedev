class_name BattleHud3D
extends Control

const COMMANDS := ["Strike", "Skill", "Focus", "Item", "Guard"]
const ICONS := ["strike", "skill", "focus", "items", "guard"]
const KEYS := ["A", "S", "O", "I", "D"]
const FAN_OFFSETS := [Vector2(-350, -80), Vector2(-175, -115), Vector2(0, -130), Vector2(175, -115), Vector2(350, -80)]

class SlantedShape extends Polygon2D:
	var edge_color := UiKit.BATTLE_WHITE
	var edge_width := 2.0

	func _draw() -> void:
		var points := polygon.duplicate()
		points.append(polygon[0])
		draw_polyline(points, edge_color, edge_width, true)

class SlantedPanel extends PanelContainer:
	var fill_color := UiKit.BATTLE_DARK
	var edge_color := UiKit.BATTLE_WHITE
	var edge_width := 1.0

	func _draw() -> void:
		var cut := minf(18.0, size.x * 0.1)
		var points := PackedVector2Array([Vector2(cut, 0), Vector2(size.x, 0), Vector2(size.x - cut, size.y), Vector2(0, size.y)])
		draw_colored_polygon(points, fill_color)
		for index in points.size():
			draw_line(points[index], points[(index + 1) % points.size()], edge_color, edge_width, true)

	func set_colors(fill: Color, edge: Color, width: float = 1.0) -> void:
		fill_color = fill
		edge_color = edge
		edge_width = width
		queue_redraw()

var _fan: Array[Button] = []
var _fan_backgrounds: Array[SlantedShape] = []
var _origin := Vector2(420, 520)
var _scale := 1.0
var _selected_command := -1
var _countdown: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func render(view: Dictionary, combat: Dictionary, party: Array, mode: String, targets: Array,
		selected_target: String, countdown_text: String, text_scale: float, callbacks: Dictionary) -> void:
	_scale = text_scale
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_fan.clear()
	_fan_backgrounds.clear()
	_build_turn_order(combat, view, text_scale)
	_build_target_banner(combat, targets, selected_target, text_scale)
	_build_party_plates(party, str(combat.get("actor", "")), text_scale)
	_build_command_fan(combat, mode, text_scale, callbacks)
	_build_description(mode, text_scale)
	_build_auto_placeholder(text_scale)
	_build_countdown(countdown_text, text_scale)
	set_command_origin(_origin)


func set_command_origin(origin: Vector2) -> void:
	_origin = origin
	if _fan.is_empty():
		return
	for index in _fan.size():
		var button := _fan[index]
		var button_size := button.custom_minimum_size
		var point: Vector2 = origin + FAN_OFFSETS[index] * _scale
		if index == _selected_command:
			point += Vector2(-6, -8) * _scale
		point.x = clampf(point.x, 12.0, maxf(12.0, size.x - button_size.x - 12.0))
		point.y = clampf(point.y, 92.0, maxf(92.0, size.y - button_size.y - 156.0))
		button.position = point
		_fan_backgrounds[index].position = point


func set_countdown(text: String, urgent: bool) -> void:
	if not is_instance_valid(_countdown):
		return
	_countdown.text = text
	_countdown.add_theme_color_override("font_color", UiKit.BATTLE_RED if urgent else UiKit.BATTLE_WHITE)


func focus_first_command() -> void:
	for button in _fan:
		if not button.disabled:
			button.grab_focus()
			return


func _build_command_fan(combat: Dictionary, mode: String, text_scale: float, callbacks: Dictionary) -> void:
	var choices: Dictionary = combat.get("choices", {})
	var active_turn := bool(combat.get("your_turn", false)) and str(combat.get("result", "")).is_empty()
	var enabled := [not choices.get("attack", {}).get("targets", []).is_empty(),
		not choices.get("skills", {}).is_empty(), bool(choices.get("focus", false)),
		not choices.get("items", {}).is_empty(), true]
	var callback_names := ["strike", "skill", "focus", "item", "guard"]
	var backgrounds: Array[SlantedShape] = []
	for index in COMMANDS.size():
		var button := Button.new()
		button.text = "%s  [%s]" % [_command_label(index), KEYS[index]]
		button.theme_type_variation = "HudButton"
		button.focus_mode = Control.FOCUS_ALL
		var selected := _is_selected(index, mode)
		button.custom_minimum_size = Vector2((154 if selected else (146 if index == 1 else 132)) * text_scale,
			(58 if selected else 50) * text_scale)
		button.icon = Icons.texture(ICONS[index])
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", Icons.size_for_scale(text_scale))
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.tooltip_text = _command_description(index)
		button.disabled = not active_turn or not enabled[index]
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		button.add_theme_color_override("font_color", UiKit.BATTLE_WHITE)
		button.add_theme_color_override("font_disabled_color", UiKit.TEXT_DIM)
		var background := SlantedShape.new()
		background.color = UiKit.BATTLE_RED if selected else UiKit.BATTLE_DARK
		background.edge_color = UiKit.BATTLE_RED if selected else UiKit.BATTLE_WHITE
		background.edge_width = 3.0 if selected else 2.0
		background.z_index = 0
		var cut := minf(16.0, button.custom_minimum_size.x * 0.12)
		background.polygon = PackedVector2Array([Vector2(cut, 0), Vector2(button.custom_minimum_size.x, 0),
			Vector2(button.custom_minimum_size.x - cut, button.custom_minimum_size.y), Vector2(0, button.custom_minimum_size.y)])
		backgrounds.append(background)
		if not enabled[index]:
			button.tooltip_text += "\n" + Tr.t("battle_hud_command_unavailable")
		var callback: Callable = callbacks.get(callback_names[index], Callable())
		if callback.is_valid():
			button.pressed.connect(callback)
		_fan.append(button)
		_fan_backgrounds.append(background)
	for background in backgrounds:
		add_child(background)
	for button in _fan:
		button.z_index = 1
		add_child(button)
	_selected_command = -1
	for index in COMMANDS.size():
		if _is_selected(index, mode):
			_selected_command = index
			break
	set_command_origin(_origin)


func _is_selected(index: int, mode: String) -> bool:
	return (index == 0 and (mode.is_empty() or mode == "attack")) or (index == 1 and (mode == "skills" or mode.begins_with("skill:"))) \
		or (index == 2 and mode == "focus") or (index == 3 and (mode == "items" or mode.begins_with("item:"))) \
		or (index == 4 and mode == "guard")


func _build_description(mode: String, text_scale: float) -> void:
	var command_index := 0
	if mode == "skills" or mode.begins_with("skill:"):
		command_index = 1
	elif mode == "focus":
		command_index = 2
	elif mode == "items" or mode.begins_with("item:"):
		command_index = 3
	elif mode == "guard":
		command_index = 4
	var label := UiKit.pixel_label(_command_description(command_index), "small", UiKit.BATTLE_WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_left = 260
	label.offset_right = -260
	label.offset_bottom = -148 * text_scale
	label.offset_top = -194 * text_scale
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func _command_description(index: int) -> String:
	match index:
		0: return Tr.t("battle_hud_strike_description")
		1: return Tr.t("battle_hud_skill_description")
		2: return Tr.t("battle_hud_focus_description")
		3: return Tr.t("battle_hud_item_description")
		4: return Tr.t("battle_hud_guard_description")
		_: return ""


func _command_label(index: int) -> String:
	match index:
		0: return Tr.t("Strike")
		1: return Tr.t("Skill")
		2: return Tr.t("Focus")
		3: return Tr.t("Item")
		4: return Tr.t("Guard")
		_: return ""


func _build_turn_order(combat: Dictionary, view: Dictionary, text_scale: float) -> void:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 4)
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 390
	row.offset_top = 82
	row.offset_right = -200
	var units := {}
	for member in view.get("party", []):
		units["p%d" % int(member.get("slot", 0))] = member
	for enemy in combat.get("enemies", []):
		units[str(enemy.get("id", ""))] = enemy
	var ordered_ids: Array[String] = []
	for id_value in combat.get("turn_order", []):
		var ordered_id := str(id_value)
		if units.has(ordered_id) and not ordered_ids.has(ordered_id):
			ordered_ids.append(ordered_id)
	for id_value in units.keys():
		var missing_id := str(id_value)
		if not ordered_ids.has(missing_id):
			ordered_ids.append(missing_id)
	for id_value in ordered_ids:
		var id := str(id_value)
		var unit: Dictionary = units.get(id, {})
		if unit.is_empty():
			continue
		var actor := id == str(combat.get("actor", ""))
		var chip := _slanted_panel(UiKit.pixel_label(str(unit.get("name", id)), "small", UiKit.BATTLE_WHITE if actor else UiKit.TEXT_DIM),
			UiKit.BATTLE_DARK, UiKit.BATTLE_RED if actor else UiKit.BATTLE_WHITE, 2.0 if actor else 1.0)
		chip.custom_minimum_size = Vector2(88 * text_scale, 38 * text_scale)
		chip.tooltip_text = str(unit.get("name", id))
		row.add_child(chip)
	add_child(row)


func _build_target_banner(combat: Dictionary, targets: Array, selected_target: String, text_scale: float) -> void:
	var chosen := selected_target if targets.has(selected_target) else ""
	if chosen.is_empty():
		for enemy in combat.get("enemies", []):
			if int(enemy.get("hp", 0)) > 0:
				chosen = str(enemy.get("id", ""))
				break
	if chosen.is_empty():
		return
	for candidate in combat.get("enemies", []):
		if str(candidate.get("id", "")) != chosen:
			continue
		var contents := UiKit.vbox(3)
		var target_index := targets.find(chosen)
		var target_label := "%s [%d]" % [Tr.t("Target"), target_index + 1] if target_index >= 0 else Tr.t("Target")
		contents.add_child(UiKit.pixel_label(target_label, "small", UiKit.BATTLE_RED))
		contents.add_child(UiKit.pixel_label(str(candidate.get("name", chosen)), "body", UiKit.BATTLE_WHITE))
		var hp := int(candidate.get("hp", 0))
		var max_hp := int(candidate.get("max_hp", 1))
		contents.add_child(UiKit.stat_bar(hp, max_hp, UiKit.BATTLE_RED, "%d/%d" % [hp, max_hp], 18 * text_scale, "tiny"))
		var banner := _slanted_panel(contents, UiKit.BATTLE_DARK, UiKit.BATTLE_RED, 2.0)
		banner.set_anchors_preset(Control.PRESET_TOP_LEFT)
		banner.offset_left = 24
		banner.offset_top = 84
		banner.custom_minimum_size = Vector2(260 * text_scale, 90 * text_scale)
		add_child(banner)
		return


func _build_party_plates(party: Array, actor: String, text_scale: float) -> void:
	var row := UiKit.hbox(6)
	row.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_right = -22
	row.offset_bottom = -18
	for member in party:
		var id := "p%d" % int(member.get("slot", 0))
		var active := id == actor
		var entry := UiKit.vbox(2)
		var portrait := TextureRect.new()
		portrait.texture = SpriteSet.portrait(str(member.get("class", "classless")))
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(42 * text_scale, 42 * text_scale)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		entry.add_child(portrait)
		entry.add_child(UiKit.pixel_label(str(member.get("name", id)), "tiny", UiKit.BATTLE_WHITE))
		var hp := int(member.get("hp", 0))
		var hp_max := int(member.get("max_hp", 1))
		entry.add_child(UiKit.stat_bar(hp, hp_max, UiKit.BATTLE_RED, "%d/%d" % [hp, hp_max], 14 * text_scale, "tiny"))
		if member.has("energy"):
			var energy := int(member.get("energy", 0))
			var energy_max := int(member.get("energy_max", 6))
			entry.add_child(UiKit.stat_bar(energy, energy_max, UiKit.BATTLE_WHITE,
				"%d/%d" % [energy, energy_max], 12 * text_scale, "tiny"))
		var effects := PackedStringArray()
		for status in member.get("statuses", []):
			effects.append(Tr.t(str(status.get("name", status.get("status", status.get("id", ""))))) if status is Dictionary else Tr.t(str(status)))
		entry.add_child(UiKit.pixel_label(" · ".join(effects), "tiny", UiKit.BATTLE_RED if not effects.is_empty() else UiKit.TEXT_DIM))
		var plate := _slanted_panel(entry, UiKit.BATTLE_DARK,
			UiKit.BATTLE_RED if active else UiKit.BATTLE_WHITE, 2.0 if active else 1.0)
		plate.modulate.a = 0.48 if hp <= 0 else 1.0
		plate.custom_minimum_size = Vector2(138 * text_scale, 126 * text_scale)
		row.add_child(plate)
	add_child(row)


func _build_auto_placeholder(text_scale: float) -> void:
	var auto := Button.new()
	auto.text = Tr.t("Auto")
	auto.icon = Icons.texture("info")
	auto.disabled = true
	auto.tooltip_text = Tr.t("battle_hud_auto_unavailable")
	auto.theme_type_variation = "HudButton"
	auto.custom_minimum_size = Vector2(100 * text_scale, 40 * text_scale)
	auto.set_anchors_preset(Control.PRESET_TOP_LEFT)
	auto.offset_left = 170
	auto.offset_top = 20
	add_child(auto)


func _build_countdown(text: String, text_scale: float) -> void:
	_countdown = UiKit.number_label(text, "body", UiKit.BATTLE_WHITE)
	var panel := _slanted_panel(_countdown, UiKit.BATTLE_DARK, UiKit.BATTLE_RED, 2.0)
	panel.custom_minimum_size = Vector2(96 * text_scale, 44 * text_scale)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 24
	panel.offset_top = 20
	add_child(panel)


func _slanted_panel(content: Control, fill: Color, edge: Color, width: float = 1.0) -> SlantedPanel:
	var panel := SlantedPanel.new()
	panel.theme_type_variation = "HudPanel"
	panel.set_colors(fill, edge, width)
	panel.add_theme_stylebox_override("panel", UiKit.flat_box(Color(fill, 0.0), UiKit.CLEAR, 0, 6))
	panel.add_child(content)
	return panel
