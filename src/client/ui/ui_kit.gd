class_name UiKit
extends RefCounted
## The one client theme (Navy + Gold, docs/design/ui-style.md) and small widget
## helpers. Screens pick a type variation from `make_theme`; they never build
## their own StyleBoxes or write hex colours. Colours are never the only
## carrier of meaning: every coloured element also has a text label.

## --- Navy + Gold tokens ------------------------------------------------------
const BG := Color("#11162a")
const NAVY := Color("#1c2233")
const NAVY_RAISED := Color("#2a3147")
const NAVY_FOCUS := Color("#333c57")
const BORDER := Color("#b3b4c0")
const SLATE := Color("#454b5e")
const SLATE_HOVER := Color("#58607a")
const GOLD := Color("#f0c85a")
const TEXT := Color("#f2f2f5")
const TEXT_DIM := Color("#a9abb8")
const SUCCESS := Color("#83df76")
const WARN := Color("#f0a040")
const DANGER := Color("#e05a4f")
const ALLY := Color("#8fd0f0")
const ENEMY := Color("#f8aca0")
const DISABLED_BG := Color("#1f2536")
const DISABLED_TEXT := Color("#8a8fa3")
## Fill behind a Status badge; the badge text uses the colour from content.
const STATUS_BG := Color(0.05, 0.05, 0.06, 0.92)

## Older names, kept so every screen reads the same tokens.
const PANEL := NAVY
const PANEL_LIGHT := NAVY_RAISED
const PANEL_FOCUS := NAVY_FOCUS
const ACCENT := GOLD
const GOOD := SUCCESS
const HP_FILL := Color("#5fb563")
const HP_LOW := Color("#d9644f")

## Battle and camp overlays: navy at 88 % so they stay readable over the field.
const HUD_BG := Color(NAVY, 0.88)
const HUD_BG_LIGHT := Color(NAVY_RAISED, 0.92)
const HUD_BORDER := Color(BORDER, 0.9)
const BAR_HP := Color("#d8453c")
const BAR_ENERGY := Color("#3b9ae1")
const BAR_BACK := Color(0.06, 0.06, 0.07, 0.9)
const CLEAR := Color(0, 0, 0, 0)
## Status effect short tag. The colour comes from content (`statuses.<id>.color`,
## sent with every status view and tick); the tag is always drawn next to it
## so colour is never the only cue.
const STATUS_TAGS := {"bleed": "BLD", "poison": "PSN", "toxin": "TOX", "venom_coat": "PREP"}

## Base font sizes per label style; multiplied by the text-size setting.
const SIZES := {"tiny": 11, "small": 15, "body": 18, "heading": 23, "title": 34, "huge": 52}
## Pixelify Sans (OFL, assets/fonts/OFL.txt) for headings, buttons and names.
## Numeric labels use the Godot body font: its digits are deliberately easier
## to distinguish at a glance than Pixelify's 5/S and 7/1.
const PIXEL_FONT_PATH := "res://assets/fonts/PixelifySans.ttf"
const THAI_FONT_PATH := "res://assets/fonts/NotoSansThai-Regular.ttf"
const NO_LIGATURES := {"liga": 0, "clig": 0, "dlig": 0}
## Story files load the TTF directly; `.import` is not tracked, so apply overrides here.

static var _pixel_font: Font = null
static var _number_font: Font = null
static var _thai_font: FontFile = null


static func thai_font() -> FontFile:
	if _thai_font == null:
		_thai_font = load(THAI_FONT_PATH) as FontFile
	return _thai_font


static func pixel_font() -> Font:
	if _pixel_font == null:
		var file: FontFile = load(PIXEL_FONT_PATH)
		file.opentype_feature_overrides = NO_LIGATURES
		file.fallbacks = [thai_font()]
		var variation := FontVariation.new()
		variation.base_font = file
		variation.opentype_features = NO_LIGATURES
		_pixel_font = variation
	return _pixel_font


