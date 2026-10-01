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
var _last_countdown_color := Color.TRANSPARENT
var _region: Label
var _encounter_label: Label
var _encounter_icon: TextureRect
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
var _content: Dictionary = {}
var _backdrop: BattleBackdrop
const SLOTS := ["helmet", "chest", "legs", "boots", "weapon", "charm1", "charm2", "charm3"]
const ATTRIBUTES := ["str", "dex", "con", "int", "fth", "cha", "lck"]
const PERCENT_STATS := ["crit", "crit_damage", "block", "block_reduction", "dodge", "aggro", "lifesteal", "status_resist"]
const COLUMN_ICONS := {"Shop": "merchant", "Crafting": "rest", "Inventory": "items", "Equipment": "armor"}
const TAB_ICONS := {"Stash": "items", "Shop": "merchant", "Craft": "rest", "Inventory": "items", "Abilities": "skill"}


static func tab_width_for_scale(text_scale: float) -> float:
	return 116.0 * maxf(1.0, text_scale)

func setup(screen: MatchScreen, app: ClientApp) -> void:
	_screen = screen
	_app = app
	var content_file := FileAccess.open("res://content/forest.json", FileAccess.READ)
	if content_file != null:
		var parsed = JSON.parse_string(content_file.get_as_text())
		if parsed is Dictionary:
			_content = parsed
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop = BattleBackdrop.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)
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
	var encounter_row := UiKit.hbox(6)
	_encounter_icon = Icons.rect("merchant", Icons.size_for_scale(_app.settings.text_scale))
	encounter_row.add_child(_encounter_icon)
	encounter_row.add_child(_encounter_label)
	var encounter_box := UiKit.panel(encounter_row, "HudPanel")
	encounter_box.name = "EncounterBox"
	encounter_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	encounter_box.position = Vector2(112, 12)
	add_child(encounter_box)
	_workspace = ScrollContainer.new()
	_workspace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_workspace.offset_left = 24
	_workspace.offset_right = -24
	_workspace.offset_top = 64
	_workspace.offset_bottom = -66
	(_workspace as ScrollContainer).horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	(_workspace as ScrollContainer).vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_workspace)
	_columns = UiKit.hbox(10)
	_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	# Dock the compact, scrollable Tip in the footer beside Ready.
	tips = UiKit.vbox(6)
	tips.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	tips.grow_horizontal = Control.GROW_DIRECTION_END
	tips.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tips.offset_left = 24
	tips.offset_right = 24
	tips.offset_bottom = -6
	add_child(tips)
	_menu_panel = screen.build_corner_menu(self)

func build(view: Dictionary, encounter: Dictionary) -> void:
	_encounter = encounter
	var layer := str(view.get("layer", 1))
	_backdrop.set_backdrop(str(_content.get("journey", {}).get("backdrops", {}).get(layer, "forest")))
	var viewport_width := get_viewport_rect().size.x if is_inside_tree() else 1280.0
	_columns.custom_minimum_size.x = maxf(0.0, viewport_width - 48.0) * maxf(1.0, _app.settings.text_scale)
	if _inspect < 0: _inspect = maxi(0, _screen.your_slot())
	# T34: build() tears down _columns/_bottom, so remember scroll positions
	# and the focused control first and restore them after the rebuild.
	var camp_state := _snapshot_camp_state()
	_region.text = "%s (%d/%d)" % [UiText.region_of(view), int(view.get("layer", 0)), int(view.get("layers_total", 5))]
	var merchant := str(encounter.get("kind", "")) == "merchant"
	_encounter_icon.texture = Icons.texture("merchant") if merchant else Icons.texture("rest")
	_encounter_label.text = "\"%s\"" % str(encounter.get("name", "Merchant" if merchant else "Rest")).replace("\"", "")
	_stock = encounter.get("stock", []) if merchant else []
	_ready = bool(encounter.get("you_are_ready", false))
	_deadline = encounter.get("deadline", encounter.get("ends_at"))
	_build_columns(view, merchant)
	_build_bottom()
	_restore_camp_state(camp_state)
	tick()
	_app.hint("merchant" if merchant else "rest")


