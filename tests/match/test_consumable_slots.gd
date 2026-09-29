extends TestCase


func test_transfer_consumable_to_empty_and_occupied_slot() -> void:
	var content = MatchHarness.only_routes(["merchant"])
	content["items"] = {"test_potion": {"kind": "consumable"}, "test_bomb": {"kind": "consumable"}}
	var h := MatchHarness.new(201, content)
	var session := h.create_room()
	assert_ok(h.server.command(session, {"type": "start_match"}))
	assert_ok(h.server.command(session, {"type": "vote", "option": 0}))
	h.advance(10.0)
	
	# Give the party some items in the stash
	var room := h.server._room_of(session)
	room.run.add_item("test_potion", 2)
	room.run.add_item("test_bomb", 1)
	
	assert_eq(int(room.run.inventory.get("test_potion", 0)), 2)
	
	# 1. Transfer to empty slot
	assert_ok(h.server.command(session, {"type": "transfer_item", "item": "test_potion", "to": 0}))
	assert_eq(int(room.run.inventory.get("test_potion", 0)), 1)
	assert_eq(h.match_view(session)["party"][0]["consumable"]["item"], "test_potion")
	assert_eq(int(h.match_view(session)["party"][0]["consumable"]["count"]), 1)
	
	# 2. Transfer to same slot holding same item (stacking)
	assert_ok(h.server.command(session, {"type": "transfer_item", "item": "test_potion", "to": 0}))
	assert_false(room.run.inventory.has("test_potion"))
	assert_eq(int(h.match_view(session)["party"][0]["consumable"]["count"]), 2)
	
	# 3. Transfer 0 in stash is rejected
	assert_rejected(h.server.command(session, {"type": "transfer_item", "item": "test_potion", "to": 0}), "not_in_stash")
	
	# 4. Swap (old stack returns, new item leaves)
	assert_ok(h.server.command(session, {"type": "transfer_item", "item": "test_bomb", "to": 0}))
	assert_eq(int(room.run.inventory.get("test_potion", 0)), 2)
	assert_false(room.run.inventory.has("test_bomb"))
	assert_eq(h.match_view(session)["party"][0]["consumable"]["item"], "test_bomb")
	assert_eq(int(h.match_view(session)["party"][0]["consumable"]["count"]), 1)


func test_combat_items_include_slot_and_consumes_slot_first() -> void:
	var h := MatchHarness.new(202, MatchHarness.ALL_COMBAT)
	var session := h.create_room()
	assert_ok(h.server.command(session, {"type": "start_match"}))
	assert_ok(h.server.command(session, {"type": "vote", "option": 0}))
	h.advance(10.0)
	
	var room := h.server._room_of(session)
	room.run.inventory.clear()
	room.run.add_item("herb", 1)
	room.run.party[0]["consumable"] = {"item": "herb", "count": 1}
	
	var encounter = h.match_view(session)["encounter"]
	var actor = str(encounter["actor"])
	var p0_session = session if actor == "p0" else 0 # Need to be acting character
	# Force actor to be p0 if it isn't
	if actor != "p0":
		while str(h.match_view(session)["encounter"]["actor"]) != "p0":
			h.advance(1.0)
	
	var choices = h.match_view(session)["encounter"]["choices"]
	assert_true(choices.has("items"))
	assert_true(choices["items"].has("herb"))
	# Total should be stash (1) + slot (1) = 2
	assert_eq(int(choices["items"]["herb"]["count"]), 2)
	
	# Consume
	assert_ok(h.server.command(session, {"type": "action", "action": "item", "item": "herb", "target": "p0"}))
	
	# Slot is empty
	assert_eq(h.match_view(session)["party"][0]["consumable"], null)
	# Stash still has 1
	assert_eq(int(room.run.inventory.get("herb", 0)), 1)
