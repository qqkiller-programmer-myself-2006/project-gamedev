extends TestCase
## The WebSocket transport adapter against a real socket (issue #5, spec
## stories 1–11, 13, 77). Game rules are tested behind the Match interface;
## these tests check that the transport carries them faithfully.

var rig: NetRig


func before_each() -> void:
	rig = NetRig.new(21)


func after_each() -> void:
	rig.stop()


func test_connection_gets_an_anonymous_session() -> void:
	assert_true(rig.port > 0, "server listening")
	var ann := rig.connect_client()
	var bob := rig.connect_client()
	assert_true(ann.session > 0)
	assert_ne(ann.session, bob.session)
	assert_true(rig.pump(func() -> bool: return ann.snapshot.has("time")), "heartbeat snapshot arrives")


func test_players_create_join_and_start_over_the_network() -> void:
	var ann := rig.connect_client()
	var bob := rig.connect_client()
	var created := rig.send(ann, {"type": "create_room", "name": "Ann"})
	assert_ok(created)
	var joined := rig.send(bob, {"type": "join_room", "code": str(created["code"]).to_lower(), "name": "Bob"})
	assert_ok(joined)
	assert_eq(joined["slot"], 1)
	rig.pump(func() -> bool: return ann.room().get("slots", []).size() == 5 and ann.room()["slots"][1]["owner_name"] == "Bob")
	var slots: Array = ann.room()["slots"]
	assert_eq([slots[0]["controller"], slots[1]["controller"], slots[2]["controller"]], ["human", "human", "ai"])
	assert_ok(rig.send(ann, {"type": "start_match"}))
	assert_true(rig.pump(func() -> bool: return bob.event_types().has("match_started")))
	assert_eq(bob.snapshot["match"]["phase"], "voting")
	assert_eq(bob.snapshot["match"]["party"].size(), 5)


func test_rejections_travel_back_without_changing_state() -> void:
	var ann := rig.connect_client()
	var bob := rig.connect_client()
	var code: String = rig.send(ann, {"type": "create_room", "name": "Ann"})["code"]
	assert_rejected(rig.send(bob, {"type": "join_room", "code": "ZZZZZZ" if code != "ZZZZZZ" else "YYYYYY", "name": "Bob"}),
			"room_not_found")
	rig.send(bob, {"type": "join_room", "code": code, "name": "Bob"})
	assert_rejected(rig.send(bob, {"type": "start_match"}), "not_host")
	assert_rejected(rig.send(bob, {"type": "vote", "option": 0}), "wrong_phase")
	rig.pump(func() -> bool: return bob.room().get("state") == "lobby")
	assert_eq(bob.room()["state"], "lobby")


func test_vote_numbers_survive_json() -> void:
	var ann := rig.connect_client()
	rig.send(ann, {"type": "create_room", "name": "Ann"})
	rig.send(ann, {"type": "start_match"})
	assert_ok(rig.send(ann, {"type": "vote", "option": 1}))
	assert_true(rig.pump(func() -> bool: return ann.event_types().has("vote_resolved")))


func test_bad_messages_get_an_error_and_keep_the_connection() -> void:
	var ann := rig.connect_client()
	ann.client._ws.send_text("not json at all")
	ann.client._ws.send_text(NetProtocol.encode({"t": "cmd", "id": 1, "cmd": "create_room"}))
	assert_true(rig.pump(func() -> bool: return ann.errors.size() == 2))
	assert_eq(ann.errors, ["bad_message", "bad_message"])
	assert_ok(rig.send(ann, {"type": "create_room", "name": "Ann"}), "still usable")


func test_dropped_connection_frees_the_slot_for_the_others() -> void:
	var ann := rig.connect_client()
	var bob := rig.connect_client()
	var code: String = rig.send(ann, {"type": "create_room", "name": "Ann"})["code"]
	rig.send(bob, {"type": "join_room", "code": code, "name": "Bob"})
	bob.client.close()
	assert_true(rig.pump(func() -> bool: return ann.event_types().has("player_left")))
	rig.pump(func() -> bool: return ann.room()["slots"][1]["controller"] == "ai")
	assert_eq(ann.room()["slots"][1]["controller"], "ai")
	assert_true(rig.pump(func() -> bool: return not bob.closed_reason.is_empty()))


func test_rooms_on_one_server_are_isolated() -> void:
	var ann := rig.connect_client()
	var zed := rig.connect_client()
	var first: String = rig.send(ann, {"type": "create_room", "name": "Ann"})["code"]
	var second: String = rig.send(zed, {"type": "create_room", "name": "Zed"})["code"]
	assert_ne(first, second)
	rig.send(zed, {"type": "start_match"})
	rig.pump(func() -> bool: return zed.snapshot.get("match") != null)
	assert_eq(ann.room()["state"], "lobby")
	assert_eq(ann.snapshot["match"], null)
