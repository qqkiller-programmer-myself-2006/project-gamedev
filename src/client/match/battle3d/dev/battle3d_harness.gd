extends SceneTree
## Stand-alone Battle3D harness (T3D-03): feeds a 5 vs N state and every cue to Battle3DStage.
##
##   godot --path . -s src/client/match/battle3d/dev/battle3d_harness.gd -- --enemies=4
##   options: --enemies=N (1-5)  --boss  --shots=<dir>  --size=WxH  --low  --reduced  --hold
## Windowed runs save one PNG per cue to --shots; `--headless` still plays every cue and checks
## for errors and leaked nodes. Prints "HARNESS OK" and perf numbers when finished.

const STEPS := [
	{"name": "00_idle", "cue": {}, "wait": 0.6},
	{"name": "01_strike", "cue": {"type": "strike", "actor": "p0", "target": "e0"}, "wait": 0.28},
	{"name": "02_strike_crit", "cue": {"type": "strike", "actor": "p1", "target": "e1", "crit": true}, "wait": 0.28},
	{"name": "03_skill", "cue": {"type": "skill", "actor": "p3", "target": "e0", "skill_id": "fireball"}, "wait": 0.3},
	{"name": "04_focus", "cue": {"type": "focus", "actor": "p2"}, "wait": 0.3},
	{"name": "05_item", "cue": {"type": "item", "actor": "p4", "target": "p0"}, "wait": 0.25},
	{"name": "06_guard", "cue": {"type": "guard", "actor": "p2"}, "wait": 0.3},
	{"name": "07_hurt", "cue": {"type": "hurt", "target": "p0", "amount": 6}, "wait": 0.15},
	{"name": "08_heal", "cue": {"type": "heal", "target": "p0", "amount": 5}, "wait": 0.3},
	{"name": "09_die", "cue": {"type": "die", "target": "e1"}, "wait": 1.0},
	{"name": "10_end", "cue": {}, "wait": 0.5},
]

class Markers extends Control:
	var stage: Battle3DStage
	func _draw() -> void:
		if stage == null:
			return
		for id in stage.unit_ids():
			var p := stage.unit_screen_position(id)
			draw_circle(p, 4.0, Color("#ffd400"))
			draw_string(ThemeDB.fallback_font, p + Vector2(6.0, -6.0), str(id), HORIZONTAL_ALIGNMENT_LEFT,
					-1.0, 14, Color.WHITE)
	func _process(_delta: float) -> void:
		queue_redraw()

var _stage: Battle3DStage
var _step := -1
var _elapsed := 0.0
var _shots_dir := ""
var _enemies := 4
var _boss := false
var _frames := 0
var _process_ms := 0.0
var _draw_calls_max := 0
var _nodes_before := 0
var _headless := false


func _initialize() -> void:
	var size_arg := Vector2i(1280, 720)
	var low := false
	var reduced := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--enemies="):
			_enemies = clampi(int(arg.get_slice("=", 1)), 1, Battle3DStage.MAX_ENEMIES)
		elif arg == "--boss":
			_boss = true
		elif arg.begins_with("--shots="):
			_shots_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--size="):
			var parts := arg.get_slice("=", 1).split("x")
			if parts.size() == 2:
				size_arg = Vector2i(int(parts[0]), int(parts[1]))
		elif arg == "--low":
			low = true
		elif arg == "--reduced":
			reduced = true
	_headless = DisplayServer.get_name() == "headless"
	root.size = size_arg
	_stage = Battle3DStage.new()
	root.add_child(_stage)
	_stage.set_quality(low)
	_stage.set_reduced_motion(reduced)
	var markers := Markers.new()
	markers.stage = _stage
	markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	markers.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(markers)
	_stage.apply_state(_state())
	if not _shots_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	_nodes_before = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))


func _process(delta: float) -> bool:
	_frames += 1
	if _frames > 5:
		_process_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		_draw_calls_max = maxi(_draw_calls_max, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	_elapsed += delta
	if _step < 0 or _elapsed >= float(STEPS[_step]["wait"]):
		if _step >= 0 and not _shots_dir.is_empty() and not _headless:
			_save(str(STEPS[_step]["name"]))
		_step += 1
		_elapsed = 0.0
		if _step >= STEPS.size():
			return _finish()
		var cue: Dictionary = STEPS[_step]["cue"]
		if not cue.is_empty():
			_stage.play_cue(cue)
	return false


func _finish() -> bool:
	var settled := 0
	while _stage.animating() and settled < 600:
		_stage.advance(0.05)
		settled += 1
	var measured := maxi(1, _frames - 5)
	print("HARNESS frames=%d avg_process_ms=%.3f max_draw_calls=%d nodes=%d->%d settled=%s" % [
		_frames, _process_ms / float(measured), _draw_calls_max, _nodes_before,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), str(not _stage.animating())])
	print("HARNESS OK")
	return true


func _save(shot_name: String) -> void:
	var image := root.get_texture().get_image()
	if image != null:
		image.save_png("%s/%s.png" % [_shots_dir, shot_name])


func _state() -> Dictionary:
	var units: Array = []
	var classes := ["swordsman", "guardian", "assassin", "mage", "archer"]
	for slot in 5:
		units.append({"id": "p%d" % slot, "side": "party", "slot": slot, "class_key": classes[slot],
				"name": "P%d" % slot, "hp": 30, "max_hp": 30, "energy": 1, "alive": true})
	for i in (1 if _boss else _enemies):
		units.append({"id": "e%d" % i, "side": "enemy", "slot": i, "class_key": "enemy", "name": "E%d" % i,
				"hp": 20, "max_hp": 20, "alive": true, "boss": _boss})
	return {"units": units, "current_actor": "p0", "mode": "targets", "targets": ["e0", "e1"]}
