extends TestCase
## Core combat through the Match interface (issue #8, spec stories 27–41).
## Content is tuned per test so numbers are exact: no damage variance, no
## crits, wolves slower than the Party unless a test says otherwise.

const SLOW_TANKY_WOLVES := {"enemies": {"grey_wolf": {"stats": {"max_hp": 500, "spd": 5}}}}

var h: MatchHarness
var sessions: Array[int] = []


func _combat(humans: int, extra: Dictionary = SLOW_TANKY_WOLVES, seed_value: int = 4) -> void:
	h = MatchHarness.new(seed_value, MatchHarness.merge([MatchHarness.ALL_COMBAT, MatchHarness.EXACT_DAMAGE, extra]))
	sessions = h.start_with_humans(humans)
	h.enter_first_encounter(sessions)


func _combat_view(session: int = -1) -> Dictionary:
	var view := h.match_view(sessions[0] if session == -1 else session)
	var encounter = view.get("encounter")
	return encounter if encounter != null else {}


func _party(slot: int) -> Dictionary:
	return h.match_view(sessions[0])["party"][slot]


func _enemy(id: String) -> Dictionary:
	for enemy in _combat_view()["enemies"]:
		if enemy["id"] == id:
			return enemy
	return {}


## Steps time until it is `actor`'s turn in `round_number`.
func _until_turn(actor: String, round_number: int, limit: float = 60.0) -> void:
	var waited := 0.0
	while waited < limit:
		var view := _combat_view()
		if view.get("actor") == actor and view.get("round") == round_number:
			return
		h.advance(0.1, 0.1)
		waited += 0.1
	fail("never reached %s's turn in round %d" % [actor, round_number])


func _act(session: int, cmd: Dictionary) -> Dictionary:
	var full := {"type": "action"}
	full.merge(cmd)
	return h.server.command(session, full)


func _events_of(session: int, type: String) -> Array:
	var out := []
	for event in h.server.take_events(session):
		if event["type"] == type:
			out.append(event)
	return out


func test_combat_encounter_fights_forest_enemies_from_content() -> void:
	_combat(1, {})
	var view := _combat_view()
	assert_eq(view["kind"], "combat")
	assert_eq(view["enemies"].size(), 2)
	for enemy in view["enemies"]:
		assert_eq([enemy["name"], enemy["hp"], enemy["max_hp"]], ["Grey Wolf", 26, 26])


func test_turn_order_follows_speed() -> void:
	_combat(1, {})
	var rounds := _events_of(sessions[0], "round_started")
	assert_eq(rounds[0]["order"], ["e0", "e1", "p0", "p1", "p2", "p3", "p4"], "wolves (13) before Party (10)")


func test_equal_speed_puts_party_first_in_slot_order() -> void:
	_combat(1, {"enemies": {"grey_wolf": {"stats": {"spd": 10}}}})
	var rounds := _events_of(sessions[0], "round_started")
	assert_eq(rounds[0]["order"], ["p0", "p1", "p2", "p3", "p4", "e0", "e1"])


func test_human_turn_opens_fifteen_second_action_window() -> void:
	_combat(1)
	var snap := h.server.snapshot(sessions[0])
	var view: Dictionary = snap["match"]["encounter"]
	assert_eq(view["actor"], "p0")
	assert_eq(view["actor_controller"], "human")
	assert_eq(view["your_turn"], true)
	assert_eq(float(view["deadline"]) - float(snap["time"]), 15.0)


func test_action_window_timeout_defends_automatically() -> void:
	_combat(1)
	h.server.take_events(sessions[0])
	h.advance(14.9, 0.1)
	assert_eq(_combat_view()["actor"], "p0", "still waiting inside the window")
	h.advance(0.2, 0.1)
	var actions := _events_of(sessions[0], "action_resolved")
	assert_eq(actions[0]["actor"], "p0")
	assert_eq(actions[0]["action"], "defend")
	assert_eq(actions[0]["automatic"], true)


func test_attack_damages_chosen_enemy() -> void:
	_combat(1)
	h.server.take_events(sessions[0])
	assert_ok(_act(sessions[0], {"action": "attack", "target": "e1"}))
	var action: Dictionary = _events_of(sessions[0], "action_resolved")[0]
	assert_eq(action["results"][0]["target"], "e1")
	assert_eq(action["results"][0]["damage"], 7, "atk 8 - def 2 x 0.5")
	assert_eq(_enemy("e1")["hp"], 493)


func test_attack_on_invalid_target_is_rejected_without_change() -> void:
	_combat(1)
	var before := _combat_view()
	for target in ["e9", "p1", "", "p0"]:
		assert_rejected(_act(sessions[0], {"action": "attack", "target": target}), "invalid_target", target)
	assert_eq(_combat_view(), before)


func test_defend_halves_damage_until_next_turn() -> void:
	_combat(1)
	assert_ok(_act(sessions[0], {"action": "defend"}))
	_until_turn("p0", 2)
	assert_eq(_party(0)["hp"], 32, "two wolf bites of 8 halved to 4 each")
	assert_ok(_act(sessions[0], {"action": "attack", "target": "e0"}))
	_until_turn("p0", 3)
	assert_eq(_party(0)["hp"], 16, "no longer defending: two full bites of 8")


