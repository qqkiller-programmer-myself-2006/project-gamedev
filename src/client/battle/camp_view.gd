class_name CampView
extends Control
## AAC-style Merchant / Rest camp. Every action is a server command.

var tips: VBoxContainer
var _screen: MatchScreen
var _app: ClientApp
var _encounter: Dictionary = {}
var _stock: Array = []
var _recipes: Array = []
var _ready := false
var _deadline: Variant = null
var _countdown: Label
var _region: Label
var _columns: HBoxContainer
var _bottom: HBoxContainer
var _workspace: Control
var _hide_button: Button
var _hidden := false
var _inspect := -1
var _category := ""
var _left_search := ""
var _inventory_search := ""
var _left_mode := "craft"
var _inventory_mode := "inventory"
var _invest_panel: PanelContainer
const CAMP_PANEL := Color("#5c5c5c")
const CAMP_ROW := Color("#7b7b7b")
const CAMP_BUTTON := Color("#4a4a4a")
const CAMP_BORDER := Color("#303030")
const CAMP_TEXT := Color("#f7f4ea")
const SLOTS := ["helmet", "chest", "legs", "boots", "weapon", "charm1", "charm2", "charm3"]
const ATTRIBUTES := ["str", "dex", "con", "int", "fth", "cha", "lck"]

func setup(screen: MatchScreen, app: ClientApp) -> void:
	_screen = screen
	_app = app
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := BattleBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.58)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var menu := UiKit.hbox(5)
	menu.position = Vector2(18, 12)
	for entry in [["≡", screen.toggle_clues], ["?", app.open_settings], ["×", app.close_hints]]:
		var button := _button(str(entry[0]), entry[1])
		button.custom_minimum_size = Vector2(43, 43)
		button.tooltip_text = "Menu" if entry[0] == "≡" else "Settings" if entry[0] == "?" else "Leave"
		menu.add_child(button)
	add_child(menu)
	_region = UiKit.pixel_label("", "title")
	_region.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_region.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_region.offset_right = -18
	_region.offset_top = 6
	_region.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_region)
	var encounter_box := UiKit.panel(UiKit.pixel_label("\"Jumpscare\"\nAll", "small"), "HudCard")
	encounter_box.name = "EncounterBox"
	encounter_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	encounter_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	encounter_box.offset_right = -18
	encounter_box.offset_top = 62
	encounter_box.offset_left = -128
	encounter_box.offset_bottom = 88
	encounter_box.add_theme_stylebox_override("panel", _flat_box(CAMP_BUTTON, CAMP_BORDER, 2, 7))
	add_child(encounter_box)
	_workspace = Control.new()
	_workspace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_workspace.offset_left = 38
	_workspace.offset_right = -38
	_workspace.offset_top = 104
	_workspace.offset_bottom = -66
	add_child(_workspace)
	_columns = UiKit.hbox(12)
	_columns.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_workspace.add_child(_columns)
	_bottom = UiKit.hbox(12)
	_bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bottom.offset_top = -58
	_bottom.offset_left = 38
	_bottom.offset_right = -38
	_bottom.offset_bottom = -10
	_bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_bottom)
	_hide_button = _button("Hide", func() -> void: _toggle_hidden())
	_hide_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hide_button.offset_left = -165
	_hide_button.offset_right = -38
	_hide_button.offset_top = -55
	_hide_button.offset_bottom = -10
	add_child(_hide_button)
	tips = UiKit.vbox(6)
	tips.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tips.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tips.offset_right = -10
	tips.offset_bottom = -10
	add_child(tips)

func build(view: Dictionary, encounter: Dictionary) -> void:
	_encounter = encounter
	if _inspect < 0: _inspect = maxi(0, _screen.your_slot())
	_region.text = "Forest (%d/%d)" % [int(view.get("layer", 0)), int(view.get("layers_total", 5))]
	var merchant := str(encounter.get("kind", "")) == "merchant"
	_stock = encounter.get("stock", []) if merchant else []
	_ready = bool(encounter.get("you_are_ready", false))
	_deadline = encounter.get("deadline", encounter.get("ends_at"))
	_build_columns(view, merchant)
	_build_bottom()
	tick()
	_app.hint("merchant" if merchant else "rest")

