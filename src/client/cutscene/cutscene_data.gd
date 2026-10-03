class_name CutsceneData
extends RefCounted
## Loads and validates `content/cutscenes/<id>.json` (ADR-0015). Pure data, no video.

const ROOT := "res://content/cutscenes/"


## Returns {"ok": bool, "data": Dictionary, "errors": Array[String]}.
static func load_cutscene(id: String) -> Dictionary:
	var path := ROOT + id + ".json"
	if not FileAccess.file_exists(path):
		return {"ok": false, "data": {}, "errors": ["missing cutscene file: %s" % path]}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {"ok": false, "data": {}, "errors": ["cutscene is not a JSON object: %s" % path]}
	var errors := validate(parsed)
	return {"ok": errors.is_empty(), "data": parsed, "errors": errors}


static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var nodes = data.get("nodes", null)
	if not nodes is Dictionary or (nodes as Dictionary).is_empty():
		errors.append("cutscene has no nodes")
		return errors
	var start := str(data.get("start", ""))
	if not nodes.has(start):
		errors.append("start node '%s' does not exist" % start)
	for node_id in nodes:
		var node = nodes[node_id]
		if not node is Dictionary:
			errors.append("node '%s' is not an object" % node_id)
			continue
		_validate_node(str(node_id), node, nodes, errors)
	_check_next_cycles(nodes, errors)
	return errors


static func _validate_node(node_id: String, node: Dictionary, nodes: Dictionary, errors: Array[String]) -> void:
	var clips: Array = [str(node.get("clip", ""))]
	if str(clips[0]).is_empty():
		errors.append("node '%s' has no clip" % node_id)
		clips.clear()
	var variants = node.get("variants", {})
	if variants is Dictionary:
		for flag in variants:
			clips.append(str(variants[flag]))
	for clip in clips:
		if not ResourceLoader.exists(clip) and not FileAccess.file_exists(clip):
			errors.append("node '%s' clip not found: %s" % [node_id, clip])
	var has_next := node.has("next")
	var has_choices := node.has("choices")
	if has_next and has_choices:
		errors.append("node '%s' has both next and choices" % node_id)
	if has_next and not nodes.has(str(node["next"])):
		errors.append("node '%s' next points to unknown node '%s'" % [node_id, node["next"]])
	if has_choices:
		var choices = node["choices"]
		if not choices is Array or (choices as Array).is_empty():
			errors.append("node '%s' choices must be a non-empty array" % node_id)
		else:
			for choice in choices:
				if not choice is Dictionary or not nodes.has(str((choice as Dictionary).get("next", ""))):
					errors.append("node '%s' has a choice with an unknown next" % node_id)
	var subtitles = node.get("subtitles", [])
	if not subtitles is Array:
		errors.append("node '%s' subtitles must be an array" % node_id)


## `next` links may never loop; only choices may lead back.
static func _check_next_cycles(nodes: Dictionary, errors: Array[String]) -> void:
	for first in nodes:
		var seen := {}
		var cursor := str(first)
		while nodes.has(cursor) and nodes[cursor] is Dictionary and (nodes[cursor] as Dictionary).has("next"):
			if seen.has(cursor):
				errors.append("cycle through next at node '%s' (cycles are only allowed through choices)" % cursor)
				return
			seen[cursor] = true
			cursor = str(nodes[cursor]["next"])
