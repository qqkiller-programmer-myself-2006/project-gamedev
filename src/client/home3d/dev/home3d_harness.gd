extends SceneTree
## Standalone Home3D harness (not part of the game).
##   godot --path . -s src/client/home3d/dev/home3d_harness.gd -- [--scale=1.4] [--reduced] [--shot=path.png] [--walk]
## Without --shot it stays open: walk with WASD, interact with E / Enter.
## With --shot it saves the viewport after a few frames; --walk first walks to Story and interacts.

var _home: Home3D
var _shot := ""
var _frames := 0
var _walk := false


func _initialize() -> void:
	Tr.setup("th")
	var scale := 1.0
	var reduced := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scale="):
			scale = float(arg.trim_prefix("--scale="))
		elif arg == "--reduced":
			reduced = true
		elif arg.begins_with("--shot="):
			_shot = arg.trim_prefix("--shot=")
		elif arg == "--walk":
			_walk = true
	var settings := ClientSettings.new()
	settings.text_scale = scale
	settings.reduced_motion = reduced
	_home = Home3D.new()
	root.add_child(_home)
	_home.apply_settings(settings)
	_home.station_activated.connect(func(id: String) -> void: print("station_activated: %s" % id))
	if _walk:
		_home.teleport(_home.station_position("story") + Vector3(0.0, 0.0, 1.0))


func _process(_delta: float) -> bool:
	_frames += 1
	if _shot.is_empty():
		return false
	if _frames == 8 and _walk:
		_home.activate_nearest_station()
	if _frames >= 12:
		var image := root.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(_shot.get_base_dir())
		image.save_png(_shot)
		print("saved %s %s" % [_shot, image.get_size()])
		return true
	return false
