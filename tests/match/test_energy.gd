extends TestCase
## Energy economy for every Class's Skills (issue #22, ADR-0009).
## Only the Match interface is used: commands, clock advances and
## event/snapshot inspection.

## Weak, slow wolves that never end the fight early.
const WEAK_WOLVES := {"enemies": {
	"grey_wolf": {"stats": {"max_hp": 500, "atk": 0, "spd": 5, "crit": 0}, "rewards": {"drops": []}},
}}
const WHOLE_PARTY := {"rules": {"ai_class_cap": 5}}

var h: MatchHarness
var sessions: Array[int] = []


## Starts a Match where the whole Party takes `class_id`, then begins a
## Combat against two weak wolves.
func _start(class_id: String) -> void:
	var group := {"encounters": {"combat": {"groups": [{"id": "test",
			"enemies": ["grey_wolf", "grey_wolf"], "layers": [1, 5]}]}}}
	h = MatchHarness.new(5, MatchHarness.merge([MatchHarness.class_and_combat(class_id),
			MatchHarness.EXACT_DAMAGE, WEAK_WOLVES, WHOLE_PARTY, group,
			{"classes": {"swordsman": {"stats": {"crit": 0}}, "mage": {"stats": {"crit": 0}}}}]))
	sessions = h.start_with_humans(1)
	h.gain_class(sessions)
	h.take_route(sessions, "combat")


## Starts a classless Match straight into a Combat against weak wolves.
func _start_classless() -> void:
	h = MatchHarness.new(7, MatchHarness.merge([MatchHarness.ALL_COMBAT, MatchHarness.WOLF_PAIR,
			MatchHarness.EXACT_DAMAGE, WEAK_WOLVES]))
	sessions = h.start_with_humans(1)
	h.enter_first_encounter(sessions)


func _encounter() -> Dictionary:
	var encounter = h.match_view(sessions[0]).get("encounter")
	return encounter if encounter != null else {}


func _energy(session: int, slot: int) -> Array:
	var character: Dictionary = h.match_view(session)["party"][slot]
	return [int(character["energy"]), int(character["energy_max"])]


func _until_my_turn(limit: float = 60.0) -> void:
	h.advance(0.1, 0.1)
	var waited := 0.0
	while not _encounter().get("your_turn", false) and waited < limit:
		h.advance(0.1, 0.1)
		waited += 0.1


func _defend() -> void:
	h.server.command(sessions[0], {"type": "action", "action": "defend"})


func test_energy_rules_and_skill_costs_live_in_content() -> void:
	h = MatchHarness.new(5)
	assert_eq([h.content.get_int("rules.energy_start"), h.content.get_int("rules.energy_regen"),
			h.content.get_int("rules.energy_max")], [1, 1, 6])
	for skill in ["power_slash", "aimed_shot", "fireball", "frost_lance", "protect", "shield_wall"]:
		var cost := h.content.get_int("skills.%s.energy" % skill, -1)
		assert_between(cost, 1, 2, "%s costs 1-2 Energy" % skill)
		var text := str(h.content.get_value("skills.%s.description" % skill, ""))
		assert_true(text.find("Energy") >= 0, "%s mentions Energy" % skill)
		assert_true(text.find("ooldown") >= 0, "%s mentions cooldown" % skill)


func test_energy_starts_at_one_for_every_party_character() -> void:
	_start("swordsman")
	for slot in 5:
		assert_eq(_energy(sessions[0], slot), [1, 6], "p%d starts at 1/6" % slot)


func test_both_players_see_every_characters_energy() -> void:
	var group := {"encounters": {"combat": {"groups": [{"id": "test",
			"enemies": ["grey_wolf", "grey_wolf"], "layers": [1, 5]}]}}}
	h = MatchHarness.new(5, MatchHarness.merge([MatchHarness.class_and_combat("swordsman"),
			MatchHarness.EXACT_DAMAGE, WEAK_WOLVES, WHOLE_PARTY, group,
			{"classes": {"swordsman": {"stats": {"crit": 0}}}}]))
	sessions = h.start_with_humans(2)
	h.gain_class(sessions)
	h.take_route(sessions, "combat")
	for slot in 5:
		assert_eq(_energy(sessions[0], slot), _energy(sessions[1], slot), "p%d matches" % slot)
		assert_eq(_energy(sessions[1], slot), [1, 6])


