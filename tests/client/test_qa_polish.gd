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
	assert_eq(UiText.region_text("Guardian of the Forest", {"layer": 5, "phase": "boss"}), "Guardian of the Cave")
	assert_eq(UiText.region_text("The Forest waits", {"layer": 2, "phase": "combat"}), "The Forest waits")


func test_item_ids_use_content_names_in_client_text() -> void:
	assert_eq(UiText.item_name("herb"), "Healing Herb")
	assert_eq(UiText.item_name("forest_tonic"), "Forest Tonic")
	assert_eq(UiText.item_name("unknown_item"), "Unknown Item", "unknown ids keep a readable fallback")


func test_battle_encounter_caption_has_no_placeholder_target_text() -> void:
	var battle := BattleView.new()
	battle._region = Label.new()
	battle._region_sub = Label.new()
	battle._combat = {}
	battle._build_region({"phase": "combat", "layer": 1, "layers_total": 5,
		"encounter": {"kind": "combat", "name": "Wolf Trail"}})
	assert_eq(battle._region_sub.text, "\"Wolf Trail\"")
	assert_false(battle._region_sub.text.contains("All"), "placeholder target text is removed")
	battle.free()


func test_camp_uses_the_content_backdrop_for_each_region() -> void:
	var content := ForestContent.load_default().data
	assert_eq(CampView.backdrop_for_layer(content, 1), "forest")
	assert_eq(CampView.backdrop_for_layer(content, 5), "cave")


func test_floating_damage_numbers_queue_without_overlap() -> void:
	var screen := MatchScreen.new()
	var first: int = screen._queue_float_start("e0", 1000)
	var second: int = screen._queue_float_start("e0", 1000)
	assert_eq(first, 1000, "the first floating number starts immediately")
	assert_eq(second, 1720, "the next number for the same card waits for the first")
	screen.free()


func test_large_camp_layout_uses_vertical_scroll_and_keeps_equipment_column() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app.settings.text_scale = 1.45
	app.settings.seen_hints.append("merchant")
	app.sounds = SoundBank.new()
	app._overlay_holder = Control.new()
	app.add_child(app._overlay_holder)
	app.snapshot = {"room": {"your_slot": 0, "story": false, "slots": []}, "match": {"story": false}}
	var screen := MatchScreen.new()
	screen.app = app
	var camp := CampView.new()
	camp.setup(screen, app)
	camp.build({"layer": 1, "layers_total": 5, "gold": 100, "party": [], "inventory": []}, {
		"kind": "merchant", "name": "Mar", "you_are_ready": false, "stock": [],
	})
	assert_eq((camp._workspace as ScrollContainer).horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED)
	assert_eq((camp._workspace as ScrollContainer).vertical_scroll_mode, ScrollContainer.SCROLL_MODE_AUTO)
	assert_true(camp._columns is VBoxContainer, "large text stacks camp sections vertically")
	assert_true(camp._columns.get_child_count() >= 4, "equipment remains in the vertically scrollable workspace")
	camp.free()
	screen.free()
	app.free()


func test_hp_bars_share_battle_color_and_room_for_large_text() -> void:
	var bar := UiKit.hp_bar(10, 20)
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	assert_eq(fill.bg_color, UiKit.BAR_HP, "party and battle HP fills use one color")
	assert_eq(bar.custom_minimum_size.y, 30.0, "large HP digits fit inside the bar")
	bar.free()


func test_defeated_tokens_keep_their_down_state_after_a_hit() -> void:
	var token := BattleToken.new()
	token.setup({"id": "e0", "side": "enemy", "name": "Wolf", "kind": "grey_wolf", "hp": 8, "max_hp": 20})
	token.play_animation("dead")
	assert_true(token.down, "death state is applied even when there is no sprite animation")
	assert_eq(token.modulate, Color(0.55, 0.55, 0.55, 0.85), "the defeated token remains dim")
	token.free()


