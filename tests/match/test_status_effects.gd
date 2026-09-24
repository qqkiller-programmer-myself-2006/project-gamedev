extends TestCase
## Status effects and DoTs: Bleed, Poison, Toxin (issue #23, ADR-0010).
## No Class applies DoT yet, so test-only darts (Items) and enemy attacks
## from content overrides apply them. Match interface only.

## Classless hits for 1 so AI-controlled allies barely scratch the wolves.
const SOFT_PARTY := {"classes": {"classless": {"stats": {"atk": 0, "crit": 0}}}}
const DARTS := {
	"party": {"starting_inventory": {"bleed_dart": 5, "poison_dart": 5, "toxin_dart": 5,
			"deep_cut": 3, "bleed_rain": 3}},
	"items": {
		"bleed_dart": {"name": "Bleed Dart", "price": 1, "use": {"target": "enemy",
				"damage": {"amount": 1}, "apply_status": [{"status": "bleed", "stacks": 1}]}},
		"poison_dart": {"name": "Poison Dart", "price": 1, "use": {"target": "enemy",
				"damage": {"amount": 1}, "apply_status": [{"status": "poison", "stacks": 1}]}},
		"toxin_dart": {"name": "Toxin Dart", "price": 1, "use": {"target": "enemy",
				"damage": {"amount": 1}, "apply_status": [{"status": "toxin", "stacks": 1}]}},
		"deep_cut": {"name": "Deep Cut", "price": 1, "use": {"target": "enemy",
				"damage": {"amount": 1}, "apply_status": [{"status": "bleed", "stacks": 9}]}},
		"bleed_rain": {"name": "Bleed Rain", "price": 1, "use": {"target": "all_enemies",
				"damage": {"amount": 1}, "apply_status": [{"status": "bleed", "stacks": 2}]}},
	},
}

var h: MatchHarness
var sessions: Array[int] = []
var seen: Array = []


func _start(wolf: Dictionary = {}, extra: Dictionary = {}) -> void:
	var stats := {"max_hp": 500, "atk": 0, "def": 0, "spd": 5, "crit": 0}
	stats.merge(wolf, true)
	h = MatchHarness.new(7, MatchHarness.merge([MatchHarness.ALL_COMBAT, MatchHarness.WOLF_PAIR,
			MatchHarness.EXACT_DAMAGE, SOFT_PARTY, DARTS,
			{"enemies": {"grey_wolf": {"stats": stats, "rewards": {"drops": []}}}}, extra]))
	sessions = h.start_with_humans(1)
	h.enter_first_encounter(sessions)
	seen = []


func _encounter() -> Dictionary:
	var encounter = h.match_view(sessions[0]).get("encounter")
	return encounter if encounter != null else {}


func _collect() -> void:
	seen.append_array(h.server.take_events(sessions[0]))


## Advances until it is the human's turn again (or the fight is over).
func _until_my_turn(limit: float = 30.0) -> void:
	h.advance(0.1, 0.1)
	_collect()
	var waited := 0.0
	while not _encounter().get("your_turn", false) and waited < limit:
		if not str(_encounter().get("result", "")).is_empty():
			return
		h.advance(0.1, 0.1)
		_collect()
		waited += 0.1


func _use(item: String, target: String = "e0") -> void:
	_collect()
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "item", "item": item, "target": target}))
	_collect()


func _defend() -> void:
	h.server.command(sessions[0], {"type": "action", "action": "defend"})


func _of(type: String, target: String = "") -> Array:
	var out := []
	for event in seen:
		if event["type"] == type and (target.is_empty() or str(event.get("target", "")) == target):
			out.append(event)
	return out


func _index_of(predicate: Callable) -> int:
	for i in seen.size():
		if predicate.call(seen[i]):
			return i
	return -1


func _statuses(unit: String) -> Array:
	return _encounter().get("statuses", {}).get(unit, [])


func test_statuses_are_defined_in_content() -> void:
	h = MatchHarness.new(1)
	assert_eq([h.content.get_int("statuses.bleed.damage"), h.content.get_int("statuses.bleed.turns"),
			h.content.get_int("statuses.bleed.max_stacks")], [3, 3, 5])
	assert_eq([h.content.get_int("statuses.poison.damage"), h.content.get_int("statuses.poison.turns")], [2, 4])
	assert_eq([h.content.get_int("statuses.toxin.damage"), h.content.get_int("statuses.toxin.turns")], [5, 2])


