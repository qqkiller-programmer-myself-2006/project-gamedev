class_name ProfileStore
extends RefCounted

const EMPTY_PROFILE := {
	"gems": 0,
	"races_owned": ["Human", "Elf", "Kobold", "Withered"],
	"class_trees": {},
	"prestige": {},
	"last_loadout": {},
}

func load_profile(_token: String) -> Dictionary:
	return EMPTY_PROFILE.duplicate(true)

func save_profile(_token: String, _profile: Dictionary) -> void:
	pass

static func normalize(profile: Dictionary) -> Dictionary:
	var out := EMPTY_PROFILE.duplicate(true)
	for key in profile:
		out[key] = profile[key].duplicate(true) if profile[key] is Dictionary or profile[key] is Array else profile[key]
	if not out["races_owned"].has("Human"):
		out["races_owned"].push_front("Human")
	return out