func _build_columns(view: Dictionary, merchant: bool) -> void:
	UiKit.clear(_columns)
	_columns.add_child(_column("Shop" if merchant else "Crafting", _left_panel(view, merchant), 0.28))
	_columns.add_child(_vertical_tabs(["Stash", "Shop" if merchant else "Craft"], true))
	_columns.add_child(_column("Inventory", _inventory_panel(view), 0.30))
	_columns.add_child(_vertical_tabs(["Inventory", "Abilities"], false, view))
	_columns.add_child(_column("Equipment", _equipment_panel(view, merchant), 0.36))

func _column(title: String, content: Control, ratio: float) -> Control:
	var column := UiKit.vbox(5)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_stretch_ratio = ratio
	var heading := UiKit.pixel_label(title, "title")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.clip_text = true
	heading.custom_minimum_size = Vector2(0, 0)
	heading.add_theme_color_override("font_outline_color", Color.BLACK)
	heading.add_theme_constant_override("outline_size", 5)
	column.add_child(heading)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel := UiKit.panel(content, "HudPanel")
	panel.add_theme_stylebox_override("panel", _flat_box(CAMP_PANEL, CAMP_BORDER, 2, 7))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(panel)
	return column

func _vertical_tabs(labels: Array, left: bool, view: Dictionary = {}) -> Control:
	var tabs := UiKit.vbox(5)
	tabs.custom_minimum_size = Vector2(70, 0)
	tabs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in labels.size():
		var label: String = labels[i]
		var active := (left and ((label == "Stash" and _left_mode == "stash") or
				((label == "Craft" or label == "Shop") and _left_mode == "craft"))) \
				or (not left and ((label == "Inventory" and _inventory_mode == "inventory") or
				(label == "Abilities" and _inventory_mode == "abilities")))
		var button := _button(label, func() -> void:
			if label == "Stash": _left_mode = "stash"
			elif label == "Craft" or label == "Shop": _left_mode = "craft"
			elif label == "Inventory": _inventory_mode = "inventory"
			elif label == "Abilities":
				_inventory_mode = "abilities"
				_show_abilities(view)
			_screen.refresh(_app, true))
		button.custom_minimum_size = Vector2(70, 58)
		button.add_theme_font_size_override("font_size", 12)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if active:
			button.add_theme_stylebox_override("normal", _flat_box(Color("#777777"), Color("#e0e0e0"), 2, 4))
			button.add_theme_stylebox_override("hover", _flat_box(Color("#858585"), Color("#f0c85c"), 2, 4))
		tabs.add_child(button)
	if not left:
		var you := _character(view, _screen.your_slot())
		var consumable := str(you.get("consumable", ""))
		var slot := UiKit.panel(UiKit.pixel_label("Consumable\n" + (consumable if not consumable.is_empty() else "Empty"), "small"), "HudCard")
		slot.custom_minimum_size = Vector2(70, 76)
		slot.add_theme_stylebox_override("panel", _flat_box(CAMP_ROW, CAMP_BORDER, 1, 5))
		tabs.add_child(slot)
	return tabs

