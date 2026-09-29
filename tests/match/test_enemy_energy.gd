extends TestCase

var h: MatchHarness
var sessions: Array[int] = []

func _to_combat(humans: int = 1, extra: Dictionary = {}) -> void:
	h = MatchHarness.new(3, MatchHarness.merge([MatchHarness.only_routes(["combat"]), MatchHarness.EXACT_DAMAGE, extra]))
	sessions = h.start_with_humans(humans)
	h.take_route(sessions, "combat")

func test_enemy_energy_gain_cap_and_snapshot() -> void:
	_to_combat(1, {"enemies": {"grey_wolf": {"energy_max": 2, "special": {"name": "Rend", "energy": 1, "use": {"target": "enemy", "damage": {"stat": "atk", "power": 1.0}}}}}})
	var v = h.match_view(sessions[0])
	var wolf = v["encounter"]["enemies"][0]
	assert_eq(int(wolf.get("energy", -1)), 0, "starts at 0")
	assert_eq(int(wolf.get("energy_max", -1)), 2, "snapshot shows max")
	
	h.server.take_events(sessions[0])
	
	# Turn 1
	h.advance(h.content.get_float("rules.action_window_seconds", 15.0) + 0.1) # player defends
	h.advance(2.0) # let enemy act (gets 0 regen on turn 1)
	
	# Turn 2
	h.advance(h.content.get_float("rules.action_window_seconds", 15.0) + 0.1) # player defends
	h.advance(2.0) # let enemy act (gets 1 regen on turn 2 -> energy = 1, uses special!)
	
	var events = h.server.take_events(sessions[0])
	var rend_used = false
	for e in events:
		if e.get("type") == "action_resolved" and e.get("actor", "").begins_with("e") and e.get("action") == "special":
			rend_used = true
	assert_true(rend_used, "used special")