func test_merchant_buy_confirmation_exists() -> void:
	assert_true(UiText.CONFIRM.has("buy_item"), "merchant purchases have a confirmation template")
	assert_true(UiText.CONFIRM["buy_item"][0].contains("%s"))
	assert_true(UiText.CONFIRM["buy_item"][1].contains("%d"))
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app.settings.seen_hints.append("merchant")
	app._overlay_holder = Control.new()
	app.add_child(app._overlay_holder)
	app.snapshot = {"room": {"your_slot": 0, "slots": []}}
	var screen := MatchScreen.new()
	screen.app = app
	var merchant := MerchantPanel.new()
	merchant.build(screen, app, {"gold": 50, "encounter": {
		"name": "The Shop", "greeting": "Welcome.", "deadline": -1.0, "you_are_ready": false,
		"ready": [], "stock": [{"item": "herb", "name": "Healing Herb", "price": 10,
			"remaining": 2, "affordable": true, "description": "Restores HP."}]}})
	assert_true(merchant.handle_key(screen, app, KEY_1), "the shortcut is handled")
	assert_true(app._overlay_holder.get_child(0) is ConfirmDialog, "the shortcut opens a confirmation before buying")
	var dialog := app._overlay_holder.get_child(0) as ConfirmDialog
	assert_true(_node_has_text(dialog, "Buy Healing Herb?"), "the dialog names the item")
	assert_true(_node_has_text(dialog, "Spend 10 Gold"), "the dialog states the price")
	merchant.free()
	screen.free()
	app.free()


func _node_has_text(node: Node, wanted: String) -> bool:
	if node is Label and str(node.text).contains(wanted):
		return true
	if node is Button and str(node.text).contains(wanted):
		return true
	for child in node.get_children():
		if _node_has_text(child, wanted):
			return true
	return false


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


func test_battle_token_updates_keep_node_and_apply_reduced_motion_bars() -> void:
	var token := BattleToken.new()
	var data := {"id": "p0", "side": "party", "name": "Arin", "kind": "swordsman", "hp": 20,
		"max_hp": 30, "energy": 3, "energy_max": 6, "statuses": [], "reduced_motion": true}
	token.setup(data)
	var instance_id := token.get_instance_id()
	data["hp"] = 10
	data["energy"] = 2
	token.update_data(data)
	assert_eq(token.get_instance_id(), instance_id, "snapshot updates retain the existing stage token")
	assert_eq(token._hp_bar.value, 10.0, "reduced motion applies the new HP immediately")
	assert_eq(token._energy_bar.value, 2.0, "reduced motion applies the new Energy immediately")
	token.free()


func test_battle_item_labels_use_content_names() -> void:
	assert_eq(UiText.item_name("herb"), "Healing Herb")
	assert_eq(UiText.item_name("tonic"), "Forest Tonic")


func test_battle_event_log_translates_names_and_combat_pattern() -> void:
	Tr.setup("th")
	var screen := MatchScreen.new()
	screen.names = {"p0": "Arin", "e0": "Goblin"}
	var line := screen._describe_action({
		"actor": "p0", "action": "attack", "results": [{"target": "e0", "damage": 15, "crit": true}],
	})
	assert_true(line.contains("อาริน") and line.contains("โจมตี"), "event log translates actor and action")
	assert_true(line.contains("ก็อบลิน") and line.contains("ได้รับความเสียหาย 15"), "event log translates target and hit")
	assert_false(line.contains("attacks") or line.contains("takes"), "event log does not leak English combat verbs")
	screen.free()
	Tr.setup("en")


func test_trainer_sprite_uses_hero_scale_and_down_tint_survives_flashes() -> void:
	var trainer := BattleToken.new()
	trainer.setup({"id": "e0", "side": "enemy", "name": "Trainer", "kind": "thief", "sprite": "thief",
		"trainer": true, "hp": 10, "max_hp": 10})
	assert_true(trainer.figure_height >= 92.0, "trainer sprites are raised to the hero display size")
	trainer.setup({"id": "e0", "side": "enemy", "name": "Trainer", "kind": "thief", "sprite": "thief",
		"trainer": true, "hp": 0, "max_hp": 10})
	trainer.play_animation("dead")
	assert_eq(trainer.modulate, Color(0.55, 0.55, 0.55, 0.85), "down tint remains on the defeated trainer")
	trainer.free()


func test_gold_tips_do_not_say_shared() -> void:
	for text in [UiText.HINTS["merchant"], UiText.TYPE_HELP["merchant"]]:
		assert_true(not text.contains("shared Gold"), "Gold is personal: %s" % text)
	assert_true(UiText.HINTS["merchant"].contains("own Gold"))
