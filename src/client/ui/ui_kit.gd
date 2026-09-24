class_name UiKit
extends RefCounted
## Theme and small widget helpers for the client. Colours are never the
## only carrier of meaning: every coloured element also has a text label.

const BG := Color("#141d18")
const PANEL := Color("#1f2c25")
const PANEL_LIGHT := Color("#2b3c33")
const PANEL_FOCUS := Color("#3a5244")
const BORDER := Color("#5f8065")
const ACCENT := Color("#f0c85c")
const TEXT := Color("#f4f0e6")
const TEXT_DIM := Color("#c3cbbf")
const ALLY := Color("#8fd0f0")
const ENEMY := Color("#f29384")
const GOOD := Color("#8ad98a")
const WARN := Color("#f5b25e")
const HP_FILL := Color("#5fb563")
const HP_LOW := Color("#d9644f")

## Base font sizes per label style; multiplied by the text-size setting.
const SIZES := {"small": 15, "body": 18, "heading": 23, "title": 34, "huge": 52}


static func make_theme(scale: float) -> Theme:
	var theme := Theme.new()
	theme.default_font_size = int(SIZES["body"] * scale)
	for style in SIZES:
		var variation: String = style.capitalize() + "Label"
		theme.set_type_variation(variation, "Label")
		theme.set_font_size("font_size", variation, int(SIZES[style] * scale))
	theme.set_color("font_color", "Label", TEXT)
	theme.set_type_variation("DimLabel", "Label")
	theme.set_color("font_color", "DimLabel", TEXT_DIM)
	theme.set_font_size("font_size", "DimLabel", int(SIZES["small"] * scale))

	theme.set_stylebox("panel", "PanelContainer", box(PANEL, BORDER, 1, 10))
	theme.set_type_variation("CardPanel", "PanelContainer")
	theme.set_stylebox("panel", "CardPanel", box(PANEL_LIGHT, BORDER, 1, 8))
	theme.set_type_variation("HighlightPanel", "PanelContainer")
	theme.set_stylebox("panel", "HighlightPanel", box(PANEL_FOCUS, ACCENT, 3, 8))
	theme.set_type_variation("CompactPanel", "PanelContainer")
	theme.set_stylebox("panel", "CompactPanel", box(PANEL_LIGHT, BORDER, 1, 5))
	theme.set_type_variation("CompactHighlightPanel", "PanelContainer")
	theme.set_stylebox("panel", "CompactHighlightPanel", box(PANEL_FOCUS, ACCENT, 3, 5))
	theme.set_type_variation("BadgePanel", "PanelContainer")
	var badge_box := box(Color(0, 0, 0, 0.35), TEXT_DIM, 1, 4)
	badge_box.content_margin_top = 0
	badge_box.content_margin_bottom = 0
	theme.set_stylebox("panel", "BadgePanel", badge_box)

	theme.set_stylebox("normal", "Button", box(PANEL_LIGHT, BORDER, 1, 8))
	theme.set_stylebox("hover", "Button", box(PANEL_FOCUS, ACCENT, 1, 8))
	theme.set_stylebox("pressed", "Button", box(PANEL_FOCUS, ACCENT, 2, 8))
	theme.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), ACCENT, 3, 8))
	theme.set_stylebox("disabled", "Button", box(Color("#1a221e"), Color("#3c4a41"), 1, 8))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", ACCENT)
	theme.set_color("font_focus_color", "Button", ACCENT)
	theme.set_color("font_pressed_color", "Button", ACCENT)
	theme.set_color("font_disabled_color", "Button", Color("#8a948b"))
	theme.set_type_variation("BigButton", "Button")
	theme.set_font_size("font_size", "BigButton", int(SIZES["heading"] * scale))

	theme.set_stylebox("normal", "LineEdit", box(Color("#0f1612"), BORDER, 1, 10))
	theme.set_stylebox("focus", "LineEdit", box(Color("#0f1612"), ACCENT, 3, 10))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", Color("#8c978d"))

	theme.set_stylebox("background", "ProgressBar", box(Color("#0f1612"), BORDER, 1, 0))
	theme.set_stylebox("fill", "ProgressBar", box(HP_FILL, Color(0, 0, 0, 0), 0, 0))
	theme.set_color("font_color", "ProgressBar", TEXT)

	theme.set_stylebox("panel", "TooltipPanel", box(Color("#0c120e"), ACCENT, 1, 8))
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_font_size("font_size", "TooltipLabel", int(SIZES["body"] * scale))
	return theme


static func box(bg: Color, border: Color, border_width: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(margin)
	return style


## A single-line label (does not wrap; keep it short).
static func label(text: String, style: String = "body", color: Color = Color(0, 0, 0, 0)) -> Label:
	var node := Label.new()
	node.text = text
	node.theme_type_variation = "DimLabel" if style == "dim" else style.capitalize() + "Label"
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


static func button(text: String, callback: Callable, big: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_ALL
	if big:
		node.theme_type_variation = "BigButton"
	node.pressed.connect(callback)
	return node


static func vbox(separation: int = 8) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


static func hbox(separation: int = 8) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
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