## The default body font has unambiguous numeric glyphs. Keep this in one
## place so screens do not have to choose a font for every stat or cost.
static func number_font() -> Font:
	if _number_font == null:
		_number_font = ThemeDB.fallback_font
	return _number_font


static func make_theme(scale: float) -> Theme:
	var theme := Theme.new()
	var pixel := pixel_font()
	var body_font := number_font()
	body_font.fallbacks = [thai_font()]
	theme.default_font = body_font
	theme.default_font_size = int(SIZES["body"] * scale)
	theme.set_constant("line_spacing", "Label", int(5 * scale))
	theme.set_constant("line_spacing", "Button", int(5 * scale))
	for style in SIZES:
		var variation: String = style.capitalize() + "Label"
		theme.set_type_variation(variation, "Label")
		theme.set_font_size("font_size", variation, int(SIZES[style] * scale))
		var pixel_variation: String = "Pixel" + variation
		theme.set_type_variation(pixel_variation, "Label")
		theme.set_font_size("font_size", pixel_variation, int(SIZES[style] * scale))
		theme.set_font("font", pixel_variation, pixel)
	for heading in ["HeadingLabel", "TitleLabel", "HugeLabel"]:
		theme.set_font("font", heading, pixel)
	theme.set_font("font", "Button", pixel)
	theme.set_color("font_color", "Label", TEXT)
	theme.set_type_variation("DimLabel", "Label")
	theme.set_color("font_color", "DimLabel", TEXT_DIM)
	theme.set_font_size("font_size", "DimLabel", int(SIZES["small"] * scale))

	theme.set_color("default_color", "RichTextLabel", TEXT)

	_panels(theme)
	_buttons(theme, scale)
	_inputs(theme, scale)
	_hud(theme, scale)
	return theme


## Panels: navy with diamonds by default, raised cards and rows inside them.
static func _panels(theme: Theme) -> void:
	theme.set_stylebox("panel", "PanelContainer", navy_box())
	theme.set_type_variation("NavyPanel", "PanelContainer")
	theme.set_stylebox("panel", "NavyPanel", navy_box())
	theme.set_type_variation("CardPanel", "PanelContainer")
	theme.set_stylebox("panel", "CardPanel", flat_box(NAVY_RAISED, Color(BORDER, 0.35), 1, 8))
	theme.set_type_variation("CompactPanel", "PanelContainer")
	theme.set_stylebox("panel", "CompactPanel", flat_box(NAVY_RAISED, Color(BORDER, 0.35), 1, 5))
	theme.set_type_variation("HighlightPanel", "PanelContainer")
	theme.set_stylebox("panel", "HighlightPanel", flat_box(NAVY_FOCUS, GOLD, 2, 8))
	theme.set_type_variation("CompactHighlightPanel", "PanelContainer")
	theme.set_stylebox("panel", "CompactHighlightPanel", flat_box(NAVY_FOCUS, GOLD, 2, 5))
	theme.set_type_variation("TitleTag", "PanelContainer")
	theme.set_stylebox("panel", "TitleTag", flat_box(NAVY_RAISED, BORDER, 2, 10))
	theme.set_type_variation("ToastPanel", "PanelContainer")
	theme.set_stylebox("panel", "ToastPanel", flat_box(NAVY, GOLD, 2, 10))
	theme.set_type_variation("IconPanel", "PanelContainer")
	theme.set_stylebox("panel", "IconPanel", flat_box(BG, Color(BORDER, 0.6), 2, 2))
	theme.set_type_variation("BadgePanel", "PanelContainer")
	var badge_box := flat_box(Color(0, 0, 0, 0.35), TEXT_DIM, 1, 4)
	badge_box.content_margin_top = 0
	badge_box.content_margin_bottom = 0
	theme.set_stylebox("panel", "BadgePanel", badge_box)
	var rule := StyleBoxLine.new()
	rule.color = Color(BORDER, 0.35)
	rule.thickness = 2
	theme.set_stylebox("separator", "HSeparator", rule)
	theme.set_constant("separation", "HSeparator", 10)
	theme.set_stylebox("panel", "TooltipPanel", flat_box(NAVY, GOLD, 1, 8))
	theme.set_color("font_color", "TooltipLabel", TEXT)