## T34: the rebuild above frees every ScrollContainer and search box, so
## capture them here (called before _build_columns) and hand the snapshot to
## _restore_camp_state after the rebuild. Scrolls are keyed by stable
## pre-order traversal index because the nodes themselves are freed.
func _snapshot_camp_state() -> Dictionary:
	var snap := {"scrolls": [], "focus_id": "", "edit_text": "", "caret": -1}
	if is_instance_valid(_columns):
		var scrolled: Array = []
		_collect_scrolls(_columns, scrolled)
		for scroll in scrolled:
			(snap["scrolls"] as Array).append({"h": (scroll as ScrollContainer).scroll_horizontal,
					"v": (scroll as ScrollContainer).scroll_vertical})
	var focused: Control = null
	var viewport := get_viewport()
	if viewport != null:
		focused = viewport.gui_get_focus_owner()
	if focused != null and is_instance_valid(focused) and is_ancestor_of(focused):
		if focused.has_meta("focus_id"):
			snap["focus_id"] = str(focused.get_meta("focus_id"))
		if focused is LineEdit:
			snap["edit_text"] = focused.text
			snap["caret"] = focused.caret_column
		elif focused is TextEdit:
			snap["edit_text"] = focused.text
			snap["caret"] = (focused as TextEdit).get_caret_column((focused as TextEdit).get_caret_line())
	return snap


func _restore_camp_state(snap: Dictionary) -> void:
	if snap.is_empty() or not is_instance_valid(_columns):
		return
	# Restore focus/text first: setting LineEdit text emits text_changed,
	# which repopulates the list body, so scrolls must be applied after.
	var focus_id := str(snap.get("focus_id", ""))
	if not focus_id.is_empty():
		var target := _find_by_focus_id(self, focus_id)
		if target != null and is_instance_valid(target):
			if target is LineEdit and not str(snap.get("edit_text", "")).is_empty():
				# Search text already survives via _left_search/_inventory_search;
				# re-apply it (and the caret) so typing continues where it left off.
				# Block signals: the matching filter closure would needlessly
				# rebuild the list body (and reset its scroll) for the same text.
				(target as LineEdit).set_block_signals(true)
				(target as LineEdit).text = str(snap["edit_text"])
				(target as LineEdit).caret_column = clampi(int(snap.get("caret", -1)), 0, (target as LineEdit).text.length())
				(target as LineEdit).set_block_signals(false)
			elif target is TextEdit and snap.has("edit_text"):
				(target as TextEdit).set_block_signals(true)
				(target as TextEdit).text = str(snap["edit_text"])
				(target as TextEdit).set_block_signals(false)
			if target is Control and (target as Control).focus_mode != Control.FOCUS_NONE and (target as Control).is_inside_tree():
				(target as Control).grab_focus()
				(target as Control).call_deferred("grab_focus")
	var fresh: Array = []
	_collect_scrolls(_columns, fresh)
	var wanted: Array = snap.get("scrolls", [])
	for i in mini(wanted.size(), fresh.size()):
		var entry: Dictionary = wanted[i]
		var scroll: ScrollContainer = fresh[i]
		scroll.scroll_horizontal = int(entry.get("h", 0))
		scroll.scroll_vertical = int(entry.get("v", 0))
		# Layout settles after build; re-apply once ready so positions stick.
		scroll.set_deferred("scroll_horizontal", int(entry.get("h", 0)))
		scroll.set_deferred("scroll_vertical", int(entry.get("v", 0)))


## T34: shortcut suppression predicate. CodeEdit extends TextEdit,
## so `is TextEdit` covers all three text editors.
static func _is_text_editor(node: Node) -> bool:
	return node is LineEdit or node is TextEdit


func _collect_scrolls(node: Node, out: Array) -> void:
	if node is ScrollContainer:
		out.append(node)
	for child in node.get_children():
		_collect_scrolls(child, out)


