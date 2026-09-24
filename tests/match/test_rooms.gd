extends TestCase
## Room code, lobby and Player slot behaviour (issue #4, spec stories 1–14).

const CONFUSABLE := ["0", "O", "1", "I", "L"]


func test_host_receives_six_character_room_code() -> void:
	var h := MatchHarness.new(11)
	h.create_room("Ann")
	assert_ok(h.last_result)
	assert_eq(h.code.length(), 6)
	assert_eq(h.last_result["slot"], 0, "creator takes slot 0")


func test_same_seed_gives_same_room_code() -> void:
	var a := MatchHarness.new(77)
	var b := MatchHarness.new(77)
	a.create_room()
	b.create_room()
	assert_eq(a.code, b.code)


func test_different_seeds_give_different_room_codes() -> void:
	var a := MatchHarness.new(1)
	var b := MatchHarness.new(2)
	a.create_room()
	b.create_room()
	assert_ne(a.code, b.code)


func test_room_codes_avoid_confusable_characters() -> void:
	for seed_value in 200:
		var h := MatchHarness.new(seed_value)
		h.create_room()
		for ch in CONFUSABLE:
			assert_false(h.code.contains(ch), "code %s contains %s" % [h.code, ch])
		assert_eq(h.code, h.code.to_upper())


func test_join_code_is_case_insensitive_and_ignores_spaces() -> void:
	var h := MatchHarness.new(5)
	h.create_room("Ann")
	var bob := h.server.open_session()
	var typed := "%s %s" % [h.code.substr(0, 3).to_lower(), h.code.substr(3).to_lower()]
	var result := h.server.command(bob, {"type": "join_room", "code": typed, "name": "Bob"})
	assert_ok(result)
	assert_eq(result["code"], h.code)
	assert_eq(result["slot"], 1)


func test_joining_player_takes_lowest_free_slot() -> void:
	var h := MatchHarness.new(5)
	var ann := h.create_room("Ann")
	var bob := h.join("Bob")
	h.join("Cid")
	h.server.command(bob, {"type": "leave_room"})
	h.join("Dee")
	assert_eq(h.last_result["slot"], 1, "Dee fills the slot Bob left")
	var slots: Array = h.room_view(ann)["slots"]
	assert_eq(slots[1]["owner_name"], "Dee")
	assert_eq(slots[2]["owner_name"], "Cid")


func test_wrong_code_is_rejected() -> void:
	var h := MatchHarness.new(5)
	h.create_room()
	var other := "ABCDEF" if h.code != "ABCDEF" else "BCDEFG"
	var bob := h.server.open_session()
	assert_rejected(h.server.command(bob, {"type": "join_room", "code": other, "name": "Bob"}), "room_not_found")


func test_malformed_code_is_rejected() -> void:
	var h := MatchHarness.new(5)
	h.create_room()
	var bob := h.server.open_session()
	assert_rejected(h.server.command(bob, {"type": "join_room", "code": "AB1", "name": "Bob"}), "invalid_code")
	assert_rejected(h.server.command(bob, {"type": "join_room", "code": "ABCDE0", "name": "Bob"}), "invalid_code")


func test_full_room_is_rejected() -> void:
	var h := MatchHarness.new(5)
	h.create_room("P1")
	for i in 4:
		h.join("P%d" % (i + 2))
		assert_ok(h.last_result)
	h.join("P6")
	assert_rejected(h.last_result, "room_full")


func test_room_with_match_in_progress_is_rejected() -> void:
	var h := MatchHarness.new(5)
	var host := h.create_room()
	assert_ok(h.start(host))
	h.join("Late")
	assert_rejected(h.last_result, "match_in_progress")


func test_closed_room_is_rejected() -> void:
	var h := MatchHarness.new(5, {"rules": {"empty_room_grace_seconds": 10}})
	var host := h.create_room()
	h.server.command(host, {"type": "leave_room"})
	h.advance(11.0)
	h.join("Late")
	assert_rejected(h.last_result, "room_closed")


func test_display_name_is_required() -> void:
	var h := MatchHarness.new(5)
	var s := h.server.open_session()
	assert_rejected(h.server.command(s, {"type": "create_room", "name": "   "}), "invalid_name")


func test_player_cannot_be_in_two_rooms() -> void:
	var h := MatchHarness.new(5)
	var host := h.create_room()
	assert_rejected(h.server.command(host, {"type": "create_room", "name": "Again"}), "already_in_room")


func test_lobby_snapshot_shows_all_five_slots_with_owner_and_controller() -> void:
	var h := MatchHarness.new(5)
	var ann := h.create_room("Ann")
	h.join("Bob")
	var room := h.room_view(ann)
	assert_eq(room["code"], h.code)
	assert_eq(room["state"], "lobby")
	assert_eq(room["your_slot"], 0)
	var slots: Array = room["slots"]
	assert_eq(slots.size(), 5)
	assert_eq([slots[0]["owner_name"], slots[0]["controller"], slots[0]["is_host"]], ["Ann", "human", true])
	assert_eq([slots[1]["owner_name"], slots[1]["controller"], slots[1]["is_host"]], ["Bob", "human", false])
	for i in range(2, 5):
		assert_eq([slots[i]["owner_name"], slots[i]["controller"]], ["", "ai"], "slot %d" % i)
	for slot in slots:
		assert_false(str(slot["character_name"]).is_empty())


