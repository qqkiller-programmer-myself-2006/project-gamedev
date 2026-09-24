extends TestCase
## Story Events and the Story Clue log (issue #15, spec stories 60, 61).

const STORY_SITES := ["old_campfire", "carved_stone", "ranger_hut", "hollow_tree"]

var h: MatchHarness
var sessions: Array[int] = []


## Every Layer offers one Story Event at `site` and one Combat.
func _start(site: String, humans: int = 1, extra: Dictionary = {}, seed_value: int = 3) -> void:
	var sites := {"journey": {"sites": {"story": [{"id": site, "name": site.capitalize(), "hint": "A clue."}]}}}
	h = MatchHarness.new(seed_value, MatchHarness.merge([MatchHarness.only_routes(["story", "combat"]),
			MatchHarness.EXACT_DAMAGE, MatchHarness.WOLF_PAIR, sites, extra]))
	sessions = h.start_with_humans(humans)


func _view(session: int = -1) -> Dictionary:
	return h.match_view(sessions[0] if session == -1 else session)


func _encounter(session: int = -1) -> Dictionary:
	var encounter = _view(session).get("encounter")
	return encounter if encounter != null else {}


func _events(type: String) -> Array:
	var out := []
	for event in h.server.take_events(sessions[0]):
		if event["type"] == type:
			out.append(event)
	return out


func _clue_ids() -> Array:
	var ids := []
	for clue in _view()["clues"]:
		ids.append(clue["id"])
	return ids


func test_forest_has_several_story_events_that_each_reveal_a_clue() -> void:
	var titles := {}
	for site in STORY_SITES:
		_start(site)
		h.take_route(sessions, "story")
		var encounter := _encounter()
		assert_eq(encounter["kind"], "story", site)
		assert_false(str(encounter["text"]).is_empty(), site)
		titles[encounter["title"]] = true
		if encounter["stage"] == "choosing":
			h.server.command(sessions[0], {"type": "vote", "option": 0})
		assert_eq(_view()["clues"].size(), 1, "%s adds a Story Clue" % site)
		assert_false(str(_view()["clues"][0]["text"]).is_empty())
	assert_eq(titles.size(), 4, "four different Story Events")


func test_event_without_choices_goes_straight_to_its_outcome() -> void:
	_start("carved_stone")
	h.take_route(sessions, "story")
	var encounter := _encounter()
	assert_eq(encounter["stage"], "outcome")
	assert_eq(encounter["outcome"]["clue"]["id"], "carved_map")
	assert_eq(_clue_ids(), ["carved_map"])


func test_story_choice_follows_path_voting_rules() -> void:
	_start("ranger_hut", 2)
	h.take_route(sessions, "story")
	assert_eq(_encounter()["stage"], "choosing")
	assert_eq(_encounter()["vote"]["options"].size(), 2)
	h.server.take_events(sessions[0])
	assert_ok(h.server.command(sessions[0], {"type": "vote", "option": 1}))
	assert_rejected(h.server.command(sessions[0], {"type": "vote", "option": 0}), "already_voted")
	assert_eq(_encounter()["stage"], "choosing", "waits for the other human, not for AI")
	assert_ok(h.server.command(sessions[1], {"type": "vote", "option": 1}))
	var resolved := _events("story_choice_resolved")
	assert_eq(resolved[0]["option"], 1)
	assert_eq(resolved[0]["votes"], {"0": 1, "1": 1})
	assert_eq(_clue_ids(), ["wren_return"])


func test_split_story_vote_is_broken_randomly_and_reproducibly() -> void:
	var picks := {}
	for seed_value in 16:
		var first := _split_vote(seed_value)
		assert_eq(first["tie_broken"], true)
		assert_eq(_split_vote(seed_value)["option"], first["option"])
		picks[first["option"]] = true
	assert_eq(picks.size(), 2)


func test_silent_story_vote_picks_a_choice_when_time_runs_out() -> void:
	_start("old_campfire")
	h.take_route(sessions, "story")
	h.server.take_events(sessions[0])
	h.advance(20.1)
	var resolved := _events("story_choice_resolved")
	assert_eq(resolved[0]["no_votes"], true)
	assert_eq(_view()["clues"].size(), 1)


