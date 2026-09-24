extends TestCase
## Rogue: Stab, Prep Time, Poke Up, Inject Venom and Enervation
## (issue #24, ADR-0010). Match interface only.

## Only the human becomes a Rogue; the AI stays Classless and hits for 1.
const LONE_ROGUE := {
	"rules": {"ai_class_cap": 0},
	"classes": {"classless": {"stats": {"atk": 0, "crit": 0}}, "rogue": {"stats": {"crit": 0}}},
}
const DARTS := {
	"party": {"starting_inventory": {"bleed_dart": 3, "poison_dart": 3}},
	"items": {
		"bleed_dart": {"name": "Bleed Dart", "price": 1, "use": {"target": "enemy",
				"damage": {"amount": 1}, "apply_status": [{"status": "bleed", "stacks": 1}]}},
		"poison_dart": {"name": "Poison Dart", "price": 1, "use": {"target": "enemy",
				"damage": {"amount": 1}, "apply_status": [{"status": "poison", "stacks": 1}]}},
	},
}

var h: MatchHarness
var sessions: Array[int] = []
var seen: Array = []


## A lone human Rogue (ATK 11, crit 0) against two slow, harmless wolves
## with DEF 2 and 500 HP.
func _start(extra: Dictionary = {}, party: Dictionary = LONE_ROGUE) -> void:
	var group := {"encounters": {"combat": {"groups": [{"id": "test",
			"enemies": ["grey_wolf", "grey_wolf"], "layers": [1, 5]}]}}}
	var wolves := {"enemies": {"grey_wolf": {"stats": {"max_hp": 500, "atk": 0, "def": 2, "spd": 5, "crit": 0},
			"rewards": {"drops": []}}}}
	h = MatchHarness.new(5, MatchHarness.merge([MatchHarness.class_and_combat("rogue"),
			MatchHarness.EXACT_DAMAGE, party, group, wolves, DARTS, extra]))
	sessions = h.start_with_humans(1)
	h.gain_class(sessions)
	h.take_route(sessions, "combat")
	seen = []
	_collect()


func _encounter() -> Dictionary:
	var encounter = h.match_view(sessions[0]).get("encounter")
	return encounter if encounter != null else {}


func _collect() -> void:
	seen.append_array(h.server.take_events(sessions[0]))


func _until_my_turn(limit: float = 30.0) -> void:
	h.advance(0.1, 0.1)
	_collect()
	var waited := 0.0
	while not _encounter().get("your_turn", false) and waited < limit:
		h.advance(0.1, 0.1)
		_collect()
		waited += 0.1


func _act(cmd: Dictionary) -> Dictionary:
	var full := {"type": "action"}
	full.merge(cmd)
	var result := h.server.command(sessions[0], full)
	_collect()
	return result


## The most recent action_resolved by p0.
func _mine() -> Dictionary:
	for i in range(seen.size() - 1, -1, -1):
		if seen[i]["type"] == "action_resolved" and seen[i]["actor"] == "p0":
			return seen[i]
	return {}


func _statuses(unit: String) -> Array:
	return _encounter().get("statuses", {}).get(unit, [])


func _status(unit: String, status: String) -> Dictionary:
	for entry in _statuses(unit):
		if entry["status"] == status:
			return entry
	return {}


func test_rogue_is_a_tier_1_class_with_four_skills_and_enervation() -> void:
	h = MatchHarness.new(1)
	assert_eq(h.content.get_value("classes.rogue.skills"), ["stab", "prep_time", "poke_up", "inject_venom"])
	var costs := []
	for skill in ["stab", "prep_time", "poke_up", "inject_venom"]:
		costs.append([h.content.get_int("skills.%s.energy" % skill), h.content.get_int("skills.%s.cooldown" % skill)])
	assert_eq(costs, [[1, 4], [1, 6], [2, 3], [2, 6]], "Energy/cooldown from the AAC reference")
	var passive := h.content.get_dict("classes.rogue.passive")
	assert_eq([passive["name"], passive["dot_bonus"], passive["dot_bonus_cap"], passive["dot_out"], passive["dot_in"]],
			["Enervation", 0.05, 1.4, 1.15, 1.15])


