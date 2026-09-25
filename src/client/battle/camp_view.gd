class_name CampView
extends Control
## Merchant and Rest as a three-column camp screen after
## docs/references/aac_rogue/08-10: the shop (Merchant) or the crafting
## recipes (Rest) on the left, the Party's shared bag and Gold in the middle,
## and a character's eight gear slots and stat sheet on the right, with
## "Ready (x/y)" at the bottom. Gold is shared by the whole Party, so there
## is no Gold transfer; the bag is shared too, so "Equip" is how an item
## moves to your character (ADR-0011). Every change is a command to the
## server; the screen only shows the snapshot.
##
## Keys: 1-9 buy (Merchant) or craft (Rest), R ready.

## Where one-time tips appear while the camp is on screen.
var tips: VBoxContainer

var _screen: MatchScreen
var _app: ClientApp
var _encounter: Dictionary = {}
var _stock: Array = []
var _ready := false
var _deadline: Variant = null
var _countdown: Label
## Slot whose stat sheet is shown (your own by default).
var _inspect := -1
## Rest: recipe category shown ("" = all) and the bag item being inspected.
var _category := ""
var _inspect_item := ""
## Rest: recipes currently listed (keys 1-9 craft them).
var _recipes: Array = []

var _region: Label
var _columns: HBoxContainer
var _bottom: VBoxContainer


func setup(screen: MatchScreen, app: ClientApp) -> void:
	_screen = screen
	_app = app
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := BattleBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var corner := UiKit.hbox(6)
	corner.position = Vector2(10, 10)
	for entry in [["Clues [C]", screen.toggle_clues], ["Settings [F2]", app.open_settings]]:
		var button := Button.new()
		button.text = entry[0]
		button.theme_type_variation = "HudButton"
		button.add_theme_font_size_override("font_size", int(UiKit.SIZES["small"] * app.settings.text_scale))
		button.pressed.connect(entry[1])
		corner.add_child(button)
	add_child(corner)

	_region = UiKit.pixel_label("", "title")
	_region.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_region.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_region.offset_right = -14
	_region.offset_top = 6
	_region.add_theme_color_override("font_outline_color", Color.BLACK)
	_region.add_theme_constant_override("outline_size", 6)
	add_child(_region)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 76)
	_columns = UiKit.hbox(18)
	margin.add_child(_columns)
	add_child(margin)

	_bottom = UiKit.vbox(4)
	_bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bottom.offset_bottom = -12
	add_child(_bottom)

	tips = UiKit.vbox(6)
	tips.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tips.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tips.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tips.offset_right = -10
	tips.offset_bottom = -10
	add_child(tips)


func build(view: Dictionary, encounter: Dictionary) -> void:
	_encounter = encounter
	if _inspect < 0:
		_inspect = maxi(0, _screen.your_slot())
	_region.text = "Forest (%d/%d)" % [int(view.get("layer", 0)), int(view.get("layers_total", 5))]
	UiKit.clear(_columns)
	var merchant := str(encounter.get("kind", "")) == "merchant"
	_stock = encounter.get("stock", []) if merchant else []
	_ready = bool(encounter.get("you_are_ready", false))
	_deadline = encounter.get("deadline", encounter.get("ends_at"))
	_columns.add_child(_column(str(encounter.get("name", "Merchant")) if merchant else "Crafting",
			_shop(view) if merchant else _crafting(encounter)))
	_columns.add_child(_column("Shared Inventory", _inventory(view, not merchant)))
	_columns.add_child(_column("Equipment & Stats", _sheet(view, not merchant)))
	_build_bottom()
	tick()
	_app.hint("merchant" if merchant else "rest")


func tick() -> void:
	if _countdown == null or not is_instance_valid(_countdown) or _deadline == null:
		return
	var left := ceili(_app.seconds_left(_deadline))
	if str(_encounter.get("kind", "")) == "merchant":
		_countdown.text = "Shop closes in %ds" % left
	else:
		_countdown.text = "Camp breaks in %ds" % left


func handle_key(key: int) -> bool:
	if key == KEY_R and not _ready:
		_app.send({"type": "ready"})
		return true
	var index := key - KEY_1
	if str(_encounter.get("kind", "")) == "merchant":
		if index >= 0 and index < _stock.size():
			_app.send({"type": "buy", "item": _stock[index]["item"]})
			return true
	elif index >= 0 and index < mini(9, _recipes.size()):
		_app.send({"type": "craft", "recipe": _recipes[index]["recipe"]})
		return true
	return false


## Back to showing your own character's sheet (a new camp starts).
func reset() -> void:
	_inspect = -1
	_category = ""
	_inspect_item = ""


## Focuses the first Buy button, else Ready.
func focus_default() -> void:
	if not UiKit.focus_first(_columns):
		UiKit.focus_first(_bottom)


