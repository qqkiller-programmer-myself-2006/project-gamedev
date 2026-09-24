class_name CombatPanel
extends VBoxContainer
## Turn-based combat (regular fights, Class Challenges and the Guardian
## Boss): enemies, turn order, whose turn it is, and - on your turn - the
## Attack / Skill / Defend / Item choices followed by valid targets only.
##
## Keys: A Attack, S Skill, D Defend, I Item, 1-9 pick from a list, Esc back.

var _combat: Dictionary = {}
var _me := ""
var _deadline: Variant = null
var _countdown: Label
## Buttons of the current list (targets, Skills or Items), in key order.
var _choices: Array[Callable] = []


## `combat` is the combat view (the Boss/Combat Encounter itself, or the
## trial inside a Class Encounter).
func build(screen: MatchScreen, app: ClientApp, view: Dictionary, combat: Dictionary = {}) -> void:
	add_theme_constant_override("separation", 10)
	var encounter: Dictionary = view.get("encounter", {})
	_combat = combat if not combat.is_empty() else encounter
	_me = "p%d" % screen.your_slot()
	var mode_key := "%d-%s-%s-%d" % [int(view.get("layer", 0)), str(view.get("phase")), _combat.get("actor", ""),
			int(_combat.get("round", 0))]
	if screen.combat_mode_key != mode_key:
		screen.combat_mode_key = mode_key
		screen.combat_mode = ""
	_deadline = _combat.get("deadline")

	if combat.is_empty():
		_header(screen, encounter)
	_build_enemies(screen)
	add_child(UiKit.para(_turn_order_text(screen), "dim"))
	if str(_combat.get("result", "")) != "":
		_build_result(screen)
	elif _combat.get("your_turn", false):
		_build_your_turn(screen, app, view)
	else:
		_build_waiting(screen)
	tick(screen, app)


func tick(screen: MatchScreen, app: ClientApp) -> void:
	if _countdown == null or _deadline == null:
		return
	var left := app.seconds_left(_deadline)
	if _combat.get("your_turn", false):
		_countdown.text = "%ds left to act%s" % [ceili(left), " - hurry! Time out means Defend." if left <= 5.0 else ""]
		screen.warn_if_short(_deadline, left)
	else:
		_countdown.text = "%ds" % ceili(left)


func handle_key(screen: MatchScreen, app: ClientApp, key: int) -> bool:
	if not _combat.get("your_turn", false):
		return false
	var choices: Dictionary = _combat.get("choices", {})
	match key:
		KEY_A:
			_set_mode(screen, "attack")
			return true
		KEY_S:
			if not choices.get("skills", {}).is_empty():
				_set_mode(screen, "skills")
			else:
				app.toast(UiText.error("skill_unavailable"))
			return true
		KEY_D:
			_send(app, {"action": "defend"})
			return true
		KEY_I:
			_set_mode(screen, "items")
			return true
		KEY_ESCAPE, KEY_BACKSPACE:
			if not screen.combat_mode.is_empty():
				_set_mode(screen, "")
				return true
	var index := key - KEY_1
	if index >= 0 and index < _choices.size():
		_choices[index].call()
		return true
	return false


func _header(screen: MatchScreen, encounter: Dictionary) -> void:
	if encounter.get("kind") == "boss":
		var boss: Dictionary = encounter["boss"]
		var head := UiKit.flow(12)
		head.add_child(UiKit.label("%s, %s" % [boss["name"], boss["title"]], "heading", UiKit.ENEMY))
		head.add_child(UiKit.badge("PHASE %d/%d: %s" % [int(boss["phase"]), int(boss["phases_total"]), boss["phase_name"]], UiKit.WARN))
		add_child(head)
		var telegraph: Dictionary = boss.get("telegraph", {})
		if not telegraph.is_empty():
			var box := UiKit.vbox(4)
			var target := "the whole Party" if telegraph["target"] == "all" else screen.name_of(str(telegraph["target"]))
			box.add_child(UiKit.para("WARNING: %s next turn, aimed at %s!" % [telegraph["name"], target], "heading", UiKit.WARN))
			box.add_child(UiKit.para(str(telegraph["text"])))
			var advice := "Defend [D] to halve it"
			advice += ", or raise Shield Wall." if telegraph["target"] == "all" else ", or have a Guardian Protect them."
			box.add_child(UiKit.para(advice, "dim"))
			add_child(UiKit.panel(box, "HighlightPanel"))
		screen.app.hint("boss")
	else:
		add_child(UiKit.label("%s - Round %d" % [encounter.get("name", "Combat"), int(_combat.get("round", 1))], "heading"))


