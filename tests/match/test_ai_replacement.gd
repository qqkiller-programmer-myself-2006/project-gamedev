extends TestCase
## AI replacement for empty slots and for players who drop mid-Match
## (issue #10, spec stories 8, 12, 14, 52–56).

const SLOW_TANKY_WOLVES := {"enemies": {"grey_wolf": {"stats": {"max_hp": 500, "spd": 5}}}}

var h: MatchHarness
var sessions: Array[int] = []


func _combat(humans: int, extra: Dictionary = SLOW_TANKY_WOLVES, seed_value: int = 4) -> void:
	h = MatchHarness.new(seed_value, MatchHarness.merge([MatchHarness.ALL_COMBAT, MatchHarness.WOLF_PAIR,
			MatchHarness.EXACT_DAMAGE, extra]))
	sessions = h.start_with_humans(humans)
	h.enter_first_encounter(sessions)


func _two_boars(boar_atk: int, inventory: Dictionary = {"herb": 3}) -> Dictionary:
	return {
		"party": {"starting_inventory": inventory},
		"encounters": {"combat": {"groups": [{"id": "boars", "enemies": ["thornback_boar", "thornback_boar"], "layers": [1, 5]}]}},
		"enemies": {"thornback_boar": {"stats": {"max_hp": 500, "spd": 5, "atk": boar_atk, "crit": 0}, "rewards": {"drops": []}}},
	}


func _combat_view(session: int) -> Dictionary:
	var encounter = h.match_view(session)["encounter"]
	return encounter if encounter != null else {}


## Advances time, Defending for every human whose turn it is, and returns
## all events the first session saw.
func _play(seconds: float) -> Array:
	var seen := []
	var waited := 0.0
	while waited < seconds:
		for session in sessions:
			if h.server.snapshot(session)["room"] != null and _combat_view(session).get("your_turn", false):
				h.server.command(session, {"type": "action", "action": "defend"})
		h.advance(0.1, 0.1)
		waited += 0.1
		seen.append_array(h.server.take_events(sessions[0]))
	return seen


func _actions_of(events: Array, actor: String) -> Array:
	var out := []
	for event in events:
		if event["type"] == "action_resolved" and event["actor"] == actor:
			out.append(event)
	return out


func test_ai_slots_take_their_own_turns() -> void:
	_combat(1)
	var events := _play(6.0)
	for slot in range(1, 5):
		var actions := _actions_of(events, "p%d" % slot)
		assert_eq(actions.size(), 1, "p%d acted once in round 1" % slot)
		assert_eq(actions[0]["action"], "attack")
		assert_eq(actions[0]["automatic"], false, "a decision, not a timeout")


func test_ai_turn_is_quick_but_readable() -> void:
	_combat(1)
	h.server.command(sessions[0], {"type": "action", "action": "defend"})
	h.server.take_events(sessions[0])
	var started_at: float = h.server.snapshot(sessions[0])["time"]
	assert_eq(_combat_view(sessions[0])["actor"], "p1")
	h.advance(0.7, 0.1)
	assert_eq(_actions_of(h.server.take_events(sessions[0]), "p1").size(), 0, "not instant")
	h.advance(0.2, 0.1)
	assert_eq(_actions_of(h.server.take_events(sessions[0]), "p1").size(), 1, "acts within a second")
	assert_true(float(h.server.snapshot(sessions[0])["time"]) - started_at < 1.0)


func test_ai_heals_itself_with_an_item_when_hp_is_low() -> void:
	_combat(1, _two_boars(30))
	var events := _play(12.0)
	var p1 := _actions_of(events, "p1")
	assert_eq(p1[0]["action"], "attack", "healthy in round 1")
	assert_eq(p1[1]["action"], "item", "11/40 HP after a boar charge")
	assert_eq(p1[1]["item"], "herb")
	assert_eq(p1[1]["results"][0]["target"], "p1")


func test_ai_defends_when_hp_is_critical_and_no_item_is_left() -> void:
	_combat(1, _two_boars(34, {"herb": 0}))
	var events := _play(12.0)
	var p1 := _actions_of(events, "p1")
	assert_eq(p1[1]["action"], "defend", "7/40 HP and nothing to heal with")


func test_ai_decisions_replay_from_the_seed() -> void:
	_combat(1, SLOW_TANKY_WOLVES, 31)
	var first := _play(20.0)
	_combat(1, SLOW_TANKY_WOLVES, 31)
	var second := _play(20.0)
	assert_eq(first, second)