func test_choices_lead_to_different_outcomes() -> void:
	_start("old_campfire")
	h.take_route(sessions, "story")
	h.server.command(sessions[0], {"type": "vote", "option": 0})
	assert_eq(_clue_ids(), ["journal_page"])
	var firebombs := 0
	for entry in _view()["inventory"]:
		if entry["item"] == "firebomb":
			firebombs = entry["count"]
	assert_eq(firebombs, 1)
	_start("old_campfire")
	h.take_route(sessions, "story")
	h.server.command(sessions[0], {"type": "vote", "option": 1})
	assert_eq(_clue_ids(), ["tin_cup"])
	assert_eq(_encounter()["outcome"]["healed"], true)


func test_outcome_rewards_come_from_content() -> void:
	_start("hollow_tree")
	h.take_route(sessions, "story")
	assert_eq(_view()["gold"], 15)
	_start("ranger_hut")
	h.take_route(sessions, "story")
	h.server.command(sessions[0], {"type": "vote", "option": 0})
	assert_eq(_view()["party"][0]["exp"], 10)


func test_reading_ends_when_everyone_is_ready_or_time_runs_out() -> void:
	_start("carved_stone", 2)
	h.take_route(sessions, "story")
	assert_ok(h.server.command(sessions[0], {"type": "ready"}))
	assert_eq(_view()["layer"], 1, "waits for the other reader")
	assert_ok(h.server.command(sessions[1], {"type": "ready"}))
	assert_eq(_view()["layer"], 2)
	h.take_route(sessions, "story")
	h.advance(25.1)
	assert_eq(_view()["layer"], 3, "reading time ran out")


func test_clue_log_is_visible_at_any_time_later_in_the_match() -> void:
	_start("carved_stone", 1, {"enemies": {"grey_wolf": {"stats": {"max_hp": 500, "spd": 5}}}})
	h.take_route(sessions, "story")
	h.server.command(sessions[0], {"type": "ready"})
	assert_eq(_view()["phase"], "voting")
	assert_eq(_clue_ids(), ["carved_map"])
	h.take_route(sessions, "combat")
	assert_eq(_encounter()["kind"], "combat")
	var clue: Dictionary = _view()["clues"][0]
	assert_eq([clue["id"], clue["title"], clue["layer"], clue["source"]], ["carved_map", "The Carved Stone", 1, "story"])


func test_clues_found_are_counted_in_the_match_summary() -> void:
	_start("carved_stone", 1, {"enemies": {"grey_wolf": {"stats": {"atk": 999, "spd": 50, "max_hp": 999}}}})
	h.take_route(sessions, "story")
	h.server.command(sessions[0], {"type": "ready"})
	h.take_route(sessions, "combat")
	h.advance(30.0)
	var summary: Dictionary = _view()["summary"]
	assert_eq(summary["result"], "defeat")
	assert_eq(summary["clues_found"], 1)
	assert_eq(summary["clues"][0]["id"], "carved_map")


func test_won_fights_can_turn_up_clues() -> void:
	_start("carved_stone", 1, {
		"story": {"combat_clues": {"chance": 1.0}},
		"enemies": {"grey_wolf": {"stats": {"max_hp": 1, "spd": 5}}},
	})
	h.take_route(sessions, "combat")
	h.server.take_events(sessions[0])
	h.server.command(sessions[0], {"type": "action", "action": "attack", "target": "e0"})
	h.advance(0.9)
	var ended := _events("combat_ended")
	var clue: Dictionary = ended[0]["rewards"]["clue"]
	assert_has(["wolf_collar", "torn_cloak", "guardian_mark"], clue["id"])
	assert_eq(_view()["clues"][0]["source"], "combat")


func test_story_sites_never_repeat_within_a_match() -> void:
	for seed_value in 60:
		var harness := MatchHarness.new(seed_value, MatchHarness.EASY)
		var bot := MatchBot.new(harness, harness.start_with_humans(1))
		bot.play_until(func(v: Dictionary) -> bool: return v["phase"] == "boss")
		var seen := {}
		for event in bot.events_of_type("vote_started"):
			for option in event["options"]:
				if option["type"] == "story":
					assert_false(seen.has(option["name"]), "seed %d repeats %s" % [seed_value, option["name"]])
					seen[option["name"]] = true


func _split_vote(seed_value: int) -> Dictionary:
	_start("ranger_hut", 2, {}, seed_value)
	h.take_route(sessions, "story")
	h.server.take_events(sessions[0])
	h.server.command(sessions[0], {"type": "vote", "option": 0})
	h.server.command(sessions[1], {"type": "vote", "option": 1})
	return _events("story_choice_resolved")[0]
