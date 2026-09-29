class_name StoryDirector
extends Node

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
var text_scale := 1.0
var reduced_motion := false

func _ready() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(STORY_PATH))
	content = parsed if parsed is Dictionary else {}

func begin() -> void:
	if not started:
		started = true
		_enqueue_scene("prologue")
		_pump()

func observe(events: Array, snapshot: Dictionary) -> void:
	if not started:
		begin()
	var match_view: Dictionary = snapshot.get("match", {}) if snapshot.get("match", {}) is Dictionary else {}
	var layer := int(match_view.get("layer", match_view.get("current_layer", 0)))
	if layer > 0 and layer != last_layer:
		last_layer = layer
		var chapters: Array = content.get("chapters", [])
		for chapter in chapters:
			if int(chapter.get("number", 0)) == layer:
				_enqueue_card(chapter)
	for event in events:
		var trigger := _trigger_for(event)
		if not trigger.is_empty():
			_enqueue_scene(trigger)
	_pump()

func _trigger_for(event: Variant) -> String:
	if not event is Dictionary:
		return ""
	var kind := str(event.get("type", event.get("kind", event.get("event", ""))))
	var map := {"combat_won":"first_combat_won", "class_gained":"class_gained", "story_clue":"story_clue", "merchant_opened":"merchant_first", "rest_opened":"rest_first", "boss_started":"before_boss", "victory":"boss_won", "defeat":"party_defeated"}
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

func _pump() -> void:
	if is_instance_valid(current) or queue.is_empty():
		return
	var item: Dictionary = queue.pop_front()
	current = ChapterCardScript.new(item.chapter, reduced_motion) if item.kind == "card" else DialoguePanelScript.new(item.lines, text_scale, reduced_motion)
	add_child(current)
	current.finished.connect(_on_finished.bind(item))
	presentation_started.emit(item)

func _on_finished(item: Dictionary) -> void:
	presentation_finished.emit(item)
	current = null
	_pump()
