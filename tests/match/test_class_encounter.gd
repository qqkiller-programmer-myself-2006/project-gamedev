extends TestCase
## Class Encounter, Skill action and the Swordsman (issue #11, spec 42–46,
## 50–52, 56).

const SWORD_SITE := {"id": "old_swordsman", "name": "Old Swordsman's Hut", "hint": "An old man practises.",
		"classes": {"swordsman": 1}}
## Every Layer offers exactly one Class Encounter (Swordsman) and one Combat.
const CLASS_AND_COMBAT := {
	"journey": {
		"options_min": 2,
		"options_max": 2,
		"type_weights": {"combat": 1, "merchant": 0, "rest": 0, "treasure": 0, "story": 0, "class": 1},
		"guarantees": {"class_by_layer": 0, "merchant_before_boss": false},
		"sites": {"class": [SWORD_SITE]},
	},
}
const WEAK_TRAINER := {"enemies": {"old_swordsman": {"stats": {"max_hp": 1}}}}
const WEAK_TRAINER_WHOLE_PARTY := {"enemies": {"old_swordsman": {"stats": {"max_hp": 1}}}, "rules": {"ai_class_cap": 5}}
const SLOW_TANKY_WOLVES := {"enemies": {"grey_wolf": {"stats": {"max_hp": 500, "spd": 5}}}}

var h: MatchHarness
var sessions: Array[int] = []


func _start(humans: int, extra: Dictionary = WEAK_TRAINER, seed_value: int = 6) -> void:
	h = MatchHarness.new(seed_value, MatchHarness.merge([CLASS_AND_COMBAT, MatchHarness.WOLF_PAIR,
			MatchHarness.EXACT_DAMAGE, SLOW_TANKY_WOLVES, extra]))
	sessions = h.start_with_humans(humans)


func _view(session: int = -1) -> Dictionary:
	return h.match_view(sessions[0] if session == -1 else session)


func _encounter(session: int = -1) -> Dictionary:
	var encounter = _view(session).get("encounter")
	return encounter if encounter != null else {}


## Every human votes for the route of `type` in the current Layer.
func _take_route(type: String) -> void:
	var options: Array = _view()["vote"]["options"]
	for option in options:
		if option["type"] == type:
			for session in sessions:
				h.server.command(session, {"type": "vote", "option": option["index"]})
	h.advance(2.6, 0.1)


## Humans attack the trainer until the Challenge is decided.
func _fight_trial(limit: float = 90.0) -> void:
	var waited := 0.0
	while _encounter().get("stage") == "challenge" and waited < limit:
		for session in sessions:
			var trial: Dictionary = _encounter(session).get("trial", {})
			if trial.get("your_turn", false):
				h.server.command(session, {"type": "action", "action": "attack", "target": "e0"})
		h.advance(0.1, 0.1)
		waited += 0.1


func _events(session: int, type: String) -> Array:
	var out := []
	for event in h.server.take_events(session):
		if event["type"] == type:
			out.append(event)
	return out


func _classes() -> Array:
	var out := []
	for character in _view()["party"]:
		out.append(character["class"])
	return out


func test_class_encounter_opens_with_a_challenge_for_its_class() -> void:
	_start(1, {})
	_take_route("class")
	var encounter := _encounter()
	assert_eq(encounter["kind"], "class")
	assert_eq(encounter["stage"], "challenge")
	assert_eq(encounter["class"], "swordsman")
	assert_eq(encounter["class_info"]["name"], "Swordsman")
	assert_eq(encounter["class_info"]["role"], "Melee DPS")
	assert_eq(encounter["class_info"]["skills"][0]["name"], "Power Slash")
	assert_false(str(encounter["class_info"]["skills"][0]["description"]).is_empty())
	assert_eq(encounter["trial"]["enemies"][0]["name"], "Old Swordsman")
	assert_eq(encounter["trial"]["round_limit"], 3)


func test_beating_the_trainer_offers_the_class_to_every_classless_character() -> void:
	_start(1)
	_take_route("class")
	_fight_trial()
	var encounter := _encounter()
	assert_eq(encounter["stage"], "offer")
	assert_eq(encounter["passed"], true)
	assert_eq(encounter["offer"]["eligible"], [0, 1, 2, 3, 4])
	assert_eq(encounter["offer"]["decisions"], {"1": true, "2": true, "3": false, "4": false},
			"AI decides on its own and stops at two of a Class")
	assert_eq(encounter["offer"]["you_can_decide"], true)


