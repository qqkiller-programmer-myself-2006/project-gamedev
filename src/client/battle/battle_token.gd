class_name BattleToken
extends Button
## One combatant on the battle stage: Status-effect badges on top, a figure
## drawn in code in the middle (replace `_draw_figure` with a sprite later
## without touching the layout) and a nameplate with HP - and Energy for
## Party characters - below, like docs/references/aac_rogue/07. It is a
## Button so a valid target can be clicked, or focused and confirmed with
## Enter.

const BADGE_HEIGHT := 30.0
const PLATE_HEIGHT := 58.0

const CLASS_TINTS := {
	"classless": Color("#b9a98c"), "swordsman": Color("#c3cbd9"), "archer": Color("#86c77e"),
	"mage": Color("#6fa9f2"), "guardian": Color("#d9b65f"), "rogue": Color("#a584de"),
}
const CLASS_GLYPHS := {
	"classless": "-", "swordsman": "S", "archer": "A", "mage": "M", "guardian": "G", "rogue": "R",
}
const ENEMY_TINTS := {
	"grey_wolf": Color("#9aa3ad"), "thornback_boar": Color("#a5714f"), "bramble_archer": Color("#79a150"),
	"forest_wisp": Color("#a6e6ee"), "elder_thornwarden": Color("#5f8f43"),
}

var unit_id := ""
## "party", "enemy" or "boss".
var side := "party"
var figure_height := 84.0
var tint := Color.WHITE
var glyph := "?"
var down := false
var acting := false
## 1-based key shown while this token is a valid target, else 0.
var target_number := 0

var _badges: HBoxContainer
var _plate: PanelContainer


## `data`: {id, side, name, kind (class or enemy kind), hp, max_hp,
## energy, energy_max, statuses, acting, controller, you}
func setup(data: Dictionary) -> void:
	unit_id = str(data["id"])
	side = str(data.get("side", "party"))
	var kind := str(data.get("kind", ""))
	down = int(data.get("hp", 0)) <= 0
	acting = bool(data.get("acting", false))
	flat = true
	text = ""
	focus_mode = Control.FOCUS_NONE
	disabled = true
	var width := 212.0 if side == "boss" else 150.0
	figure_height = 150.0 if side == "boss" else 84.0
	custom_minimum_size = Vector2(width, BADGE_HEIGHT + figure_height + PLATE_HEIGHT)
	size = custom_minimum_size
	if side == "party":
		tint = CLASS_TINTS.get(kind, CLASS_TINTS["classless"])
		glyph = str(CLASS_GLYPHS.get(kind, "?"))
	else:
		tint = ENEMY_TINTS.get(kind, Color("#c8a98a"))
		glyph = str(data.get("name", "?")).substr(0, 1).to_upper()

	_badges = UiKit.hbox(3)
	_badges.position = Vector2(0, 0)
	_badges.size = Vector2(width, BADGE_HEIGHT)
	_badges.alignment = BoxContainer.ALIGNMENT_CENTER
	_badges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var statuses: Array = data.get("statuses", [])
	var compact := statuses.size() > (3 if side == "boss" else 2)
	_badges.add_theme_constant_override("separation", 1 if compact else 3)
	for entry in statuses:
		_badges.add_child(UiKit.status_badge(entry, compact))
	add_child(_badges)

	var plate_box := UiKit.vbox(2)
	plate_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var who := str(data.get("name", unit_id))
	if bool(data.get("you", false)):
		who += " (you)"
	elif str(data.get("controller", "")) == "ai":
		who += " (AI)"
	var name_label := UiKit.pixel_label(who, "small", UiKit.ACCENT if bool(data.get("you", false)) else UiKit.TEXT)
	name_label.clip_text = true
	plate_box.add_child(name_label)
	var bars := UiKit.hbox(3)
	var hp_bar := UiKit.stat_bar(int(data.get("hp", 0)), int(data.get("max_hp", 1)), UiKit.BAR_HP,
			"%d/%d" % [int(data.get("hp", 0)), int(data.get("max_hp", 1))] if not down else "DOWN", 18)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_child(hp_bar)
	if data.has("energy"):
		var energy := UiKit.stat_bar(int(data["energy"]), int(data.get("energy_max", 6)), UiKit.BAR_ENERGY,
				"%d/%d" % [int(data["energy"]), int(data.get("energy_max", 6))], 18)
		energy.custom_minimum_size.x = 52
		bars.add_child(energy)
	plate_box.add_child(bars)
	_plate = UiKit.panel(plate_box, "HudPanel")
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.position = Vector2(0, BADGE_HEIGHT + figure_height + 2)
	_plate.custom_minimum_size = Vector2(width, 0)
	_plate.size = Vector2(width, PLATE_HEIGHT - 2)
	add_child(_plate)
	tooltip_text = str(data.get("tooltip", ""))
	modulate = Color(0.55, 0.55, 0.55, 0.85) if down else Color.WHITE


