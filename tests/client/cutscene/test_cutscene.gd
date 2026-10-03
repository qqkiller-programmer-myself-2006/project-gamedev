extends "res://tests/test_case.gd"

const RED := "res://assets/video/placeholder_red.ogv"
const BLUE := "res://assets/video/placeholder_blue.ogv"
const GREEN := "res://assets/video/placeholder_green.ogv"


func _graph() -> Dictionary:
	return {"start": "a", "nodes": {
		"a": {"clip": RED, "next": "b"},
		"b": {"clip": GREEN, "choices": [
			{"label": "one", "next": "c1", "flag": "x", "default": true},
			{"label": "two", "next": "c2", "flag": "y"}]},
		"c1": {"clip": BLUE, "variants": {"y": RED}},
		"c2": {"clip": BLUE},
	}}


func test_sample_cutscene_loads_and_is_valid() -> void:
	var loaded := CutsceneData.load_cutscene("sample")
	assert_true(loaded["ok"], "sample is valid: %s" % [loaded["errors"]])


func test_loader_reports_missing_file() -> void:
	var loaded := CutsceneData.load_cutscene("does_not_exist")
	assert_false(loaded["ok"])


func test_validation_errors() -> void:
	assert_false(CutsceneData.validate({}).is_empty(), "no nodes")
	assert_false(CutsceneData.validate({"start": "zzz", "nodes": {"a": {"clip": RED}}}).is_empty(), "unknown start")
	assert_false(CutsceneData.validate({"start": "a", "nodes": {"a": {"clip": "res://nope.ogv"}}}).is_empty(), "missing clip")
	assert_false(CutsceneData.validate({"start": "a", "nodes": {"a": {"clip": RED, "next": "zzz"}}}).is_empty(), "unknown next")
	var both := {"start": "a", "nodes": {"a": {"clip": RED, "next": "a", "choices": [{"next": "a"}]}}}
	assert_false(CutsceneData.validate(both).is_empty(), "next and choices together")
	var loop := {"start": "a", "nodes": {"a": {"clip": RED, "next": "b"}, "b": {"clip": RED, "next": "a"}}}
	assert_false(CutsceneData.validate(loop).is_empty(), "next cycle")
	var via_choice := {"start": "a", "nodes": {"a": {"clip": RED, "choices": [{"label": "again", "next": "a"}]}}}
	assert_true(CutsceneData.validate(via_choice).is_empty(), "cycle through choices is allowed")
	assert_true(CutsceneData.validate(_graph()).is_empty())


func test_router_linear_path() -> void:
	var router := CutsceneRouter.new({"start": "a", "nodes": {"a": {"clip": RED, "next": "b"}, "b": {"clip": BLUE}}})
	assert_eq(router.current_id, "a")
	assert_eq(router.clip(), RED)
	assert_true(router.advance())
	assert_eq(router.current_id, "b")
	assert_true(router.is_end())
	assert_false(router.advance())
	assert_true(router.finished)


func test_router_choice_sets_flag() -> void:
	var router := CutsceneRouter.new(_graph())
	router.advance()
	assert_true(router.has_choices())
	assert_false(router.advance(), "advance does nothing at a choice")
	assert_true(router.choose(1))
	assert_eq(router.current_id, "c2")
	assert_true(router.flags.get("y", false))
	assert_false(router.flags.has("x"))


func test_router_variant_by_flag() -> void:
	var router := CutsceneRouter.new(_graph())
	router.advance()
	router.choose(0)
	assert_eq(router.clip(), BLUE, "no flag y, base clip")
	var flagged := CutsceneRouter.new(_graph(), {"y": true})
	flagged.advance()
	flagged.choose(0)
	assert_eq(flagged.clip(), RED, "initial flag y selects the variant")


func test_router_skip_all_applies_defaults() -> void:
	var router := CutsceneRouter.new(_graph())
	var flags := router.skip_all()
	assert_true(router.finished)
	assert_true(flags.get("x", false), "default choice flag applied")
	assert_false(flags.has("y"))


