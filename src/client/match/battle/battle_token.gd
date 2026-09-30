class_name BattleToken
extends Button
## One combatant on the battle stage: Status-effect badges on top, a figure
## drawn in code in the middle (replace `_draw_figure` with a sprite later
## without touching the layout) and a nameplate with HP - and Energy for
## Party characters - below, like docs/references/aac_assassin/07. It is a
## Button so a valid target can be clicked, or focused and confirmed with
## Enter.

const BADGE_HEIGHT := 18.0
const PLATE_HEIGHT := 36.0

const PARTY_OUTFITS := {
	"Arin": {"shirt": Color("#d85b52"), "pants": Color("#3f547a"), "hair": Color("#e7c08d")},
	"Bram": {"shirt": Color("#4d9b86"), "pants": Color("#59416f"), "hair": Color("#342a2a")},
	"Cora": {"shirt": Color("#d28bba"), "pants": Color("#4a658c"), "hair": Color("#f0d4a7")},
	"Dain": {"shirt": Color("#c4974d"), "pants": Color("#443f36"), "hair": Color("#7a4f32")},
	"Wren": {"shirt": Color("#5a78c8"), "pants": Color("#31505d"), "hair": Color("#c8d4de")},
}

const CLASS_TINTS := {
	"classless": Color("#b9a98c"), "swordsman": Color("#c3cbd9"), "archer": Color("#86c77e"),
	"mage": Color("#6fa9f2"), "guardian": Color("#d9b65f"), "assassin": Color("#a584de"),
}
const CLASS_GLYPHS := {
	"classless": "-", "swordsman": "S", "archer": "A", "mage": "M", "guardian": "G", "assassin": "As",
}
const ENEMY_TINTS := {
	"grey_wolf": Color("#9aa3ad"), "thornback_boar": Color("#a5714f"), "bramble_archer": Color("#79a150"),
	"forest_wisp": Color("#a6e6ee"), "elder_thornwarden": Color("#5f8f43"),
}
const STATUS_ICONS := {
	"bleed": "bleed", "poison": "poison", "toxin": "poison", "venom_coat": "poison",
	"burn": "burn", "stun": "stun", "weak": "weak", "weakened": "weak", "enervation": "weak",
	"shield": "shield", "shielded": "shield", "protect": "shield", "protected": "shield",
	"regen": "regen", "regeneration": "regen", "dodge": "dodge", "focused": "dodge", "crit": "crit",
}

const MAX_PLATE_WIDTH := 156.0

var unit_id := ""
## "party", "enemy" or "boss".
var side := "party"
var figure_height := 84.0
var tint := Color.WHITE
var glyph := "?"
var enemy_kind := ""
var outfit: Dictionary = {}
var down := false
var acting := false
var class_id := ""
var sprite_set: SpriteSet
var enemy_sprite := false
var animation := "idle"
var animation_frames: Array[Texture2D] = []
var animation_frame := 0
var animation_elapsed := 0.0
var reduced_motion := false
## The player's text-size setting; nameplate names and bar captions follow it.
var text_scale := 1.0
var badge_height := BADGE_HEIGHT
var _bob_time := 0.0
## 1-based key shown while this token is a valid target, else 0.
var target_number := 0

var _badges: HBoxContainer
var _plate: PanelContainer


