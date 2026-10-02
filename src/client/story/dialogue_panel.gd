class_name DialoguePanel
extends Control

signal finished

const FONT_PATH := "res://assets/fonts/PixelifySans.ttf"
const PORTRAIT_ROOT := "res://assets/heroes/"

var lines: Array = []
var line_index := 0
var reduced_motion := false
var text_scale := 1.0
var _speaker := ""
var _full_text := ""
var _shown := 0
var _elapsed := 0.0
var _portrait: Texture2D
var _font: Font
var _name_label := Label.new()
var _text_label := Label.new()
var _hint_label := Label.new()
var _box: StyleBox = UiKit.navy_box()
var _safe_log_top_y := 0.0
var _safe_header_bottom_y := 0.0
var _has_safe_bounds := false
var _is_layouting := false

var class_map: Dictionary = {}

func _init(dialogue: Array = [], scale: float = 1.0, reduced: bool = false, classes: Dictionary = {}) -> void:
	lines = dialogue
	text_scale = scale
	reduced_motion = reduced
	class_map = classes
	_font = load(FONT_PATH)
	if _font == null:
		_font = ThemeDB.fallback_font
	position.y = -210.0
	size.y = 196.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	_name_label.add_theme_font_override("font", _font)
	_text_label.add_theme_font_override("font", _font)
	_hint_label.add_theme_font_override("font", _font)
	for label in [_name_label, _text_label, _hint_label]:
		label.add_theme_color_override("font_color", UiKit.TEXT)
		label.add_theme_color_override("font_outline_color", UiKit.BG)
		label.add_theme_constant_override("outline_size", 5)
		add_child(label)
	_name_label.add_theme_color_override("font_color", UiKit.GOLD)
	_hint_label.add_theme_color_override("font_color", UiKit.TEXT_DIM)
	_name_label.add_theme_font_size_override("font_size", int(UiKit.SIZES["heading"] * text_scale))
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", int(UiKit.SIZES["heading"] * text_scale))
	_hint_label.text = UiText.LABELS["dialogue_hint"]
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_size_override("font_size", int(UiKit.SIZES["small"] * text_scale))
	if not lines.is_empty():
		_show_line()
	_layout()
	queue_redraw()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_layout()
	if not reduced_motion:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.22)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func _draw() -> void:
	draw_style_box(_box, Rect2(Vector2.ZERO, size))
	var portrait_rect := Rect2(24, 20, 150, maxf(80.0, size.y - 40.0))
	draw_rect(portrait_rect, UiKit.NAVY_RAISED, true)
	draw_rect(portrait_rect, UiKit.BORDER, false, 2.0)
	if _portrait != null and not _is_narrator():
		var texture_size := _portrait.get_size()
		var fit := minf((portrait_rect.size.x - 10.0) / texture_size.x, (portrait_rect.size.y - 10.0) / texture_size.y)
		var draw_size := texture_size * fit
		draw_texture_rect(_portrait, Rect2(portrait_rect.position + (portrait_rect.size - draw_size) * 0.5, draw_size), false)
	elif _is_narrator():
		var center := portrait_rect.get_center()
		draw_line(center + Vector2(-38, 18), center + Vector2(0, 30), UiKit.GOLD, 4)
		draw_line(center + Vector2(38, 18), center + Vector2(0, 30), UiKit.GOLD, 4)
		draw_line(center + Vector2(-38, 18), center + Vector2(-38, -22), UiKit.GOLD, 4)
		draw_line(center + Vector2(38, 18), center + Vector2(38, -22), UiKit.GOLD, 4)
		draw_line(center + Vector2(0, 30), center + Vector2(0, -18), UiKit.GOLD, 3)
func _process(delta: float) -> void:
	if _shown < _full_text.length() and not reduced_motion:
		_elapsed += delta
		_shown = mini(_full_text.length(), int(_elapsed * 52.0))
		_text_label.visible_characters = _shown

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	# The dialogue owns every key while open so battle and camp hotkeys cannot
	# fire underneath it. Enter and Esc keep their overlay actions.
	if not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
		advance() if event.keycode != KEY_ESCAPE else skip()
	get_viewport().set_input_as_handled()

