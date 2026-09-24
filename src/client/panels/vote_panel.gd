class_name VotePanel
extends VBoxContainer
## Path Voting: the 2-3 route options with their Encounter type, who has
## voted, and the time left. Keys 1-3 vote.

var _options: Array = []
var _deadline: Variant = null
var _countdown: Label
var _bar: ProgressBar
var _voted := false


func build(screen: MatchScreen, app: ClientApp, view: Dictionary) -> void:
	add_theme_constant_override("separation", 12)
	var vote: Dictionary = view["vote"]
	_options = vote["options"]
	_deadline = vote["deadline"]
	var me := screen.your_slot()
	_voted = vote["voted_slots"].has(me)
	add_child(UiKit.para("Layer %d of %d: choose the next path" % [int(vote["layer"]), int(view["layers_total"])], "title"))
	add_child(UiKit.para("Every player has one vote; AI characters never vote. The most votes wins and a tie is broken at random.", "dim"))
	var row := UiKit.flow(12)
	for option in _options:
		row.add_child(_option_card(screen, app, option))
	add_child(row)
	add_child(UiKit.para(_voter_status(screen, view, vote)))
	var timer_row := UiKit.hbox(10)
	_countdown = UiKit.label("", "heading")
	timer_row.add_child(_countdown)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.max_value = maxf(1.0, float(vote.get("seconds", 20.0)))
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.custom_minimum_size = Vector2(0, 14)
	timer_row.add_child(_bar)
	add_child(timer_row)
	tick(screen, app)
	app.hint("vote")


func tick(screen: MatchScreen, app: ClientApp) -> void:
	var left := app.seconds_left(_deadline)
	_bar.value = left
	_countdown.text = "Vote closes in %ds%s" % [ceili(left), "  - hurry!" if left <= 5.0 else ""]
	if not _voted:
		screen.warn_if_short(_deadline, left)


func handle_key(screen: MatchScreen, app: ClientApp, key: int) -> bool:
	var index := key - KEY_1
	if index >= 0 and index < _options.size() and not _voted:
		_vote(screen, app, index)
		return true
	return false


func _option_card(screen: MatchScreen, app: ClientApp, option: Dictionary) -> Control:
	var index := int(option["index"])
	var box := UiKit.vbox(6)
	var head := UiKit.hbox(6)
	head.add_child(UiKit.badge(UiText.type_tag(option["type"]), UiKit.ACCENT))
	head.add_child(UiKit.label(UiText.type_label(option["type"]), "dim"))
	box.add_child(head)
	box.add_child(UiKit.para(str(option["name"]), "heading"))
	box.add_child(UiKit.para(str(option["hint"])))
	box.add_child(UiKit.para(str(UiText.TYPE_HELP.get(option["type"], "")), "dim"))
	box.add_child(UiKit.spacer())
	var mine: bool = screen.get_meta("my_vote_%d" % int(screen.match_view()["layer"]), -1) == index
	var text := "Your vote" if mine else ("[%d] Vote for this path" % (index + 1))
	var button := UiKit.button(text, func() -> void: _vote(screen, app, index))
	button.disabled = _voted
	button.set_meta("focus_id", "vote_%d" % index)
	box.add_child(button)
	var card := UiKit.panel(box, "HighlightPanel" if mine else "CardPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(250, 230)
	return card


func _vote(screen: MatchScreen, app: ClientApp, index: int) -> void:
	screen.set_meta("my_vote_%d" % int(screen.match_view()["layer"]), index)
	app.send({"type": "vote", "option": index})


static func _voter_status(screen: MatchScreen, view: Dictionary, vote: Dictionary) -> String:
	var voted: Array[String] = []
	var waiting: Array[String] = []
	var slots: Array = screen.room_view().get("slots", [])
	for character in view["party"]:
		if character["controller"] != "human":
			continue
		var slot := int(character["slot"])
		var who := str(slots[slot]["owner_name"]) if slot < slots.size() else str(character["name"])
		(voted if vote["voted_slots"].has(slot) else waiting).append(who)
	var text := "Voted: %s." % (", ".join(voted) if not voted.is_empty() else "nobody yet")
	if not waiting.is_empty():
		text += "  Waiting for: %s." % ", ".join(waiting)
	return text
