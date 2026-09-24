extends TestCase
## Merchant, Rest and Treasure Encounters (issue #14, spec stories 57–59, 62).

var h: MatchHarness
var sessions: Array[int] = []


func _start(types: Array, humans: int = 1, extra: Dictionary = {}, seed_value: int = 3) -> void:
	h = MatchHarness.new(seed_value, MatchHarness.merge([MatchHarness.only_routes(types), MatchHarness.EXACT_DAMAGE,
			MatchHarness.WOLF_PAIR, extra]))
	sessions = h.start_with_humans(humans)


func _shop(gold: int, humans: int = 1) -> void:
	_start(["merchant", "combat"], humans, {"party": {"starting_gold": gold}})
	h.take_route(sessions, "merchant")


func _view(session: int = -1) -> Dictionary:
	return h.match_view(sessions[0] if session == -1 else session)


func _encounter(session: int = -1) -> Dictionary:
	var encounter = _view(session).get("encounter")
	return encounter if encounter != null else {}


func _stock(item: String) -> Dictionary:
	for entry in _encounter()["stock"]:
		if entry["item"] == item:
			return entry
	return {}


func _count(item: String, session: int = -1) -> int:
	for entry in _view(session)["inventory"]:
		if entry["item"] == item:
			return entry["count"]
	return 0


func test_merchant_offers_content_stock_with_prices() -> void:
	_shop(0)
	var encounter := _encounter()
	assert_eq(encounter["kind"], "merchant")
	var items := []
	for entry in encounter["stock"]:
		items.append([entry["item"], entry["price"], entry["remaining"]])
		assert_false(str(entry["name"]).is_empty())
		assert_false(str(entry["description"]).is_empty())
	assert_eq(items, [["herb", 12, 5], ["tonic", 28, 2], ["spirit_bloom", 40, 1], ["firebomb", 24, 2]])


func test_buying_spends_shared_gold_and_fills_shared_inventory() -> void:
	_shop(50, 2)
	h.server.take_events(sessions[1])
	assert_ok(h.server.command(sessions[0], {"type": "buy", "item": "tonic"}))
	assert_ok(h.server.command(sessions[1], {"type": "buy", "item": "herb"}), "any human buys from the same purse")
	assert_eq(_view(sessions[1])["gold"], 50 - 28 - 12)
	assert_eq(_count("tonic", sessions[1]), 1)
	assert_eq(_count("herb", sessions[1]), 4, "3 starting herbs + 1")
	assert_eq(_stock("tonic")["remaining"], 1)
	var purchases := []
	for event in h.server.take_events(sessions[1]):
		if event["type"] == "purchase":
			purchases.append([event["slot"], event["item"]])
	assert_eq(purchases, [[0, "tonic"], [1, "herb"]], "everyone sees every purchase")


func test_not_enough_gold_is_rejected_without_change() -> void:
	_shop(20)
	var before := _view()
	assert_rejected(h.server.command(sessions[0], {"type": "buy", "item": "tonic"}), "not_enough_gold")
	var after := _view()
	assert_eq([after["gold"], after["inventory"], after["encounter"]["stock"]],
			[before["gold"], before["inventory"], before["encounter"]["stock"]])
	assert_eq(_stock("tonic")["affordable"], false)
	assert_eq(_stock("herb")["affordable"], true)


func test_invalid_and_sold_out_items_are_rejected() -> void:
	_shop(200)
	assert_rejected(h.server.command(sessions[0], {"type": "buy", "item": "dragon_egg"}), "invalid_item")
	assert_ok(h.server.command(sessions[0], {"type": "buy", "item": "spirit_bloom"}))
	assert_rejected(h.server.command(sessions[0], {"type": "buy", "item": "spirit_bloom"}), "out_of_stock")
	assert_eq(_view()["gold"], 160)


func test_single_player_moves_on_without_buying() -> void:
	_shop(100)
	assert_ok(h.server.command(sessions[0], {"type": "ready"}))
	var view := _view()
	assert_eq([view["phase"], view["layer"]], ["voting", 2])
	assert_eq(view["gold"], 100, "AI slots never spend the Party's Gold")