func _find_by_focus_id(node: Node, focus_id: String) -> Node:
	if node.has_meta("focus_id") and str(node.get_meta("focus_id")) == focus_id:
		return node
	for child in node.get_children():
		var found := _find_by_focus_id(child, focus_id)
		if found != null:
			return found
	return null


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
	var heading := UiKit.hbox(6)
	heading.add_child(Icons.rect(str(COLUMN_ICONS.get(title, "items")), Icons.size_for_scale(_app.settings.text_scale)))
	var heading_label := UiKit.pixel_label(title, "heading")
	heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_child(heading_label)
	var tag := UiKit.panel(heading, "TitleTag")
	tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
	var tab_width := tab_width_for_scale(_app.settings.text_scale)
	tabs.custom_minimum_size = Vector2(tab_width, 0)
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
			elif label == "Inventory":
				_inventory_mode = "inventory"
				_close_invest_panel()
			elif label == "Abilities":
				_inventory_mode = "abilities"
			_screen.refresh(_app, true)
			if label == "Abilities":
				_show_abilities(view))
		Icons.apply_to_button(button, str(TAB_ICONS.get(label, "items")), _app.settings.text_scale)
		button.custom_minimum_size = Vector2(tab_width, 52)
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
		var slot_row := UiKit.hbox(3)
		slot_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_row.add_child(Icons.rect("consumable", Icons.size_for_scale(_app.settings.text_scale)))
		var slot_label := UiKit.pixel_label("Consumable\n" + consumable_text, "tiny")
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_row.add_child(slot_label)
		var slot := UiKit.panel(slot_row, "HudCard")
		slot.custom_minimum_size = Vector2(tab_width, 64)
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

func _search_box(text: String, on_change: Callable, focus_id: String) -> LineEdit:
	var search := LineEdit.new()
	search.placeholder_text = "Search..."
	search.text = text
	search.clear_button_enabled = true
	search.set_meta("focus_id", focus_id)
	search.text_changed.connect(on_change)
	return search

## A short line telling the player what to do when a list is empty.
func _empty(key: String, query: String = "") -> Label:
	var text: String = UiText.EMPTY["search"] % query if not query.strip_edges().is_empty() else UiText.EMPTY[key]
	return UiKit.para(text, "small", UiKit.TEXT_DIM)

func _left_panel(view: Dictionary, merchant: bool) -> Control:
	var root := UiKit.vbox(6)
	var body := UiKit.vbox(5)
	root.add_child(_search_box(_left_search, func(value: String) -> void:
		_left_search = value
		_populate_left(view, merchant, body), "camp_search_left"))
	root.add_child(_scroll_body(body))
	_populate_left(view, merchant, body)
	return root


func _populate_left(view: Dictionary, merchant: bool, body: VBoxContainer) -> void:
	UiKit.clear(body)
	if _left_mode == "stash": _build_stash(view, body)
	elif merchant: _build_shop(view, body)
	else: _build_crafting(body)

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
		text.add_child(Icons.with_text("gold", "%d Gold   (%d left)" % [int(entry.get("price", 0)), int(entry.get("remaining", 0))], "small", _app.settings.text_scale, UiKit.ACCENT))
		card.get_child(0).add_child(text)
		var actions := UiKit.vbox(2)
		var affordable := int(_character(view, _acting_slot()).get("gold", 0)) >= int(entry.get("price", 0)) if _screen.room_view().get("story", false) else bool(entry.get("affordable", int(view.get("gold", 0)) >= int(entry.get("price", 0))))
		# The state is in the button text itself (not only the tooltip), so it
		# is readable with keyboard focus and without hovering.
		var buy_label := "Buy"
		if int(entry.get("remaining", 0)) <= 0:
			buy_label = "Sold out"
		elif not affordable:
			buy_label = "Need %d Gold" % int(entry.get("price", 0))
		var buy := _button(buy_label, func() -> void: _app.send({"type": "buy", "slot": _acting_slot(), "item": entry.get("item", "")}))
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
	# Materials are visible text (have/need with OK/NEED words), not only the
	# Craft button's hover tooltip, so keyboard users can tell what is missing.
	var mats := UiKit.pixel_label(_materials_text(recipe), "tiny", UiKit.TEXT_DIM)
	mats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.add_child(mats)
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


