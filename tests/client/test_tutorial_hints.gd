extends TestCase


class FakeScreen extends Control:
	var received_key := -1

	func handle_key(_app: ClientApp, key: int) -> bool:
		received_key = key
		return true


class KeyBattle extends BattleView:
	var received_key := -1

	func handle_key(key: int) -> bool:
		received_key = key
		return true


class MemorySettings extends ClientSettings:
	var save_calls := 0

	func save() -> void:
		save_calls += 1


func test_hint_is_marked_seen_only_after_player_closes_it() -> void:
	var app := ClientApp.new()
	var memory_settings := MemorySettings.new()
	app.settings = memory_settings
	app._overlay_holder = Control.new()
	app.add_child(app._overlay_holder)

	app.hint("combat")

	assert_false(memory_settings.seen_hints.has("combat"))
	assert_eq(memory_settings.save_calls, 0)
	assert_eq(app._overlay_holder.get_child_count(), 1)

	app.close_hints()

	assert_true(memory_settings.seen_hints.has("combat"))
	assert_eq(memory_settings.save_calls, 1)
	app.free()


func test_screen_transition_does_not_mark_hint_seen() -> void:
	var app := ClientApp.new()
	var memory_settings := MemorySettings.new()
	app.settings = memory_settings
	app._overlay_holder = Control.new()
	app.add_child(app._overlay_holder)
	app.hint("combat")

	app.close_hints(false)

	assert_false(memory_settings.seen_hints.has("combat"))
	assert_eq(memory_settings.save_calls, 0)
	app.free()


func test_tip_only_consumes_h_and_escape_other_keys_reach_screen() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app._overlay_holder = Control.new()
	app._banner = PanelContainer.new()
	app._banner.visible = false
	app.add_child(app._overlay_holder)
	var screen := FakeScreen.new()
	app._current = screen
	app.hint("combat")

	var number_key := InputEventKey.new()
	number_key.keycode = KEY_1
	number_key.pressed = true
	app._unhandled_key_input(number_key)
	assert_eq(screen.received_key, KEY_1, "non-H keys pass through an open tip")
	assert_eq(app._overlay_holder.get_child_count(), 1)

	var h_key := InputEventKey.new()
	h_key.keycode = KEY_H
	h_key.pressed = true
	app._unhandled_key_input(h_key)
	assert_false(app._has_open_hint(), "H closes the tip")
	app._overlay_holder.get_child(0).free()
	app.hint("combat")
	var escape_key := InputEventKey.new()
	escape_key.keycode = KEY_ESCAPE
	escape_key.pressed = true
	app._unhandled_key_input(escape_key)
	assert_false(app._has_open_hint(), "Esc closes the tip")
	app.free()


func test_battle_tick_waiting_turn_deadline_and_story() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app._snapshot_server_time = 0.0
	app._snapshot_local_time = 0.0
	var screen := MatchScreen.new()
	screen.app = app
	var battle := BattleView.new()
	battle._app = app
	battle._screen = screen
	battle._countdown = Label.new()
	battle._combat = {"your_turn": false, "actor": "p0", "actor_controller": "human"}
	battle._deadline = 100.0
	battle.tick()
	assert_eq(battle._countdown.text, "Waiting for p0 to act...")

	battle._combat["your_turn"] = true
	battle._deadline = 1000000.0
	battle.tick()
	assert_true(battle._countdown.text.ends_with("s"), "active turns show seconds")

	battle._deadline = -1.0
	battle.tick()
	assert_eq(battle._countdown.text, "", "story turns have no countdown")
	app.free()


func test_story_deadlines_have_no_timer() -> void:
	assert_false(ClientApp.has_timer(null), "null deadlines are untimed")
	assert_false(ClientApp.has_timer(-1.0), "negative deadlines are untimed")
	assert_true(ClientApp.has_timer(10.0), "positive deadlines remain timed")


func test_action_banner_keeps_hud_and_match_keys_flow_through() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	var battle := BattleView.new()
	battle._app = app
	battle._combat = {}
	battle._bottom = VBoxContainer.new()
	var row := Control.new()
	row.set_meta("combat_action_row", true)
	battle._bottom.add_child(row)
	battle._banner = PanelContainer.new()
	battle._banner_label = Label.new()
	battle._banner.add_child(battle._banner_label)
	battle.announce("Frost Lance")
	assert_true(row.visible, "the HUD action row stays visible during a banner")

	var screen := MatchScreen.new()
	var key_battle := KeyBattle.new()
	screen._battle_mode = true
	screen._battle = key_battle
	assert_true(screen.handle_key(app, KEY_1))
	assert_eq(key_battle.received_key, KEY_1, "match keys reach battle while a banner is visible")
	battle.queue_free()
	app.free()