func test_failing_the_challenge_offers_nothing() -> void:
	_start(1, {"enemies": {"old_swordsman": {"stats": {"max_hp": 9999}}}})
	_take_route("class")
	h.server.take_events(sessions[0])
	_fight_trial()
	var ended := _events(sessions[0], "class_challenge_ended")
	assert_eq(ended[0]["passed"], false)
	assert_eq(_classes(), ["classless", "classless", "classless", "classless", "classless"])
	assert_eq(_view()["phase"], "voting", "journey moves on to the next Layer")
	assert_eq(_view()["layer"], 2)


func test_trial_never_knocks_anyone_out_and_hp_is_restored() -> void:
	_start(1, {"enemies": {"old_swordsman": {"stats": {"max_hp": 9999, "atk": 999}}}})
	_take_route("class")
	var lowest := 999
	var waited := 0.0
	while _encounter().get("stage") == "challenge" and waited < 90.0:
		for character in _view()["party"]:
			lowest = mini(lowest, character["hp"])
		h.advance(0.1, 0.1)
		waited += 0.1
	assert_eq(lowest, 1, "trainer hits hard but only down to 1 HP")
	for character in _view()["party"]:
		assert_eq(character["hp"], character["max_hp"], "HP back after the trial")


func test_accepting_gives_swordsman_stats_from_content() -> void:
	_start(1)
	_take_route("class")
	_fight_trial()
	assert_ok(h.server.command(sessions[0], {"type": "class_choice", "accept": true}))
	var me: Dictionary = _view()["party"][0]
	assert_eq([me["class"], me["class_name"]], ["swordsman", "Swordsman"])
	assert_eq([me["max_hp"], me["atk"], me["def"], me["spd"]], [52, 12, 5, 10])
	assert_eq(me["hp"], 52, "HP grows with the new max HP")


func test_several_characters_can_take_the_same_class() -> void:
	_start(2)
	_take_route("class")
	_fight_trial()
	h.server.command(sessions[0], {"type": "class_choice", "accept": true})
	h.server.command(sessions[1], {"type": "class_choice", "accept": true})
	assert_eq(_classes(), ["swordsman", "swordsman", "swordsman", "swordsman", "classless"],
			"humans always may; AI stopped once two had it")


func test_ai_left_classless_takes_a_class_at_a_later_encounter_up_to_the_cap() -> void:
	_start(1)
	_take_route("class")
	_fight_trial()
	h.server.command(sessions[0], {"type": "class_choice", "accept": false})
	assert_eq(_classes(), ["classless", "swordsman", "swordsman", "classless", "classless"])
	_take_route("class")
	_fight_trial()
	var offer: Dictionary = _encounter()["offer"]
	assert_eq(offer["eligible"], [0, 3, 4])
	assert_eq(offer["decisions"], {"3": false, "4": false}, "two Swordsmen already")


func test_declining_keeps_classless_and_allows_a_later_class_encounter() -> void:
	_start(2, WEAK_TRAINER_WHOLE_PARTY)
	_take_route("class")
	_fight_trial()
	h.server.command(sessions[0], {"type": "class_choice", "accept": true})
	h.server.command(sessions[1], {"type": "class_choice", "accept": false})
	assert_eq(_classes()[1], "classless")
	assert_eq(_view()["layer"], 2, "offer closes once both humans answered")
	_take_route("class")
	_fight_trial()
	var offer: Dictionary = _encounter(sessions[1])["offer"]
	assert_eq(offer["eligible"], [1], "only the Classless character is offered again")
	assert_rejected(h.server.command(sessions[0], {"type": "class_choice", "accept": true}), "not_eligible")
	assert_ok(h.server.command(sessions[1], {"type": "class_choice", "accept": true}))
	assert_eq(_classes()[1], "swordsman")


func test_unanswered_offer_is_declined_at_the_deadline() -> void:
	_start(1)
	_take_route("class")
	_fight_trial()
	h.server.take_events(sessions[0])
	h.advance(20.1)
	var choices := _events(sessions[0], "class_choice")
	assert_eq(choices.size(), 1)
	assert_eq([choices[0]["slot"], choices[0]["accepted"]], [0, false])
	assert_eq(_classes()[0], "classless")


func test_class_choice_is_rejected_outside_an_offer_or_twice() -> void:
	_start(1)
	assert_rejected(h.server.command(sessions[0], {"type": "class_choice", "accept": true}), "wrong_phase")
	_take_route("class")
	_fight_trial()
	assert_ok(h.server.command(sessions[0], {"type": "class_choice", "accept": false}))
	assert_rejected(h.server.command(sessions[0], {"type": "class_choice", "accept": true}), "wrong_phase",
			"offer already closed")


