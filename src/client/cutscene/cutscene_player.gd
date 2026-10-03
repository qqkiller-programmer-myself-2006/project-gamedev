class_name CutscenePlayer
extends Control
## Plays a cutscene graph as short Theora clips with Thai subtitles and choices.
## It reports only flags (`finished`) and never touches match rules (ADR-0015).

signal finished(flags: Dictionary)

const FALLBACK_SECONDS := 3.0
## A second Esc within this many seconds skips the whole cutscene.
const SKIP_ALL_WINDOW := 1.2

var router: CutsceneRouter
var text_scale := 1.0
var reduced_motion := false
## True while the current node shows a black subtitle card instead of video.
var using_fallback := false

var _video := VideoStreamPlayer.new()
var _card := ColorRect.new()
var _subtitle := Label.new()
var _hint := Label.new()
var _choice_box := VBoxContainer.new()
var _choice_buttons: Array[Button] = []
var _choice_index := 0
var _elapsed := 0.0
var _clip_length := FALLBACK_SECONDS
var _clip_done := false
var _last_skip_msec := -100000
var _ended := false


func _init(cutscene: Dictionary = {}, initial_flags: Dictionary = {}, scale: float = 1.0, reduced: bool = false) -> void:
	router = CutsceneRouter.new(cutscene, initial_flags)
	text_scale = scale
	reduced_motion = reduced
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.color = Color.BLACK
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_video.expand = true
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.finished.connect(_on_clip_finished)
	add_child(_video)
	var font := UiKit.pixel_font()
	for label in [_subtitle, _hint]:
		if font != null:
			label.add_theme_font_override("font", font)
		label.add_theme_color_override("font_color", UiKit.TEXT)
		label.add_theme_color_override("font_outline_color", UiKit.BG)
		label.add_theme_constant_override("outline_size", 6)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	_hint.text = Tr.t(UiText.LABELS["dialogue_hint"])
	_choice_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_box.add_theme_constant_override("separation", 10)
	_choice_box.visible = false
	add_child(_choice_box)
	apply_settings(scale, reduced)
	resized.connect(_layout)


func _ready() -> void:
	_layout()
	_enter_node()


func apply_settings(scale: float, reduced: bool) -> void:
	text_scale = scale
	reduced_motion = reduced
	_subtitle.add_theme_font_size_override("font_size", int(UiKit.SIZES["heading"] * scale))
	_hint.add_theme_font_size_override("font_size", int(UiKit.SIZES["small"] * scale))
	for button in _choice_buttons:
		button.add_theme_font_size_override("font_size", int(UiKit.SIZES["heading"] * scale))
	if is_inside_tree():
		_layout()


func _layout() -> void:
	var view := size if size.x > 0.0 else Vector2(1280, 720)
	var margin := 48.0
	var hint_height := float(UiKit.SIZES["small"]) * text_scale * 1.6
	_hint.position = Vector2(margin, view.y - hint_height - 8.0)
	_hint.size = Vector2(view.x - margin * 2.0, hint_height)
	# Subtitles may wrap to three lines at scale 1.4; reserve room above the hint.
	var sub_height := float(UiKit.SIZES["heading"]) * text_scale * 1.5 * 3.0
	_subtitle.position = Vector2(margin, view.y - hint_height - 16.0 - sub_height)
	_subtitle.size = Vector2(view.x - margin * 2.0, sub_height)
	_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	var box_width := minf(760.0, view.x - margin * 2.0)
	_choice_box.position = Vector2((view.x - box_width) * 0.5, view.y * 0.25)
	_choice_box.size = Vector2(box_width, view.y * 0.5)


func _enter_node() -> void:
	if router.finished:
		_finish()
		return
	_clip_done = false
	_elapsed = 0.0
	_choice_box.visible = false
	_subtitle.text = ""
	var stream: VideoStream = null
	var clip_path := router.clip()
	if not clip_path.is_empty() and ResourceLoader.exists(clip_path):
		stream = load(clip_path) as VideoStream
	using_fallback = stream == null
	_card.visible = using_fallback
	_video.visible = not using_fallback
	if using_fallback:
		_video.stop()
		_clip_length = float(router.node().get("duration", FALLBACK_SECONDS))
	else:
		_video.stream = stream
		_video.play()
	_update_subtitle()


func _process(delta: float) -> void:
	if _ended or _clip_done:
		return
	if using_fallback:
		_elapsed += delta
		if _elapsed >= _clip_length:
			_on_clip_finished()
			return
	else:
		_elapsed = _video.stream_position
	_update_subtitle()


func _update_subtitle() -> void:
	var text := ""
	for line in router.subtitles():
		if not line is Dictionary:
			continue
		var start := float(line.get("t", 0.0))
		var stop := float(line.get("end", INF))
		if _elapsed >= start and _elapsed < stop:
			text = Tr.t(str(line.get("text", "")))
	_subtitle.text = text


func _on_clip_finished() -> void:
	if _ended or _clip_done:
		return
	_clip_done = true
	_video.stop()
	if router.has_choices():
		_show_choices()
	elif not router.advance():
		_finish()
	else:
		_enter_node()


func _show_choices() -> void:
	for child in _choice_box.get_children():
		child.queue_free()
	_choice_buttons.clear()
	_choice_index = 0
	for index in router.choices().size():
		var option: Dictionary = router.choices()[index]
		var button := Button.new()
		button.text = Tr.t(str(option.get("label", "")))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 44.0 * text_scale)
		button.add_theme_font_size_override("font_size", int(UiKit.SIZES["heading"] * text_scale))
		var font := UiKit.pixel_font()
		if font != null:
			button.add_theme_font_override("font", font)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(choose.bind(index))
		_choice_box.add_child(button)
		_choice_buttons.append(button)
	_choice_box.visible = true
	_subtitle.text = ""
	_mark_choice()


func _mark_choice() -> void:
	for index in _choice_buttons.size():
		var button := _choice_buttons[index]
		button.add_theme_color_override("font_color", UiKit.GOLD if index == _choice_index else UiKit.TEXT)
		var raw := Tr.t(str(router.choices()[index].get("label", "")))
		button.text = ("> " + raw) if index == _choice_index else raw


func choose(index: int) -> void:
	if _ended or not router.has_choices():
		return
	if not router.choose(index):
		return
	_enter_node()


## First call skips the current clip; a second call within SKIP_ALL_WINDOW skips everything.
## On a choice node it skips everything, taking each default choice.
func skip() -> void:
	if _ended:
		return
	var now := Time.get_ticks_msec()
	if now - _last_skip_msec <= int(SKIP_ALL_WINDOW * 1000.0) or _choice_box.visible:
		skip_all()
		return
	_last_skip_msec = now
	_on_clip_finished()


func skip_all() -> void:
	if _ended:
		return
	router.skip_all()
	_finish()


func _finish() -> void:
	if _ended:
		return
	_ended = true
	_video.stop()
	finished.emit(router.flags)
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			skip()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if _choice_box.visible:
				choose(_choice_index)
			elif using_fallback:
				_on_clip_finished()
		KEY_UP, KEY_LEFT:
			_move_choice(-1)
		KEY_DOWN, KEY_RIGHT:
			_move_choice(1)
	# Own every key while open so battle and camp hotkeys cannot fire underneath.
	get_viewport().set_input_as_handled()


func _move_choice(step: int) -> void:
	if not _choice_box.visible or _choice_buttons.is_empty():
		return
	_choice_index = posmod(_choice_index + step, _choice_buttons.size())
	_mark_choice()
