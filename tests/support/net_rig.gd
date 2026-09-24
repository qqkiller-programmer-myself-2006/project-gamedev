class_name NetRig
extends RefCounted
## Test rig for the real WebSocket transport inside one process: a
## MatchServer behind WsServerTransport on a local port, and NetClients that
## connect to it. pump() drives both sides until a condition holds.

class Probe extends RefCounted:
	## What one client has received.
	var client: NetClient
	var session := 0
	var events: Array = []
	var snapshot: Dictionary = {}
	var results: Array = []
	var errors: Array = []
	var closed_reason := ""

	func _init(net_client: NetClient) -> void:
		client = net_client
		client.opened.connect(_on_opened)
		client.update_received.connect(_on_update)
		client.result_received.connect(_on_result)
		client.server_error.connect(_on_error)
		client.closed.connect(_on_closed)

	func _on_opened(id: int) -> void:
		session = id

	func _on_update(new_events: Array, snap: Dictionary) -> void:
		events.append_array(new_events)
		snapshot = snap

	func _on_result(_id: int, _cmd: Dictionary, result: Dictionary) -> void:
		results.append(result)

	func _on_error(error: String) -> void:
		errors.append(error)

	func _on_closed(reason: String) -> void:
		closed_reason = reason

	func event_types() -> Array:
		var out := []
		for event in events:
			out.append(event["type"])
		return out

	func room() -> Dictionary:
		var room = snapshot.get("room")
		return room if room != null else {}

	func last_result() -> Dictionary:
		return results[-1] if not results.is_empty() else {}


var clock := ManualClock.new()
var server: MatchServer
var transport: WsServerTransport
var port := 0
var probes: Array[Probe] = []


func _init(seed_value: int = 1) -> void:
	server = MatchServer.new(GameRng.new(seed_value), clock, ForestContent.load_default())
	transport = WsServerTransport.new(server, clock)
	for candidate in range(24000, 24100):
		if transport.listen(candidate, "127.0.0.1") == OK:
			port = candidate
			break


func url() -> String:
	return "ws://127.0.0.1:%d" % port


## Connects a new client and waits until the server welcomed it.
func connect_client() -> Probe:
	var client := NetClient.new()
	client.connect_to(url())
	var probe := Probe.new(client)
	probes.append(probe)
	pump(func() -> bool: return probe.session != 0)
	return probe


## Sends a command and waits for its result.
func send(probe: Probe, cmd: Dictionary) -> Dictionary:
	var before := probe.results.size()
	probe.client.send_command(cmd)
	pump(func() -> bool: return probe.results.size() > before)
	return probe.last_result()


## Runs both sides until `done` returns true or `timeout_ms` passes.
## Returns whether the condition was met.
func pump(done: Callable, timeout_ms: int = 3000) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < timeout_ms:
		transport.poll()
		server.update()
		transport.flush()
		for probe in probes:
			probe.client.poll()
		if done.call():
			return true
		OS.delay_msec(2)
	return false


func stop() -> void:
	for probe in probes:
		probe.client.close()
	pump(func() -> bool: return false, 50)
	transport.stop()
