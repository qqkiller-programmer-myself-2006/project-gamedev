class_name SummaryPanel
extends VBoxContainer
## End of a Match: Victory or Defeat, the Forest ending text and a summary.
## The Host starts a new Match in the same room; everyone else waits.

func build(screen: MatchScreen, app: ClientApp, view: Dictionary) -> void:
	add_theme_constant_override("separation", 12)
	var summary: Dictionary = view.get("summary", {})
	var won: bool = summary.get("result") == "victory"
	add_child(UiKit.label("VICTORY" if won else "DEFEAT", "huge", UiKit.GOOD if won else UiKit.ENEMY))
	add_child(UiKit.para(str(summary.get("title", "")), "title", UiKit.ACCENT))
	# What to do next comes first, so it is on screen without scrolling.
	var actions := UiKit.flow(12)
	if screen.is_host():
		var again := UiKit.primary("Start a new Match", func() -> void: app.send({"type": "start_match"}))
		again.set_meta("focus_id", "again")
		actions.add_child(again)
	else:
		actions.add_child(UiKit.label("Waiting for the Host to start a new Match...", "heading"))
	actions.add_child(UiKit.button("Clue log [C]", screen.toggle_clues, true))
	add_child(actions)
	add_child(UiKit.para(str(summary.get("text", ""))))
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 24)
	var classes: Array[String] = []
	for id in summary.get("classes_discovered", []):
		classes.append(Tr.t(str(id).capitalize()))
	var rows := [
		["Time played", UiText.clock(float(summary.get("elapsed", 0.0)))],
		["Reached", _reached(summary, won)],
		["Enemies defeated", str(int(summary.get("enemies_defeated", 0)))],
		["Classes discovered", ", ".join(classes) if not classes.is_empty() else Tr.t("none")],
		[Tr.t("Story Clues found"), str(int(summary.get("clues_found", 0)))],
	]
	for row in rows:
		stats.add_child(UiKit.label(row[0], "dim"))
		stats.add_child(UiKit.label(row[1], "heading"))
	add_child(UiKit.panel(stats, "CardPanel"))
	for clue in summary.get("clues", []):
		add_child(UiKit.para("- %s: %s" % [Tr.t(str(clue["title"])), Tr.t(str(clue["text"]))], "dim"))


static func _reached(summary: Dictionary, won: bool) -> String:
	if won:
		return Tr.t("Guardian Boss defeated")
	if summary.get("reached_boss", false):
		return "Guardian Boss"
	return Tr.t("Layer %d of %d" % [int(summary.get("layer", 0)), int(summary.get("layers_total", 5))])
