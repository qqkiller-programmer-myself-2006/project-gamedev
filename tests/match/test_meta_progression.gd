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
	assert_ok(h.server.command(session, {"type": "tree_upgrade", "class": "assassin", "node": "might"}))
	assert_eq(h.room_view(session)["profile"]["class_trees"]["assassin"]["might"], 1)
	assert_eq(h.room_view(session)["profile"]["gems"], 940)
	for i in 4:
		assert_ok(h.server.command(session, {"type": "tree_upgrade", "class": "assassin", "node": "might"}))
	assert_eq(h.server.command(session, {"type": "tree_upgrade", "class": "assassin", "node": "might"})["error"], "max_level")
	var before: int = int(h.room_view(session)["profile"]["gems"])
	assert_ok(h.server.command(session, {"type": "reset_tree", "class": "assassin"}))
	assert_eq(h.room_view(session)["profile"]["gems"], before + 100)


func test_support_and_healer_skill_trees_load_and_allow_node_purchases() -> void:
	var h := MatchHarness.new(25, {}, _profile(1000))
	var session := _room(h)
	var nodes: Dictionary = h.content.get_dict("meta.class_tree")
	assert_eq(nodes.size(), 7, "both new Classes use the full 3-3-1 tree")
	for class_id in ["support", "healer"]:
		assert_ok(h.server.command(session, {"type": "tree_upgrade", "class": class_id, "node": "stat_points"}))
		assert_eq(h.room_view(session)["profile"]["class_trees"][class_id]["stat_points"], 1)
	assert_eq(h.room_view(session)["profile"]["gems"], 980)


func test_match_end_awards_gems_and_persists_them() -> void:
	var store := _profile(0)
	var h := MatchHarness.new(22, MatchHarness.merge([MatchHarness.EASY, MatchHarness.ALL_COMBAT,
			MatchHarness.WOLF_PAIR, {"party": {"ai_class_order": ["guardian", "swordsman", "archer", "mage", "assassin"]}}]), store)
	var session := _room(h)
	assert_ok(h.server.command(session, {"type": "set_loadout", "class": "swordsman", "race": "Human", "boons": []}))
	assert_ok(h.server.command(session, {"type": "start_match"}))
	var bot := MatchBot.new(h, [session])
	bot.choose_route = MatchBot.sensible_route
	var view := bot.play_to_end(3600.0)
	assert_true(view["summary"].has("gems_earned"))
	assert_eq(int(view["summary"]["gems_earned"][0]), 100)
	assert_eq(store.load_profile(TOKEN)["gems"], 100)


func test_reset_empty_tree_charges_nothing() -> void:
	var store := _profile(100)
	var h := MatchHarness.new(23, {}, store)
	var session := _room(h)
	var before := int(h.room_view(session)["profile"]["gems"])
	assert_rejected(h.server.command(session, {"type": "reset_tree", "class": "swordsman"}),
			"nothing_to_reset")
	assert_eq(h.room_view(session)["profile"]["gems"], before)
	assert_eq(UiText.error("nothing_to_reset"), "No Skill Tree levels to reset for this Class.")

func test_level_up_stat_points_growth() -> void:
	var store := _profile(0)
	store.profiles[TOKEN]["class_trees"] = {"assassin": {"stat_points": 5}}
	var h := MatchHarness.new(24, {}, store)
	var session := _room(h)
	assert_ok(h.server.command(session, {"type": "set_loadout", "class": "assassin", "race": "Human", "boons": []}))
	assert_ok(h.server.command(session, {"type": "start_match"}))

	var view := h.match_view(session)
	var character = view["party"][0]
	assert_eq(character["points"], 5) # 5 from the starting node

	var run = h.server._rooms[h.server._sessions[session].room].run
	run.grant_exp(0, run._exp_to_next(1)) # Level up to 2

	view = h.match_view(session)
	character = view["party"][0]
	var pts_per_lvl = h.content.get_int("leveling.points_per_level", 0)
	assert_eq(character["level"], 2)
	assert_eq(character["points"], 5 + pts_per_lvl + 1) # +1 from Human level 2
