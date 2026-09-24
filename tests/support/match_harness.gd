class_name MatchHarness
extends RefCounted
## Test helper that owns a MatchServer wired to a seed, a ManualClock and
## Forest content. Tests talk to `server` only through the Match interface.

## Content overrides that make the Party practically unbeatable, for tests
## that need to walk the whole journey without testing combat balance.
## They never touch journey data, so routes are the same as with real content.
const EASY := {
	"leveling": {"growth": {"max_hp": 400, "atk": 60, "mag": 60}},
	"classes": {
		"classless": {"stats": {"max_hp": 999, "atk": 120, "def": 60, "spd": 40}},
		"swordsman": {"stats": {"max_hp": 999, "atk": 120, "def": 60, "spd": 40}},
		"archer": {"stats": {"max_hp": 999, "atk": 120, "def": 60, "spd": 40}},
		"mage": {"stats": {"max_hp": 999, "atk": 120, "mag": 120, "def": 60, "spd": 40}},
		"guardian": {"stats": {"max_hp": 999, "atk": 120, "def": 60, "spd": 40}},
		"rogue": {"stats": {"max_hp": 999, "atk": 120, "def": 60, "spd": 40}},
	},
}

## Content overrides whose routes only ever offer Combat Encounters.
const ALL_COMBAT := {
	"journey": {
		"type_weights": {"combat": 1, "merchant": 0, "rest": 0, "treasure": 0, "story": 0, "class": 0},
		"guarantees": {"class_by_layer": 0, "merchant_before_boss": false},
	},
}
## Every Combat Encounter is exactly two Grey Wolves.
const WOLF_PAIR := {
	"encounters": {"combat": {"groups": [
		{"id": "wolf_pair", "enemies": ["grey_wolf", "grey_wolf"], "layers": [1, 5], "weight": 1},
	]}},
}
## Removes randomness from damage and pins pacing and a reference balance,
## so mechanics tests can expect exact numbers whatever the real balance in
## content/forest.json says (balance is covered by tests/regression).
const EXACT_DAMAGE := {
	"rules": {"damage_variance": 0, "ai_turn_seconds": 0.8, "enemy_turn_seconds": 0.9, "combat_end_seconds": 3},
	"story": {"combat_clues": {"chance": 0}},
	"leveling": {
		"exp_to_next": [20, 35, 55, 80, 110, 150],
		"growth": {"max_hp": 5, "atk": 1, "def": 1, "mag": 1, "res": 1, "spd": 0},
	},
	"class_encounters": {"pass_exp": 0, "mastery_exp": 15},
	"encounters": {"rest": {"heal_ratio": 0.6}},
	"classes": {"classless": {"stats": {"crit": 0}}},
	"enemies": {
		"grey_wolf": {"stats": {"max_hp": 26, "atk": 9, "crit": 0}, "rewards": {"exp": 8, "gold": 5, "drops": []}},
		"thornback_boar": {"stats": {"max_hp": 48, "atk": 12}, "rewards": {"exp": 14, "gold": 9}},
		"bramble_archer": {"stats": {"max_hp": 20, "atk": 10}, "rewards": {"exp": 10, "gold": 12}},
		"forest_wisp": {"stats": {"max_hp": 18, "mag": 9}, "rewards": {"exp": 12, "gold": 8}},
		"elder_thornwarden": {"stats": {"max_hp": 480}},
	},
	"boss": {
		"phases": [
			{"name": "Rooted Sentinel", "below_ratio": 1.0, "pattern": ["bramble_lash", "bramble_lash", "telegraph:crushing_root"]},
			{"name": "Wrathful Bloom", "below_ratio": 0.5, "boost": {"atk": 4, "mag": 4, "spd": 4},
				"pattern": ["bramble_lash", "telegraph:thorn_storm", "bramble_lash", "telegraph:crushing_root"],
				"text": "The Thornwarden roars."},
		],
		"moves": {
			"crushing_root": {"use": {"damage": {"power": 2.6}}},
			"thorn_storm": {"use": {"damage": {"power": 1.5}}},
		},
	},
}

var clock := ManualClock.new()
var content: ForestContent
var server: MatchServer


func _init(seed_value: int = 1, content_overrides: Dictionary = {}) -> void:
	content = ForestContent.load_default().with_overrides(content_overrides)
	server = MatchServer.new(GameRng.new(seed_value), clock, content)


## Passes `seconds` of time in small steps, calling update() after each one
## like the real server loop does every frame.
func advance(seconds: float, step: float = 0.25) -> void:
	var remaining := seconds
	while remaining > 0.000001:
		var dt := minf(step, remaining)
		clock.advance(dt)
		remaining -= dt
		server.update()


