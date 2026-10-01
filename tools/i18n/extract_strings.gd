extends SceneTree
## Extract player-facing content strings into a gettext POT and Thai PO catalog.

const INPUTS := ["content/forest.json", "content/story_mode.json"]
const UI_TEXT_PATH := "res://src/client/ui/ui_text.gd"
const UI_TEXT_GROUPS := ["ERRORS", "TYPE_LABELS", "TYPE_TAGS", "TYPE_HELP", "HINTS", "CONFIRM", "LABELS", "EMPTY", "WHY"]
const FORMATTED_FALLBACKS := [
	"%d Gems",
	"Not enough Gems: this costs %d, you have %d.",
	"Something went wrong (%s).",
]
const UI_LITERAL_LABELS := [
	"Shop", "Crafting", "Inventory", "Equipment", "Stash", "Craft", "Abilities",
	"Time played", "Reached", "Enemies defeated", "Classes discovered",
	"Search...", "Hide", "Hide the camp to look at the field", "Buy", "Inspect", "Ready [R]",
	"Fight [F]", "Items [I]", "Focus [O]", "Attack [A]", "Defend [D]", "Skill [S] - needs a Class",
	"Vote closes in %ds", "The journey continues in %ds", "%ds left to act%s", "Offer closes in %ds",
	"The journey continues in %ds.", "Gold amount", "Tip", "Vote", "Ready %d of %d.",
	"Guardian Boss", "Guardian", "Swordsman", "Archer", "Mage", "Assassin", "Classless",
	"[%d] Vote for this path", "[%d] Choose this path", "Chosen", "Profile", "Races", "Boons", "Records",
	"Your turn!", "Stat Points", "Reset Skills", "Status: Unlocked", "Cost: %s", "READY",
	"none", "Guardian Boss defeated", "Story Clues found", "Room code copied.",
]
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
	var ui_text = load(UI_TEXT_PATH)
	for group in UI_TEXT_GROUPS:
		_add_ui_value(ui_text.get_script_constant_map()[group], group)
	for message in FORMATTED_FALLBACKS:
		_add_message(message, "src/client/ui/tr.gd:formatted_fallback")
	for message in UI_LITERAL_LABELS:
		_add_message(message, "src/client/ui/ui_text.gd:client_literal")
	_scan_client_translations("res://src/client", "src/client")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://i18n"))
	_write_pot()
	_write_po()
	print("Extracted %d msgids" % _messages.size())
	quit(0)


func _scan_client_translations(directory: String, reference_root: String) -> void:
	var dir := DirAccess.open(directory)
	if dir == null:
		push_error("Could not open %s" % directory)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		var path := directory.path_join(name)
		if dir.current_is_dir():
			if not name.begins_with("."):
				_scan_client_translations(path, reference_root.path_join(name))
		elif name.ends_with(".gd"):
			_scan_translation_calls(path, reference_root.path_join(name))
			_scan_ui_literals(path, reference_root.path_join(name))
		name = dir.get_next()
	dir.list_dir_end()


func _scan_translation_calls(path: String, reference: String) -> void:
	var source := FileAccess.get_file_as_string(path)
	var regex := RegEx.new()
	regex.compile("Tr\\.t\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\"")
	for found in regex.search_all(source):
		var parsed = JSON.parse_string("\"%s\"" % found.get_string(1))
		if parsed is String:
			_add_message(parsed, "%s:%d" % [reference, source.substr(0, found.get_start()).count("\n") + 1])


func _scan_ui_literals(path: String, reference: String) -> void:
	var source := FileAccess.get_file_as_string(path)
	var call_regex := RegEx.new()
	call_regex.compile("(?:UiKit\\.(?:label|para|button|primary|badge|pixel_label)|_(?:text|button|center)|Icons\\.with_text)\\(\\s*")
	var literal_regex := RegEx.new()
	literal_regex.compile("\"((?:\\\\.|[^\"\\\\])*)\"")
	for call in call_regex.search_all(source):
		var start := call.get_end()
		var end := _first_argument_end(source, start)
		if end <= start:
			continue
		var arguments: Array[String] = [source.substr(start, end - start)]
		if source.substr(call.get_start(), call.get_end() - call.get_start()).contains("Icons.with_text"):
			var second_start := end + 1
			while second_start < source.length() and source.substr(second_start, 1).strip_edges().is_empty():
				second_start += 1
			var second_end := _first_argument_end(source, second_start)
			arguments.append(source.substr(second_start, second_end - second_start))
		for argument_text in arguments:
			for found in literal_regex.search_all(argument_text):
				var parsed = JSON.parse_string("\"%s\"" % found.get_string(1))
				if parsed is String and parsed.strip_edges().length() > 1 and parsed.to_lower() != parsed:
					_add_message(parsed, "%s:%d" % [reference, source.substr(0, start + found.get_start()).count("\n") + 1])


func _first_argument_end(source: String, start: int) -> int:
	var depth := 0
	var in_string := false
	var escaped := false
	for index in range(start, source.length()):
		var character := source.substr(index, 1)
		if in_string:
			if escaped:
				escaped = false
			elif character == "\\":
				escaped = true
			elif character == "\"":
				in_string = false
		elif character == "\"":
			in_string = true
		elif character == "(" or character == "[" or character == "{":
			depth += 1
		elif character == ")" or character == "]" or character == "}":
			if depth == 0:
				return index
			depth -= 1
		elif character == "," and depth == 0:
			return index
	return source.length()


func _add_ui_value(value: Variant, path: String) -> void:
	if value is Dictionary:
		for key in value:
			_add_ui_value(value[key], "%s.%s" % [path, str(key)])
	elif value is Array:
		for index in value.size():
			_add_ui_value(value[index], "%s[%d]" % [path, index])
	elif value is String:
		_add_message(value, "src/client/ui/ui_text.gd:%s" % path)


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