# --- Columns ------------------------------------------------------------------

func _column(title: String, body: Control) -> Control:
	var column := UiKit.vbox(8)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var heading := UiKit.pixel_label(title, "title")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_outline_color", Color.BLACK)
	heading.add_theme_constant_override("outline_size", 6)
	column.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var panel := UiKit.panel(scroll, "HudPanel")
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(panel)
	return column


func _shop(view: Dictionary) -> Control:
	var list := UiKit.vbox(6)
	list.add_child(UiKit.para(str(_encounter.get("greeting", "")), "small", UiKit.TEXT_DIM))
	for i in _stock.size():
		var entry: Dictionary = _stock[i]
		var row := UiKit.hbox(8)
		var text := UiKit.vbox(0)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(UiKit.pixel_label(str(entry["name"]), "heading"))
		text.add_child(UiKit.pixel_label("%d Gold  -  %d left" % [int(entry["price"]), int(entry["remaining"])], "small", UiKit.ACCENT))
		row.add_child(text)
		var buttons := UiKit.vbox(4)
		var label := "[%d] Buy" % (i + 1)
		if int(entry["remaining"]) <= 0:
			label = "Sold out"
		elif not entry["affordable"]:
			label = "Need %d" % int(entry["price"])
		var buy := _hud_button(label, func() -> void: _app.send({"type": "buy", "item": entry["item"]}))
		buy.disabled = not entry["affordable"] or int(entry["remaining"]) <= 0
		buy.set_meta("focus_id", "buy_" + str(entry["item"]))
		buttons.add_child(buy)
		var inspect := UiKit.pixel_label("Inspect", "small", UiKit.TEXT_DIM)
		inspect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inspect.mouse_filter = Control.MOUSE_FILTER_STOP
		inspect.tooltip_text = str(entry["description"])
		buttons.add_child(inspect)
		row.add_child(buttons)
		var card := UiKit.panel(row, "HudCard")
		card.tooltip_text = str(entry["description"])
		list.add_child(card)
	return list


## Rest, left column: who healed, then the recipe catalogue with a
## category filter and a live material checklist per recipe.
func _crafting(encounter: Dictionary) -> Control:
	var list := UiKit.vbox(6)
	list.add_child(UiKit.para(str(encounter.get("text", "")), "small", UiKit.TEXT_DIM))
	var healed := []
	for entry in encounter.get("healed", []):
		if int(entry["amount"]) > 0:
			healed.append("%s +%d" % [_screen.name_of("p%d" % int(entry["slot"])), int(entry["amount"])])
	if not healed.is_empty():
		list.add_child(UiKit.para("Healed: " + ", ".join(healed) + " HP", "small", UiKit.GOOD))
	var filters := UiKit.flow(4)
	for category in [""] + Array(encounter.get("categories", [])):
		var pick := _hud_button("All" if category == "" else str(category), func() -> void:
			_category = category
			_screen.refresh(_app, true))
		pick.add_theme_font_size_override("font_size", int(UiKit.SIZES["small"] * _app.settings.text_scale))
		pick.set_meta("focus_id", "category_" + str(category))
		if category == _category:
			pick.add_theme_color_override("font_color", UiKit.ACCENT)
			pick.text = "[" + pick.text + "]"
		filters.add_child(pick)
	list.add_child(filters)
	_recipes = []
	for recipe in encounter.get("recipes", []):
		if _category.is_empty() or recipe["category"] == _category:
			_recipes.append(recipe)
	if _recipes.is_empty():
		list.add_child(UiKit.para("No recipes in this category.", "small", UiKit.TEXT_DIM))
	for i in _recipes.size():
		list.add_child(_recipe_card(_recipes[i], i))
	return list


func _recipe_card(recipe: Dictionary, index: int) -> Control:
	var box := UiKit.vbox(2)
	var head := UiKit.hbox(8)
	var title := UiKit.vbox(0)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_child(UiKit.pixel_label(str(recipe["name"]), "heading"))
	title.add_child(UiKit.pixel_label(str(recipe["category"]), "small", UiKit.ACCENT))
	head.add_child(title)
	var label := ("[%d] Craft" % (index + 1)) if index < 9 else "Craft"
	var craft := _hud_button(label, func() -> void: _app.send({"type": "craft", "recipe": recipe["recipe"]}))
	craft.disabled = not recipe["craftable"]
	craft.tooltip_text = str(recipe["description"])
	craft.set_meta("focus_id", "craft_" + str(recipe["recipe"]))
	head.add_child(craft)
	box.add_child(head)
	for material in recipe["materials"]:
		var enough := int(material["have"]) >= int(material["need"])
		box.add_child(UiKit.pixel_label("%s %s  %d/%d" % ["OK " if enough else "NEED", material["name"],
				int(material["have"]), int(material["need"])], "small", UiKit.GOOD if enough else UiKit.TEXT_DIM))
	var card := UiKit.panel(box, "HudCard")
	card.tooltip_text = str(recipe["description"])
	return card


