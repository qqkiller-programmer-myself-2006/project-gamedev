extends TestCase
## Statuses are cleared at every Combat and Class Challenge boundary, so a
## DoT never leaks into a later Encounter (issue #42, ADR-0010). Covers a
## won Combat, a lost Combat, a passed Challenge and a failed one. Match
## interface only: commands, snapshots and events.

## A long DoT (99 turns, 1 damage) that outlives every fight here, so a
## leftover would be easy to see.
const SMOLDER := {
	"statuses": {"smolder": {"name": "Smolder", "kind": "dot", "damage": 1, "turns": 99, "max_stacks": 1,
			"tick_every": 1, "color": "#ff8a2a"}},
	"items": {
		"smolder_rain": {"name": "Smolder Rain", "price": 1, "use": {"target": "all_enemies",
				"damage": {"amount": 1}, "apply_status": [{"status": "smolder", "stacks": 1}]}},
	},
	"party": {"starting_inventory": {"smolder_rain": 3}},
}
## Wolves that cannot hurt anyone, so later Combats show only leaked Statuses.
const HARMLESS_WOLVES := {"enemies": {"grey_wolf": {"stats": {"max_hp": 500, "atk": 0, "spd": 5, "crit": 0},
		"rewards": {"drops": []}}}}
## Wolves that poison for a lethal amount, so the whole Party goes down to DoT.
const DEADLY_WOLVES := {
	"statuses": {"poison": {"damage": 60}},
	"enemies": {"grey_wolf": {"stats": {"max_hp": 500, "atk": 0, "spd": 5, "crit": 0},
			"attack": {"target": "enemy", "damage": {"amount": 1}, "apply_status": [{"status": "poison", "stacks": 1}]},
			"behavior": "hunt_weakest", "rewards": {"drops": []}}},
}
## The Class Encounter's trainer poisons the Party (Smolder) on his first turn.
const SMOLDERING_TRAINER := {"enemies": {"old_swordsman": {"stats": {"atk": 0, "spd": 99, "crit": 0},
		"attack": {"target": "enemy", "damage": {"amount": 1}, "apply_status": [{"status": "smolder", "stacks": 1}]}}}}

var h: MatchHarness
var sessions: Array[int] = []
## Every event seen since the last _mark().
var seen: Array = []


func _start_combat(extra: Dictionary) -> void:
	h = MatchHarness.new(7, MatchHarness.merge([MatchHarness.ALL_COMBAT, MatchHarness.WOLF_PAIR,
			MatchHarness.EXACT_DAMAGE, SMOLDER, HARMLESS_WOLVES, extra]))
	sessions = h.start_with_humans(1)
	h.enter_first_encounter(sessions)
	_mark()


func _start_challenge(trainer: Dictionary) -> void:
	h = MatchHarness.new(6, MatchHarness.merge([MatchHarness.class_and_combat("swordsman"), MatchHarness.WOLF_PAIR,
			MatchHarness.EXACT_DAMAGE, SMOLDER, HARMLESS_WOLVES, SMOLDERING_TRAINER, {"enemies": {"old_swordsman": trainer}}]))
	sessions = h.start_with_humans(1)
	h.take_route(sessions, "class")
	_mark()


func _view() -> Dictionary:
	return h.match_view(sessions[0])


func _encounter() -> Dictionary:
	var encounter = _view().get("encounter")
	return encounter if encounter != null else {}


## The Combat the player is looking at: the Encounter itself, or a Class
## Challenge's trial.
func _combat() -> Dictionary:
	var encounter := _encounter()
	if encounter.get("kind") == "class":
		return encounter.get("trial", {})
	return encounter


func _mark() -> void:
	h.server.take_events(sessions[0])
	seen = []


func _collect() -> void:
	seen.append_array(h.server.take_events(sessions[0]))


func _of(type: String) -> Array:
	return seen.filter(func(e): return e["type"] == type)


## One step of play: the human attacks whenever it is their turn.
func _play_step() -> void:
	var combat := _combat()
	if combat.get("your_turn", false):
		var target := ""
		for enemy in combat["enemies"]:
			if enemy["hp"] > 0:
				target = enemy["id"]
				break
		if not target.is_empty():
			h.server.command(sessions[0], {"type": "action", "action": "attack", "target": target})
	h.advance(0.1, 0.1)
	_collect()


