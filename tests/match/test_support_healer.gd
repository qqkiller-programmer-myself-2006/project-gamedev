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