## `data`: {id, side, name, kind (class or enemy kind), hp, max_hp,
## energy, energy_max, statuses, acting, controller, you}
func setup(data: Dictionary) -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	unit_id = str(data["id"])
	side = str(data.get("side", "party"))
	var kind := str(data.get("kind", ""))
	class_id = kind.to_lower()
	enemy_sprite = side != "party" and not str(data.get("sprite", "")).is_empty()
	sprite_set = SpriteSet.for_class(class_id) if side == "party" else SpriteSet.for_enemy(str(data.get("sprite", "")), str(data.get("sprite_variant", ""))) if enemy_sprite else null
	reduced_motion = bool(data.get("reduced_motion", false))
	enemy_kind = kind
	down = int(data.get("hp", 0)) <= 0
	acting = bool(data.get("acting", false))
	flat = true
	text = ""
	focus_mode = Control.FOCUS_NONE
	disabled = true
	var text_factor := clampf(text_scale, 0.75, 1.5)
	badge_height = 36.0 if text_scale >= 1.4 else BADGE_HEIGHT
	var plate_height := PLATE_HEIGHT * text_factor
	# Party and enemy slots are 160 px apart on the 1280x720 field, so a plate
	# never grows past 156 px however large the text is (T29); only the boss is wider.
	var width := 180.0 * text_factor if side == "boss" else minf(140.0 * text_factor, MAX_PLATE_WIDTH)
	figure_height = 150.0 if side == "boss" else 110.0
	if sprite_set != null and sprite_set.is_enemy:
		figure_height = sprite_set.size_px() * 1.65
	custom_minimum_size = Vector2(width, badge_height + figure_height + plate_height)
	size = custom_minimum_size
	if side == "party":
		outfit = PARTY_OUTFITS.get(str(data.get("name", "")), PARTY_OUTFITS["Wren"])
		tint = outfit["shirt"]
		glyph = str(CLASS_GLYPHS.get(kind, "?"))
	else:
		tint = ENEMY_TINTS.get(kind, Color("#c8a98a"))
		glyph = str(data.get("name", "?")).substr(0, 1).to_upper()

	_badges = UiKit.hbox(3)
	_badges.position = Vector2(0, 0)
	_badges.size = Vector2(width, badge_height)
	_badges.alignment = BoxContainer.ALIGNMENT_CENTER
	_badges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var statuses: Array = data.get("statuses", [])
	var compact := statuses.size() > (3 if side == "boss" else 2)
	_badges.add_theme_constant_override("separation", 1 if compact else 3)
	for entry in statuses:
		_badges.add_child(_status_badge(entry, compact))
	add_child(_badges)

	var plate_box := UiKit.vbox(1)
	plate_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var who := str(data.get("name", unit_id))
	if bool(data.get("you", false)):
		who += " (you)"
	elif str(data.get("controller", "")) == "ai":
		who += " (AI)"
	var name_color := tint if side == "party" else (UiKit.ACCENT if bool(data.get("you", false)) else UiKit.TEXT)
	var name_label := UiKit.pixel_label(who, "small", name_color)
	name_label.add_theme_font_size_override("font_size", int(10 * (0.9 if side == "boss" else 1.0) * text_factor))
	name_label.clip_text = false
	plate_box.add_child(name_label)
	var bars := UiKit.hbox(0)
	bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hp_bar := UiKit.stat_bar(int(data.get("hp", 0)), int(data.get("max_hp", 1)), UiKit.BAR_HP,
			"%d/%d" % [int(data.get("hp", 0)), int(data.get("max_hp", 1))] if not down else "DOWN", 14 * text_factor, "small")
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.size_flags_stretch_ratio = 6.0
	_fit_bar_caption(hp_bar, text_factor)
	bars.add_child(hp_bar)
	if data.has("energy"):
		var energy := UiKit.stat_bar(int(data["energy"]), int(data.get("energy_max", 6)), UiKit.BAR_ENERGY,
				"%d/%d" % [int(data["energy"]), int(data.get("energy_max", 6))], 14 * text_factor, "small")
		energy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		energy.size_flags_stretch_ratio = 4.0
		_fit_bar_caption(energy, text_factor)
		bars.add_child(energy)
	plate_box.add_child(bars)
	_plate = UiKit.panel(plate_box, "HudPanel")
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.position = Vector2(0, badge_height + figure_height + 2)
	_plate.custom_minimum_size = Vector2(width, 0)
	_plate.size = Vector2(width, plate_height)
	add_child(_plate)
	tooltip_text = str(data.get("tooltip", ""))
	modulate = Color(0.55, 0.55, 0.55, 0.85) if down else Color.WHITE
	_set_animation("dead" if down else "idle")
	set_process(sprite_set != null)

func play_animation(kind: String) -> void:
	if sprite_set == null:
		return
	if kind == "revive":
		down = false
		modulate = Color.WHITE
		_set_animation("idle")
		return
	if kind == "dead":
		down = true
	_set_animation(kind)

## A fresh token is built for each snapshot. Carry a one-shot animation over
## to it when the snapshot still describes the same life state.
func continue_animation(previous: BattleToken) -> void:
	if sprite_set == null or previous == null or previous.sprite_set == null:
		return
	if previous.class_id != class_id or previous.enemy_sprite != enemy_sprite or previous.down != down:
		return
	if previous.animation == "idle":
		_bob_time = previous._bob_time
		return
	_set_animation(previous.animation)
	if animation_frames.is_empty():
		return
	animation_frame = mini(previous.animation_frame, animation_frames.size() - 1)
	animation_elapsed = previous.animation_elapsed
	_bob_time = previous._bob_time