func test_members_see_each_other_join() -> void:
	var h := MatchHarness.new(5)
	var ann := h.create_room("Ann")
	h.server.take_events(ann)
	h.join("Bob")
	var events := h.server.take_events(ann)
	assert_eq(events.size(), 1)
	assert_eq(events[0], {"type": "player_joined", "slot": 1, "name": "Bob"})


func test_only_host_can_start_match() -> void:
	var h := MatchHarness.new(5)
	var host := h.create_room("Ann")
	var bob := h.join("Bob")
	assert_rejected(h.start(bob), "not_host")
	assert_eq(h.room_view(host)["state"], "lobby", "nothing started")
	assert_ok(h.start(host))
	assert_eq(h.room_view(host)["state"], "in_match")


func test_single_player_host_can_start_alone() -> void:
	var h := MatchHarness.new(5)
	var host := h.create_room("Solo")
	assert_ok(h.start(host))
	var party: Array = h.match_view(host)["party"]
	assert_eq(party.size(), 5)
	assert_eq(_controllers(party), ["human", "ai", "ai", "ai", "ai"])


func test_duo_coop_has_two_humans_and_three_ai() -> void:
	var h := MatchHarness.new(5)
	var sessions := h.start_with_humans(2)
	var party: Array = h.match_view(sessions[1])["party"]
	assert_eq(_controllers(party), ["human", "human", "ai", "ai", "ai"])


func test_party_is_always_five_classless_characters() -> void:
	for humans in range(1, 6):
		var h := MatchHarness.new(5)
		var sessions := h.start_with_humans(humans)
		var party: Array = h.match_view(sessions[0])["party"]
		assert_eq(party.size(), 5, "%d humans" % humans)
		var human_count := 0
		for character in party:
			assert_eq(character["class"], "classless")
			assert_eq(character["hp"], character["max_hp"])
			if character["controller"] == "human":
				human_count += 1
		assert_eq(human_count, humans)


func test_match_start_is_announced_to_every_member() -> void:
	var h := MatchHarness.new(5)
	var host := h.create_room("Ann")
	var bob := h.join("Bob")
	h.server.take_events(host)
	h.server.take_events(bob)
	h.start(host)
	assert_has(h.event_types(host), "match_started")
	assert_has(h.event_types(bob), "match_started")


func test_player_leaving_lobby_frees_slot_to_ai() -> void:
	var h := MatchHarness.new(5)
	var ann := h.create_room("Ann")
	var bob := h.join("Bob")
	assert_ok(h.server.command(bob, {"type": "leave_room"}))
	var slots: Array = h.room_view(ann)["slots"]
	assert_eq([slots[1]["owner_name"], slots[1]["controller"]], ["", "ai"])
	assert_eq(h.server.snapshot(bob)["room"], null, "Bob is no longer in a room")


func test_disconnect_in_lobby_frees_slot() -> void:
	var h := MatchHarness.new(5)
	var ann := h.create_room("Ann")
	var bob := h.join("Bob")
	h.server.take_events(ann)
	h.server.close_session(bob)
	var slots: Array = h.room_view(ann)["slots"]
	assert_eq(slots[1]["controller"], "ai")
	var events := h.server.take_events(ann)
	assert_eq(events[0], {"type": "player_left", "slot": 1, "name": "Bob", "reason": "disconnected"})


func test_host_leaving_hands_host_to_next_player() -> void:
	var h := MatchHarness.new(5)
	var ann := h.create_room("Ann")
	var bob := h.join("Bob")
	h.server.command(ann, {"type": "leave_room"})
	var room := h.room_view(bob)
	assert_eq(room["host_slot"], 1)
	assert_ok(h.start(bob), "new Host can start")


func test_empty_room_closes_only_after_grace_period() -> void:
	var h := MatchHarness.new(5, {"rules": {"empty_room_grace_seconds": 20}})
	var host := h.create_room("Ann")
	h.server.command(host, {"type": "leave_room"})
	h.advance(19.0)
	var early := h.join("Bob")
	assert_ok(h.last_result, "room still open during grace period")
	assert_eq(h.room_view(early)["host_slot"], 0, "newcomer becomes Host")
	h.server.command(early, {"type": "leave_room"})
	h.advance(20.0)
	h.join("Cid")
	assert_rejected(h.last_result, "room_closed")


func test_rooms_are_isolated() -> void:
	var h := MatchHarness.new(5)
	var ann := h.create_room("Ann")
	var first := h.code
	var zed := h.create_room("Zed")
	assert_ne(h.code, first)
	h.start(zed)
	assert_eq(h.room_view(ann)["state"], "lobby", "other room unaffected")
	assert_eq(h.room_view(zed)["state"], "in_match")


func _controllers(party: Array) -> Array:
	var out := []
	for character in party:
		out.append(character["controller"])
	return out
