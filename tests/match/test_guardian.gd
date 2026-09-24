extends TestCase
## Guardian and Protect Ally (issue #13, spec stories 49, 50, 52).

const WHOLE_PARTY := {"rules": {"ai_class_cap": 5}}

var h: MatchHarness
var sessions: Array[int] = []


## Takes the Guardian Class in Layer 1 (the whole Party unless `cap` says
## otherwise), then starts the Layer 2 Combat against `enemies`.
func _start(enemies: Array, enemy_stats: Dictionary, cap: Dictionary = WHOLE_PARTY) -> void:
	var group := {"encounters": {"combat": {"groups": [{"id": "test", "enemies": enemies, "layers": [1, 5]}]}}}
	var stats := {}
	for kind in enemy_stats:
		stats[kind] = {"stats": enemy_stats[kind], "rewards": {"drops": []}}
	h = MatchHarness.new(5, MatchHarness.merge([MatchHarness.class_and_combat("guardian"),
			MatchHarness.EXACT_DAMAGE, cap, group, {"enemies": stats},
			{"classes": {"guardian": {"stats": {"crit": 0}}}}]))
	sessions = h.start_with_humans(1)
	h.gain_class(sessions)
	h.take_route(sessions, "combat")


func _encounter() -> Dictionary:
	var encounter = h.match_view(sessions[0]).get("encounter")
	return encounter if encounter != null else {}


func _party(slot: int) -> Dictionary:
	return h.match_view(sessions[0])["party"][slot]


## Actions resolved over `seconds`, with the human Defending on their turns.
func _actions(seconds: float) -> Array:
	var found := []
	var waited := 0.0
	while waited < seconds:
		if _encounter().get("your_turn", false):
			h.server.command(sessions[0], {"type": "action", "action": "defend"})
		h.advance(0.1, 0.1)
		waited += 0.1
		for event in h.server.take_events(sessions[0]):
			if event["type"] == "action_resolved":
				found.append(event)
	return found


func _by(actor: String, actions: Array) -> Array:
	var out := []
	for action in actions:
		if action["actor"] == actor:
			out.append(action)
	return out


func test_guardian_has_the_most_hp_and_defense() -> void:
	var classes := ForestContent.load_default().get_dict("classes")
	var guardian: Dictionary = classes["guardian"]["stats"]
	for other in classes:
		if other == "guardian":
			continue
		assert_true(int(guardian["max_hp"]) > int(classes[other]["stats"]["max_hp"]), "HP above %s" % other)
		assert_true(int(guardian["def"]) > int(classes[other]["stats"]["def"]), "DEF above %s" % other)


func test_protect_redirects_damage_to_the_guardian_with_a_reduction() -> void:
	_start(["thornback_boar", "thornback_boar"], {"thornback_boar": {"max_hp": 500, "spd": 5, "atk": 30, "crit": 0}})
	h.server.take_events(sessions[0])
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "skill", "skill": "protect", "target": "p1"}))
	assert_eq(_encounter()["protected"], {"p1": "p0"}, "UI can show who guards whom")
	var boars := _by("e1", _actions(6.0))
	var hit: Dictionary = boars[0]["results"][0]
	assert_eq(hit["protected"], "p1", "the boar charged p1 ...")
	assert_eq(hit["target"], "p0", "... but the Guardian took it")
	assert_eq(hit["damage"], 18, "(30 - 9 x 0.5) x 0.7")
	assert_eq(_party(1)["hp"], 70, "protected ally untouched")
	assert_eq(_party(0)["hp"], 70 - 26 - 18)


func test_protect_cannot_target_yourself() -> void:
	_start(["grey_wolf"], {"grey_wolf": {"max_hp": 500, "spd": 5}})
	assert_rejected(h.server.command(sessions[0], {"type": "action", "action": "skill", "skill": "protect",
			"target": "p0"}), "invalid_target")


func test_protection_ends_on_the_guardians_next_turn() -> void:
	_start(["grey_wolf"], {"grey_wolf": {"max_hp": 500, "spd": 5}})
	h.server.command(sessions[0], {"type": "action", "action": "skill", "skill": "protect", "target": "p3"})
	var waited := 0.0
	while _encounter().get("round") != 2 and waited < 20.0:
		h.advance(0.1, 0.1)
		waited += 0.1
	assert_eq(_encounter()["actor"], "p0")
	assert_eq(_encounter()["protected"], {})


func test_shield_wall_reduces_damage_for_the_whole_party() -> void:
	_start(["grey_wolf", "grey_wolf"], {"grey_wolf": {"max_hp": 500, "spd": 5, "atk": 20, "crit": 0}})
	h.server.take_events(sessions[0])
	assert_rejected(h.server.command(sessions[0], {"type": "action", "action": "skill",
			"skill": "shield_wall", "target": "p0"}), "not_enough_energy")
	h.server.command(sessions[0], {"type": "action", "action": "defend"})
	var waited := 0.0
	while not _encounter().get("your_turn", false) and waited < 20.0:
		h.advance(0.1, 0.1)
		waited += 0.1
	h.server.take_events(sessions[0])
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "skill", "skill": "shield_wall", "target": "p0"}))
	assert_eq(_encounter()["shielded"], true)
	var bites := _by("e0", _actions(6.0))
	assert_eq(bites[0]["results"][0]["damage"], 9, "(20 - 4.5) x 0.6 instead of 16")


func test_guardian_ai_protects_the_most_wounded_ally() -> void:
	_start(["grey_wolf", "grey_wolf"], {"grey_wolf": {"max_hp": 500, "spd": 5, "atk": 60, "crit": 0}})
	var actions := _actions(10.0)
	var round_one := []
	for action in _by("p1", actions):
		round_one.append(action)
	assert_eq(round_one[0]["action"], "defend", "nobody hurt yet: Defend")
	assert_eq(round_one[1]["action"], "skill", "p0 is down to 14/70")
	assert_eq(round_one[1]["skill"], "protect")
	assert_eq(round_one[1]["results"][0]["target"], "p0")
	var p2 := _by("p2", actions)
	assert_eq(p2[1]["action"], "defend", "p0 is already protected, nobody else needs it")


func test_guardian_ai_raises_shield_wall_when_the_party_is_in_danger() -> void:
	_start(["grey_wolf", "grey_wolf", "grey_wolf"], {"grey_wolf": {"max_hp": 500, "spd": 5, "atk": 60, "crit": 0}})
	var first_wall := {}
	for action in _actions(40.0):
		if action.get("skill") == "shield_wall" and first_wall.is_empty():
			first_wall = action
	assert_false(first_wall.is_empty(), "a Guardian braces the Party once half its HP is gone")
	assert_true(first_wall.get("round", 0) >= 2, "not while the Party is healthy")


func test_offer_explains_guardian_and_its_skills() -> void:
	h = MatchHarness.new(5, MatchHarness.class_and_combat("guardian"))
	sessions = h.start_with_humans(1)
	h.take_route(sessions, "class")
	var info: Dictionary = _encounter()["class_info"]
	assert_eq([info["name"], info["role"]], ["Guardian", "Tank / Defense"])
	var names := []
	for skill in info["skills"]:
		names.append(skill["name"])
		assert_false(str(skill["description"]).is_empty())
	assert_eq(names, ["Protect", "Shield Wall"])
	assert_eq(_encounter()["trial"]["enemies"][0]["name"], "Stone Sentinel")
