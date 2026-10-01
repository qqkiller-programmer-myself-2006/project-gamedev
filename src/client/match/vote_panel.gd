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
	add_child(UiKit.para(Tr.t("Choose your path") if solo else Tr.t("Layer %d of %d: choose the next path" % [int(vote["layer"]), int(view["layers_total"])]), "heading"))
	add_child(UiKit.para(Tr.t("Choose one path.") if solo else Tr.t("Every player has one vote; AI characters never vote. The most votes wins and a tie is broken at random."), "dim"))
	var option_scroll := ScrollContainer.new()
	option_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	option_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	option_scroll.custom_minimum_size = Vector2(0, 150)
	var option_stack := UiKit.vbox(3)
	option_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_scroll.add_child(option_stack)
	add_child(option_scroll)
	if _options.is_empty():
		option_stack.add_child(UiKit.para(Tr.t("No routes available."), "dim"))
	else:
		# First server-ordered route is featured with full detail; the rest
		# stay in server order as compact alternatives. Keys 1-3 still follow
		# that same server order so the featured card is always [1].
		option_stack.add_child(_featured_card(screen, app, _options[0]))
		if _options.size() > 1:
			for i in range(1, _options.size()):
				option_stack.add_child(_compact_card(screen, app, _options[i]))
	var timer_row := UiKit.hbox(10)
	# This row stays after the independently scrolling route list. Keep it at
	# the bottom of the available panel height when the route details overflow.
	timer_row.size_flags_vertical = Control.SIZE_SHRINK_END
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
	_countdown.text = Tr.t("Vote closes in %ds" % ceili(left))
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
	var card := UiKit.panel(box, "HighlightPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 0)
	return card


func _compact_card(screen: MatchScreen, app: ClientApp, option: Dictionary) -> Control:
	var box := UiKit.vbox(4)
	var row := UiKit.hbox(8)
	row.add_child(Icons.rect(str(TYPE_ICONS.get(str(option["type"]), "info")), Icons.size_for_scale(app.settings.text_scale)))
	row.add_child(UiKit.badge(UiText.type_tag(option["type"]), UiKit.ACCENT))
	var index := int(option["index"])
	var solo := ClientApp.is_story_view(screen.match_view())
	var mine: bool = screen.get_meta("my_vote_%d" % int(screen.match_view()["layer"]), -1) == index
	row.add_child(_vote_button(screen, app, option, mine, solo, "secondary"))
	box.add_child(row)
	var detail := Tr.t("Other path: %s" % Tr.t(str(option["name"])))
	if not solo:
		var voters: Array = option.get("voters", [])
		var voter_names: Array[String] = []
		for slot in voters: voter_names.append(_voter_name(screen, int(slot)))
		detail += "  " + Tr.t("Votes: %d%s" % [voters.size(), " (%s)" % ", ".join(voter_names) if not voter_names.is_empty() else ""])
	var title := UiKit.para(detail, "body")
	title.tooltip_text = Tr.t(str(option.get("hint", "")))
	box.add_child(title)
	var card := UiKit.panel(box, "CompactHighlightPanel" if mine else "CompactPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 44)
	return card


func _option_body(screen: MatchScreen, app: ClientApp, option: Dictionary, full: bool) -> VBoxContainer:
	var box := UiKit.vbox(2)
	var head := UiKit.flow(6)
	head.add_child(Icons.rect(str(TYPE_ICONS.get(str(option["type"]), "info")), Icons.size_for_scale(app.settings.text_scale)))
	head.add_child(UiKit.badge(UiText.type_tag(option["type"]), UiKit.ACCENT))
	head.add_child(UiKit.label(UiText.type_label(option["type"]), "dim"))
	if full:
		head.add_child(UiKit.badge(Tr.t("Recommended"), UiKit.ACCENT))
	box.add_child(head)
	var name := UiKit.pixel_label(Tr.t(str(option["name"])), "heading")
	box.add_child(name)
	if full:
		box.add_child(_art_strip(screen, app))
	var hint_text := Tr.t(str(option.get("hint", "")))
	if full:
		box.add_child(UiKit.para(hint_text))
		var rewards := UiKit.flow(5)
		for reward in [["exp", "EXP"], ["gold", "Gold"], ["items", "Items"]]:
			var chip := UiKit.hbox(3)
			chip.add_child(Icons.rect(str(reward[0]), Icons.size_for_scale(app.settings.text_scale)))
			var reward_label := Tr.t("Gold") if str(reward[0]) == "gold" else Tr.t(str(reward[1]))
			chip.add_child(UiKit.label(reward_label, "small"))
			rewards.add_child(UiKit.panel(chip, "CompactPanel"))
		box.add_child(rewards)
	var solo := ClientApp.is_story_view(screen.match_view())
	if not solo:
		var voters: Array = option.get("voters", [])
		var tally := UiKit.flow(4)
		tally.add_child(UiKit.label(Tr.t("Votes: %d" % voters.size()), "heading" if not voters.is_empty() else "dim"))
		for slot in voters:
			tally.add_child(UiKit.badge(_voter_name(screen, int(slot)), UiKit.ALLY))
		box.add_child(tally)
	return box


func _vote_button(screen: MatchScreen, app: ClientApp, option: Dictionary, mine: bool, solo: bool, kind: String) -> Button:
	var index := int(option["index"])
	var text := Tr.t("Chosen") if mine and solo else Tr.t("Choose path [%d]" % (index + 1)) if solo \
		else Tr.t("Your vote") if mine else Tr.t("Vote for this path [%d]" % (index + 1))
	var button := UiKit.button(text, func() -> void: _vote(screen, app, index), false, "selected" if mine else kind)
	UiKit.disable(button, _voted, UiText.WHY["voted"])
	button.set_meta("focus_id", "vote_%d" % index)
	return button


func _art_strip(screen: MatchScreen, app: ClientApp) -> Control:
	var layer := int(screen.match_view().get("layer", 1))
	var path := "res://assets/backgrounds/%s.png" % ("cave" if layer >= 4 else "forest")
	var art := TextureRect.new()
	art.texture = load(path)
	art.custom_minimum_size = Vector2(0, 18)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.tooltip_text = Tr.t("Recommended route")
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
	row.add_child(UiKit.label(Tr.t("%d of %d ready" % [mini(ready, human_count), human_count]), "heading"))
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
	var text := Tr.t("Ready %d of %d." % [voted.size(), total])
	if not waiting.is_empty():
		text += " " + Tr.t("Waiting: %s." % ", ".join(waiting))
	return text
