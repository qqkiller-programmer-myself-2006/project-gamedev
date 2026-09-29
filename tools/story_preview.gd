extends SceneTree

const DialoguePanelScript = preload("res://src/client/story/dialogue_panel.gd")
const ChapterCardScript = preload("res://src/client/story/chapter_card.gd")

var out_dir := "build/story"
var scale := 1.0
var interactive := false
var reduced := true
var frame := 0
var stage := 0
var panel: Control

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--scale="): scale = float(arg.trim_prefix("--scale="))
		elif arg == "--interactive": interactive = true
		elif arg == "--reduced-motion": reduced = true
	DirAccess.make_dir_recursive_absolute(out_dir)
	var bg := ColorRect.new()
	bg.color = Color("101624")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://content/story_mode.json"))
	panel = DialoguePanelScript.new(data["prologue"], scale, reduced)
	root.add_child(panel)
	panel.finished.connect(_next)
	await process_frame
	await RenderingServer.frame_post_draw
	_shot("01_prologue")
	if reduced:
		for _i in 8: panel.advance()

func _process(_delta: float) -> bool:
	frame += 1
	if stage == 0 and not interactive and frame > 240:
		panel.skip()
	if stage == 1 and frame > 10:
		_shot("02_chapter_card")
		if not interactive:
			quit()
		stage = 2
	return false

func _next() -> void:
	if stage != 0: return
	stage = 1
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://content/story_mode.json"))
	var card = ChapterCardScript.new(data["chapters"][0], reduced)
	root.add_child(card)
	card.finished.connect(func() -> void: stage = 2)

func _shot(name: String) -> void:
	var image := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	if DisplayServer.get_name() != "headless":
		var texture := root.get_viewport().get_texture()
		if texture != null:
			var captured = texture.get_image()
			if captured != null:
				image = captured
	image.save_png(out_dir.path_join(name + ".png"))
	print("screenshot ", out_dir.path_join(name + ".png"))