## Buttons: slate secondary (the default), gold primary, red danger, a
## selected state, round tabs. Every focus style is the same gold ring drawn
## just outside the button, so it shows on every fill.
static func _buttons(theme: Theme, scale: float) -> void:
	theme.set_type_variation("SecondaryButton", "Button")
	for type in ["Button", "SecondaryButton", "OptionButton"]:
		_button_look(theme, type, SLATE, Color(BORDER, 0.7), SLATE_HOVER, BORDER, TEXT, GOLD)
	theme.set_font("font", "Button", pixel_font())
	theme.set_font("font", "OptionButton", pixel_font())
	theme.set_type_variation("PrimaryButton", "Button")
	_button_look(theme, "PrimaryButton", GOLD, GOLD.darkened(0.35), GOLD.lightened(0.18), GOLD.lightened(0.4), NAVY, NAVY)
	theme.set_type_variation("DangerButton", "Button")
	_button_look(theme, "DangerButton", DANGER.darkened(0.55), DANGER, DANGER.darkened(0.4), DANGER.lightened(0.2), TEXT, TEXT)
	theme.set_type_variation("SelectedButton", "Button")
	_button_look(theme, "SelectedButton", NAVY_FOCUS, GOLD, NAVY_FOCUS.lightened(0.08), GOLD, GOLD, GOLD)
	for kind in ["", "Primary", "Danger"]:
		var big := "Big%sButton" % kind
		theme.set_type_variation(big, kind + "Button" if not kind.is_empty() else "Button")
		theme.set_font_size("font_size", big, int(SIZES["heading"] * scale))
	theme.set_type_variation("SmallButton", "Button")
	theme.set_font_size("font_size", "SmallButton", int(SIZES["small"] * scale))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var small: StyleBoxFlat = theme.get_stylebox(state, "Button").duplicate()
		small.content_margin_left = 6
		small.content_margin_right = 6
		small.content_margin_top = 2
		small.content_margin_bottom = 2
		theme.set_stylebox(state, "SmallButton", small)
	theme.set_type_variation("TabButton", "Button")
	_button_look(theme, "TabButton", NAVY, BORDER, SLATE_HOVER, TEXT, TEXT_DIM, TEXT)
	theme.set_type_variation("TabButtonSelected", "TabButton")
	_button_look(theme, "TabButtonSelected", NAVY_FOCUS, GOLD, NAVY_FOCUS.lightened(0.08), GOLD, GOLD, GOLD)
	for type in ["TabButton", "TabButtonSelected"]:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var round_box: StyleBoxFlat = theme.get_stylebox(state, type)
			round_box.set_corner_radius_all(40)
		theme.set_font_size("font_size", type, int(SIZES["title"] * scale))

	for state in ["normal", "pressed", "hover_pressed", "disabled"]:
		var empty := StyleBoxEmpty.new()
		empty.set_content_margin_all(4)
		theme.set_stylebox(state, "CheckButton", empty)
	theme.set_stylebox("hover", "CheckButton", flat_box(NAVY_RAISED, CLEAR, 0, 4))
	theme.set_stylebox("focus", "CheckButton", focus_ring())
	for type in ["CheckButton", "CheckBox"]:
		theme.set_color("font_color", type, TEXT)
		theme.set_color("font_hover_color", type, GOLD)
		theme.set_color("font_focus_color", type, GOLD)
		theme.set_color("font_pressed_color", type, TEXT)
		theme.set_color("font_hover_pressed_color", type, GOLD)
		theme.set_color("font_disabled_color", type, DISABLED_TEXT)
	theme.set_stylebox("panel", "PopupMenu", flat_box(NAVY, BORDER, 2, 6))
	theme.set_stylebox("hover", "PopupMenu", flat_box(SLATE_HOVER, GOLD, 1, 4))
	theme.set_color("font_color", "PopupMenu", TEXT)
	theme.set_color("font_hover_color", "PopupMenu", GOLD)
	theme.set_font("font", "PopupMenu", pixel_font())


