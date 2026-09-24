extends TestCase
## Cross-process smoke test (issue #5): a real headless server process and
## scripted clients over real WebSockets create a room, join it and start a
## Match. The same flow is checked in a browser by tools/web_smoke.mjs.

var _pid := -1
var _probes: Array = []


func after_each() -> void:
	for probe in _probes:
		probe.client.close()
	if _pid > 0:
		OS.kill(_pid)


func test_headless_server_hosts_create_join_and_start() -> void:
	var port := 24600 + (Time.get_ticks_msec() % 300)
	_pid = OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--", "--server", "--port=%d" % port, "--seed=5"])
	assert_true(_pid > 0, "server process started")
	var host := _connect(port)
	var guest := _connect(port)
	assert_true(host.session > 0 and guest.session > 0, "both clients welcomed by the server process")
	var created := _send(host, {"type": "create_room", "name": "Pc Player"})
	assert_ok(created)
	var joined := _send(guest, {"type": "join_room", "code": str(created.get("code", "")).to_lower(), "name": "Web Player"})
	assert_ok(joined)
	assert_rejected(_send(guest, {"type": "start_match"}), "not_host")
	assert_ok(_send(host, {"type": "start_match"}))
	assert_true(_pump(func() -> bool: return guest.event_types().has("match_started")), "guest sees the Match start")
	assert_eq(guest.snapshot["match"]["party"][1]["controller"], "human")
	assert_eq(guest.snapshot["match"]["party"][2]["controller"], "ai")


## Connects, retrying while the server process boots.
func _connect(port: int) -> NetRig.Probe:
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		var client := NetClient.new()
		client.connect_to("ws://127.0.0.1:%d" % port)
		var probe := NetRig.Probe.new(client)
		_probes.append(probe)
		_pump(func() -> bool: return probe.session != 0 or not probe.closed_reason.is_empty(), 3000)
		if probe.session != 0:
			return probe
		_probes.erase(probe)
		OS.delay_msec(200)
	fail("could not connect to the server process")
	return NetRig.Probe.new(NetClient.new())


func _send(probe: NetRig.Probe, cmd: Dictionary) -> Dictionary:
	var before: int = probe.results.size()
	probe.client.send_command(cmd)
	_pump(func() -> bool: return probe.results.size() > before)
	return probe.last_result()


func _pump(done: Callable, timeout_ms: int = 5000) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < timeout_ms:
		for probe in _probes:
			probe.client.poll()
		if done.call():
			return true
		OS.delay_msec(5)
	return false
