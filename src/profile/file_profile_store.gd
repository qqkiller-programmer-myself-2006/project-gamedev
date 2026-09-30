class_name FileProfileStore
extends ProfileStore

var directory: String

func _init(data_directory: String = "user://profiles") -> void:
	directory = data_directory
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))

func _path(token: String) -> String:
	return directory.path_join(token + ".json")

func load_profile(token: String) -> Dictionary:
	var file := _path(token)
	if not FileAccess.file_exists(file):
		return ProfileStore.normalize({})
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(file))
	return ProfileStore.normalize(parsed if parsed is Dictionary else {})

func save_profile(token: String, profile: Dictionary) -> void:
	var file := FileAccess.open(_path(token), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(ProfileStore.normalize(profile)))
		file.close()
