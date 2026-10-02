extends "res://tests/test_case.gd"


func test_enemy_manifest_loads_and_every_animation_resolves() -> void:
	var manifest := SpriteSet.enemy_manifest()
	assert_false(manifest.is_empty(), "enemy manifest should load")
	for enemy_id in manifest:
		var sprite_set := SpriteSet.for_enemy(str(enemy_id))
		assert_true(sprite_set != null, "manifest id should resolve: " + str(enemy_id))
		for animation in ["idle", "attack", "hurt", "die"]:
			var frames := sprite_set.frames(animation)
			assert_false(frames.is_empty(), "%s should have %s frames" % [enemy_id, animation])
			for frame in frames:
				assert_true(frame != null, "%s/%s frame should load" % [enemy_id, animation])


func test_every_forest_enemy_resolves_to_a_portrait_texture() -> void:
	var file := FileAccess.open("res://content/forest.json", FileAccess.READ)
	assert_true(file != null, "forest content should open")
	if file == null:
		return
	var content = JSON.parse_string(file.get_as_text())
	assert_true(content is Dictionary and content.get("enemies", {}) is Dictionary,
			"forest content should define enemies")
	if not content is Dictionary or not content.get("enemies", {}) is Dictionary:
		return
	for enemy_id in content["enemies"]:
		var enemy: Dictionary = content["enemies"][enemy_id]
		var sprite := str(enemy.get("sprite", enemy_id))
		assert_true(SpriteSet.enemy_portrait(sprite) != null,
				"%s (%s) should resolve to a portrait texture" % [enemy_id, sprite])


func test_enemy_portrait_uses_first_idle_frame_when_portrait_is_missing() -> void:
	var sprite_set := SpriteSet.for_enemy("thornback_boar")
	assert_true(sprite_set != null)
	var idle := sprite_set.frames("idle")
	assert_false(idle.is_empty())
	assert_eq(SpriteSet.enemy_portrait("thornback_boar"), idle[0])


func test_unknown_enemy_sprite_returns_null_for_code_drawn_fallback() -> void:
	assert_true(SpriteSet.for_enemy("unknown_enemy") == null)


func test_token_dead_animation_uses_the_enemy_die_frames() -> void:
	var sprite_set := SpriteSet.for_enemy("wolf")
	assert_false(sprite_set.frames("dead").is_empty(), "tokens ask for 'dead'; enemy sheets call it 'die'")
	assert_eq(sprite_set.frames("dead").size(), sprite_set.frames("die").size())
	assert_eq(sprite_set.canvas("dead"), sprite_set.canvas("die"))


func test_numeric_enemy_idle_returns_all_frames() -> void:
	var wolf := SpriteSet.for_enemy("wolf")
	assert_eq(wolf.frames("idle").size(), 4, "wolf numeric idle 4 should not collapse to one frame")
	var manifest := SpriteSet.enemy_manifest()
	for enemy_id in manifest:
		var entry: Dictionary = manifest[enemy_id]
		var idle_count = entry.get("animations", {}).get("idle", 0)
		if idle_count is int or idle_count is float:
			var sprite_set := SpriteSet.for_enemy(str(enemy_id))
			assert_eq(sprite_set.frames("idle").size(), int(idle_count),
					"%s numeric idle should return all frames" % enemy_id)


func test_elder_thornwarden_boss_idle_has_six_frames() -> void:
	var sprite_set := SpriteSet.for_enemy("elder_thornwarden")
	assert_true(sprite_set != null, "elder_thornwarden should resolve")
	assert_eq(sprite_set.frames("idle").size(), 6, "boss idle should return all six frames")
	for frame in sprite_set.frames("idle"):
		assert_true(frame != null, "boss idle frame should load")


func test_owner_enemy_sheets_load_with_alpha_and_transparent_corners() -> void:
	for enemy_id in ["old_swordsman", "shrine_spirit", "thornback_boar", "veteran_hunter"]:
		var sprite_set := SpriteSet.for_enemy(enemy_id)
		assert_true(sprite_set != null, "%s should resolve" % enemy_id)
		for animation in ["idle", "attack"]:
			var frames := sprite_set.frames(animation)
			assert_false(frames.is_empty(), "%s/%s should have frames" % [enemy_id, animation])
			for frame in frames:
				assert_true(frame != null, "%s/%s texture should load" % [enemy_id, animation])
				var image := frame.get_image()
				assert_true(image != null and image.get_used_rect().has_area(),
						"%s/%s should contain visible alpha" % [enemy_id, animation])
				assert_eq(image.get_pixel(0, 0).a, 0.0,
						"%s/%s top-left corner should be transparent" % [enemy_id, animation])
				assert_eq(image.get_pixel(image.get_width() - 1, image.get_height() - 1).a, 0.0,
						"%s/%s bottom-right corner should be transparent" % [enemy_id, animation])


func test_bram_classless_idle_and_attack_have_six_frames() -> void:
	var sprite_set := SpriteSet.for_class("classless")
	assert_true(sprite_set != null, "classless should resolve to the Bram sprite set")
	assert_eq(sprite_set.class_id, "bram")
	assert_eq(sprite_set.frames("idle").size(), 6, "Bram idle should have six frames")
	assert_eq(sprite_set.frames("attack").size(), 6, "Bram attack should have six frames")
	for frame in sprite_set.frames("idle") + sprite_set.frames("attack"):
		assert_true(frame != null, "Bram frame should load")
	assert_true(sprite_set.mirrored("idle"), "Bram art is left-facing so tokens mirror it")
	assert_true(sprite_set.mirrored("attack"), "Bram attack is left-facing so tokens mirror it")


func test_bram_missing_hurt_and_dead_fall_back_to_idle() -> void:
	var sprite_set := SpriteSet.for_class("classless")
	var idle := sprite_set.frames("idle")
	assert_false(idle.is_empty(), "Bram idle should load")
	assert_eq(sprite_set.frames("hurt").size(), idle.size(), "Bram hurt should reuse idle frames")
	assert_eq(sprite_set.frames("dead").size(), idle.size(), "Bram dead should reuse idle frames")
	assert_true(sprite_set.mirrored("hurt"), "Bram hurt fallback should mirror like idle")
	assert_true(sprite_set.mirrored("dead"), "Bram dead fallback should mirror like idle")


func test_bram_portrait_loads() -> void:
	var portrait := SpriteSet.portrait("classless")
	assert_true(portrait != null, "Bram portrait should load")
	assert_eq(portrait.get_width(), 260)
	assert_eq(portrait.get_height(), 260)


func test_other_classes_keep_single_idle_frame() -> void:
	var swordsman := SpriteSet.for_class("swordsman")
	assert_true(swordsman != null, "swordsman should still resolve")
	assert_eq(swordsman.frames("idle").size(), 1, "directional hero idle still collapses to one facing frame")
	assert_true(SpriteSet.for_class("unknown_class") == null)
