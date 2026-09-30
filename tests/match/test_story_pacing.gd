extends TestCase

var h: MatchHarness
var sessions: Array[int] = []

func _start(sites: Dictionary = {}, humans: int = 1, story: bool = true) -> void:
	h = MatchHarness.new(3, MatchHarness.merge([MatchHarness.EASY, sites]))
	if story:
		h.server.allow_story = true
		var session = h.server.open_session()
		var room_resp = h.server.command(session, {"type": "create_room", "name": "Story", "story": true})
		var room = h.server._rooms[room_resp["code"]]
		sessions = [session]
		h.server.command(session, {"type": "start_match"})
	else:
		sessions = h.start_with_humans(humans)

func test_story_room_encounters_never_time_out() -> void:
	# Story room tests
	var sites := {"journey": {"sites": {
		"merchant": [{"id": "m1"}],
		"rest": [{"id": "r1"}],
		"class": [{"id": "c1", "classes": {"swordsman": 1}}],
		"story": [{"id": "s1", "name": "S1", "hint": "h"}]
	}}}
	
	_start(sites, 1, true)
	var run = h.server._rooms[h.server._sessions[sessions[0]]["room"]].run
	
	var clock = run.clock
	run.rng = GameRng.new(1)
	
	run.emit({"type": "layer_started", "layer": 1, "routes": ["story", "merchant", "rest", "class"]})
	run.phase = "encounter"
	
	var encounter_scripts = [
		preload("res://src/match/encounters/merchant_encounter.gd"),
		preload("res://src/match/encounters/rest_encounter.gd"),
		preload("res://src/match/encounters/class_encounter.gd"),
		preload("res://src/match/encounters/story_encounter.gd")
	]
	
	for script in encounter_scripts:
		var enc = script.new({"site": {"id": "test", "classes": {"swordsman": 1}}, "name": "test"})
		if enc.get_script().resource_path.ends_with("story_encounter.gd"):
			enc.start(run)
			clock.advance(600.0)
			enc.update(run)
			assert_false(enc.done, "Story vote should not time out")
			h.server.command(sessions[0], {"type": "vote", "option": 0})
			enc.update(run)
			clock.advance(600.0)
			enc.update(run)
			assert_false(enc.done, "Story read should not time out")
		elif enc.get_script().resource_path.ends_with("class_encounter.gd"):
			enc.start(run)
			enc.stage = "offer"
			enc.deadline = -1.0 if run.story else clock.now() + 10.0
			enc.eligible.clear()
			enc.eligible.append(0)
			clock.advance(600.0)
			enc.update(run)
			assert_false(enc.done, "Class offer should not time out in story mode")
		else:
			enc.start(run)
			clock.advance(600.0)
			enc.update(run)
			assert_false(enc.done, "%s should not time out in story mode" % script.resource_path)

func test_online_room_encounters_time_out() -> void:
	var sites := {"journey": {"sites": {
		"merchant": [{"id": "m1"}],
		"rest": [{"id": "r1"}],
		"class": [{"id": "c1", "classes": {"swordsman": 1}}],
		"story": [{"id": "s1", "name": "S1", "hint": "h"}]
	}}}
	
	_start(sites, 1, false)
	var run = h.server._rooms[h.server._sessions[sessions[0]]["room"]].run
	
	var clock = run.clock
	run.emit({"type": "layer_started", "layer": 1, "routes": ["story", "merchant", "rest", "class"]})
	run.phase = "encounter"
	
	var encounter_scripts = [
		preload("res://src/match/encounters/merchant_encounter.gd"),
		preload("res://src/match/encounters/rest_encounter.gd"),
		preload("res://src/match/encounters/class_encounter.gd"),
		preload("res://src/match/encounters/story_encounter.gd")
	]
	
	for script in encounter_scripts:
		var enc = script.new({"site": {"id": "test", "classes": {"swordsman": 1}}, "name": "test"})
		if enc.get_script().resource_path.ends_with("story_encounter.gd"):
			enc.start(run)
			clock.advance(600.0)
			enc.update(run)
			# Story choice resolves, moves to reading
			clock.advance(600.0)
			enc.update(run)
			assert_true(enc.done, "Story should time out in online mode")
		elif enc.get_script().resource_path.ends_with("class_encounter.gd"):
			enc.start(run)
			enc.stage = "offer"
			enc.deadline = -1.0 if run.story else clock.now() + 10.0
			enc.eligible.clear()
			enc.eligible.append(0)
			clock.advance(600.0)
			enc.update(run)
			assert_true(enc.done, "Class offer should time out in online mode")
		else:
			enc.start(run)
			clock.advance(600.0)
			enc.update(run)
			assert_true(enc.done, "%s should time out in online mode" % script.resource_path)

func test_story_class_choice_applies_to_correct_slot() -> void:
	var clock = preload("res://src/shared/manual_clock.gd").new()
	var forest = ForestContent.new()
	forest.data = {"journey": {"sites": {"class": [{"id": "c1", "classes": {"swordsman": 1, "archer": 1}}]}}}
	var run = MatchRun.new(GameRng.new(1), clock, forest, [true, true, true, true, true], 1, [], true, 0)
	run.party[2]["class"] = "classless"
	var enc = preload("res://src/match/encounters/class_encounter.gd").new({"site": {"id": "c1", "classes": {"swordsman": 1, "archer": 1}}, "name": "test"})
	enc.start(run)
	enc.stage = "offer"
	enc.eligible.clear()
	enc.eligible.append(0)
	enc.eligible.append(2)
	
	# Host makes class_choice for slot 2
	var resp = enc.handle(run, 2, {"type": "class_choice", "accept": true})
	assert_ok(resp)
	assert_eq(run.party[2]["class"], "swordsman")
	assert_eq(run.party[0]["class"], "classless")

func test_story_voters_and_ready_follow_story_host() -> void:
	var clock = preload("res://src/shared/manual_clock.gd").new()
	var forest = ForestContent.new()
	var run = MatchRun.new(GameRng.new(1), clock, forest, [true, true, true, true, true], 1, [], true, 2)
	var voters = run.voters()
	assert_false(voters[0])
	assert_true(voters[2])
	
	assert_false(run.needs_ready(0))
	assert_true(run.needs_ready(2))
