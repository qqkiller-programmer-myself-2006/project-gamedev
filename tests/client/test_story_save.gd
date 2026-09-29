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

func test_corrupt_file_is_no_save() -> void:
	var file := FileAccess.open(StorySaveScript.PATH, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	assert_false(save.has_save())
