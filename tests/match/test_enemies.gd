extends TestCase
## Forest enemy kinds, their behaviours and the seeded Combat pool (issue #9).

const NO_ENEMY_CRITS := {"enemies": {
	"grey_wolf": {"stats": {"crit": 0}, "rewards": {"drops": []}},
	"thornback_boar": {"stats": {"crit": 0}, "rewards": {"drops": []}},
	"bramble_archer": {"stats": {"crit": 0}, "rewards": {"drops": []}},
	"forest_wisp": {"stats": {"crit": 0}, "rewards": {"drops": []}},
}}
const LAYER_ONE_GROUPS := [
	["grey_wolf", "grey_wolf"], ["thornback_boar"], ["grey_wolf", "bramble_archer"],
]

var h: MatchHarness
var sessions: Array[int] = []


## Starts a Match whose first Encounter is a fight against exactly `kinds`.
func _fight(kinds: Array, extra: Dictionary = {}, seed_value: int = 4) -> void:
	var group := {"encounters": {"combat": {"groups": [{"id": "test", "enemies": kinds, "layers": [1, 5]}]}}}
	h = MatchHarness.new(seed_value, MatchHarness.merge([MatchHarness.ALL_COMBAT, MatchHarness.EXACT_DAMAGE,
			NO_ENEMY_CRITS, group, extra]))
	sessions = h.start_with_humans(1)
	h.enter_first_encounter(sessions)


func _combat_view() -> Dictionary:
	var encounter = h.match_view(sessions[0])["encounter"]
	return encounter if encounter != null else {}


## Every action taken by `actor` during the next `seconds`, with the human
## Defending whenever it is their turn.
func _actions_by(actor: String, seconds: float) -> Array:
	return _by(actor, _actions(seconds))


func _by(actor: String, actions: Array) -> Array:
	var out := []
	for action in actions:
		if action["actor"] == actor:
			out.append(action)
	return out


## Every action resolved during the next `seconds`, with the human Defending
## whenever it is their turn.
func _actions(seconds: float) -> Array:
	var found := []
	var waited := 0.0
	h.server.take_events(sessions[0])
	while waited < seconds:
		if _combat_view().get("your_turn", false):
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


func test_wolves_hunt_the_weakest_character() -> void:
	_fight(["grey_wolf", "grey_wolf"], {"enemies": {"grey_wolf": {"stats": {"max_hp": 500, "spd": 5}}}})
	var actions := _actions(6.0)
	assert_eq(_targets(_by("e0", actions)[0]), ["p0"], "all equal: first in line")
	assert_eq(_targets(_by("e1", actions)[0]), ["p0"], "the bitten one is now the weakest")


func test_boars_charge_the_strongest_character() -> void:
	_fight(["thornback_boar", "thornback_boar"], {"enemies": {"thornback_boar": {"stats": {"max_hp": 500, "spd": 5}}}})
	var actions := _actions(6.0)
	assert_eq(_targets(_by("e0", actions)[0]), ["p0"])
	assert_eq(_targets(_by("e1", actions)[0]), ["p1"], "p0 was hurt, so p1 now has the most HP")


func test_archers_pick_targets_at_random() -> void:
	var targets := {}
	for seed_value in 20:
		_fight(["bramble_archer"], {"enemies": {"bramble_archer": {"stats": {"max_hp": 500, "spd": 5}}}}, seed_value)
		var shots: Array = _actions_by("e0", 6.0)
		targets[_targets(shots[0])[0]] = true
	assert_true(targets.size() >= 3, "archers spread their shots (%d targets)" % targets.size())


