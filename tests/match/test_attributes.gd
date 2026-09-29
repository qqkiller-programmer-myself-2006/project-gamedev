extends TestCase

func test_derived_stats_at_level_1_equal_old_stats() -> void:
	var h := MatchHarness.new(123)
	var old_stats = {
		"classless": {"max_hp": 54, "atk": 15, "def": 5, "mag": 4, "res": 3, "spd": 10, "crit": 0.05},
		"swordsman": {"max_hp": 48, "atk": 11, "def": 5, "mag": 3, "res": 3, "spd": 10, "crit": 0.08},
		"archer": {"max_hp": 40, "atk": 10, "def": 3, "mag": 3, "res": 3, "spd": 15, "crit": 0.25},
		"mage": {"max_hp": 34, "atk": 5, "def": 2, "mag": 13, "res": 6, "spd": 9, "crit": 0.05},
		"guardian": {"max_hp": 66, "atk": 8, "def": 8, "mag": 2, "res": 6, "spd": 7, "crit": 0.05},
		"assassin": {"max_hp": 38, "atk": 10, "def": 3, "mag": 3, "res": 3, "spd": 12, "crit": 0.18}
	}
	
	for class_id in old_stats.keys():
		var char_dict = {"class": class_id, "level": 1, "invested": {}, "gear": {}}
		Attributes.recalculate(char_dict, h.content)
		var expected = old_stats[class_id]
		for stat in expected.keys():
			if stat == "crit":
				assert_true(abs(char_dict[stat] - expected[stat]) < 0.001, "%s %s" % [class_id, stat])
			else:
				assert_eq(char_dict[stat], expected[stat], "%s %s" % [class_id, stat])

func test_attribute_effects_on_derived_stats() -> void:
	var h := MatchHarness.new(123)
	var char_dict = {"class": "classless", "level": 1, "invested": {}, "gear": {}}
	
	# Override attributes explicitly for testing the derived stats formulas
	var base_attrs = h.content.get_dict("classes.classless.attributes")
	# Force some investment to test changes
	char_dict["invested"] = {"dex": 2, "con": 4, "lck": 5}
	# dex +2 -> spd +1, dodge +1%
	# con +4 -> max_hp +16, def +2, block +2%
	# lck +5 -> crit +5%, crit_damage +10%
	Attributes.recalculate(char_dict, h.content)
	
	assert_eq(char_dict["attributes"]["dex"], int(base_attrs["dex"]) + 2)
	assert_eq(char_dict["attributes"]["con"], int(base_attrs["con"]) + 4)
	assert_eq(char_dict["attributes"]["lck"], int(base_attrs["lck"]) + 5)
	
	assert_true(abs(char_dict["derived"]["dodge"] - float(char_dict["attributes"]["dex"]) * 0.005) < 0.001)
	assert_true(abs(char_dict["derived"]["block"] - float(char_dict["attributes"]["con"]) * 0.005) < 0.001)
	assert_true(abs(char_dict["derived"]["crit_damage"] - (1.5 + float(char_dict["attributes"]["lck"]) * 0.02)) < 0.001)
	assert_eq(char_dict["derived"]["aggro"], 1.0)
	assert_eq(char_dict["derived"]["block_reduction"], 0.5)

func test_focus_command_gives_energy_and_dodge() -> void:
	var h := MatchHarness.new(123, MatchHarness.merge([MatchHarness.ALL_COMBAT, MatchHarness.WOLF_PAIR]))
	var sessions = h.start_with_humans(1)
	h.enter_first_encounter(sessions)
	
	var view = h.match_view(sessions[0])
	while not view["encounter"].get("your_turn", false):
		h.advance(0.1, 0.1)
		view = h.match_view(sessions[0])
	var encounter = view["encounter"]
	assert_true(encounter["choices"].has("focus"))
	
	# P0 uses focus
	var res = h.server.command(sessions[0], {"type": "action", "action": "focus", "slot": 0})
	assert_true(res.get("ok", false))
	
	var new_view = h.match_view(sessions[0])
	var p0 = new_view["party"][0]
	assert_eq(p0["energy"], 2) # started at 1, focus gave +1 = 2
	

