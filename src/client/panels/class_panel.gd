class_name ClassPanel
extends VBoxContainer
## Class Encounter: the Challenge (a trial fight shown with CombatPanel),
## then the offer every Classless character may accept [Y] or decline [N].

var _combat: CombatPanel = null
var _offer: Dictionary = {}
var _countdown: Label


func build(screen: MatchScreen, app: ClientApp, view: Dictionary) -> void:
	add_theme_constant_override("separation", 10)
	var encounter: Dictionary = view["encounter"]
	var info: Dictionary = encounter["class_info"]
	add_child(UiKit.label("Class Encounter: %s" % info["name"], "heading", UiKit.ACCENT))
	if encounter["stage"] == "challenge":
		add_child(UiKit.para(str(encounter["intro"]), "dim"))
		var trial: Dictionary = encounter["trial"]
		add_child(UiKit.para("Challenge: beat %s within %d rounds (round %d of %d). Nobody can fall in a Challenge." % [
				screen.name_of("e0"), int(trial["round_limit"]), int(trial["round"]), int(trial["round_limit"])]))
		var skills: Array[String] = []
		for skill in info.get("skills", []):
			skills.append(str(skill["name"]))
		add_child(UiKit.para("Pass to be offered: %s (%s) with %s." % [info["name"], info["role"], ", ".join(skills)], "dim"))
		_combat = CombatPanel.new()
		add_child(_combat)
		_combat.build(screen, app, view, trial)
		return
	add_child(UiKit.para(str(encounter.get("outcome_text", ""))))
	add_child(class_card(info))
	_offer = encounter.get("offer", {})
	if _offer.is_empty():
		return
	if _offer["you_can_decide"]:
		var row := UiKit.hbox(10)
		row.add_child(UiKit.label("Take the %s Class?" % info["name"], "heading"))
		var accept := UiKit.button("Accept [Y]", func() -> void: app.send({"type": "class_choice", "accept": true}), true)
		accept.set_meta("focus_id", "accept")
		row.add_child(accept)
		var decline := UiKit.button("Decline [N]", func() -> void: app.send({"type": "class_choice", "accept": false}), true)
		decline.set_meta("focus_id", "decline")
		row.add_child(decline)
		add_child(row)
		add_child(UiKit.para("Declining keeps you Classless; you can take a Class at a later Class Encounter. Silence counts as declining.", "dim"))
		app.hint("class_offer")
	elif not _offer["eligible"].has(screen.your_slot()):
		add_child(UiKit.label("Your character already has a Class.", "dim"))
	_countdown = UiKit.label("", "heading")
	add_child(_countdown)
	for slot in _offer["eligible"]:
		var key := str(int(slot))
		var status := "deciding..."
		if _offer["decisions"].has(key):
			status = "takes the Class" if _offer["decisions"][key] else "stays Classless"
		add_child(UiKit.label("%s: %s" % [screen.name_of("p%d" % int(slot)), status]))
	tick(screen, app)


func tick(screen: MatchScreen, app: ClientApp) -> void:
	if _combat != null:
		_combat.tick(screen, app)
	elif _countdown != null and not _offer.is_empty():
		var left := app.seconds_left(_offer["deadline"])
		_countdown.text = "Offer closes in %ds" % ceili(left)
		if _offer["you_can_decide"]:
			screen.warn_if_short(_offer["deadline"], left)


func handle_key(screen: MatchScreen, app: ClientApp, key: int) -> bool:
	if _combat != null:
		return _combat.handle_key(screen, app, key)
	if not _offer.is_empty() and _offer["you_can_decide"]:
		if key == KEY_Y:
			app.send({"type": "class_choice", "accept": true})
			return true
		if key == KEY_N:
			app.send({"type": "class_choice", "accept": false})
			return true
	return false


## Name, role, description, stats and Skills of a Class (the tooltip text,
## always visible so keyboard players can read it too).
static func class_card(info: Dictionary) -> Control:
	var box := UiKit.vbox(4)
	var head := UiKit.hbox(8)
	head.add_child(UiKit.label(str(info["name"]), "heading"))
	head.add_child(UiKit.badge(str(info["role"]), UiKit.ACCENT))
	box.add_child(head)
	box.add_child(UiKit.para(str(info["description"])))
	var stats: Dictionary = info.get("stats", {})
	box.add_child(UiKit.label("HP %d  ATK %d  DEF %d  MAG %d  RES %d  SPD %d" % [int(stats.get("max_hp", 0)),
			int(stats.get("atk", 0)), int(stats.get("def", 0)), int(stats.get("mag", 0)), int(stats.get("res", 0)),
			int(stats.get("spd", 0))], "dim"))
	for skill in info.get("skills", []):
		box.add_child(UiKit.para("Skill - %s: %s" % [skill["name"], skill["description"]]))
	var card := UiKit.panel(box, "CardPanel")
	card.tooltip_text = str(info["description"])
	return card
