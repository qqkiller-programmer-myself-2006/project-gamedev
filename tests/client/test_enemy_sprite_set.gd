extends "res://tests/test_case.gd"


func test_enemy_manifest_loads_and_every_animation_resolves() -> void:
	var manifest := SpriteSet.enemy_manifest()
	assert_false(manifest.is_empty(), "enemy manifest should load")
	for enemy_id in manifest:
		var sprite_set := SpriteSet.for_enemy(str(enemy_id))
		assert_true(sprite_set != null, "manifest id should resolve: " + str(enemy_id))
		var entry: Dictionary = manifest[enemy_id]
		var defined: Dictionary = entry.get("animations", {})
		for animation in ["idle", "attack", "hurt", "die"]:
			if not defined.has(animation) and (animation == "hurt" or animation == "die"):
				continue
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


func test_elder_thornwarden_idle_and_attack_each_load_six_frames() -> void:
	var sprite_set := SpriteSet.for_enemy("elder_thornwarden")
	assert_true(sprite_set != null, "elder_thornwarden should resolve")
	var idle := sprite_set.frames("idle")
	assert_eq(idle.size(), 6, "elder_thornwarden idle should have six frames")
	for frame in idle:
		assert_true(frame != null, "elder_thornwarden idle frame should load")
	var attack := sprite_set.frames("attack")
	assert_eq(attack.size(), 6, "elder_thornwarden attack should have six frames")
	for frame in attack:
		assert_true(frame != null, "elder_thornwarden attack frame should load")


func test_classless_hero_loads_bram_frames_with_hurt_dead_fallback() -> void:
	var sprite_set := SpriteSet.for_class("classless")
	assert_true(sprite_set != null, "classless should resolve to the bram entry")
	var idle := sprite_set.frames("idle")
	assert_eq(idle.size(), 6, "bram idle should have six frames")
	for frame in idle:
		assert_true(frame != null, "bram idle frame should load")
	var attack := sprite_set.frames("attack")
	assert_eq(attack.size(), 6, "bram attack should have six frames")
	for frame in attack:
		assert_true(frame != null, "bram attack frame should load")
	var hurt := sprite_set.frames("hurt")
	assert_false(hurt.is_empty(), "classless hurt should fall back to idle frames")
	for frame in hurt:
		assert_true(frame != null, "classless hurt fallback frame should load")
	var dead := sprite_set.frames("dead")
	assert_false(dead.is_empty(), "classless dead should fall back to idle frames")
	for frame in dead:
		assert_true(frame != null, "classless dead fallback frame should load")


func test_classless_portrait_loads() -> void:
	var portrait := SpriteSet.portrait("classless")
	assert_true(portrait != null, "classless portrait should load")