func test_every_status_carries_its_badge_colour_and_tick_interval() -> void:
	h = MatchHarness.new(1)
	var colours := {}
	for status in ["bleed", "poison", "toxin", "venom_coat"]:
		var colour := str(h.content.get_value("statuses.%s.color" % status, ""))
		assert_true(Color.html_is_valid(colour), "%s has a colour" % status)
		colours[colour] = true
		assert_eq(h.content.get_int("statuses.%s.tick_every" % status), 1)
	assert_eq(colours.size(), 4, "each kind has its own colour")


func test_tick_colour_is_sent_with_every_tick() -> void:
	_start()
	_use("poison_dart")
	assert_eq(_statuses("e0")[0]["color"], h.content.get_value("statuses.poison.color"))
	_until_my_turn()
	assert_eq(_of("status_tick", "e0")[0]["color"], h.content.get_value("statuses.poison.color"))


func test_a_slow_dot_ticks_only_every_nth_turn() -> void:
	_start({}, {"statuses": {"bleed": {"tick_every": 2, "turns": 6}}})
	_use("bleed_dart")
	_until_my_turn()
	assert_eq(_of("status_tick", "e0").size(), 0, "first turn: no tick yet")
	_defend()
	_until_my_turn()
	assert_eq(_of("status_tick", "e0").size(), 1, "second turn: it ticks")
	assert_eq(_statuses("e0")[0]["tick_every"], 2)


func test_new_dot_kinds_are_data_only() -> void:
	_start({}, {"statuses": {"burn": {"name": "Burn", "kind": "dot", "damage": 4, "turns": 2, "max_stacks": 2,
			"tick_every": 1, "color": "#ff8a2a"}},
			"items": {"burn_dart": {"name": "Burn Dart", "use": {"target": "enemy", "damage": {"amount": 1},
			"apply_status": [{"status": "burn", "stacks": 1}]}}},
			"party": {"starting_inventory": {"burn_dart": 1}}})
	_use("burn_dart")
	_until_my_turn()
	var ticks := _of("status_tick", "e0")
	assert_eq([ticks[0]["name"], ticks[0]["damage"], ticks[0]["color"]], ["Burn", 4, "#ff8a2a"])


func test_unknown_status_names_are_ignored() -> void:
	_start({}, {"items": {"odd_dart": {"name": "Odd Dart", "use": {"target": "enemy", "damage": {"amount": 1},
			"apply_status": [{"status": "no_such_status", "stacks": 1}]}}},
			"party": {"starting_inventory": {"odd_dart": 1}}})
	_use("odd_dart")
	assert_eq(_statuses("e0"), [], "nothing is put on the target")
	assert_eq(_of("status_applied").size(), 0)


func test_applying_a_dot_is_announced_and_shown_on_the_target() -> void:
	_start()
	_use("bleed_dart")
	var applied := _of("status_applied", "e0")
	assert_eq(applied.size(), 1)
	assert_eq([applied[0]["status"], applied[0]["stacks"], applied[0]["turns"], applied[0]["source"]],
			["bleed", 1, 3, "p0"])
	var shown: Array = _statuses("e0")
	assert_eq([shown[0]["status"], shown[0]["name"], shown[0]["stacks"], shown[0]["turns"]], ["bleed", "Bleed", 1, 3])
	var enemy: Dictionary = _encounter()["enemies"][0]
	assert_eq(enemy["statuses"].size(), 1, "enemy views carry their statuses too")


func test_dot_ticks_at_the_start_of_the_afflicted_units_turn_before_it_acts() -> void:
	_start()
	_use("bleed_dart")
	_until_my_turn()
	var ticks := _of("status_tick", "e0")
	assert_eq(ticks.size(), 1)
	assert_eq([ticks[0]["status"], ticks[0]["damage"], ticks[0]["down"]], ["bleed", 3, false])
	var tick_at := _index_of(func(e): return e["type"] == "status_tick" and e["target"] == "e0")
	var acts_at := _index_of(func(e): return e["type"] == "action_resolved" and e["actor"] == "e0")
	assert_true(tick_at < acts_at, "ticks before the wolf acts")
	assert_eq(_statuses("e0")[0]["turns"], 2, "one turn used up")


func test_reapplying_adds_stacks_and_keeps_the_longer_duration() -> void:
	_start()
	_use("bleed_dart")
	_until_my_turn()
	_use("bleed_dart")
	var second: Dictionary = _of("status_applied", "e0")[1]
	assert_eq([second["stacks"], second["turns"]], [2, 3], "2 stacks, duration back to 3")
	_until_my_turn()
	assert_eq(_of("status_tick", "e0")[1]["damage"], 6, "3 per stack x 2")


func test_stacks_never_pass_max_stacks() -> void:
	_start()
	_use("deep_cut")
	assert_eq(_statuses("e0")[0]["stacks"], 5)
	_until_my_turn()
	assert_eq(_of("status_tick", "e0")[0]["damage"], 15)