## Plays until `done` is true; returns whether any Status was on show on the way.
func _play_until(done: Callable, limit: float = 300.0) -> bool:
	var saw_status := false
	var waited := 0.0
	while not done.call() and waited < limit:
		_play_step()
		if not _combat().get("statuses", {}).is_empty():
			saw_status = true
		waited += 0.1
	return saw_status


func _throw_smolder_rain() -> void:
	var waited := 0.0
	while not _combat().get("your_turn", false) and waited < 30.0:
		h.advance(0.1, 0.1)
		waited += 0.1
	assert_ok(h.server.command(sessions[0], {"type": "action", "action": "item", "item": "smolder_rain"}))
	assert_false(_combat()["statuses"].is_empty(), "the Statuses are on show")


## Enter the next Layer's Combat and check nothing carried over.
func _assert_next_combat_is_clean(label: String) -> void:
	var waited := 0.0
	while _view()["phase"] != "voting" and waited < 30.0 and not (_view()["phase"] in ["victory", "defeat"]):
		if _encounter().get("stage") == "offer":
			h.server.command(sessions[0], {"type": "class_choice", "accept": false})
		h.advance(0.1, 0.1)
		waited += 0.1
	assert_eq(_view()["phase"], "voting", "%s: the journey moved on" % label)
	_mark()
	h.take_route(sessions, "combat")
	assert_eq(_encounter().get("kind"), "combat", label)
	assert_eq(_combat()["statuses"], {}, "%s: the next Combat starts clean" % label)
	h.advance(20.0, 0.1)
	_collect()
	assert_eq(_of("status_applied"), [], label)
	assert_eq(_of("status_tick"), [], "%s: nothing keeps burning" % label)
	assert_eq(_of("status_expired"), [], label)
	assert_eq(_combat()["statuses"], {}, label)


func test_statuses_are_cleared_after_a_won_combat() -> void:
	_start_combat({"enemies": {"grey_wolf": {"stats": {"max_hp": 30}}}})
	_throw_smolder_rain()
	var saw_status := _play_until(func(): return not str(_combat().get("result", "")).is_empty())
	assert_true(saw_status, "the Statuses were live during the fight")
	assert_eq(_combat()["result"], "victory")
	assert_eq(_combat()["statuses"], {}, "cleared the moment the Combat is won")
	assert_eq(_of("combat_ended")[0]["result"], "victory")
	_assert_next_combat_is_clean("won")


func test_statuses_are_cleared_after_a_defeated_combat() -> void:
	_start_combat(DEADLY_WOLVES)
	_throw_smolder_rain()
	var saw_status := _play_until(func(): return not str(_combat().get("result", "")).is_empty())
	assert_true(saw_status)
	assert_eq(_combat()["result"], "defeat", "the Party went down to the poison")
	assert_eq(_combat()["statuses"], {}, "cleared the moment the Combat is lost")
	assert_eq(_of("combat_ended")[0]["result"], "defeat")
	assert_true(_of("status_tick").size() > 0, "DoT ticked while it lasted")
	h.advance(10.0, 0.1)
	_collect()
	var view := _view()
	assert_eq([view["phase"], view["encounter"]], ["defeat", null])
	assert_eq(_of("match_ended").size(), 1)


func test_statuses_are_cleared_after_a_completed_challenge() -> void:
	_start_challenge({"stats": {"max_hp": 12}})
	var saw_status := _play_until(func(): return not _of("class_challenge_ended").is_empty())
	assert_true(saw_status, "the Party was poisoned during the trial")
	assert_eq(_of("combat_ended")[0]["result"], "victory")
	assert_eq(_of("class_challenge_ended")[0]["passed"], true)
	_assert_next_combat_is_clean("passed challenge")


func test_statuses_are_cleared_after_a_failed_challenge() -> void:
	_start_challenge({"stats": {"max_hp": 9999}})
	var saw_status := _play_until(func(): return not _of("class_challenge_ended").is_empty())
	assert_true(saw_status, "the Party was poisoned during the trial")
	assert_eq(_of("combat_ended")[0]["result"], "timeout")
	assert_eq(_of("class_challenge_ended")[0]["passed"], false)
	_assert_next_combat_is_clean("failed challenge")
