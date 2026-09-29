extends TestCase

const CLASSES := ["swordsman", "archer", "mage", "guardian", "rogue"]


func _start_story(h: MatchHarness) -> int:
	var session := h.server.open_session()
	assert_ok(h.server.command(session, {"type": "create_room", "name": "Story", "story": true}))
	for i in CLASSES.size():
		assert_ok(h.server.command(session, {"type": "set_loadout", "slot": i,
			"class": CLASSES[i], "race": "Human", "boons": []}))
	assert_ok(h.server.command(session, {"type": "start_match"}))
	return session


func test_one_session_controls_all_five_and_vote_has_one_voter() -> void:
	var h := MatchHarness.new(91)
	var session := _start_story(h)
	var view := h.match_view(session)
	assert_true(view["story"])
	for i in 5:
		assert_eq(view["party"][i]["class"], CLASSES[i])
		assert_eq(view["party"][i]["controller"], "human")
	assert_ok(h.server.command(session, {"type": "vote", "option": 0}))
	assert_ne(h.match_view(session)["phase"], "voting")
	var other := h.server.open_session()
	assert_rejected(h.server.command(other, {"type": "join_room", "name": "Other",
		"code": h.server.snapshot(session)["room"]["code"]}), "room_closed")


func test_story_action_waits_and_routes_to_current_character() -> void:
	var h := MatchHarness.new(92, MatchHarness.merge([MatchHarness.ALL_COMBAT, MatchHarness.WOLF_PAIR]))
	var session := _start_story(h)
	assert_ok(h.server.command(session, {"type": "vote", "option": 0}))
	h.advance(10.0)
	var combat: Dictionary = h.match_view(session)["encounter"]
	assert_eq(combat["kind"], "combat")
	while not str(combat["actor"]).begins_with("p"):
		h.advance(1.0)
		combat = h.match_view(session)["encounter"]
	var actor := str(combat["actor"])
	h.advance(100.0)
	combat = h.match_view(session)["encounter"]
	assert_eq(combat["actor"], actor)
	assert_eq(combat["deadline"], null)
	assert_true(combat["your_turn"])
	assert_rejected(h.server.command(session, {"type": "action", "slot": (int(actor.substr(1)) + 1) % 5,
		"action": "defend"}), "not_your_slot")
	assert_ok(h.server.command(session, {"type": "action", "action": "defend"}))


func test_layer_export_restores_party_route_stash_and_clues() -> void:
	var h := MatchHarness.new(93)
	var session := _start_story(h)
	var saved := h.server.export_story(session)
	assert_eq(saved["layer"], 1)
	assert_eq(saved["party"].size(), 5)
	assert_true(saved.has("route"))
	assert_true(saved.has("stash"))
	assert_true(saved.has("clues"))
	var round_tripped = JSON.parse_string(JSON.stringify(saved))
	var restored := MatchHarness.new(999)
	var new_session := restored.server.open_session()
	assert_ok(restored.server.command(new_session, {"type": "create_room", "name": "Story", "story": true}))
	assert_ok(restored.server.command(new_session, {"type": "restore_story", "save": round_tripped}))
	var again := restored.server.export_story(new_session)
	assert_eq(again["party"], saved["party"])
	assert_eq(again["route"], saved["route"])
	assert_eq(again["stash"], saved["stash"])
	assert_eq(again["clues"], saved["clues"])
	assert_eq(restored.match_view(new_session)["party"], h.match_view(session)["party"])


func test_one_ready_closes_story_rest_and_next_layer_can_restore() -> void:
	var h := MatchHarness.new(96, MatchHarness.only_routes(["rest"]))
	var session := _start_story(h)
	assert_ok(h.server.command(session, {"type": "vote", "option": 0}))
	h.advance(10.0)
	assert_eq(h.match_view(session)["encounter"]["kind"], "rest")
	assert_eq(h.match_view(session)["encounter"]["humans"], 1)
	assert_ok(h.server.command(session, {"type": "ready"}))
	assert_eq(h.match_view(session)["layer"], 2)
	var saved := h.server.export_story(session)
	assert_eq(saved["layer"], 2)
	var restored := MatchHarness.new(1)
	var new_session := restored.server.open_session()
	assert_ok(restored.server.command(new_session, {"type": "create_room", "name": "Story", "story": true}))
	assert_ok(restored.server.command(new_session, {"type": "restore_story", "save": JSON.parse_string(JSON.stringify(saved))}))
	assert_eq(restored.match_view(new_session)["party"], h.match_view(session)["party"])
	assert_eq(restored.match_view(new_session)["layer"], 2)


func test_normal_room_still_has_ai_and_rejects_other_slot() -> void:
	var h := MatchHarness.new(94)
	var session := h.create_room()
	assert_ok(h.server.command(session, {"type": "set_loadout", "slot": 1,
		"class": "mage", "race": "Human", "boons": []}))
	assert_eq(h.room_view(session)["slots"][0]["loadout"]["class"], "mage")
	assert_eq(h.room_view(session)["slots"][1]["loadout"], {})
	assert_ok(h.server.command(session, {"type": "start_match"}))
	assert_false(h.match_view(session)["story"])
	assert_eq(h.match_view(session)["party"][1]["controller"], "ai")
