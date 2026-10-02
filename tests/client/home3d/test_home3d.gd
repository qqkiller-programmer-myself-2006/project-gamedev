extends TestCase

var _home: Home3D
var _emitted: Array[String] = []


func before_each() -> void:
	Tr.setup("en")
	_emitted.clear()
	_home = Home3D.new()
	_home.station_activated.connect(func(id: String) -> void: _emitted.append(id))


func after_each() -> void:
	if _home != null and is_instance_valid(_home):
		_home.free()
	_home = null


func test_scene_builds_with_six_stations() -> void:
	assert_true(_home.player is CharacterBody3D, "player is a CharacterBody3D")
	assert_true(_home.camera is Camera3D, "camera exists")
	assert_eq(Home3D.STATION_IDS, ["story", "battle", "party", "class", "shop", "settings"] as Array[String], "station ids")
	for id in Home3D.STATION_IDS:
		assert_true(_home.find_child("Station_%s" % id, true, false) != null, "marker for %s" % id)
		assert_true(_home.find_child("Name_%s" % id, true, false) != null, "name label for %s" % id)


func test_step_moves_player_and_normalizes_diagonals() -> void:
	var start := _home.player.position
	_home.step(Vector2(1.0, 0.0), 0.5)
	assert_true(absf((_home.player.position.x - start.x) - Home3D.WALK_SPEED * 0.5) < 0.001, "moves right at walk speed")
	_home.teleport(Vector3.ZERO)
	_home.step(Vector2(0.0, -1.0), 0.5)
	assert_true(_home.player.position.z < -2.0, "up moves toward -Z")
	_home.teleport(Vector3.ZERO)
	_home.step(Vector2(1.0, 1.0), 1.0)
	var moved := Vector2(_home.player.position.x, _home.player.position.z).length()
	assert_true(absf(moved - Home3D.WALK_SPEED) < 0.001, "diagonal speed equals straight speed")


func test_player_stays_inside_arena() -> void:
	_home.step(Vector2(-1.0, -1.0), 10.0)
	assert_true(_home.player.position.x >= -Home3D.ARENA_HALF.x, "left bound")
	assert_true(_home.player.position.z >= -Home3D.ARENA_HALF.y, "top bound")
	_home.step(Vector2(1.0, 1.0), 20.0)
	assert_true(_home.player.position.x <= Home3D.ARENA_HALF.x, "right bound")
	assert_true(_home.player.position.z <= Home3D.ARENA_HALF.y, "bottom bound")


func test_walking_into_range_then_interact_emits_id() -> void:
	assert_eq(_home.nearest_station(), "", "spawn is not near a station")
	assert_false(_home.activate_nearest_station(), "nothing to interact with at spawn")
	_home.teleport(_home.station_position("shop") + Vector3(Home3D.INTERACTION_RADIUS + 1.5, 0.0, 0.0))
	assert_eq(_home.nearest_station(), "", "outside the radius")
	_home.step(Vector2(-1.0, 0.0), 0.4)
	assert_eq(_home.nearest_station(), "shop", "walking in reaches the shop")
	assert_true(_home.handle_key(KEY_E), "E interacts")
	assert_eq(_emitted, ["shop"] as Array[String], "signal carries the station id")
	assert_false(_home.handle_key(KEY_Q), "other keys ignored")


func test_every_station_activates_with_its_own_id() -> void:
	for id in Home3D.STATION_IDS:
		_home.teleport(_home.station_position(id))
		assert_eq(_home.nearest_station(), id, "nearest at %s" % id)
		assert_true(_home.handle_key(KEY_ENTER), "Enter interacts at %s" % id)
	assert_eq(_emitted, Home3D.STATION_IDS, "ids emitted in order")


func test_disabled_station_does_not_emit() -> void:
	_home.set_stations_enabled(["story", "settings"])
	assert_true(_home.is_station_enabled("story"), "story enabled")
	assert_false(_home.is_station_enabled("battle"), "battle disabled")
	_home.teleport(_home.station_position("battle"))
	assert_false(_home.activate_nearest_station(), "disabled station refuses")
	_home.teleport(_home.station_position("story"))
	assert_true(_home.activate_nearest_station(), "enabled station works")
	assert_eq(_emitted, ["story"] as Array[String], "only story emitted")


func test_input_disabled_blocks_interaction() -> void:
	_home.teleport(_home.station_position("party"))
	_home.input_enabled = false
	assert_false(_home.activate_nearest_station(), "no interaction while input is disabled")
	assert_true(_emitted.is_empty(), "nothing emitted")


func test_camera_follows_and_reduced_motion_snaps() -> void:
	_home.reduced_motion = false
	_home.teleport(Vector3.ZERO)
	_home.player.position = Vector3(5.0, 0.0, 0.0)
	_home.update_camera(0.016)
	var eased := _home.camera_focus().x
	assert_true(eased > 0.0 and eased < 5.0, "camera eases toward the player")
	_home.reduced_motion = true
	_home.update_camera(0.016)
	assert_true(absf(_home.camera_focus().x - 5.0) < 0.001, "reduced motion snaps the camera")
	assert_true(absf(_home.camera.position.x - 5.0) < 0.001, "camera node follows focus")


func test_text_scale_applies_theme() -> void:
	_home.set_text_scale(1.4)
	assert_true(_home.theme != null, "theme set")
	assert_eq(_home.text_scale, 1.4, "scale stored")