func test_taking_the_rogue_class_unlocks_its_skills() -> void:
	_start()
	assert_eq(h.match_view(sessions[0])["party"][0]["class"], "rogue")
	assert_eq(_encounter()["choices"]["skills"].keys(), ["stab", "prep_time", "poke_up", "inject_venom"])


func test_stab_pierces_half_the_defense_and_causes_bleed() -> void:
	_start()
	assert_ok(_act({"action": "skill", "skill": "stab", "target": "e0"}))
	var hit: Dictionary = _mine()["results"][0]
	assert_eq(hit["damage"], 14, "11 x 1.3 - 2 DEF x 0.5 x half = 13.8")
	assert_eq(hit["applied"], [{"status": "bleed", "stacks": 1, "turns": 3}])


func test_prep_time_coats_the_next_three_damaging_actions_with_poison() -> void:
	_start()
	assert_ok(_act({"action": "skill", "skill": "prep_time", "target": "p0"}))
	var coat := _status("p0", "venom_coat")
	assert_eq([coat["name"], coat["kind"], coat["charges"]], ["Prep Time", "buff", 3])
	for i in 3:
		_until_my_turn()
		assert_ok(_act({"action": "attack", "target": "e0"}))
		assert_eq(_mine()["results"][0]["applied"][0]["status"], "poison", "coated hit %d" % (i + 1))
	assert_eq(_status("e0", "poison")["stacks"], 3)
	assert_eq(_status("p0", "venom_coat"), {}, "the coating is used up")
	var gone := seen.filter(func(e): return e["type"] == "status_expired" and e["target"] == "p0")
	assert_eq(gone.size(), 1)


func test_poke_up_stabs_three_times_and_bleeds_on_every_stab() -> void:
	_start()
	_act({"action": "defend"})
	_until_my_turn()
	assert_ok(_act({"action": "skill", "skill": "poke_up", "target": "e0"}))
	var hit: Dictionary = _mine()["results"][0]
	assert_eq(hit["hits"], [5, 5, 5], "11 x 0.55 - 1 = 5.05 each (Enervation +5% after the first)")
	assert_eq(hit["damage"], 15)
	assert_eq(_status("e0", "bleed")["stacks"], 3)


func test_rogue_dots_are_fifteen_percent_stronger() -> void:
	_start()
	_act({"action": "defend"})
	_until_my_turn()
	_act({"action": "skill", "skill": "poke_up", "target": "e0"})
	_until_my_turn()
	var tick: Array = seen.filter(func(e): return e["type"] == "status_tick" and e["target"] == "e0")
	assert_eq(tick[0]["damage"], 10, "3 stacks x 3 x 1.15 = 10.35 instead of 9")


func test_enervation_adds_five_percent_per_dot_kind_on_the_target() -> void:
	_start()
	_act({"action": "item", "item": "bleed_dart", "target": "e0"})
	_until_my_turn()
	_act({"action": "item", "item": "poison_dart", "target": "e0"})
	_until_my_turn()
	_act({"action": "attack", "target": "e1"})
	assert_eq(_mine()["results"][0]["damage"], 10, "clean target: 11 - 1")
	_until_my_turn()
	_act({"action": "attack", "target": "e0"})
	assert_eq(_mine()["results"][0]["damage"], 11, "two DoT kinds: 10 x 1.10")


func test_enervation_is_capped() -> void:
	_start({"classes": {"rogue": {"passive": {"dot_bonus": 0.5}}}})
	_act({"action": "item", "item": "bleed_dart", "target": "e0"})
	_until_my_turn()
	_act({"action": "item", "item": "poison_dart", "target": "e0"})
	_until_my_turn()
	_act({"action": "attack", "target": "e0"})
	assert_eq(_mine()["results"][0]["damage"], 14, "x2.0 capped at x1.4")