func test_answering_twice_is_rejected_while_others_decide() -> void:
	_start(2)
	_take_route("class")
	_fight_trial()
	assert_ok(h.server.command(sessions[0], {"type": "class_choice", "accept": false}))
	assert_rejected(h.server.command(sessions[0], {"type": "class_choice", "accept": true}), "already_decided")


func test_passing_with_nobody_classless_grants_mastery_exp() -> void:
	_start(1, WEAK_TRAINER_WHOLE_PARTY)
	_take_route("class")
	_fight_trial()
	h.server.command(sessions[0], {"type": "class_choice", "accept": true})
	_take_route("class")
	_fight_trial()
	for character in _view()["party"]:
		assert_eq([character["level"], character["exp"]], [1, 15])


func test_swordsman_power_slash_hits_hard_then_cools_down() -> void:
	_start(1)
	_take_route("class")
	_fight_trial()
	h.server.command(sessions[0], {"type": "class_choice", "accept": true})
	_take_route("combat")
	var skills: Dictionary = _encounter()["choices"]["skills"]
	assert_eq(skills["power_slash"]["cooldown"], 0)
	h.server.take_events(sessions[0])
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "skill", "skill": "power_slash", "target": "e0"}))
	var hit: Dictionary = _events(sessions[0], "action_resolved")[0]
	assert_eq(hit["skill"], "power_slash")
	assert_eq(hit["results"][0]["damage"], 21, "12 ATK x 1.8 - 2 DEF x 0.5")
	for turn in 2:
		_until_my_turn()
		assert_eq(_encounter()["choices"]["skills"]["power_slash"]["cooldown"], 2 - turn)
		assert_rejected(h.server.command(sessions[0], {"type": "action", "action": "skill",
				"skill": "power_slash", "target": "e0"}), "skill_on_cooldown")
		h.server.command(sessions[0], {"type": "action", "action": "defend"})
	_until_my_turn()
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "skill", "skill": "power_slash", "target": "e0"}),
			"ready again after two turns")


func test_classless_character_still_cannot_use_skills() -> void:
	_start(2)
	_take_route("class")
	_fight_trial()
	h.server.command(sessions[0], {"type": "class_choice", "accept": true})
	h.server.command(sessions[1], {"type": "class_choice", "accept": false})
	_take_route("combat")
	h.server.command(sessions[0], {"type": "action", "action": "defend"})
	assert_eq(_encounter(sessions[1])["choices"]["skills"], {})
	assert_rejected(h.server.command(sessions[1], {"type": "action", "action": "skill", "skill": "power_slash",
			"target": "e0"}), "skill_unavailable")


func test_swordsman_ai_uses_power_slash_when_ready() -> void:
	_start(1)
	_take_route("class")
	_fight_trial()
	h.server.command(sessions[0], {"type": "class_choice", "accept": false})
	_take_route("combat")
	h.server.take_events(sessions[0])
	var p1 := []
	var waited := 0.0
	while p1.size() < 3 and waited < 60.0:
		if _encounter().get("your_turn", false):
			h.server.command(sessions[0], {"type": "action", "action": "defend"})
		h.advance(0.1, 0.1)
		waited += 0.1
		for event in h.server.take_events(sessions[0]):
			if event["type"] == "action_resolved" and event["actor"] == "p1":
				p1.append(event)
	assert_eq(p1[0]["action"], "skill", "opens with Power Slash")
	assert_eq(p1[0]["skill"], "power_slash")
	assert_eq([p1[1]["action"], p1[2]["action"]], ["attack", "attack"], "attacks while it cools down")


func test_class_encounter_reachable_early_on_every_seed() -> void:
	for seed_value in 40:
		var harness := MatchHarness.new(seed_value, MatchHarness.EASY)
		var bot := MatchBot.new(harness, harness.start_with_humans(1))
		bot.choose_route = func(options: Array, _slot: int) -> int:
			for option in options:
				if option["type"] == "class":
					return option["index"]
			return 0
		bot.play_until(func(v: Dictionary) -> bool: return v["layer"] >= 3)
		assert_eq(bot.events_of_type("class_offered").size() >= 1, true, "seed %d offered a Class by Layer 2" % seed_value)


func _until_my_turn(limit: float = 30.0) -> void:
	var waited := 0.0
	h.advance(0.1, 0.1)
	while not _encounter().get("your_turn", false) and waited < limit:
		h.advance(0.1, 0.1)
		waited += 0.1
