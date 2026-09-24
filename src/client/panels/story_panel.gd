class_name StoryPanel
extends VBoxContainer
## Story Event: the text, an optional choice decided by vote (keys 1-2),
## the outcome with any Story Clue found, then Continue [Enter].

var _vote: Dictionary = {}
var _deadline: Variant = null
var _countdown: Label
var _stage := ""
var _ready := false


func build(screen: MatchScreen, app: ClientApp, view: Dictionary) -> void:
	add_theme_constant_override("separation", 12)
	var encounter: Dictionary = view["encounter"]
	_stage = encounter["stage"]
	_deadline = encounter["deadline"]
	add_child(UiKit.label(str(encounter["title"]), "title", UiKit.ACCENT))
	add_child(UiKit.para(str(encounter["text"])))
	if _stage == "choosing":
		_vote = encounter["vote"]
		var me := screen.your_slot()
		var voted: bool = _vote["voted_slots"].has(me)
		add_child(UiKit.label("What does the Party do? (one vote each; ties are broken at random)", "heading"))
		for option in _vote["options"]:
			var index := int(option["index"])
			var box := UiKit.hbox(10)
			var text := UiKit.vbox(2)
			text.add_child(UiKit.para(str(option["name"]), "heading"))
			text.add_child(UiKit.para(str(option["hint"]), "dim"))
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_child(text)
			var button := UiKit.button("[%d] Vote" % (index + 1), func() -> void: app.send({"type": "vote", "option": index}))
			button.disabled = voted
			button.set_meta("focus_id", "story_vote_%d" % index)
			box.add_child(button)
			add_child(UiKit.panel(box, "CardPanel"))
		add_child(UiKit.label("Voted so far: %d" % _vote["voted_slots"].size(), "dim"))
	else:
		var outcome: Dictionary = encounter.get("outcome", {})
		_ready = encounter.get("you_are_ready", false)
		add_child(UiKit.panel(UiKit.para(str(outcome.get("text", "")), "heading"), "HighlightPanel"))
		var clue = outcome.get("clue")
		if clue != null:
			add_child(UiKit.para("Story Clue found - %s: %s" % [clue["title"], clue["text"]], "body", UiKit.ACCENT))
		var extras: Array[String] = []
		if int(outcome.get("gold", 0)) > 0:
			extras.append("+%d Gold" % int(outcome["gold"]))
		for item in outcome.get("items", {}):
			extras.append("+%d %s" % [int(outcome["items"][item]), str(item).replace("_", " ").capitalize()])
		if int(outcome.get("exp", 0)) > 0:
			extras.append("+%d EXP each" % int(outcome["exp"]))
		if outcome.get("healed", false):
			extras.append("the Party recovers some HP")
		if not extras.is_empty():
			add_child(UiKit.para(", ".join(extras), "heading"))
		var go := UiKit.button("Waiting for the others..." if _ready else "Continue [Enter]",
				func() -> void: app.send({"type": "ready"}), true)
		go.disabled = _ready
		go.set_meta("focus_id", "continue")
		add_child(go)
	_countdown = UiKit.label("", "dim")
	add_child(_countdown)
	tick(screen, app)


func tick(_screen: MatchScreen, app: ClientApp) -> void:
	var left := ceili(app.seconds_left(_deadline))
	_countdown.text = ("Vote closes in %ds" if _stage == "choosing" else "The journey continues in %ds") % left


func handle_key(_screen: MatchScreen, app: ClientApp, key: int) -> bool:
	if _stage == "choosing":
		var index := key - KEY_1
		if index >= 0 and index < _vote.get("options", []).size():
			app.send({"type": "vote", "option": index})
			return true
	elif (key == KEY_ENTER or key == KEY_KP_ENTER or key == KEY_R) and not _ready:
		app.send({"type": "ready"})
		return true
	return false