func test_router_skip_all_terminates_on_choice_loop() -> void:
	var data := {"start": "a", "nodes": {"a": {"clip": RED, "choices": [{"label": "again", "next": "a"}]}}}
	var router := CutsceneRouter.new(data)
	router.skip_all()
	assert_true(router.finished)


func test_player_missing_clip_uses_subtitle_card() -> void:
	var data := {"start": "a", "nodes": {"a": {"clip": "res://assets/video/gone.ogv", "duration": 2.0,
			"subtitles": [{"t": 0.0, "text": "สวัสดี"}]}}}
	var player := CutscenePlayer.new(data)
	var flags_seen: Array = []
	player.finished.connect(func(flags): flags_seen.append(flags))
	player._enter_node()
	assert_true(player.using_fallback)
	assert_eq(player._subtitle.text, "สวัสดี")
	player._process(1.0)
	assert_true(flags_seen.is_empty(), "still showing the card")
	player._process(1.5)
	assert_eq(flags_seen.size(), 1, "card ends after its duration")


func test_player_choice_and_skip() -> void:
	var data := _graph()
	for id in data["nodes"]:
		data["nodes"][id]["clip"] = "res://assets/video/gone.ogv"
		data["nodes"][id]["duration"] = 0.5
	var player := CutscenePlayer.new(data)
	var results: Array = []
	player.finished.connect(func(flags): results.append(flags))
	player._enter_node()
	player._process(0.6)
	assert_eq(player.router.current_id, "b")
	player._process(0.6)
	assert_true(player._choice_box.visible, "choices shown at the end of the choice clip")
	player._move_choice(1)
	player.choose(player._choice_index)
	assert_eq(player.router.current_id, "c2")
	player._process(0.6)
	assert_eq(results.size(), 1)
	assert_true(results[0].get("y", false))

	var skipped := CutscenePlayer.new(data)
	var skipped_flags: Array = []
	skipped.finished.connect(func(flags): skipped_flags.append(flags))
	skipped._enter_node()
	skipped.skip()
	assert_eq(skipped.router.current_id, "b", "first skip ends the current clip only")
	skipped.skip()
	assert_eq(skipped_flags.size(), 1, "second skip within the window ends the cutscene")
	assert_true(skipped_flags[0].get("x", false), "default flags applied")


func test_player_text_scale_keeps_subtitles_inside_view() -> void:
	var player := CutscenePlayer.new({"start": "a", "nodes": {"a": {"clip": RED}}}, {}, 1.4)
	player.set_anchors_preset(Control.PRESET_TOP_LEFT)
	player.size = Vector2(1280, 720)
	player._layout()
	var bottom := player._subtitle.position.y + player._subtitle.size.y
	assert_true(bottom <= player._hint.position.y, "subtitle area sits above the hint")
	assert_true(player._subtitle.position.y >= 0.0)
	player.free()


func test_story_director_plays_cutscene_entry_and_continues() -> void:
	var director := StoryDirector.new()
	director.content = {"scenes": {"after": [{"speaker": "narrator", "text": "next"}]}}
	director.text_scale = 1.0
	var finished_ids: Array = []
	director.presentation_finished.connect(func(item): finished_ids.append(item.get("id")))
	director.queue.append({"kind": "cutscene", "id": "sample"})
	director.queue.append({"kind": "scene", "id": "after", "lines": director.content["scenes"]["after"]})
	director._pump()
	assert_true(director.current is CutscenePlayer, "cutscene entry creates the player")
	var player: CutscenePlayer = director.current
	player.skip_all()
	assert_true(finished_ids.has("sample"))
	assert_true(director.cutscene_flags.has("stay"), "default flag reported to the director")
	assert_true(director.current is DialoguePanel, "queue continues with the next entry")
	director.current.free()
	director.free()


func test_story_director_skips_broken_cutscene() -> void:
	var director := StoryDirector.new()
	director.queue.append({"kind": "cutscene", "id": "does_not_exist"})
	director._pump()
	assert_eq(director.current, null)
	assert_true(director.queue.is_empty())
	director.free()