func _build_enemies(screen: MatchScreen) -> void:
	var row := UiKit.flow(10)
	var targets := _current_targets(screen)
	for enemy in _combat.get("enemies", []):
		var id := str(enemy["id"])
		var box := UiKit.vbox(4)
		var head := UiKit.hbox(6)
		head.add_child(UiKit.label(screen.name_of(id), "heading", UiKit.ENEMY if int(enemy["hp"]) > 0 else UiKit.TEXT_DIM))
		head.add_child(UiKit.spacer())
		head.add_child(UiKit.badge("FRONT" if enemy["row"] == "front" else "BACK ROW", UiKit.TEXT_DIM))
		box.add_child(head)
		if int(enemy["hp"]) > 0:
			box.add_child(UiKit.hp_bar(int(enemy["hp"]), int(enemy["max_hp"])))
		else:
			box.add_child(UiKit.badge("DEFEATED", UiKit.TEXT_DIM))
		var weakness: Array = enemy.get("weakness", [])
		if not weakness.is_empty():
			box.add_child(UiKit.label("Weak to: %s" % ", ".join(weakness), "dim"))
		if _combat.get("actor", "") == id:
			box.add_child(UiKit.badge("ACTING", UiKit.ACCENT))
		var target_index := targets.find(id)
		if target_index >= 0:
			box.add_child(UiKit.badge("TARGET [%d]" % (target_index + 1), UiKit.ACCENT))
		var card := UiKit.panel(box, "HighlightPanel" if target_index >= 0 else "CardPanel")
		card.tooltip_text = str(enemy.get("description", ""))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(230, 0)
		row.add_child(card)
		screen.anchors[id] = card
	add_child(row)


func _build_your_turn(screen: MatchScreen, app: ClientApp, view: Dictionary) -> void:
	var banner := UiKit.flow(16)
	banner.add_child(UiKit.label("YOUR TURN - %s" % screen.name_of(_me), "heading", UiKit.ACCENT))
	_countdown = UiKit.label("", "heading")
	banner.add_child(_countdown)
	add_child(banner)
	var choices: Dictionary = _combat.get("choices", {})
	var mode := screen.combat_mode
	if mode.is_empty():
		var actions := UiKit.flow(10)
		actions.add_child(_action_button("Attack [A]", func() -> void: _set_mode(screen, "attack"), "attack"))
		var skill := _action_button("Skill [S]", func() -> void: _set_mode(screen, "skills"), "skill")
		if choices.get("skills", {}).is_empty():
			skill.disabled = true
			skill.text = "Skill [S] - needs a Class"
			skill.tooltip_text = UiText.error("skill_unavailable")
		actions.add_child(skill)
		actions.add_child(_action_button("Defend [D]", func() -> void: _send(app, {"action": "defend"}), "defend"))
		var item := _action_button("Item [I]", func() -> void: _set_mode(screen, "items"), "item")
		item.disabled = choices.get("items", {}).is_empty()
		actions.add_child(item)
		add_child(actions)
		add_child(UiKit.para("Defend halves damage until your next turn. Items come from the Party's shared bag.", "dim"))
		app.hint("combat")
		for character in view.get("party", []):
			if "p%d" % int(character["slot"]) == _me and character["class"] != "classless":
				app.hint("skill")
		return
	var list := UiKit.vbox(6)
	_choices.clear()
	match mode:
		"attack":
			list.add_child(UiKit.label("Attack whom?", "heading"))
			_target_buttons(screen, app, list, choices["attack"]["targets"], {"action": "attack"})
		"skills":
			list.add_child(UiKit.label("Use which Skill?", "heading"))
			for skill_id in choices.get("skills", {}):
				var info: Dictionary = choices["skills"][skill_id]
				var ready: bool = int(info["cooldown"]) == 0 and not info["targets"].is_empty()
				var text := "[%d] %s - %s" % [_choices.size() + 1, info["name"],
						"ready" if ready else "cooling down: %d turn(s)" % int(info["cooldown"])]
				var pick := func() -> void: _pick_skill(screen, app, skill_id, info)
				var button := UiKit.button(text, pick)
				button.disabled = not ready
				button.set_meta("focus_id", "skill_" + skill_id)
				list.add_child(button)
				_choices.append(pick if ready else func() -> void: app.toast(UiText.error("skill_on_cooldown")))
		"items":
			list.add_child(UiKit.label("Use which Item?", "heading"))
			for item_id in choices.get("items", {}):
				var info: Dictionary = choices["items"][item_id]
				var usable: bool = not info["targets"].is_empty()
				var description := _item_description(screen, item_id)
				var pick := func() -> void: _pick_item(screen, app, item_id, info)
				var button := UiKit.button("[%d] %s x%d - %s" % [_choices.size() + 1, item_id.replace("_", " ").capitalize(),
						int(info["count"]), description], pick)
				button.disabled = not usable
				button.set_meta("focus_id", "item_" + item_id)
				list.add_child(button)
				_choices.append(pick if usable else func() -> void: app.toast(UiText.error("invalid_target")))
		_:
			var parts := mode.split(":")
			var info: Dictionary = choices.get("skills" if parts[0] == "skill" else "items", {}).get(parts[1], {})
			list.add_child(UiKit.label("Target for %s?" % parts[1].replace("_", " ").capitalize(), "heading"))
			var cmd := {"action": parts[0], parts[0]: parts[1]}
			_target_buttons(screen, app, list, info.get("targets", []), cmd)
	list.add_child(UiKit.button("Back [Esc]", func() -> void: _set_mode(screen, "")))
	add_child(list)


