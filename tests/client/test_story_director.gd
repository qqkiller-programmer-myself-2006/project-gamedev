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
	# Start match 1
	d.observe([], {"match": {"number": 1, "layer": 0}})
	d.last_layer = 1
	
	# Reset to match 2, continue at layer 3
	d.observe([], {"match": {"number": 2, "layer": 3}})
	assert_eq(d.match_number, 2)
	assert_eq(d.last_layer, 3)
	assert_true(d.shown.has("prologue"))
	assert_true(d.shown.has("chapter_1"))
	assert_true(d.shown.has("chapter_2"))
	
	# Verify prologue and old chapters are NOT in queue
	for item in d.queue:
		assert_ne(item.get("id"), "prologue")
		assert_ne(item.get("id"), "chapter_1")
		assert_ne(item.get("id"), "chapter_2")
	d.free()
