extends SceneTree
## A scripted "PC" client for the cross-platform smoke test (tools/web_smoke.mjs):
## it uses the same NetClient as the desktop build, over a real WebSocket.
##
##   godot --headless --path . -s tools/pc_smoke_client.gd -- --url=ws://127.0.0.1:8910 --create
##   godot --headless --path . -s tools/pc_smoke_client.gd -- --url=ws://127.0.0.1:8910 --join=CODE
##
## --create prints "CODE=<room code>", waits for a second player, starts the
## Match and waits for it to begin. --join joins and waits for the Match to
## begin. Exits 0 on success, 1 on failure or after 90 seconds.

var client := NetClient.new()
var options := {}
var snapshot := {}
var events: Array = []
var started_at := 0
var sent_start := false
var sent_join := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		options[pair[0]] = pair[1] if pair.size() > 1 else true
	client.update_received.connect(func(new_events: Array, snap: Dictionary) -> void:
		events.append_array(new_events)
		snapshot = snap)
	client.result_received.connect(func(_id: int, cmd: Dictionary, result: Dictionary) -> void:
		print("RESULT %s %s" % [cmd.get("type"), JSON.stringify(result)])
		if cmd.get("type") == "create_room" and result.get("ok", false):
			print("CODE=%s" % result["code"])
		if not result.get("ok", false) and cmd.get("type") != "start_match":
			_finish(1))
	client.closed.connect(func(reason: String) -> void:
		print("CLOSED %s" % reason)
		_finish(1))
	client.connect_to(str(options.get("url", "ws://127.0.0.1:8910")))
	started_at = Time.get_ticks_msec()


func _process(_delta: float) -> bool:
	client.poll()
	if Time.get_ticks_msec() - started_at > 90000:
		print("TIMEOUT")
		_finish(1)
		return true
	if client.is_open() and not sent_join:
		sent_join = true
		var display_name := str(options.get("name", "Pc Player"))
		if options.has("join"):
			client.send_command({"type": "join_room", "code": options["join"], "name": display_name})
		else:
			client.send_command({"type": "create_room", "name": display_name})
	var room = snapshot.get("room")
	if room != null and options.has("create") and not sent_start:
		var humans := 0
		for slot in room["slots"]:
			if slot["controller"] == "human":
				humans += 1
		if humans >= 2:
			sent_start = true
			print("STARTING with %d players" % humans)
			client.send_command({"type": "start_match"})
	for event in events:
		if event["type"] == "match_started":
			print("MATCH_STARTED controllers=%s" % JSON.stringify(_controllers()))
			_finish(0)
			return true
	events.clear()
	return false


func _controllers() -> Array:
	var out := []
	var run = snapshot.get("match")
	if run != null:
		for character in run["party"]:
			out.append(character["controller"])
	return out


func _finish(code: int) -> void:
	client.close()
	quit(code)