func test_item_heals_from_shared_party_inventory() -> void:
	_combat(2)
	assert_ok(_act(sessions[0], {"action": "defend"}))
	_until_turn("p0", 2)
	assert_eq(_party(0)["hp"], 32)
	h.server.take_events(sessions[0])
	assert_ok(_act(sessions[0], {"action": "item", "item": "herb", "target": "p0"}))
	var action: Dictionary = _events_of(sessions[0], "action_resolved")[0]
	assert_eq(action["results"][0]["heal"], 8, "heal capped at max HP")
	assert_eq(_party(0)["hp"], 40)
	var seen_by_partner: Array = h.match_view(sessions[1])["inventory"]
	assert_eq(seen_by_partner[0]["item"], "herb")
	assert_eq(seen_by_partner[0]["count"], 2, "one herb used from the shared inventory")


func test_missing_item_is_rejected() -> void:
	_combat(1)
	assert_rejected(_act(sessions[0], {"action": "item", "item": "tonic", "target": "p0"}), "item_unavailable")
	assert_rejected(_act(sessions[0], {"action": "item", "item": "herb", "target": "e0"}), "invalid_target")


func test_classless_character_cannot_use_skill() -> void:
	_combat(1)
	assert_rejected(_act(sessions[0], {"action": "skill", "skill": "power_slash", "target": "e0"}), "skill_unavailable")
	assert_eq(_combat_view()["choices"]["skills"], {})


func test_commands_for_someone_else_are_rejected() -> void:
	_combat(2)
	var before := _combat_view()
	assert_rejected(_act(sessions[1], {"slot": 0, "action": "defend"}), "not_your_slot")
	assert_rejected(_act(sessions[1], {"action": "defend"}), "not_your_turn")
	assert_eq(_combat_view(), before)
	assert_eq(_combat_view(sessions[1])["your_turn"], false)


func test_command_after_action_window_is_rejected() -> void:
	_combat(1)
	h.clock.advance(15.0)
	assert_rejected(_act(sessions[0], {"action": "attack", "target": "e0"}), "action_window_closed")
	h.server.update()
	var actions := _events_of(sessions[0], "action_resolved")
	assert_eq(actions[-1]["action"], "defend")


func test_every_client_sees_the_same_combat_events() -> void:
	_combat(2, {}, 17)
	h.server.take_events(sessions[0])
	h.server.take_events(sessions[1])
	h.advance(40.0)
	var first := h.server.take_events(sessions[0])
	var second := h.server.take_events(sessions[1])
	assert_true(first.size() > 5)
	assert_eq(first, second)


func test_victory_grants_exp_gold_and_level_ups() -> void:
	_combat(1, {"enemies": {"grey_wolf": {"stats": {"max_hp": 1, "spd": 5}, "rewards": {"exp": 30, "gold": 7}}}})
	h.server.take_events(sessions[0])
	assert_ok(_act(sessions[0], {"action": "attack", "target": "e0"}))
	h.advance(1.0)
	var ended := _events_of(sessions[0], "combat_ended")
	assert_eq(ended.size(), 1)
	assert_eq(ended[0]["result"], "victory")
	assert_eq(ended[0]["rewards"], {"exp": 60, "gold": 14, "items": {}})
	var view := h.match_view(sessions[0])
	assert_eq(view["gold"], 14)
	for character in view["party"]:
		assert_eq([character["level"], character["exp"]], [3, 5], "60 EXP: 20 + 35 to reach level 3")
		assert_eq([character["max_hp"], character["atk"]], [50, 10], "+5 HP and +1 ATK per level")


func test_journey_continues_after_combat_victory() -> void:
	_combat(1, {"enemies": {"grey_wolf": {"stats": {"max_hp": 1, "spd": 5}}}})
	_act(sessions[0], {"action": "attack", "target": "e0"})
	h.server.take_events(sessions[0])
	h.advance(4.0)
	var types := []
	for event in h.server.take_events(sessions[0]):
		types.append(event["type"])
	assert_has(types, "encounter_completed")
	assert_has(types, "vote_started")
	assert_eq(h.match_view(sessions[0])["layer"], 2)


func test_party_wipe_ends_match_in_defeat_with_summary() -> void:
	_combat(1, {"enemies": {"grey_wolf": {"stats": {"atk": 999, "spd": 50, "max_hp": 999}}}})
	h.server.take_events(sessions[0])
	h.advance(30.0)
	var ended := _events_of(sessions[0], "match_ended")
	assert_eq(ended.size(), 1)
	assert_eq(ended[0]["result"], "defeat")
	var view := h.match_view(sessions[0])
	assert_eq(view["phase"], "defeat")
	assert_eq(view["summary"]["result"], "defeat")
	assert_eq(view["summary"]["layer"], 1)
	assert_eq(h.room_view(sessions[0])["state"], "lobby", "room is back to the lobby")
