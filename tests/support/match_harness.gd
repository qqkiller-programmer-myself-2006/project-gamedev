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
