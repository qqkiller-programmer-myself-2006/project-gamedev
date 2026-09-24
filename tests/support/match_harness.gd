class_name MatchHarness
extends RefCounted
## Test helper that owns a MatchServer wired to a seed, a ManualClock and
## Forest content. Tests talk to `server` only through the Match interface.

## Content overrides that make the Party practically unbeatable, for tests
## that need to walk the whole journey without testing combat balance.
## They never touch journey data, so routes are the same as with real content.
const EASY := {
	"leveling": {"growth": {"max_hp": 400, "atk": 60}},
	"classes": {"classless": {"stats": {"max_hp": 999, "atk": 120, "def": 60, "spd": 40}}},
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
## Removes randomness from damage so tests can expect exact numbers.
const EXACT_DAMAGE := {
	"rules": {"damage_variance": 0},
	"classes": {"classless": {"stats": {"crit": 0}}},
	"enemies": {"grey_wolf": {"stats": {"crit": 0}, "rewards": {"drops": []}}},
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
