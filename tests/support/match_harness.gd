class_name MatchHarness
extends RefCounted
## Test helper that owns a MatchServer wired to a seed, a ManualClock and
## Forest content. Tests talk to `server` only through the Match interface.

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
