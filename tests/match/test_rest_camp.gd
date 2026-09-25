extends TestCase
## Rest camp: Ready check, crafting, gear and stat points (issues #36, #37,
## ADR-0011). Match interface only.

const BAG := {"party": {"starting_inventory": {"herb": 3, "wolf_pelt": 4, "boar_tusk": 2}}}
## One quick wolf fight is enough for a level-up (and one stat point).
const QUICK_LEVEL := {
	"leveling": {"exp_to_next": [5, 500, 500, 500, 500, 500]},
	"enemies": {"grey_wolf": {"stats": {"max_hp": 1, "spd": 1}, "rewards": {"exp": 10, "drops": []}}},
}

var h: MatchHarness
var sessions: Array[int] = []


func _camp(humans: int = 1, extra: Dictionary = {}) -> void:
	h = MatchHarness.new(3, MatchHarness.merge([MatchHarness.only_routes(["rest", "combat"]),
			MatchHarness.EXACT_DAMAGE, MatchHarness.WOLF_PAIR, BAG, extra]))
	sessions = h.start_with_humans(humans)
	h.take_route(sessions, "rest")


func _view(session: int = -1) -> Dictionary:
	return h.match_view(sessions[0] if session == -1 else session)


func _encounter(session: int = -1) -> Dictionary:
	var encounter = _view(session).get("encounter")
	return encounter if encounter != null else {}


func _count(item: String) -> int:
	for entry in _view()["inventory"]:
		if entry["item"] == item:
			return entry["count"]
	return 0


func _recipe(id: String) -> Dictionary:
	for recipe in _encounter()["recipes"]:
		if recipe["recipe"] == id:
			return recipe
	return {}


func _cmd(cmd: Dictionary, session: int = -1) -> Dictionary:
	return h.server.command(sessions[0] if session == -1 else session, cmd)


# --- Ready check ----------------------------------------------------------------

func test_camp_waits_for_every_human_to_be_ready() -> void:
	_camp(2)
	var camp := _encounter()
	assert_eq(camp["kind"], "rest")
	assert_eq(camp["humans"], 2, "Ready (x/2): two humans")
	assert_eq(camp["ready"], [])
	h.advance(10.0)
	assert_eq(_view()["layer"], 1, "the camp does not close on its own before the timer")
	assert_ok(_cmd({"type": "ready"}))
	assert_eq(_encounter(sessions[1])["ready"], [0], "everyone sees the count go up")
	assert_rejected(_cmd({"type": "ready"}), "already_ready")
	assert_eq(_view()["layer"], 1, "one of two is not enough")
	assert_ok(_cmd({"type": "ready"}, sessions[1]))
	assert_eq(_view()["layer"], 2, "all humans Ready: the journey moves on")


func test_camp_closes_when_its_timer_runs_out() -> void:
	_camp(1)
	h.advance(h.content.get_float("encounters.rest.seconds") + 0.5)
	assert_eq(_view()["layer"], 2, "an idle player cannot stall the Match")


func test_a_dropped_player_counts_as_ready() -> void:
	_camp(2)
	assert_ok(_cmd({"type": "ready"}))
	h.server.close_session(sessions[1])
	assert_eq(_view()["layer"], 2, "the AI that took over needs no Ready")


# --- Crafting --------------------------------------------------------------------

func test_recipes_show_a_live_material_checklist() -> void:
	_camp()
	var boots := _recipe("pelt_boots")
	assert_eq(boots["category"], "Boots")
	assert_eq(boots["materials"], [{"item": "wolf_pelt", "name": "Wolf Pelt", "need": 2, "have": 4}])
	assert_true(boots["craftable"])
	assert_false(_recipe("wisp_charm")["craftable"], "no Wisp Dust in the bag")
	assert_has(_encounter()["categories"], "Quivers")


func test_crafting_turns_materials_into_an_item() -> void:
	_camp()
	assert_ok(_cmd({"type": "craft", "recipe": "tusk_charm"}))
	assert_eq(_count("boar_tusk"), 0, "two tusks used")
	assert_eq(_count("tusk_charm"), 1)
	assert_false(_recipe("tusk_charm")["craftable"], "the checklist updates")
	assert_has(h.event_types(sessions[0]), "crafted")


func test_crafting_without_materials_is_rejected_and_changes_nothing() -> void:
	_camp()
	var before: Array = _view()["inventory"]
	assert_rejected(_cmd({"type": "craft", "recipe": "wisp_charm"}), "missing_materials")
	assert_rejected(_cmd({"type": "craft", "recipe": "golden_crown"}), "invalid_recipe")
	assert_eq(_view()["inventory"], before)


func test_camp_commands_only_work_in_a_camp() -> void:
	_camp()
	assert_ok(_cmd({"type": "ready"}))
	assert_rejected(_cmd({"type": "craft", "recipe": "pelt_boots"}), "wrong_phase", "voting now")


# --- Gear --------------------------------------------------------------------------

