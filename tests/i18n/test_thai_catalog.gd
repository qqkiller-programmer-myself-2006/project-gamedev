extends "res://tests/test_case.gd"
## Regression checks matching tools/i18n/check_po.gd.

const POT_PATH := "res://i18n/messages.pot"
const PO_PATH := "res://i18n/th.po"


func test_every_extracted_msgid_is_translated() -> void:
	var pot := _read_po(POT_PATH)
	var po := _read_po(PO_PATH)
	assert_true(not pot.is_empty(), "POT contains msgids")
	for message in pot:
		assert_true(po.has(message), "missing msgid: %s" % message)
		if po.has(message):
			assert_false(str(po[message]).is_empty(), "empty msgstr: %s" % message)


func test_placeholders_are_preserved() -> void:
	var pot := _read_po(POT_PATH)
	var po := _read_po(PO_PATH)
	for message in pot:
		if po.has(message):
			assert_eq(_placeholders(message), _placeholders(str(po[message])), "placeholder mismatch: %s" % message)


func test_catalog_loads_as_translation() -> void:
	var translation = load(PO_PATH)
	assert_true(translation != null and translation is Translation, "th.po loads as Translation")


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
