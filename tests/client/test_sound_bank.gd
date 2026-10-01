extends TestCase


func test_audio_cues_resolve_and_unknown_music_is_ignored() -> void:
	var sound_bank := SoundBank.new()
	# The custom runner executes tests from SceneTree._init before root exists.
	sound_bank._ready()
	var cue_names := [
		"turn", "warn", "hit", "vote", "good", "bad", "click",
		"hover", "cancel", "error", "sword_hit", "enemy_death", "player_down",
		"level_up", "loot_pickup", "victory_sting", "defeat_sting",
		"magic_cast", "heal", "buff", "debuff", "critical", "miss",
	]
	for cue in cue_names:
		assert_true(sound_bank.has_cue(cue), "%s resolves to an asset or fallback player" % cue)
	sound_bank.play_music("unknown_track")
	sound_bank.free()


func test_finished_defeat_is_not_replayed_but_other_music_can_switch() -> void:
	var sound_bank := SoundBank.new()
	sound_bank._ready()
	sound_bank._music_track = "defeat"
	sound_bank._music_active_index = 0

	# The test runner has no scene-tree root, so play_music returns before audio
	# playback. Check the same extracted repeat guard that play_music uses.
	sound_bank._on_music_finished(sound_bank._music_active_index)
	assert_true(sound_bank._should_skip_music("defeat"), "finished defeat music stays selected")
	assert_false(sound_bank._should_skip_music("battle"), "a different track can replace defeat")
	sound_bank._music_track = "battle"
	assert_false(sound_bank._should_skip_music("defeat"), "defeat can play again after switching away")
	sound_bank.free()
