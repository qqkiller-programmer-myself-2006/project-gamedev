extends TestCase
## Archer and Mage (issue #12, spec stories 47, 48, 50, 52).

const SLOW_TANKY := {"enemies": {
	"grey_wolf": {"stats": {"max_hp": 500, "spd": 5, "crit": 0}, "rewards": {"drops": []}},
	"thornback_boar": {"stats": {"max_hp": 500, "spd": 5, "crit": 0}, "rewards": {"drops": []}},
	"bramble_archer": {"stats": {"max_hp": 500, "spd": 5, "crit": 0}, "rewards": {"drops": []}},
}}
const NO_CLASS_CRITS := {"classes": {"archer": {"stats": {"crit": 0}}, "mage": {"stats": {"crit": 0}}}}
## The whole Party takes the Class so Class mechanics are tested in isolation.
const WHOLE_PARTY := {"rules": {"ai_class_cap": 5}}

var h: MatchHarness
var sessions: Array[int] = []


## Everyone takes `class_id` in Layer 1, then the Layer 2 Combat against
## `enemies` starts.
func _start(class_id: String, enemies: Array = ["grey_wolf", "grey_wolf"], extra: Dictionary = NO_CLASS_CRITS,
		seed_value: int = 5) -> void:
	var group := {"encounters": {"combat": {"groups": [{"id": "test", "enemies": enemies, "layers": [1, 5]}]}}}
	h = MatchHarness.new(seed_value, MatchHarness.merge([MatchHarness.class_and_combat(class_id),
			MatchHarness.EXACT_DAMAGE, SLOW_TANKY, WHOLE_PARTY, group, extra]))
	sessions = h.start_with_humans(1)
	h.gain_class(sessions)
	h.take_route(sessions, "combat")


func _encounter() -> Dictionary:
	var encounter = h.match_view(sessions[0]).get("encounter")
	return encounter if encounter != null else {}


func _act(cmd: Dictionary) -> Dictionary:
	var full := {"type": "action"}
	full.merge(cmd)
	h.server.take_events(sessions[0])
	var result := h.server.command(sessions[0], full)
	return result


func _last_action() -> Dictionary:
	var found := {}
	for event in h.server.take_events(sessions[0]):
		if event["type"] == "action_resolved":
			found = event
	return found


## Actions resolved over `seconds`, the human Defending on their turns.
func _actions(seconds: float) -> Array:
	var found := []
	var waited := 0.0
	h.server.take_events(sessions[0])
	while waited < seconds:
		if _encounter().get("your_turn", false):
			h.server.command(sessions[0], {"type": "action", "action": "defend"})
		h.advance(0.1, 0.1)
		waited += 0.1
		for event in h.server.take_events(sessions[0]):
			if event["type"] == "action_resolved":
				found.append(event)
	return found


func _targets(action: Dictionary) -> Array:
	var out := []
	for entry in action["results"]:
		out.append(entry["target"])
	return out


func _damages(action: Dictionary) -> Array:
	var out := []
	for entry in action["results"]:
		out.append(entry["damage"])
	return out


func test_archer_is_noticeably_faster_than_other_classes() -> void:
	_start("archer")
	var me: Dictionary = h.match_view(sessions[0])["party"][0]
	assert_eq([me["class"], me["spd"]], ["archer", 15])
	var classes := h.content.get_dict("classes")
	for other in classes:
		if other != "archer":
			assert_true(int(classes[other]["stats"]["spd"]) <= 10, "%s is slower" % other)


func test_archer_shoots_into_the_back_row() -> void:
	_start("archer", ["grey_wolf", "bramble_archer"])
	assert_eq(_encounter()["choices"]["attack"]["targets"], ["e0", "e1"])
	assert_ok(_act({"action": "attack", "target": "e1"}))


func test_archer_critical_hits_come_from_the_seed() -> void:
	var patterns := []
	for run in 2:
		_start("archer", ["grey_wolf", "grey_wolf"], {}, 12)
		var crits := []
		for action in _actions(20.0):
			if action["action"] == "attack" and action["actor"] != "p0":
				crits.append(action["results"][0]["crit"])
		patterns.append(crits)
	assert_eq(patterns[0], patterns[1], "same seed, same critical hits")
	assert_has(patterns[0], true)
	assert_has(patterns[0], false)


func test_aimed_shot_always_lands_a_critical_hit() -> void:
	_start("archer")
	assert_ok(_act({"action": "skill", "skill": "aimed_shot", "target": "e0"}))
	var action := _last_action()
	assert_eq(action["results"][0]["crit"], true)
	assert_eq(action["results"][0]["damage"], 22, "(11 x 1.4 - 1) x 1.5")


