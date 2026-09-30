extends SceneTree
## Validate the Thai catalog against the extracted POT.

const POT_PATH := "res://i18n/messages.pot"
const PO_PATH := "res://i18n/th.po"


func _init() -> void:
	var failures := _check_catalog()
	if failures.is_empty():
		print("Thai catalog OK: %d msgids translated" % _read_po(PO_PATH).size())
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)


func _check_catalog() -> Array[String]:
	var failures: Array[String] = []
	var pot := _read_po(POT_PATH)
	var po := _read_po(PO_PATH)
	if not FileAccess.file_exists(PO_PATH):
		failures.append("missing %s" % PO_PATH)
		return failures
	for message in pot:
		if not po.has(message):
			failures.append("missing msgid: %s" % message)
			continue
		if str(po[message]).is_empty():
			failures.append("empty msgstr: %s" % message)
		if _placeholders(message) != _placeholders(str(po[message])):
			failures.append("placeholder mismatch: %s" % message)
	var translation = load(PO_PATH)
	if translation == null or not translation is Translation:
		failures.append("Godot could not load %s as Translation" % PO_PATH)
	return failures


func _placeholders(value: String) -> Array[String]:
	var found: Array[String] = []
	var regex := RegEx.new()
	regex.compile("\\{[^{}]+\\}|%[sd]")
	for match in regex.search_all(value):
		found.append(match.get_string())
	found.sort()
	return found


func _read_po(path: String) -> Dictionary:
	var entries: Dictionary = {}
	if not FileAccess.file_exists(path):
		return entries
	var lines := FileAccess.get_file_as_string(path).split("\n")
	var message_id := ""
	var message_str := ""
	var mode := ""
	var has_id := false
	for raw_line in lines:
		var line := raw_line.strip_edges()
		if line.is_empty():
			if has_id and not message_id.is_empty():
				entries[message_id] = message_str
			message_id = ""
			message_str = ""
			mode = ""
			has_id = false
			continue
		if line.begins_with("#"):
			continue
		if line.begins_with("msgid "):
			if has_id and not message_id.is_empty():
				entries[message_id] = message_str
			message_id = _parse_quoted(line.trim_prefix("msgid "))
			message_str = ""
			mode = "id"
			has_id = true
		elif line.begins_with("msgstr "):
			message_str = _parse_quoted(line.trim_prefix("msgstr "))
			mode = "str"
		elif line.begins_with("\""):
			if mode == "id":
				message_id += _parse_quoted(line)
			elif mode == "str":
				message_str += _parse_quoted(line)
	if has_id and not message_id.is_empty():
		entries[message_id] = message_str
	return entries


func _parse_quoted(value: String) -> String:
	var parsed = JSON.parse_string(value)
	return str(parsed) if parsed != null else ""