## Visible materials summary for a recipe row: "have/need name [OK|NEED]".
## Words carry the state so colour is never the only cue.
func _materials_text(recipe: Dictionary) -> String:
	var materials: Array = recipe.get("materials", [])
	if materials.is_empty():
		return "No materials needed"
	var parts: Array[String] = []
	for material in materials:
		var need := int(material.get("need", 0))
		var have := int(material.get("have", 0))
		parts.append("%d/%d %s %s" % [have, need, str(material.get("name", material.get("item", ""))),
				"OK" if have >= need else "NEED"])
	return "Mats: " + ", ".join(parts)

func _build_stash(view: Dictionary, body: VBoxContainer) -> void:
	for entry in view.get("inventory", []):
		if _matches(str(entry.get("name", "")), _left_search): body.add_child(_item_row(entry, false))
	if body.get_child_count() == 0:
		body.add_child(_empty("stash", _left_search))

func _inventory_panel(view: Dictionary) -> Control:
	var root := UiKit.vbox(6)
	var body := UiKit.vbox(5)
	root.add_child(_search_box(_inventory_search, func(value: String) -> void:
		_inventory_search = value
		_populate_inventory(view, body), "camp_search_inventory"))
	root.add_child(_scroll_body(body))
	_populate_inventory(view, body)
	var you := _character(view, _acting_slot())
	var gold := int(you.get("gold", view.get("gold", 0)))
	var gold_row := UiKit.hbox(4)
	gold_row.add_child(Icons.with_text("gold", UiText.gold(gold), "heading", _app.settings.text_scale, UiKit.ACCENT))
	gold_row.add_child(UiKit.spacer())
	var transfer := _button("Transfer Gold", func() -> void: _open_gold_picker())
	Icons.apply_to_button(transfer, "transfer", _app.settings.text_scale)
	UiKit.disable(transfer, not you.has("gold"), UiText.WHY["transfer_unavailable"])
	gold_row.add_child(transfer)
	root.add_child(UiKit.panel(gold_row, "HudCard"))
	return root


func _populate_inventory(view: Dictionary, body: VBoxContainer) -> void:
	UiKit.clear(body)
	for entry in view.get("inventory", []):
		if _matches(str(entry.get("name", "")), _inventory_search): body.add_child(_item_row(entry, true))
	if body.get_child_count() == 0:
		body.add_child(_empty("inventory", _inventory_search))

