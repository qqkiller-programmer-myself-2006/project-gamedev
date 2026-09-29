class_name HomeBackdrop
extends Control

var reduced_motion := false
var _time := 0.0
var _sprites: Array[TextureRect] = []

const SKY_TOP := Color("#080d1d")
const SKY_BOTTOM := Color("#26354b")
const TREE_FAR := Color("#17263a")
const TREE_NEAR := Color("#0d1725")

func setup(reduced: bool) -> void:
	reduced_motion = reduced
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(not reduced_motion)
	for item in [["swordsman", "idle_right.png", 0.43], ["archer", "idle_left.png", 0.62], ["mage", "idle_left.png", 0.73]]:
		var sprite := TextureRect.new()
		sprite.texture = load("res://assets/characters/%s/%s" % [item[0], item[1]])
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.anchor_left = item[2]
		sprite.anchor_right = item[2]
		sprite.anchor_top = 0.64
		sprite.anchor_bottom = 0.64
		sprite.offset_left = -72
		sprite.offset_right = 72
		sprite.offset_top = -110
		sprite.offset_bottom = 20
		add_child(sprite)
		_sprites.append(sprite)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	for i in _sprites.size():
		var bob := sin(_time * 1.6 + float(i) * 1.7) * 2.0
		_sprites[i].offset_top = -110.0 + bob
		_sprites[i].offset_bottom = 20.0 + bob

func _draw() -> void:
	var size := get_viewport_rect().size
	var bands := 18
	for i in bands:
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(0, size.y * t, size.x, size.y / bands + 1), SKY_TOP.lerp(SKY_BOTTOM, t))
	var moon := Vector2(size.x * 0.78, size.y * 0.22)
	draw_circle(moon, minf(size.x, size.y) * 0.075, Color(1.0, 0.88, 0.58, 0.08))
	draw_circle(moon, minf(size.x, size.y) * 0.052, Color("#f6df9a"))
	draw_circle(moon + Vector2(12, -8), minf(size.x, size.y) * 0.052, SKY_TOP.lerp(SKY_BOTTOM, 0.2))
	_draw_trees(size, TREE_FAR, size.y * 0.61, 22.0)
	_draw_trees(size, TREE_NEAR, size.y * 0.72, 31.0)
	draw_rect(Rect2(0, size.y * 0.71, size.x, size.y * 0.29), Color("#0a121d"))
	draw_circle(Vector2(size.x * 0.54, size.y * 0.83), size.x * 0.22, Color(0.80, 0.48, 0.18, 0.055))
	_draw_fire(Vector2(size.x * 0.54, size.y * 0.84))
	for i in 9:
		var p := Vector2(size.x * (0.10 + fmod(float(i) * 0.173, 0.82)), size.y * (0.20 + fmod(float(i) * 0.31, 0.48)))
		var pulse := 1.0 if reduced_motion else (0.55 + 0.45 * sin(_time * 1.8 + i))
		draw_circle(p, 2.0, Color(0.93, 0.83, 0.34, pulse))

func _draw_trees(size: Vector2, color: Color, baseline: float, height: float) -> void:
	var drift := 0.0 if reduced_motion else sin(_time * 0.10) * 6.0
	var x := -50.0 + drift
	while x < size.x + 80.0:
		var h := height + fmod(abs(x * 1.7), 55.0)
		draw_rect(Rect2(x + 18, baseline - h * 0.28, 8, h * 0.30), color)
		draw_colored_polygon(PackedVector2Array([Vector2(x, baseline), Vector2(x + 22, baseline - h), Vector2(x + 44, baseline)]), color)
		x += 52.0

func _draw_fire(center: Vector2) -> void:
	draw_line(center + Vector2(-30, 11), center + Vector2(26, -3), Color("#5e3422"), 8.0)
	draw_line(center + Vector2(-25, -3), center + Vector2(30, 12), Color("#7d4527"), 7.0)
	var flicker := 0.0 if reduced_motion else sin(_time * 7.0) * 4.0
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -72 - flicker), center + Vector2(25, 2), center + Vector2(0, 21), center + Vector2(-25, 2)]), Color("#e35b2c"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -49 - flicker), center + Vector2(13, 5), center + Vector2(0, 15), center + Vector2(-13, 5)]), Color("#ffd35e"))
