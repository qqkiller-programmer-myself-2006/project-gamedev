extends TestCase
## The client palette meets WCAG 2.1 AA contrast for text (4.5:1) on every
## background it is drawn on (issue #17). Disabled buttons stay readable
## (3:1) even though WCAG exempts them.

const TEXT_COLORS := {
	"TEXT": UiKit.TEXT, "TEXT_DIM": UiKit.TEXT_DIM, "ACCENT": UiKit.ACCENT, "ALLY": UiKit.ALLY,
	"ENEMY": UiKit.ENEMY, "GOOD": UiKit.GOOD, "WARN": UiKit.WARN,
}
const BACKGROUNDS := {"BG": UiKit.BG, "NAVY": UiKit.NAVY, "NAVY_RAISED": UiKit.NAVY_RAISED, "NAVY_FOCUS": UiKit.NAVY_FOCUS}


func test_text_colours_meet_wcag_aa_on_every_panel() -> void:
	for text_name in TEXT_COLORS:
		for bg_name in BACKGROUNDS:
			var ratio := contrast(TEXT_COLORS[text_name], BACKGROUNDS[bg_name])
			assert_true(ratio >= 4.5, "%s on %s is %.2f:1" % [text_name, bg_name, ratio])


func test_status_badge_colours_from_content_are_readable() -> void:
	var content := ForestContent.load_default()
	var badge_bg := Color(0.05, 0.05, 0.06)
	for status in content.get_dict("statuses"):
		var colour := UiKit.status_color(str(content.get_value("statuses.%s.color" % status, "")))
		var ratio := contrast(colour, badge_bg)
		assert_true(ratio >= 4.5, "%s badge text %.2f:1" % [status, ratio])


func test_disabled_button_text_stays_readable() -> void:
	var ratio := contrast(UiKit.DISABLED_TEXT, UiKit.DISABLED_BG)
	assert_true(ratio >= 3.0, "disabled text %.2f:1" % ratio)


func test_button_text_is_readable_on_every_button_fill() -> void:
	var pairs := {"primary": [UiKit.NAVY, UiKit.GOLD], "secondary": [UiKit.TEXT, UiKit.SLATE],
			"secondary hover": [UiKit.TEXT, UiKit.SLATE_HOVER],
			"secondary focus": [UiKit.GOLD, UiKit.SLATE], "selected": [UiKit.GOLD, UiKit.NAVY_FOCUS.lightened(0.08)], "danger": [UiKit.TEXT, UiKit.DANGER.darkened(0.55)]}
	for name in pairs:
		var ratio := contrast(pairs[name][0], pairs[name][1])
		assert_true(ratio >= 4.5, "%s button text %.2f:1" % [name, ratio])


func test_theme_has_the_navy_and_gold_variations() -> void:
	var theme := UiKit.make_theme(1.0)
	for variation in ["NavyPanel", "CardPanel", "CompactPanel", "TitleTag", "HudPanel", "ToastPanel",
			"PrimaryButton", "SecondaryButton", "DangerButton", "BigPrimaryButton", "SelectedButton", "TabButton"]:
		assert_true(theme.is_type_variation(variation, theme.get_type_variation_base(variation)),
				"%s is a variation" % variation)
	var primary: StyleBoxFlat = theme.get_stylebox("normal", "PrimaryButton")
	assert_eq(primary.bg_color, UiKit.GOLD, "primary buttons are gold")
	var focus: StyleBoxFlat = theme.get_stylebox("focus", "Button")
	assert_eq(focus.border_color, UiKit.GOLD, "focus ring is gold")
	assert_true(focus.expand_margin_left > 0.0, "focus ring sits outside the button")
	var hud: StyleBoxFlat = theme.get_stylebox("panel", "HudPanel")
	assert_true(is_equal_approx(hud.bg_color.a, 0.88), "battle HUD is navy at 88%")


func test_hp_bar_text_is_outlined_on_both_fills() -> void:
	var bar := UiKit.hp_bar(10, 40)
	var label: Label = bar.get_child(0)
	assert_true(label.get_theme_constant("outline_size") >= 3, "outline keeps numbers readable on any fill")
	assert_eq(label.text, "HP 10 / 40", "numbers, not just a coloured bar")
	bar.free()


static func contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func _luminance(c: Color) -> float:
	var channels := []
	for v in [c.r, c.g, c.b]:
		channels.append(v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
