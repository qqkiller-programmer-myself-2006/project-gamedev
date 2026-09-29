class_name CharacterSetup
extends Control
## Room-only character setup. All purchases and loadout changes go to the server.

class TreeLinks extends Control:
	func _draw() -> void:
		var ink := UiKit.TEXT_DIM
		var w := size.x / 3.0
		var h := size.y / 3.0
		for row in [0, 1]:
			draw_line(Vector2(w * 0.5, h * (row + 0.5)), Vector2(w * 2.5, h * (row + 0.5)), ink, 2)
		for column in [0, 2]:
			draw_line(Vector2(w * (column + 0.5), h * 0.5), Vector2(w * (column + 0.5), h * 1.5), ink, 2)
		draw_line(Vector2(w * 1.5, h * 1.5), Vector2(w * 1.5, h * 2.5), ink, 2)

class ClassMark extends Control:
	var class_id := "assassin"
	func _draw() -> void:
		var center := size * 0.5
		var pale := UiKit.TEXT
		var shadow := UiKit.BG
		if class_id == "guardian":
			var shield := PackedVector2Array([center + Vector2(-40, -46), center + Vector2(40, -46), center + Vector2(34, 16), center + Vector2(0, 54), center + Vector2(-34, 16)])
			draw_colored_polygon(shield, pale)
			draw_polyline(shield, shadow, 5)
			draw_line(center + Vector2(0, -32), center + Vector2(0, 28), shadow, 8)
			draw_line(center + Vector2(-24, -4), center + Vector2(24, -4), shadow, 8)
		else:
			var blade := PackedVector2Array([center + Vector2(0, -58), center + Vector2(16, -20), center + Vector2(10, 28), center + Vector2(-10, 28), center + Vector2(-16, -20)])
			draw_colored_polygon(blade, pale)
			draw_line(center + Vector2(-23, 30), center + Vector2(23, 30), pale, 9)
			draw_line(center + Vector2(0, 34), center + Vector2(0, 58), pale, 11)
			draw_circle(center + Vector2(0, 58), 7, shadow)

const NAV := ["Profile", "Races", "Class", "Boons", "Records"]
const ICONS := ["◆", "♜", "⚔", "✦", "♛"]
const CLASSES := ["swordsman", "archer", "mage", "guardian", "assassin"]
const RACE_ORDER := ["Elf", "Dwarf", "Kobold", "Lunaeia", "Withered", "Human"]
const TREE_ORDER := ["vitality", "might", "precision", "swiftness", "reserves", "mastery", "stat_points"]
const PASSIVES := {
	"adaptable": ["Adaptable", "+1 attribute point at every even level."],
	"versatile": ["Versatile", "+1 to every attribute."],
	"keen_eyes": ["Keen Eyes", "+5% critical chance."],
	"grace": ["Grace", "+2 DEX."],
	"scrappy": ["Scrappy", "+10% Gold from rewards."],
	"small_target": ["Small Target", "+5% Dodge."],
	"undying": ["Undying", "5% Lifesteal."],
	"frail": ["Frail", "−10% max HP."],
	"dwarven_resilience": ["Dwarven Resilience", "+10% max HP and +10% Status resistance."],
	"masterwork": ["Masterwork", "Crafted gear gains +0.75% stats per current level."],
	"moonlit": ["Moonlit", "+10% magic damage."],
	"tidal": ["Tidal", "+1 starting Energy in Combat."]
}
const BOON_EFFECTS := {
	"Potential: Bunny": "+3 Initiative and +15% Dodge.",
	"The Chosen One": "+2 to every attribute. Requires 5 total Prestige.",
	"Daredevil Impulse": "+25% damage while HP is 30% or lower.",
	"Critical Healing": "Critical hits heal you for 20% of damage dealt.",
	"Energy Conserver": "15% chance to gain one extra Energy at turn start.",
	"Enervation": "More direct damage per DoT type; stronger outgoing DoTs, but more incoming DoT damage.",
	"Alert": "+3 Initiative; +5% Block and Dodge for the first two turns.",
	"Will of Thiacdemo": "Once per Combat, survive a lethal hit at 1 HP."
}
const TREE_EFFECTS := {
	"vitality": "+2% max HP per level.",
	"might": "+2% direct damage per level.",
	"precision": "+1% critical chance per level.",
	"swiftness": "+1 Initiative per two levels.",
	"reserves": "+1 starting Energy at level 5.",
	"mastery": "Class Skill cooldown −1 at level 5.",
	"stat_points": "+1 starting attribute point per level."
}

