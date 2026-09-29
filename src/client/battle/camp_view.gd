class_name CampView
extends Control
## AAC-style Merchant / Rest camp in the Navy + Gold theme: three columns
## (Crafting or Shop | Inventory | Equipment). Every action is a server command.

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
var _encounter_label: Label
var _columns: HBoxContainer
var _bottom: HBoxContainer
var _workspace: Control
var _hide_button: Button
var _menu_panel: PanelContainer
var _hidden := false
var _inspect := -1
var _category := ""
var _left_search := ""
var _inventory_search := ""
var _left_mode := "craft"
var _inventory_mode := "inventory"
var _invest_panel: PanelContainer
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
	shade.color = Color(UiKit.BG, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_region = UiKit.pixel_label("", "title")
	_region.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_region.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_region.offset_right = -18
	_region.offset_top = 6
	_region.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_region.add_theme_color_override("font_outline_color", UiKit.BG)
	_region.add_theme_constant_override("outline_size", 6)
	add_child(_region)
	_encounter_label = UiKit.pixel_label("", "small")
	var encounter_box := UiKit.panel(_encounter_label, "HudPanel")
	encounter_box.name = "EncounterBox"
	encounter_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	encounter_box.position = Vector2(112, 12)
	add_child(encounter_box)
	_workspace = Control.new()
	_workspace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_workspace.offset_left = 24
	_workspace.offset_right = -24
	_workspace.offset_top = 64
	_workspace.offset_bottom = -66
	add_child(_workspace)
	_columns = UiKit.hbox(10)
	_columns.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_workspace.add_child(_columns)
	_bottom = UiKit.hbox(12)
	_bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bottom.offset_bottom = -10
	_bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_bottom)
	_hide_button = _button("Hide", func() -> void: _toggle_hidden())
	_hide_button.tooltip_text = "Hide the camp to look at the field"
	_hide_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hide_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hide_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hide_button.offset_right = -24
	_hide_button.offset_bottom = -12
	_hide_button.custom_minimum_size = Vector2(110, 40)
	add_child(_hide_button)
	# Tips sit low over the Inventory column, which has room at its bottom,
	# so they never cover Ready, the recipes or the character's stats.
	tips = UiKit.vbox(6)
	tips.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tips.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tips.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tips.offset_bottom = -120
	add_child(tips)
	_menu_panel = screen.build_corner_menu(self)

