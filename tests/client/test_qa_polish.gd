extends "res://tests/test_case.gd"
## T29 QA polish: region name per Layer, class display names, nameplate width,
## no "shared Gold" wording.


func test_region_name_per_layer_comes_from_content() -> void:
	var content := ForestContent.load_default().data
	for layer in range(1, 5):
		assert_eq(UiText.region_name(content, layer), "Forest", "Layer %d is in the Forest" % layer)
	assert_eq(UiText.region_name(content, 5), "Cave", "Layer 5 is in the Cave")
	assert_eq(UiText.region_name(content, 5, true), "Cave", "the Boss fight is in the Cave")


func test_region_name_falls_back_to_forest() -> void:
	assert_eq(UiText.region_name({}, 3), "Forest")
	assert_eq(UiText.region_name({}, 5, true), "Forest")


func test_region_of_reads_boss_from_the_snapshot() -> void:
	assert_eq(UiText.region_of({"layer": 5, "phase": "boss"}), "Cave")
	assert_eq(UiText.region_of({"layer": 2, "phase": "combat"}), "Forest")
	assert_eq(UiText.region_of({"layer": 5, "phase": "combat"}), "Cave")


func test_every_class_has_a_capitalised_display_name() -> void:
	var classes := ForestContent.load_default().get_dict("classes")
	assert_true(classes.size() >= 5, "the Classes are in content")
	for id in classes:
		var shown := UiText.class_display(classes, str(id))
		assert_eq(shown, str(id).capitalize(), "%s is shown as %s" % [id, str(id).capitalize()])
	assert_eq(UiText.class_display({}, "assassin"), "Assassin", "fallback capitalises the id")


func test_nameplates_stay_inside_their_slot_at_every_text_size() -> void:
	for scale in [1.0, 1.2, 1.4, 1.5]:
		var token := BattleToken.new()
		token.text_scale = scale
		token.setup({"id": "p0", "side": "party", "name": "Arin", "kind": "swordsman", "hp": 20, "max_hp": 30,
				"energy": 1, "energy_max": 6, "statuses": [], "you": true})
		assert_true(token.size.x <= 156.0, "plate width %s <= 156 at text %s" % [token.size.x, scale])
		token.free()


func test_gold_tips_do_not_say_shared() -> void:
	for text in [UiText.HINTS["merchant"], UiText.TYPE_HELP["merchant"]]:
		assert_true(not text.contains("shared Gold"), "Gold is personal: %s" % text)
	assert_true(UiText.HINTS["merchant"].contains("own Gold"))