func test_challenge_starts_at_energy_start() -> void:
	h = MatchHarness.new(5, MatchHarness.merge([MatchHarness.class_and_combat("swordsman"),
			MatchHarness.EXACT_DAMAGE]))
	sessions = h.start_with_humans(1)
	h.take_route(sessions, "class")
	for slot in 5:
		assert_eq(_energy(sessions[0], slot), [1, 6], "trial starts at 1/6")


func test_choices_expose_cost_and_mark_unaffordable_skills() -> void:
	_start("swordsman")
	var skills: Dictionary = _encounter()["choices"]["skills"]
	assert_eq(skills["power_slash"]["energy"], 2)
	assert_eq(skills["power_slash"]["affordable"], false)
	assert_eq(skills["power_slash"]["targets"], [])


func test_two_energy_skill_rejected_without_state_change() -> void:
	_start("swordsman")
	var before := h.match_view(sessions[0])
	var before_hp: Dictionary = {"party": [], "enemies": []}
	for character in before["party"]:
		before_hp["party"].append(character["hp"])
	for enemy in before["encounter"]["enemies"]:
		before_hp["enemies"].append(enemy["hp"])
	assert_rejected(h.server.command(sessions[0], {"type": "action", "action": "skill",
			"skill": "power_slash", "target": "e0"}), "not_enough_energy")
	var after := h.match_view(sessions[0])
	for slot in 5:
		assert_eq(_energy(sessions[0], slot), [1, 6], "no Energy spent")
		assert_eq(after["party"][slot]["hp"], before_hp["party"][slot])
	for i in after["encounter"]["enemies"].size():
		assert_eq(after["encounter"]["enemies"][i]["hp"], before_hp["enemies"][i])
	assert_eq(after["encounter"]["choices"]["skills"]["power_slash"]["cooldown"], 0)


func test_attack_defend_and_item_cost_no_energy() -> void:
	_start("swordsman")
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "attack", "target": "e0"}))
	assert_eq(_energy(sessions[0], 0), [1, 6])
	_until_my_turn()
	_defend()
	_until_my_turn()
	assert_eq(_energy(sessions[0], 0), [3, 6], "two regens, no spending")


func test_skill_use_deducts_and_event_reports_energy_spent() -> void:
	_start("mage")
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "skill",
			"skill": "frost_lance", "target": "e0"}))
	assert_eq(_energy(sessions[0], 0), [0, 6])
	var spent := -1
	for event in h.server.take_events(sessions[0]):
		if event["type"] == "action_resolved" and event.get("skill") == "frost_lance":
			spent = int(event["energy_spent"])
	assert_eq(spent, 1)
	_until_my_turn()
	assert_eq(_energy(sessions[0], 0), [1, 6])
	assert_rejected(h.server.command(sessions[0], {"type": "action", "action": "skill",
			"skill": "fireball"}), "not_enough_energy", "fireball costs 2")
	_defend()
	_until_my_turn()
	assert_eq(_energy(sessions[0], 0), [2, 6])
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "skill",
			"skill": "fireball"}))
	assert_eq(_energy(sessions[0], 0), [0, 6])


func test_energy_regenerates_each_own_turn_and_caps_at_six() -> void:
	_start_classless()
	var seen := []
	for turn in 8:
		if turn > 0:
			_until_my_turn()
		seen.append(_energy(sessions[0], 0)[0])
		_defend()
	assert_eq(seen, [1, 2, 3, 4, 5, 6, 6, 6])


