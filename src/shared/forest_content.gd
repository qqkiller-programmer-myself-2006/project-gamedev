class_name ForestContent
extends RefCounted
## Read-only Forest content data (rules, classes, enemies, items, encounters,
## story text). All balance numbers live in content/forest.json, never in
## game logic. MatchServer receives an instance from outside so tests can
## inject tuned or reduced content.

const DEFAULT_PATH := "res://content/forest.json"

var data: Dictionary = {}


static func load_default() -> ForestContent:
	return load_file(DEFAULT_PATH)


static func load_file(path: String) -> ForestContent:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("ForestContent: cannot read %s" % path)
		return from_dict({})
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ForestContent: %s is not a JSON object" % path)
		return from_dict({})
	return from_dict(parsed)


static func from_dict(source: Dictionary) -> ForestContent:
	var content := ForestContent.new()
	content.data = source.duplicate(true)
	return content


## A copy of this content with `overrides` deep-merged on top. Dictionaries
## merge key by key; any other value (including arrays) replaces the original.
func with_overrides(overrides: Dictionary) -> ForestContent:
	return from_dict(_merged(data, overrides))


## Value at a dotted path such as "rules.vote_seconds", or `fallback`.
func get_value(path: String, fallback: Variant = null) -> Variant:
	var node: Variant = data
	for key in path.split("."):
		if typeof(node) != TYPE_DICTIONARY or not node.has(key):
			return fallback
		node = node[key]
	return node


func get_float(path: String, fallback: float = 0.0) -> float:
	return float(get_value(path, fallback))


func get_int(path: String, fallback: int = 0) -> int:
	return int(get_value(path, fallback))


func get_dict(path: String) -> Dictionary:
	var value = get_value(path, {})
	return value if typeof(value) == TYPE_DICTIONARY else {}


func get_array(path: String) -> Array:
	var value = get_value(path, [])
	return value if typeof(value) == TYPE_ARRAY else []


static func _merged(base: Dictionary, overrides: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	for key in overrides:
		var value = overrides[key]
		if typeof(value) == TYPE_DICTIONARY and typeof(out.get(key)) == TYPE_DICTIONARY:
			out[key] = _merged(out[key], value)
		else:
			out[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	return out
