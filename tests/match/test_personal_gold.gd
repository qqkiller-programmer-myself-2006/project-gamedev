extends TestCase

var h: MatchHarness
var sessions: Array[int] = []

func _to_merchant(humans: int = 1, extra: Dictionary = {}) -> void:
	h = MatchHarness.new(3, MatchHarness.merge([MatchHarness.only_routes(["merchant"]), extra]))
	sessions = h.start_with_humans(humans)
	h.take_route(sessions, "merchant")

func test_personal_gold_at_merchant() -> void:
	_to_merchant(2, {"party": {"starting_gold": 10}, "items": {"herb": {"price": 10, "kind": "consumable"}}, "encounters": {"merchant": {"stock": [{"item": "herb", "quantity": 1}]}}})
	# Starting gold is 10, split to 5 each (2 humans, 3 ai, starting gold split to 5 chars = 2 each. AI transfers 6 gold to 2 humans = 3 each. Total 5)
	var v = h.match_view(sessions[0])
	assert_eq(int(v["party"][0]["gold"]), 5)
	
	# Try to buy for 10
	var res = h.server.command(sessions[0], {"type": "buy", "item": "herb"})
	assert_eq(res.get("ok", false), false)
	assert_eq(res.get("error", ""), "not_enough_gold")
	
	# Transfer gold from slot 1 to slot 0
	res = h.server.command(sessions[1], {"type": "transfer_gold", "to": 0, "amount": 5})
	if res.has("error"):
		print("Error: ", res["error"])
	assert_eq(res.get("ok", false), true)
	
	v = h.match_view(sessions[0])
	assert_eq(int(v["party"][0]["gold"]), 10)
	
	# Buy
	res = h.server.command(sessions[0], {"type": "buy", "item": "herb"})
	assert_eq(res.get("ok", false), true)
	
	v = h.match_view(sessions[0])
	assert_eq(int(v["party"][0]["gold"]), 0)

func test_transfer_item_consumable_slot() -> void:
	_to_merchant(1, {"party": {"starting_gold": 0, "starting_inventory": {"herb": 2}}, "items": {"herb": {"kind": "consumable"}}})
	var res = h.server.command(sessions[0], {"type": "transfer_item", "item": "herb", "to": 0})
	assert_eq(res.get("ok", false), true)
	var v = h.match_view(sessions[0])
	assert_eq(str(v["party"][0]["consumable"]["item"]), "herb")
