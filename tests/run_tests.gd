extends SceneTree
## Headless test runner (see docs/testing.md).
##
##   godot --headless --path . -s tests/run_tests.gd
##   godot --headless --path . -s tests/run_tests.gd -- --filter=voting
##
## Finds every tests/**/test_*.gd, runs each `test_*` method on a fresh
## instance and exits with code 0 when everything passed, 1 otherwise.
## `--filter=<text>` only runs tests whose "file::method" contains <text>.

const TEST_ROOT := "res://tests"


## Collects engine and script errors so a test that crashes (null access,
## bad operands, push_error...) is reported as failed instead of passing.
class ErrorCapture extends Logger:
	var _mutex := Mutex.new()
	var _errors: Array[String] = []

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		var text := code if rationale.is_empty() else "%s (%s)" % [rationale, code]
		_mutex.lock()
		_errors.append("%s:%d %s" % [file, line, text])
		_mutex.unlock()

	func take() -> Array[String]:
		_mutex.lock()
		var out := _errors.duplicate()
		_errors.clear()
		_mutex.unlock()
		return out


var _capture := ErrorCapture.new()


func _init() -> void:
	OS.add_logger(_capture)
	var filter := _read_filter()
	var files := _find_test_files(TEST_ROOT)
	files.sort()
	var passed := 0
	var failed := 0
	var started := Time.get_ticks_msec()
	for path in files:
		_capture.take()
		var script = load(path)
		var load_errors := _capture.take()
		if script == null or not script.can_instantiate() or not load_errors.is_empty():
			failed += 1
			_report_fail(path, "<load>", ["script failed to load"] + load_errors)
			continue
		for method in _test_methods(script):
			var test_id := "%s::%s" % [path.trim_prefix("res://"), method]
			if not filter.is_empty() and not test_id.contains(filter):
				continue
			var failures := _run_one(script, method)
			if failures.is_empty():
				passed += 1
				print("[PASS] %s" % test_id)
			else:
				failed += 1
				_report_fail(test_id, "", failures)
	var elapsed := (Time.get_ticks_msec() - started) / 1000.0
	print("")
	print("%d passed, %d failed (%.2fs)" % [passed, failed, elapsed])
	if passed + failed == 0:
		print("No tests matched.")
		failed = 1
	OS.remove_logger(_capture)
	quit(0 if failed == 0 else 1)


func _run_one(script: Script, method: String) -> Array[String]:
	_capture.take()
	var instance = script.new()
	if instance.has_method("before_each"):
		instance.before_each()
	instance.call(method)
	if instance.has_method("after_each"):
		instance.after_each()
	var failures: Array[String] = []
	failures.append_array(instance._failures)
	for error in _capture.take():
		failures.append("engine error: %s" % error)
	return failures


func _report_fail(test_id: String, suffix: String, failures: Array) -> void:
	print("[FAIL] %s%s" % [test_id, suffix])
	for failure in failures:
		print("       - %s" % failure)


func _test_methods(script: Script) -> Array[String]:
	var names: Array[String] = []
	for info in script.get_script_method_list():
		var name := str(info["name"])
		if name.begins_with("test_") and not names.has(name):
			names.append(name)
	return names


func _find_test_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub in dir.get_directories():
		found.append_array(_find_test_files(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			found.append(dir_path.path_join(file))
	return found


func _read_filter() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			return arg.trim_prefix("--filter=")
	return ""
