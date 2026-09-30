extends TestCase
## Ready check at the Merchant and the Rest camp (issue #43, ADR-0011):
## AI slots never block, disconnected humans count as Ready, and the
## Ready (x/N) numbers in snapshots and events match the human state.
## Every scenario runs for both camps. Match interface only.

var h: MatchHarness
var sessions: Array[int] = []
var kind := ""


func _camp(camp: String, humans: int) -> void:
	kind = camp
	h = MatchHarness.new(3, MatchHarness.merge([MatchHarness.only_routes([camp, "combat"]),
			MatchHarness.EXACT_DAMAGE, MatchHarness.WOLF_PAIR]))
	sessions = h.start_with_humans(humans)
	h.take_route(sessions, camp)
	h.server.take_events(sessions[0])


func _view(index: int = 0) -> Dictionary:
	return h.match_view(sessions[index])


func _encounter(index: int = 0) -> Dictionary:
	var encounter = _view(index).get("encounter")
	return encounter if encounter != null else {}


func _ready(index: int) -> Dictionary:
	return h.server.command(sessions[index], {"type": "ready"})


## [ready, humans] as the camp shows them to the player at `index`.
func _count(index: int = 0) -> Array:
	var encounter := _encounter(index)
	return [encounter["ready_count"], encounter["humans"]]


func _ready_events(index: int = 0) -> Array:
	return h.server.take_events(sessions[index]).filter(func(e): return e["type"] == kind + "_ready")


func _moved_on() -> bool:
	return _view()["layer"] == 2 and _view()["phase"] == "voting"


func test_single_player_leaves_without_any_ai_ready() -> void:
	for camp in ["merchant", "rest"]:
		_camp(camp, 1)
		assert_eq(_encounter()["kind"], camp)
		assert_eq(_count(), [0, 1], "%s: only the human counts" % camp)
		assert_ok(_ready(0), camp)
		assert_true(_moved_on(), "%s: one Ready is enough with four AI slots" % camp)


func test_single_player_ready_event_counts_one_of_one() -> void:
	for camp in ["merchant", "rest"]:
		_camp(camp, 1)
		_ready(0)
		var events := _ready_events()
		assert_eq(events.size(), 1, camp)
		assert_eq([events[0]["slot"], events[0]["ready"], events[0]["humans"]], [0, 1, 1], camp)


func test_coop_advances_only_when_every_connected_human_is_ready() -> void:
	for camp in ["merchant", "rest"]:
		_camp(camp, 3)
		assert_eq(_count(2), [0, 3], "%s: Ready (0/3)" % camp)
		assert_ok(_ready(0))
		assert_eq(_count(2), [1, 3], "%s: every player sees 1/3" % camp)
		assert_ok(_ready(2))
		assert_eq(_count(1), [2, 3], "%s: 2/3" % camp)
		assert_eq(_view()["phase"], "encounter", "%s: two of three is not enough" % camp)
		assert_ok(_ready(1))
		assert_true(_moved_on(), "%s: all three Ready" % camp)


func test_ready_events_carry_the_running_count() -> void:
	for camp in ["merchant", "rest"]:
		_camp(camp, 3)
		_ready(1)
		_ready(0)
		var events := _ready_events(2)
		assert_eq(events.size(), 2, camp)
		assert_eq([events[0]["slot"], events[0]["ready"], events[0]["humans"]], [1, 1, 3], camp)
		assert_eq([events[1]["slot"], events[1]["ready"], events[1]["humans"]], [0, 2, 3], camp)


func test_a_disconnected_human_counts_as_ready() -> void:
	for camp in ["merchant", "rest"]:
		_camp(camp, 3)
		assert_ok(_ready(0))
		h.server.close_session(sessions[1])
		assert_eq(_count(0), [1, 2], "%s: the dropped player is no longer waited for" % camp)
		assert_eq(_view()["phase"], "encounter", "%s: the third human is still out" % camp)
		assert_ok(_ready(2))
		assert_true(_moved_on(), "%s: connected humans are all Ready" % camp)


func test_the_last_human_dropping_closes_the_camp() -> void:
	for camp in ["merchant", "rest"]:
		_camp(camp, 2)
		assert_ok(_ready(0))
		h.server.close_session(sessions[1])
		assert_true(_moved_on(), "%s: nobody left to wait for" % camp)


func test_a_ready_human_who_drops_is_not_counted_twice() -> void:
	for camp in ["merchant", "rest"]:
		_camp(camp, 3)
		assert_ok(_ready(1))
		h.server.close_session(sessions[1])
		var encounter := _encounter(0)
		assert_eq(_count(0), [0, 2], "%s: 0/2, the AI that took over is not a Ready human" % camp)
		assert_eq(encounter["ready"], [], camp)
		assert_ok(_ready(0))
		assert_eq(_count(2), [1, 2], camp)
		assert_ok(_ready(2))
		assert_true(_moved_on(), camp)


func test_duplicate_ready_keeps_its_deterministic_error() -> void:
	for camp in ["merchant", "rest"]:
		_camp(camp, 2)
		assert_ok(_ready(0))
		_ready_events()
		assert_rejected(_ready(0), "already_ready", camp)
		assert_rejected(_ready(0), "already_ready", camp)
		assert_eq(_count(1), [1, 2], "%s: the count did not move" % camp)
		assert_eq(_ready_events(), [], "%s: no event for a rejected Ready" % camp)
		assert_eq(_view()["phase"], "encounter", camp)


func test_ready_outside_a_camp_is_wrong_phase() -> void:
	h = MatchHarness.new(3, MatchHarness.merge([MatchHarness.only_routes(["combat"]), MatchHarness.EXACT_DAMAGE,
			MatchHarness.WOLF_PAIR]))
	sessions = h.start_with_humans(1)
	assert_rejected(_ready(0), "wrong_phase", "voting")
	h.take_route(sessions, "combat")
	assert_rejected(_ready(0), "wrong_phase", "combat")