func test_inject_venom_grows_with_each_dot_kind_then_adds_toxin() -> void:
	_start()
	_act({"action": "defend"})
	_until_my_turn()
	assert_ok(_act({"action": "skill", "skill": "inject_venom", "target": "e1"}))
	var clean: Dictionary = _mine()["results"][0]
	assert_eq(clean["damage"], 10, "no DoT: 11 x 1.0 - 1")
	assert_eq(clean["applied"], [{"status": "toxin", "stacks": 2, "turns": 2}])
	_start()
	_act({"action": "item", "item": "bleed_dart", "target": "e0"})
	_until_my_turn()
	_act({"action": "item", "item": "poison_dart", "target": "e0"})
	_until_my_turn()
	assert_ok(_act({"action": "skill", "skill": "inject_venom", "target": "e0"}))
	assert_eq(_mine()["results"][0]["damage"], 21, "(11 x 1.8 - 1) x Enervation 1.10 = 20.7")


func test_rogue_takes_more_damage_from_dots() -> void:
	_start({"enemies": {"grey_wolf": {"stats": {"spd": 20}, "behavior": "charge_strongest",
			"attack": {"target": "enemy", "damage": {"amount": 1}, "apply_status": [{"status": "poison", "stacks": 1}]}}},
		"statuses": {"poison": {"damage": 10}},
		"classes": {"rogue": {"stats": {"max_hp": 500}}}})
	_act({"action": "defend"})
	_until_my_turn()
	var ticks: Array = seen.filter(func(e): return e["type"] == "status_tick" and e["target"] == "p0")
	assert_false(ticks.is_empty(), "p0 was poisoned")
	assert_eq(ticks[0]["damage"], 23, "both wolves charge the strongest (p0): 2 stacks x 10 x 1.15")


func test_rogue_ai_coats_first_stacks_one_target_then_injects_venom() -> void:
	_start({}, {"rules": {"ai_class_cap": 5}, "classes": {"rogue": {"stats": {"crit": 0}}}})
	var waited := 0.0
	while waited < 40.0:
		if _encounter().get("your_turn", false):
			_act({"action": "defend"})
		h.advance(0.1, 0.1)
		_collect()
		waited += 0.1
	var kinds := {}
	var p1 := []
	var injected_on := []
	for event in seen:
		match str(event["type"]):
			"status_applied":
				if event.get("kind") == "dot":
					var on: Dictionary = kinds.get(event["target"], {})
					on[event["status"]] = true
					kinds[event["target"]] = on
			"status_expired":
				kinds.get(event["target"], {}).erase(event["status"])
			"action_resolved":
				if event["actor"] == "p1":
					p1.append(event.get("skill", event["action"]))
					if event.get("skill") == "inject_venom":
						injected_on.append(kinds.get(event["results"][0]["target"], {}).size())
	assert_eq(p1[0], "prep_time", "coats the weapon first")
	assert_false(injected_on.is_empty(), "uses Inject Venom within the fight")
	for count in injected_on:
		assert_true(count >= 2, "only injects a target already carrying 2+ DoT kinds")


func test_bandit_hideout_offers_the_rogue_class() -> void:
	var offered := ""
	for seed_value in 60:
		var harness := MatchHarness.new(seed_value)
		var sessions_here := harness.start_with_humans(1)
		for option in harness.match_view(sessions_here[0])["vote"]["options"]:
			if option["name"] == "Bandit Hideout":
				harness.server.command(sessions_here[0], {"type": "vote", "option": option["index"]})
				harness.advance(harness.content.get_float("rules.travel_seconds") + 0.1, 0.1)
				offered = str(harness.match_view(sessions_here[0])["encounter"]["class"])
				break
		if not offered.is_empty():
			break
	assert_eq(offered, "rogue", "some seed offers the Bandit Hideout in Layer 1, and it teaches Rogue")
