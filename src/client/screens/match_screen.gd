class_name MatchScreen
extends Control
## Everything during (and right after) a Match: journey progress, the Party
## with owner and human/AI control for every slot, the panel for the current
## phase, and a readable log of what happened.

var app: ClientApp
## id ("p0", "e1") -> display name, rebuilt on every refresh.
var names: Dictionary = {}
## id -> Control the floating numbers rise from.
var anchors: Dictionary = {}
## Combat input state that must survive refreshes while it is still your turn.
var combat_mode := ""
var combat_mode_key := ""

var _top: HBoxContainer
var _party: VBoxContainer
var _center: MarginContainer
var _center_scroll: ScrollContainer
var _log: RichTextLabel
var _log_lines: Array[String] = []
var _tips: VBoxContainer
var _panel: Control = null
var _digest := ""
var _clue_overlay: Control = null
var _last_warned_deadline := -1.0


func setup(client: ClientApp) -> void:
	app = client
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var column := UiKit.vbox(10)
	margin.add_child(column)
	_top = UiKit.hbox(12)
	column.add_child(UiKit.panel(_top))
	var middle := UiKit.hbox(12)
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(middle)
	var party_scroll := ScrollContainer.new()
	party_scroll.custom_minimum_size = Vector2(310, 0)
	party_scroll.follow_focus = true
	party_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_party = UiKit.vbox(6)
	_party.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	party_scroll.add_child(_party)
	middle.add_child(party_scroll)
	var center_scroll := ScrollContainer.new()
	_center_scroll = center_scroll
	center_scroll.follow_focus = true
	center_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_center = MarginContainer.new()
	_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_scroll.add_child(_center)
	var center_panel := UiKit.panel(center_scroll)
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(center_panel)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = false
	_log.scroll_following = true
	_log.custom_minimum_size = Vector2(0, 100)
	_log.focus_mode = Control.FOCUS_NONE
	_log.add_theme_color_override("default_color", UiKit.TEXT_DIM)
	var bottom := UiKit.hbox(10)
	var log_panel := UiKit.panel(_log)
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(log_panel)
	_tips = UiKit.vbox(0)
	bottom.add_child(_tips)
	column.add_child(bottom)


## Where one-time tips appear, next to the log so they never cover controls.
func tip_slot() -> Container:
	return _tips


func match_view() -> Dictionary:
	var view = app.snapshot.get("match")
	return view if view != null else {}


func room_view() -> Dictionary:
	var room = app.snapshot.get("room")
	return room if room != null else {}


func your_slot() -> int:
	return int(room_view().get("your_slot", -1))


func is_host() -> bool:
	return your_slot() >= 0 and your_slot() == int(room_view().get("host_slot", -2))


func refresh(client: ClientApp, force: bool = false) -> void:
	app = client
	var view := match_view()
	var stable := view.duplicate()
	stable.erase("elapsed")
	var digest := JSON.stringify([stable, room_view()])
	if digest == _digest and not force:
		return
	_digest = digest
	_collect_names(view)
	var focus_id := _focused_id()
	anchors.clear()
	_build_top(view)
	_build_party(view)
	_build_panel(view)
	if not _restore_focus(focus_id):
		UiKit.focus_first(_center)
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and _center.is_ancestor_of(focused):
		_scroll_to.call_deferred(focused)


func tick(client: ClientApp) -> void:
	if _panel != null and _panel.has_method("tick"):
		_panel.tick(self, client)


func handle_key(client: ClientApp, key: int) -> bool:
	if key == KEY_C:
		toggle_clues()
		return true
	if key == KEY_ESCAPE and _clue_overlay != null:
		toggle_clues()
		return true
	if _panel != null and _panel.has_method("handle_key"):
		return _panel.handle_key(self, client, key)
	return false


func show_events(client: ClientApp, events: Array) -> void:
	for event in events:
		var line := describe(event)
		if not line.is_empty():
			_add_log(line)
		_feedback(client, event)