## Makes the token a clickable target with number `number` (0 = not a target).
func set_target(number: int, callback: Callable) -> void:
	target_number = number
	disabled = number <= 0
	focus_mode = Control.FOCUS_ALL if number > 0 else Control.FOCUS_NONE
	if number > 0:
		pressed.connect(callback)
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, BADGE_HEIGHT + figure_height - 6)
	var ring_color := Color(0, 0, 0, 0)
	if target_number > 0:
		ring_color = UiKit.ACCENT
	if acting:
		ring_color = Color("#fff3b0")
	if has_focus():
		ring_color = UiKit.ACCENT
	_draw_ellipse(center, size.x * 0.34, 9.0, Color(0, 0, 0, 0.45), true)
	if ring_color.a > 0.0:
		_draw_ellipse(center, size.x * 0.42, 13.0, ring_color, false, 3.0)
	_draw_figure(center)
	if target_number > 0:
		var font := UiKit.pixel_font()
		var tag := "[%d]" % target_number
		draw_string_outline(font, Vector2(size.x - 34, BADGE_HEIGHT + 18), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, Color.BLACK)
		draw_string(font, Vector2(size.x - 34, BADGE_HEIGHT + 18), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UiKit.ACCENT)


## The placeholder art: a hooded hero for the Party, a beast for enemies,
## a towering tree-guardian for the Boss. Each carries its Class/enemy glyph.
func _draw_figure(feet: Vector2) -> void:
	var body := tint
	var dark := tint.darkened(0.45)
	var font := UiKit.pixel_font()
	match side:
		"party":
			var top := feet.y - figure_height + 14
			draw_colored_polygon(PackedVector2Array([
				Vector2(feet.x - 22, feet.y - 4), Vector2(feet.x + 22, feet.y - 4),
				Vector2(feet.x + 14, top + 26), Vector2(feet.x - 14, top + 26)]), dark)
			draw_colored_polygon(PackedVector2Array([
				Vector2(feet.x - 17, feet.y - 8), Vector2(feet.x + 17, feet.y - 8),
				Vector2(feet.x + 11, top + 28), Vector2(feet.x - 11, top + 28)]), body)
			draw_circle(Vector2(feet.x, top + 14), 14.0, body.lightened(0.15))
			draw_circle(Vector2(feet.x, top + 14), 14.0, dark, false, 2.0)
			_draw_glyph(font, Vector2(feet.x, feet.y - 22), 20)
		"enemy":
			var c := Vector2(feet.x, feet.y - 28)
			draw_circle(c, 30.0, dark)
			draw_circle(c + Vector2(0, -2), 26.0, body)
			draw_circle(c + Vector2(-9, -8), 4.0, Color("#1b1b1b"))
			draw_circle(c + Vector2(9, -8), 4.0, Color("#1b1b1b"))
			draw_circle(c + Vector2(-9, -9), 1.5, Color("#ff6b5a"))
			draw_circle(c + Vector2(9, -9), 1.5, Color("#ff6b5a"))
			_draw_glyph(font, c + Vector2(0, 14), 18)
		"boss":
			var top := feet.y - figure_height + 10
			draw_colored_polygon(PackedVector2Array([
				Vector2(feet.x - 44, feet.y - 2), Vector2(feet.x + 44, feet.y - 2),
				Vector2(feet.x + 26, top + 50), Vector2(feet.x - 26, top + 50)]), dark)
			draw_colored_polygon(PackedVector2Array([
				Vector2(feet.x - 36, feet.y - 6), Vector2(feet.x + 36, feet.y - 6),
				Vector2(feet.x + 20, top + 52), Vector2(feet.x - 20, top + 52)]), body.darkened(0.2))
			for offset in [Vector2(-34, 34), Vector2(0, 18), Vector2(34, 34), Vector2(-18, 22), Vector2(18, 22)]:
				draw_circle(Vector2(feet.x, top) + offset, 24.0, body)
			draw_circle(Vector2(feet.x - 10, top + 62), 5.0, Color("#b8ff7a"))
			draw_circle(Vector2(feet.x + 10, top + 62), 5.0, Color("#b8ff7a"))
			_draw_glyph(font, Vector2(feet.x, feet.y - 30), 26)


func _draw_glyph(font: Font, at: Vector2, font_size: int) -> void:
	var width := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := at + Vector2(-width * 0.5, font_size * 0.35)
	draw_string_outline(font, pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.8))
	draw_string(font, pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


func _draw_ellipse(center: Vector2, radius_x: float, radius_y: float, color: Color, filled: bool, width: float = 1.0) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	if filled:
		draw_colored_polygon(points, color)
	else:
		points.append(points[0])
		draw_polyline(points, color, width, true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT:
		queue_redraw()