var _app: ClientApp
var _finish: Callable
var _meta: Dictionary = {}
var _classes: Dictionary = {}
var _sprite_manifest: Dictionary = {}
var _tab := "Class"
var _class_id := "assassin"
var _race := "Human"
var _boons: Array = []
var _node := "stat_points"
var _selected_boon := ""
var _digest := ""
var _content: Control
var _gems_label: Label
var _search := ""
var _boon_details: VBoxContainer
var _tree_focus: Button


func setup(app: ClientApp, finish: Callable) -> void:
	_app = app
	_finish = finish
	var file := FileAccess.open("res://content/forest.json", FileAccess.READ)
	if file != null:
		var data: Dictionary = JSON.parse_string(file.get_as_text())
		_meta = data.get("meta", {})
		_classes = data.get("classes", {})
	var manifest_file := FileAccess.open("res://assets/heroes/manifest.json", FileAccess.READ)
	if manifest_file != null:
		_sprite_manifest = JSON.parse_string(manifest_file.get_as_text())
	var room: Dictionary = app.snapshot.get("room", {})
	for slot in room.get("slots", []):
		if slot.get("is_you", false):
			var loadout: Dictionary = slot.get("loadout", {})
			_class_id = str(loadout.get("class", "assassin"))
			_race = str(loadout.get("race", "Human"))
			_boons = loadout.get("boons", []).duplicate()
			break
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_shell()
	refresh(app, true)
	if _own_loadout().is_empty():
		_send_loadout()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiKit.BG)


func _build_shell() -> void:
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 14)
	nav.set_anchors_preset(Control.PRESET_TOP_WIDE)
	nav.offset_top = 24
	nav.offset_bottom = 92
	add_child(nav)
	for i in NAV.size():
		var tab_name: String = NAV[i]
		var button := Button.new()
		button.text = ICONS[i]
		button.custom_minimum_size = Vector2(72, 72)
		button.focus_mode = Control.FOCUS_ALL
		button.theme_type_variation = "TabButton"
		button.pressed.connect(func() -> void: _switch_tab(tab_name))
		button.set_meta("tab", tab_name)
		button.set_meta("focus_id", "tab_" + tab_name)
		button.tooltip_text = "%s [%d]" % [tab_name, i + 1]
		nav.add_child(button)
	_content = Control.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.offset_left = 20
	_content.offset_right = -20
	_content.offset_top = 118
	_content.offset_bottom = -88
	add_child(_content)
	var finish_button := UiKit.primary("Finish [Esc]", func() -> void: _finish.call())
	finish_button.set_meta("focus_id", "finish")
	finish_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	finish_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	finish_button.offset_left = -110
	finish_button.offset_right = 110
	finish_button.offset_top = -75
	finish_button.offset_bottom = -18
	add_child(finish_button)
	_gems_label = UiKit.pixel_label("◆ 0", "heading", UiKit.SUCCESS)
	_gems_label.tooltip_text = "Gems: spend them on Races, the Skill Tree and Prestige."
	_gems_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_gems_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_gems_label.position = Vector2(15, -45)
	_gems_label.size = Vector2(180, 38)
	add_child(_gems_label)


func refresh(app: ClientApp, force: bool = false) -> void:
	var room: Dictionary = app.snapshot.get("room", {})
	var digest := JSON.stringify(room)
	if digest == _digest and not force:
		return
	_digest = digest
	_gems_label.text = "◆ %d" % int(_profile().get("gems", 0))
	_render()


func _switch_tab(tab_name: String) -> void:
	_tab = tab_name
	_render()


