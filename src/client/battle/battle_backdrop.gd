class_name BattleBackdrop
extends Control
## The Forest battlefield drawn in code: a dark canopy, a mossy clearing,
## tree silhouettes, rocks and red mushrooms (after the reference's forest
## arena). Fixed shapes, no randomness, so every client draws the same.

const SKY_TOP := Color("#101815")
const SKY_BOTTOM := Color("#23352c")
const GRASS := Color("#34503f")
const GRASS_LIGHT := Color("#3f6049")
const TREE := Color("#0f1a14")
const ROCK := Color("#4a524f")
const CAP := Color("#b8433f")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var horizon := h * 0.34
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, horizon), Vector2(0, horizon)]),
			PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOTTOM, SKY_BOTTOM]))
	draw_rect(Rect2(0, horizon, w, h - horizon), GRASS)
	_ellipse(Vector2(w * 0.5, h * 0.62), w * 0.46, h * 0.3, GRASS_LIGHT)
	for i in 14:
		var x := w * (float(i) / 13.0) + (18.0 if i % 2 == 0 else -12.0)
		var tall := h * (0.2 + 0.06 * float((i * 7) % 4))
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 34, horizon + 12), Vector2(x + 34, horizon + 12), Vector2(x, horizon - tall)]), TREE)
		draw_rect(Rect2(x - 5, horizon, 10, 22), TREE)
	for rock in [Vector2(0.86, 0.46), Vector2(0.93, 0.52), Vector2(0.08, 0.83), Vector2(0.62, 0.9)]:
		_ellipse(Vector2(w * rock.x, h * rock.y), 46.0, 20.0, ROCK)
		_ellipse(Vector2(w * rock.x - 8, h * rock.y - 6), 30.0, 11.0, ROCK.lightened(0.12))
	for shroom in [Vector2(0.9, 0.38), Vector2(0.95, 0.42), Vector2(0.05, 0.36)]:
		var base := Vector2(w * shroom.x, h * shroom.y)
		draw_rect(Rect2(base.x - 3, base.y - 24, 6, 26), Color("#d9d2c0"))
		_ellipse(base + Vector2(0, -26), 20.0, 9.0, CAP)
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.18))


func _ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)
