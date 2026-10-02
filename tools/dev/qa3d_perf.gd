extends SceneTree
## QA 3D Performance & Benchmark Harness (T3D-05)
## Measures FPS, frame times (min, avg, max, p95, p99, 1% low), draw calls,
## memory usage, and boot time for 2D baseline and 3D vertical slice scenes.
##
## Usage:
##   godot --path . -s tools/dev/qa3d_perf.gd
##   godot --path . -s tools/dev/qa3d_perf.gd -- --frames=300 --warmup=30
##   godot --path . -s tools/dev/qa3d_perf.gd -- --scene=res://src/client/home3d/home3d.tscn
##   godot --path . -s tools/dev/qa3d_perf.gd -- --out=build/perf_baseline.json
##   godot --headless --path . -s tools/dev/qa3d_perf.gd -- --quiet

var target_scene_path := ""
var frame_count := 180
var warmup_frames := 30
var out_path := ""
var quiet := false

var _frame := 0
var _boot_time_ms := 0.0
var _app_ready_ms := 0.0
var _frame_times: Array[float] = []
var _draw_calls: Array[int] = []
var _objects: Array[int] = []
var _primitives: Array[int] = []
var _fps_samples: Array[float] = []
var _scene_instance: Node = null


func _initialize() -> void:
	_boot_time_ms = float(Time.get_ticks_msec())
	_parse_arguments()

	if not target_scene_path.is_empty():
		if ResourceLoader.exists(target_scene_path):
			var packed: PackedScene = load(target_scene_path)
			if packed != null:
				_scene_instance = packed.instantiate()
				root.add_child(_scene_instance)
			else:
				printerr("qa3d_perf: failed to instantiate scene: ", target_scene_path)
		else:
			printerr("qa3d_perf: target scene does not exist: ", target_scene_path)

	if _scene_instance == null:
		# Default fallback: benchmark the client application
		var client_app := ClientApp.new()
		client_app.name = "ClientApp"
		client_app.configure({"name": "PerfTester", "lang": "en"})
		_scene_instance = client_app
		root.add_child(client_app)

	_app_ready_ms = float(Time.get_ticks_msec())


func _process(delta: float) -> bool:
	_frame += 1

	# Skip warmup frames to let shaders compile and nodes settle
	if _frame <= warmup_frames:
		return false

	# Record frame metrics
	var frame_ms := delta * 1000.0
	_frame_times.append(frame_ms)

	var current_fps := Performance.get_monitor(Performance.TIME_FPS)
	_fps_samples.append(current_fps)

	var dc := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_draw_calls.append(dc)

	var objs := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_objects.append(objs)

	var prims := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_primitives.append(prims)

	if _frame_times.size() >= frame_count:
		_finish_and_report()
		quit(0)
		return true

	return false