func _render() -> void:
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var focus_id := str(focused.get_meta("focus_id", "")) if focused != null else ""
	UiKit.clear(_content)
	for button in get_children()[0].get_children():
		if button is Button:
			button.theme_type_variation = "TabButtonSelected" if button.get_meta("tab", "") == _tab else "TabButton"
	match _tab:
		"Class": _render_class()
		"Races": _render_races()
		"Boons": _render_boons()
		"Profile": _render_profile()
		"Records": _render_records()
	# Keep the keyboard focus where it was (a tab, a tree node, a Race...).
	if focus_id.is_empty() or not LobbyScreen._find_and_focus(self, focus_id):
		UiKit.focus_first(_content)


func _render_class() -> void:
	_tree_focus = null
	var row := UiKit.hbox(9)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.add_child(row)
	var left := _column_panel(row, 0.31, "Class")
	var left_scroll := _scroll(left)
	var portrait_host := UiKit.vbox(0)
	portrait_host.custom_minimum_size.x = 330
	left_scroll.add_child(portrait_host)
	var portrait_panel := _card(portrait_host, 0)
	portrait_panel.add_child(_center(str(_classes.get(_class_id, {}).get("name", _class_id.capitalize())), "title"))
	var portrait_path := "res://assets/heroes/%s/portrait.png" % _class_id
	if _sprite_manifest.has(_class_id) and ResourceLoader.exists(portrait_path):
		var portrait := TextureRect.new()
		portrait.texture = load(portrait_path)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size.y = 145
		portrait_panel.add_child(portrait)
	else:
		var icon := ClassMark.new()
		icon.class_id = _class_id
		icon.custom_minimum_size.y = 145
		portrait_panel.add_child(icon)
	var arrows := UiKit.hbox(8)
	var prev := _button("❮", func() -> void: _cycle_class(-1))
	prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arrows.add_child(prev)
	arrows.add_child(_center("● " if CLASSES.find(_class_id) == 0 else "○ ", "small"))
	for i in range(1, CLASSES.size()):
		arrows.add_child(UiKit.pixel_label("●" if i == CLASSES.find(_class_id) else "○", "small"))
	var next := _button("❯", func() -> void: _cycle_class(1))
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arrows.add_child(next)
	portrait_panel.add_child(arrows)
	var class_data: Dictionary = _classes.get(_class_id, {})
	portrait_panel.add_child(_text(str(class_data.get("description", ""))))
	portrait_panel.add_child(_text("Recommended Stats: %s" % "/".join(class_data.get("recommended_stats", []))))
	left.add_child(_button("Skill Tree", _focus_tree))
	var middle := _column_panel(row, 0.30)
	var node_data: Dictionary = _meta.get("class_tree", {}).get(_node, {})
	var level := _tree_level(_node)
	middle.add_child(_heading(_node.replace("_", " ").capitalize()))
	middle.add_child(UiKit.pixel_label("Level: %d/5" % level, "heading"))
	middle.add_child(_text(str(TREE_EFFECTS.get(_node, ""))))
	middle.add_child(_text("Cost: %s\nStatus: Unlocked" % ("MAX" if level >= 5 else str(int(node_data.get("cost", 10)) * (level + 1)))))
	middle.add_child(UiKit.spacer())
	var upgrade := UiKit.primary("Upgrade", func() -> void: _app.send({"type": "tree_upgrade", "class": _class_id, "node": _node}), false)
	var upgrade_cost := int(node_data.get("cost", 10)) * (level + 1)
	upgrade.set_meta("focus_id", "upgrade")
	if level >= 5:
		UiKit.disable(upgrade, true, UiText.WHY["max_level"])
	else:
		UiKit.disable(upgrade, _gems() < upgrade_cost, UiText.WHY["need_gems"] % [upgrade_cost, _gems()])
	middle.add_child(upgrade)
	var right := _column_panel(row, 0.39)
	var prestige := int(_profile().get("prestige", {}).get(_class_id, 0))
	right.add_child(_center("%s (%d)" % [_class_id.capitalize(), prestige], "title"))
	right.add_child(_center("Prestige: %d%s" % [prestige, " (MAX)" if prestige >= 25 else ""], "body"))
	var tree := Control.new()
	tree.custom_minimum_size.y = 274
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(tree)
	var lines := TreeLinks.new()
	lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tree.add_child(lines)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 13)
	grid.position = Vector2(65, 4)
	grid.size = Vector2(290, 270)
	tree.add_child(grid)
	for i in 9:
		if i == 6 or i == 8:
			var blank := Control.new()
			blank.custom_minimum_size = Vector2(82, 76)
			grid.add_child(blank)
			continue
		var node_id: String = TREE_ORDER[6] if i == 7 else TREE_ORDER[i]
		var node_button := _button("✦\n%d/5" % _tree_level(node_id), func() -> void: _node = node_id; _render())
		node_button.custom_minimum_size = Vector2(82, 76)
		node_button.tooltip_text = node_id.replace("_", " ").capitalize()
		node_button.set_meta("focus_id", "node_" + node_id)
		if node_id == _node:
			node_button.theme_type_variation = "SelectedButton"
			_tree_focus = node_button
		grid.add_child(node_button)
	right.add_child(UiKit.spacer())
	var actions := UiKit.hbox(8)
	var all_max := true
	for node_id in TREE_ORDER:
		if _tree_level(node_id) < 5:
			all_max = false
	var prestige_cost := int(_meta.get("prestige", {}).get("cost", 100))
	var buy := _button("Buy Prestige\n◆ %d" % prestige_cost, func() -> void: _app.send({"type": "buy_prestige", "class": _class_id}))
	if prestige >= 25:
		UiKit.disable(buy, true, UiText.WHY["prestige_max"])
	elif not all_max:
		UiKit.disable(buy, true, UiText.WHY["prestige_locked"])
	else:
		UiKit.disable(buy, _gems() < prestige_cost, UiText.WHY["need_gems"] % [prestige_cost, _gems()])
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(buy)
	var reset_cost := int(_meta.get("reset_cost", 50))
	var reset := UiKit.button("Reset Skills\n◆ %d" % reset_cost, func() -> void:
		_app.confirm("reset_skills", func() -> void: _app.send({"type": "reset_tree", "class": _class_id}),
				[_class_id.capitalize(), reset_cost]), false, "danger")
	reset.set_meta("focus_id", "reset")
	UiKit.disable(reset, _gems() < reset_cost, UiText.WHY["need_gems"] % [reset_cost, _gems()])
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(reset)
	right.add_child(actions)


