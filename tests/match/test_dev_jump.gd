extends TestCase
## The dev Playtest jump (dev_jump): only the embedded Playtest server accepts it.

const CAVES := ["Cave Mouth", "Bone Pit", "Spider Hollow"]


func _start(seed_value: int, allow_dev: bool = true) -> Array:
	var h := MatchHarness.new(seed_value)
	h.server.allow_dev = allow_dev
	var session := h.start_with_humans(1)[0]
	return [h, session]


func _jump(h: MatchHarness, session: int, target: String, extra: Dictionary = {}) -> Dictionary:
	var cmd := {"type": "dev_jump", "target": target}
	cmd.merge(extra, true)
	return h.server.command(session, cmd)


func test_each_target_lands_on_the_right_encounter() -> void:
	for target in ["combat", "merchant", "rest", "class", "story", "treasure"]:
		var pair := _start(7)
		var h: MatchHarness = pair[0]
		assert_ok(_jump(h, pair[1], target), target)
		var view := h.match_view(pair[1])
		assert_eq(view["phase"], "encounter", target)
		assert_eq(view["encounter"]["type"], target, target)
		assert_true(view["layer"] >= 1 and view["layer"] <= 4, "%s is a forest Layer" % target)


func test_cave_is_a_layer_5_combat() -> void:
	var pair := _start(7)
	var h: MatchHarness = pair[0]
	assert_ok(_jump(h, pair[1], "cave"))
	var view := h.match_view(pair[1])
	assert_eq(view["layer"], 5)
	assert_eq(view["encounter"]["type"], "combat")
	assert_has(CAVES, view["encounter"]["name"])
	assert_eq(view["party"][0]["level"], 5)


func test_boss_starts_the_guardian_fight() -> void:
	var pair := _start(7)
	var h: MatchHarness = pair[0]
	assert_ok(_jump(h, pair[1], "boss"))
	var view := h.match_view(pair[1])
	assert_eq(view["phase"], "boss")
	assert_eq(view["encounter"]["type"], "boss")
	assert_eq(view["party"][0]["level"], 6)


func test_class_is_set_and_layer_and_level_follow() -> void:
	var pair := _start(7)
	var h: MatchHarness = pair[0]
	assert_ok(_jump(h, pair[1], "merchant", {"class": "mage", "layer": 3}))
	var view := h.match_view(pair[1])
	assert_eq(view["layer"], 3)
	assert_eq(view["party"][0]["class"], "mage")
	assert_eq(view["party"][0]["level"], 3)
	assert_true(view["party"][0]["gold"] > 0, "gold to shop with")


func test_journey_target_only_sets_the_class() -> void:
	var pair := _start(7)
	var h: MatchHarness = pair[0]
	assert_ok(_jump(h, pair[1], "journey", {"class": "archer"}))
	var view := h.match_view(pair[1])
	assert_eq(view["phase"], "voting")
	assert_eq(view["layer"], 1)
	assert_eq(view["party"][0]["class"], "archer")


func test_same_seed_and_target_give_the_same_scene() -> void:
	var names: Array[String] = []
	for i in 2:
		var pair := _start(11)
		assert_ok(_jump(pair[0], pair[1], "story"))
		names.append(str(pair[0].match_view(pair[1])["encounter"]["name"]))
	assert_eq(names[0], names[1])


func test_online_server_rejects_dev_jump_and_changes_nothing() -> void:
	var pair := _start(7, false)
	var h: MatchHarness = pair[0]
	var before := h.match_view(pair[1])
	assert_rejected(_jump(h, pair[1], "boss"), "dev_offline_only")
	var after := h.match_view(pair[1])
	assert_eq(after["phase"], before["phase"])
	assert_eq(after["layer"], before["layer"])
	assert_true(UiText.ERRORS.has("dev_offline_only"), "the rejection has player text")


func test_only_the_embedded_playtest_server_enables_dev() -> void:
	var online := GameServer.new()
	online.configure({})
	assert_false(online.match_server.allow_dev, "the online GameServer never sets allow_dev")
	online.free()


func test_bad_jumps_are_rejected() -> void:
	var pair := _start(7)
	var h: MatchHarness = pair[0]
	assert_rejected(_jump(h, pair[1], "nowhere"), "invalid_jump")
	assert_rejected(_jump(h, pair[1], "combat", {"layer": 9}), "invalid_jump")
	assert_rejected(_jump(h, pair[1], "combat", {"class": "wizard"}), "invalid_class")
	assert_eq(h.match_view(pair[1])["phase"], "voting")
	var lobby := MatchHarness.new(7)
	lobby.server.allow_dev = true
	var session := lobby.create_room()
	assert_rejected(_jump(lobby, session, "combat"), "wrong_phase")
