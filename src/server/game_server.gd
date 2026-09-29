class_name GameServer
extends Node
## The headless authoritative server: owns the MatchServer (real clock,
## seeded GameRng, Forest content) and the WebSocket transport, and ticks
## both every frame.
##
##   godot --headless --path . -- --server [--port=8910] [--seed=123]

var match_server: MatchServer
var transport: WsServerTransport
var port := NetProtocol.DEFAULT_PORT

var _clock := SystemClock.new()
var _last_report := 0.0
var profile_store: ProfileStore


func configure(options: Dictionary) -> void:
	port = int(options.get("port", port))
	var seed_value := int(options.get("seed", Time.get_unix_time_from_system() * 1000.0))
	var profile_url := str(options.get("profile-url", OS.get_environment("PROFILE_URL")))
	var profile_secret := str(options.get("profile-secret", OS.get_environment("PROFILE_SECRET")))
	profile_store = D1ProfileStore.new(profile_url, profile_secret) if not profile_url.is_empty() else FileProfileStore.new("user://profiles")
	match_server = MatchServer.new(GameRng.new(seed_value), _clock, ForestContent.load_default(), profile_store)
	transport = WsServerTransport.new(match_server, _clock)


func _ready() -> void:
	if match_server == null:
		configure({})
	var error := transport.listen(port)
	if error != OK:
		printerr("GameServer: cannot listen on port %d (error %d)" % [port, error])
		get_tree().quit(1)
		return
	print("GameServer: listening on ws://0.0.0.0:%d" % port)


func _process(_delta: float) -> void:
	transport.poll()
	match_server.update()
	transport.flush()
	if _clock.now() - _last_report >= 60.0:
		_last_report = _clock.now()
		print("GameServer: %d connection(s)" % transport.peer_count())


func _exit_tree() -> void:
	if transport != null:
		transport.stop()