func _render_races() -> void:
	var row := UiKit.hbox(16)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.add_child(row)
	var left := _column_panel(row, 0.28, "Races")
	var scroll := _scroll(left)
	var list := UiKit.vbox(8)
	list.custom_minimum_size.x = 300
	scroll.add_child(list)
	for race in RACE_ORDER:
		var cost := int(_meta.get("races", {}).get(race, {}).get("cost", 0))
		var owned: bool = _profile().get("races_owned", []).has(race)
		var button := _button("%s%s" % [race, "   ◆ %d" % cost if not owned else ""], func() -> void: _race = race; _render())
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", int(UiKit.SIZES["title"] * _app.settings.text_scale))
		button.custom_minimum_size.y = int(58 * _app.settings.text_scale)
		button.set_meta("focus_id", "race_" + race)
		if race == _race:
			button.theme_type_variation = "SelectedButton"
		elif not owned:
			button.add_theme_color_override("font_color", UiKit.TEXT_DIM)
		button.tooltip_text = "%s - owned" % race if owned else "%s - costs ◆ %d" % [race, cost]
		list.add_child(button)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	space.size_flags_stretch_ratio = 41.0
	row.add_child(space)
	var right := _column_panel(row, 0.31, "Description")
	var details := _scroll(right)
	var info := UiKit.vbox(12)
	info.custom_minimum_size.x = 320
	details.add_child(info)
	info.add_child(_center(_race, "title"))
	for passive in _meta.get("races", {}).get(_race, {}).get("passives", []):
		var entry: Array = PASSIVES.get(passive, [str(passive), ""])
		info.add_child(UiKit.pixel_label(str(entry[0]), "heading"))
		info.add_child(_text(str(entry[1])))
	var owned: bool = _profile().get("races_owned", []).has(_race)
	var race_cost := int(_meta.get("races", {}).get(_race, {}).get("cost", 0))
	var action := UiKit.primary("Select" if owned else "Purchase  ◆ %d" % race_cost, func() -> void:
		if owned:
			_send_loadout()
		else:
			_app.send({"type": "buy_race", "race": _race}), false)
	action.set_meta("focus_id", "race_action")
	UiKit.disable(action, not owned and _gems() < race_cost, UiText.WHY["need_gems"] % [race_cost, _gems()])
	right.add_child(action)


