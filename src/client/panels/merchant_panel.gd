class_name MerchantPanel
extends VBoxContainer
## Merchant: buy Items with the Party's shared Gold (keys 1-4), then say
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
	add_child(UiKit.label(str(encounter["name"]), "title"))
	add_child(UiKit.para(str(encounter["greeting"])))
	add_child(UiKit.label("Party Gold: %d" % int(view["gold"]), "heading", UiKit.ACCENT))
	for i in _stock.size():
		add_child(_row(app, i, _stock[i]))
	var slots: Array = screen.room_view().get("slots", [])
	var ready_names: Array[String] = []
	for slot in encounter["ready"]:
		ready_names.append(str(slots[int(slot)]["owner_name"]) if int(slot) < slots.size() else "?")
	add_child(UiKit.label("Done shopping: %s" % (", ".join(ready_names) if not ready_names.is_empty() else "nobody yet"), "dim"))
	var actions := UiKit.hbox(10)
	var done := UiKit.button("Waiting for the others..." if _ready else "Done shopping [R]",
			func() -> void: app.send({"type": "ready"}), true)
	done.disabled = _ready
	done.set_meta("focus_id", "ready")
	actions.add_child(done)
	_countdown = UiKit.label("", "heading")
	actions.add_child(_countdown)
	add_child(actions)
	tick(screen, app)
	app.hint("merchant")


func tick(_screen: MatchScreen, app: ClientApp) -> void:
	_countdown.text = "Shop closes in %ds" % ceili(app.seconds_left(_deadline))


func handle_key(_screen: MatchScreen, app: ClientApp, key: int) -> bool:
	if key == KEY_R and not _ready:
		app.send({"type": "ready"})
		return true
	var index := key - KEY_1
	if index >= 0 and index < _stock.size():
		app.send({"type": "buy", "item": _stock[index]["item"]})
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
	var buy := UiKit.button(label, func() -> void: app.send({"type": "buy", "item": entry["item"]}))
	buy.disabled = not entry["affordable"]
	buy.set_meta("focus_id", "buy_" + str(entry["item"]))
	row.add_child(buy)
	return UiKit.panel(row, "CardPanel")
