class_name LocalConnection
extends ServerConnection
## In-process stand-in for NetClient, wired straight to a MatchServer. Used
## by development tools (UI previews, screenshots); real play always goes
## through the network server.

var server: MatchServer
var _next_id := 1
var _open := false
var _pending_results: Array = []


func _init(match_server: MatchServer) -> void:
	server = match_server


func start() -> void:
	session = server.open_session()
	_open = true
	opened.emit(session)
	_push_update()


func is_open() -> bool:
	return _open


func poll() -> void:
	if not _open:
		return
	for pending in _pending_results:
		result_received.emit(pending[0], pending[1], pending[2])
	_pending_results.clear()
	_push_update()


func send_command(cmd: Dictionary) -> int:
	if not _open:
		return 0
	var id := _next_id
	_next_id += 1
	_pending_results.append([id, cmd, server.command(session, cmd)])
	return id


func close(reason: String = "closed") -> void:
	if not _open:
		return
	_open = false
	server.close_session(session)
	closed.emit(reason)


func _push_update() -> void:
	update_received.emit(server.take_events(session), server.snapshot(session))
