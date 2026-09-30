class_name ManualClock
extends RefCounted
## A clock that only moves when told to. Tests and deterministic replays
## inject it into MatchServer and call advance() to pass time (Action
## windows, vote timers, AI pacing, room grace periods).

var _now := 0.0


func _init(start: float = 0.0) -> void:
	_now = start


## Seconds since the clock started.
func now() -> float:
	return _now


func advance(seconds: float) -> void:
	assert(seconds >= 0.0, "time cannot go backwards")
	_now += seconds
