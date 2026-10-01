extends "res://tests/test_case.gd"
## Nameplate names and HP/Energy captions follow the text-size setting
## (client review C23).


func _plate_font_sizes(scale: float) -> Array[int]:
	var token := BattleToken.new()
	token.text_scale = scale
	token.setup({"id": "p1", "side": "party", "name": "Arin", "kind": "swordsman", "hp": 20, "max_hp": 30,
			"energy": 2, "energy_max": 6, "statuses": []})
	var sizes: Array[int] = []
	_collect_label_sizes(token, sizes)
	token.free()
	return sizes


func _collect_label_sizes(node: Node, sizes: Array[int]) -> void:
	if node is Label and node.has_theme_font_size_override("font_size"):
		sizes.append(node.get_theme_font_size("font_size"))
	for child in node.get_children():
		_collect_label_sizes(child, sizes)


func test_plate_text_grows_with_text_scale() -> void:
	var normal := _plate_font_sizes(1.0)
	var large := _plate_font_sizes(1.45)
	assert_true(normal.size() >= 3, "name, HP and Energy captions are sized")
	assert_eq(normal.size(), large.size(), "same labels at both scales")
	for i in mini(normal.size(), large.size()):
		assert_true(large[i] > normal[i], "label %d is larger at 1.45 (%d vs %d)" % [i, large[i], normal[i]])


func test_default_scale_keeps_readable_name_and_compact_stat_text() -> void:
	var sizes := _plate_font_sizes(1.0)
	assert_true(sizes.size() >= 3, "name, HP and Energy captions are sized")
	assert_eq(sizes[0], 12, "nameplate names use the readable 12 px size")
	for i in range(1, sizes.size()):
		assert_eq(sizes[i], 10, "compact nameplate stats stay 10 px")
