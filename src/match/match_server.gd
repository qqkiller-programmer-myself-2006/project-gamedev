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
##
## Commands (all Dictionaries with a "type"):
##   create_room {name}          join_room {code, name}
##   leave_room                  start_match (Host only)
## and, during a Match, the in-Match commands documented in MatchRun.

const MAX_NAME_LENGTH := 16

var _rng: GameRng
var _clock
var _content: ForestContent

var _next_session_id := 1
## session id -> {"events": Array, "room": String}
var _sessions: Dictionary = {}
## Room code -> Room, for rooms that are still open.
var _rooms: Dictionary = {}
## Codes of rooms that have been closed, so joining them says so.
var _closed_codes: Dictionary = {}


func _init(rng: GameRng, clock, content: ForestContent) -> void:
	assert(rng != null and clock != null and content != null)
	_rng = rng
	_clock = clock
	_content = content


## Registers a new anonymous connection and returns its session id.
func open_session() -> int:
	var id := _next_session_id
	_next_session_id += 1
	_sessions[id] = {"events": [], "room": ""}
	return id


## The connection behind `session_id` is gone: the player leaves their room
## (their slot becomes AI-controlled) and the session is forgotten.
func close_session(session_id: int) -> void:
	if not _sessions.has(session_id):
		return
	var room := _room_of(session_id)
	if room != null:
		room.leave(session_id, "disconnected")
		_flush(room)
	_sessions.erase(session_id)


## Applies one command sent by `session_id`. Rejected commands never change
## state and return {"ok": false, "error": <code>}.
func command(session_id: int, cmd: Dictionary) -> Dictionary:
	if not _sessions.has(session_id):
		return _reject("unknown_session")
	var kind := str(cmd.get("type", ""))
	match kind:
		"create_room":
			return _create_room(session_id, cmd)
		"join_room":
			return _join_room(session_id, cmd)
		"leave_room":
			return _leave_room(session_id)
		"start_match":
			return _start_match(session_id)
	if not MatchRun.COMMANDS.has(kind):
		return _reject("unknown_command")
	var room := _room_of(session_id)
	if room == null:
		return _reject("not_in_room")
	if room.state != Room.State.IN_MATCH:
		return _reject("wrong_phase")
	var result := room.handle_match_command(room.slot_of(session_id), cmd)
	_flush(room)
	return result


## Processes timers that are due at the injected clock's current time.
func update() -> void:
	for code in _rooms.keys():
		var room: Room = _rooms[code]
		room.update()
		_flush(room)
		if room.state == Room.State.CLOSED:
			_rooms.erase(code)
			_closed_codes[code] = true


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
	var room := _room_of(session_id)
	var view := {
		"session": session_id if _sessions.has(session_id) else 0,
		"time": _clock.now(),
		"room": null,
		"match": null,
	}
	if room != null:
		view["room"] = room.snapshot_for(session_id)
		if room.run != null:
			view["match"] = room.run.snapshot(room.slot_of(session_id))
	return view


func _create_room(session_id: int, cmd: Dictionary) -> Dictionary:
	if _room_of(session_id) != null:
		return _reject("already_in_room")
	var display_name := _clean_name(cmd.get("name", ""))
	if display_name.is_empty():
		return _reject("invalid_name")
	var code := RoomCodes.generate(_rng)
	while _rooms.has(code) or _closed_codes.has(code):
		code = RoomCodes.generate(_rng)
	var room := Room.new(code, _rng.fork(), _clock, _content)
	_rooms[code] = room
	var slot := room.join(session_id, display_name)
	_sessions[session_id]["room"] = code
	_flush(room)
	return {"ok": true, "code": code, "slot": slot}


func _join_room(session_id: int, cmd: Dictionary) -> Dictionary:
	if _room_of(session_id) != null:
		return _reject("already_in_room")
	var display_name := _clean_name(cmd.get("name", ""))
	if display_name.is_empty():
		return _reject("invalid_name")
	var code := RoomCodes.normalize(str(cmd.get("code", "")))
	if code.is_empty():
		return _reject("invalid_code")
	if _closed_codes.has(code):
		return _reject("room_closed")
	if not _rooms.has(code):
		return _reject("room_not_found")
	var room: Room = _rooms[code]
	if room.state == Room.State.IN_MATCH:
		return _reject("match_in_progress")
	if room.is_full():
		return _reject("room_full")
	var slot := room.join(session_id, display_name)
	_sessions[session_id]["room"] = code
	_flush(room)
	return {"ok": true, "code": code, "slot": slot}


func _leave_room(session_id: int) -> Dictionary:
	var room := _room_of(session_id)
	if room == null:
		return _reject("not_in_room")
	room.leave(session_id, "left")
	_sessions[session_id]["room"] = ""
	_flush(room)
	return {"ok": true}


func _start_match(session_id: int) -> Dictionary:
	var room := _room_of(session_id)
	if room == null:
		return _reject("not_in_room")
	if room.slot_of(session_id) != room.host_slot:
		return _reject("not_host")
	if room.state != Room.State.LOBBY:
		return _reject("wrong_phase")
	room.start_match()
	_flush(room)
	return {"ok": true}


func _room_of(session_id: int) -> Room:
	if not _sessions.has(session_id):
		return null
	var code: String = _sessions[session_id]["room"]
	if code.is_empty() or not _rooms.has(code):
		return null
	return _rooms[code]


## Delivers the room's pending events to every human in it.
func _flush(room: Room) -> void:
	if room.outbox.is_empty():
		return
	for session_id in room.sessions():
		if _sessions.has(session_id):
			_sessions[session_id]["events"].append_array(room.outbox.duplicate(true))
	room.outbox.clear()


static func _clean_name(raw: Variant) -> String:
	var text := str(raw).strip_edges()
	while text.contains("  "):
		text = text.replace("  ", " ")
	return text.substr(0, MAX_NAME_LENGTH)


func _reject(error: String) -> Dictionary:
	return {"ok": false, "error": error}
