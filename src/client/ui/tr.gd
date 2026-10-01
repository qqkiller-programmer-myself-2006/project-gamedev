class_name Tr
extends RefCounted
## Client-side gettext lookup. The server never loads the locale catalog.

const CATALOG_PATH := "res://i18n/th.po"

static var _catalog: Translation
static var _formatted: Array[Dictionary] = []
static var _msgids: Array[String] = []


static func setup(language: String = "th") -> void:
	if _catalog == null:
		_catalog = load(CATALOG_PATH) as Translation
	if _catalog != null and not TranslationServer.get_loaded_locales().has(_catalog.locale):
		TranslationServer.add_translation(_catalog)
	if _catalog != null and _formatted.is_empty():
		for msgid in _catalog.get_message_list():
			_msgids.append(str(msgid))
			if str(msgid).contains("%") or str(msgid).contains("{"):
				var pattern := _pattern_for(str(msgid))
				if pattern != null:
					_formatted.append({"msgid": str(msgid), "regex": pattern})
		_msgids.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	TranslationServer.set_locale("en" if language.to_lower() == "en" else "th")


static func t(msgid: String) -> String:
	var translated := TranslationServer.translate(msgid)
	if translated != msgid:
		return translated
	for source in _msgids:
		if not source.contains("%") and not source.contains("{"):
			continue
		var regex := _pattern_for(source)
		if regex == null:
			continue
		var found := regex.search(msgid)
		if found == null:
			continue
		var result := TranslationServer.translate(source)
		for index in range(1, found.get_group_count() + 1):
			var placeholder := _placeholders(source)[index - 1]
			var placeholder_regex := RegEx.new()
			placeholder_regex.compile(_regex_escape(placeholder))
			result = placeholder_regex.sub(result, found.get_string(index), false)
		return result
	var embedded := msgid
	for source in _msgids:
		if source.length() > 1 and embedded.contains(source):
			var translated_source := TranslationServer.translate(source)
			if translated_source != source:
				embedded = embedded.replace(source, translated_source)
	return embedded


static func _pattern_for(msgid: String) -> RegEx:
	var pattern := "^"
	var placeholders := RegEx.new()
	placeholders.compile("\\{[^{}]+\\}|%[sd]")
	var cursor := 0
	for found in placeholders.search_all(msgid):
		pattern += _regex_escape(msgid.substr(cursor, found.get_start() - cursor)) + "(.+?)"
		cursor = found.get_end()
	pattern += _regex_escape(msgid.substr(cursor)) + "$"
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return null
	return regex


static func _placeholders(msgid: String) -> Array[String]:
	var result: Array[String] = []
	var regex := RegEx.new()
	regex.compile("\\{[^{}]+\\}|%[sd]")
	for found in regex.search_all(msgid):
		result.append(found.get_string())
	return result


static func _regex_escape(value: String) -> String:
	var result := value
	for character in ["\\", ".", "^", "$", "|", "?", "*", "+", "(", ")", "[", "]", "{", "}"]:
		result = result.replace(character, "\\" + character)
	return result
