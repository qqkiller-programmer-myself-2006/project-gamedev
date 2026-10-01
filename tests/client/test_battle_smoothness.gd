extends "res://tests/test_case.gd"


func test_token_node_identity_survives_consecutive_snapshot_updates() -> void:
	var token := BattleToken.new()
	token.setup({"id": "e0", "side": "enemy", "name": "Wolf", "kind": "grey_wolf",
			"hp": 20, "max_hp": 20, "reduced_motion": true})
	var identity := token.get_instance_id()
	token.update_data({"id": "e0", "side": "enemy", "name": "Wolf", "kind": "grey_wolf",
			"hp": 12, "max_hp": 20, "reduced_motion": true})
	assert_eq(token.get_instance_id(), identity)
	token.free()


func test_reduced_motion_applies_hp_update_immediately() -> void:
	var token := BattleToken.new()
	token.setup({"id": "e0", "side": "enemy", "name": "Wolf", "kind": "grey_wolf",
			"hp": 20, "max_hp": 20, "reduced_motion": true})
	token.update_data({"id": "e0", "side": "enemy", "name": "Wolf", "kind": "grey_wolf",
			"hp": 7, "max_hp": 20, "reduced_motion": true})
	assert_eq(_bar_value(token), 7.0)
	token.free()


func test_forest_content_is_parsed_once_for_multiple_battle_builds() -> void:
	BattleView._forest_content.clear()
	BattleView.forest_parse_count = 0
	for _i in 5:
		BattleView._load_forest_content()
	assert_eq(BattleView.forest_parse_count, 1)
	assert_false(BattleView._load_forest_content().is_empty())


func _bar_value(token: BattleToken) -> float:
	return token._hp_bar.value
