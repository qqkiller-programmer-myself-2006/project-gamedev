class_name StorySave
extends RefCounted

const PATH := "user://story_save.json"
const TEMP_PATH := "user://story_save.json.tmp"
const VERSION := 1

func save(data: Dictionary) -> bool:
	var payload := data.duplicate(true)
	payload["version"] = VERSION
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	var dir := DirAccess.open("user://")
	if dir == null or dir.rename("story_save.json.tmp", "story_save.json") != OK:
		return false
	return true

func load() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(PATH)) != OK:
		# Keep the Continue path alive for one attempt so the normal restore
		# rejection can explain the problem and clear the broken file.
		return {"version": VERSION, "_invalid": true}
	var parsed = parser.data
	if not parsed is Dictionary:
		return {"version": VERSION, "_invalid": true}
	return parsed

func has_save() -> bool:
	return FileAccess.file_exists(PATH)

func clear() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
