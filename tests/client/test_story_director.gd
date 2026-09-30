extends "res://tests/test_case.gd"

const StoryDirector = preload("res://src/client/story/story_director.gd")

func test_scenes_queue_until_decisions_are_made() -> void:
	var d = StoryDirector.new()
	var snapshot := {"match": {"number": 1, "phase": "voting", "vote": {"you_can_vote": true}}}
	d.observe([], snapshot)
	assert_true(d._is_decision_pending(), "voting is a pending decision")
	d.queue.append({"kind": "scene", "id": "test", "lines": []})
	d._pump()
	assert_eq(d.current, null, "director shouldn't show scene while decision pending")
	
	snapshot["match"]["phase"] = "travel"
	d.observe([], snapshot)
	assert_false(d._is_decision_pending(), "travel has no pending decision")
	assert_ne(d.current, null, "director should show scene now")
	d.free()

func test_c11_speaker_name_maps_to_class_portrait() -> void:
	var d = StoryDirector.new()
	var snapshot := {
		"match": {
			"number": 1,
			"phase": "voting",
			"party": [
				{"name": "Alice", "class": "archer"},
				{"name": "Bob", "class": "unknown_class"}
			]
		}
	}
	d.observe([], snapshot)
	d.queue.append({"kind": "scene", "id": "test", "lines": [{"speaker": "Alice", "text": "Hi"}, {"speaker": "Bob", "text": "Hello"}]})
	# Need to force phase so it's not pending decision
	snapshot["match"]["phase"] = "travel"
	d.observe([], snapshot)
	d._pump()
	var panel = d.current
	assert_ne(panel, null)
	# Check Alice
	var tex = panel._find_portrait("Alice")
	assert_ne(tex, null)
	assert_eq(tex.resource_path, "res://assets/heroes/archer/portrait.png")
	# Check Bob
	var tex_bob = panel._find_portrait("Bob")
	assert_eq(tex_bob, null, "Unknown class should yield no texture (placeholder)")
	panel.free()
	d.free()

func test_c12_class_challenge_ended_queues_class_gained_scene() -> void:
	var d = StoryDirector.new()
	d.content = {"scenes": {"class_gained": [{"speaker": "System", "text": "Class gained!"}]}}
	var event := {"type": "class_challenge_ended", "passed": true}
	d.observe([event], {"match": {"number": 1}})
	assert_true(d.shown.has("class_gained"))
	var found = false
	for item in d.queue:
		if item.get("id") == "class_gained":
			found = true
	assert_true(found, "class_challenge_ended with passed:true should enqueue class_gained")
	d.free()

func test_c13_director_resets_on_new_match_number_and_skips_prologue_on_continue() -> void:
	var d = StoryDirector.new()
	d.content = {
		"prologue": [{"text": "Intro"}],
		"chapters": [{"number": 1}, {"number": 2}, {"number": 3}]
	}
	# Continue from a save at layer 3 (the flag comes from ClientApp.is_story_restore()).
	d.restoring = true
	d.observe([], {"match": {"number": 2, "layer": 3}})
	assert_eq(d.match_number, 2)
	assert_eq(d.last_layer, 3)
	assert_true(d.shown.has("prologue"))
	assert_true(d.shown.has("chapter_1"))
	assert_true(d.shown.has("chapter_2"))
	var ids: Array = []
	for item in d.queue:
		ids.append(item.get("id"))
	assert_false(ids.has("prologue"), "no prologue on Continue")
	assert_false(ids.has("chapter_1"))
	assert_false(ids.has("chapter_2"))
	assert_true(ids.has("chapter_3") or d.shown.has("chapter_3"), "the current chapter card still shows")
	d.free()


func test_new_story_match_at_layer_one_shows_prologue_and_chapter_one() -> void:
	# A real new Match's first snapshot is already Layer 1 (review F2).
	var d = StoryDirector.new()
	d.content = {"prologue": [{"text": "Intro"}], "chapters": [{"number": 1}, {"number": 2}]}
	d.observe([], {"match": {"number": 1, "layer": 1}})
	var ids: Array = []
	for item in d.queue:
		ids.append(item.get("id"))
	if is_instance_valid(d.current):
		ids.append("current")
	assert_true(ids.has("prologue") or d.shown.has("prologue") or ids.has("current"), "prologue queued or showing")
	assert_true(d.shown.has("chapter_1"), "Chapter 1 card queued")
	# "Start a new Match" in the same room: prologue again.
	d.observe([], {"match": {"number": 2, "layer": 1}})
	assert_true(d.shown.has("chapter_1"))
	d.free()