func test_mage_attack_deals_magic_damage() -> void:
	_start("mage")
	var me: Dictionary = h.match_view(sessions[0])["party"][0]
	assert_eq([me["class"], me["mag"]], ["mage", 14])
	assert_ok(_act({"action": "attack", "target": "e0"}))
	var result: Dictionary = _last_action()["results"][0]
	assert_eq([result["damage"], result["element"]], [14, "arcane"], "14 MAG - 1 RES x 0.5")


func test_fireball_hits_every_enemy_and_burns_the_fire_weak_harder() -> void:
	_start("mage", ["thornback_boar", "grey_wolf", "bramble_archer"])
	assert_ok(_act({"action": "skill", "skill": "fireball"}))
	var action := _last_action()
	assert_eq(_targets(action), ["e0", "e1", "e2"], "front and back row")
	assert_eq(_damages(action), [22, 15, 22], "boar and archer are weak to fire")
	assert_eq(action["results"][0]["weak"], true)
	assert_eq(action["results"][1]["weak"], false)
	assert_eq(action["results"][2]["element"], "fire")


func test_frost_lance_is_a_single_target_elemental_skill_with_short_cooldown() -> void:
	_start("mage")
	assert_ok(_act({"action": "skill", "skill": "frost_lance", "target": "e1"}))
	var result: Dictionary = _last_action()["results"][0]
	assert_eq([result["target"], result["damage"], result["element"]], ["e1", 22, "ice"])
	_until_my_turn()
	assert_rejected(_act({"action": "skill", "skill": "frost_lance", "target": "e1"}), "skill_on_cooldown")
	assert_ok(_act({"action": "skill", "skill": "fireball"}), "other skills have their own cooldown")
	_until_my_turn()
	assert_ok(_act({"action": "skill", "skill": "frost_lance", "target": "e0"}), "ready after one turn")


func test_hunter_camp_may_offer_archer_but_does_not_guarantee_it() -> void:
	var offered := {}
	for seed_value in 40:
		offered[_class_offered_at("hunter_camp", seed_value)] = true
	assert_eq(offered.keys().size(), 2)
	assert_has(offered, "archer")
	assert_has(offered, "swordsman")


func test_ruined_shrine_offers_mage() -> void:
	for seed_value in 5:
		assert_eq(_class_offered_at("ruined_shrine", seed_value), "mage")


func test_archer_ai_picks_off_the_weakest_enemy() -> void:
	_start("archer")
	h.server.command(sessions[0], {"type": "action", "action": "attack", "target": "e1"})
	var round_one := []
	for action in _actions(5.0):
		if action["actor"] in ["p1", "p2", "p3", "p4"] and action["round"] == 1:
			round_one.append(_targets(action)[0])
	assert_eq(round_one, ["e1", "e1", "e1", "e1"], "everyone follows up on the wounded wolf")


func test_mage_ai_uses_fireball_against_a_group() -> void:
	_start("mage")
	var p1 := []
	for action in _actions(5.0):
		if action["actor"] == "p1":
			p1.append(action)
	assert_eq(p1[0]["skill"], "fireball")
	assert_eq(_targets(p1[0]), ["e0", "e1"])


func test_mage_ai_uses_single_target_magic_against_one_enemy() -> void:
	_start("mage", ["grey_wolf"])
	var p1 := []
	for action in _actions(5.0):
		if action["actor"] == "p1":
			p1.append(action)
	assert_eq(p1[0]["skill"], "frost_lance")


func test_offers_explain_archer_and_mage_and_their_skills() -> void:
	for class_id in ["archer", "mage"]:
		h = MatchHarness.new(5, MatchHarness.class_and_combat(class_id))
		sessions = h.start_with_humans(1)
		h.take_route(sessions, "class")
		var info: Dictionary = _encounter()["class_info"]
		assert_false(str(info["description"]).is_empty(), class_id)
		assert_false(str(info["role"]).is_empty(), class_id)
		for skill in info["skills"]:
			assert_false(str(skill["description"]).is_empty(), skill["id"])
			assert_true(skill["cooldown"] > 0, "%s uses the cooldown system" % skill["id"])


func _class_offered_at(site_id: String, seed_value: int) -> String:
	var site := {}
	for candidate in ForestContent.load_default().get_array("journey.sites.class"):
		if candidate["id"] == site_id:
			site = candidate
	var harness := MatchHarness.new(seed_value, {"journey": {
		"type_weights": {"combat": 0, "merchant": 0, "rest": 0, "treasure": 0, "story": 0, "class": 1},
		"guarantees": {"class_by_layer": 0, "merchant_before_boss": false},
		"sites": {"class": [site]},
	}})
	var solo := harness.start_with_humans(1)
	harness.take_route(solo, "class")
	return str(harness.match_view(solo[0])["encounter"]["class"])


func _until_my_turn(limit: float = 30.0) -> void:
	var waited := 0.0
	h.advance(0.1, 0.1)
	while not _encounter().get("your_turn", false) and waited < limit:
		h.advance(0.1, 0.1)
		waited += 0.1
