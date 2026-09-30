extends TestCase
## The Match interface itself: injected dependencies, determinism and time.


func test_same_seed_and_clock_replay_identically() -> void:
	assert_eq(_scripted_run(1234), _scripted_run(1234))


func test_advancing_the_clock_changes_observed_time() -> void:
	var h := MatchHarness.new()
	var session := h.server.open_session()
	assert_eq(h.server.snapshot(session)["time"], 0.0)
	h.advance(2.5)
	assert_eq(h.server.snapshot(session)["time"], 2.5)


func test_unknown_command_is_rejected() -> void:
	var h := MatchHarness.new()
	var session := h.server.open_session()
	var before := h.server.snapshot(session)
	assert_rejected(h.server.command(session, {"type": "fly_to_the_moon"}), "unknown_command")
	assert_eq(h.server.snapshot(session), before, "state unchanged")


func test_command_from_unknown_session_is_rejected() -> void:
	var h := MatchHarness.new()
	assert_rejected(h.server.command(999, {"type": "anything"}), "unknown_session")

func test_malformed_numeric_and_string_fields_are_rejected() -> void:
	var h := MatchHarness.new()
	var sessions := h.start_with_humans(2)
	var s0 = sessions[0]

	var b1 = h.server.snapshot(s0)
	
	# MatchServer.command rejects invalid types immediately before checking match state,
	# so we can test all fields right at the start.
	assert_rejected(h.server.command(s0, {"type": "class_choice", "accept": [1]}), "bad_message")
	assert_rejected(h.server.command(s0, {"type": "vote", "option": [1]}), "bad_message")
	assert_rejected(h.server.command(s0, {"type": "transfer_gold", "amount": {}}), "bad_message")
	assert_rejected(h.server.command(s0, {"type": "transfer_gold", "to": "1"}), "bad_message")
	assert_rejected(h.server.command(s0, {"type": "action", "slot": []}), "bad_message")
	assert_rejected(h.server.command(s0, {"type": "event_choice", "layer": "3"}), "bad_message")

	assert_eq(h.server.snapshot(s0), b1)


## Plays a fixed script and records everything a client could observe.
func _scripted_run(seed_value: int) -> Array:
	var h := MatchHarness.new(seed_value)
	var log := []
	var a := h.server.open_session()
	var b := h.server.open_session()
	log.append(h.server.command(a, {"type": "noop"}))
	h.advance(1.0)
	log.append(h.server.snapshot(a))
	log.append(h.server.snapshot(b))
	log.append(h.server.take_events(a))
	log.append(h.server.take_events(b))
	return log
