extends TestCase
## Guards the rule that game logic never uses the engine's randomness or
## wall-clock directly: everything goes through the injected GameRng and clock.

const GAME_LOGIC_DIRS := ["res://src/match", "res://src/core"]
const RNG_SOURCE := "res://src/core/game_rng.gd"
const CLOCK_SOURCE := "res://src/core/system_clock.gd"


func test_game_logic_uses_only_injected_randomness() -> void:
	var forbidden := RegEx.create_from_string(
		"(?<![.\\w])(randi|randf|randf_range|randi_range|randfn|randomize|seed)\\s*\\(" +
		"|RandomNumberGenerator|\\.shuffle\\s*\\(|\\.pick_random\\s*\\(")
	for path in _game_logic_files():
		if path == RNG_SOURCE:
			continue
		for hit in _matches(path, forbidden):
			fail("%s uses engine randomness: %s" % [path, hit])


func test_game_logic_uses_only_injected_clock() -> void:
	var forbidden := RegEx.create_from_string("Time\\.get_(ticks|unix|datetime|time)|OS\\.get_ticks")
	for path in _game_logic_files():
		if path == CLOCK_SOURCE:
			continue
		for hit in _matches(path, forbidden):
			fail("%s reads the wall clock: %s" % [path, hit])


func _matches(path: String, regex: RegEx) -> Array[String]:
	var hits: Array[String] = []
	var lines := FileAccess.get_file_as_string(path).split("\n")
	for i in lines.size():
		var line := lines[i]
		var code := line.split("#")[0]
		if regex.search(code) != null:
			hits.append("line %d: %s" % [i + 1, line.strip_edges()])
	return hits


func _game_logic_files() -> Array[String]:
	var files: Array[String] = []
	for dir in GAME_LOGIC_DIRS:
		files.append_array(_gd_files(dir))
	assert_false(files.is_empty(), "found game logic files")
	return files


func _gd_files(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for sub in dir.get_directories():
		out.append_array(_gd_files(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
	return out
