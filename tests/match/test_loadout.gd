extends TestCase

const TOKEN := "0123456789abcdef0123456789abcdef"


func test_loadout_is_visible_and_applied_at_match_start() -> void:
	var profiles := MemoryProfileStore.new()
	profiles.profiles[TOKEN] = {"gems": 0}
	var h := MatchHarness.new(11, {}, profiles)
	var session := h.server.open_session()
	var created := h.server.command(session, {"type": "create_room", "name": "Loadout", "token": TOKEN})
	assert_ok(created)
	assert_ok(h.server.command(session, {"type": "set_loadout", "class": "rogue", "race": "Elf", "boons": ["Enervation"]}))
	var room := h.room_view(session)
	assert_eq(room["slots"][0]["loadout"]["class"], "rogue")
	assert_eq(room["slots"][0]["loadout"]["boons"], ["Enervation"])
	assert_ok(h.server.command(session, {"type": "start_match"}))
	assert_eq(h.match_view(session)["party"][0]["class"], "rogue")
	assert_eq(h.match_view(session)["party"][0]["race"], "Elf")
	assert_eq(h.match_view(session)["party"][0]["boons"], ["Enervation"])


func test_no_loadout_preserves_classless_start_and_loadout_commands_close() -> void:
	var h := MatchHarness.new(12)
	var session := h.create_room()
	assert_eq(h.server.command(session, {"type": "start_match"})["ok"], true)
	assert_eq(h.match_view(session)["party"][0]["class"], "classless")
	assert_eq(h.server.command(session, {"type": "set_loadout", "class": "rogue", "race": "Human", "boons": []})["error"], "wrong_phase")


func test_ai_uses_unclaimed_classes_in_content_order() -> void:
	var h := MatchHarness.new(13)
	var host := h.create_room()
	assert_ok(h.server.command(host, {"type": "set_loadout", "class": "guardian", "race": "Human", "boons": []}))
	assert_ok(h.server.command(host, {"type": "start_match"}))
	var party: Array = h.match_view(host)["party"]
	assert_eq(party[0]["class"], "guardian")
	assert_eq(party[1]["class"], "swordsman")
	assert_eq(party[2]["class"], "archer")
	assert_eq(party[3]["class"], "mage")
	assert_eq(party[4]["class"], "rogue")
