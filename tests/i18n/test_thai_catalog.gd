extends "res://tests/test_case.gd"
## Regression checks matching tools/i18n/check_po.gd.

const POT_PATH := "res://i18n/messages.pot"
const PO_PATH := "res://i18n/th.po"
const UI_TEXT_GROUPS := ["ERRORS", "TYPE_LABELS", "TYPE_TAGS", "TYPE_HELP", "HINTS", "CONFIRM", "LABELS", "EMPTY", "WHY"]


func test_every_ui_text_string_is_in_catalog() -> void:
	var script = load("res://src/client/ui/ui_text.gd")
	var constants: Dictionary = script.get_script_constant_map()
	var pot := _read_po(POT_PATH)
	var po := _read_po(PO_PATH)
	for group in UI_TEXT_GROUPS:
		for message in _strings(constants[group]):
			assert_true(pot.has(message), "UiText msgid missing from POT: %s" % message)
			assert_true(po.has(message) and not str(po.get(message, "")).is_empty(), "UiText msgid missing Thai: %s" % message)


func test_locale_switch_and_formatted_placeholder() -> void:
	Tr.setup("th")
	assert_eq(Tr.t("Forest"), "ป่า", "Thai catalog active")
	assert_eq(Tr.t("%d Gems" % 5), "อัญมณี 5 เม็ด", "formatted msgid preserves its number")
	assert_eq(Tr.t("Not enough Gems: this costs 10, you have 4."), "อัญมณีไม่พอ: ต้องใช้ 10 เม็ด คุณมี 4 เม็ด.", "each placeholder keeps its own value")
	assert_eq(Tr.t("Something went wrong (server_error)."), "เกิดข้อผิดพลาด (server_error).", "translated fallback keeps its code placeholder")
	Tr.setup("en")
	assert_eq(Tr.t("Forest"), "Forest", "English source remains available")
	assert_eq(Tr.t("%d Gems" % 5), "5 Gems", "English formatting remains intact")
	assert_eq(Tr.t("Not enough Gems: this costs 10, you have 4."), "Not enough Gems: this costs 10, you have 4.", "English preserves both values")
	assert_eq(Tr.t("Something went wrong (server_error)."), "Something went wrong (server_error).", "English fallback keeps its code placeholder")


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


func _strings(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Dictionary:
		for key in value:
			result.append_array(_strings(value[key]))
	elif value is Array:
		for child in value:
			result.append_array(_strings(child))
	elif value is String:
		result.append(value)
	return result
