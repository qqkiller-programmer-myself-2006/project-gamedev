extends "res://tests/test_case.gd"
## Battle3DStage anchors, state and cues (T3D-03). Runs without a SceneTree.

const CLASSES := ["swordsman", "guardian", "assassin", "mage", "archer"]
const SIZES := [Vector2(1280, 720), Vector2(800, 600), Vector2(360, 640), Vector2(1920, 500), Vector2(2560, 1440)]


func _state(enemy_count: int = 4, boss: bool = false) -> Dictionary:
	var units: Array = []
	for slot in 5:
		units.append({"id": "p%d" % slot, "side": "party", "slot": slot, "class_key": CLASSES[slot],
				"name": "P%d" % slot, "hp": 30, "max_hp": 30, "alive": true})
	for i in enemy_count:
		units.append({"id": "e%d" % i, "side": "enemy", "slot": i, "class_key": "enemy", "name": "E%d" % i,
				"hp": 20, "max_hp": 20, "alive": true, "boss": boss})
	return {"units": units, "current_actor": "p0", "mode": "command", "targets": []}


func _stage(enemy_count: int = 4, size: Vector2 = Vector2(1280, 720)) -> Battle3DStage:
	var stage := Battle3DStage.new()
	stage.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stage.size = size
	stage.apply_state(_state(enemy_count))
	return stage


func test_five_party_and_up_to_five_enemies_are_spawned() -> void:
	for count in [1, 3, 5, 8]:
		var stage := _stage(count)
		assert_eq(stage.unit_ids().size(), 5 + mini(count, Battle3DStage.MAX_ENEMIES), "5 vs %d" % count)
		stage.free()


func test_anchors_are_inside_view_for_every_size_and_party_is_left() -> void:
	for size in SIZES:
		var stage := _stage(5, size)
		var view := Rect2(Vector2.ZERO, size)
		for id in stage.unit_ids():
			var anchor := stage.unit_screen_position(id)
			assert_true(view.has_point(anchor), "%s anchor %s inside %s" % [id, anchor, size])
			assert_true(view.has_point(stage.unit_head_screen_position(id)), "%s head inside %s" % [id, size])
		for p in 5:
			for e in 5:
				assert_true(stage.unit_screen_position("p%d" % p).x < stage.unit_screen_position("e%d" % e).x,
						"party p%d is left of e%d at %s" % [p, e, size])
		stage.free()


func test_anchor_follows_resize_and_unknown_id_is_flagged() -> void:
	var stage := _stage(4)
	var small := stage.unit_screen_position("p0")
	stage.size = Vector2(2560, 1440)
	var large := stage.unit_screen_position("p0")
	assert_true(large.x > small.x and large.y > small.y, "anchor scales with the control size")
	assert_eq(stage.unit_screen_position("nope"), Battle3DStage.NO_ANCHOR)
	assert_false(stage.has_unit("nope"))
	stage.free()


func test_state_updates_remove_units_and_mark_down() -> void:
	var stage := _stage(4)
	var state := _state(2)
	state["units"][1]["alive"] = false
	stage.apply_state(state)
	assert_eq(stage.unit_ids().size(), 7)
	assert_false(stage.has_unit("e3"))
	assert_false(stage.is_unit_alive("p1"))
	assert_true(stage.is_unit_alive("p0"))
	state["units"][1]["alive"] = true
	stage.apply_state(state)
	assert_true(stage.is_unit_alive("p1"), "revived by state")
	stage.apply_state({"units": [{"id": ""}, 5, {"id": "p0", "side": "party", "slot": 99}]})
	assert_eq(stage.unit_ids(), ["p0"], "malformed units skipped, slot clamped")
	stage.free()


func test_every_cue_plays_settles_and_leaves_no_effects() -> void:
	var stage := _stage(4)
	var cues := [
		{"type": "strike", "actor": "p0", "target": "e0"},
		{"type": "skill", "actor": "p3", "target": "e1", "skill_id": "fireball"},
		{"type": "focus", "actor": "p2"},
		{"type": "item", "actor": "p4", "target": "p0"},
		{"type": "guard", "actor": "p1"},
		{"type": "hurt", "target": "p0", "amount": 4},
		{"type": "heal", "target": "p0", "amount": 4},
		{"type": "die", "target": "e2"},
		{"type": "strike", "actor": "ghost", "target": "nobody"},
		{"type": "unknown"},
		{},
	]
	for cue in cues:
		stage.play_cue(cue)
		for i in 60:
			stage.advance(0.02)
	for i in 200:
		stage.advance(0.05)
	assert_false(stage.animating(), "everything settles")
	assert_false(stage.is_unit_alive("e2"), "die cue leaves the unit down")
	assert_true(stage.is_unit_alive("e0"))
	stage.free()


