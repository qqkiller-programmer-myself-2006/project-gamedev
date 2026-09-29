extends TestCase
## Regression coverage for issue #65: Race/Boon effects and combat ordering.


func _character(class_id: String, race: String = "", boons: Array = [], level: int = 1,
		gear: Dictionary = {}) -> Dictionary:
	return {"class": class_id, "race": race, "boons": boons.duplicate(), "level": level,
			"invested": {}, "gear": gear.duplicate()}


func _run(race: String = "Human", boons: Array = [], extra: Dictionary = {},
		profile: Dictionary = {}) -> MatchRun:
	var content := ForestContent.load_default().with_overrides(ForestContent._merged({
		"rules": {"damage_variance": 0},
		"story": {"combat_clues": {"chance": 0}},
	}, extra))
	var loadouts := [{"loadout": {"class": "swordsman", "race": race,
			"boons": boons.duplicate()}, "profile": ProfileStore.normalize(profile)}]
	return MatchRun.new(GameRng.new(91), ManualClock.new(), content,
			[true, false, false, false, false], 1, loadouts)


func _combat(run: MatchRun) -> CombatEncounter:
	var combat := CombatEncounter.new({}, ["grey_wolf"])
	combat.start(run)
	return combat


func test_attribute_bonuses_apply_before_stats_are_derived() -> void:
	var content := ForestContent.load_default()
	var base_human := _character("swordsman")
	var human := _character("swordsman", "Human")
	Attributes.recalculate(base_human, content)
	Attributes.recalculate(human, content)
	assert_eq(human["attributes"]["str"], base_human["attributes"]["str"] + 1)
	assert_eq(human["max_hp"], base_human["max_hp"] + 4)
	assert_eq(human["atk"], base_human["atk"] + 1)

	var base_elf := _character("archer")
	var elf := _character("archer", "Elf")
	Attributes.recalculate(base_elf, content)
	Attributes.recalculate(elf, content)
	assert_eq(elf["attributes"]["dex"], base_elf["attributes"]["dex"] + 2)
	assert_eq(elf["atk"], base_elf["atk"] + 2)
	assert_eq(elf["spd"], base_elf["spd"] + 1)

	var chosen := _character("swordsman", "", ["The Chosen One"])
	Attributes.recalculate(chosen, content)
	assert_eq(chosen["max_hp"], base_human["max_hp"] + 8)
	assert_eq(chosen["atk"], base_human["atk"] + 2)
	assert_eq(chosen["spd"], base_human["spd"] + 1)


func test_static_race_passives_are_applied() -> void:
	var content := ForestContent.load_default()
	var plain := _character("swordsman")
	var kobold := _character("swordsman", "Kobold")
	var withered := _character("swordsman", "Withered")
	var dwarf := _character("swordsman", "Dwarf")
	var lunaeia := _character("mage", "Lunaeia")
	var plain_mage := _character("mage")
	for character in [plain, kobold, withered, dwarf, lunaeia, plain_mage]:
		Attributes.recalculate(character, content)
	assert_true(is_equal_approx(kobold["derived"]["dodge"],
			plain["derived"]["dodge"] + 0.05), "Small Target adds 5% Dodge")
	assert_true(is_equal_approx(withered["derived"]["lifesteal"], 0.05),
			"Undying adds 5% Lifesteal")
	assert_eq(withered["max_hp"], int(plain["max_hp"] * 0.9), "Frail reduces max HP")
	assert_eq(dwarf["max_hp"], int(plain["max_hp"] * 1.1), "Dwarven Resilience adds max HP")
	assert_true(is_equal_approx(dwarf["derived"]["status_resist"], 0.1),
			"Dwarven Resilience adds Status resistance")
	assert_eq(lunaeia["mag"], int(plain_mage["mag"] * 1.1), "Moonlit adds magic damage")


func test_human_adaptable_adds_a_point_on_even_levels() -> void:
	var run := _run("Human")
	run.grant_exp(0, int(run.content.get_array("leveling.exp_to_next")[0]))
	assert_eq(run.party[0]["level"], 2)
	assert_eq(run.party[0]["points"], 3, "2 normal points plus 1 Adaptable point")


func test_kobold_scrappy_adds_ten_percent_to_its_reward_share() -> void:
	var run := _run("Kobold")
	for character in run.party:
		character["gold"] = 0
	run.gold = 0
	run.add_gold(50, true)
	assert_eq(run.party[0]["gold"], 11)
	assert_eq(run.party[1]["gold"], 10)
	assert_eq(run.gold, 51)


func test_dwarf_masterwork_scales_crafted_gear_stats_by_level() -> void:
	var content := ForestContent.load_default()
	var without_gear := _character("swordsman", "Dwarf", [], 10)
	var with_gear := _character("swordsman", "Dwarf", [], 10, {"charm1": "tusk_charm"})
	Attributes.recalculate(without_gear, content)
	Attributes.recalculate(with_gear, content)
	assert_true(is_equal_approx(float(with_gear["atk"] - without_gear["atk"]), 2.15),
			"2 ATK crafted charm gains 7.5% at level 10")


func test_lunaeia_tidal_adds_starting_energy_in_every_combat() -> void:
	var run := _run("Lunaeia")
	_combat(run)
	assert_eq(run.party[0]["energy"], 2)


func test_initiative_orders_units_before_speed_and_speed_breaks_ties() -> void:
	var run := _run("Human", ["Potential: Bunny"], {
		"enemies": {"grey_wolf": {"stats": {"spd": 12}}},
	})
	var combat := _combat(run)
	assert_true(combat.order.find("p0") < combat.order.find("e0"),
			"p0 speed 10 plus 3 Initiative acts before speed 12 enemy")
	run.party[0]["derived"]["initiative"] = 12
	assert_false(combat._before(run, "p0", "e0"),
			"equal Initiative falls back to the enemy's higher Speed")


