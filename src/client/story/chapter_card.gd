class_name ChapterCard
extends Control

signal finished
var chapter := {}
var reduced_motion := false
var _timer := 0.0
var _title := Label.new()
var _subtitle := Label.new()
var _hint: Label
var _font: Font
var _closing := false

func _init(data: Dictionary = {}, reduced: bool = false) -> void:
	chapter = data
	reduced_motion = reduced
	_font = UiKit.pixel_font()
	if _font == null:
		_font = ThemeDB.fallback_font
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title.text = "%s\n%s" % [Tr.t(UiText.LABELS["chapter"] % int(chapter.get("number", 0))), Tr.t(str(chapter.get("title", "")))]
	_subtitle.text = Tr.t(str(chapter.get("subtitle", "")))
	for label in [_title, _subtitle]:
		label.add_theme_font_override("font", _font)
		label.add_theme_color_override("font_outline_color", UiKit.BG)
		label.add_theme_constant_override("outline_size", 8)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_title.offset_left = -450
	_title.offset_right = 450
	_title.offset_top = -165
	_title.offset_bottom = 50
	_title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_title.add_theme_font_size_override("font_size", UiKit.SIZES["huge"])
	_title.add_theme_color_override("font_color", UiKit.GOLD)
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_subtitle.offset_left = -450
	_subtitle.offset_right = 450
	_subtitle.offset_top = 72
	_subtitle.offset_bottom = 122
	_subtitle.add_theme_font_size_override("font_size", UiKit.SIZES["heading"])
	_subtitle.add_theme_color_override("font_color", UiKit.TEXT)
	if reduced_motion:
		# Without motion the card waits for a key: say which.
		_add_hint()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiKit.BG, true)
	draw_line(Vector2(150, size.y / 2 + 110), Vector2(size.x - 150, size.y / 2 + 110), Color(UiKit.GOLD, 0.45), 2)

func _ready() -> void:
	if not reduced_motion:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.25)

func _process(delta: float) -> void:
	if reduced_motion:
		return
	_timer += delta
	if _timer >= 2.5 and not _closing:
		_close()


func apply_settings(_scale: float, reduced: bool) -> void:
	if reduced_motion == reduced:
		return
	reduced_motion = reduced
	if reduced_motion:
		set_process(false)
		modulate.a = 1.0
		_add_hint()
	else:
		if is_instance_valid(_hint):
			_hint.queue_free()
		_hint = null
		set_process(true)
		_timer = 0.0
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


func _add_hint() -> void:
	if is_instance_valid(_hint):
		return
	_hint = Label.new()
	_hint.text = Tr.t(UiText.LABELS["continue"])
	_hint.add_theme_font_override("font", _font)
	_hint.add_theme_font_size_override("font_size", UiKit.SIZES["small"])
	_hint.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_hint.offset_left = -450
	_hint.offset_right = 450
	_hint.offset_top = 150
	_hint.offset_bottom = 180
	add_child(_hint)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	if reduced_motion and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
		_close()
	get_viewport().set_input_as_handled()

func _close() -> void:
	if _closing:
		return
	_closing = true
	finished.emit()
	if reduced_motion or not is_inside_tree():
		queue_free()
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_callback(queue_free)