func build(view: Dictionary, encounter: Dictionary) -> void:
	_encounter = encounter
	if _inspect < 0: _inspect = maxi(0, _screen.your_slot())
	_region.text = "Forest (%d/%d)" % [int(view.get("layer", 0)), int(view.get("layers_total", 5))]
	var merchant := str(encounter.get("kind", "")) == "merchant"
	_encounter_label.text = "\"%s\"" % str(encounter.get("name", "Merchant" if merchant else "Rest")).replace("\"", "")
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
	var column := UiKit.vbox(6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_stretch_ratio = ratio
	var tag := UiKit.panel(UiKit.pixel_label(title, "heading"), "TitleTag")
	tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	(tag.get_child(0) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.custom_minimum_size = Vector2(150, 0)
	column.add_child(tag)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel := UiKit.panel(content, "HudPanel")
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(panel)
	return column

func _vertical_tabs(labels: Array, left: bool, view: Dictionary = {}) -> Control:
	var tabs := UiKit.vbox(6)
	tabs.custom_minimum_size = Vector2(88, 0)
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
		button.custom_minimum_size = Vector2(88, 52)
		button.clip_text = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("focus_id", "camp_tab_" + label)
		if active:
			button.theme_type_variation = "SelectedButton"
			button.add_theme_font_size_override("font_size", int(UiKit.SIZES["small"] * _app.settings.text_scale))
		tabs.add_child(button)
	if not left:
		var you := _character(view, _acting_slot())
		var consumable = you.get("consumable")
		var consumable_text := str(consumable) if consumable != null and not str(consumable).is_empty() else "Empty"
		var slot_label := UiKit.pixel_label("Consumable\n" + consumable_text, "tiny")
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var slot := UiKit.panel(slot_label, "HudCard")
		slot.custom_minimum_size = Vector2(88, 64)
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

func _search_box(text: String, on_change: Callable) -> LineEdit:
	var search := LineEdit.new()
	search.placeholder_text = "Search..."
	search.text = text
	search.clear_button_enabled = true
	search.text_changed.connect(on_change)
	return search

## A short line telling the player what to do when a list is empty.
func _empty(key: String, query: String = "") -> Label:
	var text: String = UiText.EMPTY["search"] % query if not query.strip_edges().is_empty() else UiText.EMPTY[key]
	return UiKit.para(text, "small", UiKit.TEXT_DIM)

func _left_panel(view: Dictionary, merchant: bool) -> Control:
	var root := UiKit.vbox(6)
	root.add_child(_search_box(_left_search, func(value: String) -> void:
		_left_search = value
		_screen.refresh(_app, true)))
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
		var shop_name := UiKit.pixel_label("[%d] %s" % [i + 1, str(entry.get("name", entry.get("item", "")))], "small")
		shop_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(shop_name)
		text.add_child(UiKit.pixel_label("%d Gold   (%d left)" % [int(entry.get("price", 0)), int(entry.get("remaining", 0))], "small", UiKit.ACCENT))
		card.get_child(0).add_child(text)
		var actions := UiKit.vbox(2)
		var buy := _button("Buy", func() -> void: _app.send({"type": "buy", "slot": _acting_slot(), "item": entry.get("item", "")}))
		var affordable := int(_character(view, _acting_slot()).get("gold", 0)) >= int(entry.get("price", 0)) if _screen.room_view().get("story", false) else bool(entry.get("affordable", int(view.get("gold", 0)) >= int(entry.get("price", 0))))
		if int(entry.get("remaining", 0)) <= 0:
			UiKit.disable(buy, true, UiText.WHY["sold_out"])
		else:
			UiKit.disable(buy, not affordable, UiText.WHY["need_gold"] % int(entry.get("price", 0)))
		buy.set_meta("focus_id", "buy_" + str(entry.get("item", "")))
		actions.add_child(buy)
		actions.add_child(_button("Inspect", func() -> void: _show_info(entry)))
		card.get_child(0).add_child(actions)
		body.add_child(card)
	if body.get_child_count() == 0:
		body.add_child(_empty("shop", _left_search))

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
		header.tooltip_text = "Show only %s (click again to show all)" % category
		body.add_child(header)
		for i in _recipes.size():
			var recipe: Dictionary = _recipes[i]
			if str(recipe.get("category", "")) != str(category) or not _matches(str(recipe.get("name", "")), _left_search): continue
			body.add_child(_recipe_row(recipe, i))
	if _recipes.is_empty():
		body.add_child(_empty("recipes"))
	elif not _left_search.strip_edges().is_empty() and body.get_child_count() == groups.size():
		body.add_child(_empty("recipes", _left_search))

func _recipe_row(recipe: Dictionary, index: int) -> Control:
	var card := _row_card()
	var name := UiKit.vbox(1)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var recipe_name := UiKit.pixel_label("%s%s" % ["[%d] " % (index + 1) if index < 9 else "", str(recipe.get("name", recipe.get("recipe", "")))], "small")
	recipe_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.add_child(recipe_name)
	var tips_text := ""
	for material in recipe.get("materials", []):
		tips_text += "%d %s (%d)\n" % [int(material.get("need", 0)), str(material.get("name", material.get("item", ""))), int(material.get("have", 0))]
	var actions := UiKit.vbox(2)
	var craftable := bool(recipe.get("craftable", false))
	var craft := _button("Craft", func() -> void: _app.send({"type": "craft", "slot": _acting_slot(), "recipe": recipe.get("recipe", "")}))
	craft.disabled = not craftable
	craft.add_theme_color_override("font_color", UiKit.ALLY)
	craft.add_theme_color_override("font_disabled_color", UiKit.ENEMY)
	craft.tooltip_text = ("Needs:\n" if not craftable else "Uses:\n") + tips_text.strip_edges()
	craft.set_meta("focus_id", "craft_" + str(recipe.get("recipe", "")))
	actions.add_child(craft)
	actions.add_child(_button("Inspect", func() -> void: _show_info(recipe)))
	card.get_child(0).add_child(name)
	card.get_child(0).add_child(actions)
	return card

func _build_stash(view: Dictionary, body: VBoxContainer) -> void:
	for entry in view.get("inventory", []):
		if _matches(str(entry.get("name", "")), _left_search): body.add_child(_item_row(entry, false))
	if body.get_child_count() == 0:
		body.add_child(_empty("stash", _left_search))

func _inventory_panel(view: Dictionary) -> Control:
	var root := UiKit.vbox(6)
	root.add_child(_search_box(_inventory_search, func(value: String) -> void:
		_inventory_search = value
		_screen.refresh(_app, true)))
	var body := UiKit.vbox(5)
	root.add_child(_scroll_body(body))
	for entry in view.get("inventory", []):
		if _matches(str(entry.get("name", "")), _inventory_search): body.add_child(_item_row(entry, true))
	if body.get_child_count() == 0:
		body.add_child(_empty("inventory", _inventory_search))
	var you := _character(view, _acting_slot())
	var gold := int(you.get("gold", view.get("gold", 0)))
	var gold_row := UiKit.hbox(4)
	gold_row.add_child(UiKit.pixel_label("%d Gold" % gold, "heading", UiKit.ACCENT))
	gold_row.add_child(UiKit.spacer())
	var transfer := _button("Transfer Gold", func() -> void: _open_gold_picker())
	UiKit.disable(transfer, not you.has("gold"), "Arrives with the next server update")
	gold_row.add_child(transfer)
	root.add_child(UiKit.panel(gold_row, "HudCard"))
	return root

func _item_row(entry: Dictionary, with_transfer: bool) -> Control:
	var card := _row_card()
	var text := UiKit.vbox(1)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var item_name := UiKit.pixel_label("%s (x%d)" % [str(entry.get("name", entry.get("item", ""))), int(entry.get("count", 1))], "small")
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(item_name)
	card.get_child(0).add_child(text)
	var actions := UiKit.vbox(2)
	if with_transfer: actions.add_child(_button("Transfer", func() -> void: _open_item_picker(str(entry.get("item", "")))))
	if str(entry.get("kind", "")) == "gear": actions.add_child(_button("Equip", func() -> void: _app.send({"type": "equip", "slot": _acting_slot(), "item": entry.get("item", "")})))
	actions.add_child(_button("Inspect", func() -> void: _show_info(entry)))
	card.get_child(0).add_child(actions)
	return card

func _equipment_panel(view: Dictionary, merchant: bool) -> Control:
	var root := UiKit.vbox(6)
	var party: Array = view.get("party", [])
	var character := _character(view, _inspect)
	var switcher := UiKit.hbox(4)
	var previous := _button("<", func() -> void: _move_inspect(-1, party))
	previous.custom_minimum_size = Vector2(36, 36)
	previous.tooltip_text = "Previous character"
	switcher.add_child(previous)
	var who := UiKit.pixel_label(str(character.get("name", "Character")), "heading", UiKit.ACCENT)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	switcher.add_child(who)
	var next := _button(">", func() -> void: _move_inspect(1, party))
	next.custom_minimum_size = Vector2(36, 36)
	next.tooltip_text = "Next character"
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
		cell.custom_minimum_size = Vector2(0, 70)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var worn: Dictionary = gear.get(slot, {})
		var slot_label := UiKit.pixel_label(_slot_name(slot) + "\n" + (str(worn.get("name", "Empty")) if not worn.is_empty() else "Empty"), "tiny",
				UiKit.TEXT if not worn.is_empty() else UiKit.TEXT_DIM)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.custom_minimum_size = Vector2(0, 44)
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(slot_label)
		var controls := UiKit.hbox(2)
		controls.alignment = BoxContainer.ALIGNMENT_END
		if not worn.is_empty():
			var off := _button("–", func() -> void: _app.send({"type": "unequip", "slot": _acting_slot(), "gear_slot": slot}))
			off.tooltip_text = "Unequip"
			controls.add_child(off)
			var info := _button("?", func() -> void: _show_info(worn))
			info.tooltip_text = "Inspect"
			controls.add_child(info)
		cell.add_child(controls)
		var cell_panel := UiKit.panel(cell, "HudCard")
		cell_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	var stat_panel := UiKit.panel(stat_scroll, "HudCard")
	stat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(stat_panel)
	var points := int(character.get("points", 0))
	var invest := _button("Invest Points (%d)" % points, func() -> void: _open_invest(character))
	invest.set_meta("focus_id", "invest")
	if merchant:
		UiKit.disable(invest, true, UiText.WHY["invest_merchant"])
	elif points <= 0:
		UiKit.disable(invest, true, UiText.WHY["invest_none"])
	else:
		UiKit.disable(invest, not _screen.room_view().get("story", false) and _inspect != _screen.your_slot(), UiText.WHY["invest_not_yours"])
	root.add_child(invest)
	return root

func _stat(label: String, value: String) -> Control:
	var row := UiKit.pixel_label(label + ": " + value, "small")
	row.clip_text = false
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return row

func _build_bottom() -> void:
	UiKit.clear(_bottom)
	var ready := UiKit.primary("Ready (%d/%d) [R]" % [int(_encounter.get("ready", []).size()), maxi(1, int(_encounter.get("humans", 1)))], func() -> void: _app.send({"type": "ready"}), false)
	UiKit.disable(ready, _ready, UiText.WHY["ready"])
	ready.custom_minimum_size = Vector2(280, 44)
	ready.set_meta("focus_id", "ready")
	_bottom.add_child(ready)
	_countdown = UiKit.pixel_label("", "heading")
	_countdown.add_theme_color_override("font_outline_color", UiKit.BG)
	_countdown.add_theme_constant_override("outline_size", 5)
	_bottom.add_child(_countdown)

func tick() -> void:
	if _countdown == null or _deadline == null: return
	var left := _app.seconds_left(_deadline)
	_countdown.text = "%ds" % ceili(left)
	_countdown.add_theme_color_override("font_color", UiKit.WARN if left <= 5.0 else UiKit.TEXT)

func handle_key(key: int) -> bool:
	if key == KEY_ESCAPE:
		if is_instance_valid(_invest_panel):
			_close_invest_panel()
		elif _hidden:
			_toggle_hidden()
		else:
			_menu_panel.visible = not _menu_panel.visible
			if _menu_panel.visible:
				UiKit.focus_first(_menu_panel)
		return true
	if key == KEY_R and not _ready:
		_app.send({"type": "ready"})
		return true
	var index := key - KEY_1
	if str(_encounter.get("kind", "")) == "merchant" and index >= 0 and index < _stock.size():
		_app.send({"type": "buy", "slot": _acting_slot(), "item": _stock[index].get("item", "")})
		return true
	if str(_encounter.get("kind", "")) == "rest" and index >= 0 and index < mini(9, _recipes.size()):
		_app.send({"type": "craft", "slot": _acting_slot(), "recipe": _recipes[index].get("recipe", "")})
		return true
	return false

func reset() -> void:
	_inspect = -1
	_category = ""
	_left_mode = "craft"
	_inventory_mode = "inventory"
	_close_invest_panel()
	_menu_panel.visible = false
	if _hidden:
		_toggle_hidden()

func focus_default() -> void:
	if not UiKit.focus_first(_bottom): UiKit.focus_first(_columns)

func _row_card() -> PanelContainer:
	var row := UiKit.hbox(5)
	row.custom_minimum_size = Vector2(0, 52)
	return UiKit.panel(row, "HudCard")

func _button(text: String, callback: Callable) -> Button:
	var button := UiKit.button(text, callback, false, "small")
	button.custom_minimum_size = Vector2(0, 28)
	return button

func _matches(value: String, query: String) -> bool:
	return query.strip_edges().is_empty() or value.to_lower().contains(query.to_lower())

func _character(view: Dictionary, slot: int) -> Dictionary:
	for character in view.get("party", []):
		if int(character.get("slot", -1)) == slot: return character
	return {}

func _acting_slot() -> int:
	return _inspect if _screen.room_view().get("story", false) else _screen.your_slot()

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
	_open_transfer_picker("transfer_item", item)

func _open_gold_picker() -> void:
	_open_transfer_picker("transfer_gold")

func _open_transfer_picker(kind: String, item: String = "") -> void:
	_close_invest_panel()
	var body := UiKit.vbox(6)
	body.add_child(UiKit.pixel_label("Transfer from %s" % _character(_screen.match_view(), _acting_slot()).get("name", ""), "heading", UiKit.ACCENT))
	var amount := LineEdit.new()
	if kind == "transfer_gold":
		amount.text = "1"
		amount.placeholder_text = "Gold amount"
		body.add_child(amount)
	body.add_child(UiKit.label("To:", "dim"))
	for character in _screen.match_view().get("party", []):
		var to := int(character["slot"])
		if to == _acting_slot():
			continue
		body.add_child(UiKit.button(str(character["name"]), func() -> void:
			var command := {"type": kind, "slot": _acting_slot(), "to": to}
			if kind == "transfer_gold":
				command["amount"] = int(amount.text)
			else:
				command["item"] = item
			_app.send(command)
			_close_invest_panel()))
	body.add_child(UiKit.button("Cancel [Esc]", _close_invest_panel))
	_open_popup(body, 280)

func _open_invest(character: Dictionary) -> void:
	_close_invest_panel()
	var body := UiKit.vbox(6)
	body.add_child(UiKit.pixel_label("Invest Points (%d)" % int(character.get("points", 0)), "heading", UiKit.ACCENT))
	for attr in ATTRIBUTES:
		var stat: String = attr
		var plus := UiKit.button("+ %s" % attr.to_upper(), func() -> void:
			_app.send({"type": "invest", "slot": _acting_slot(), "stat": stat})
			_close_invest_panel())
		body.add_child(plus)
	body.add_child(UiKit.button("Cancel [Esc]", _close_invest_panel))
	_open_popup(body, 220)
	_invest_panel.name = "InvestPanel"

## A small navy box in the middle of the camp (invest, transfer).
func _open_popup(body: Control, width: float) -> void:
	body.custom_minimum_size = Vector2(width, 0)
	_invest_panel = UiKit.panel(body)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_invest_panel)
	_invest_panel.tree_exited.connect(center.queue_free)
	add_child(center)
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
		var show := UiKit.button("Show camp [Esc]", func() -> void: _toggle_hidden())
		show.name = "CampShowButton"
		show.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		show.grow_horizontal = Control.GROW_DIRECTION_BOTH
		show.grow_vertical = Control.GROW_DIRECTION_BEGIN
		show.offset_bottom = -20
		add_child(show)
		show.grab_focus()
