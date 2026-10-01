extends TestCase


class FakeStoryApp extends ClientApp:
	var started_classes: Array = []

	func start_story(classes: Array = [], _restore: Dictionary = {}, _seed_value: int = 0) -> void:
		started_classes = classes.duplicate()


func _title(text_scale: float = 1.0) -> Array:
	var app := FakeStoryApp.new()
	app.settings = ClientSettings.new()
	app.settings.text_scale = text_scale
	app.options = {}
	app.apply_settings()
	var title := TitleScreen.new()
	title.size = Vector2(1280, 720)
	title.theme = app.theme
	app.add_child(title)
	title.setup(app)
	title._show_story_setup()
	return [app, title]


func test_default_choices_unchanged() -> void:
	var pair := _title()
	var app: FakeStoryApp = pair[0]
	var title: TitleScreen = pair[1]
	assert_eq(title._story_classes, ["swordsman", "archer", "mage", "guardian", "assassin"])
	app.free()


func test_picker_selection_updates_row_and_begin_story_ids() -> void:
	var pair := _title()
	var app: FakeStoryApp = pair[0]
	var title: TitleScreen = pair[1]
	title._open_story_picker(2)
	title._select_story_class(4)
	assert_eq(title._story_classes[2], "assassin")
	assert_eq(title._story_picks[2].text, "Assassin")
	title._begin_story()
	assert_eq(app.started_classes, ["swordsman", "archer", "assassin", "guardian", "assassin"])
	app.free()


func test_number_shortcut_selects_and_escape_closes_without_change() -> void:
	var pair := _title()
	var app: FakeStoryApp = pair[0]
	var title: TitleScreen = pair[1]
	title._open_story_picker(0)
	assert_true(title.handle_key(app, KEY_3))
	assert_eq(title._story_classes[0], "mage")
	title._open_story_picker(1)
	var before: String = title._story_classes[1]
	assert_true(title.handle_key(app, KEY_ESCAPE))
	assert_eq(title._story_classes[1], before)
	assert_true(title._story_picker == null)
	app.free()


func test_escape_closes_picker_before_leaving_story_setup() -> void:
	var pair := _title()
	var app: FakeStoryApp = pair[0]
	var title: TitleScreen = pair[1]
	title._open_story_picker(0)
	assert_true(title.handle_key(app, KEY_ESCAPE))
	assert_true(title._story_picker == null)
	assert_eq(title._view, "story_setup")
	assert_true(title.handle_key(app, KEY_ESCAPE))
	assert_eq(title._view, "play")
	app.free()


func test_back_button_frees_open_picker() -> void:
	var pair := _title()
	var app: FakeStoryApp = pair[0]
	var title: TitleScreen = pair[1]
	title._open_story_picker(0)
	title._show_play()
	assert_true(title._story_picker == null)
	app.free()


func test_picker_cards_use_theme_variations_for_selection() -> void:
	var pair := _title()
	var app: FakeStoryApp = pair[0]
	var title: TitleScreen = pair[1]
	title._open_story_picker(0)
	for i in title._story_cards.size():
		var expected := "SelectedButton" if i == 0 else "HudButton"
		assert_eq(title._story_cards[i].theme_type_variation, expected)
	app.free()


func test_arrows_and_tab_cycle_picker_cards_without_committing() -> void:
	var pair := _title()
	var app: FakeStoryApp = pair[0]
	var title: TitleScreen = pair[1]
	title._open_story_picker(0)
	assert_true(title.handle_key(app, KEY_RIGHT))
	assert_eq(title._story_card_index, 1)
	assert_true(title.handle_key(app, KEY_TAB))
	assert_eq(title._story_card_index, 2)
	assert_true(title.handle_key(app, KEY_LEFT))
	assert_eq(title._story_card_index, 1)
	assert_eq(title._story_classes[0], "swordsman")
	app.free()


func test_picker_fits_supported_resolutions_at_large_text_scale() -> void:
	var pair := _title(1.4)
	var app: FakeStoryApp = pair[0]
	var title: TitleScreen = pair[1]
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		title.size = Vector2(resolution)
		title._open_story_picker(0)
		var picker := title._story_picker
		var rect := Rect2(Vector2(picker.offset_left, picker.offset_top),
				Vector2(resolution.x + picker.offset_right - picker.offset_left,
					resolution.y + picker.offset_bottom - picker.offset_top))
		assert_true(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(rect),
				"picker panel stays in the viewport at %s" % resolution)
		assert_eq(title._story_cards.size(), 5)
		assert_true(title._story_cards[0].custom_minimum_size.y >= 310.0,
				"cards keep the portrait and text layout at text scale 1.4")
		title._close_story_picker(false)
	app.free()
