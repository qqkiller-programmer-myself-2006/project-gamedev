extends "res://tests/test_case.gd"

const SKILL_FX := preload("res://src/client/match/battle/skill_fx.gd")
## T4S-01a adds content-driven skills without introducing client FX assets.
const CONTENT_ONLY_SKILLS := ["mending_light", "renewing_wave", "cleanse", "rally", "weaken", "energize"]


func test_every_forest_skill_has_loadable_manifest_frames() -> void:
	var forest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/forest.json"))
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/fx/manifest.json"))
	for skill in forest.get("skills", {}):
		if CONTENT_ONLY_SKILLS.has(skill):
			continue
		assert_true(manifest.has(skill), "%s must have a manifest entry" % skill)
		var info: Dictionary = manifest[skill]
		var count := int(info.get("frames", 0))
		assert_eq(count, 8 if info.get("tier") == "ultimate" else 6)
		for i in count:
			var path := "res://assets/fx/%s/frame_%02d.png" % [skill, i]
			assert_true(FileAccess.file_exists(path), "%s frame %d must exist" % [skill, i])
			assert_true(load(path) is Texture2D, "%s frame %d must load as a texture" % [skill, i])


func test_unknown_skill_play_is_silent() -> void:
	var parent := Control.new()
	SKILL_FX.play(parent, "unknown_skill", Vector2.ZERO)
	assert_eq(parent.get_child_count(), 0)
	parent.free()