func test_different_dots_coexist_and_all_tick() -> void:
	_start()
	_use("bleed_dart")
	_until_my_turn()
	_use("poison_dart")
	var kinds := []
	for status in _statuses("e0"):
		kinds.append(status["status"])
	assert_eq(kinds, ["bleed", "poison"])
	seen.clear()
	_until_my_turn()
	var ticks := []
	for tick in _of("status_tick", "e0"):
		ticks.append([tick["status"], tick["damage"]])
	assert_eq(ticks, [["bleed", 3], ["poison", 2]])


func test_a_dot_expires_when_its_turns_run_out() -> void:
	_start()
	_use("toxin_dart")
	_until_my_turn()
	_defend()
	_until_my_turn()
	assert_eq(_of("status_tick", "e0").size(), 2, "Toxin lasts 2 turns")
	assert_eq(_of("status_expired", "e0").size(), 1)
	assert_eq(_statuses("e0"), [])


func test_dots_can_finish_enemies_and_win_the_combat() -> void:
	_start({"max_hp": 7})
	_use("bleed_rain")
	_until_my_turn()
	var downs := []
	for tick in _of("status_tick"):
		if tick["down"]:
			downs.append(tick["target"])
	assert_eq(downs, ["e0", "e1"])
	assert_eq(_of("action_resolved").filter(func(e): return str(e["actor"]).begins_with("e")), [],
			"a unit felled by its DoT never acts")
	var ended := _of("combat_ended")
	assert_eq(ended[0]["result"], "victory")
	assert_true(int(ended[0]["rewards"]["exp"]) > 0, "normal rewards")
	assert_eq(_encounter()["statuses"], {}, "everything is cleared when the Combat ends")


func test_dots_can_fell_a_character_who_then_loses_the_turn() -> void:
	_start({"spd": 20}, {
		"enemies": {"grey_wolf": {"attack": {"target": "enemy", "damage": {"amount": 1},
				"apply_status": [{"status": "poison", "stacks": 1}]}, "behavior": "hunt_weakest"}},
		"statuses": {"poison": {"damage": 60}},
	})
	_until_my_turn()
	var fell := []
	for tick in _of("status_tick"):
		if tick["down"]:
			fell.append(tick["target"])
	assert_false(fell.is_empty(), "a character dropped to Poison")
	var victim: String = fell[0]
	var tick_at := _index_of(func(e): return e["type"] == "status_tick" and e["target"] == victim)
	var after := seen.slice(tick_at + 1)
	for event in after:
		if event["type"] == "turn_started":
			assert_ne(event["actor"], victim, "the fallen character gets no turn")
			break


func test_dot_ticks_before_energy_regen_and_the_action_window() -> void:
	_start({"spd": 20}, {
		"enemies": {"grey_wolf": {"attack": {"target": "enemy", "damage": {"amount": 1},
				"apply_status": [{"status": "poison", "stacks": 1}]}}},
		"classes": {"classless": {"stats": {"max_hp": 500}}},
	})
	_until_my_turn()
	_defend()
	_until_my_turn()
	var ticks := _of("status_tick", "p0")
	assert_false(ticks.is_empty(), "p0 was poisoned by the fast wolves")
	var tick_at := _index_of(func(e): return e["type"] == "status_tick" and e["target"] == "p0")
	var turn_at := -1
	for i in range(tick_at, seen.size()):
		if seen[i]["type"] == "turn_started" and seen[i]["actor"] == "p0":
			turn_at = i
			break
	assert_true(turn_at > tick_at, "the tick comes before p0's turn starts")
	assert_eq(h.match_view(sessions[0])["party"][0]["energy"], 2, "Energy still regenerates after the tick")


func test_outgoing_and_incoming_dot_modifiers() -> void:
	_start({}, {"classes": {"classless": {"passive": {"dot_out": 2.0}}}})
	_use("bleed_dart")
	_until_my_turn()
	assert_eq(_of("status_tick", "e0")[0]["damage"], 6, "applier doubles its DoTs: 3 x 2")
	_start({"spd": 20}, {
		"enemies": {"grey_wolf": {"behavior": "hunt_weakest", "attack": {"target": "enemy",
				"damage": {"amount": 1}, "apply_status": [{"status": "bleed", "stacks": 1}]}}},
		"classes": {"classless": {"stats": {"max_hp": 500}, "passive": {"dot_in": 1.5}}},
	})
	_until_my_turn()
	var ticks := _of("status_tick", "p0")
	assert_false(ticks.is_empty())
	assert_eq(ticks[0]["damage"], 9, "both wolves bite the tied-weakest p0: 2 stacks x 3 x 1.5")
