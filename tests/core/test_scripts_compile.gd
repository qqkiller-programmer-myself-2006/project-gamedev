extends TestCase
## Every script in the project parses and compiles, including client and
## server code that the Match tests never load.

const ROOTS := ["res://src", "res://tools"]


func test_every_script_compiles() -> void:
	var count := 0
	for root in ROOTS:
		for path in _scripts(root):
			var script = load(path)
			count += 1
			if script == null or not script.can_instantiate():
				fail("%s does not compile" % path)
	assert_true(count > 20, "found %d scripts" % count)


func _scripts(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for sub in dir.get_directories():
		out.append_array(_scripts(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
	return out