func test_ai_targets_vary_with_the_seed() -> void:
	var patterns := {}
	for seed_value in 12:
		_combat(1, {"enemies": {"grey_wolf": {"stats": {"max_hp": 500, "spd": 5}}},
				"encounters": {"combat": {"groups": [{"id": "trio", "enemies": ["grey_wolf", "grey_wolf", "grey_wolf"], "layers": [1, 5]}]}}},
				seed_value)
		var targets := []
		for event in _play(6.0):
			if event["type"] == "action_resolved" and event["action"] == "attack" and event["actor"].begins_with("p"):
				targets.append(event["results"][0]["target"])
		patterns[str(targets)] = true
	assert_true(patterns.size() >= 3, "AI choices depend on the seed")


func test_player_dropping_mid_match_hands_character_to_ai_intact() -> void:
	_combat(2, _two_boars(20))
	_play(12.0)
	var before: Dictionary = h.match_view(sessions[0])["party"][1]
	h.server.take_events(sessions[0])
	h.server.close_session(sessions[1])
	var after: Dictionary = h.match_view(sessions[0])["party"][1]
	assert_eq(after["controller"], "ai")
	for key in ["class", "hp", "max_hp", "level", "exp", "atk"]:
		assert_eq(after[key], before[key], key)
	var types := []
	for event in h.server.take_events(sessions[0]):
		types.append(event["type"])
	assert_has(types, "player_left")
	assert_has(types, "slot_ai_takeover")
	var slots: Array = h.room_view(sessions[0])["slots"]
	assert_eq(slots[1]["controller"], "ai")


func test_drop_during_own_action_window_does_not_stall_the_turn() -> void:
	_combat(2)
	h.server.command(sessions[0], {"type": "action", "action": "defend"})
	assert_eq(_combat_view(sessions[0])["actor"], "p1", "Bob's turn")
	h.server.take_events(sessions[0])
	h.server.close_session(sessions[1])
	h.advance(1.0, 0.1)
	var p1 := _actions_of(h.server.take_events(sessions[0]), "p1")
	assert_eq(p1.size(), 1, "AI plays Bob's turn within a second, not after 15")
	assert_eq(p1[0]["automatic"], false)


func test_leaving_mid_match_works_like_dropping() -> void:
	_combat(2)
	assert_ok(h.server.command(sessions[1], {"type": "leave_room"}))
	assert_eq(h.match_view(sessions[0])["party"][1]["controller"], "ai")
	assert_rejected(h.server.command(sessions[1], {"type": "action", "action": "defend"}), "not_in_room")


func test_drop_during_path_voting_does_not_stall_the_vote() -> void:
	h = MatchHarness.new(3)
	sessions = h.start_with_humans(2)
	h.server.command(sessions[0], {"type": "vote", "option": 1})
	h.server.take_events(sessions[0])
	h.server.close_session(sessions[1])
	var resolved := []
	for event in h.server.take_events(sessions[0]):
		if event["type"] == "vote_resolved":
			resolved.append(event)
	assert_eq(resolved.size(), 1, "remaining human already voted")
	assert_eq(resolved[0]["option"], 1)


func test_duo_can_finish_the_journey_after_one_player_drops() -> void:
	h = MatchHarness.new(12, MatchHarness.EASY)
	sessions = h.start_with_humans(2)
	var dropped := sessions[1]
	var bot := MatchBot.new(h, [sessions[0]])
	bot.play_until(func(v: Dictionary) -> bool: return v["layer"] >= 2)
	h.server.close_session(dropped)
	var view := bot.play_until(func(v: Dictionary) -> bool: return v["phase"] == "boss")
	assert_eq(view["phase"], "boss")
	assert_eq(view["party"][1]["controller"], "ai")


func test_room_and_match_close_after_every_human_leaves() -> void:
	h = MatchHarness.new(3, {"rules": {"empty_room_grace_seconds": 10}})
	sessions = h.start_with_humans(2)
	var code := h.code
	h.server.close_session(sessions[0])
	h.server.close_session(sessions[1])
	h.advance(10.5)
	var late := h.server.open_session()
	assert_rejected(h.server.command(late, {"type": "join_room", "code": code, "name": "Late"}), "room_closed")
