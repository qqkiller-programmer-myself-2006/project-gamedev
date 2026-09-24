extends TestCase
## Journey through the Forest's Layers and Path Voting (issue #7, spec 15–26).

const SLICE_TYPES := ["combat", "merchant", "rest", "treasure", "story", "class"]


func test_first_layer_offers_two_or_three_distinct_encounter_types() -> void:
	for seed_value in 50:
		var h := MatchHarness.new(seed_value)
		var sessions := h.start_with_humans(1)
		var view := h.match_view(sessions[0])
		assert_eq(view["phase"], "voting")
		assert_eq(view["layer"], 1)
		assert_eq(view["layers_total"], 5)
		var options: Array = view["vote"]["options"]
		assert_between(options.size(), 2, 3, "seed %d" % seed_value)
		var types := []
		for option in options:
			assert_has(SLICE_TYPES, option["type"])
			assert_false(str(option["name"]).is_empty())
			assert_false(str(option["hint"]).is_empty())
			assert_not_has(types, option["type"], "types within a Layer are distinct")
			types.append(option["type"])


func test_same_seed_offers_same_routes() -> void:
	assert_eq(_route_log(99), _route_log(99))


func test_routes_differ_between_matches() -> void:
	var distinct := {}
	for seed_value in 10:
		distinct[str(_route_log(seed_value))] = true
	assert_true(distinct.size() >= 8, "most seeds give different routes (%d/10)" % distinct.size())


func test_every_match_offers_class_encounter_early_and_merchant_before_boss() -> void:
	for seed_value in 150:
		var layers := _route_log(seed_value)
		assert_eq(layers.size(), 5, "seed %d reached all Layers" % seed_value)
		var early_class := false
		var merchant := false
		for i in layers.size():
			for option in layers[i]:
				if option["type"] == "class" and i < 2:
					early_class = true
				if option["type"] == "merchant":
					merchant = true
		assert_true(early_class, "seed %d offers a Class Encounter in Layer 1–2" % seed_value)
		assert_true(merchant, "seed %d offers a Merchant before the Boss" % seed_value)


func test_single_player_vote_decides_immediately() -> void:
	var h := MatchHarness.new(3)
	var solo := h.start_with_humans(1)[0]
	h.server.take_events(solo)
	assert_ok(h.server.command(solo, {"type": "vote", "option": 1}))
	var resolved := _events(h, solo, "vote_resolved")
	assert_eq(resolved.size(), 1)
	assert_eq(resolved[0]["option"], 1)
	assert_eq(resolved[0]["tie_broken"], false)
	assert_ne(h.match_view(solo)["phase"], "voting")


func test_each_human_has_exactly_one_vote() -> void:
	var h := MatchHarness.new(3)
	var sessions := h.start_with_humans(3)
	assert_ok(h.server.command(sessions[0], {"type": "vote", "option": 0}))
	assert_rejected(h.server.command(sessions[0], {"type": "vote", "option": 1}), "already_voted")
	assert_eq(h.match_view(sessions[0])["vote"]["voted_slots"], [0])


func test_invalid_option_is_rejected() -> void:
	var h := MatchHarness.new(3)
	var solo := h.start_with_humans(1)[0]
	assert_rejected(h.server.command(solo, {"type": "vote", "option": 7}), "invalid_option")
	assert_eq(h.match_view(solo)["vote"]["voted_slots"], [])


func test_duo_resolves_once_both_humans_voted_without_ai_votes() -> void:
	var h := MatchHarness.new(3)
	var duo := h.start_with_humans(2)
	h.server.command(duo[0], {"type": "vote", "option": 0})
	assert_eq(h.match_view(duo[0])["phase"], "voting", "waits for the other human")
	h.server.take_events(duo[1])
	h.server.command(duo[1], {"type": "vote", "option": 0})
	var resolved := _events(h, duo[1], "vote_resolved")
	assert_eq(resolved.size(), 1, "three AI slots never block the vote")
	assert_eq(resolved[0]["votes"], {"0": 0, "1": 0})
	assert_eq(resolved[0]["tally"][0], 2)


func test_most_votes_wins() -> void:
	var h := MatchHarness.new(3)
	var trio := h.start_with_humans(3)
	h.server.take_events(trio[0])
	h.server.command(trio[0], {"type": "vote", "option": 0})
	h.server.command(trio[1], {"type": "vote", "option": 1})
	h.server.command(trio[2], {"type": "vote", "option": 1})
	var resolved: Dictionary = _events(h, trio[0], "vote_resolved")[0]
	assert_eq(resolved["option"], 1)
	assert_eq(resolved["tie_broken"], false)


