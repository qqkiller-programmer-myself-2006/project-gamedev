class_name HomeBackdrop
extends Control
## Animated night-forest home scene: smooth sky, moon, two drifting tree lines,
## fireflies and a pixel campfire with the class sprites standing around it.
## Everything is static when Reduced motion is on.

var reduced_motion := false
var _time := 0.0
var _sprites: Array[TextureRect] = []
var _sprite_heights: Array[float] = []

const SKY_TOP := Color("#060a18")
const SKY_BOTTOM := Color("#23324a")
const TREE_FAR := Color("#16243a")
const TREE_NEAR := Color("#0c1624")
const GROUND := Color("#0b131e")
const GROUND_EDGE := Color("#18263a")
const FIRE_X := 0.68
const GROUND_Y := 0.80
const SPRITE_SCALE := 2.0
## [class, frame, x as a fraction of the width]; the Swordsman faces the fire from the left.
const PARTY := [["swordsman", "idle_right.png", 0.56], ["archer", "idle_left.png", 0.79], ["mage", "idle_left.png", 0.89]]


func setup(reduced: bool) -> void:
	reduced_motion = reduced
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(not reduced_motion)
	for item in PARTY:
		var texture := load("res://assets/heroes/%s/%s" % [item[0], item[1]]) as Texture2D
		if texture == null:
			continue
		var sprite := TextureRect.new()
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var w := texture.get_width() * SPRITE_SCALE
		var h := texture.get_height() * SPRITE_SCALE
		sprite.anchor_left = item[2]
		sprite.anchor_right = item[2]
		sprite.anchor_top = GROUND_Y
		sprite.anchor_bottom = GROUND_Y
		sprite.offset_left = -w * 0.5
		sprite.offset_right = w * 0.5
		sprite.offset_top = -h
		sprite.offset_bottom = 0.0
		add_child(sprite)
		_sprites.append(sprite)
		_sprite_heights.append(h)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	for i in _sprites.size():
		var bob := sin(_time * 1.6 + float(i) * 1.7) * 2.0
		_sprites[i].offset_top = -_sprite_heights[i] + bob
		_sprites[i].offset_bottom = bob


func _sky_at(y: float, height: float) -> Color:
	return SKY_TOP.lerp(SKY_BOTTOM, clampf(y / height, 0.0, 1.0))


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)]),
		PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOTTOM, SKY_BOTTOM]))
	_draw_moon(size)
	_draw_trees(size, TREE_FAR, size.y * 0.66, 30.0, 0.10)
	_draw_trees(size, TREE_NEAR, size.y * 0.76, 42.0, 0.16)
	var ground_top := size.y * (GROUND_Y - 0.03)
	draw_rect(Rect2(0, ground_top, size.x, size.y - ground_top), GROUND)
	draw_rect(Rect2(0, ground_top, size.x, 3), GROUND_EDGE)
	var fire := Vector2(size.x * FIRE_X, size.y * GROUND_Y)
	_draw_glow(fire, size)
	_draw_fire(fire)
	_draw_fireflies(size)


func _draw_moon(size: Vector2) -> void:
	var moon := Vector2(size.x * 0.84, size.y * 0.20)
	var r := minf(size.x, size.y) * 0.05
	draw_circle(moon, r, Color("#f6df9a"))
	# Crescent: cover part of the disc with the sky colour, then lay the glow over both
	# so the cut-out never reads as a dark disc.
	var cut := moon + Vector2(r * 0.42, -r * 0.28)
	draw_circle(cut, r * 0.92, _sky_at(cut.y, size.y))
	for i in 16:
		draw_circle(moon, r * (2.4 - i * 0.09), Color(1.0, 0.9, 0.62, 0.012))


func _draw_trees(size: Vector2, color: Color, baseline: float, height: float, speed: float) -> void:
	var drift := 0.0 if reduced_motion else sin(_time * speed) * 8.0
	var x := -60.0 + drift
	while x < size.x + 80.0:
		var h := height + fmod(abs(x * 1.7), 60.0)
		draw_rect(Rect2(x + 19, baseline - h * 0.25, 8, h * 0.30), color)
		draw_colored_polygon(PackedVector2Array([Vector2(x, baseline - h * 0.20), Vector2(x + 23, baseline - h), Vector2(x + 46, baseline - h * 0.20)]), color)
		draw_colored_polygon(PackedVector2Array([Vector2(x + 4, baseline), Vector2(x + 23, baseline - h * 0.65), Vector2(x + 42, baseline)]), color)
		x += 54.0


func _draw_glow(fire: Vector2, size: Vector2) -> void:
	var pulse := 1.0 if reduced_motion else 0.9 + 0.1 * sin(_time * 5.3)
	var base := minf(size.x, size.y) * 0.34
	var rings := 24
	for i in rings:
		var t := float(i) / float(rings - 1)
		draw_circle(fire + Vector2(0, -18), base * (1.0 - t * 0.85) * pulse, Color(1.0, 0.55, 0.18, 0.011))


## Pixel campfire: two crossed logs, stones, three flame layers of 6-px blocks and rising sparks.
func _draw_fire(c: Vector2) -> void:
	var px := 6.0
	for s in [-4, -3, 3, 4]:
		draw_rect(Rect2(c.x + s * px - px * 0.5, c.y - px, px, px), Color("#3a3f4a"))
	draw_line(c + Vector2(-34, -4), c + Vector2(30, -14), Color("#5e3422"), 9.0)
	draw_line(c + Vector2(-30, -14), c + Vector2(34, -4), Color("#7d4527"), 9.0)
	var layers := [[Color("#c2381d"), 7, 11], [Color("#f07a24"), 5, 8], [Color("#ffd35e"), 3, 5]]
	for layer in layers:
		var half: int = layer[1]
		var tall: int = layer[2]
		for col in range(-half, half + 1):
			var edge := 1.0 - absf(float(col)) / float(half + 1)
			var flick := 0.0 if reduced_motion else sin(_time * 9.0 + col * 1.3) * 1.2
			var rows := int(round(tall * edge + flick))
			for row in rows:
				draw_rect(Rect2(c.x + col * px - px * 0.5, c.y - 14 - (row + 1) * px, px, px), layer[0])
	if not reduced_motion:
		for i in 6:
			var t := fmod(_time * 0.7 + i * 0.37, 1.0)
			var spark := c + Vector2(sin(_time * 2.0 + i) * 14.0 + (i - 3) * 5.0, -90 - t * 90.0)
			draw_rect(Rect2(spark, Vector2(3, 3)), Color(1.0, 0.8, 0.35, 1.0 - t))


func _draw_fireflies(size: Vector2) -> void:
	for i in 10:
		var p := Vector2(size.x * (0.42 + fmod(float(i) * 0.173, 0.56)), size.y * (0.18 + fmod(float(i) * 0.31, 0.46)))
		if not reduced_motion:
			p += Vector2(sin(_time * 0.6 + i) * 10.0, cos(_time * 0.5 + i * 2.0) * 6.0)
		var pulse := 1.0 if reduced_motion else (0.45 + 0.55 * sin(_time * 1.8 + i))
		draw_circle(p, 2.0, Color(0.93, 0.83, 0.34, pulse))