func test_wisp_heals_a_wounded_ally() -> void:
	_fight(["thornback_boar", "forest_wisp"], {"enemies": {
		"thornback_boar": {"stats": {"max_hp": 60, "spd": 5}},
		"forest_wisp": {"stats": {"spd": 4}},
	}})
	h.server.command(sessions[0], {"type": "action", "action": "attack", "target": "e0"})
	var mends: Array = _actions_by("e1", 6.0)
	assert_eq(mends[0]["action"], "skill")
	assert_eq(mends[0]["skill"], "Mend")
	assert_eq(_targets(mends[0]), ["e0"])
	assert_eq(mends[0]["results"][0]["heal"], 18)


func test_wisp_attacks_when_nobody_needs_healing() -> void:
	_fight(["forest_wisp"], {"enemies": {"forest_wisp": {"stats": {"max_hp": 500, "spd": 5}}}})
	var actions: Array = _actions_by("e0", 6.0)
	assert_eq(actions[0]["action"], "attack")
	assert_eq(actions[0]["results"][0]["element"], "spirit")


func test_melee_cannot_reach_back_row_while_front_row_stands() -> void:
	_fight(["grey_wolf", "bramble_archer"], {"enemies": {
		"grey_wolf": {"stats": {"max_hp": 1, "spd": 5}},
		"bramble_archer": {"stats": {"max_hp": 500, "spd": 4}},
	}})
	assert_eq(_combat_view()["choices"]["attack"]["targets"], ["e0"])
	assert_rejected(h.server.command(sessions[0], {"type": "action", "action": "attack", "target": "e1"}),
			"invalid_target")
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "attack", "target": "e0"}))
	var archer_hits: Array = []
	for action in _actions_by("p1", 1.0):
		archer_hits.append_array(_targets(action))
	assert_eq(archer_hits, ["e1"], "with the wolf down, the archer is in reach")


func test_encounter_can_have_several_enemies() -> void:
	_fight(["thornback_boar", "grey_wolf", "forest_wisp"])
	var names := []
	for enemy in _combat_view()["enemies"]:
		names.append(enemy["name"])
	assert_eq(names, ["Thornback Boar", "Grey Wolf", "Forest Wisp"])


func test_enemy_view_describes_each_kind() -> void:
	_fight(["thornback_boar", "bramble_archer"])
	var enemies: Array = _combat_view()["enemies"]
	assert_eq([enemies[0]["row"], enemies[1]["row"]], ["front", "back"])
	assert_eq(enemies[0]["weakness"], ["fire"])
	for enemy in enemies:
		assert_false(str(enemy["description"]).is_empty())


func test_rewards_depend_on_enemy_kind() -> void:
	var expected := {"grey_wolf": [8, 5], "thornback_boar": [14, 9], "bramble_archer": [10, 12], "forest_wisp": [12, 8]}
	for kind in expected:
		_fight([kind], {"enemies": {kind: {"stats": {"max_hp": 1, "spd": 5}}}})
		h.server.command(sessions[0], {"type": "action", "action": "attack", "target": "e0"})
		var view := h.match_view(sessions[0])
		assert_eq([view["encounter"]["rewards"]["exp"], view["encounter"]["rewards"]["gold"]], expected[kind], kind)


func test_combat_group_is_chosen_from_pool_by_seed() -> void:
	var seen := {}
	for seed_value in 60:
		var kinds := _first_combat_kinds(seed_value)
		assert_eq(_first_combat_kinds(seed_value), kinds, "seed %d reproducible" % seed_value)
		assert_has(LAYER_ONE_GROUPS, kinds, "Layer 1 only uses early groups")
		seen[str(kinds)] = true
	assert_eq(seen.size(), LAYER_ONE_GROUPS.size(), "every early group shows up across seeds")


func _first_combat_kinds(seed_value: int) -> Array:
	var harness := MatchHarness.new(seed_value, MatchHarness.ALL_COMBAT)
	var solo := harness.start_with_humans(1)
	harness.enter_first_encounter(solo)
	var kinds := []
	for enemy in harness.match_view(solo[0])["encounter"]["enemies"]:
		kinds.append(enemy["kind"])
	return kinds