func test_duo_disagreement_is_a_tie_broken_randomly_and_reproducibly() -> void:
	var winners := {}
	for seed_value in 30:
		var first := _duo_split_winner(seed_value)
		assert_eq(first["tie_broken"], true)
		assert_has([0, 1], first["option"], "only tied options can win")
		assert_eq(_duo_split_winner(seed_value)["option"], first["option"], "same seed, same pick")
		winners[first["option"]] = true
	assert_eq(winners.size(), 2, "either tied option can win")


func test_vote_resolves_at_deadline_with_votes_cast_so_far() -> void:
	var h := MatchHarness.new(3)
	var duo := h.start_with_humans(2)
	h.server.command(duo[0], {"type": "vote", "option": 1})
	h.server.take_events(duo[0])
	h.advance(19.5)
	assert_eq(h.match_view(duo[0])["phase"], "voting", "still open before 20 seconds")
	h.advance(0.5)
	var resolved := _events(h, duo[0], "vote_resolved")
	assert_eq(resolved.size(), 1)
	assert_eq(resolved[0]["option"], 1)
	assert_eq(resolved[0]["no_votes"], false)


func test_vote_time_is_configurable() -> void:
	var h := MatchHarness.new(3, {"rules": {"vote_seconds": 5}})
	var duo := h.start_with_humans(2)
	h.server.take_events(duo[0])
	h.advance(5.0)
	assert_eq(_events(h, duo[0], "vote_resolved").size(), 1)


func test_no_votes_picks_randomly_from_all_options() -> void:
	var picked := {}
	for seed_value in 40:
		var h := MatchHarness.new(seed_value)
		var solo := h.start_with_humans(1)[0]
		h.server.take_events(solo)
		h.advance(20.0)
		var resolved: Dictionary = _events(h, solo, "vote_resolved")[0]
		assert_eq(resolved["no_votes"], true)
		picked[resolved["option"]] = true
	assert_true(picked.size() >= 2, "different options get picked across seeds")


func test_vote_outside_voting_phase_is_rejected() -> void:
	var h := MatchHarness.new(3)
	var solo := h.start_with_humans(1)[0]
	h.server.command(solo, {"type": "vote", "option": 0})
	assert_eq(h.match_view(solo)["phase"], "travel")
	assert_rejected(h.server.command(solo, {"type": "vote", "option": 0}), "wrong_phase")


func test_vote_in_lobby_is_rejected() -> void:
	var h := MatchHarness.new(3)
	var host := h.create_room()
	assert_rejected(h.server.command(host, {"type": "vote", "option": 0}), "wrong_phase")


func test_chosen_route_leads_to_encounter_of_advertised_type() -> void:
	var h := MatchHarness.new(8)
	var solo := h.start_with_humans(1)[0]
	var options: Array = h.match_view(solo)["vote"]["options"]
	h.server.command(solo, {"type": "vote", "option": options.size() - 1})
	h.server.take_events(solo)
	h.advance(3.0)
	var started := _events(h, solo, "encounter_started")
	assert_eq(started.size(), 1)
	assert_eq(started[0]["encounter_type"], options[-1]["type"])
	assert_eq(started[0]["name"], options[-1]["name"])


func test_journey_reaches_guardian_boss_after_five_layers() -> void:
	var h := MatchHarness.new(21, MatchHarness.EASY)
	var bot := MatchBot.new(h, h.start_with_humans(2))
	var view := bot.play_until(func(v: Dictionary) -> bool: return v["phase"] == "boss")
	assert_eq(view["phase"], "boss")
	assert_eq(view["layer"], 5)
	assert_eq(bot.events_of_type("vote_resolved").size(), 5)
	assert_eq(bot.events_of_type("encounter_completed").size(), 5)
	assert_eq(bot.events_of_type("boss_reached").size(), 1)


## Options offered at every Layer when a bot always takes the first route.
func _route_log(seed_value: int) -> Array:
	var h := MatchHarness.new(seed_value, MatchHarness.EASY)
	var bot := MatchBot.new(h, h.start_with_humans(1))
	bot.play_until(func(v: Dictionary) -> bool: return v["phase"] == "boss")
	var layers := []
	for event in bot.events_of_type("vote_started"):
		layers.append(event["options"])
	return layers


func _duo_split_winner(seed_value: int) -> Dictionary:
	var h := MatchHarness.new(seed_value)
	var duo := h.start_with_humans(2)
	h.server.take_events(duo[0])
	h.server.command(duo[0], {"type": "vote", "option": 0})
	h.server.command(duo[1], {"type": "vote", "option": 1})
	return _events(h, duo[0], "vote_resolved")[0]


func _events(h: MatchHarness, session: int, type: String) -> Array:
	var out := []
	for event in h.server.take_events(session):
		if event["type"] == type:
			out.append(event)
	return out