func _build_waiting(screen: MatchScreen) -> void:
	var actor := str(_combat.get("actor", ""))
	var row := UiKit.flow(10)
	match str(_combat.get("actor_controller", "")):
		"human":
			row.add_child(UiKit.label("Waiting for %s to act..." % screen.name_of(actor), "heading"))
			_countdown = UiKit.label("", "heading")
			row.add_child(_countdown)
		"ai":
			row.add_child(UiKit.label("%s (AI) is acting..." % screen.name_of(actor), "heading"))
		"enemy":
			row.add_child(UiKit.label("%s is acting..." % screen.name_of(actor), "heading", UiKit.ENEMY))
	add_child(row)


func _build_result(screen: MatchScreen) -> void:
	match str(_combat["result"]):
		"victory":
			var rewards: Dictionary = _combat.get("rewards", {})
			if _combat.get("trial", false):
				add_child(UiKit.label("Challenge won!", "title", UiKit.GOOD))
				return
			add_child(UiKit.label("Victory!", "title", UiKit.GOOD))
			var parts: Array[String] = ["+%d EXP for everyone" % int(rewards.get("exp", 0)), "+%d Gold" % int(rewards.get("gold", 0))]
			for item in rewards.get("items", {}):
				parts.append("+%d %s" % [int(rewards["items"][item]), item.replace("_", " ").capitalize()])
			add_child(UiKit.para(", ".join(parts), "heading", UiKit.ACCENT))
			if rewards.has("clue"):
				add_child(UiKit.para("Story Clue found: %s - %s" % [rewards["clue"]["title"], rewards["clue"]["text"]]))
		"timeout":
			add_child(UiKit.label("Time is up - the Challenge is over.", "title", UiKit.WARN))
		_:
			add_child(UiKit.label("The Party has fallen...", "title", UiKit.ENEMY))


func _target_buttons(screen: MatchScreen, app: ClientApp, list: VBoxContainer, targets: Array, base: Dictionary) -> void:
	for target in targets:
		var cmd := base.duplicate()
		cmd["target"] = target
		var pick := func() -> void: _send(app, cmd)
		var button := UiKit.button("[%d] %s" % [_choices.size() + 1, _target_text(screen, str(target))], pick)
		button.set_meta("focus_id", "target_" + str(target))
		list.add_child(button)
		_choices.append(pick)


func _target_text(screen: MatchScreen, id: String) -> String:
	for enemy in _combat.get("enemies", []):
		if enemy["id"] == id:
			return "%s (HP %d/%d%s)" % [screen.name_of(id), int(enemy["hp"]), int(enemy["max_hp"]),
					", back row" if enemy["row"] != "front" else ""]
	for character in screen.match_view().get("party", []):
		if "p%d" % int(character["slot"]) == id:
			return "%s (HP %d/%d)%s" % [screen.name_of(id), int(character["hp"]), int(character["max_hp"]),
					" - you" if id == _me else ""]
	return screen.name_of(id)


func _pick_skill(screen: MatchScreen, app: ClientApp, skill_id: String, info: Dictionary) -> void:
	match str(info["target"]):
		"all_enemies":
			_send(app, {"action": "skill", "skill": skill_id})
		"self":
			_send(app, {"action": "skill", "skill": skill_id, "target": _me})
		_:
			_set_mode(screen, "skill:" + skill_id)


func _pick_item(screen: MatchScreen, app: ClientApp, item_id: String, info: Dictionary) -> void:
	if str(info["target"]) in ["all_enemies", "all_allies"]:
		_send(app, {"action": "item", "item": item_id})
	else:
		_set_mode(screen, "item:" + item_id)


func _set_mode(screen: MatchScreen, mode: String) -> void:
	screen.combat_mode = mode
	screen.refresh(screen.app, true)


func _send(app: ClientApp, cmd: Dictionary) -> void:
	var full := {"type": "action"}
	full.merge(cmd)
	app.send(full)


func _current_targets(screen: MatchScreen) -> Array:
	var mode := screen.combat_mode
	var choices: Dictionary = _combat.get("choices", {})
	if not _combat.get("your_turn", false) or choices.is_empty():
		return []
	if mode == "attack":
		return choices["attack"]["targets"]
	if mode.begins_with("skill:"):
		return choices["skills"].get(mode.trim_prefix("skill:"), {}).get("targets", [])
	if mode.begins_with("item:"):
		return choices["items"].get(mode.trim_prefix("item:"), {}).get("targets", [])
	return []


func _turn_order_text(screen: MatchScreen) -> String:
	var parts: Array[String] = []
	for id in _combat.get("turn_order", []):
		var who := screen.name_of(str(id))
		if id == _me:
			who += " (you)"
		if id == _combat.get("actor", ""):
			who = "> " + who
		parts.append(who)
	return "Turn order this round: " + "  |  ".join(parts)


static func _action_button(text: String, callback: Callable, id: String) -> Button:
	var button := UiKit.button(text, callback, true)
	button.set_meta("focus_id", "action_" + id)
	return button


static func _item_description(screen: MatchScreen, item_id: String) -> String:
	for entry in screen.match_view().get("inventory", []):
		if entry["item"] == item_id:
			return str(entry["description"])
	return ""
