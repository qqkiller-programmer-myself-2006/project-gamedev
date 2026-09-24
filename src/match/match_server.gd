class_name MatchServer
extends RefCounted
## The Match interface: the single seam of the authoritative game logic.
##
## Everything that decides the game (rooms, Player slots, Path Voting,
## combat, rewards, Match state) lives behind this small interface:
##
##   open_session()            -> anonymous session id for a new connection
##   command(session, cmd)     -> {"ok": true, ...} or {"ok": false, "error": code}
##   update()                  -> process everything that is due at clock.now()
##   take_events(session)      -> events this session should see, oldest first
##   snapshot(session)         -> the state this session should see right now
##   close_session(session)    -> the connection is gone
##
## It depends on exactly three things supplied from outside: a GameRng (all
## randomness), a clock (anything with now() -> float seconds) and the
## ForestContent data. It never creates these itself, so tests can run a
## Match headless and deterministically. Transport adapters only translate
## messages to and from these calls and never decide anything themselves.

var _rng: GameRng
var _clock
var _content: ForestContent

var _next_session_id := 1
## session id -> per-session bookkeeping ({"events": Array})
var _sessions: Dictionary = {}


func _init(rng: GameRng, clock, content: ForestContent) -> void:
	assert(rng != null and clock != null and content != null)
	_rng = rng
	_clock = clock
	_content = content


## Registers a new anonymous connection and returns its session id.
func open_session() -> int:
	var id := _next_session_id
	_next_session_id += 1
	_sessions[id] = {"events": []}
	return id


## Forgets a session. Safe to call more than once.
func close_session(session_id: int) -> void:
	_sessions.erase(session_id)


## Applies one command sent by `session_id`. Rejected commands never change
## state and return {"ok": false, "error": <code>}.
func command(session_id: int, cmd: Dictionary) -> Dictionary:
	if not _sessions.has(session_id):
		return _reject("unknown_session")
	var kind := str(cmd.get("type", ""))
	match kind:
		_:
			return _reject("unknown_command")


## Processes timers that are due at the injected clock's current time.
func update() -> void:
	pass


## Returns and clears the events queued for `session_id`.
func take_events(session_id: int) -> Array:
	if not _sessions.has(session_id):
		return []
	var events: Array = _sessions[session_id]["events"]
	_sessions[session_id]["events"] = []
	return events


## The state `session_id` should see. `time` is the server clock, which
## clients use together with deadlines to render countdowns.
func snapshot(session_id: int) -> Dictionary:
	return {
		"session": session_id if _sessions.has(session_id) else 0,
		"time": _clock.now(),
	}


func _reject(error: String) -> Dictionary:
	return {"ok": false, "error": error}