## Warns once per deadline when a countdown the player owns gets short.
func warn_if_short(deadline: Variant, seconds_left: float) -> void:
	if deadline == null or seconds_left > 5.0 or seconds_left <= 0.0:
		return
	if not is_equal_approx(float(deadline), _last_warned_deadline):
		_last_warned_deadline = float(deadline)
		app.sounds.play("warn")


## The combat view inside an Encounter view (a Class Encounter's trial,
## or the Combat/Boss Encounter itself), or {} when there is no fight.
static func combat_of(encounter: Variant) -> Dictionary:
	if encounter == null:
		return {}
	match str(encounter.get("kind", "")):
		"class":
			return encounter.get("trial", {}) if encounter.get("stage") == "challenge" else {}
		"combat", "boss":
			return encounter
	return {}


func name_of(id: String) -> String:
	return str(names.get(id, id))


func toggle_clues() -> void:
	if _clue_overlay != null:
		_clue_overlay.queue_free()
		_clue_overlay = null
		return
	var box := UiKit.vbox(10)
	box.custom_minimum_size = Vector2(620, 0)
	box.add_child(UiKit.label("Story Clues", "title", UiKit.ACCENT))
	var clues: Array = match_view().get("clues", [])
	if clues.is_empty():
		box.add_child(UiKit.para("No clues yet. Story Events (and some fights) reveal where Father went."))
	for clue in clues:
		var entry := UiKit.vbox(2)
		entry.add_child(UiKit.label("%s  (Layer %d, %s)" % [clue["title"], int(clue["layer"]), clue["source"]], "heading"))
		entry.add_child(UiKit.para(str(clue["text"])))
		box.add_child(UiKit.panel(entry, "CardPanel"))
	var close := UiKit.button("Close [C]", toggle_clues)
	box.add_child(close)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_clue_overlay = Control.new()
	_clue_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_clue_overlay.add_child(dim)
	_clue_overlay.add_child(center)
	center.add_child(UiKit.panel(box, "HighlightPanel"))
	add_child(_clue_overlay)
	close.grab_focus()


## A number or word that rises from a character or enemy card.
func float_text(id: String, text: String, color: Color) -> void:
	# Cards may have just been rebuilt: wait for layout before measuring.
	await get_tree().process_frame
	var anchor: Control = anchors.get(id)
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_inside_tree():
		return
	var label := UiKit.label(text, "title", color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var rect := anchor.get_global_rect()
	label.global_position = rect.position + Vector2(rect.size.x * 0.5 - 20, 0)
	var tween := create_tween()
	if app.settings.reduced_motion:
		tween.tween_interval(1.2)
	else:
		tween.tween_property(label, "global_position:y", label.global_position.y - 40, 1.1)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 1.1).set_delay(0.4)
	tween.tween_callback(label.queue_free)


