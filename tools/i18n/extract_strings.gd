extends SceneTree
## Extract player-facing content strings into a gettext POT and Thai PO catalog.

const INPUTS := ["content/forest.json", "content/story_mode.json"]
const POT_PATH := "i18n/messages.pot"
const PO_PATH := "i18n/th.po"

const DISPLAY_KEYS := [
	"name", "role", "bio", "description", "text", "hint", "title", "subtitle",
	"intro", "pass", "fail", "telegraph", "label", "category", "greeting"
]
const DISPLAY_PARENT_KEYS := ["type_labels", "categories", "regions"]
const DISPLAY_KEY_MAPS := ["meta.races", "meta.boons"]

var _messages: Dictionary = {}


func _init() -> void:
	for input_path in INPUTS:
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://" + input_path))
		if parsed == null:
			push_error("Could not parse %s" % input_path)
			quit(1)
			return
		_walk(parsed, input_path, "")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://i18n"))
	_write_pot()
	_write_po()
	print("Extracted %d msgids" % _messages.size())
	quit(0)


func _walk(value: Variant, source: String, path: String) -> void:
	if value is Dictionary:
		var display_key_map := _is_display_key_map(path)
		for key in value:
			var key_text := str(key)
			var child_path := _child_path(path, key_text)
			if display_key_map and _is_display_map_key(key_text):
				_add_message(key_text, "%s:%s" % [source, child_path.trim_prefix(".")])
			_walk(value[key], source, child_path)
	elif value is Array:
		for index in value.size():
			_walk(value[index], source, "%s[%d]" % [path, index])
	elif value is String:
		if _is_display_value(path, str(value)):
			_add_message(str(value), "%s:%s" % [source, path.trim_prefix(".")])


func _child_path(path: String, key: String) -> String:
	if key.is_valid_identifier():
		return "%s.%s" % [path, key]
	return "%s[\"%s\"]" % [path, _po_escape(key)]


func _is_display_key_map(path: String) -> bool:
	for suffix in DISPLAY_KEY_MAPS:
		if path.ends_with(suffix):
			return true
	return false


func _is_display_map_key(key: String) -> bool:
	return not key.is_empty() and not key.to_lower() in ["id", "key"]


func _is_display_value(path: String, value: String) -> bool:
	if value.strip_edges().is_empty():
		return false
	var segments := path.split(".")
	var leaf := segments[segments.size() - 1]
	var bracket := leaf.find("[")
	if bracket >= 0:
		leaf = leaf.substr(0, bracket)
	if leaf in DISPLAY_KEYS:
		return true
	for parent_key in DISPLAY_PARENT_KEYS:
		# Children appear as `.parent.key`, `.parent["1"]` or `.parent[0]`.
		if path.contains("." + parent_key + ".") or path.contains("." + parent_key + "["):
			return true
	if path.ends_with(".boss.region"):
		return true
	return false


func _add_message(message: String, reference: String) -> void:
	if message.strip_edges().is_empty():
		return
	# `#:` references are whitespace-separated, so keys such as "The Chosen One" encode their spaces.
	reference = reference.replace(" ", "%20")
	if not _messages.has(message):
		_messages[message] = []
	if not _messages[message].has(reference):
		_messages[message].append(reference)


func _write_pot() -> void:
	var output := _po_header("en")
	var ids: Array = _messages.keys()
	ids.sort()
	for message in ids:
		output += _entry_comments(_messages[message])
		output += "msgid \"%s\"\nmsgstr \"\"\n\n" % _po_escape(message)
	FileAccess.open("res://" + POT_PATH, FileAccess.WRITE).store_string(output)


func _write_po() -> void:
	var existing := _read_po(PO_PATH)
	var current: Dictionary = existing.get("current", {})
	var obsolete: Dictionary = existing.get("obsolete", {})
	var output := _po_header("th")
	var ids: Array = _messages.keys()
	ids.sort()
	for message in ids:
		var translation := str(current.get(message, ""))
		output += _entry_comments(_messages[message])
		output += "msgid \"%s\"\nmsgstr \"%s\"\n\n" % [_po_escape(message), _po_escape(translation)]
	var old_ids: Array = obsolete.keys()
	for message in current:
		if message != "" and not _messages.has(message):
			if not old_ids.has(message):
				old_ids.append(message)
	old_ids.sort()
	for message in old_ids:
		if message == "" or _messages.has(message):
			continue
		output += "#~ msgid \"%s\"\n#~ msgstr \"%s\"\n\n" % [_po_escape(message), _po_escape(str(obsolete.get(message, current.get(message, ""))))]
	FileAccess.open("res://" + PO_PATH, FileAccess.WRITE).store_string(output)


func _po_header(language: String) -> String:
	var plural := "nplurals=1; plural=0;" if language == "th" else "nplurals=2; plural=(n != 1);"
	return "msgid \"\"\nmsgstr \"\"\n" + \
		"\"Project-Id-Version: beyond-the-worlds-end\\n\"\n" + \
		"\"Content-Type: text/plain; charset=UTF-8\\n\"\n" + \
		"\"Language: %s\\n\"\n" % language + \
		"\"Plural-Forms: %s\\n\"\n\n" % plural


func _entry_comments(references: Array) -> String:
	var sorted_refs := references.duplicate()
	sorted_refs.sort()
	return "#: %s\n" % " ".join(sorted_refs)


func _read_po(path: String) -> Dictionary:
	var result := {"current": {}, "obsolete": {}}
	if not FileAccess.file_exists("res://" + path):
		return result
	var lines := FileAccess.get_file_as_string("res://" + path).split("\n")
	var message_id := ""
	var message_str := ""
	var mode := ""
	var obsolete := false
	var has_id := false
	for raw_line in lines:
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#") and not line.begins_with("#~"):
			if line.is_empty():
				_store_po_entry(result, message_id, message_str, obsolete, has_id)
				message_id = ""
				message_str = ""
				mode = ""
				obsolete = false
				has_id = false
			continue
		if line.begins_with("#~ msgid "):
			_store_po_entry(result, message_id, message_str, obsolete, has_id)
			message_id = _parse_quoted(line.trim_prefix("#~ msgid "))
			message_str = ""
			mode = "id"
			obsolete = true
			has_id = true
		elif line.begins_with("#~ msgstr "):
			message_str = _parse_quoted(line.trim_prefix("#~ msgstr "))
			mode = "str"
			obsolete = true
		elif line.begins_with("msgid "):
			_store_po_entry(result, message_id, message_str, obsolete, has_id)
			message_id = _parse_quoted(line.trim_prefix("msgid "))
			message_str = ""
			mode = "id"
			obsolete = false
			has_id = true
		elif line.begins_with("msgstr "):
			message_str = _parse_quoted(line.trim_prefix("msgstr "))
			mode = "str"
		elif line.begins_with("#~ "):
			continue
		elif line.begins_with("\""):
			if mode == "id":
				message_id += _parse_quoted(line)
			elif mode == "str":
				message_str += _parse_quoted(line)
	_store_po_entry(result, message_id, message_str, obsolete, has_id)
	return result


func _store_po_entry(result: Dictionary, message_id: String, message_str: String, obsolete: bool, has_id: bool) -> void:
	if not has_id or message_id.is_empty():
		return
	if obsolete:
		result.obsolete[message_id] = message_str
	else:
		result.current[message_id] = message_str


func _parse_quoted(value: String) -> String:
	var parsed = JSON.parse_string(value)
	return str(parsed) if parsed != null else ""


func _po_escape(value: String) -> String:
	return value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "").replace("\n", "\\n")