func _finish_and_report() -> void:
	var total_frames := _frame_times.size()
	if total_frames == 0:
		printerr("qa3d_perf: no frames sampled")
		quit(1)
		return

	var sorted_times: Array[float] = _frame_times.duplicate()
	sorted_times.sort()

	var sum_ms := 0.0
	for t in sorted_times:
		sum_ms += t

	var avg_ms := sum_ms / float(total_frames)
	var min_ms := sorted_times[0]
	var max_ms := sorted_times[total_frames - 1]
	var p50_ms := sorted_times[int(round(float(total_frames - 1) * 0.50))]
	var p95_ms := sorted_times[int(round(float(total_frames - 1) * 0.95))]
	var p99_ms := sorted_times[int(round(float(total_frames - 1) * 0.99))]

	var total_duration_sec := sum_ms / 1000.0
	var avg_fps := float(total_frames) / total_duration_sec if total_duration_sec > 0.0 else 0.0
	var min_fps := (1000.0 / max_ms) if max_ms > 0.0 else 0.0
	var max_fps := (1000.0 / min_ms) if min_ms > 0.0 else 0.0
	var fps_1percent_low := (1000.0 / p99_ms) if p99_ms > 0.0 else 0.0

	var avg_draw_calls := _average_int(_draw_calls)
	var max_draw_calls := _max_int(_draw_calls)
	var avg_objects := _average_int(_objects)
	var avg_primitives := _average_int(_primitives)

	var mem_static_bytes := Performance.get_monitor(Performance.MEMORY_STATIC)
	var mem_static_max_bytes := Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
	var mem_static_mb := mem_static_bytes / (1024.0 * 1024.0)
	var mem_static_max_mb := mem_static_max_bytes / (1024.0 * 1024.0)

	var report: Dictionary = {
		"status": "ok",
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"environment": {
			"os": OS.get_name(),
			"godot_version": Engine.get_version_info().get("string", "unknown"),
			"display_driver": DisplayServer.get_name(),
			"rendering_device": RenderingServer.get_video_adapter_name() if DisplayServer.get_name() != "headless" else "headless",
			"rendering_method": ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility"),
			"window_size": "%dx%d" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y]
		},
		"test_config": {
			"target_scene": target_scene_path if not target_scene_path.is_empty() else "ClientApp (Default 2D)",
			"frames_sampled": total_frames,
			"warmup_frames": warmup_frames,
			"duration_seconds": snapped(total_duration_sec, 0.001)
		},
		"boot_metrics": {
			"boot_time_engine_ms": _boot_time_ms,
			"boot_time_ready_ms": _app_ready_ms,
			"time_to_ready_ms": snapped(_app_ready_ms - _boot_time_ms, 0.1)
		},
		"fps_metrics": {
			"fps_average": snapped(avg_fps, 0.1),
			"fps_min": snapped(min_fps, 0.1),
			"fps_max": snapped(max_fps, 0.1),
			"fps_1percent_low": snapped(fps_1percent_low, 0.1)
		},
		"frame_time_ms": {
			"avg": snapped(avg_ms, 0.2),
			"min": snapped(min_ms, 0.2),
			"max": snapped(max_ms, 0.2),
			"p50": snapped(p50_ms, 0.2),
			"p95": snapped(p95_ms, 0.2),
			"p99": snapped(p99_ms, 0.2)
		},
		"rendering_metrics": {
			"draw_calls_avg": avg_draw_calls,
			"draw_calls_max": max_draw_calls,
			"objects_avg": avg_objects,
			"primitives_avg": avg_primitives
		},
		"memory_metrics_mb": {
			"static_current": snapped(mem_static_mb, 0.2),
			"static_peak": snapped(mem_static_max_mb, 0.2)
		}
	}

	var json_str := JSON.stringify(report, "  ")

	if not quiet:
		print(json_str)

	if not out_path.is_empty():
		var dir := out_path.get_base_dir()
		if not dir.is_empty() and not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		var file := FileAccess.open(out_path, FileAccess.WRITE)
		if file != null:
			file.store_string(json_str)
			file.close()
			if not quiet:
				print("qa3d_perf: output saved to ", out_path)
		else:
			printerr("qa3d_perf: failed to write output file: ", out_path)


func _average_int(arr: Array) -> int:
	if arr.is_empty():
		return 0
	var sum: int = 0
	for val in arr:
		sum += int(val)
	return int(round(float(sum) / float(arr.size())))


func _max_int(arr: Array) -> int:
	if arr.is_empty():
		return 0
	var m: int = int(arr[0])
	for val in arr:
		var v := int(val)
		if v > m:
			m = v
	return m


func _parse_arguments() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frames="):
			frame_count = int(arg.trim_prefix("--frames="))
		elif arg.begins_with("--warmup="):
			warmup_frames = int(arg.trim_prefix("--warmup="))
		elif arg.begins_with("--scene="):
			target_scene_path = arg.trim_prefix("--scene=")
		elif arg.begins_with("--out="):
			out_path = arg.trim_prefix("--out=")
		elif arg == "--quiet":
			quiet = true
