extends TestCase
## Guardian Boss, Victory/Defeat, Forest ending and a new Match (issue #16,
## spec stories 40, 63–66).

## One quiet Layer (a Rest) so the Boss comes right after it.
const SHORT_JOURNEY := {"journey": {"layers": 1}}
const EXACT_BOSS := {"enemies": {"elder_thornwarden": {"stats": {"crit": 0}}}}

var h: MatchHarness
var sessions: Array[int] = []


func _to_boss(humans: int = 1, extra: Dictionary = {}, seed_value: int = 3) -> void:
	h = MatchHarness.new(seed_value, MatchHarness.merge([MatchHarness.only_routes(["rest"]), SHORT_JOURNEY,
			MatchHarness.EXACT_DAMAGE, EXACT_BOSS, extra]))
	sessions = h.start_with_humans(humans)
	h.take_route(sessions, "rest")
	h.advance(4.0)


func _view(session: int = -1) -> Dictionary:
	return h.match_view(sessions[0] if session == -1 else session)


func _boss_view() -> Dictionary:
	var encounter = _view().get("encounter")
	return encounter if encounter != null else {}


## Plays for `seconds`, running `on_turn` whenever it is the first human's turn,
## and returns every event seen.
func _play(seconds: float, on_turn: Callable) -> Array:
	var seen := []
	var waited := 0.0
	while waited < seconds and not _view()["phase"] in ["victory", "defeat"]:
		if _boss_view().get("your_turn", false):
			on_turn.call()
		h.advance(0.1, 0.1)
		waited += 0.1
		seen.append_array(h.server.take_events(sessions[0]))
	return seen


func _attack() -> void:
	h.server.command(sessions[0], {"type": "action", "action": "attack", "target": "e0"})


func _defend() -> void:
	h.server.command(sessions[0], {"type": "action", "action": "defend"})


func _of_type(events: Array, type: String) -> Array:
	var out := []
	for event in events:
		if event["type"] == type:
			out.append(event)
	return out


func test_boss_appears_after_the_fifth_layer() -> void:
	h = MatchHarness.new(9, MatchHarness.EASY)
	var bot := MatchBot.new(h, h.start_with_humans(1))
	var view := bot.play_until(func(v: Dictionary) -> bool: return v["phase"] == "boss")
	assert_eq(bot.events_of_type("encounter_completed").size(), 5)
	assert_eq(view["layer"], 5)
	var encounter: Dictionary = view["encounter"]
	assert_eq(encounter["kind"], "boss")
	assert_eq(encounter["boss"]["name"], "Elder Thornwarden")
	assert_eq(encounter["boss"]["title"], "Guardian of the Forest")
	assert_eq(encounter["enemies"][0]["max_hp"], h.content.get_int("enemies.elder_thornwarden.stats.max_hp"),
			"Boss numbers come from content")
	assert_eq(bot.events_of_type("boss_started").size(), 1)


func test_boss_changes_phase_at_its_threshold_and_announces_it() -> void:
	_to_boss(1, {"enemies": {"elder_thornwarden": {"stats": {"max_hp": 120, "atk": 1, "mag": 1}}}})
	assert_eq(_boss_view()["boss"]["phase"], 1)
	assert_eq(_boss_view()["boss"]["phases_total"], 2)
	var events := _play(40.0, _attack)
	var phases := _of_type(events, "boss_phase")
	assert_eq(phases.size(), 1)
	assert_eq(phases[0]["phase"], 2)
	assert_eq(phases[0]["name"], "Wrathful Bloom")
	assert_false(str(phases[0]["text"]).is_empty())


func test_boss_telegraphs_its_heavy_blow_a_turn_ahead() -> void:
	_to_boss(1, {"enemies": {"elder_thornwarden": {"stats": {"max_hp": 5000, "atk": 5, "spd": 5}}}})
	var events := _play(30.0, _defend)
	var telegraph_at := -1
	var blow_at := -1
	for i in events.size():
		if events[i]["type"] == "boss_telegraph" and telegraph_at == -1:
			telegraph_at = i
		if events[i]["type"] == "action_resolved" and events[i].get("move") == "crushing_root" \
				and events[i]["action"] == "attack" and blow_at == -1:
			blow_at = i
	assert_true(telegraph_at >= 0, "the Boss announces Crushing Root")
	assert_true(blow_at > telegraph_at, "and only strikes later")
	assert_eq(events[telegraph_at]["move"], "crushing_root")
	assert_eq(events[telegraph_at]["target"], "p0", "the strongest character (tie: first)")
	var party_turns_between := 0
	for i in range(telegraph_at, blow_at):
		if events[i]["type"] == "turn_started" and str(events[i]["actor"]).begins_with("p"):
			party_turns_between += 1
	assert_eq(party_turns_between, 5, "every character gets a turn to react")


