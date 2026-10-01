class_name DialoguePanel
extends Control

signal finished

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

var class_map: Dictionary = {}

func _init(dialogue: Array = [], scale: float = 1.0, reduced: bool = false, classes: Dictionary = {}) -> void:
	lines = dialogue
	text_scale = scale
	reduced_motion = reduced
	class_map = classes
	_font = UiKit.pixel_font()
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
	_name_label.position = Vector2(210, 20)
	_name_label.size = Vector2(900, 34)
	_name_label.add_theme_font_size_override("font_size", int(UiKit.SIZES["heading"] * text_scale))
	_text_label.position = Vector2(210, 60)
	_text_label.size = Vector2(1010, 86)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", int(UiKit.SIZES["heading"] * text_scale))
	_hint_label.text = Tr.t(UiText.LABELS["dialogue_hint"])
	_hint_label.position = Vector2(840, 157)
	_hint_label.size = Vector2(350, 26)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_size_override("font_size", int(UiKit.SIZES["small"] * text_scale))
	if not lines.is_empty():
		_show_line()
	queue_redraw()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -210.0
	offset_bottom = -14.0
	if not reduced_motion:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.22)

func _draw() -> void:
	draw_style_box(_box, Rect2(Vector2.ZERO, size))
	draw_rect(Rect2(24, 20, 150, 150), UiKit.NAVY_RAISED, true)
	draw_rect(Rect2(24, 20, 150, 150), UiKit.BORDER, false, 2.0)
	if _portrait != null:
		draw_texture_rect(_portrait, Rect2(32, 25, 134, 140), false)
	else:
		draw_circle(Vector2(99, 75), 30, UiKit.SLATE_HOVER)
		draw_rect(Rect2(72, 105, 54, 44), UiKit.SLATE_HOVER, true)
		draw_string(_font, Vector2(92, 92), _speaker.substr(0, 1).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.SIZES["heading"], UiKit.TEXT)

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
		_close()
	else:
		_show_line()

func skip() -> void:
	_close()

func _close() -> void:
	finished.emit()
	if reduced_motion or not is_inside_tree():
		queue_free()
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	tween.tween_callback(queue_free)

func _show_line() -> void:
	var line: Dictionary = lines[line_index]
	_speaker = str(line.get("speaker", "narrator")).capitalize()
	_full_text = Tr.t(str(line.get("text", "")))
	_shown = _full_text.length() if reduced_motion else 0
	_elapsed = 0.0
	_name_label.text = Tr.t(_speaker)
	_text_label.text = _full_text
	_text_label.visible_characters = -1 if reduced_motion else 0
	_portrait = _find_portrait(str(line.get("speaker", "")))
	queue_redraw()

func _find_portrait(speaker: String) -> Texture2D:
	var lower := speaker.to_lower()
	var class_id: String = class_map.get(lower, lower)
	if class_id == "classless": class_id = lower
	var path: String = PORTRAIT_ROOT + class_id + "/portrait.png"
	if ResourceLoader.exists(path):
		return load(path)
	return null
