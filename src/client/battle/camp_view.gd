class_name CampView
extends Control
## Merchant and Rest as a three-column camp screen after
## docs/references/aac_rogue/08: the shop (or the rest) on the left, the
## Party's shared bag and Gold in the middle, and a character's stat sheet
## on the right, with "Ready (x/y)" at the bottom. Crafting, Equipment and
## Gold transfer from the reference are not part of this game.
##
## Keys: 1-9 buy, R ready (Merchant).

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
	_deadline = encounter.get("deadline") if merchant else encounter.get("ends_at")
	_columns.add_child(_column(str(encounter.get("name", "Merchant" if merchant else "Rest")),
			_shop(view) if merchant else _rest(encounter)))
	_columns.add_child(_column("Inventory", _inventory(view)))
	_columns.add_child(_column("Party", _sheet(view)))
	_build_bottom(merchant)
	tick()
	if merchant:
		_app.hint("merchant")


func tick() -> void:
	if _countdown == null or not is_instance_valid(_countdown) or _deadline == null:
		return
	var left := ceili(_app.seconds_left(_deadline))
	if str(_encounter.get("kind", "")) == "merchant":
		_countdown.text = "Shop closes in %ds" % left
	else:
		_countdown.text = "The journey continues in %ds" % left


func handle_key(key: int) -> bool:
	if str(_encounter.get("kind", "")) != "merchant":
		return false
	if key == KEY_R and not _ready:
		_app.send({"type": "ready"})
		return true
	var index := key - KEY_1
	if index >= 0 and index < _stock.size():
		_app.send({"type": "buy", "item": _stock[index]["item"]})
		return true
	return false


## Back to showing your own character's sheet (a new camp starts).
func reset() -> void:
	_inspect = -1


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


func _rest(encounter: Dictionary) -> Control:
	var list := UiKit.vbox(6)
	list.add_child(UiKit.para(str(encounter.get("text", ""))))
	for entry in encounter.get("healed", []):
		var line := UiKit.hbox(8)
		line.add_child(UiKit.pixel_label(_screen.name_of("p%d" % int(entry["slot"])), "body"))
		line.add_child(UiKit.spacer())
		line.add_child(UiKit.pixel_label("+%d HP  (now %d)" % [int(entry["amount"]), int(entry["hp"])], "body", UiKit.GOOD))
		list.add_child(UiKit.panel(line, "HudCard"))
	return list


func _inventory(view: Dictionary) -> Control:
	var list := UiKit.vbox(6)
	var items: Array = view.get("inventory", [])
	if items.is_empty():
		list.add_child(UiKit.para("The shared bag is empty.", "small", UiKit.TEXT_DIM))
	for entry in items:
		var row := UiKit.vbox(0)
		var head := UiKit.hbox(8)
		head.add_child(UiKit.pixel_label(str(entry["name"]), "heading"))
		head.add_child(UiKit.spacer())
		head.add_child(UiKit.pixel_label("x%d" % int(entry["count"]), "heading", UiKit.ACCENT))
		row.add_child(head)
		row.add_child(UiKit.para(str(entry["description"]), "small", UiKit.TEXT_DIM))
		list.add_child(UiKit.panel(row, "HudCard"))
	var gold := UiKit.hbox(8)
	gold.add_child(UiKit.pixel_label("Party Gold", "heading"))
	gold.add_child(UiKit.spacer())
	gold.add_child(UiKit.pixel_label("%d" % int(view.get("gold", 0)), "heading", UiKit.ACCENT))
	list.add_child(UiKit.panel(gold, "HudCard"))
	return list


func _sheet(view: Dictionary) -> Control:
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
		var owner := "you" if int(character["slot"]) == _screen.your_slot() else ("AI" if character["controller"] == "ai" else "player")
		list.add_child(UiKit.pixel_label("%s (%s)" % [character["name"], owner], "heading", UiKit.ACCENT))
		list.add_child(UiKit.pixel_label("%s  Lvl %d" % [character["class_name"], int(character["level"])], "body"))
		var exp_next := int(character.get("exp_next", 0))
		list.add_child(UiKit.stat_bar(int(character["hp"]), int(character["max_hp"]), UiKit.BAR_HP,
				"HP %d/%d" % [int(character["hp"]), int(character["max_hp"])], 22, "body"))
		var rows := [
			["EXP", "%d / %d" % [int(character["exp"]), exp_next] if exp_next > 0 else "MAX"],
			["Energy", "max %d (starts at 1 each Combat)" % int(character.get("energy_max", 6))],
			["ATK", str(int(character["atk"]))], ["DEF", str(int(character["def"]))],
			["MAG", str(int(character["mag"]))], ["RES", str(int(character["res"]))],
			["SPD", str(int(character["spd"]))], ["Crit", "%d%%" % roundi(float(character.get("crit", 0.0)) * 100.0)],
		]
		for row in rows:
			var line := UiKit.hbox(8)
			line.add_child(UiKit.pixel_label(str(row[0]) + ":", "body", UiKit.TEXT_DIM))
			line.add_child(UiKit.pixel_label(str(row[1]), "body"))
			list.add_child(line)
	return list


func _build_bottom(merchant: bool) -> void:
	UiKit.clear(_bottom)
	var row := UiKit.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if merchant:
		var humans := 0
		for slot in _screen.room_view().get("slots", []):
			if slot.get("controller", "") == "human":
				humans += 1
		var count: int = _encounter.get("ready", []).size()
		var ready := _hud_button("Ready (%d/%d) [R]" % [count, maxi(1, humans)], func() -> void: _app.send({"type": "ready"}))
		ready.disabled = _ready
		ready.custom_minimum_size = Vector2(300, 52)
		ready.set_meta("focus_id", "ready")
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