func test_telegraph_is_visible_in_the_boss_view_until_it_lands() -> void:
	_to_boss(1, {"enemies": {"elder_thornwarden": {"stats": {"max_hp": 5000, "atk": 5, "spd": 5}}}})
	var seen_pending := false
	var waited := 0.0
	while waited < 30.0 and not seen_pending:
		if _boss_view().get("your_turn", false):
			_defend()
		h.advance(0.1, 0.1)
		waited += 0.1
		seen_pending = not _boss_view()["boss"]["telegraph"].is_empty()
	assert_true(seen_pending)
	var telegraph: Dictionary = _boss_view()["boss"]["telegraph"]
	assert_eq([telegraph["move"], telegraph["name"], telegraph["target"]], ["crushing_root", "Crushing Root", "p0"])
	assert_true(str(telegraph["text"]).contains("Arin"), "names the target: %s" % telegraph["text"])


func test_defending_against_the_telegraphed_blow_halves_it() -> void:
	var blows := []
	for defend in [false, true]:
		_to_boss(1, {"enemies": {"elder_thornwarden": {"stats": {"max_hp": 5000, "spd": 5}}}})
		var on_turn := func() -> void:
			var pending: Dictionary = _boss_view()["boss"]["telegraph"]
			if defend and not pending.is_empty():
				_defend()
			else:
				_attack()
		for event in _play(30.0, on_turn):
			if event["type"] == "action_resolved" and event.get("move") == "crushing_root" and event["action"] == "attack":
				blows.append(event["results"][0]["damage"])
				break
	assert_eq(blows, [43, 21], "17 ATK x 2.6 - 1.5, halved by Defend")


func test_ai_braces_for_telegraphed_blows() -> void:
	_to_boss(1, {"enemies": {"elder_thornwarden": {"stats": {"max_hp": 5000, "spd": 5, "atk": 5}}},
			"boss": {"phases": [{"name": "Test", "below_ratio": 1.0, "pattern": ["telegraph:thorn_storm"]}]},
			"classes": {"classless": {"stats": {"max_hp": 40}}}})
	var events := _play(60.0, _defend)
	var braced := false
	for event in events:
		if event["type"] == "action_resolved" and event["actor"] != "p0" and event["action"] == "defend" \
				and str(event["actor"]).begins_with("p"):
			braced = true
	assert_true(braced, "hurt AI characters Defend before a Party-wide blow")


func test_defeating_the_boss_is_victory_with_forest_ending_and_summary() -> void:
	_to_boss(2, {"enemies": {"elder_thornwarden": {"stats": {"max_hp": 1, "spd": 1}}}})
	h.server.take_events(sessions[1])
	_play(10.0, _attack)
	var view := _view(sessions[1])
	assert_eq(view["phase"], "victory")
	var summary: Dictionary = view["summary"]
	assert_eq(summary["result"], "victory")
	assert_eq(summary["title"], "The Forest Falls Silent")
	assert_false(str(summary["text"]).is_empty())
	for key in ["clues_found", "clues", "classes_discovered", "elapsed", "enemies_defeated"]:
		assert_has(summary, key)
	assert_true(float(summary["elapsed"]) > 0.0)
	var ended := _of_type(h.server.take_events(sessions[1]), "match_ended")
	assert_eq(ended[0]["result"], "victory")
	assert_eq(h.room_view(sessions[1])["state"], "lobby", "back to the room, no Region selection")


func test_party_wipe_against_the_boss_is_defeat() -> void:
	_to_boss(1, {"enemies": {"elder_thornwarden": {"stats": {"max_hp": 5000, "atk": 999, "spd": 50}}}})
	_play(60.0, _defend)
	var view := _view()
	assert_eq(view["phase"], "defeat")
	assert_eq(view["summary"]["title"], "Lost in the Forest")


func test_host_starts_a_new_match_in_the_same_room_after_it_ends() -> void:
	_to_boss(2, {"enemies": {"elder_thornwarden": {"stats": {"max_hp": 1, "spd": 1}}}})
	_play(10.0, _attack)
	assert_eq(_view()["phase"], "victory")
	assert_rejected(h.server.command(sessions[1], {"type": "start_match"}), "not_host")
	assert_ok(h.server.command(sessions[0], {"type": "start_match"}))
	var view := _view(sessions[1])
	assert_eq(view["number"], 2)
	assert_eq([view["phase"], view["layer"]], ["voting", 1])
	assert_eq(view["summary"], {})
	for character in view["party"]:
		assert_eq(character["class"], "classless")
		assert_eq(character["hp"], character["max_hp"])
	var slots: Array = h.room_view(sessions[1])["slots"]
	assert_eq([slots[0]["owner_name"], slots[1]["owner_name"]], ["P1", "P2"], "players keep their slots")
	assert_eq(h.room_view(sessions[1])["your_slot"], 1)


func test_new_player_can_join_between_matches() -> void:
	_to_boss(1, {"enemies": {"elder_thornwarden": {"stats": {"max_hp": 1, "spd": 1}}}})
	_play(10.0, _attack)
	h.join("Late")
	assert_ok(h.last_result, "the room is open again after the Match")