## Middle column: the Party's shared bag. At a Rest, gear can be put on
## your character ([Equip]) and anything can be inspected.
func _inventory(view: Dictionary, rest: bool) -> Control:
	var list := UiKit.vbox(6)
	var items: Array = view.get("inventory", [])
	if items.is_empty():
		list.add_child(UiKit.para("The shared bag is empty.", "small", UiKit.TEXT_DIM))
	for entry in items:
		var row := UiKit.vbox(2)
		var head := UiKit.hbox(8)
		var name_box := UiKit.vbox(0)
		name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_box.add_child(UiKit.pixel_label(str(entry["name"]), "heading"))
		var kind := str(entry.get("kind", "consumable"))
		var sub := str(entry.get("category", ""))
		if kind == "gear":
			sub = "%s - %s slot" % [sub, str(entry.get("gear_slot", "")).capitalize()]
		if not sub.is_empty():
			name_box.add_child(UiKit.pixel_label(sub, "small", UiKit.TEXT_DIM))
		head.add_child(name_box)
		head.add_child(UiKit.pixel_label("x%d" % int(entry["count"]), "heading", UiKit.ACCENT))
		row.add_child(head)
		var actions := UiKit.hbox(6)
		if rest and kind == "gear":
			var equip := _hud_button("Equip", func() -> void: _app.send({"type": "equip", "item": entry["item"]}))
			equip.tooltip_text = "Put it on %s." % _screen.name_of("p%d" % _screen.your_slot())
			equip.set_meta("focus_id", "equip_" + str(entry["item"]))
			actions.add_child(equip)
		var inspecting := _inspect_item == str(entry["item"])
		var inspect := _hud_button("Hide" if inspecting else "Inspect", func() -> void:
			_inspect_item = "" if inspecting else str(entry["item"])
			_screen.refresh(_app, true))
		inspect.set_meta("focus_id", "inspect_item_" + str(entry["item"]))
		actions.add_child(inspect)
		row.add_child(actions)
		if inspecting:
			row.add_child(UiKit.para(str(entry["description"]), "small"))
			var uses := _recipes_using(str(entry["item"]))
			if not uses.is_empty():
				row.add_child(UiKit.para("Used in: " + ", ".join(uses), "small", UiKit.TEXT_DIM))
		var card := UiKit.panel(row, "HudCard")
		card.tooltip_text = str(entry["description"])
		list.add_child(card)
	var gold := UiKit.hbox(8)
	gold.add_child(UiKit.pixel_label("Party Gold (shared)", "heading"))
	gold.add_child(UiKit.spacer())
	gold.add_child(UiKit.pixel_label("%d" % int(view.get("gold", 0)), "heading", UiKit.ACCENT))
	list.add_child(UiKit.panel(gold, "HudCard"))
	return list


func _recipes_using(item: String) -> Array:
	var out := []
	for recipe in _encounter.get("recipes", []):
		for material in recipe["materials"]:
			if material["item"] == item:
				out.append(str(recipe["name"]))
	return out


## Right column: a character's gear grid and stat sheet. At a Rest your own
## character's gear can be taken off and stat points spent.
func _sheet(view: Dictionary, rest: bool) -> Control:
	var list := UiKit.vbox(6)
	var picker := UiKit.flow(4)
	var party: Array = view.get("party", [])
	for character in party:
		var slot := int(character["slot"])
		var pick := _hud_button(str(character["name"]), func() -> void:
			_inspect = slot
			_screen.refresh(_app, true))
		pick.add_theme_font_size_override("font_size", int(UiKit.SIZES["small"] * _app.settings.text_scale))
		pick.set_meta("focus_id", "inspect_%d" % slot)
		if slot == _inspect:
			pick.add_theme_color_override("font_color", UiKit.ACCENT)
		picker.add_child(pick)
	list.add_child(picker)
	for character in party:
		if int(character["slot"]) != _inspect:
			continue
		var mine := int(character["slot"]) == _screen.your_slot()
		var owner := "you" if mine else ("AI" if character["controller"] == "ai" else "player")
		list.add_child(UiKit.pixel_label("%s (%s)" % [character["name"], owner], "heading", UiKit.ACCENT))
		list.add_child(UiKit.pixel_label("%s  Lvl %d" % [character["class_name"], int(character["level"])], "body"))
		list.add_child(UiKit.stat_bar(int(character["hp"]), int(character["max_hp"]), UiKit.BAR_HP,
				"HP %d/%d" % [int(character["hp"]), int(character["max_hp"])], 22, "body"))
		list.add_child(_gear_grid(character, rest and mine))
		var points := int(character.get("points", 0))
		if rest and mine and points > 0:
			list.add_child(_invest_row(points))
		elif points > 0:
			list.add_child(UiKit.pixel_label("%d stat point(s) to spend at a Rest" % points, "small", UiKit.ACCENT))
		var exp_next := int(character.get("exp_next", 0))
		var rows := [
			["EXP", "%d / %d" % [int(character["exp"]), exp_next] if exp_next > 0 else "MAX"],
			["Energy", "max %d (starts at 1 each Combat)" % int(character.get("energy_max", 6))],
			["ATK", str(int(character["atk"]))], ["DEF", str(int(character["def"]))],
			["MAG", str(int(character["mag"]))], ["RES", str(int(character["res"]))],
			["SPD (Initiative)", str(int(character["spd"]))],
			["Crit", "%d%%" % roundi(float(character.get("crit", 0.0)) * 100.0)],
		]
		for row in rows:
			var line := UiKit.hbox(8)
			line.add_child(UiKit.pixel_label(str(row[0]) + ":", "body", UiKit.TEXT_DIM))
			line.add_child(UiKit.pixel_label(str(row[1]), "body"))
			list.add_child(line)
	return list


