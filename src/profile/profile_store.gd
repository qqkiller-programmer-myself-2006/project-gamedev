class_name ProfileStore
extends RefCounted

const EMPTY_PROFILE := {
	"gems": 0,
	"races_owned": ["Human", "Elf", "Kobold", "Withered"],
	"class_trees": {},
	"prestige": {},
	"last_loadout": {},
	"version": 0,
}

func load_profile(_token: String) -> Dictionary:
	return EMPTY_PROFILE.duplicate(true)

func save_profile(_token: String, _profile: Dictionary) -> void:
	pass

## Store writes are fire-and-forget from the Match's point of view.
func save_profile_async(token: String, profile: Dictionary) -> void:
	save_profile(token, profile)

static func normalize(profile: Dictionary) -> Dictionary:
	var out := EMPTY_PROFILE.duplicate(true)
	for key in profile:
		out[key] = profile[key].duplicate(true) if profile[key] is Dictionary or profile[key] is Array else profile[key]
	for field in ["class_trees", "prestige"]:
		var values: Dictionary = out.get(field, {})
		if values.has("rogue"):
			if not values.has("assassin"):
				values["assassin"] = values["rogue"]
			values.erase("rogue")
		out[field] = values
	var loadout: Dictionary = out.get("last_loadout", {})
	if loadout.get("class", "") == "rogue":
		loadout["class"] = "assassin"
	out["last_loadout"] = loadout
	if not out["races_owned"].has("Human"):
		out["races_owned"].push_front("Human")
	return out