func _set_animation(kind: String) -> void:
	animation = kind if sprite_set != null else "idle"
	animation_frames.clear()
	if sprite_set != null:
		animation_frames = sprite_set.frames(animation)
	animation_frame = 0
	animation_elapsed = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if sprite_set == null:
		return
	_bob_time += delta
	if animation == "idle":
		if not reduced_motion:
			queue_redraw()
		if reduced_motion or animation_frames.size() <= 1:
			return
	if animation_frames.is_empty():
		_set_animation("idle")
		return
	animation_elapsed += delta
	var frame_time := 1.0 / maxf(1.0, sprite_set.fps(animation))
	while animation_elapsed >= frame_time:
		animation_elapsed -= frame_time
		if animation == "dead":
			animation_frame = mini(animation_frame + 1, animation_frames.size() - 1)
		elif animation == "idle":
			animation_frame = (animation_frame + 1) % animation_frames.size()
		else:
			animation_frame += 1
			if animation_frame >= animation_frames.size():
				_set_animation("idle")
				break
		queue_redraw()


## Makes the token a clickable target with number `number` (0 = not a target).
func set_target(number: int, callback: Callable) -> void:
	target_number = number
	disabled = number <= 0
	focus_mode = Control.FOCUS_ALL if number > 0 else Control.FOCUS_NONE
	if number > 0:
		pressed.connect(callback)
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, badge_height + figure_height - 6)
	var ring_color := Color(0, 0, 0, 0)
	if target_number > 0:
		ring_color = UiKit.ACCENT
	if acting:
		ring_color = Color("#fff3b0")
	if has_focus():
		ring_color = UiKit.ACCENT
	var ground_color := Color(0, 0, 0, 0.45)
	if side == "party":
		ground_color = tint.darkened(0.25)
	_draw_ellipse(center, size.x * 0.34, 9.0, ground_color, true)
	if ring_color.a > 0.0:
		_draw_ellipse(center, size.x * 0.42, 13.0, ring_color, false, 3.0)
	_draw_figure(center)
	if target_number > 0:
		var font := UiKit.number_font()
		var tag := "[%d]" % target_number
		draw_string_outline(font, Vector2(size.x - 34, badge_height + 18), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, Color.BLACK)
		draw_string(font, Vector2(size.x - 34, badge_height + 18), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UiKit.ACCENT)


## Plate bars are 14 px tall at the default text size and grow with the text-size
## setting, so their numbers scale too without spilling out of the bar.
func _fit_bar_caption(bar: Control, factor: float) -> void:
	for child in bar.get_children():
		if child is Label:
			child.add_theme_font_size_override("font_size", int(10 * factor))
			child.add_theme_constant_override("outline_size", 3)


## Height of the character's body (not the whole canvas) for an animation. The
## owner's sheets draw each row at a different size, and attack canvases also hold
## arrows/slashes/orbs, so attack borrows the run row and dead the hurt row; the
## character then keeps one size while effects reach past it.
func _body_height(anim: String) -> float:
	match anim:
		"attack":
			for reference in ["run", "walk", "idle"]:
				var h: float = sprite_set.canvas(reference).y
				if h > 1.0:
					return h
		"dead":
			var hurt_h: float = sprite_set.canvas("hurt").y
			if hurt_h > 1.0:
				return hurt_h
	return sprite_set.canvas(anim).y


## Compact block figures keep the stage readable at 1280x720. The silhouettes
## deliberately use rectangles like the reference's Roblox-style avatars.
func _draw_figure(feet: Vector2) -> void:
	if sprite_set != null and not animation_frames.is_empty():
		var canvas: Vector2 = sprite_set.canvas(animation)
		var target_height := 110.0
		if sprite_set.is_enemy:
			target_height = sprite_set.size_px() * 1.65
		var scale := target_height / maxf(1.0, _body_height(animation))
		var bob := 0.0 if reduced_motion or animation != "idle" else sin(_bob_time * TAU) * 2.0
		var top_left := Vector2(roundf(feet.x - canvas.x * scale * 0.5),
				roundf(feet.y - sprite_set.baseline(animation) * scale + bob))
		var rect := Rect2(top_left, canvas * scale)
		if sprite_set.mirrored(animation):
			draw_set_transform(top_left + Vector2(rect.size.x, 0), 0.0, Vector2(-1, 1))
			draw_texture_rect(animation_frames[animation_frame], Rect2(Vector2.ZERO, rect.size), false)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_texture_rect(animation_frames[animation_frame], rect, false)
		return
	var body := tint
	var dark := tint.darkened(0.45)
	match side:
		"party":
			_draw_humanoid(feet, outfit.get("shirt", body), dark, 1.35)
		"enemy":
			_draw_enemy(feet, body, dark)
		"boss":
			_draw_humanoid(feet, body, dark, 2.0)
			draw_rect(Rect2(feet.x - 46, feet.y - 132, 92, 34), dark)
			draw_rect(Rect2(feet.x - 35, feet.y - 143, 70, 45), body.darkened(0.2))
			draw_circle(Vector2(feet.x - 17, feet.y - 124), 5.0, Color("#b8ff7a"))
			draw_circle(Vector2(feet.x + 17, feet.y - 124), 5.0, Color("#b8ff7a"))


