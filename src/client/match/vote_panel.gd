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
	add_theme_constant_override("separation", 8)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vote: Dictionary = view["vote"]
	_options = vote["options"]
	_deadline = vote["deadline"]
	var me := screen.your_slot()
	_voted = vote["voted_slots"].has(me)
	var solo := ClientApp.is_story_view(view)
	add_child(UiKit.para("Choose your path" if solo else "Layer %d of %d: choose the next path" % [int(vote["layer"]), int(view["layers_total"])], "title"))
	add_child(UiKit.para("Choose one path." if solo else "Every player has one vote; AI characters never vote. The most votes wins and a tie is broken at random.", "dim"))
	var option_scroll := ScrollContainer.new()
	option_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	option_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	option_scroll.custom_minimum_size = Vector2(0, 150)
	var option_stack := UiKit.hbox(12)
	option_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	option_scroll.add_child(option_stack)
	add_child(option_scroll)
	if _options.is_empty():
		option_stack.add_child(UiKit.para("No routes available.", "dim"))
	else:
		# Routes sit side by side as equal cards, like a map fork. Server order is
		# kept: the first card is the recommended one and keys 1-3 follow the cards
		# left to right.
		for i in range(_options.size()):
			option_stack.add_child(_route_card(screen, app, _options[i], i == 0))
	var timer_row := UiKit.hbox(10)
	if not solo:
		timer_row.add_child(_ready_status(screen, view, vote))
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


func _route_card(screen: MatchScreen, app: ClientApp, option: Dictionary, featured: bool) -> Control:
	var box := _option_body(screen, app, option, featured)
	var index := int(option["index"])
	var solo := ClientApp.is_story_view(screen.match_view())
	var mine: bool = screen.get_meta("my_vote_%d" % int(screen.match_view()["layer"]), -1) == index
	box.add_child(_vote_button(screen, app, option, mine, solo, "primary" if featured else "secondary"))
	var card := UiKit.panel(box, "HighlightPanel" if mine else "CardPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.0
	card.custom_minimum_size = Vector2(210, 0)
	return card


func _option_body(screen: MatchScreen, app: ClientApp, option: Dictionary, featured: bool) -> VBoxContainer:
	var full := true
	var box := UiKit.vbox(6)
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var head := UiKit.hbox(6)
	head.add_child(Icons.rect(str(TYPE_ICONS.get(str(option["type"]), "info")), Icons.size_for_scale(app.settings.text_scale)))
	head.add_child(UiKit.badge(UiText.type_tag(option["type"]), UiKit.ACCENT))
	head.add_child(UiKit.label(UiText.type_label(option["type"]), "dim"))
	if featured:
		head.add_child(UiKit.badge("Recommended", UiKit.ACCENT))
	box.add_child(head)
	var name := UiKit.pixel_label(str(option["name"]), "heading")
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name)
	if full:
		box.add_child(_art_strip(screen, app))
	var hint_text := str(option.get("hint", ""))
	if full:
		var hint_label := UiKit.para(hint_text)
		hint_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(hint_label)
		var rewards := UiKit.flow(5)
		for reward in [["exp", "EXP"], ["gold", "Gold"], ["items", "Items"]]:
			var chip := UiKit.hbox(3)
			chip.add_child(Icons.rect(str(reward[0]), Icons.size_for_scale(app.settings.text_scale)))
			chip.add_child(UiKit.label(str(reward[1]), "small"))
			rewards.add_child(UiKit.panel(chip, "CompactPanel"))
		box.add_child(rewards)
	var solo := ClientApp.is_story_view(screen.match_view())
	if not solo:
		var voters: Array = option.get("voters", [])
		var tally := UiKit.flow(4)
		tally.add_child(UiKit.label("Votes: %d" % voters.size(), "body" if not voters.is_empty() else "dim"))
		for slot in voters:
			tally.add_child(UiKit.badge(_voter_name(screen, int(slot)), UiKit.ALLY))
		box.add_child(tally)
	return box


func _vote_button(screen: MatchScreen, app: ClientApp, option: Dictionary, mine: bool, solo: bool, kind: String) -> Button:
	var index := int(option["index"])
	var text := ("Chosen" if mine else "Choose this path [%d]" % (index + 1)) if solo \
		else ("Your vote" if mine else "Vote for this path [%d]" % (index + 1))
	var button := UiKit.button(text, func() -> void: _vote(screen, app, index), false, "selected" if mine else kind)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.tooltip_text = str(option["name"])
	UiKit.disable(button, _voted, UiText.WHY["voted"])
	button.set_meta("focus_id", "vote_%d" % index)
	return button


func _art_strip(screen: MatchScreen, app: ClientApp) -> Control:
	var layer := int(screen.match_view().get("layer", 1))
	var path := "res://assets/backgrounds/%s.png" % ("cave" if layer >= 4 else "forest")
	var art := TextureRect.new()
	art.texture = load(path)
	art.custom_minimum_size = Vector2(0, 44)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return art


func _ready_status(screen: MatchScreen, view: Dictionary, vote: Dictionary) -> Control:
	var human_count := 0
	for character in view.get("party", []):
		if character.get("controller") == "human" and (not view.get("story", false) or int(character["slot"]) == 0):
			human_count += 1
	var ready: int = vote.get("voted_slots", []).size()
	var row := UiKit.hbox(8)
	row.custom_minimum_size = Vector2(150, 0)
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(UiKit.label("%d of %d ready" % [mini(ready, human_count), human_count], "heading"))
	var segments := UiKit.hbox(3)
	for i in range(human_count):
		var segment := ColorRect.new()
		segment.color = UiKit.GOOD if i < ready else UiKit.SLATE
		segment.custom_minimum_size = Vector2(20, 10)
		segments.add_child(segment)
	row.add_child(segments)
	return row


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
