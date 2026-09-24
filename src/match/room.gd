class_name Room
extends RefCounted
## One room behind a Room code: five Player slots, a Host, and the current
## (or most recent) Match. Internal to the Match module; only MatchServer
## talks to it.

const SLOT_COUNT := 5

enum State { LOBBY, IN_MATCH, CLOSED }

var code: String
var state: State = State.LOBBY
var host_slot := -1
## Each slot: {"session": int (0 = nobody), "name": String}
var slots: Array[Dictionary] = []
## The running Match, or the finished one whose summary is still shown.
var run: MatchRun = null
## Events waiting to be delivered to every member of the room.
var outbox: Array[Dictionary] = []

var _rng: GameRng
var _clock
var _content: ForestContent
var _empty_since := -1.0
var _matches_started := 0


func _init(room_code: String, rng: GameRng, clock, content: ForestContent) -> void:
	code = room_code
	_rng = rng
	_clock = clock
	_content = content
	for i in SLOT_COUNT:
		slots.append({"session": 0, "name": ""})


func human_count() -> int:
	var count := 0
	for slot in slots:
		if slot["session"] != 0:
			count += 1
	return count


func is_full() -> bool:
	return human_count() >= SLOT_COUNT


func slot_of(session_id: int) -> int:
	for i in SLOT_COUNT:
		if slots[i]["session"] == session_id:
			return i
	return -1


func sessions() -> Array[int]:
	var out: Array[int] = []
	for slot in slots:
		if slot["session"] != 0:
			out.append(slot["session"])
	return out


## Seats a new human in the lowest free slot. Caller checks is_full()/state.
func join(session_id: int, display_name: String) -> int:
	var index := -1
	for i in SLOT_COUNT:
		if slots[i]["session"] == 0:
			index = i
			break
	slots[index] = {"session": session_id, "name": display_name}
	_empty_since = -1.0
	_emit({"type": "player_joined", "slot": index, "name": display_name})
	if host_slot == -1:
		_set_host(index)
	return index


## The human in `session_id` leaves (by choice or because the connection
## dropped). Their slot becomes AI-controlled; the character keeps its state.
func leave(session_id: int, reason: String) -> void:
	var index := slot_of(session_id)
	if index == -1:
		return
	var old_name: String = slots[index]["name"]
	slots[index] = {"session": 0, "name": ""}
	_emit({"type": "player_left", "slot": index, "name": old_name, "reason": reason})
	if run != null and state == State.IN_MATCH:
		run.set_human(index, false)
		_drain_run()
	if host_slot == index:
		host_slot = -1
		for i in SLOT_COUNT:
			if slots[i]["session"] != 0:
				_set_host(i)
				break
	if human_count() == 0:
		_empty_since = _clock.now()


func start_match() -> void:
	var humans: Array[bool] = []
	for slot in slots:
		humans.append(slot["session"] != 0)
	_matches_started += 1
	state = State.IN_MATCH
	run = MatchRun.new(_rng.fork(), _clock, _content, humans, _matches_started)
	_drain_run()


## Routes an in-Match command from the human in `slot`.
func handle_match_command(slot: int, cmd: Dictionary) -> Dictionary:
	var result := run.handle(slot, cmd)
	_drain_run()
	return result


func update() -> void:
	if state == State.CLOSED:
		return
	if human_count() == 0 and _empty_since >= 0.0:
		var grace := _content.get_float("rules.empty_room_grace_seconds", 30.0)
		if _clock.now() - _empty_since >= grace:
			close()
			return
	if state == State.IN_MATCH and run != null:
		run.update()
		_drain_run()


func close() -> void:
	state = State.CLOSED
	_emit({"type": "room_closed"})


func snapshot_for(session_id: int) -> Dictionary:
	var you := slot_of(session_id)
	var slot_views: Array = []
	var members: Array = _content.get_array("party.members")
	for i in SLOT_COUNT:
		var human: bool = slots[i]["session"] != 0
		var member: Dictionary = members[i] if i < members.size() else {}
		slot_views.append({
			"index": i,
			"character_name": str(member.get("name", "Hero %d" % (i + 1))),
			"controller": "human" if human else "ai",
			"owner_name": slots[i]["name"],
			"is_host": i == host_slot,
			"is_you": i == you,
		})
	return {
		"code": code,
		"state": _state_name(),
		"host_slot": host_slot,
		"your_slot": you,
		"slots": slot_views,
	}


func _set_host(index: int) -> void:
	host_slot = index
	_emit({"type": "host_changed", "slot": index, "name": slots[index]["name"]})


func _drain_run() -> void:
	if run == null:
		return
	for event in run.take_outbox():
		outbox.append(event)
	if state == State.IN_MATCH and run.is_over():
		state = State.LOBBY


func _emit(event: Dictionary) -> void:
	outbox.append(event)


func _state_name() -> String:
	match state:
		State.LOBBY:
			return "lobby"
		State.IN_MATCH:
			return "in_match"
		_:
			return "closed"