func _draw_humanoid(feet: Vector2, body: Color, dark: Color, scale: float) -> void:
	var s := scale
	var head := Rect2(feet.x - 13.0 * s, feet.y - 72.0 * s, 26.0 * s, 25.0 * s)
	draw_rect(head.grow(2.0 * s), dark)
	var head_color: Color = outfit.get("hair", body.lightened(0.18)) if side == "party" else body.lightened(0.18)
	draw_rect(head, head_color)
	if side == "party":
		draw_rect(Rect2(head.position + Vector2(0, 2.0 * s), Vector2(head.size.x, 7.0 * s)), outfit.get("hair", dark).darkened(0.1))
	draw_rect(Rect2(feet.x - 19.0 * s, feet.y - 45.0 * s, 38.0 * s, 34.0 * s), dark)
	var shirt: Color = outfit.get("shirt", body) if side == "party" else body
	var pants: Color = outfit.get("pants", dark) if side == "party" else dark
	draw_rect(Rect2(feet.x - 15.0 * s, feet.y - 43.0 * s, 30.0 * s, 28.0 * s), shirt)
	draw_rect(Rect2(feet.x - 29.0 * s, feet.y - 42.0 * s, 10.0 * s, 30.0 * s), dark)
	draw_rect(Rect2(feet.x + 19.0 * s, feet.y - 42.0 * s, 10.0 * s, 30.0 * s), shirt.darkened(0.12))
	draw_rect(Rect2(feet.x - 14.0 * s, feet.y - 13.0 * s, 11.0 * s, 15.0 * s), pants)
	draw_rect(Rect2(feet.x + 3.0 * s, feet.y - 13.0 * s, 11.0 * s, 15.0 * s), pants.darkened(0.12))
	if glyph == "As":
		draw_line(Vector2(feet.x + 25.0 * s, feet.y - 27.0 * s), Vector2(feet.x + 40.0 * s, feet.y - 8.0 * s), Color("#e7e9ed"), maxf(2.0, 3.0 * s))
	elif glyph == "A":
		draw_line(Vector2(feet.x + 24.0 * s, feet.y - 54.0 * s), Vector2(feet.x + 42.0 * s, feet.y - 8.0 * s), Color("#c99d5b"), maxf(2.0, 2.0 * s))
	elif glyph == "M":
		draw_circle(Vector2(feet.x + 28.0 * s, feet.y - 27.0 * s), 7.0 * s, Color("#8fe8f0"))


