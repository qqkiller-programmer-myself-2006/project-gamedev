class_name CutsceneRouter
extends RefCounted
## Walks a cutscene graph and collects flags. Pure logic, no video or UI.
## A node: {clip, subtitles?, variants?{flag: clip}, duration?, next | choices[{label, next, flag?, default?}]}.

const MAX_STEPS := 512

var data: Dictionary
var flags: Dictionary
var current_id := ""
var finished := false


## `initial_flags` (for example {"route_2": true}) select `variants`.
func _init(cutscene: Dictionary, initial_flags: Dictionary = {}) -> void:
	data = cutscene
	flags = initial_flags.duplicate()
	current_id = str(cutscene.get("start", ""))
	finished = not _nodes().has(current_id)


func _nodes() -> Dictionary:
	var nodes = data.get("nodes", {})
	return nodes if nodes is Dictionary else {}


func node() -> Dictionary:
	var found = _nodes().get(current_id, {})
	return found if found is Dictionary else {}


## The clip to play now: the first variant whose flag is set, else the node clip.
func clip() -> String:
	var variants = node().get("variants", {})
	if variants is Dictionary:
		for flag in variants:
			if flags.get(flag, false):
				return str(variants[flag])
	return str(node().get("clip", ""))


func subtitles() -> Array:
	var found = node().get("subtitles", [])
	return found if found is Array else []


func choices() -> Array:
	var found = node().get("choices", [])
	return found if found is Array else []


func has_choices() -> bool:
	return not choices().is_empty()


func is_end() -> bool:
	return not node().has("next") and not has_choices()


## Move along `next`. Returns false (and finishes) at an end node; does nothing at a choice node.
func advance() -> bool:
	if finished or has_choices():
		return false
	if not node().has("next"):
		finished = true
		return false
	return _go(str(node()["next"]))


## Pick choice `index` at a choice node and apply its flag.
func choose(index: int) -> bool:
	var options := choices()
	if finished or index < 0 or index >= options.size():
		return false
	return _take(options[index])


## Skip the rest: follow `next`, take each choice's default (flagged `default`, else the first),
## applying default flags, until an end node. Returns the final flags.
func skip_all() -> Dictionary:
	var steps := 0
	while not finished and steps < MAX_STEPS:
		steps += 1
		if has_choices():
			var options := choices()
			var picked: Dictionary = options[0]
			for option in options:
				if option is Dictionary and option.get("default", false):
					picked = option
					break
			_take(picked)
		elif not advance():
			break
	finished = true
	return flags


func _take(choice: Variant) -> bool:
	if not choice is Dictionary:
		return false
	var flag := str(choice.get("flag", ""))
	if not flag.is_empty():
		flags[flag] = true
	return _go(str(choice.get("next", "")))


func _go(node_id: String) -> bool:
	if not _nodes().has(node_id):
		finished = true
		return false
	current_id = node_id
	return true
