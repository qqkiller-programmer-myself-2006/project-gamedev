class_name InfoPanel
extends VBoxContainer
## Short, automatic stops: travelling after a vote, Rest and Treasure.

var _until: Variant = null
var _countdown: Label


func build(screen: MatchScreen, app: ClientApp, view: Dictionary) -> void:
	add_theme_constant_override("separation", 12)
	var encounter = view.get("encounter")
	if view["phase"] == "travel":
		_build_travel(view)
	elif encounter != null and encounter.get("kind") == "rest":
		add_child(UiKit.label(str(encounter["name"]), "title"))
		add_child(UiKit.para(str(encounter["text"])))
		for entry in encounter["healed"]:
			add_child(UiKit.label("%s recovers %d HP (now %d)." % [screen.name_of("p%d" % int(entry["slot"])),
					int(entry["amount"]), int(entry["hp"])]))
		_until = encounter["ends_at"]
	elif encounter != null and encounter.get("kind") == "treasure":
		add_child(UiKit.label(str(encounter["name"]), "title"))
		add_child(UiKit.para(str(encounter["text"])))
		var found: Dictionary = encounter["found"]
		if int(found["gold"]) > 0:
			add_child(UiKit.label("+%d Gold for the Party." % int(found["gold"]), "heading", UiKit.ACCENT))
		for item in found["items"]:
			add_child(UiKit.label("+%d %s added to the shared bag." % [int(found["items"][item]), item.replace("_", " ").capitalize()], "heading"))
		_until = encounter["ends_at"]
	else:
		add_child(UiKit.label("...", "title"))
	_countdown = UiKit.label("", "dim")
	add_child(_countdown)
	tick(screen, app)


func tick(_screen: MatchScreen, app: ClientApp) -> void:
	if _until != null:
		_countdown.text = "The journey continues in %ds." % ceili(app.seconds_left(_until))


func _build_travel(view: Dictionary) -> void:
	var result: Dictionary = view.get("last_vote", {})
	add_child(UiKit.label("The Party sets off...", "title"))
	if result.is_empty():
		return
	var head := UiKit.hbox(8)
	head.add_child(UiKit.badge(UiText.type_tag(result["type"]), UiKit.ACCENT))
	head.add_child(UiKit.label("Next: %s (%s)" % [result["name"], UiText.type_label(result["type"])], "heading"))
	add_child(head)
	var tally: Array = result["tally"]
	var parts: Array[String] = []
	for i in tally.size():
		parts.append("path %d: %d vote%s" % [i + 1, int(tally[i]), "" if int(tally[i]) == 1 else "s"])
	add_child(UiKit.para("Final tally - %s." % ", ".join(parts)))
	if result["no_votes"]:
		add_child(UiKit.para("Nobody voted in time, so the path was chosen at random.", "body", UiKit.WARN))
	elif result["tie_broken"]:
		add_child(UiKit.para("It was a tie, so the path was chosen at random among the tied options.", "body", UiKit.WARN))
