extends TestCase


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
