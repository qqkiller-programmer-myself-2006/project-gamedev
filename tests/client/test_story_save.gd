extends "res://tests/test_case.gd"

const StorySaveScript = preload("res://src/client/story/story_save.gd")

var save = StorySaveScript.new()

func before_each() -> void:
	save.clear()

func after_each() -> void:
	save.clear()

func test_round_trip_and_clear() -> void:
	var data := {"seed": 42, "layer": 3, "party": [{"name":"Arin"}], "gold": 15}
	assert_true(save.save(data))
	assert_true(save.has_save())
	var loaded := save.load()
	assert_eq(loaded.seed, 42)
	assert_eq(loaded.layer, 3)
	assert_eq(loaded.version, 1)
	save.clear()
	assert_false(save.has_save())

func test_corrupt_file_is_offered_once_for_restore_validation() -> void:
	var file := FileAccess.open(StorySaveScript.PATH, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	assert_true(save.has_save())
	assert_eq(save.load(), {"version": 1, "_invalid": true})

func test_rejected_story_restore_clears_save_and_shows_error_once() -> void:
	assert_true(save.save({"seed": 42}))
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	var title := TitleScreen.new()
	app._current = title
	app.add_child(title)
	title.setup(app)
	app.story_launcher = StoryLauncher.new()

	app._on_result(1, {"type": "restore_story"}, {"ok": false, "error": "invalid_save"})

	assert_false(save.has_save())
	assert_true(title._status.visible)
	assert_eq(title._status.text, UiText.ERRORS["invalid_save"])
	for button in title.find_children("*", "Button", true, false):
		assert_ne(button.text, "Continue Story", "Continue disappears after the rejection")
	app.free()