func _render_boons() -> void:
	var row := UiKit.hbox(0)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.add_child(row)
	var detail := _column_panel(row, 0.33)
	_boon_details = detail
	if _selected_boon.is_empty():
		_selected_boon = _boons[0] if not _boons.is_empty() else str(_meta.get("boons", {}).keys().front() if not _meta.get("boons", {}).is_empty() else "")
	_show_boon_details(_selected_boon)
	var middle := _column_panel(row, 0.34)
	var scroll := _scroll(middle)
	var list := UiKit.vbox(6)
	list.custom_minimum_size.x = 340
	scroll.add_child(list)
	for slots in range(5, 0, -1):
		list.add_child(_heading("Slots: %d" % slots))
		for boon in _meta.get("boons", {}):
			if int(_meta["boons"][boon].get("slots", 0)) != slots:
				continue
			var boon_name: String = boon
			var button := _button(boon_name, func() -> void: _select_boon(boon_name))
			button.set_meta("boon", boon_name)
			button.set_meta("focus_id", "boon_" + boon_name)
			button.add_theme_font_size_override("font_size", int(UiKit.SIZES["heading"] * _app.settings.text_scale))
			button.custom_minimum_size.y = int(46 * _app.settings.text_scale)
			button.visible = _search.is_empty() or boon_name.to_lower().contains(_search.to_lower())
			button.mouse_entered.connect(func() -> void: _show_boon_details(boon_name))
			button.focus_entered.connect(func() -> void: _show_boon_details(boon_name))
			button.tooltip_text = str(BOON_EFFECTS.get(boon_name, ""))
			if boon_name == "The Chosen One" and _prestige_total() < 5:
				button.disabled = true
				button.tooltip_text = "Requires 5 total Prestige."
			elif not _boons.has(boon_name) and _used_slots() + slots > 5:
				button.tooltip_text = "Not enough Boon slots: %d/5 used." % _used_slots()
			list.add_child(button)
	var search := LineEdit.new()
	search.placeholder_text = "Search..."
	search.text = _search
	search.text_changed.connect(func(value: String) -> void:
		_search = value
		for child in list.get_children():
			if child is Button:
				child.visible = value.is_empty() or str(child.get_meta("boon", "")).to_lower().contains(value.to_lower()))
	middle.add_child(search)
	var right := _column_panel(row, 0.33)
	right.add_child(_heading("Slots: %d/5" % _used_slots()))
	for boon in _boons:
		var boon_name: String = boon
		var remove := _button("%s   ×" % boon_name, func() -> void: _boons.erase(boon_name); _send_loadout(); _render())
		remove.tooltip_text = "Remove %s" % boon_name
		right.add_child(remove)
	if _boons.is_empty():
		right.add_child(_text(UiText.EMPTY["boons"]))


func _show_boon_details(boon: String) -> void:
	if not is_instance_valid(_boon_details):
		return
	UiKit.clear(_boon_details)
	if boon.is_empty():
		return
	var slots := int(_meta.get("boons", {}).get(boon, {}).get("slots", 0))
	_boon_details.add_child(_center(boon, "title"))
	_boon_details.add_child(_text("Slots: %d" % slots))
	_boon_details.add_child(_text(str(BOON_EFFECTS.get(boon, ""))))
	var status := ""
	var color := UiKit.TEXT_DIM
	if _boons.has(boon):
		status = "Equipped. Click it on the right to remove."
		color = UiKit.SUCCESS
	elif boon == "The Chosen One" and _prestige_total() < 5:
		status = "Locked: requires 5 total Prestige (you have %d)." % _prestige_total()
		color = UiKit.WARN
	elif _used_slots() + slots > 5:
		status = "Not enough Boon slots: %d/5 used." % _used_slots()
		color = UiKit.WARN
	else:
		status = "Click to equip (%d/5 slots used)." % _used_slots()
	var status_label := _text(status)
	status_label.add_theme_color_override("font_color", color)
	_boon_details.add_child(status_label)