func test_dodge_blocks_profile_statuses_and_weapon_coating() -> void:
	var run := _run()
	var combat := _combat(run)
	run.party[0]["derived"]["dodge"] = 1.0
	var results := combat._apply_profile(run, "e0", {
		"target": "enemy", "damage": {"amount": 10},
		"apply_status": [{"status": "bleed", "stacks": 1}],
	}, ["p0"])
	assert_true(results[0].get("dodged", false))
	assert_eq(combat.status_book.view("p0"), [], "a missed attack applies no profile status")

	combat.enemies[0]["derived"] = {"dodge": 1.0, "block": 0.0}
	combat.status_book.apply("p0", "venom_coat", 1, 0)
	results = combat._apply_profile(run, "p0", {"target": "enemy",
			"damage": {"amount": 10}}, ["e0"])
	combat._apply_coating(run, "p0", results)
	assert_eq(combat.status_book.view("e0"), [], "a missed coated attack applies no Poison")
	assert_eq(combat.status_book.view("p0")[0]["charges"], 3, "a miss spends no coating charge")


func test_alert_defenses_last_for_only_the_first_two_own_turns() -> void:
	var run := _run("Human", ["Alert"])
	var combat := _combat(run)
	var target: Dictionary = run.party[0]
	target["derived"]["dodge"] = 0.95
	combat._turns_started["p0"] = 2
	var hit := combat._hit(run, "e0", target, {"amount": 10})
	assert_true(hit.get("dodged", false), "Alert raises first-two-turn Dodge to 100%")

	target["derived"]["dodge"] = -0.05
	target["derived"]["block"] = 0.95
	hit = combat._hit(run, "e0", target, {"amount": 10})
	assert_true(hit.get("blocked", false), "Alert raises first-two-turn Block to 100%")

	combat._turns_started["p0"] = 3
	target["derived"]["dodge"] = 0.0
	target["derived"]["block"] = 0.0
	hit = combat._hit(run, "e0", target, {"amount": 10})
	assert_false(hit.get("dodged", false), "Dodge bonus expires on turn 3")
	assert_false(hit.get("blocked", false), "Block bonus expires on turn 3")


func test_critical_healing_heals_twenty_percent_of_crit_damage() -> void:
	var run := _run("Human", ["Critical Healing"])
	var combat := _combat(run)
	var attacker: Dictionary = run.party[0]
	combat.enemies[0]["derived"] = {"dodge": 0.0, "block": 0.0}
	combat.enemies[0]["hp"] = 500
	attacker["hp"] = attacker["max_hp"] - 30
	var before := int(attacker["hp"])
	var hit := combat._hit(run, "p0", combat.enemies[0], {"stat": "atk", "power": 1.0, "always_crit": true})
	assert_true(hit["crit"], "forced crit")
	var expected := mini(30, maxi(1, int(round(int(hit["damage"]) * 0.2))))
	assert_eq(int(attacker["hp"]) - before, expected, "crit heals 20% of damage dealt")
	assert_eq(int(hit.get("crit_heal", 0)), expected)
	# No heal without a crit, and healing actions are not boosted.
	attacker["crit"] = 0.0
	before = int(attacker["hp"])
	combat._hit(run, "p0", combat.enemies[0], {"stat": "atk", "power": 1.0})
	assert_eq(int(attacker["hp"]), before, "no crit, no heal")


func test_daredevil_impulse_increases_damage_at_thirty_percent_hp() -> void:
	var run := _run("Human", ["Daredevil Impulse"])
	var combat := _combat(run)
	var attacker: Dictionary = run.party[0]
	attacker["crit"] = 0.0
	combat.enemies[0]["derived"] = {"dodge": 0.0, "block": 0.0}
	combat.enemies[0]["hp"] = 500
	attacker["hp"] = attacker["max_hp"]
	var normal := combat._hit(run, "p0", combat.enemies[0], {"stat": "atk", "power": 1.0})
	combat.enemies[0]["hp"] = 500
	attacker["hp"] = int(attacker["max_hp"] * 0.3)
	var boosted := combat._hit(run, "p0", combat.enemies[0], {"stat": "atk", "power": 1.0})
	assert_true(int(boosted["damage"]) > int(normal["damage"]))


func test_energy_conserver_can_add_one_extra_energy() -> void:
	var run := _run("Human", ["Energy Conserver"])
	var combat := _combat(run)
	run.party[0]["energy"] = 1
	combat._had_turn["p0"] = true
	# A probability of 1 keeps this test deterministic while exercising the
	# same Energy Conserver branch used by the seeded production RNG.
	run.content = run.content.with_overrides({"rules": {"energy_regen": 1}})
	run.party[0]["derived"]["energy_regen"] = 1
	var old_chance := run.rng
	run.rng = _AlwaysChanceRng.new()
	combat._begin_turn(run, "p0")
	run.rng = old_chance
	assert_eq(run.party[0]["energy"], 3, "normal regen plus the Boon's extra Energy")


func test_will_of_thiacdemo_prevents_only_the_first_defeat() -> void:
	var run := _run("Human", ["Will of Thiacdemo"])
	var combat := _combat(run)
	var target: Dictionary = run.party[0]
	target["derived"]["dodge"] = 0.0
	target["derived"]["block"] = 0.0
	var first := combat._hit(run, "e0", target, {"amount": 999})
	assert_eq(target["hp"], 1)
	assert_true(first.get("survived", false))
	var second := combat._hit(run, "e0", target, {"amount": 999})
	assert_eq(target["hp"], 0)
	assert_true(second.get("down", false))


class _AlwaysChanceRng extends GameRng:
	func chance(_probability: float) -> bool:
		return true
