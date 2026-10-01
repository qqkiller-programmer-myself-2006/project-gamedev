class_name MerchantPanel
extends VBoxContainer
## Merchant: buy Items with your character's own Gold (keys 1-4), then say
## you are done [R]. The shop closes when every player is done.

var _stock: Array = []
var _deadline: Variant = null
var _countdown: Label
var _ready := false


func build(screen: MatchScreen, app: ClientApp, view: Dictionary) -> void:
	add_theme_constant_override("separation", 10)
	var encounter: Dictionary = view["encounter"]
	_stock = encounter["stock"]
	_deadline = encounter["deadline"]
	_ready = encounter["you_are_ready"]
	add_child(Icons.with_text("merchant", str(encounter["name"]), "title", app.settings.text_scale))
	add_child(UiKit.para(str(encounter["greeting"])))
	add_child(Icons.with_text("gold", "Party Gold: %d" % int(view["gold"]), "heading", app.settings.text_scale, UiKit.ACCENT))
	for i in _stock.size():
		add_child(_row(app, i, _stock[i]))
	var slots: Array = screen.room_view().get("slots", [])
	var ready_names: Array[String] = []
	for slot in encounter["ready"]:
		ready_names.append(str(slots[int(slot)]["owner_name"]) if int(slot) < slots.size() else "?")
	add_child(UiKit.label("Done shopping: %s" % (", ".join(ready_names) if not ready_names.is_empty() else "nobody yet"), "dim"))
	var actions := UiKit.flow(10)
	var done := UiKit.primary("Waiting for the others..." if _ready else "Done shopping [R]",
			func() -> void: app.send({"type": "ready"}))
	Icons.apply_to_button(done, "ready", app.settings.text_scale)
	UiKit.disable(done, _ready, UiText.WHY["ready"])
	done.set_meta("focus_id", "ready")
	actions.add_child(done)
	_countdown = UiKit.label("", "heading")
	actions.add_child(_countdown)
	add_child(actions)
	tick(screen, app)
	app.hint("merchant")


func tick(_screen: MatchScreen, app: ClientApp) -> void:
	if not ClientApp.has_timer(_deadline):
		_countdown.text = ""
		return
	_countdown.text = "Shop closes in %ds" % ceili(app.seconds_left(_deadline))


func handle_key(_screen: MatchScreen, app: ClientApp, key: int) -> bool:
	if key == KEY_R and not _ready:
		app.send({"type": "ready"})
		return true
	var index := key - KEY_1
	if index >= 0 and index < _stock.size():
		_request_buy(app, _stock[index])
		return true
	return false


func _row(app: ClientApp, index: int, entry: Dictionary) -> Control:
	var row := UiKit.hbox(10)
	var text := UiKit.vbox(2)
	text.add_child(UiKit.label("%s  (%d left)" % [entry["name"], int(entry["remaining"])], "heading"))
	text.add_child(UiKit.para(str(entry["description"]), "dim"))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var label := "[%d] Buy for %d Gold" % [index + 1, int(entry["price"])]
	if int(entry["remaining"]) <= 0:
		label = "Sold out"
	elif not entry["affordable"]:
		label = "Need %d Gold" % int(entry["price"])
	var buy := UiKit.button(label, func() -> void: _request_buy(app, entry))
	Icons.apply_to_button(buy, "gold", app.settings.text_scale)
	if int(entry["remaining"]) <= 0:
		UiKit.disable(buy, true, UiText.WHY["sold_out"])
	else:
		UiKit.disable(buy, not entry["affordable"], UiText.WHY["need_gold"] % int(entry["price"]))
	buy.set_meta("focus_id", "buy_" + str(entry["item"]))
	row.add_child(buy)
	return UiKit.panel(row, "CardPanel")


func _request_buy(app: ClientApp, entry: Dictionary) -> void:
	if int(entry.get("remaining", 0)) <= 0:
		app.toast(UiText.WHY["sold_out"])
		return
	var price := int(entry.get("price", 0))
	if not bool(entry.get("affordable", false)):
		app.toast(UiText.WHY["need_gold"] % price)
		return
	var item_id := str(entry.get("item", ""))
	app.confirm("buy_item", func() -> void: app.send({"type": "buy", "item": item_id}),
			[str(entry.get("name", UiText.item_name(item_id))), price])