static func _button_look(theme: Theme, type: String, fill: Color, edge: Color, hover_fill: Color, hover_edge: Color,
		font: Color, accent_font: Color) -> void:
	theme.set_stylebox("normal", type, flat_box(fill, edge, 2, 8))
	theme.set_stylebox("hover", type, flat_box(hover_fill, hover_edge, 2, 8))
	theme.set_stylebox("pressed", type, flat_box(fill.darkened(0.2), GOLD, 2, 8))
	theme.set_stylebox("hover_pressed", type, flat_box(hover_fill, GOLD, 2, 8))
	theme.set_stylebox("focus", type, focus_ring())
	theme.set_stylebox("disabled", type, flat_box(DISABLED_BG, Color(BORDER, 0.2), 2, 8))
	# Hover keeps the normal text colour (gold on the lighter hover fill would
	# be too faint); focus and pressed turn gold.
	theme.set_color("font_color", type, font)
	theme.set_color("font_hover_color", type, font)
	theme.set_color("font_focus_color", type, accent_font)
	theme.set_color("font_pressed_color", type, accent_font)
	theme.set_color("font_hover_pressed_color", type, accent_font)
	theme.set_color("font_disabled_color", type, DISABLED_TEXT)


## Text fields, sliders, bars and scrollbars.
static func _inputs(theme: Theme, _scale: float) -> void:
	theme.set_stylebox("normal", "LineEdit", flat_box(NAVY_RAISED, Color(BORDER, 0.55), 2, 10))
	theme.set_stylebox("focus", "LineEdit", flat_box(CLEAR, GOLD, 2, 10))
	theme.set_stylebox("read_only", "LineEdit", flat_box(DISABLED_BG, Color(BORDER, 0.2), 2, 10))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", TEXT_DIM)
	theme.set_color("caret_color", "LineEdit", GOLD)
	theme.set_color("selection_color", "LineEdit", Color(GOLD, 0.35))
	theme.set_color("clear_button_color", "LineEdit", TEXT_DIM)
	theme.set_color("clear_button_color_pressed", "LineEdit", GOLD)

	theme.set_stylebox("background", "ProgressBar", flat_box(BG, Color(BORDER, 0.35), 1, 0))
	theme.set_stylebox("fill", "ProgressBar", flat_box(SUCCESS, CLEAR, 0, 0))
	theme.set_color("font_color", "ProgressBar", TEXT)

	var track := flat_box(NAVY_RAISED, CLEAR, 0, 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", flat_box(GOLD, CLEAR, 0, 3))
	theme.set_stylebox("grabber_area_highlight", "HSlider", flat_box(GOLD.lightened(0.2), CLEAR, 0, 3))
	theme.set_stylebox("focus", "HSlider", focus_ring())

	for bar in ["VScrollBar", "HScrollBar"]:
		var lane := flat_box(Color(BG, 0.7), CLEAR, 0, 4)
		theme.set_stylebox("scroll", bar, lane)
		theme.set_stylebox("scroll_focus", bar, lane)
		theme.set_stylebox("grabber", bar, flat_box(SLATE, CLEAR, 0, 4))
		theme.set_stylebox("grabber_highlight", bar, flat_box(SLATE_HOVER, CLEAR, 0, 4))
		theme.set_stylebox("grabber_pressed", bar, flat_box(GOLD, CLEAR, 0, 4))


## Battle and camp overlays: navy at 88 % over the field.
static func _hud(theme: Theme, scale: float) -> void:
	theme.set_type_variation("HudPanel", "PanelContainer")
	theme.set_stylebox("panel", "HudPanel", flat_box(HUD_BG, HUD_BORDER, 2, 8))
	theme.set_type_variation("HudHighlightPanel", "PanelContainer")
	theme.set_stylebox("panel", "HudHighlightPanel", flat_box(HUD_BG, GOLD, 2, 6))
	theme.set_type_variation("HudWarnPanel", "PanelContainer")
	theme.set_stylebox("panel", "HudWarnPanel", flat_box(HUD_BG, WARN, 2, 8))
	theme.set_type_variation("HudCard", "PanelContainer")
	theme.set_stylebox("panel", "HudCard", flat_box(HUD_BG_LIGHT, CLEAR, 0, 6))
	theme.set_type_variation("BannerPanel", "PanelContainer")
	var band := flat_box(Color(NAVY, 0.94), GOLD, 0, 0)
	band.border_width_top = 2
	band.border_width_bottom = 2
	theme.set_stylebox("panel", "BannerPanel", band)
	theme.set_type_variation("HudButton", "Button")
	_button_look(theme, "HudButton", HUD_BG_LIGHT, Color(BORDER, 0.35), Color(SLATE_HOVER, 0.95), GOLD, TEXT, GOLD)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var hud_box: StyleBoxFlat = theme.get_stylebox(state, "HudButton")
		hud_box.set_border_width_all(1)
	theme.set_stylebox("disabled", "HudButton", flat_box(Color(DISABLED_BG, 0.9), Color(BORDER, 0.1), 1, 8))
	theme.set_font_size("font_size", "HudButton", int(SIZES["heading"] * scale))


static func box(bg: Color, border: Color, border_width: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(margin)
	return style


## Square-cornered box (the whole theme is square: AAC pixel look).
static func flat_box(bg: Color, border: Color, border_width: int, margin: int) -> StyleBoxFlat:
	return box(bg, border, border_width, margin)


## The gold focus ring: 2 px, drawn 3 px outside the control.
static func focus_ring() -> StyleBoxFlat:
	var ring := flat_box(CLEAR, GOLD, 2, 0)
	ring.draw_center = false
	ring.set_expand_margin_all(3)
	return ring


## The navy panel look: NAVY fill, 2 px BORDER, a small diamond on each corner.
## Also used by custom-drawn controls (the dialogue box) via draw_style_box.
static func navy_box(margin: int = 14, fill: Color = NAVY) -> StyleBox:
	var style := DiamondBox.new()
	style.fill = flat_box(fill, BORDER, 2, margin)
	style.set_content_margin_all(margin)
	return style


## A StyleBox that draws a flat box, then the corner diamonds of the AAC
## panels (refs 01-03) on top, so every navy panel gets them for free.
class DiamondBox extends StyleBox:
	var fill: StyleBoxFlat
	var diamond := 5.0
	var diamond_color := BORDER

	func _draw(to_canvas_item: RID, rect: Rect2) -> void:
		fill.draw(to_canvas_item, rect)
		var inset := Vector2(1, 1)
		var corners := [rect.position + inset, Vector2(rect.end.x - 1, rect.position.y + 1),
				Vector2(rect.position.x + 1, rect.end.y - 1), rect.end - inset]
		for corner: Vector2 in corners:
			RenderingServer.canvas_item_add_polygon(to_canvas_item, PackedVector2Array([
					corner + Vector2(0, -diamond), corner + Vector2(diamond, 0),
					corner + Vector2(0, diamond), corner + Vector2(-diamond, 0)]), PackedColorArray([diamond_color]))


## A single-line label whose numeric strings use the digit-safe body font.
## This is the central routing point so para(), badge() and every caller share
## the same rule.
static func pixel_label(text: String, style: String = "body", color: Color = Color(0, 0, 0, 0)) -> Label:
	var node := label(text, style, color)
	node.theme_type_variation = "Pixel" + style.capitalize() + "Label"
	return node


static func number_label(text: String, style: String = "body", color: Color = Color(0, 0, 0, 0)) -> Label:
	var node := label(text, style, color)
	node.add_theme_font_override("font", number_font())
	return node


static func _has_digit(text: String) -> bool:
	for i in text.length():
		var code := text.unicode_at(i)
		if code >= 48 and code <= 57:
			return true
	return false


static func _has_thai(text: String) -> bool:
	for i in text.length():
		var code := text.unicode_at(i)
		if code >= 0x0E00 and code <= 0x0E7F:
			return true
	return false


## A bar with its numbers written on it (HP in red, Energy in blue...).
static func stat_bar(value: int, max_value: int, color: Color, text: String, height: float = 18.0,
		style: String = "small") -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maxi(1, max_value)
	bar.value = clampi(value, 0, maxi(1, max_value))
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", flat_box(BAR_BACK, Color(0, 0, 0, 0), 0, 0))
	bar.add_theme_stylebox_override("fill", flat_box(color, Color(0, 0, 0, 0), 0, 0))
	if not text.is_empty():
		var caption := pixel_label(text, style)
		caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.add_theme_color_override("font_outline_color", Color.BLACK)
		caption.add_theme_constant_override("outline_size", 4)
		bar.add_child(caption)
	return bar


## Energy as `max_value` separate segments with "x/max" written over them.
static func energy_segments(value: int, max_value: int, height: float = 20.0, style: String = "small") -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, height)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := hbox(3)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in maxi(1, max_value):
		var cell := Panel.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_theme_stylebox_override("panel", flat_box(BAR_ENERGY if i < value else BAR_BACK,
				Color(1, 1, 1, 0.15), 1, 0))
		row.add_child(cell)
	holder.add_child(row)
	var caption := pixel_label("%d/%d" % [value, max_value], style)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_outline_color", Color.BLACK)
	caption.add_theme_constant_override("outline_size", 4)
	holder.add_child(caption)
	return holder


## The colour the server sent for a status ("#rrggbb"), or ACCENT.
static func status_color(html: String) -> Color:
	return Color(html) if Color.html_is_valid(html) else ACCENT


static func status_tag(status: String) -> String:
	return str(STATUS_TAGS.get(status, status.substr(0, 4).to_upper()))


## A small square badge for one Status effect: tag, stacks and turns left.
## `compact` drops the turns (still in the tooltip) so four badges fit in a
## row above a token.
static func status_badge(entry: Dictionary, compact: bool = false) -> PanelContainer:
	var status := str(entry.get("status", ""))
	var color := status_color(str(entry.get("color", "")))
	var line := hbox(2 if compact else 3)
	line.add_child(pixel_label(status_tag(status), "small", color))
	var count := "x%d %dt" % [int(entry.get("stacks", 1)), int(entry.get("turns", 0))]
	if compact:
		count = "%d" % int(entry.get("stacks", 1))
	if str(entry.get("kind", "dot")) != "dot":
		count = "%d" % int(entry.get("charges", 0))
	line.add_child(pixel_label(count, "small"))
	var badge_panel := panel(line)
	var style := flat_box(STATUS_BG, color, 2, 3)
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	badge_panel.add_theme_stylebox_override("panel", style)
	badge_panel.tooltip_text = Tr.t("%s: %s stack(s), %s turn(s) left" % [Tr.t(str(entry.get("name", status))),
			entry.get("stacks", 1), entry.get("turns", 0)])
	return badge_panel


## A single-line label (does not wrap; keep it short).
static func label(text: String, style: String = "body", color: Color = Color(0, 0, 0, 0)) -> Label:
	var node := Label.new()
	var display_text := Tr.t(text)
	node.text = display_text
	node.theme_type_variation = "DimLabel" if style == "dim" else style.capitalize() + "Label"
	if _has_thai(display_text):
		node.add_theme_font_override("font", number_font())
	if _has_digit(text):
		node.add_theme_font_override("font", number_font())
	if color.a > 0.0:
		node.add_theme_color_override("font_color", color)
	return node


## Wrapping text that fills the width it is given. Inside horizontal boxes
## give it (or its parent) a minimum width.
static func para(text: String, style: String = "body", color: Color = Color(0, 0, 0, 0), min_width: float = 0.0) -> Label:
	var node := label(text, style, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.custom_minimum_size = Vector2(min_width, 0)
	return node


## `kind`: "secondary" (default), "primary" (the one gold action of a panel),
## "danger" (destructive, ask first) or "small" (dense rows).
static func button(text: String, callback: Callable, big: bool = false, kind: String = "secondary") -> Button:
	var node := Button.new()
	var display_text := Tr.t(text)
	node.text = display_text
	node.focus_mode = Control.FOCUS_ALL
	node.theme_type_variation = button_variation(kind, big)
	if _has_digit(text):
		node.add_theme_font_override("font", number_font())
	if _has_thai(display_text):
		node.add_theme_font_override("font", number_font())
	node.pressed.connect(callback)
	return node


static func button_variation(kind: String, big: bool = false) -> String:
	match kind:
		"primary":
			return "BigPrimaryButton" if big else "PrimaryButton"
		"danger":
			return "BigDangerButton" if big else "DangerButton"
		"small":
			return "SmallButton"
		"selected":
			return "SelectedButton"
	return "BigButton" if big else ""


static func primary(text: String, callback: Callable, big: bool = true) -> Button:
	return button(text, callback, big, "primary")


## Disables `control` (when `off`) and says why in its tooltip.
static func disable(control: BaseButton, off: bool, reason: String) -> void:
	control.disabled = off
	if off:
		control.tooltip_text = Tr.t(reason)


static func vbox(separation: int = 8) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


static func hbox(separation: int = 8) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


## A row that wraps onto the next line when it runs out of width, so large
## text sizes never push controls off screen.
static func flow(separation: int = 8) -> HFlowContainer:
	var node := HFlowContainer.new()
	node.add_theme_constant_override("h_separation", separation)
	node.add_theme_constant_override("v_separation", separation)
	return node


static func panel(content: Control, variation: String = "") -> PanelContainer:
	var node := PanelContainer.new()
	if not variation.is_empty():
		node.theme_type_variation = variation
	node.add_child(content)
	return node


## A small framed tag such as "AI", "YOU" or "HOST".
static func badge(text: String, color: Color = TEXT_DIM) -> PanelContainer:
	return panel(label(text, "small", color), "BadgePanel")


## HP bar with the numbers always written on it.
static func hp_bar(hp: int, max_hp: int, width: float = 0.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maxi(1, max_hp)
	bar.value = hp
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, 20)
	var ratio := float(hp) / float(maxi(1, max_hp))
	bar.add_theme_stylebox_override("fill", box(HP_LOW if ratio < 0.35 else HP_FILL, Color(0, 0, 0, 0), 0, 0))
	var text := label("HP %d / %d" % [hp, max_hp], "small")
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_color_override("font_outline_color", Color.BLACK)
	text.add_theme_constant_override("outline_size", 4)
	bar.add_child(text)
	return bar


static func spacer() -> Control:
	var node := Control.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node


static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


## Focuses the first enabled button found under `node`.
static func focus_first(node: Node) -> bool:
	for child in node.get_children():
		if child is Button and not child.disabled and child.is_visible_in_tree():
			child.grab_focus()
			return true
		if focus_first(child):
			return true
	return false


static func key_hint(key: String) -> String:
	return "[%s]" % key
