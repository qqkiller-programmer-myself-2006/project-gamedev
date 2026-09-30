class_name SystemClock
extends RefCounted
## Real monotonic time for the running server. Same duck-typed interface as
## ManualClock: now() returns seconds as a float.

var _start_usec := Time.get_ticks_usec()


func now() -> float:
	return float(Time.get_ticks_usec() - _start_usec) / 1_000_000.0
