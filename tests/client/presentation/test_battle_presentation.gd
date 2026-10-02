extends TestCase


func test_state_keeps_all_party_and_enemy_units_including_fallen() -> void:
	var party: Array[Dictionary] = []
	for slot in 5:
		party.append({"slot": slot, "name": "Hero %d" % slot, "class": "mage", "hp": 10 if slot != 2 else 0,
				"max_hp": 20, "energy": slot})
	var view := {
		"party": party,
		"encounter": {
			"actor": "e1",
			"enemies": [
				{"id": "e0", "kind": "wolf", "hp": 0, "max_hp": 12},
				{"id": "e1", "kind": "bear", "name": "Old Bear", "hp": 20, "max_hp": 30, "energy": 2},
			],
		},
	}

	var state := BattlePresentation.state(view)

	assert_eq(state["units"].size(), 7)
	assert_eq(state["current_actor"], "e1")
	assert_eq(state["units"][0], {"id": "p0", "side": "party", "slot": 0, "class_key": "mage", "name": "Hero 0",
			"hp": 10, "max_hp": 20, "energy": 0, "alive": true})
	assert_eq(state["units"][2]["alive"], false)
	assert_eq(state["units"][5]["alive"], false)
	assert_eq(state["units"][6]["class_key"], "bear")
	assert_eq(state["units"][6]["name"], "Old Bear")
	assert_eq(state["units"][6]["energy"], 2)
	assert_false(state["units"][6]["boss"])
	assert_false(state["units"][6].has("row"))


func test_state_marks_bosses_and_preserves_optional_enemy_rows() -> void:
	var state := BattlePresentation.state({
		"party": [],
		"encounter": {"kind": "boss", "enemies": [
			{"id": "e0", "kind": "guardian", "hp": 40, "max_hp": 40, "row": "back"},
		]},
	})
	assert_eq(state["units"][0]["boss"], true)
	assert_eq(state["units"][0]["row"], "back")


func test_state_uses_optional_menu_mode_to_resolve_targets() -> void:
	var view := {
		"party": [],
		"mode": "skill:fireball",
		"encounter": {"choices": {"skills": {"fireball": {"targets": ["e0", "e1"]}}}},
	}

	var state := BattlePresentation.state(view)

	assert_eq(state["mode"], "skill:fireball")
	assert_eq(state["targets"], ["e0", "e1"])
	assert_eq(BattlePresentation.state({"party": []})["targets"], [])


func test_cues_cover_actions_damage_death_and_healing() -> void:
	var events := [
		{"action": "attack", "expected": "strike"},
		{"action": "skill", "skill": "fireball", "expected": "skill"},
		{"action": "special", "move": "claw", "expected": "skill"},
		{"action": "focus", "expected": "focus"},
		{"action": "item", "item": "potion", "expected": "item"},
		{"action": "defend", "expected": "guard"},
	]
	for action_case in events:
		var event: Dictionary = action_case
		event["type"] = "action_resolved"
		event["actor"] = "p0"
		var cues := BattlePresentation.cues(event)
		assert_eq(cues.size(), 1)
		assert_eq(cues[0]["type"], action_case["expected"])
		assert_has(cues[0], "skill_id")
		assert_has(cues[0], "amount")
		assert_has(cues[0], "crit")

	var result_cues := BattlePresentation.cues({
		"type": "action_resolved", "action": "attack", "actor": "p0",
		"results": [
			{"target": "e0", "damage": 7, "crit": true},
			{"target": "e1", "damage": 12, "down": true},
			{"target": "p1", "heal": 5},
			{"target": "p2", "revived": true},
		],
	})
	assert_eq(result_cues.map(func(cue: Dictionary) -> String: return str(cue["type"])),
		["strike", "hurt", "die", "heal", "heal"])
	assert_eq(result_cues[1]["amount"], 7)
	assert_eq(result_cues[1]["crit"], true)
	assert_eq(result_cues[2]["target"], "e1")
	assert_eq(result_cues[3]["amount"], 5)


func test_unknown_and_malformed_events_return_no_cues() -> void:
	assert_eq(BattlePresentation.cues({"type": "status_tick"}), [])
	assert_eq(BattlePresentation.cues({"type": "action_resolved", "action": "charge"}), [])
	assert_eq(BattlePresentation.cues({"type": "action_resolved", "action": "attack", "results": "bad"}).size(), 1)


func test_3d_launch_option_is_opt_in() -> void:
	assert_false(LaunchOptions.use_3d({}))
	assert_true(LaunchOptions.use_3d({"3d": true}))
	assert_false(LaunchOptions.use_3d({"3d": false}))
