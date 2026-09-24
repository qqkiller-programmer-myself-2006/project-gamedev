extends TestCase
## Full-run regression over many seeds with the real Forest content
## (issue #18, spec stories 26, 80, 82). Bots play complete Matches through
## the Match interface only.

const SEEDS := 40
const FIRST_SEED := 5000
## The whole slice should be won most of the time, but not always.
const MIN_WIN_RATE := 0.7
const MAX_WIN_RATE := 0.97


func test_single_player_matches_always_finish_and_mostly_win() -> void:
	_check_mode(1)


func test_duo_coop_matches_always_finish_and_mostly_win() -> void:
	_check_mode(2)


func test_every_seed_offers_class_encounter_early_and_merchant_before_boss() -> void:
	for seed_value in range(FIRST_SEED, FIRST_SEED + SEEDS):
		var run := _play(seed_value, 1)
		var bot: MatchBot = run["bot"]
		var layers: Array = bot.events_of_type("vote_started")
		var early_class := false
		var merchant := false
		for event in layers:
			for option in event["options"]:
				early_class = early_class or (option["type"] == "class" and int(event["layer"]) <= 2)
				merchant = merchant or option["type"] == "merchant"
		assert_true(early_class, "seed %d: Class Encounter in Layer 1-2" % seed_value)
		if run["view"]["summary"]["result"] == "victory" or bot.events_of_type("boss_started").size() > 0:
			assert_true(merchant, "seed %d: Merchant offered before the Boss" % seed_value)


func test_player_dropping_mid_match_still_finishes() -> void:
	for seed_value in range(FIRST_SEED, FIRST_SEED + 10):
		var h := MatchHarness.new(seed_value)
		var sessions := h.start_with_humans(2)
		var stayer := MatchBot.new(h, [sessions[0]])
		stayer.choose_route = MatchBot.sensible_route
		var leaver := MatchBot.new(h, [sessions[1]])
		leaver.choose_route = MatchBot.sensible_route
		var both := func(v: Dictionary) -> bool: return v["layer"] >= 3
		stayer.play_until(func(v: Dictionary) -> bool:
			leaver.act(sessions[1])
			return both.call(v))
		h.server.close_session(sessions[1])
		var view := stayer.play_to_end()
		assert_has(["victory", "defeat"], view["phase"], "seed %d ends" % seed_value)
		assert_eq(view["party"][1]["controller"], "ai")


func test_idle_humans_never_stall_a_match() -> void:
	for seed_value in range(FIRST_SEED, FIRST_SEED + 5):
		var h := MatchHarness.new(seed_value)
		var sessions := h.start_with_humans(2)
		var waited := 0.0
		while waited < 4 * 3600.0:
			var view := h.match_view(sessions[0])
			if view["phase"] in ["victory", "defeat"]:
				break
			h.advance(5.0, 0.5)
			waited += 5.0
		var final := h.match_view(sessions[0])
		assert_has(["victory", "defeat"], final["phase"],
				"seed %d: votes, Action windows and offers all time out" % seed_value)
		assert_true(final["summary"]["elapsed"] > 0.0)


func test_defeat_returns_to_the_room_and_the_next_match_plays_through() -> void:
	var h := MatchHarness.new(FIRST_SEED, {"enemies": {"grey_wolf": {"stats": {"atk": 999, "spd": 60}},
			"thornback_boar": {"stats": {"atk": 999, "spd": 60}}, "bramble_archer": {"stats": {"atk": 999, "spd": 60}},
			"forest_wisp": {"stats": {"mag": 999, "spd": 60}}},
			"journey": {"type_weights": {"combat": 1, "merchant": 0, "rest": 0, "treasure": 0, "story": 0, "class": 0},
				"guarantees": {"class_by_layer": 0, "merchant_before_boss": false}}})
	var sessions := h.start_with_humans(1)
	var bot := MatchBot.new(h, sessions)
	assert_eq(bot.play_to_end()["phase"], "defeat")
	assert_ok(h.server.command(sessions[0], {"type": "start_match"}))
	var again := MatchBot.new(h, sessions)
	var view := again.play_to_end()
	assert_eq(view["number"], 2)
	assert_eq(view["phase"], "defeat", "the second Match also runs to its end")


func test_modelled_human_pacing_stays_in_a_sane_range() -> void:
	var minutes := 0.0
	var runs := 8
	for seed_value in range(FIRST_SEED, FIRST_SEED + runs):
		minutes += float(_play(seed_value, 1, true)["view"]["summary"]["elapsed"]) / 60.0
	minutes /= runs
	assert_between(minutes, 7.0, 35.0, "average modelled Single-player Match length (docs/balance.md)")


func _check_mode(humans: int) -> void:
	var wins := 0
	for seed_value in range(FIRST_SEED, FIRST_SEED + SEEDS):
		var run := _play(seed_value, humans)
		var view: Dictionary = run["view"]
		assert_has(["victory", "defeat"], view["phase"], "seed %d reaches an end" % seed_value)
		assert_eq(run["bot"].commands_rejected, 0, "seed %d: the bot never sent an illegal command" % seed_value)
		if view["phase"] == "victory":
			wins += 1
	var rate := float(wins) / SEEDS
	assert_between(rate, MIN_WIN_RATE, MAX_WIN_RATE, "%d-human win rate %d/%d" % [humans, wins, SEEDS])


func _play(seed_value: int, humans: int, paced: bool = false) -> Dictionary:
	var h := MatchHarness.new(seed_value)
	var bot := MatchBot.new(h, h.start_with_humans(humans))
	bot.choose_route = MatchBot.sensible_route
	if paced:
		bot.think = MatchBot.HUMAN_PACE
	var view := bot.play_to_end(4 * 3600.0)
	return {"view": view, "bot": bot}
