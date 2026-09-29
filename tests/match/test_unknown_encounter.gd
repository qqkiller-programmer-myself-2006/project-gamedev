extends TestCase
## Route data with an Encounter type the game does not support fails fast
## at the Match boundary instead of counting as a completed Encounter
## (issue #41). Match interface only.

var h: MatchHarness
var sessions: Array[int] = []


func _start(types: Array) -> void:
	h = MatchHarness.new(3, MatchHarness.merge([MatchHarness.only_routes(types), MatchHarness.EXACT_DAMAGE,
			MatchHarness.WOLF_PAIR]))
	sessions = h.start_with_humans(1)
	h.server.take_events(sessions[0])


func _view() -> Dictionary:
	return h.match_view(sessions[0])


func test_a_supported_encounter_starts_normally() -> void:
	_start(["combat", "mystery"])
	h.take_route(sessions, "combat")
	var events := h.server.take_events(sessions[0])
	var view := _view()
	assert_eq(view["phase"], "encounter")
	assert_eq(view["encounter"]["type"], "combat")
	assert_eq(events.filter(func(e): return e["type"] == "match_error"), [])


func test_the_route_offers_the_unsupported_type_as_data() -> void:
	_start(["combat", "mystery"])
	var types := []
	for option in _view()["vote"]["options"]:
		types.append(option["type"])
	assert_has(types, "mystery")


func test_entering_an_unsupported_encounter_ends_the_match_with_an_error_naming_it() -> void:
	_start(["mystery"])
	h.take_route(sessions, "mystery")
	var events := h.server.take_events(sessions[0])
	var errors := events.filter(func(e): return e["type"] == "match_error")
	assert_eq(errors.size(), 1)
	assert_eq(errors[0]["error"], "unsupported_encounter")
	assert_eq(errors[0]["encounter_type"], "mystery")
	assert_eq(errors[0]["layer"], 1)
	var ended := events.filter(func(e): return e["type"] == "match_ended")
	assert_eq(ended.size(), 1)
	assert_eq(ended[0]["result"], "defeat", "a broken route is never a win")
	assert_eq(ended[0]["summary"]["error"], "unsupported_encounter")
	assert_eq(ended[0]["summary"]["encounter_type"], "mystery")
	var view := _view()
	assert_eq(view["phase"], "defeat")
	assert_eq(view["encounter"], null)
	assert_eq(view["summary"]["encounter_type"], "mystery")


func test_an_unsupported_encounter_is_never_reported_as_completed() -> void:
	_start(["mystery"])
	h.take_route(sessions, "mystery")
	h.advance(10.0)
	var types := []
	for event in h.server.take_events(sessions[0]):
		types.append(event["type"])
	assert_not_has(types, "encounter_started")
	assert_not_has(types, "encounter_completed")
	var view := _view()
	assert_eq(view["phase"], "defeat")
	assert_eq(view["layer"], 1, "the journey did not move on")
	assert_eq(view["summary"]["layer"], 1)


func test_the_match_stays_finished_after_the_error() -> void:
	_start(["mystery"])
	h.take_route(sessions, "mystery")
	assert_rejected(h.server.command(sessions[0], {"type": "vote", "option": 0}), "wrong_phase")
	assert_rejected(h.server.command(sessions[0], {"type": "ready"}), "wrong_phase")


func test_the_error_code_has_player_text() -> void:
	assert_true(UiText.ERRORS.has("unsupported_encounter"))