## Room code of the room created with create_room().
var code := ""
## Result of the most recent helper command, for tests that want to check it.
var last_result: Dictionary = {}


## Deep-merges content override dictionaries (later ones win).
static func merge(overrides: Array) -> Dictionary:
	var out := {}
	for item in overrides:
		out = ForestContent._merged(out, item)
	return out


## Every human votes for the first route and the travel time passes, so the
## first Layer's Encounter has started.
func enter_first_encounter(sessions: Array[int]) -> void:
	for session in sessions:
		server.command(session, {"type": "vote", "option": 0})
	advance(content.get_float("rules.travel_seconds", 0.0) + 0.01, 0.01)


## Content where every Layer offers one Combat and one Class Encounter for
## `class_id` (with a trainer that falls in one hit).
static func class_and_combat(class_id: String) -> Dictionary:
	var trainer: String = {
		"swordsman": "old_swordsman", "archer": "veteran_hunter",
		"mage": "shrine_spirit", "guardian": "stone_sentinel", "rogue": "masked_outlaw",
	}[class_id]
	return {
		"journey": {
			"options_min": 2,
			"options_max": 2,
			"type_weights": {"combat": 1, "merchant": 0, "rest": 0, "treasure": 0, "story": 0, "class": 1},
			"guarantees": {"class_by_layer": 0, "merchant_before_boss": false},
			"sites": {"class": [{"id": "test_site", "name": "Test Site", "hint": "Test.", "classes": {class_id: 1}}]},
		},
		"enemies": {trainer: {"stats": {"max_hp": 1}}},
	}


## Content where every Layer offers exactly the given Encounter types.
static func only_routes(types: Array) -> Dictionary:
	var weights := {"combat": 0, "merchant": 0, "rest": 0, "treasure": 0, "story": 0, "class": 0}
	for type in types:
		weights[type] = 1
	return {"journey": {
		"options_min": types.size(),
		"options_max": types.size(),
		"type_weights": weights,
		"guarantees": {"class_by_layer": 0, "merchant_before_boss": false},
	}}


## Every human votes for the route of `type` in the current Layer, then the
## travel time passes.
func take_route(sessions: Array[int], type: String) -> void:
	var view := match_view(sessions[0])
	for option in view["vote"]["options"]:
		if option["type"] == type:
			for session in sessions:
				server.command(session, {"type": "vote", "option": option["index"]})
			break
	advance(content.get_float("rules.travel_seconds", 0.0) + 0.1, 0.1)


## Humans attack the trainer until the Class Encounter's Challenge is over.
func fight_trial(sessions: Array[int], limit: float = 90.0) -> void:
	var waited := 0.0
	while waited < limit:
		var encounter = match_view(sessions[0]).get("encounter")
		if encounter == null or encounter.get("stage") != "challenge":
			return
		for session in sessions:
			var trial: Dictionary = match_view(session)["encounter"].get("trial", {})
			if trial.get("your_turn", false):
				server.command(session, {"type": "action", "action": "attack", "target": "e0"})
		advance(0.1, 0.1)
		waited += 0.1


## Takes the Class Encounter route, passes it and has every human accept.
func gain_class(sessions: Array[int]) -> void:
	take_route(sessions, "class")
	fight_trial(sessions)
	for session in sessions:
		server.command(session, {"type": "class_choice", "accept": true})


## Opens a session that creates a room; remembers the Room code.
func create_room(display_name: String = "Host") -> int:
	var session := server.open_session()
	last_result = server.command(session, {"type": "create_room", "name": display_name})
	code = str(last_result.get("code", ""))
	return session


## Opens a session that joins the remembered room.
func join(display_name: String) -> int:
	var session := server.open_session()
	last_result = server.command(session, {"type": "join_room", "code": code, "name": display_name})
	return session


func start(host_session: int) -> Dictionary:
	last_result = server.command(host_session, {"type": "start_match"})
	return last_result


## A room with `humans` players (first one is the Host), Match started.
## Returns the sessions in slot order.
func start_with_humans(humans: int) -> Array[int]:
	var sessions: Array[int] = [create_room("P1")]
	for i in range(1, humans):
		sessions.append(join("P%d" % (i + 1)))
	start(sessions[0])
	return sessions


func room_view(session: int) -> Dictionary:
	var room = server.snapshot(session)["room"]
	return room if room != null else {}


func match_view(session: int) -> Dictionary:
	var run = server.snapshot(session)["match"]
	return run if run != null else {}


func event_types(session: int) -> Array:
	var types := []
	for event in server.take_events(session):
		types.append(event["type"])
	return types
