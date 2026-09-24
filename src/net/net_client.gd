class_name NetClient
extends ServerConnection
## WebSocket connection to the authoritative server. Works in desktop and
## browser builds. Call poll() every frame.

var url := ""
var _ws := WebSocketPeer.new()
var _state := "idle"
var _next_id := 1
## request id -> command, so results can be matched to what was asked.
var _sent: Dictionary = {}
var _close_reason := ""


func connect_to(server_url: String) -> Error:
	url = server_url
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = NetProtocol.BUFFER_BYTES
	_ws.outbound_buffer_size = NetProtocol.BUFFER_BYTES
	var error := _ws.connect_to_url(url)
	_state = "connecting" if error == OK else "closed"
	return error


func is_open() -> bool:
	return _state == "open" and session != 0


func poll() -> void:
	if _state in ["idle", "closed"]:
		return
	_ws.poll()
	match _ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if _state == "connecting":
				_state = "open"
			while _ws.get_available_packet_count() > 0:
				_handle(NetProtocol.decode(_ws.get_packet().get_string_from_utf8()))
		WebSocketPeer.STATE_CLOSED:
			var was_open := session != 0
			_state = "closed"
			var reason := _close_reason
			if reason.is_empty():
				reason = "connection_lost" if was_open else "cannot_connect"
			closed.emit(reason)


func send_command(cmd: Dictionary) -> int:
	if not is_open():
		return 0
	var id := _next_id
	_next_id += 1
	_sent[id] = cmd
	_ws.send_text(NetProtocol.encode({"t": "cmd", "id": id, "cmd": cmd}))
	return id


func close(reason: String = "closed") -> void:
	if _state in ["idle", "closed"]:
		return
	_close_reason = reason
	_ws.close(1000, reason)


func _handle(message: Dictionary) -> void:
	match str(message.get("t", "")):
		"welcome":
			session = int(message.get("session", 0))
			opened.emit(session)
		"update":
			update_received.emit(message.get("events", []), message.get("snapshot", {}))
		"result":
			var id := int(message.get("id", 0))
			var cmd: Dictionary = _sent.get(id, {})
			_sent.erase(id)
			result_received.emit(id, cmd, message.get("result", {}))
		"error":
			server_error.emit(str(message.get("error", "")))
