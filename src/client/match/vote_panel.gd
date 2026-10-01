class_name VotePanel
extends VBoxContainer
## Path Voting: the 2-3 route options with their Encounter type, a live
## tally of who voted for which path, and the time left. Keys 1-3 vote.

var _options: Array = []
var _deadline: Variant = null
var _countdown: Label
var _bar: ProgressBar
var _voted := false
const TYPE_ICONS := {
	"combat": "combat", "elite": "elite", "merchant": "merchant", "rest": "rest",
	"treasure": "treasure", "story": "story", "class": "class_trial", "class_trial": "class_trial",
	"boss": "boss", "choice": "story",
}


func build(screen: MatchScreen, app: ClientApp, view: Dictionary) -> void:
	add_theme_constant_override("separation", 12)
	var vote: Dictionary = view["vote"]
	_options = vote["options"]
	_deadline = vote["deadline"]
	var me := screen.your_slot()
	_voted = vote["voted_slots"].has(me)
	var solo := ClientApp.is_story_view(view)
	add_child(UiKit.para("Choose your path" if solo else "Layer %d of %d: choose the next path" % [int(vote["layer"]), int(view["layers_total"])], "title"))
	add_child(UiKit.para("Choose one path." if solo else "Every player has one vote; AI characters never vote. The most votes wins and a tie is broken at random.", "dim"))
	var timer_row := UiKit.hbox(10)
	_countdown = UiKit.label("", "heading")
	timer_row.add_child(_countdown)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.max_value = maxf(1.0, float(vote.get("seconds", 20.0)))
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.custom_minimum_size = Vector2(0, 14)
	timer_row.add_child(_bar)
	if not view.get("story", false):
		add_child(timer_row)
	if not solo:
		add_child(UiKit.para(_voter_status(screen, view, vote)))
	if _options.is_empty():
		add_child(UiKit.para("No routes available.", "dim"))
	else:
		# First server-ordered route is featured with full detail; the rest
		# stay in server order as compact alternatives. Keys 1-3 still follow
		# that same server order so the featured card is always [1].
		add_child(_featured_card(screen, app, _options[0]))
		if _options.size() > 1:
			add_child(UiKit.label("Alternatives", "dim"))
			var alt_row := UiKit.flow(12)
			for i in range(1, _options.size()):
				alt_row.add_child(_compact_card(screen, app, _options[i]))
			add_child(alt_row)
	tick(screen, app)
	if not solo:
		app.hint("vote")


func tick(screen: MatchScreen, app: ClientApp) -> void:
	if _deadline == null or float(_deadline) < 0.0:
		return
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


func _featured_card(screen: MatchScreen, app: ClientApp, option: Dictionary) -> Control:
	var box := _option_body(screen, app, option, true)
	var index := int(option["index"])
	var solo := ClientApp.is_story_view(screen.match_view())
	var mine: bool = screen.get_meta("my_vote_%d" % int(screen.match_view()["layer"]), -1) == index
	box.add_child(_vote_button(screen, app, option, mine, solo, "primary"))
	var card := UiKit.panel(box, "HighlightPanel" if mine else "CardPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(250, 230)
	return card


func _compact_card(screen: MatchScreen, app: ClientApp, option: Dictionary) -> Control:
	var box := _option_body(screen, app, option, false)
	var index := int(option["index"])
	var solo := ClientApp.is_story_view(screen.match_view())
	var mine: bool = screen.get_meta("my_vote_%d" % int(screen.match_view()["layer"]), -1) == index
	box.add_child(_vote_button(screen, app, option, mine, solo, "secondary"))
	var card := UiKit.panel(box, "CompactHighlightPanel" if mine else "CompactPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(220, 0)
	return card


func _option_body(screen: MatchScreen, app: ClientApp, option: Dictionary, full: bool) -> VBoxContainer:
	var box := UiKit.vbox(6)
	var head := UiKit.hbox(6)
	head.add_child(Icons.rect(str(TYPE_ICONS.get(str(option["type"]), "info")), Icons.size_for_scale(app.settings.text_scale)))
	head.add_child(UiKit.badge(UiText.type_tag(option["type"]), UiKit.ACCENT))
	head.add_child(UiKit.label(UiText.type_label(option["type"]), "dim"))
	if full:
		head.add_child(UiKit.badge("Featured", UiKit.ACCENT))
	box.add_child(head)
	box.add_child(UiKit.para(str(option["name"]), "heading"))
	var hint_text := str(option.get("hint", ""))
	if full:
		box.add_child(UiKit.para(hint_text))
		box.add_child(UiKit.para(str(UiText.TYPE_HELP.get(option["type"], "")), "dim"))
	elif not hint_text.is_empty():
		box.add_child(UiKit.para(hint_text, "dim"))
	box.add_child(UiKit.spacer())
	var solo := ClientApp.is_story_view(screen.match_view())
	if not solo:
		var voters: Array = option.get("voters", [])
		var tally := UiKit.flow(4)
		tally.add_child(UiKit.label("Votes: %d" % voters.size(), "heading" if not voters.is_empty() else "dim"))
		for slot in voters:
			tally.add_child(UiKit.badge(_voter_name(screen, int(slot)), UiKit.ALLY))
		box.add_child(tally)
	return box


func _vote_button(screen: MatchScreen, app: ClientApp, option: Dictionary, mine: bool, solo: bool, kind: String) -> Button:
	var index := int(option["index"])
	var text := ("Chosen" if mine else "[%d] Choose this path" % (index + 1)) if solo \
		else ("Your vote" if mine else "[%d] Vote for this path" % (index + 1))
	var button := UiKit.button(text, func() -> void: _vote(screen, app, index), false, "selected" if mine else kind)
	UiKit.disable(button, _voted, UiText.WHY["voted"])
	button.set_meta("focus_id", "vote_%d" % index)
	return button


func _vote(screen: MatchScreen, app: ClientApp, index: int) -> void:
	screen.set_meta("my_vote_%d" % int(screen.match_view()["layer"]), index)
	app.send({"type": "vote", "option": index})


static func _voter_name(screen: MatchScreen, slot: int) -> String:
	var slots: Array = screen.room_view().get("slots", [])
	if slot < slots.size() and not str(slots[slot].get("owner_name", "")).is_empty():
		return str(slots[slot]["owner_name"])
	return screen.name_of("p%d" % slot)


static func _voter_status(screen: MatchScreen, view: Dictionary, vote: Dictionary) -> String:
	var voted: Array[String] = []
	var waiting: Array[String] = []
	var slots: Array = screen.room_view().get("slots", [])
	for character in view["party"]:
		if view.get("story", false) and int(character["slot"]) != 0:
			continue
		if character["controller"] != "human":
			continue
		var slot := int(character["slot"])
		var who := str(slots[slot]["owner_name"]) if slot < slots.size() else str(character["name"])
		(voted if vote["voted_slots"].has(slot) else waiting).append(who)
	var total := voted.size() + waiting.size()
	var text := "Ready %d of %d." % [voted.size(), total]
	if not waiting.is_empty():
		text += " Waiting: %s." % ", ".join(waiting)
	return text