func _scroll_body(body: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	return scroll

func _left_panel(view: Dictionary, merchant: bool) -> Control:
	var root := UiKit.vbox(6)
	var search := LineEdit.new()
	search.placeholder_text = "Search..."
	search.text = _left_search
	search.clear_button_enabled = true
	search.text_changed.connect(func(value: String) -> void:
		_left_search = value
		_screen.refresh(_app, true))
	root.add_child(search)
	var body := UiKit.vbox(5)
	root.add_child(_scroll_body(body))
	if _left_mode == "stash": _build_stash(view, body)
	elif merchant: _build_shop(view, body)
	else: _build_crafting(body)
	return root

func _build_shop(view: Dictionary, body: VBoxContainer) -> void:
	for i in _stock.size():
		var entry: Dictionary = _stock[i]
		if not _matches(str(entry.get("name", entry.get("item", ""))), _left_search): continue
		var card := _row_card()
		var text := UiKit.vbox(1)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.custom_minimum_size = Vector2(0, 0)
		var shop_name := UiKit.pixel_label(str(entry.get("name", entry.get("item", ""))), "small")
		shop_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		shop_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		shop_name.custom_minimum_size = Vector2(0, 0)
		text.add_child(shop_name)
		text.add_child(UiKit.pixel_label("%d Gold   (%d)" % [int(entry.get("price", 0)), int(entry.get("remaining", 0))], "small", UiKit.ACCENT))
		card.get_child(0).add_child(text)
		var actions := UiKit.vbox(2)
		var buy := _button("Buy", func() -> void: _app.send({"type": "buy", "item": entry.get("item", "")}))
		buy.disabled = not bool(entry.get("affordable", int(view.get("gold", 0)) >= int(entry.get("price", 0)))) or int(entry.get("remaining", 0)) <= 0
		buy.tooltip_text = "Need %d" % int(entry.get("price", 0)) if not bool(entry.get("affordable", true)) else ""
		buy.set_meta("focus_id", "buy_" + str(entry.get("item", "")))
		actions.add_child(buy)
		actions.add_child(_button("Inspect", func() -> void: _show_info(entry)))
		card.get_child(0).add_child(actions)
		body.add_child(card)

func _build_crafting(body: VBoxContainer) -> void:
	_recipes = []
	var groups: Dictionary = {}
	for recipe in _encounter.get("recipes", []):
		if _category.is_empty() or str(recipe.get("category", "")) == _category:
			_recipes.append(recipe)
			var category := str(recipe.get("category", "Other"))
			groups[category] = int(groups.get(category, 0)) + 1
	for category in groups:
		var header := _button("%s (%d)  –" % [category, groups[category]], func() -> void:
			_category = "" if _category == str(category) else str(category)
			_screen.refresh(_app, true))
		header.alignment = HORIZONTAL_ALIGNMENT_LEFT
		body.add_child(header)
		for i in _recipes.size():
			var recipe: Dictionary = _recipes[i]
			if str(recipe.get("category", "")) != str(category) or not _matches(str(recipe.get("name", "")), _left_search): continue
			body.add_child(_recipe_row(recipe, i))

func _recipe_row(recipe: Dictionary, index: int) -> Control:
	var card := _row_card()
	var name := UiKit.vbox(1)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.custom_minimum_size = Vector2(0, 0)
	var recipe_name := UiKit.pixel_label(str(recipe.get("name", recipe.get("recipe", ""))), "small")
	recipe_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	recipe_name.custom_minimum_size = Vector2(0, 0)
	name.add_child(recipe_name)
	var tips_text := ""
	for material in recipe.get("materials", []):
		tips_text += "%d %s (%d)\n" % [int(material.get("need", 0)), str(material.get("name", material.get("item", ""))), int(material.get("have", 0))]
	var actions := UiKit.vbox(2)
	var craftable := bool(recipe.get("craftable", false))
	var craft := _button("Craft", func() -> void: _app.send({"type": "craft", "recipe": recipe.get("recipe", "")}))
	craft.disabled = not craftable
	craft.add_theme_color_override("font_color", UiKit.ALLY if craftable else UiKit.ENEMY)
	craft.add_theme_color_override("font_disabled_color", UiKit.ALLY if craftable else UiKit.ENEMY)
	craft.tooltip_text = tips_text
	craft.set_meta("focus_id", "craft_" + str(recipe.get("recipe", "")))
	actions.add_child(craft)
	actions.add_child(_button("Inspect", func() -> void: _show_info(recipe)))
	card.get_child(0).add_child(name)
	card.get_child(0).add_child(actions)
	return card

func _build_stash(view: Dictionary, body: VBoxContainer) -> void:
	for entry in view.get("inventory", []):
		if _matches(str(entry.get("name", "")), _left_search): body.add_child(_item_row(entry, false))

func _inventory_panel(view: Dictionary) -> Control:
	var root := UiKit.vbox(6)
	var search := LineEdit.new()
	search.placeholder_text = "Search..."
	search.text = _inventory_search
	search.clear_button_enabled = true
	search.text_changed.connect(func(value: String) -> void:
		_inventory_search = value
		_screen.refresh(_app, true))
	root.add_child(search)
	var body := UiKit.vbox(5)
	root.add_child(_scroll_body(body))
	for entry in view.get("inventory", []):
		if _matches(str(entry.get("name", "")), _inventory_search): body.add_child(_item_row(entry, true))
	var you := _character(view, _screen.your_slot())
	var gold := int(you.get("gold", view.get("gold", 0)))
	var gold_row := UiKit.hbox(4)
	gold_row.add_child(UiKit.pixel_label("%d 🪙" % gold, "heading", UiKit.ACCENT))
	gold_row.add_child(UiKit.spacer())
	var transfer := _button("Transfer Gold", func() -> void: _open_gold_picker())
	transfer.disabled = not you.has("gold")
	transfer.tooltip_text = "Arrives with the next server update" if transfer.disabled else ""
	gold_row.add_child(transfer)
	var gold_panel := UiKit.panel(gold_row, "HudCard")
	gold_panel.add_theme_stylebox_override("panel", _flat_box(CAMP_ROW, CAMP_BORDER, 1, 5))
	root.add_child(gold_panel)
	return root

func _item_row(entry: Dictionary, with_transfer: bool) -> Control:
	var card := _row_card()
	var text := UiKit.vbox(1)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size = Vector2(0, 0)
	var item_name := UiKit.pixel_label("%s (x%d)" % [str(entry.get("name", entry.get("item", ""))), int(entry.get("count", 1))], "small")
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_name.custom_minimum_size = Vector2(0, 0)
	text.add_child(item_name)
	card.get_child(0).add_child(text)
	var actions := UiKit.vbox(2)
	if with_transfer: actions.add_child(_button("Transfer", func() -> void: _open_item_picker(str(entry.get("item", "")))))
	if str(entry.get("kind", "")) == "gear": actions.add_child(_button("Equip", func() -> void: _app.send({"type": "equip", "item": entry.get("item", "")})))
	actions.add_child(_button("Inspect", func() -> void: _show_info(entry)))
	card.get_child(0).add_child(actions)
	return card

func _equipment_panel(view: Dictionary, merchant: bool) -> Control:
	var root := UiKit.vbox(6)
	var party: Array = view.get("party", [])
	var character := _character(view, _inspect)
	var switcher := UiKit.hbox(4)
	var previous := _button("<", func() -> void: _move_inspect(-1, party))
	previous.custom_minimum_size = Vector2(32, 42)
	switcher.add_child(previous)
	var who := UiKit.pixel_label(str(character.get("name", "Character")), "heading", UiKit.ACCENT)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	switcher.add_child(who)
	var next := _button(">", func() -> void: _move_inspect(1, party))
	next.custom_minimum_size = Vector2(32, 42)
	switcher.add_child(next)
	root.add_child(switcher)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	var gear: Dictionary = character.get("gear", {})
	for slot in SLOTS:
		var cell := UiKit.vbox(1)
		cell.custom_minimum_size = Vector2(0, 86)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var worn: Dictionary = gear.get(slot, {})
		var slot_label := UiKit.pixel_label(_slot_name(slot) + "\n" + (str(worn.get("name", "Empty")) if not worn.is_empty() else "Empty"), "small")
		slot_label.add_theme_font_size_override("font_size", 11)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.custom_minimum_size = Vector2(0, 62)
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(slot_label)
		var controls := UiKit.hbox(2)
		controls.alignment = BoxContainer.ALIGNMENT_END
		if not worn.is_empty():
			controls.add_child(_button("–", func() -> void: _app.send({"type": "unequip", "gear_slot": slot})))
			controls.add_child(_button("T", func() -> void: _show_info(worn)))
		cell.add_child(controls)
		var cell_panel := UiKit.panel(cell, "HudCard")
		cell_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell_panel.add_theme_stylebox_override("panel", _flat_box(CAMP_ROW, CAMP_BORDER, 1, 5))
		grid.add_child(cell_panel)
	root.add_child(grid)
	var stats := UiKit.vbox(1)
	var attrs: Dictionary = character.get("attributes", {})
	var derived: Dictionary = character.get("derived", {})
	stats.add_child(_stat("HP", "%d/%d" % [int(character.get("hp", 0)), int(character.get("max_hp", 0))]))
	stats.add_child(_stat("Energy", str(character.get("energy", 0))))
	stats.add_child(_stat("Level", "%d (%d/%d)" % [int(character.get("level", 1)), int(character.get("exp", 0)), int(character.get("exp_next", 0))]))
	var separator_one := Control.new()
	separator_one.custom_minimum_size = Vector2(0, 8)
	stats.add_child(separator_one)
	for key in ATTRIBUTES:
		stats.add_child(_stat(key.to_upper(), str(attrs.get(key, _fallback_attr(character, key)))))
	var separator_two := Control.new()
	separator_two.custom_minimum_size = Vector2(0, 8)
	stats.add_child(separator_two)
	stats.add_child(_stat("Initiative", _range_text(derived.get("initiative", character.get("spd", 0)))))
	stats.add_child(_stat("Crit Chance", _percent(derived.get("crit", character.get("crit", 0)))))
	stats.add_child(_stat("Crit Damage", _percent(derived.get("crit_damage", 1.5))))
	stats.add_child(_stat("Block Chance", _percent(derived.get("block", 0))))
	stats.add_child(_stat("Block Damage Reduction", _percent(derived.get("block_reduction", 0.5))))
	stats.add_child(_stat("Dodge Chance", _percent(derived.get("dodge", 0))))
	stats.add_child(_stat("Aggro", _percent(derived.get("aggro", 1.0))))
	stats.add_child(_stat("Lifesteal", _percent(derived.get("lifesteal", 0))))
	stats.add_child(_stat("Energy Regen", str(derived.get("energy_regen", 1))))
	var stat_scroll := _scroll_body(stats)
	stat_scroll.custom_minimum_size = Vector2(0, 0)
	var stat_panel := UiKit.panel(stat_scroll, "HudCard")
	stat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stat_panel.add_theme_stylebox_override("panel", _flat_box(CAMP_ROW, CAMP_BORDER, 1, 7))
	root.add_child(stat_panel)
	var points := int(character.get("points", 0))
	var invest := _button("Invest Points (%d)" % points, func() -> void: _open_invest(character))
	invest.disabled = merchant or points <= 0 or _inspect != _screen.your_slot()
	root.add_child(invest)
	return root

func _stat(label: String, value: String) -> Control:
	var row := UiKit.pixel_label(label + ": " + value, "small")
	row.clip_text = false
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.custom_minimum_size = Vector2(0, 22)
	return row

func _build_bottom() -> void:
	UiKit.clear(_bottom)
	var ready := _button("Ready (%d/%d) [R]" % [int(_encounter.get("ready", []).size()), maxi(1, int(_encounter.get("humans", 1)))], func() -> void: _app.send({"type": "ready"}))
	ready.disabled = _ready
	ready.custom_minimum_size = Vector2(280, 48)
	ready.set_meta("focus_id", "ready")
	_bottom.add_child(ready)
	_countdown = UiKit.pixel_label("", "heading")
	_bottom.add_child(_countdown)

func tick() -> void:
	if _countdown == null or _deadline == null: return
	_countdown.text = "%ds" % ceili(_app.seconds_left(_deadline))

func handle_key(key: int) -> bool:
	if key == KEY_R and not _ready:
		_app.send({"type": "ready"})
		return true
	var index := key - KEY_1
	if str(_encounter.get("kind", "")) == "merchant" and index >= 0 and index < _stock.size():
		_app.send({"type": "buy", "item": _stock[index].get("item", "")})
		return true
	if str(_encounter.get("kind", "")) == "rest" and index >= 0 and index < mini(9, _recipes.size()):
		_app.send({"type": "craft", "recipe": _recipes[index].get("recipe", "")})
		return true
	return false

func reset() -> void:
	_inspect = -1
	_category = ""
	_left_mode = "craft"
	_inventory_mode = "inventory"
	_close_invest_panel()
	_hidden = false

func focus_default() -> void:
	if not UiKit.focus_first(_columns): UiKit.focus_first(_bottom)

func _row_card() -> PanelContainer:
	var row := UiKit.hbox(5)
	row.custom_minimum_size = Vector2(0, 62)
	var panel := UiKit.panel(row, "HudCard")
	panel.add_theme_stylebox_override("panel", _flat_box(CAMP_ROW, CAMP_BORDER, 1, 5))
	return panel

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = "HudButton"
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", CAMP_TEXT)
	button.add_theme_color_override("font_outline_color", Color("#242424"))
	button.add_theme_constant_override("outline_size", 3)
	button.custom_minimum_size = Vector2(0, 27)
	button.add_theme_stylebox_override("normal", _flat_box(CAMP_BUTTON, CAMP_BORDER, 1, 4))
	button.add_theme_stylebox_override("disabled", _flat_box(Color("#666666"), CAMP_BORDER, 1, 4))
	return button

func _flat_box(bg: Color, border: Color, width: int, margin: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(2)
	box.set_content_margin_all(margin)
	return box

func _matches(value: String, query: String) -> bool:
	return query.strip_edges().is_empty() or value.to_lower().contains(query.to_lower())

func _character(view: Dictionary, slot: int) -> Dictionary:
	for character in view.get("party", []):
		if int(character.get("slot", -1)) == slot: return character
	return {}

func _move_inspect(delta: int, party: Array) -> void:
	if party.is_empty(): return
	var index := 0
	for i in party.size():
		if int(party[i].get("slot", -1)) == _inspect: index = i
	_inspect = int(party[posmod(index + delta, party.size())].get("slot", 0))
	_screen.refresh(_app, true)

func _slot_name(slot: String) -> String:
	if slot.begins_with("charm"): return "Charm " + slot.trim_prefix("charm")
	return slot.capitalize()

func _fallback_attr(character: Dictionary, key: String) -> int:
	var map := {"str": "atk", "dex": "spd", "con": "max_hp", "int": "mag", "fth": "res", "cha": "crit", "lck": "crit"}
	return int(character.get(map.get(key, key), 0))

func _range_text(value: Variant) -> String:
	if value is Array and value.size() >= 2: return "%s - %s" % [value[0], value[1]]
	return "%s - %s" % [value, int(value) + 5]

func _percent(value: Variant) -> String:
	var number := float(value)
	if number <= 1.0: number *= 100.0
	return "%.1f%%" % number

func _show_info(data: Dictionary) -> void: _app.hint(str(data.get("description", "")))

func _show_abilities(view: Dictionary) -> void: _app.hint("Skills: " + str(_character(view, _inspect).get("skills", "None")))

func _open_item_picker(item: String) -> void:
	var party: Array = _screen.match_view().get("party", [])
	if not party.is_empty(): _app.send({"type": "transfer_item", "item": item, "to": int(party[0].get("slot", 0))})

func _open_gold_picker() -> void:
	var party: Array = _screen.match_view().get("party", [])
	if party.size() > 1: _app.send({"type": "transfer_gold", "to": int(party[1].get("slot", 1)), "amount": 1})

func _open_invest(character: Dictionary) -> void:
	_close_invest_panel()
	var body := UiKit.vbox(4)
	body.add_child(UiKit.pixel_label("Invest Points (%d)" % int(character.get("points", 0)), "small"))
	for attr in ATTRIBUTES:
		var stat: String = attr
		var plus := _button("+ %s" % attr.to_upper(), func() -> void:
			_app.send({"type": "invest", "stat": stat})
			_close_invest_panel())
		plus.custom_minimum_size = Vector2(150, 28)
		body.add_child(plus)
	_invest_panel = UiKit.panel(body, "HudPanel")
	_invest_panel.name = "InvestPanel"
	_invest_panel.add_theme_stylebox_override("panel", _flat_box(CAMP_PANEL, Color("#e0e0e0"), 2, 8))
	_invest_panel.set_anchors_preset(Control.PRESET_CENTER)
	_invest_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_invest_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_invest_panel.offset_left = -90
	_invest_panel.offset_right = 90
	_invest_panel.offset_top = -150
	_invest_panel.offset_bottom = 150
	add_child(_invest_panel)
	UiKit.focus_first(_invest_panel)

func _close_invest_panel() -> void:
	if is_instance_valid(_invest_panel):
		_invest_panel.queue_free()
	_invest_panel = null

func _toggle_hidden() -> void:
	_hidden = not _hidden
	_columns.visible = not _hidden
	_bottom.visible = not _hidden
	_hide_button.visible = not _hidden
	var old := get_node_or_null("CampShowButton")
	if old != null: old.queue_free()
	if _hidden:
		var show := _button("Show", func() -> void: _toggle_hidden())
		show.name = "CampShowButton"
		show.set_anchors_preset(Control.PRESET_CENTER)
		show.custom_minimum_size = Vector2(180, 54)
		add_child(show)
