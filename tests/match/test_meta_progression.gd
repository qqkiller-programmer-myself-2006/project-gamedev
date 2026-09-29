extends TestCase

const TOKEN := "fedcba9876543210fedcba9876543210"


func _profile(gems: int) -> MemoryProfileStore:
	var store := MemoryProfileStore.new()
	store.profiles[TOKEN] = {"gems": gems}
	return store


func _room(h: MatchHarness) -> int:
	var session := h.server.open_session()
	assert_ok(h.server.command(session, {"type": "create_room", "name": "Meta", "token": TOKEN}))
	return session


func test_race_purchase_and_tree_costs_caps_and_reset_refund() -> void:
	var store := _profile(1000)
	var h := MatchHarness.new(21, {}, store)
	var session := _room(h)
	assert_ok(h.server.command(session, {"type": "buy_race", "race": "Dwarf"}))
	assert_eq(h.room_view(session)["profile"]["gems"], 950)
	assert_ok(h.server.command(session, {"type": "tree_upgrade", "class": "rogue", "node": "might"}))
	assert_eq(h.room_view(session)["profile"]["class_trees"]["rogue"]["might"], 1)
	assert_eq(h.room_view(session)["profile"]["gems"], 940)
	for i in 4:
		assert_ok(h.server.command(session, {"type": "tree_upgrade", "class": "rogue", "node": "might"}))
	assert_eq(h.server.command(session, {"type": "tree_upgrade", "class": "rogue", "node": "might"})["error"], "max_level")
	var before: int = int(h.room_view(session)["profile"]["gems"])
	assert_ok(h.server.command(session, {"type": "reset_tree", "class": "rogue"}))
	assert_eq(h.room_view(session)["profile"]["gems"], before + 100)


func test_match_end_awards_gems_and_persists_them() -> void:
	var store := _profile(0)
	var h := MatchHarness.new(22, MatchHarness.merge([MatchHarness.EASY, MatchHarness.ALL_COMBAT, MatchHarness.WOLF_PAIR]), store)
	var session := _room(h)
	assert_ok(h.server.command(session, {"type": "set_loadout", "class": "swordsman", "race": "Human", "boons": []}))
	assert_ok(h.server.command(session, {"type": "start_match"}))
	var bot := MatchBot.new(h, [session])
	bot.choose_route = MatchBot.sensible_route
	var view := bot.play_to_end(3600.0)
	assert_true(view["summary"].has("gems_earned"))
	assert_true(int(view["summary"]["gems_earned"][0]) > 0)
	assert_eq(store.load_profile(TOKEN)["gems"], int(view["summary"]["gems_earned"][0]))
