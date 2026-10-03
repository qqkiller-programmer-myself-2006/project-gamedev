class_name StoryDirector
extends Control

const DialoguePanelScript = preload("res://src/client/story/dialogue_panel.gd")
const ChapterCardScript = preload("res://src/client/story/chapter_card.gd")
const CutscenePlayerScript = preload("res://src/client/cutscene/cutscene_player.gd")

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
## The new-story prologue and opening chapter must finish before Layer 1's
## first path choice is exposed. Continue restores skip this gate.
var opening_presentation_pending := false
## Set by MatchScreen when the Match comes from a Story save (Continue); used once, for the first Match seen.
var restoring := false
## Presentation ids copied from the client-side Story save on Continue.
var restored_presentations: Dictionary = {}
## Flags reported by finished cutscenes (never sent to the server).
var cutscene_flags: Dictionary = {}
var text_scale := 1.0
var reduced_motion := false
var _safe_log_top_y := 0.0
var _safe_header_bottom_y := 0.0
var _has_safe_bounds := false


func apply_settings(scale: float, reduced: bool) -> void:
	text_scale = scale
	reduced_motion = reduced
	if is_instance_valid(current) and current.has_method("apply_settings"):
		current.apply_settings(scale, reduced)


func set_safe_bounds(log_top_y: float, header_bottom_y: float) -> void:
	_safe_log_top_y = log_top_y
	_safe_header_bottom_y = header_bottom_y
	_has_safe_bounds = true
	if is_instance_valid(current) and current.has_method("set_safe_bounds"):
		current.set_safe_bounds(log_top_y, header_bottom_y)


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
		opening_presentation_pending = false

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
			# Old saves lack presentation metadata. At Layer 3+, the first merchant/rest
			# scenes belong to earlier progress and must not replay after Continue.
			if layer > 1:
				shown["merchant_first"] = true
				shown["rest_first"] = true
			for presentation_id in restored_presentations:
				if restored_presentations[presentation_id] and _is_known_presentation(str(presentation_id)):
					shown[str(presentation_id)] = true
			# The save is taken at layer start, before its card is presented.
			shown.erase("chapter_%s" % layer)
			opening_presentation_pending = true
		else:
			queue.append({"kind":"scene", "id":"prologue", "lines":content.get("prologue", [])})
			opening_presentation_pending = layer == 1
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
	var scene = content["scenes"][trigger]
	if scene is Dictionary and str(scene.get("type", "")) == "cutscene":
		enqueue_cutscene(str(scene.get("id", "")))
		return
	queue.append({"kind":"scene", "id":trigger, "lines":scene})

## Queue a `{"type": "cutscene", "id": ...}` presentation entry (content/cutscenes/<id>.json).
func enqueue_cutscene(id: String) -> void:
	queue.append({"kind":"cutscene", "id":id})
	_pump()

func _enqueue_card(chapter: Dictionary) -> void:
	var key := "chapter_%s" % chapter.get("number", 0)
	if shown.has(key):
		return
	shown[key] = true
	queue.append({"kind":"card", "id":key, "chapter":chapter})

func _is_known_presentation(presentation_id: String) -> bool:
	if presentation_id == "prologue" or content.get("scenes", {}).has(presentation_id):
		return true
	for chapter in content.get("chapters", []):
		if presentation_id == "chapter_%s" % chapter.get("number", 0):
			return true
	return false

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
	if is_instance_valid(current) or queue.is_empty() or (_is_decision_pending() and not opening_presentation_pending):
		return
	var item: Dictionary = queue.pop_front()
	if item.kind == "cutscene":
		var loaded := CutsceneData.load_cutscene(str(item.get("id", "")))
		if not loaded["ok"]:
			push_warning("cutscene '%s' skipped: %s" % [item.get("id", ""), loaded["errors"]])
			_pump()
			return
		current = CutscenePlayerScript.new(loaded["data"], cutscene_flags, text_scale, reduced_motion)
		add_child(current)
		current.finished.connect(_on_cutscene_finished.bind(item))
		presentation_started.emit(item)
		return
	if item.kind == "card":
		current = ChapterCardScript.new(item.chapter, reduced_motion)
	else:
		var class_map := {}
		var match_view: Dictionary = _latest_snapshot.get("match", {}) if _latest_snapshot.get("match", {}) is Dictionary else {}
		for member in match_view.get("party", []):
			class_map[str(member.get("name", "")).to_lower()] = str(member.get("class", ""))
		current = DialoguePanelScript.new(item.lines, text_scale, reduced_motion, class_map)
		if _has_safe_bounds:
			current.set_safe_bounds(_safe_log_top_y, _safe_header_bottom_y)
	add_child(current)
	current.finished.connect(_on_finished.bind(item))
	presentation_started.emit(item)

func _on_cutscene_finished(flags: Dictionary, item: Dictionary) -> void:
	cutscene_flags.merge(flags, true)
	_on_finished(item)

func _on_finished(item: Dictionary) -> void:
	current = null
	var layer := int((_latest_snapshot.get("match", {}) as Dictionary).get("layer", 0))
	if opening_presentation_pending and str(item.get("id", "")) == "chapter_%s" % layer:
		opening_presentation_pending = false
	elif opening_presentation_pending and queue.is_empty():
		# Content may omit chapter cards in a test or a future build.
		opening_presentation_pending = false
	_pump()
	presentation_finished.emit(item)
