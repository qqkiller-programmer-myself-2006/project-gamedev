extends TestCase
## Support and Healer combat effects (T4S-01a).

func _run(class_id: String) -> MatchRun:
	var content := ForestContent.load_default().with_overrides({
		"rules": {"damage_variance": 0},
		"story": {"combat_clues": {"chance": 0}},
		"classes": {class_id: {"base": {"crit": -0.2}}},
		"enemies": {"grey_wolf": {"stats": {"max_hp": 500, "atk": 10, "def": 0, "spd": 5, "crit": 0}}},
	})
	var loadouts := [{"loadout": {"class": class_id, "race": "Human", "boons": []},
			"profile": ProfileStore.normalize({})}]
	return MatchRun.new(GameRng.new(812), ManualClock.new(), content,
			[true, false, false, false, false], 1, loadouts)


func _combat(run: MatchRun) -> CombatEncounter:
	var combat := CombatEncounter.new({}, ["grey_wolf", "grey_wolf"])
	combat.start(run)
	return combat


func test_support_and_healer_are_complete_tier_one_classes() -> void:
	var content := ForestContent.load_default()
	var classes := content.get_dict("classes")
	assert_eq(classes.size(), 8, "seven Tier 1 classes plus Classless")
	for class_id in ["support", "healer"]:
		assert_eq(content.get_array("classes.%s.skills" % class_id).size(), 3)
		assert_true(not content.get_dict("classes.%s.attack" % class_id).is_empty(), "Strike profile exists")
	assert_eq(content.get_value("classes.support.invest_focus"), "cha")
	assert_eq(content.get_value("classes.healer.invest_focus"), "fth")
	assert_eq(content.get_value("classes.support.icon"), "shield")
	assert_eq(content.get_value("classes.healer.icon"), "regen")


func test_both_new_classes_can_be_selected_in_a_multiplayer_loadout() -> void:
	for class_id in ["support", "healer"]:
		var h := MatchHarness.new(21)
		var session := h.create_room()
		assert_ok(h.server.command(session, {"type": "set_loadout", "class": class_id,
				"race": "Human", "boons": []}))
		assert_ok(h.server.command(session, {"type": "start_match"}))
		assert_eq(h.match_view(session)["party"][0]["class"], class_id)


func test_healer_single_target_and_party_heals_apply_and_cap_at_max_hp() -> void:
	var run := _run("healer")
	var combat := _combat(run)
	run.party[0]["hp"] = 10
	run.party[1]["hp"] = 10
	var single := combat._apply_profile(run, "p0", combat.skill_profile(run, "mending_light"), ["p1"])
	assert_eq(single[0]["heal"], 23, "Faith Attribute scales healing")
	assert_eq(run.party[1]["hp"], 33)
	run.party[0]["hp"] = 10
	var all_targets: Array = combat.valid_targets(run, "p0", combat.skill_profile(run, "renewing_wave"))
	var group := combat._apply_profile(run, "p0", combat.skill_profile(run, "renewing_wave"), all_targets)
	assert_eq(group.size(), 5)
	assert_eq(run.party[0]["hp"], 24)
	assert_eq(run.party[1]["hp"], 47)


func test_cleanse_removes_negative_statuses_but_keeps_buffs() -> void:
	var run := _run("healer")
	var combat := _combat(run)
	combat.status_book.apply("p1", "bleed", 2, 3)
	combat.status_book.apply("p1", "rally", 1, 3)
	var results := combat._apply_profile(run, "p0", combat.skill_profile(run, "cleanse"), ["p1"])
	assert_eq(results[0]["cleansed"], ["bleed"])
	assert_eq(combat.status_book.view("p1").map(func(status): return status["status"]), ["rally"])
	assert_eq(combat._status_events[0]["type"], "status_expired")


func test_grant_energy_stops_at_party_cap() -> void:
	var run := _run("support")
	var combat := _combat(run)
	run.party[1]["energy"] = 5
	var profile := combat.skill_profile(run, "energize")
	var results := combat._apply_profile(run, "p0", profile, ["p1"])
	assert_eq(results[0]["energy_granted"], 1)
	assert_eq(run.party[1]["energy"], 6)
	assert_eq(run.party[1]["energy_max"], 6)


func test_timed_rally_and_weaken_modify_damage_until_they_expire() -> void:
	var run := _run("support")
	var combat := _combat(run)
	var ally: Dictionary = run.party[1]
	ally["crit"] = 0.0
	ally["derived"]["dodge"] = 0.0
	ally["derived"]["block"] = 0.0
	var enemy: Dictionary = combat.enemies[0]
	enemy["derived"] = {"dodge": 0.0, "block": 0.0}
	var base_out: int = combat._hit(run, "p1", enemy, {"amount": 20})["damage"]
	var rally := combat._apply_profile(run, "p0", combat.skill_profile(run, "rally"), ["p1"])
	assert_true(rally[0].has("applied"))
	assert_eq(combat._hit(run, "p1", enemy, {"amount": 20})["damage"], 24)
	for _turn in 3:
		combat.status_book.start_turn("p1")
	assert_eq(combat._hit(run, "p1", enemy, {"amount": 20})["damage"], base_out, "Rally expires after three own turns")
	combat._apply_profile(run, "p0", combat.skill_profile(run, "weaken"), ["e0"])
	var reduced: int = combat._hit(run, "e0", ally, {"amount": 20})["damage"]
	assert_eq(reduced, 14)
	combat.status_book.start_turn("e0")
	combat.status_book.start_turn("e0")
	assert_eq(combat._hit(run, "e0", ally, {"amount": 20})["damage"], 20, "Weaken expires after two own turns")