func describe(event: Dictionary) -> String:
	match str(event["type"]):
		"player_joined":
			return "%s joined (slot %d)." % [event["name"], int(event["slot"]) + 1]
		"player_left":
			var why := "lost connection" if event["reason"] == "disconnected" else "left"
			return "%s %s. Slot %d is now played by AI." % [event["name"], why, int(event["slot"]) + 1]
		"slot_ai_takeover":
			return "AI takes over %s." % event["character"]
		"host_changed":
			return "%s is now the Host." % event["name"]
		"match_started":
			return "The journey into the Forest begins."
		"vote_started":
			return "Layer %d: choose the next path." % int(event["layer"])
		"vote_resolved":
			var how := ""
			if event["no_votes"]:
				how = " Nobody voted, so it was picked at random."
			elif event["tie_broken"]:
				how = " It was a tie, broken at random."
			return "The Party heads for %s (%s).%s" % [event["name"], UiText.type_label(event["encounter_type"]), how]
		"encounter_started":
			return "Arrived: %s." % event["name"]
		"combat_started":
			return "Enemies appear!"
		"action_resolved":
			return _describe_action(event)
		"combat_ended":
			if event["result"] == "victory":
				var rewards: Dictionary = event.get("rewards", {})
				if rewards.is_empty() or int(rewards.get("exp", 0)) + int(rewards.get("gold", 0)) == 0:
					return "The enemy falls!"
				return "Victory! +%d EXP each, +%d Gold." % [int(rewards.get("exp", 0)), int(rewards.get("gold", 0))]
			if event["result"] == "timeout":
				return "Time is up for the Challenge."
			return "The Party has fallen..."
		"level_up":
			return "%s reached level %d!" % [name_of("p%d" % int(event["slot"])), int(event["level"])]
		"class_challenge_ended":
			return str(event["text"])
		"class_choice":
			return "%s %s the %s Class." % [name_of("p%d" % int(event["slot"])),
					"takes" if event["accepted"] else "declines", str(event["class"]).capitalize()]
		"purchase":
			return "%s bought %s for %d Gold." % [name_of("p%d" % int(event["slot"])), str(event["item"]).capitalize(), int(event["price"])]
		"rested":
			return "The Party rests and recovers."
		"treasure_found":
			return "Treasure! +%d Gold." % int(event["gold"])
		"clue_found":
			return "Story Clue found: %s." % event["clue"]["title"]
		"boss_started":
			return "%s, %s, blocks the way!" % [event["name"], event["title"]]
		"boss_telegraph":
			return "WARNING: %s" % event["text"]
		"boss_phase":
			return "Phase %d - %s: %s" % [int(event["phase"]), event["name"], event["text"]]
		"match_ended":
			return "Victory! The Forest is behind you." if event["result"] == "victory" else "Defeat. The Forest wins this time."
	return ""


func _describe_action(event: Dictionary) -> String:
	var actor := name_of(str(event["actor"]))
	match str(event["action"]):
		"defend":
			return "%s %s." % [actor, "ran out of time and Defends" if event["automatic"] else "Defends"]
		"charge":
			return "%s gathers power for %s..." % [actor, event.get("move_name", "something big")]
	var what := "attacks"
	if event.has("skill"):
		what = "uses %s" % str(event.get("skill", "")).replace("_", " ").capitalize()
	if event.has("move_name"):
		what = "uses %s" % event["move_name"]
	if event.has("item"):
		what = "uses %s" % str(event["item"]).replace("_", " ").capitalize()
	var parts: Array[String] = []
	for result in event.get("results", []):
		var target := name_of(str(result["target"]))
		if result.has("damage"):
			var note := ""
			if result.get("crit", false):
				note += " critical!"
			if result.get("weak", false):
				note += " weak spot!"
			if result.has("protected"):
				note += " (shielding %s)" % name_of(str(result["protected"]))
			if result.get("down", false):
				note += " - down"
			parts.append("%s takes %d%s" % [target, int(result["damage"]), note])
		elif result.has("heal"):
			parts.append("%s recovers %d HP" % [target, int(result["heal"])])
		elif result.get("revived", false):
			parts.append("%s is back on their feet" % target)
		elif result.get("status", "") == "protected":
			parts.append("%s is protected" % target)
		elif result.get("status", "") == "shielded":
			parts.append("the Party raises its guard")
	return "%s %s: %s." % [actor, what, ", ".join(parts)] if not parts.is_empty() else "%s %s." % [actor, what]


