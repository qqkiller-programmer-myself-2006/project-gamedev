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


func test_unknown_enemy_sprite_returns_null_for_code_drawn_fallback() -> void:
	assert_true(SpriteSet.for_enemy("unknown_enemy") == null)


func test_token_dead_animation_uses_the_enemy_die_frames() -> void:
	var sprite_set := SpriteSet.for_enemy("wolf")
	assert_false(sprite_set.frames("dead").is_empty(), "tokens ask for 'dead'; enemy sheets call it 'die'")
	assert_eq(sprite_set.frames("dead").size(), sprite_set.frames("die").size())
	assert_eq(sprite_set.canvas("dead"), sprite_set.canvas("die"))