func _render_profile() -> void:
	var loadout := _own_loadout()
	var panel := _column_panel(_content, 1.0)
	panel.add_child(_heading("Profile"))
	panel.add_child(_text("Player: %s" % _app.settings.player_name))
	panel.add_child(_text("ID: %s…" % _app.player_token.substr(0, 8)))
	panel.add_child(_text("Gems: %d" % int(_profile().get("gems", 0))))
	panel.add_child(_text("Class: %s\nRace: %s\nBoons: %s" % [str(loadout.get("class", _class_id)).capitalize(), str(loadout.get("race", _race)), ", ".join(loadout.get("boons", _boons))]))


func _render_records() -> void:
	var panel := _column_panel(_content, 1.0)
	panel.add_child(_heading("Records"))
	panel.add_child(_text(UiText.EMPTY["records"]))


func _select_boon(boon: String) -> void:
	_selected_boon = boon
	if not _boons.has(boon):
		var slots := int(_meta.get("boons", {}).get(boon, {}).get("slots", 0))
		if _used_slots() + slots > 5:
			_app.toast("Not enough Boon slots: %d/5 used." % _used_slots())
		else:
			_boons.append(boon)
			_send_loadout()
	_render()


func _cycle_class(step: int) -> void:
	_class_id = CLASSES[posmod(CLASSES.find(_class_id) + step, CLASSES.size())]
	_send_loadout()
	_render()


func _focus_tree() -> void:
	if is_instance_valid(_tree_focus):
		_tree_focus.grab_focus()


func _send_loadout() -> void:
	var race_to_send := _race if _profile().get("races_owned", []).has(_race) else "Human"
	_app.send({"type": "set_loadout", "class": _class_id, "race": race_to_send, "boons": _boons.duplicate()})


func _profile() -> Dictionary:
	return _app.snapshot.get("room", {}).get("profile", {})


func _own_loadout() -> Dictionary:
	for slot in _app.snapshot.get("room", {}).get("slots", []):
		if slot.get("is_you", false):
			return slot.get("loadout", {})
	return {}


func _tree_level(node: String) -> int:
	return int(_profile().get("class_trees", {}).get(_class_id, {}).get(node, 0))


func _used_slots() -> int:
	var total := 0
	for boon in _boons:
		total += int(_meta.get("boons", {}).get(boon, {}).get("slots", 0))
	return total


func _prestige_total() -> int:
	var total := 0
	for value in _profile().get("prestige", {}).values():
		total += int(value)
	return total


func handle_key(keycode: int) -> bool:
	if keycode == KEY_ESCAPE:
		_finish.call()
		return true
	var tab := keycode - KEY_1
	if tab >= 0 and tab < NAV.size():
		_switch_tab(NAV[tab])
		return true
	return false


## A navy column. With `title`, the title sits in its own small box above the
## panel, like the floating "Class" / "Races" / "Description" boxes in refs 01-02.
func _column_panel(parent: Control, share: float, title: String = "") -> VBoxContainer:
	var box := UiKit.vbox(9)
	var panel := UiKit.panel(box)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var outer: Control = panel
	if not title.is_empty():
		var column := UiKit.vbox(8)
		var tag := UiKit.panel(_center(title, "heading"), "TitleTag")
		tag.custom_minimum_size.x = 200
		tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(tag)
		column.add_child(panel)
		outer = column
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if parent == _content:
		outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		outer.size_flags_stretch_ratio = share * 100.0
	parent.add_child(outer)
	return box


func _card(parent: VBoxContainer, min_height: float) -> VBoxContainer:
	var box := UiKit.vbox(6)
	var panel := UiKit.panel(box, "CardPanel")
	panel.custom_minimum_size.y = min_height
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	return box


func _scroll(parent: VBoxContainer) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	return scroll


func _heading(value: String) -> Label:
	return UiKit.pixel_label(value, "heading")


func _center(value: String, style: String) -> Label:
	var label := UiKit.pixel_label(value, style)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _text(value: String) -> Label:
	var label := UiKit.pixel_label(value, "body")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _button(value: String, action: Callable, big: bool = false) -> Button:
	return UiKit.button(value, action, big)


func _gems() -> int:
	return int(_profile().get("gems", 0))