func test_new_skills_use_energy_and_enter_cooldown() -> void:
	var run := _run("healer")
	var combat := _combat(run)
	run.party[0]["energy"] = 6
	var plan := combat._plan_for(run, 0, {"action": "skill", "skill": "mending_light", "target": "p0"})
	assert_true(plan.has("skill"), "skill is selectable")
	combat._perform(run, plan, false)
	assert_eq(run.party[0]["energy"], 4, "Energy cost is paid")
	assert_rejected(combat._plan_for(run, 0,
			{"action": "skill", "skill": "mending_light", "target": "p0"}), "skill_on_cooldown")
	for skill in ["mending_light", "renewing_wave", "cleanse", "rally", "weaken", "energize"]:
		assert_true(run.content.get_int("skills.%s.energy" % skill) > 0, "%s has an Energy cost" % skill)
		assert_true(run.content.get_int("skills.%s.cooldown" % skill) >= 0, "%s has a cooldown" % skill)


func test_healer_ai_uses_single_and_party_heals_then_cleanses_and_strikes() -> void:
	var run := _run("healer")
	var combat := _combat(run)
	var healer: Dictionary = run.party[0]
	healer["energy"] = 6
	run.party[1]["hp"] = 10
	var plan := PartyAi.decide(run, combat, 0)
	assert_eq([plan["action"], plan["skill"], plan["targets"]], ["skill", "mending_light", ["p1"]])
	run.party[2]["hp"] = 10
	plan = PartyAi.decide(run, combat, 0)
	assert_eq([plan["action"], plan["skill"]], ["skill", "renewing_wave"])
	combat._perform(run, combat._plan_for(run, 0, {"action": "skill", "skill": "renewing_wave", "target": "p1"}), false)
	for ally in run.party:
		ally["hp"] = ally["max_hp"]
	combat.status_book.apply("p1", "bleed", 1, 3)
	plan = PartyAi.decide(run, combat, 0)
	assert_eq([plan["action"], plan["skill"], plan["targets"]], ["skill", "cleanse", ["p1"]])
	combat._perform(run, combat._plan_for(run, 0, {"action": "skill", "skill": "cleanse", "target": "p1"}), false)
	plan = PartyAi.decide(run, combat, 0)
	assert_eq(plan["action"], "attack", "uses a basic Strike when no ally needs help")


func test_support_ai_buffs_grants_energy_debuffs_and_strikes() -> void:
	var run := _run("support")
	var combat := _combat(run)
	var support: Dictionary = run.party[0]
	support["energy"] = 6
	run.party[1]["class"] = "swordsman"
	var plan := PartyAi.decide(run, combat, 0)
	assert_eq([plan["action"], plan["skill"]], ["skill", "rally"])
	assert_true(plan["targets"].has("p1"), "Rally chooses an ally without the buff")
	for slot in range(1, run.party.size()):
		combat.status_book.apply("p%d" % slot, "rally", 1, 3)
	run.party[1]["energy"] = 0
	plan = PartyAi.decide(run, combat, 0)
	assert_eq([plan["action"], plan["skill"], plan["targets"]], ["skill", "energize", ["p1"]])
	run.party[1]["energy"] = 2
	for slot in range(1, run.party.size()):
		run.party[slot]["class"] = "classless"
	plan = PartyAi.decide(run, combat, 0)
	assert_eq([plan["action"], plan["skill"], plan["targets"]], ["skill", "weaken", ["e0"]])
	combat.status_book.apply("e0", "weakened", 1, 2)
	plan = PartyAi.decide(run, combat, 0)
	assert_eq(plan["action"], "attack", "uses a basic Strike when every support effect is active")


func test_support_and_healer_ai_complete_a_match_without_errors() -> void:
	var content := MatchHarness.merge([MatchHarness.EASY, MatchHarness.ALL_COMBAT, MatchHarness.WOLF_PAIR,
		{"party": {"ai_class_order": ["support", "healer", "swordsman", "archer", "assassin"]}}])
	var h := MatchHarness.new(581, content)
	var session := h.create_room()
	assert_ok(h.server.command(session, {"type": "set_loadout", "class": "swordsman", "race": "Human", "boons": []}))
	assert_ok(h.server.command(session, {"type": "start_match"}))
	var bot := MatchBot.new(h, [session])
	bot.choose_route = func(options: Array, _slot: int, _view: Dictionary) -> int:
		for option in options:
			if option["type"] == "combat":
				return option["index"]
		return 0
	var view := bot.play_to_end()
	assert_true(view["phase"] in ["victory", "defeat"])
	var actions := bot.events_of_type("action_resolved")
	assert_true(actions.any(func(event): return event.get("actor") == "p1" and event.get("skill") in ["rally", "weaken", "energize"]),
			"Support AI action missing; party=%s actions=%s" % [view.get("party", []), actions])
	assert_true(view["phase"] == "victory", "all encounters finish; party=%s actions=%s" % [view.get("party", []), actions])