func _feedback(client: ClientApp, event: Dictionary) -> void:
	var me := "p%d" % your_slot()
	match str(event["type"]):
		"turn_started":
			if event["actor"] == me and event["controller"] == "human":
				client.banner("Your turn!", 1.6, "turn")
		"action_resolved":
			var hurt := false
			for result in event.get("results", []):
				var target := str(result["target"])
				if result.has("damage"):
					hurt = true
					var text := "-%d" % int(result["damage"])
					if result.get("crit", false):
						text += " CRIT"
					float_text(target, text, UiKit.ENEMY if target.begins_with("p") else UiKit.ACCENT)
				elif result.has("heal"):
					float_text(target, "+%d" % int(result["heal"]), UiKit.GOOD)
			if hurt:
				client.sounds.play("hit")
		"vote_resolved":
			client.banner("Next: %s" % event["name"], 2.2, "vote")
		"level_up":
			float_text("p%d" % int(event["slot"]), "LEVEL UP", UiKit.GOOD)
			client.sounds.play("good")
		"class_changed":
			client.sounds.play("good")
		"boss_telegraph":
			client.banner("Warning: %s next turn!" % event["name"], 2.5, "warn")
		"boss_phase":
			client.banner("Phase %d: %s" % [int(event["phase"]), event["name"]], 2.5, "warn")
		"slot_ai_takeover":
			client.toast("%s is now controlled by AI." % event["character"])
		"match_ended":
			client.banner("Victory!" if event["result"] == "victory" else "Defeat", 3.0,
					"good" if event["result"] == "victory" else "bad")


func _collect_names(view: Dictionary) -> void:
	names.clear()
	for character in view.get("party", []):
		names["p%d" % int(character["slot"])] = str(character["name"])
	var encounter = view.get("encounter")
	if encounter == null:
		return
	var combat: Dictionary = MatchScreen.combat_of(encounter)
	var counts := {}
	for enemy in combat.get("enemies", []):
		counts[enemy["name"]] = int(counts.get(enemy["name"], 0)) + 1
	var seen := {}
	for enemy in combat.get("enemies", []):
		var base := str(enemy["name"])
		if int(counts[base]) > 1:
			seen[base] = int(seen.get(base, 0)) + 1
			names[enemy["id"]] = "%s %s" % [base, "ABCDE"[int(seen[base]) - 1]]
		else:
			names[enemy["id"]] = base


func _build_top(view: Dictionary) -> void:
	UiKit.clear(_top)
	_top.add_child(UiKit.label("Forest", "heading", UiKit.ACCENT))
	var total := int(view.get("layers_total", 5))
	var layer := int(view.get("layer", 0))
	var phase := str(view.get("phase", ""))
	var steps := UiKit.hbox(4)
	for i in range(1, total + 1):
		var done := i < layer or (i == layer and phase in ["boss", "victory", "defeat"])
		var text := "%d" % i
		if i == layer and not done:
			text = "> %d <" % i
		steps.add_child(UiKit.badge(text, UiKit.ACCENT if i == layer else (UiKit.GOOD if done else UiKit.TEXT_DIM)))
	var boss_now := phase == "boss" or (phase in ["victory", "defeat"] and layer >= total)
	steps.add_child(UiKit.badge("> BOSS <" if phase == "boss" else "BOSS", UiKit.ENEMY if boss_now else UiKit.TEXT_DIM))
	_top.add_child(steps)
	var where := "Guardian Boss" if phase == "boss" else "Layer %d of %d" % [layer, total]
	_top.add_child(UiKit.label(where))
	_top.add_child(UiKit.spacer())
	_top.add_child(UiKit.label("Gold: %d" % int(view.get("gold", 0)), "heading", UiKit.ACCENT))
	var clues := UiKit.button("Clues: %d [C]" % view.get("clues", []).size(), toggle_clues)
	clues.set_meta("focus_id", "clues")
	_top.add_child(clues)
	_top.add_child(UiKit.button("Settings [F2]", app.open_settings))
	var leave := UiKit.button("Leave", func() -> void:
		app.send({"type": "leave_room"})
		app.disconnect_from_server())
	leave.set_meta("focus_id", "leave")
	_top.add_child(leave)


