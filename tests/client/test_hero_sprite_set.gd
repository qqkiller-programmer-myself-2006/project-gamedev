extends "res://tests/test_case.gd"

const CLASSES := ["archer", "mage", "swordsman", "guardian", "assassin", "bram"]


func test_every_hero_animation_frame_resolves() -> void:
	for class_id in CLASSES:
		var sprite_set := SpriteSet.for_class(class_id)
		assert_true(sprite_set != null, "class should resolve: " + class_id)
		for animation in ["idle", "attack"]:
			var frames := sprite_set.frames(animation)
			assert_false(frames.is_empty(), "%s should have %s frames" % [class_id, animation])


func test_hero_frames_come_from_one_consistent_sheet() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/heroes/manifest.json"))
	for class_id in manifest:
		var text := JSON.stringify(manifest[class_id].get("animations", {}))
		assert_false(text.contains("generated"),
				"%s must not mix in frames from a differently drawn character" % class_id)
