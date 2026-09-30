extends TestCase

var h: MatchHarness
var sessions: Array[int] = []

func _to_combat(humans: int = 1, extra: Dictionary = {}) -> void:
	h = MatchHarness.new(3, MatchHarness.merge([MatchHarness.only_routes(["combat"]), MatchHarness.EXACT_DAMAGE, extra]))
	sessions = h.start_with_humans(humans)
	h.take_route(sessions, "combat")

func test_enemy_energy_gain_cap_and_snapshot() -> void:
	_to_combat(1, {"enemies": {"grey_wolf": {"stats": {"max_hp": 1000}, "energy_max": 2, "special": {"name": "Rend", "energy": 1, "use": {"target": "enemy", "damage": {"stat": "atk", "power": 1.0}}}}}})
	var v = h.match_view(sessions[0])
	var wolf = v["encounter"]["enemies"][0]
	assert_eq(int(wolf.get("energy", -1)), 1, "first own turn immediately gains 1 Energy")
	assert_eq(int(wolf.get("energy_max", -1)), 2, "snapshot shows max")
	
	h.server.take_events(sessions[0])
	
	# Each round the player defends; the wolf gains 1 Energy per own turn and uses
	# Rend once it can pay for it. Turn order depends on SPD, so allow a few rounds.
	var rend_used = false
	for _round in 4:
		h.advance(h.content.get_float("rules.action_window_seconds", 15.0) + 0.1)
		h.advance(2.0)
		for e in h.server.take_events(sessions[0]):
			if e.get("type") == "action_resolved" and str(e.get("actor", "")).begins_with("e") and e.get("action") == "special":
				rend_used = true
		if rend_used:
			break
	assert_true(rend_used, "used special")