func _item_row(entry: Dictionary, with_transfer: bool) -> Control:
	var card := _row_card()
	var text := UiKit.vbox(1)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var item_name := UiKit.pixel_label("%s (x%d)" % [str(entry.get("name", entry.get("item", ""))), int(entry.get("count", 1))], "small")
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(item_name)
	card.get_child(0).add_child(text)
	var actions := UiKit.vbox(2)
	if with_transfer:
		var transfer := _button("Transfer", func() -> void: _open_item_picker(str(entry.get("item", ""))))
		Icons.apply_to_button(transfer, "transfer", _app.settings.text_scale)
		actions.add_child(transfer)
	if str(entry.get("kind", "")) == "gear":
		var equip := _button("Equip", func() -> void: _app.send({"type": "equip", "slot": _acting_slot(), "item": entry.get("item", "")}))
		UiKit.disable(equip, not _can_manage_inspected(), UiText.WHY["equip_not_yours"])
		actions.add_child(equip)
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
	# At Extra-large text the 32 px icons and slot names need two wider cells
	# per row; the stat sheet below already scrolls, so the extra rows are safe.
	grid.columns = 2 if _app.settings.text_scale >= 1.4 else 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	var gear: Dictionary = character.get("gear", {})
	for slot in SLOTS:
		var cell := UiKit.vbox(1)
		cell.custom_minimum_size = Vector2(0, 82 if _app.settings.text_scale >= 1.4 else 70)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var worn: Dictionary = gear.get(slot, {})
		var slot_row := UiKit.hbox(2)
		slot_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var large_text := _app.settings.text_scale >= 1.4
		# At large text the two-column cell is too narrow for icon + label, so the label wins.
		if not large_text:
			slot_row.add_child(Icons.rect(_slot_icon(slot), Icons.size_for_scale(_app.settings.text_scale)))
		var slot_label := UiKit.pixel_label(_slot_name(slot) + "\n" + (str(worn.get("name", "Empty")) if not worn.is_empty() else "Empty"), "tiny",
				UiKit.TEXT if not worn.is_empty() else UiKit.TEXT_DIM)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		slot_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.custom_minimum_size = Vector2(0, 44)
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_row.add_child(slot_label)
		cell.add_child(slot_row)
		var controls := UiKit.hbox(2)
		controls.alignment = BoxContainer.ALIGNMENT_END
		if not worn.is_empty():
			var off := _button("–", func() -> void: _app.send({"type": "unequip", "slot": _acting_slot(), "gear_slot": slot}))
			off.tooltip_text = "Unequip"
			UiKit.disable(off, not _can_manage_inspected(), UiText.WHY["equip_not_yours"])
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
	stats.add_child(_stat("HP", "%d/%d" % [int(character.get("hp", 0)), int(character.get("max_hp", 0))], "hp"))
	stats.add_child(_stat("Energy", str(character.get("energy", 0)), "energy"))
	stats.add_child(_stat("Level", str(int(character.get("level", 1))), "level"))
	stats.add_child(_stat("EXP", "%d/%d" % [int(character.get("exp", 0)), int(character.get("exp_next", 0))], "exp"))
	var separator_one := Control.new()
	separator_one.custom_minimum_size = Vector2(0, 8)
	stats.add_child(separator_one)
	for key in ATTRIBUTES:
		stats.add_child(_stat(key.to_upper(), str(int(attrs[key])) if attrs.has(key) else "\u2014", key))
	var separator_two := Control.new()
	separator_two.custom_minimum_size = Vector2(0, 8)
	stats.add_child(separator_two)
	stats.add_child(_stat("Initiative", str(int(derived["initiative"])) if derived.has("initiative") else "\u2014"))
	stats.add_child(_stat("Crit Chance", _percent(derived.get("crit", character.get("crit"))), "crit"))
	stats.add_child(_stat("Crit Damage", _percent(derived.get("crit_damage"))))
	stats.add_child(_stat("Block Chance", _percent(derived.get("block"))))
	stats.add_child(_stat("Block Damage Reduction", _percent(derived.get("block_reduction"))))
	stats.add_child(_stat("Dodge Chance", _percent(derived.get("dodge")), "dodge"))
	stats.add_child(_stat("Aggro", _percent(derived.get("aggro"))))
	stats.add_child(_stat("Lifesteal", _percent(derived.get("lifesteal"))))
	stats.add_child(_stat("Energy Regen", str(int(derived["energy_regen"])) if derived.has("energy_regen") else "\u2014"))
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

func _stat(label: String, value: String, icon_name: String = "") -> Control:
	var line := UiKit.hbox(4)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not icon_name.is_empty():
		line.add_child(Icons.rect(icon_name, Icons.size_for_scale(_app.settings.text_scale)))
	var text := UiKit.pixel_label(label + ": " + value, "small")
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.clip_text = false
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_child(text)
	return line

func _build_bottom() -> void:
	UiKit.clear(_bottom)
	var story := ClientApp.is_story_view(_screen.room_view())
	var ready_text := "Ready [R]" if story else "Ready (%d/%d) [R]" % [int(_encounter.get("ready", []).size()), maxi(1, int(_encounter.get("humans", 1)))]
	var ready := UiKit.primary(ready_text, func() -> void: _app.send({"type": "ready"}), false)
	Icons.apply_to_button(ready, "ready", _app.settings.text_scale)
	UiKit.disable(ready, _ready, UiText.WHY["ready"])
	ready.custom_minimum_size = Vector2(280, 44)
	ready.set_meta("focus_id", "ready")
	_bottom.add_child(ready)
	_countdown = UiKit.pixel_label("", "heading")
	_countdown.add_theme_color_override("font_outline_color", UiKit.BG)
	_countdown.add_theme_constant_override("outline_size", 5)
	_bottom.add_child(_countdown)

