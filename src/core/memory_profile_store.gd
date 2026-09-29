class_name MemoryProfileStore
extends ProfileStore

var profiles: Dictionary = {}
var saves: Array[Dictionary] = []

func load_profile(token: String) -> Dictionary:
	return ProfileStore.normalize(profiles.get(token, {}))

func save_profile(token: String, profile: Dictionary) -> void:
	var copy := ProfileStore.normalize(profile)
	profiles[token] = copy
	saves.append({"token": token, "profile": copy.duplicate(true)})