func test_timed_out_turn_still_regenerates() -> void:
	_start_classless()
	assert_eq(_energy(sessions[0], 0), [1, 6])
	h.server.take_events(sessions[0])
	h.advance(16.0, 0.1)
	var auto := false
	for event in h.server.take_events(sessions[0]):
		if event["type"] == "action_resolved" and event["actor"] == "p0" \
				and event["action"] == "defend" and bool(event.get("automatic", false)):
			auto = true
	assert_true(auto, "p0 timed out into an automatic Defend")
	_until_my_turn()
	assert_eq(_energy(sessions[0], 0), [2, 6])


func test_energy_and_cooldown_gate_together() -> void:
	_start("swordsman")
	_defend()
	_until_my_turn()
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "skill",
			"skill": "power_slash", "target": "e0"}))
	_until_my_turn()
	assert_rejected(h.server.command(sessions[0], {"type": "action", "action": "skill",
			"skill": "power_slash", "target": "e0"}), "not_enough_energy")
	_defend()
	_until_my_turn()
	assert_rejected(h.server.command(sessions[0], {"type": "action", "action": "skill",
			"skill": "power_slash", "target": "e0"}), "skill_on_cooldown")
	_defend()
	_until_my_turn()
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "skill",
			"skill": "power_slash", "target": "e0"}), "ready again with Energy saved")


func test_energy_resets_between_combats() -> void:
	var frail := {"enemies": {
		"grey_wolf": {"stats": {"max_hp": 1, "atk": 0, "spd": 5, "crit": 0}, "rewards": {"drops": []}},
	}}
	var pair := {"encounters": {"combat": {"groups": [{"id": "test",
			"enemies": ["grey_wolf", "grey_wolf"], "layers": [1, 5]}]}}}
	h = MatchHarness.new(5, MatchHarness.merge([MatchHarness.class_and_combat("mage"),
			MatchHarness.EXACT_DAMAGE, frail, WHOLE_PARTY, pair,
			{"classes": {"mage": {"stats": {"crit": 0}}}}]))
	sessions = h.start_with_humans(1)
	h.gain_class(sessions)
	h.take_route(sessions, "combat")
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "skill",
			"skill": "frost_lance", "target": "e0"}))
	assert_eq(_energy(sessions[0], 0), [0, 6])
	var waited := 0.0
	while h.match_view(sessions[0])["phase"] != "voting" and waited < 60.0:
		var encounter = h.match_view(sessions[0]).get("encounter")
		if encounter != null and encounter.get("your_turn", false):
			var living := ""
			for enemy in encounter["enemies"]:
				if enemy["hp"] > 0:
					living = enemy["id"]
			if living.is_empty():
				h.advance(0.1, 0.1)
			else:
				h.server.command(sessions[0], {"type": "action", "action": "attack", "target": living})
		else:
			h.advance(0.1, 0.1)
		waited += 0.1
	h.take_route(sessions, "combat")
	for slot in 5:
		assert_eq(_energy(sessions[0], slot), [1, 6], "next Combat resets")


func test_enemies_have_no_energy() -> void:
	_start("swordsman")
	for enemy in _encounter()["enemies"]:
		assert_false(enemy.has("energy"), "%s has no Energy" % enemy["id"])


func test_ai_never_uses_unaffordable_skills() -> void:
	_start("swordsman")
	var slashes := []
	var waited := 0.0
	h.server.take_events(sessions[0])
	while waited < 30.0:
		if _encounter().get("your_turn", false):
			_defend()
		h.advance(0.1, 0.1)
		waited += 0.1
		for event in h.server.take_events(sessions[0]):
			if event["type"] == "action_resolved" and event.get("skill") == "power_slash" \
					and str(event["actor"]) != "p0":
				slashes.append(event)
	assert_false(slashes.is_empty(), "AI still uses Power Slash once it can afford it")
	for slash in slashes:
		assert_true(int(slash["round"]) >= 2, "round 1 Energy cannot afford it")
		assert_eq(slash["energy_spent"], 2)