func tick() -> void:
	if _countdown == null or not ClientApp.has_timer(_deadline):
		if _countdown != null:
			_countdown.text = ""
		return
	var left := _app.seconds_left(_deadline)
	_countdown.text = "%ds" % ceili(left)
	var color := UiKit.WARN if left <= 5.0 else UiKit.TEXT
	if color != _last_countdown_color:
		_countdown.add_theme_color_override("font_color", color)
		_last_countdown_color = color

func handle_key(key: int) -> bool:
	var viewport := get_viewport()
	var focused: Control = viewport.gui_get_focus_owner() if viewport != null else null
	# T34: while a text editor has focus, typing must never fire camp
	# shortcuts (r = Ready, 1-9 = buy/craft). Swallow everything except Esc.
	if _is_text_editor(focused):
		if key == KEY_ESCAPE:
			focused.release_focus()
			focus_default()
		return true
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
		var stock_item: Dictionary = _stock[index]
		var item_name := str(stock_item.get("name", stock_item.get("item", "Item")))
		var price := int(stock_item.get("price", 0))
		_app.confirm_custom("Confirm purchase?", "Spend %d Gold on %s?" % [price, item_name], "Buy %s" % item_name,
			func() -> void: _app.send({"type": "buy", "slot": _acting_slot(), "item": stock_item.get("item", "")}))
		return true
	if str(_encounter.get("kind", "")) == "rest" and index >= 0 and index < mini(9, _recipes.size()):
		_app.send({"type": "craft", "slot": _acting_slot(), "recipe": _recipes[index].get("recipe", "")})
		return true
	return false

func reset() -> void:
	_inspect = -1
	_category = ""
	_left_search = ""
	_inventory_search = ""
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

func _can_manage_inspected() -> bool:
	return bool(_screen.room_view().get("story", false)) or _inspect == _screen.your_slot()

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


func _slot_icon(slot: String) -> String:
	if slot == "weapon":
		return "weapon"
	if slot.begins_with("charm"):
		return "accessory"
	return "armor"

func _percent(value: Variant) -> String:
	if value == null:
		return "\u2014"
	return "%d%%" % roundi(float(value) * 100.0)

func _show_info(data: Dictionary) -> void:
	_close_invest_panel()
	var item_id := str(data.get("item", ""))
	var item: Dictionary = _content.get("items", {}).get(item_id, {}).duplicate(true)
	for key in data:
		item[key] = data[key]
	var body := UiKit.vbox(8)
	body.add_child(UiKit.pixel_label(str(item.get("name", item_id.capitalize())), "heading", UiKit.ACCENT))
	var kind := str(item.get("kind", "Item")).capitalize()
	var category := str(item.get("category", ""))
	body.add_child(UiKit.label(kind + (" | " + category if not category.is_empty() else ""), "dim"))
	var description := str(item.get("description", ""))
	if not description.is_empty():
		body.add_child(UiKit.para(description, "small", UiKit.TEXT, 400))
	if item.has("count"):
		body.add_child(UiKit.pixel_label("Quantity: %d" % int(item["count"]), "small"))
	if item.has("price"):
		body.add_child(UiKit.pixel_label("Price: %d Gold" % int(item["price"]), "small"))
	if item.has("remaining"):
		body.add_child(UiKit.pixel_label("Merchant stock: %d" % int(item["remaining"]), "small"))
	var gear: Dictionary = item.get("gear", {})
	if not gear.is_empty():
		body.add_child(UiKit.pixel_label("Slot: %s" % _slot_name(str(gear.get("slot", ""))), "small"))
		var bonuses: Dictionary = gear.get("stats", {})
		if not bonuses.is_empty():
			body.add_child(UiKit.pixel_label("Bonuses", "small", UiKit.ACCENT))
			var bonus_keys := bonuses.keys()
			bonus_keys.sort()
			for key in bonus_keys:
				body.add_child(UiKit.pixel_label("%s %s" % [_bonus_text(str(key), bonuses[key]), str(key).to_upper()], "small"))
	_add_use_stats(body, item.get("use", {}))
	body.add_child(UiKit.button("Close [Esc]", _close_invest_panel, false, "primary"))
	_open_popup(body, 440)
	_invest_panel.name = "ItemInfoPanel"


