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
var full := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--scale="): scale = float(arg.trim_prefix("--scale="))
		elif arg == "--interactive": interactive = true
		elif arg == "--reduced-motion": reduced = true
		elif arg == "--full": full = true
	DirAccess.make_dir_recursive_absolute(out_dir)
	if full:
		_full_preview.call_deferred()
		return
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
	if full:
		return false
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


func _full_preview() -> void:
	var app := ClientApp.new()
	root.add_child(app)
	await process_frame
	app.settings.text_scale = scale
	app.settings.reduced_motion = true
	app.apply_settings()
	var title: TitleScreen = app._current
	title._show_play()
	await _settle()
	_shot("01_home_play")
	title._show_story_setup()
	await _settle()
	_shot("02_class_pick")
	app.start_story(TitleScreen.STORY_CLASSES, {}, 1000)
	for _i in 12:
		await process_frame
	await _settle()
	app._toast_until = 0.0
	_shot("03_prologue_match")
	var match_screen: MatchScreen = app._current
	if match_screen._story_director != null and match_screen._story_director.current is DialoguePanel:
		match_screen._story_director.current.skip()
	await _settle()
	app._toast_until = 0.0
	_shot("04_chapter_card")
	if match_screen._story_director != null and match_screen._story_director.current is ChapterCard:
		var card: ChapterCard = match_screen._story_director.current
		card.finished.emit()
		card.queue_free()
	var vote: Dictionary = app.snapshot.get("match", {}).get("vote", {})
	var combat_option := -1
	for option in vote.get("options", []):
		if option["type"] == "combat":
			combat_option = int(option["index"])
			break
	if combat_option >= 0:
		app.send({"type": "vote", "option": combat_option})
		for _i in 900:
			await process_frame
			var encounter = app.snapshot.get("match", {}).get("encounter", {})
			if encounter is Dictionary and encounter.get("kind", "") == "combat" and str(encounter.get("actor", "")).begins_with("p"):
				break
		await _settle()
		app._toast_until = 0.0
		_shot("05_story_battle")
	app.story_save.clear()
	app.disconnect_from_server()
	app.queue_free()
	await process_frame
	quit()


func _settle() -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
