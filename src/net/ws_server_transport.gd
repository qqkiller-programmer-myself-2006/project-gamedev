class_name WsServerTransport
extends RefCounted
## Transport adapter between WebSocket connections and the MatchServer.
## It only translates: a new connection opens an anonymous session, a
## "cmd" message becomes MatchServer.command(), pending events and the
## session's snapshot are pushed back, and a dropped connection closes the
## session. It never decides anything about the game.

const HANDSHAKE_TIMEOUT := 5.0
## A session with nothing new still gets a snapshot this often, so clients
## keep their countdowns in sync with the server clock.
const HEARTBEAT_SECONDS := 1.0

var server: MatchServer
var _clock
var _tcp := TCPServer.new()
## peer id -> {"ws": WebSocketPeer, "session": int, "since": float, "last_sent": float}
var _peers: Dictionary = {}
var _next_peer := 1


func _init(match_server: MatchServer, clock) -> void:
	server = match_server
	_clock = clock


func listen(port: int, bind_address: String = "*") -> Error:
	return _tcp.listen(port, bind_address)


func stop() -> void:
	for peer_id in _peers.keys():
		_drop(peer_id, 1001, "server_stopping")
	_tcp.stop()


func peer_count() -> int:
	return _peers.size()


## Accepts connections, reads messages and notices dropped peers.
func poll() -> void:
	while _tcp.is_connection_available():
		var ws := WebSocketPeer.new()
		ws.inbound_buffer_size = NetProtocol.BUFFER_BYTES
		ws.outbound_buffer_size = NetProtocol.BUFFER_BYTES
		ws.accept_stream(_tcp.take_connection())
		_peers[_next_peer] = {"ws": ws, "session": 0, "since": _clock.now(), "last_sent": -INF}
		_next_peer += 1
	for peer_id in _peers.keys():
		var peer: Dictionary = _peers[peer_id]
		var ws: WebSocketPeer = peer["ws"]
		ws.poll()
		match ws.get_ready_state():
			WebSocketPeer.STATE_CONNECTING:
				if _clock.now() - float(peer["since"]) > HANDSHAKE_TIMEOUT:
					_drop(peer_id, 1002, "handshake_timeout")
			WebSocketPeer.STATE_OPEN:
				if peer["session"] == 0:
					peer["session"] = server.open_session()
					_send(ws, {"t": "welcome", "session": peer["session"], "protocol": NetProtocol.VERSION})
				while ws.get_available_packet_count() > 0:
					_receive(peer, ws.get_packet().get_string_from_utf8())
			WebSocketPeer.STATE_CLOSED:
				_drop(peer_id, 1000, "")


## Pushes pending events (with a fresh snapshot) to every connected session.
func flush() -> void:
	var now: float = _clock.now()
	for peer_id in _peers:
		var peer: Dictionary = _peers[peer_id]
		var ws: WebSocketPeer = peer["ws"]
		if peer["session"] == 0 or ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
			continue
		var events := server.take_events(peer["session"])
		if events.is_empty() and now - float(peer["last_sent"]) < HEARTBEAT_SECONDS:
			continue
		_send_update(peer, events)


func _receive(peer: Dictionary, text: String) -> void:
	var ws: WebSocketPeer = peer["ws"]
	var message := NetProtocol.decode(text)
	if message.is_empty() or message["t"] != "cmd" or typeof(message.get("cmd")) != TYPE_DICTIONARY:
		_send(ws, {"t": "error", "error": "bad_message"})
		return
	var cmd: Dictionary = NetProtocol.normalize_numbers(message["cmd"])
	var result := server.command(peer["session"], cmd)
	_send(ws, {"t": "result", "id": message.get("id", 0), "result": result})
	_send_update(peer, server.take_events(peer["session"]))


func _send_update(peer: Dictionary, events: Array) -> void:
	_send(peer["ws"], {"t": "update", "events": events, "snapshot": server.snapshot(peer["session"])})
	peer["last_sent"] = _clock.now()


func _drop(peer_id: int, code: int, reason: String) -> void:
	var peer: Dictionary = _peers[peer_id]
	var ws: WebSocketPeer = peer["ws"]
	if ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		ws.close(code, reason)
	if peer["session"] != 0:
		server.close_session(peer["session"])
	_peers.erase(peer_id)


static func _send(ws: WebSocketPeer, message: Dictionary) -> void:
	ws.send_text(NetProtocol.encode(message))
