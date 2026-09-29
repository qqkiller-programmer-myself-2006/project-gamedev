class_name ChapterCard
extends Control

signal finished
const FONT_PATH := "res://assets/fonts/PixelifySans.ttf"
var chapter := {}
var reduced_motion := false
var _timer := 0.0
var _title := Label.new()
var _subtitle := Label.new()
var _font: Font

func _init(data: Dictionary = {}, reduced: bool = false) -> void:
	chapter = data
	reduced_motion = reduced
	_font = load(FONT_PATH)
	if _font == null:
		_font = ThemeDB.fallback_font
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title.text = "Chapter %d\n%s" % [int(chapter.get("number", 0)), chapter.get("title", "")]
	_subtitle.text = str(chapter.get("subtitle", ""))
	for label in [_title, _subtitle]:
		label.add_theme_font_override("font", _font)
		label.add_theme_color_override("font_outline_color", Color("10131d"))
		label.add_theme_constant_override("outline_size", 8)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_title.position.y -= 80
	_title.size = Vector2(900, 170)
	_title.add_theme_font_size_override("font_size", 42)
	_title.add_theme_color_override("font_color", Color("e8c56a"))
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_subtitle.position.y += 72
	_subtitle.size = Vector2(900, 50)
	_subtitle.add_theme_font_size_override("font_size", 23)
	_subtitle.add_theme_color_override("font_color", Color("e1e4ed"))
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("101624"), true)
	draw_line(Vector2(150, size.y / 2 + 110), Vector2(size.x - 150, size.y / 2 + 110), Color("8a7343"), 2)

func _process(delta: float) -> void:
	if reduced_motion:
		return
	_timer += delta
	if _timer >= 2.5:
		finished.emit()
		queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if reduced_motion and event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_SPACE]:
		finished.emit()
		queue_free()
