extends "res://tests/test_case.gd"

func test_story_content_schema() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://content/story_mode.json"))
	assert_true(data is Dictionary)
	assert_between(data.prologue.size(), 6, 10)
	for chapter in data.chapters:
		assert_false(str(chapter.title).is_empty())
	var required := ["first_combat_won", "class_gained", "story_clue", "merchant_first", "rest_first", "before_boss", "boss_won", "party_defeated"]
	for trigger in required:
		assert_true(data.scenes.has(trigger), "missing %s" % trigger)
		assert_between(data.scenes[trigger].size(), 3, 8)
		for line in data.scenes[trigger]:
			assert_has(["arin", "bram", "cora", "dain", "wren", "narrator"], line.speaker)
			assert_false(str(line.text).strip_edges().is_empty())

func test_chapters_cover_layers_and_boss() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://content/story_mode.json"))
	var numbers := []
	for chapter in data.chapters: numbers.append(int(chapter.number))
	for number in [1, 2, 3, 4, 5, 6]: assert_has(numbers, number)


func test_defeat_epilogue_is_not_specific_to_the_cave() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://content/story_mode.json"))
	var text := " ".join(data.scenes.party_defeated.map(func(line: Dictionary) -> String: return str(line.text)))
	assert_false(text.to_lower().contains("cave"))
	assert_false(text.to_lower().contains("guardian"))