func _draw_enemy(feet: Vector2, body: Color, dark: Color) -> void:
	var kind := enemy_kind.to_lower()
	if kind.contains("bee"):
		draw_rect(Rect2(feet.x - 25, feet.y - 48, 50, 36), Color("#d8ad24"))
		for x in [-12, 5]:
			draw_rect(Rect2(feet.x + x, feet.y - 48, 8, 36), Color("#24242a"))
		draw_colored_polygon(PackedVector2Array([Vector2(feet.x - 25, feet.y - 42), Vector2(feet.x - 54, feet.y - 62), Vector2(feet.x - 31, feet.y - 19)]), Color(0.75, 0.9, 1.0, 0.6))
		draw_colored_polygon(PackedVector2Array([Vector2(feet.x + 25, feet.y - 42), Vector2(feet.x + 54, feet.y - 62), Vector2(feet.x + 31, feet.y - 19)]), Color(0.75, 0.9, 1.0, 0.6))
	elif kind.contains("spider"):
		draw_rect(Rect2(feet.x - 26, feet.y - 38, 52, 30), dark)
		for side_x in [-1, 1]:
			for y in [feet.y - 35, feet.y - 23, feet.y - 11]:
				draw_line(Vector2(feet.x + side_x * 20, y), Vector2(feet.x + side_x * 46, y - 12), dark, 4)
		draw_circle(Vector2(feet.x - 12, feet.y - 28), 4, Color("#e54d4d"))
		draw_circle(Vector2(feet.x + 12, feet.y - 28), 4, Color("#e54d4d"))
	elif kind.contains("rat"):
		draw_rect(Rect2(feet.x - 25, feet.y - 34, 50, 25), body)
		draw_circle(Vector2(feet.x - 16, feet.y - 36), 9, body.lightened(0.2))
		draw_line(Vector2(feet.x + 22, feet.y - 13), Vector2(feet.x + 44, feet.y - 2), body, 3)
	elif kind.contains("wolf"):
		draw_rect(Rect2(feet.x - 32, feet.y - 42, 64, 27), body)
		draw_colored_polygon(PackedVector2Array([Vector2(feet.x - 32, feet.y - 42), Vector2(feet.x - 8, feet.y - 66), Vector2(feet.x + 4, feet.y - 39)]), dark)
		for x in [-25, -8, 12, 25]:
			draw_rect(Rect2(feet.x + x, feet.y - 18, 8, 20), dark)
		draw_circle(Vector2(feet.x - 22, feet.y - 49), 3, Color("#ff6b5a"))
	elif kind.contains("boar"):
		draw_rect(Rect2(feet.x - 35, feet.y - 43, 70, 31), body)
		draw_rect(Rect2(feet.x - 44, feet.y - 38, 18, 19), dark)
		draw_colored_polygon(PackedVector2Array([Vector2(feet.x - 45, feet.y - 20), Vector2(feet.x - 54, feet.y - 10), Vector2(feet.x - 39, feet.y - 16)]), Color("#f2e3bf"))
		for x in [-26, -7, 13, 27]:
			draw_rect(Rect2(feet.x + x, feet.y - 15, 8, 17), dark)
		for x in [-24, -8, 8, 24]:
			draw_colored_polygon(PackedVector2Array([Vector2(feet.x + x, feet.y - 43), Vector2(feet.x + x + 7, feet.y - 59), Vector2(feet.x + x + 13, feet.y - 43)]), dark)
	elif kind.contains("wisp"):
		for radius in [34.0, 26.0, 18.0]:
			draw_circle(Vector2(feet.x, feet.y - 43), radius, Color(0.30, 0.90, 0.94, 0.06))
		draw_circle(Vector2(feet.x, feet.y - 43), 18.0, Color("#8fe8f0"))
		draw_circle(Vector2(feet.x - 6, feet.y - 49), 5.0, Color("#eaffff"))
	elif kind.contains("outlaw") or kind.contains("bandit") or kind.contains("swordsman") or kind.contains("hunter") or kind.contains("sentinel"):
		_draw_humanoid(feet, Color("#45494f"), Color("#20242b"), 1.0)
		draw_rect(Rect2(feet.x - 17, feet.y - 53, 34, 9), Color("#181b22"))
	elif kind.contains("archer"):
		_draw_humanoid(feet, body, dark, 0.9)
		draw_arc(Vector2(feet.x + 27, feet.y - 36), 24, -1.2, 1.2, 16, Color("#d8b36a"), 3)
		draw_line(Vector2(feet.x + 27, feet.y - 58), Vector2(feet.x + 27, feet.y - 14), Color("#d8b36a"), 1)
	else:
		_draw_humanoid(feet, body, dark, 0.9)


func _status_badge(entry: Dictionary, compact: bool) -> PanelContainer:
	var status := str(entry.get("status", ""))
	var color := UiKit.status_color(str(entry.get("color", "")))
	var line := UiKit.hbox(2)
	var icon_name := str(STATUS_ICONS.get(status, "info"))
	line.add_child(Icons.rect(icon_name, Icons.size_for_scale(text_scale)))
	# Turns left are visible text when there is room (compact badges keep the
	# tooltip fallback so four badges still fit above a token).
	var count := "%d" % int(entry.get("stacks", 1))
	if str(entry.get("kind", "dot")) != "dot":
		count = "%d" % int(entry.get("charges", 0))
	elif not compact:
		count = "x%d %dt" % [int(entry.get("stacks", 1)), int(entry.get("turns", 0))]
	if not compact:
		line.add_child(UiKit.pixel_label(UiKit.status_tag(status), "small", color))
	line.add_child(UiKit.pixel_label(count, "small"))
	var result := UiKit.panel(line)
	result.add_theme_stylebox_override("panel", UiKit.flat_box(UiKit.STATUS_BG, color, 1, 3))
	result.tooltip_text = "%s: %s stack(s), %s turn(s) left" % [entry.get("name", status), entry.get("stacks", 1), entry.get("turns", 0)]
	return result


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
