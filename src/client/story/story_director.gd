class_name StoryDirector
extends Control

const DialoguePanelScript = preload("res://src/client/story/dialogue_panel.gd")
const ChapterCardScript = preload("res://src/client/story/chapter_card.gd")

## Presentation-only story queue. It observes client data and never sends commands.
signal presentation_started(item)
signal presentation_finished(item)

const STORY_PATH := "res://content/story_mode.json"
var content: Dictionary = {}
var queue: Array = []
var shown: Dictionary = {}
var current: Node = null
var last_layer := 0
var started := false
## Set by MatchScreen when the Match comes from a Story save (Continue); used once, for the first Match seen.
var restoring := false
var text_scale := 1.0
var reduced_motion := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(STORY_PATH))
	content = parsed if parsed is Dictionary else {}

func begin() -> void:
	if not started:
		started = true
		queue.append({"kind":"scene", "id":"prologue", "lines":content.get("prologue", [])})
		_pump()

var _latest_snapshot: Dictionary = {}
var match_number := 0

func observe(events: Array, snapshot: Dictionary) -> void:
	_latest_snapshot = snapshot
	var match_view: Dictionary = snapshot.get("match", {}) if snapshot.get("match", {}) is Dictionary else {}
	var current_match := int(match_view.get("number", 0))
	if current_match > 0 and current_match != match_number:
		match_number = current_match
		started = false
		queue.clear()
		shown.clear()
		if is_instance_valid(current):
			current.queue_free()
			current = null
		last_layer = 0

	if not started and current_match > 0:
		started = true
		var layer := int(match_view.get("layer", match_view.get("current_layer", 0)))
		# A new Match already starts at Layer 1, so only an explicit restore counts as a Continue.
		if restoring and layer > 0:
			# Continue: skip what came before this layer; this layer's chapter card still shows below.
			shown["prologue"] = true
			for i in range(1, layer):
				shown["chapter_%s" % i] = true
				if i == 1: shown["first_combat_won"] = true
		else:
			queue.append({"kind":"scene", "id":"prologue", "lines":content.get("prologue", [])})
		restoring = false
		_pump()

	var layer := int(match_view.get("layer", match_view.get("current_layer", 0)))
	if layer > 0 and layer != last_layer:
		last_layer = layer
		var chapters: Array = content.get("chapters", [])
		for chapter in chapters:
			if int(chapter.get("number", 0)) == layer:
				_enqueue_card(chapter)
	for event in events:
		if event.get("type", "") == "boss_reached":
			for chapter in content.get("chapters", []):
				if int(chapter.get("number", 0)) == 6:
					_enqueue_card(chapter)
		var trigger := _trigger_for(event)
		if not trigger.is_empty():
			_enqueue_scene(trigger)
	_pump()

func _trigger_for(event: Variant) -> String:
	if not event is Dictionary:
		return ""
	var kind := str(event.get("type", event.get("kind", event.get("event", ""))))
	var map := {
		"combat_ended": "first_combat_won" if event.get("result", "") == "victory" else "",
		"class_changed": "class_gained",
		"class_challenge_ended": "class_gained" if event.get("passed", false) else "",
		"clue_found": "story_clue",
		"merchant_opened": "merchant_first",
		"rested": "rest_first",
		"boss_reached": "before_boss",
		"match_ended": "boss_won" if event.get("result", "") == "victory" else "party_defeated"
	}
	return str(map.get(kind, kind if content.get("scenes", {}).has(kind) else ""))

func _enqueue_scene(trigger: String) -> void:
	if shown.has(trigger) or not content.get("scenes", {}).has(trigger):
		return
	shown[trigger] = true
	queue.append({"kind":"scene", "id":trigger, "lines":content["scenes"][trigger]})

func _enqueue_card(chapter: Dictionary) -> void:
	var key := "chapter_%s" % chapter.get("number", 0)
	if shown.has(key):
		return
	shown[key] = true
	queue.append({"kind":"card", "id":key, "chapter":chapter})

func _is_decision_pending() -> bool:
	var match_view: Dictionary = _latest_snapshot.get("match", {}) if _latest_snapshot.get("match", {}) is Dictionary else {}
	if match_view.is_empty():
		return false
	var phase = str(match_view.get("phase", ""))
	if phase == "voting":
		return true
	if phase == "encounter" or phase == "boss":
		var encounter = match_view.get("encounter", {})
		if not encounter is Dictionary:
			return false
		var kind = str(encounter.get("kind", ""))
		if kind == "class":
			var offer = encounter.get("offer", {})
			if offer is Dictionary:
				var eligible = offer.get("eligible", [])
				var decisions = offer.get("decisions", {})
				return eligible.size() > decisions.size()
		elif kind in ["merchant", "rest"]:
			return not encounter.get("you_are_ready", true)
		elif kind == "story":
			if str(encounter.get("stage", "")) == "choosing":
				return true
			return not encounter.get("you_are_ready", true)
		elif kind == "combat":
			return str(encounter.get("actor_controller", "")) == "human"
	return false

func _pump() -> void:
	if is_instance_valid(current) or queue.is_empty() or _is_decision_pending():
		return
	var item: Dictionary = queue.pop_front()
	if item.kind == "card":
		current = ChapterCardScript.new(item.chapter, reduced_motion)
	else:
		var class_map := {}
		var match_view: Dictionary = _latest_snapshot.get("match", {}) if _latest_snapshot.get("match", {}) is Dictionary else {}
		for member in match_view.get("party", []):
			class_map[str(member.get("name", "")).to_lower()] = str(member.get("class", ""))
		current = DialoguePanelScript.new(item.lines, text_scale, reduced_motion, class_map)
	add_child(current)
	current.finished.connect(_on_finished.bind(item))
	presentation_started.emit(item)

func _on_finished(item: Dictionary) -> void:
	presentation_finished.emit(item)
	current = null
	_pump()
