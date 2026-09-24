class_name MatchBot
extends RefCounted
## Scripted player(s) that drive a Match purely through the Match interface:
## it reads each human session's snapshot and sends the commands a sensible
## player would. Used for journey tests and the full-run regression suite.

var harness: MatchHarness
var sessions: Array[int] = []
## Events seen by the first session, in order.
var events: Array = []
## Chooses a route option: func(options: Array, slot: int) -> int
var choose_route: Callable = func(_options: Array, _slot: int) -> int: return 0
## Seconds of game time between bot decisions.
var step := 0.5


func _init(match_harness: MatchHarness, human_sessions: Array[int]) -> void:
	harness = match_harness
	sessions = human_sessions


## Plays until `stop` returns true for the first session's Match snapshot,
## the Match is over, or `max_seconds` of game time pass. Returns the final
## Match snapshot.
func play_until(stop: Callable, max_seconds: float = 7200.0) -> Dictionary:
	var elapsed := 0.0
	while elapsed < max_seconds:
		_collect_events()
		var view := _match_of(sessions[0])
		if view.is_empty() or view["phase"] in ["victory", "defeat"] or stop.call(view):
			return view
		for session in sessions:
			act(session)
		_collect_events()
		harness.advance(step, step)
		elapsed += step
	return _match_of(sessions[0])


## Plays until the Match ends (Victory or Defeat).
func play_to_end(max_seconds: float = 7200.0) -> Dictionary:
	return play_until(func(_v: Dictionary) -> bool: return false, max_seconds)


## Makes one decision for `session` if it has something to do.
func act(session: int) -> void:
	var snap := harness.server.snapshot(session)
	var view = snap["match"]
	if view == null or snap["room"] == null:
		return
	var slot: int = snap["room"]["your_slot"]
	if slot < 0:
		return
	match view["phase"]:
		"voting":
			var vote: Dictionary = view["vote"]
			if not vote["voted_slots"].has(slot):
				var option: int = choose_route.call(vote["options"], slot)
				harness.server.command(session, {"type": "vote", "option": option})


func events_of_type(type: String) -> Array:
	var out := []
	for event in events:
		if event["type"] == type:
			out.append(event)
	return out


func _collect_events() -> void:
	events.append_array(harness.server.take_events(sessions[0]))
	for i in range(1, sessions.size()):
		harness.server.take_events(sessions[i])


func _match_of(session: int) -> Dictionary:
	var view = harness.server.snapshot(session)["match"]
	return view if view != null else {}