func advance() -> void:
	if _shown < _full_text.length():
		_shown = _full_text.length()
		_text_label.visible_characters = -1
		return
	line_index += 1
	if line_index >= lines.size():
		finished.emit()
		queue_free()
	else:
		_show_line()

func skip() -> void:
	finished.emit()
	queue_free()

func _show_line() -> void:
	var line: Dictionary = lines[line_index]
	_speaker = str(line.get("speaker", "narrator")).capitalize()
	if _is_narrator():
		_speaker = "NARRATOR"
	_full_text = str(line.get("text", ""))
	_shown = _full_text.length() if reduced_motion else 0
	_elapsed = 0.0
	_name_label.text = _speaker
	_text_label.text = _full_text
	_text_label.visible_characters = -1 if reduced_motion else 0
	_portrait = _find_portrait(str(line.get("speaker", "")))
	_layout()
	queue_redraw()


func apply_settings(scale: float, reduced: bool) -> void:
	text_scale = scale
	reduced_motion = reduced
	_name_label.add_theme_font_size_override("font_size", int(UiKit.SIZES["heading"] * text_scale))
	_text_label.add_theme_font_size_override("font_size", int(UiKit.SIZES["heading"] * text_scale))
	_hint_label.add_theme_font_size_override("font_size", int(UiKit.SIZES["small"] * text_scale))
	if reduced_motion:
		_shown = _full_text.length()
		_text_label.visible_characters = -1
	_layout()
	queue_redraw()


func set_safe_bounds(log_top_y: float, header_bottom_y: float) -> void:
	_safe_log_top_y = log_top_y
	_safe_header_bottom_y = header_bottom_y
	_has_safe_bounds = true
	_layout()


func _layout() -> void:
	if _is_layouting:
		return
	_is_layouting = true
	var left := clampf(280.0 * text_scale, 280.0, 360.0) + 32.0
	var available_width := maxf(300.0, size.x - 24.0)
	var font_size := float(int(UiKit.SIZES["heading"] * text_scale))
	var chars_per_line := maxi(12, int((available_width - 210.0) / maxf(1.0, font_size * 0.52)))
	var line_count := 1
	for paragraph in _full_text.split("\n"):
		line_count += maxi(0, ceili(float(paragraph.length()) / float(chars_per_line)) - 1)
	var viewport_height := get_viewport_rect().size.y if is_inside_tree() else 720.0
	var content_height := 110.0 + line_count * font_size * 1.3
	var height := clampf(content_height, 190.0, maxf(190.0, viewport_height - 28.0))
	offset_left = left
	offset_top = -height
	if _has_safe_bounds:
		var safe_bottom := _safe_log_top_y - 14.0
		var safe_top := _safe_header_bottom_y + 14.0
		var max_height := maxf(1.0, safe_bottom - safe_top)
		height = clampf(content_height, minf(190.0, max_height), max_height)
		offset_bottom = safe_bottom - viewport_height
		offset_top = offset_bottom - height
	else:
		offset_top = -height
		offset_bottom = -14.0
	var text_width := maxf(80.0, available_width - 210.0)
	_name_label.position = Vector2(210, 18)
	_name_label.size = Vector2(text_width, font_size + 12.0)
	_text_label.position = Vector2(210, 58)
	_text_label.size = Vector2(text_width, maxf(40.0, height - 100.0))
	_hint_label.position = Vector2(maxf(210.0, available_width - 360.0), height - 34.0)
	_hint_label.size = Vector2(minf(340.0, text_width), 24.0)
	_is_layouting = false


func _is_narrator() -> bool:
	return _speaker.to_lower() == "narrator"

func _find_portrait(speaker: String) -> Texture2D:
	var lower := speaker.to_lower()
	var class_id: String = class_map.get(lower, lower)
	if class_id == "classless": class_id = lower
	var path: String = PORTRAIT_ROOT + class_id + "/portrait.png"
	if ResourceLoader.exists(path):
		return load(path)
	return null