## Eight gear slots in two columns; your own worn gear can be taken off.
func _gear_grid(character: Dictionary, editable: bool) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	var gear: Dictionary = character.get("gear", {})
	var slots: Array = _encounter.get("gear_slots",
			["helmet", "chest", "legs", "boots", "weapon", "charm1", "charm2", "charm3"])
	for gear_slot in slots:
		var worn: Dictionary = gear.get(gear_slot, {})
		var cell := UiKit.vbox(0)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(UiKit.pixel_label(_slot_label(str(gear_slot)), "small", UiKit.TEXT_DIM))
		if worn.is_empty():
			cell.add_child(UiKit.pixel_label("empty", "small", UiKit.TEXT_DIM))
		elif editable:
			var off := _hud_button(str(worn["name"]), func() -> void:
				_app.send({"type": "unequip", "gear_slot": gear_slot}))
			off.tooltip_text = "%s\nClick to take it off (back to the shared bag)." % worn["description"]
			off.add_theme_font_size_override("font_size", int(UiKit.SIZES["small"] * _app.settings.text_scale))
			off.set_meta("focus_id", "unequip_" + str(gear_slot))
			cell.add_child(off)
		else:
			var name_label := UiKit.pixel_label(str(worn["name"]), "small")
			name_label.tooltip_text = str(worn["description"])
			name_label.mouse_filter = Control.MOUSE_FILTER_STOP
			cell.add_child(name_label)
		var box := UiKit.panel(cell, "HudCard")
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(box)
	return grid


func _invest_row(points: int) -> Control:
	var box := UiKit.vbox(4)
	box.add_child(UiKit.pixel_label("Invest Points (%d left)" % points, "body", UiKit.ACCENT))
	var row := UiKit.flow(4)
	var invest: Dictionary = _encounter.get("invest", {})
	for stat in invest:
		var stat_name := "Max HP" if stat == "max_hp" else str(stat).to_upper()
		var button := _hud_button("+%d %s" % [int(invest[stat]), stat_name], func() -> void:
			_app.send({"type": "invest", "stat": stat}))
		button.add_theme_font_size_override("font_size", int(UiKit.SIZES["small"] * _app.settings.text_scale))
		button.set_meta("focus_id", "invest_" + str(stat))
		row.add_child(button)
	box.add_child(row)
	return UiKit.panel(box, "HudCard")


static func _slot_label(gear_slot: String) -> String:
	if gear_slot.begins_with("charm"):
		return "Charm " + gear_slot.trim_prefix("charm")
	return gear_slot.capitalize()


func _build_bottom() -> void:
	UiKit.clear(_bottom)
	var row := UiKit.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var humans := int(_encounter.get("humans", 1))
	var count: int = _encounter.get("ready", []).size()
	var ready := _hud_button("Ready (%d/%d) [R]" % [count, maxi(1, humans)], func() -> void: _app.send({"type": "ready"}))
	ready.disabled = _ready
	ready.custom_minimum_size = Vector2(300, 52)
	ready.set_meta("focus_id", "ready")
	ready.tooltip_text = "The journey moves on when every player is Ready. AI characters never need to be."
	row.add_child(ready)
	_countdown = UiKit.pixel_label("", "heading")
	_countdown.add_theme_color_override("font_outline_color", Color.BLACK)
	_countdown.add_theme_constant_override("outline_size", 5)
	row.add_child(_countdown)
	_bottom.add_child(row)


func _hud_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = "HudButton"
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	return button