func _build_party(view: Dictionary) -> void:
	UiKit.clear(_party)
	var encounter = view.get("encounter")
	var combat: Dictionary = {}
	if encounter != null:
		combat = MatchScreen.combat_of(encounter)
	var slots: Array = room_view().get("slots", [])
	for character in view.get("party", []):
		var slot := int(character["slot"])
		var id := "p%d" % slot
		var card := UiKit.vbox(2)
		var head := UiKit.hbox(6)
		head.add_child(UiKit.label(str(character["name"]), "body", UiKit.ACCENT if slot == your_slot() else UiKit.TEXT))
		head.add_child(UiKit.label("Lv %d %s" % [int(character["level"]), character["class_name"]], "dim"))
		head.add_child(UiKit.spacer())
		if slot == your_slot():
			head.add_child(UiKit.badge("YOU", UiKit.GOOD))
		head.add_child(UiKit.badge("PLAYER" if character["controller"] == "human" else "AI",
				UiKit.ALLY if character["controller"] == "human" else UiKit.TEXT_DIM))
		card.add_child(head)
		card.add_child(UiKit.hp_bar(int(character["hp"]), int(character["max_hp"])))
		var info := UiKit.hbox(4)
		var owner := "AI controlled"
		if character["controller"] == "human" and slot < slots.size():
			owner = str(slots[slot]["owner_name"])
		info.add_child(UiKit.label(owner, "dim"))
		info.add_child(UiKit.spacer())
		if int(character["hp"]) <= 0:
			info.add_child(UiKit.badge("DOWN", UiKit.ENEMY))
		if combat.get("actor", "") == id:
			info.add_child(UiKit.badge("ACTING", UiKit.ACCENT))
		if combat.get("defending", []).has(id):
			info.add_child(UiKit.badge("DEFEND", UiKit.ALLY))
		if combat.get("protected", {}).has(id):
			info.add_child(UiKit.badge("GUARDED", UiKit.ALLY))
		if combat.get("shielded", false) and int(character["hp"]) > 0:
			info.add_child(UiKit.badge("WALL", UiKit.ALLY))
		card.add_child(info)
		var panel := UiKit.panel(card, "CompactHighlightPanel" if combat.get("actor", "") == id else "CompactPanel")
		var tip := "ATK %d  DEF %d  MAG %d  RES %d  SPD %d  EXP %d" % [int(character["atk"]), int(character["def"]),
				int(character["mag"]), int(character["res"]), int(character["spd"]), int(character["exp"])]
		if combat.get("protected", {}).has(id):
			tip += "\nGuarded by %s until their next turn." % name_of(combat["protected"][id])
		panel.tooltip_text = tip
		_party.add_child(panel)
		anchors[id] = panel


func _build_panel(view: Dictionary) -> void:
	if _panel != null:
		_center.remove_child(_panel)
		_panel.queue_free()
	var phase := str(view.get("phase", ""))
	var encounter = view.get("encounter")
	match phase:
		"voting":
			_panel = VotePanel.new()
		"travel":
			_panel = InfoPanel.new()
		"victory", "defeat":
			_panel = SummaryPanel.new()
		_:
			match str(encounter.get("kind", "") if encounter != null else ""):
				"combat", "boss":
					_panel = CombatPanel.new()
				"class":
					_panel = ClassPanel.new()
				"merchant":
					_panel = MerchantPanel.new()
				"story":
					_panel = StoryPanel.new()
				_:
					_panel = InfoPanel.new()
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center.add_child(_panel)
	_panel.build(self, app, view)


func _scroll_to(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree():
		_center_scroll.ensure_control_visible(control)


func _add_log(line: String) -> void:
	_log_lines.append(line)
	if _log_lines.size() > 60:
		_log_lines.pop_front()
	_log.text = "\n".join(_log_lines)


func _focused_id() -> String:
	var focused := get_viewport().gui_get_focus_owner()
	return str(focused.get_meta("focus_id", "")) if focused != null else ""


func _restore_focus(focus_id: String) -> bool:
	return not focus_id.is_empty() and LobbyScreen._find_and_focus(self, focus_id)