func test_die_fall_survives_a_same_state_refresh_and_revive_resets() -> void:
	var stage := _stage(2)
	stage.play_cue({"type": "die", "target": "e0"})
	for i in 60:
		stage.advance(0.02)
	var state := _state(2)
	state["units"][5]["alive"] = false
	stage.apply_state(state)
	assert_false(stage.is_unit_alive("e0"))
	state["units"][5]["alive"] = true
	stage.apply_state(state)
	assert_true(stage.is_unit_alive("e0"))
	stage.free()


func test_strike_pushes_camera_in_and_crit_shakes() -> void:
	var stage := _stage(3)
	var rest := stage.camera_distance()
	stage.play_cue({"type": "strike", "actor": "p0", "target": "e0", "crit": true})
	for i in 22:
		stage.advance(0.02)
	assert_true(stage.camera_push_amount() > 0.3, "push-in during strike")
	assert_true(stage.camera_shake_amount() > 0.0, "shake on crit")
	var closer := stage.camera.position.distance_to(Battle3DStage.CAMERA_TARGET)
	assert_true(closer < rest, "camera moved toward the action (%s < %s)" % [closer, rest])
	for i in 200:
		stage.advance(0.05)
	assert_eq(stage.camera_push_amount(), 0.0)
	assert_eq(stage.camera_shake_amount(), 0.0)
	stage.free()


func test_reduced_motion_disables_drift_push_and_shake() -> void:
	var stage := _stage(3)
	stage.set_reduced_motion(true)
	var start := stage.camera.position
	stage.play_cue({"type": "strike", "actor": "p0", "target": "e0", "crit": true})
	for i in 30:
		stage.advance(0.05)
	assert_eq(stage.camera_shake_amount(), 0.0)
	assert_eq(stage.camera_push_amount(), 0.0)
	assert_true(stage.camera.position.is_equal_approx(start), "camera static under reduced motion")
	stage.free()


func test_idle_drift_moves_camera_unless_low_quality() -> void:
	var stage := _stage(3)
	var start := stage.camera.position
	for i in 20:
		stage.advance(0.1)
	assert_false(stage.camera.position.is_equal_approx(start), "idle drift")
	stage.set_quality(true)
	var low_start := stage.camera.position
	stage.advance(0.1)
	var after := stage.camera.position
	assert_true(low_start.distance_to(after) < 4.0)
	stage.free()


func test_narrow_windows_pull_the_camera_back() -> void:
	var wide := _stage(3, Vector2(1920, 1080))
	var narrow := _stage(3, Vector2(360, 640))
	assert_true(narrow.camera_distance() > wide.camera_distance())
	wide.free()
	narrow.free()


func test_pick_unit_round_trips_anchor_and_ignores_empty_space_and_downed() -> void:
	var stage := _stage(3)
	for id in stage.unit_ids():
		assert_eq(stage.pick_unit(stage.unit_screen_position(id)), id, "pick %s" % id)
	assert_eq(stage.pick_unit(Vector2(2.0, 2.0)), "")
	stage.play_cue({"type": "die", "target": "e1"})
	assert_ne(stage.pick_unit(stage.unit_screen_position("e1")), "e1", "downed units are not pickable")
	stage.free()


func test_click_emits_unit_clicked() -> void:
	var stage := _stage(3)
	var clicked: Array = []
	stage.unit_clicked.connect(func(id: String) -> void: clicked.append(id))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = stage.unit_screen_position("e2")
	stage._gui_input(press)
	assert_eq(clicked, ["e2"])
	press.position = Vector2(1.0, 1.0)
	stage._gui_input(press)
	assert_eq(clicked.size(), 1, "empty space emits nothing")
	stage.free()


func test_quality_toggle_hides_decor_and_shrinks_render() -> void:
	var stage := _stage(2)
	stage.set_quality(true)
	assert_true(stage.low_quality)
	assert_false(stage._decor_extra.visible)
	assert_eq(stage._container.stretch_shrink, 2)
	stage.set_quality(false)
	assert_true(stage._decor_extra.visible)
	assert_eq(stage._container.stretch_shrink, 1)
	stage.free()