func test_gear_changes_stats_and_goes_back_to_the_bag() -> void:
	_camp()
	var before: Dictionary = _view()["party"][0]
	assert_ok(_cmd({"type": "craft", "recipe": "hide_jerkin"}))
	assert_ok(_cmd({"type": "equip", "item": "hide_jerkin"}))
	var me: Dictionary = _view()["party"][0]
	assert_eq(me["gear"]["chest"]["item"], "hide_jerkin")
	assert_eq(me["def"], before["def"] + 2, "+2 DEF")
	assert_eq(me["max_hp"], before["max_hp"] + 8, "+8 max HP")
	assert_eq(_count("hide_jerkin"), 0, "taken out of the shared bag")
	assert_ok(_cmd({"type": "unequip", "gear_slot": "chest"}))
	me = _view()["party"][0]
	assert_eq(me["def"], before["def"])
	assert_eq(me["max_hp"], before["max_hp"])
	assert_eq(_count("hide_jerkin"), 1, "back in the bag")


func test_three_charm_slots() -> void:
	_camp(1, {"party": {"starting_inventory": {"tusk_charm": 3, "pelt_boots": 1}}})
	var atk: int = _view()["party"][0]["atk"]
	for i in 3:
		assert_ok(_cmd({"type": "equip", "item": "tusk_charm"}))
	var gear: Dictionary = _view()["party"][0]["gear"]
	assert_eq(gear.keys().size(), 3)
	for gear_slot in ["charm1", "charm2", "charm3"]:
		assert_true(gear.has(gear_slot), gear_slot)
	assert_eq(_view()["party"][0]["atk"], atk + 6, "three charms stack")
	assert_eq(_encounter()["gear_slots"].size(), 8, "Helmet, Chest, Legs, Boots, Weapon, Charm x3")
	assert_rejected(_cmd({"type": "equip", "item": "pelt_boots", "gear_slot": "helmet"}), "wrong_gear_slot")
	assert_rejected(_cmd({"type": "equip", "item": "herb"}), "not_gear")
	assert_rejected(_cmd({"type": "equip", "item": "wisp_robe"}), "item_unavailable")
	assert_rejected(_cmd({"type": "unequip", "gear_slot": "legs"}), "nothing_equipped")


func test_gear_cannot_be_used_as_a_combat_item() -> void:
	h = MatchHarness.new(3, MatchHarness.merge([MatchHarness.ALL_COMBAT, MatchHarness.WOLF_PAIR,
			MatchHarness.EXACT_DAMAGE, {"party": {"starting_inventory": {"wolf_pelt": 1}},
			"classes": {"classless": {"stats": {"spd": 99}}}}]))
	sessions = h.start_with_humans(1)
	h.enter_first_encounter(sessions)
	var combat := _encounter()
	assert_true(combat["your_turn"])
	assert_false(combat["choices"]["items"].has("wolf_pelt"), "materials are not offered in battle")
	assert_rejected(_cmd({"type": "action", "action": "item", "item": "wolf_pelt", "target": "e0"}), "item_unusable")


# --- Stat points -----------------------------------------------------------------

func _level_up_then_camp(humans: int = 1) -> void:
	h = MatchHarness.new(3, MatchHarness.merge([MatchHarness.only_routes(["rest", "combat"]),
			MatchHarness.EXACT_DAMAGE, MatchHarness.WOLF_PAIR, BAG, QUICK_LEVEL]))
	sessions = h.start_with_humans(humans)
	h.take_route(sessions, "combat")
	var waited := 0.0
	while _view()["layer"] == 1 and waited < 60.0:
		var encounter := _encounter()
		if encounter.get("your_turn", false):
			var target: String = encounter["choices"]["attack"]["targets"][0]
			_cmd({"type": "action", "action": "attack", "target": target})
		h.advance(0.5, 0.5)
		waited += 0.5
	h.take_route(sessions, "rest")


func test_level_ups_give_points_to_invest() -> void:
	_level_up_then_camp()
	var me: Dictionary = _view()["party"][0]
	assert_eq(me["level"], 2)
	assert_eq(me["points"], 1, "one point per level")
	assert_eq(_encounter()["invest"]["atk"], 1, "the camp says what a point buys")
	assert_ok(_cmd({"type": "invest", "stat": "atk"}))
	var after: Dictionary = _view()["party"][0]
	assert_eq(after["atk"], me["atk"] + 1)
	assert_eq(after["points"], 0)
	assert_eq(after["invested"], {"atk": 1})
	assert_rejected(_cmd({"type": "invest", "stat": "atk"}), "no_points")


func test_invalid_stat_is_rejected() -> void:
	_level_up_then_camp()
	assert_rejected(_cmd({"type": "invest", "stat": "luck"}), "invalid_stat")
	assert_eq(_view()["party"][0]["points"], 1)


func test_ai_characters_spend_points_and_take_spare_gear_when_camp_closes() -> void:
	_level_up_then_camp()
	assert_ok(_cmd({"type": "craft", "recipe": "pelt_boots"}))
	var ai: Dictionary = _view()["party"][1]
	assert_eq(ai["controller"], "ai")
	assert_eq(ai["points"], 1)
	assert_ok(_cmd({"type": "ready"}))
	ai = _view()["party"][1]
	assert_eq(ai["points"], 0, "Classless AI spent its point")
	assert_eq(ai["invested"], {"max_hp": 1}, "on its Class's focus stat")
	assert_eq(ai["gear"]["boots"]["item"], "pelt_boots", "and put on the spare boots")
	assert_eq(_count("pelt_boots"), 0)