func test_shop_closes_once_every_human_is_ready() -> void:
	_shop(100, 2)
	assert_ok(h.server.command(sessions[0], {"type": "ready"}))
	assert_rejected(h.server.command(sessions[0], {"type": "ready"}), "already_ready")
	assert_eq(_encounter()["ready"], [0])
	assert_eq(_view()["phase"], "encounter", "waits for the other human")
	assert_ok(h.server.command(sessions[1], {"type": "buy", "item": "herb"}), "still shopping")
	assert_ok(h.server.command(sessions[1], {"type": "ready"}))
	assert_eq(_view()["layer"], 2)


func test_shop_closes_when_its_timer_runs_out() -> void:
	_shop(100, 2)
	h.advance(44.0)
	assert_eq(_encounter().get("kind"), "merchant")
	h.advance(1.0)
	assert_eq(_view()["layer"], 2)


func test_shop_does_not_wait_for_a_player_who_dropped() -> void:
	_shop(100, 2)
	h.server.command(sessions[0], {"type": "ready"})
	h.server.close_session(sessions[1])
	assert_eq(_view()["layer"], 2)


func test_buying_outside_a_merchant_is_rejected() -> void:
	_start(["combat"])
	assert_rejected(h.server.command(sessions[0], {"type": "buy", "item": "herb"}), "wrong_phase")


func test_gold_won_in_combat_buys_items() -> void:
	_start(["merchant", "combat"], 1, {"enemies": {"grey_wolf": {"stats": {"max_hp": 1, "spd": 5}, "rewards": {"gold": 10}}}})
	h.take_route(sessions, "combat")
	h.server.command(sessions[0], {"type": "action", "action": "attack", "target": "e0"})
	h.advance(4.0)
	assert_eq(_view()["gold"], 20)
	h.take_route(sessions, "merchant")
	assert_ok(h.server.command(sessions[0], {"type": "buy", "item": "herb"}))
	assert_eq(_view()["gold"], 8)


func test_rest_restores_party_hp_by_content_ratio() -> void:
	_start(["rest", "combat"], 1, {"enemies": {"grey_wolf": {"stats": {"max_hp": 1, "spd": 20, "atk": 20}}}})
	h.take_route(sessions, "combat")
	h.advance(2.0)
	assert_eq(_view()["party"][0]["hp"], 2, "two wolf bites of 19")
	h.server.command(sessions[0], {"type": "action", "action": "attack", "target": "e0"})
	h.advance(4.0)
	h.take_route(sessions, "rest")
	var encounter := _encounter()
	assert_eq(encounter["kind"], "rest")
	assert_eq(encounter["healed"][0], {"slot": 0, "amount": 24, "hp": 26}, "60% of 40 max HP")
	assert_eq(_view()["party"][1]["hp"], 40, "never above max HP")
	h.advance(4.0)
	assert_eq(_view()["layer"], 3, "journey continues")


func test_treasure_adds_seeded_gold_and_items_to_shared_pool() -> void:
	var loots := {}
	for seed_value in 12:
		_start(["treasure", "combat"], 1, {}, seed_value)
		h.take_route(sessions, "treasure")
		var found: Dictionary = _encounter()["found"]
		assert_eq(_view()["gold"], found["gold"], "seed %d gold goes to the pool" % seed_value)
		for item in found["items"]:
			var expected := int(found["items"][item]) + (3 if item == "herb" else 0)
			assert_eq(_count(item), expected, "seed %d %s" % [seed_value, item])
		loots[str(found)] = true
		_start(["treasure", "combat"], 1, {}, seed_value)
		h.take_route(sessions, "treasure")
		assert_eq(_encounter()["found"], found, "same seed, same treasure")
	assert_true(loots.size() >= 5, "treasure differs between seeds")


func test_encounter_matches_the_type_advertised_in_the_vote() -> void:
	for type in ["merchant", "rest", "treasure"]:
		_start([type, "combat"])
		h.take_route(sessions, type)
		assert_eq(_encounter()["kind"], type)
		assert_eq(_encounter()["type"], type)


func test_every_seed_can_reach_a_real_merchant_before_the_boss() -> void:
	for seed_value in 40:
		var harness := MatchHarness.new(seed_value, MatchHarness.EASY)
		var bot := MatchBot.new(harness, harness.start_with_humans(1))
		bot.choose_route = func(options: Array, _slot: int, _view: Dictionary) -> int:
			for option in options:
				if option["type"] == "merchant":
					return option["index"]
			return 0
		bot.play_until(func(v: Dictionary) -> bool: return v["phase"] == "boss")
		assert_eq(bot.events_of_type("merchant_opened").size() >= 1, true, "seed %d met a Merchant" % seed_value)
