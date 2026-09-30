extends TestCase


class FakeConnection extends ServerConnection:
	var close_reason := ""
	var connect_error: Error = OK

	func connect_to(_server_url: String) -> Error:
		return connect_error

	func close(reason: String = "closed") -> void:
		close_reason = reason


class TestClientApp extends ClientApp:
	var connection_error := ""
	var shown_screen := ""
	var toast_message := ""

	func _show_screen(screen: String) -> void:
		shown_screen = screen
		_current_name = screen

	func _show_connection_error(reason: String) -> void:
		connection_error = reason

	func toast(message: String, _seconds: float = 4.0) -> void:
		toast_message = message


func test_connect_timeout_closes_transport_and_shows_error() -> void:
	var app := TestClientApp.new()
	app.configure({"connect_timeout_seconds": 0.0})
	var transport := FakeConnection.new()
	var action_calls := [0]
	app.connect_and("ws://unreachable.test", func() -> void: action_calls[0] += 1, transport)

	app.poll_connection()

	assert_eq(transport.close_reason, "connect_timeout")
	assert_eq(app.connection_error, "connect_timeout")
	assert_eq(action_calls[0], 0)
	assert_eq(app.connection, null)
	app.free()


func test_disconnect_clears_pending_action() -> void:
	var app := TestClientApp.new()
	var transport := FakeConnection.new()
	var action_calls := [0]
	app.connect_and("ws://slow.test", func() -> void: action_calls[0] += 1, transport)

	app.disconnect_from_server()
	transport.opened.emit(1)

	assert_eq(action_calls[0], 0)
	app.free()


func test_rejected_command_clears_pending_action() -> void:
	var app := TestClientApp.new()
	var transport := FakeConnection.new()
	var action_calls := [0]
	app.connect_and("ws://slow.test", func() -> void: action_calls[0] += 1, transport)

	transport.result_received.emit(1, {"type": "create_room"}, {"ok": false, "error": "room_full"})
	transport.opened.emit(1)

	assert_eq(action_calls[0], 0)
	app.free()


func test_new_snapshot_clears_pending_action() -> void:
	var app := TestClientApp.new()
	var transport := FakeConnection.new()
	var action_calls := [0]
	app.connect_and("ws://slow.test", func() -> void: action_calls[0] += 1, transport)

	transport.update_received.emit([], {})
	transport.opened.emit(1)

	assert_eq(action_calls[0], 0)
	app.free()


func test_connection_error_keeps_multiplayer_back_button_visible() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	var title := TitleScreen.new()
	app._current = title
	app.add_child(title)
	title.setup(app)

	app._show_connection_error("connect_timeout")

	assert_eq(title._view, "multiplayer")
	assert_true(title._status.visible)
	assert_eq(title._status.text, UiText.ERRORS["connect_timeout"])
	var has_back := false
	for button in title.find_children("*", "Button", true, false):
		if button.text == "Back [Esc]":
			has_back = true
	assert_true(has_back, "connection error view keeps a Back button")
	app.free()