func _add_use_stats(body: VBoxContainer, use: Dictionary) -> void:
	if use.is_empty():
		return
	body.add_child(UiKit.pixel_label("Use", "small", UiKit.ACCENT))
	if use.has("target"):
		body.add_child(UiKit.pixel_label("Target: %s" % str(use["target"]).replace("_", " ").capitalize(), "small"))
	if use.has("heal"):
		body.add_child(UiKit.pixel_label("Healing: %d HP" % int(use["heal"]), "small"))
	if use.has("revive_ratio"):
		body.add_child(UiKit.pixel_label("Revive HP: %s" % _percent(use["revive_ratio"]), "small"))
	var damage: Dictionary = use.get("damage", {})
	if not damage.is_empty():
		body.add_child(UiKit.pixel_label("Damage: %d %s" % [int(damage.get("amount", 0)), str(damage.get("element", "")).capitalize()], "small"))


func _bonus_text(key: String, value: Variant) -> String:
	if PERCENT_STATS.has(key):
		var amount := roundi(float(value) * 100.0)
		return ("+" if amount >= 0 else "") + str(amount) + "%"
	var amount := int(value)
	return ("+" if amount >= 0 else "") + str(amount)


func _show_abilities(view: Dictionary) -> void:
	_close_invest_panel()
	var character := _character(view, _inspect)
	var class_id := str(character.get("class", "classless"))
	var class_data: Dictionary = _content.get("classes", {}).get(class_id, {})
	var body := UiKit.vbox(8)
	body.add_child(UiKit.pixel_label("%s Skills" % str(class_data.get("name", class_id.capitalize())), "heading", UiKit.ACCENT))
	var list := UiKit.vbox(6)
	var skill_ids: Array = class_data.get("skills", [])
	if skill_ids.is_empty():
		list.add_child(UiKit.para("This character has no Class Skills.", "small", UiKit.TEXT_DIM, 420))
	else:
		for skill_id in skill_ids:
			var skill: Dictionary = _content.get("skills", {}).get(str(skill_id), {})
			var card_body := UiKit.vbox(3)
			card_body.add_child(UiKit.pixel_label(str(skill.get("name", skill_id)), "small", UiKit.ACCENT))
			card_body.add_child(UiKit.pixel_label("Energy: %d | Cooldown: %d turn(s)" % [int(skill.get("energy", 0)), int(skill.get("cooldown", 0))], "tiny"))
			card_body.add_child(UiKit.para(str(skill.get("description", "")), "small", UiKit.TEXT, 410))
			list.add_child(UiKit.panel(card_body, "HudCard"))
	var scroll := _scroll_body(list)
	scroll.custom_minimum_size = Vector2(0, 360)
	body.add_child(scroll)
	body.add_child(UiKit.button("Close [Esc]", _close_invest_panel, false, "primary"))
	_open_popup(body, 470)
	_invest_panel.name = "AbilitiesPanel"

func _open_item_picker(item: String) -> void:
	_open_transfer_picker("transfer_item", item)

func _open_gold_picker() -> void:
	_open_transfer_picker("transfer_gold")

func _open_transfer_picker(kind: String, item: String = "") -> void:
	_close_invest_panel()
	var body := UiKit.vbox(6)
	body.add_child(Icons.with_text("transfer", "Transfer from %s" % _character(_screen.match_view(), _acting_slot()).get("name", ""), "heading", _app.settings.text_scale, UiKit.ACCENT))
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
