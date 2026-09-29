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
## Set by listen_embedded(): the in-client Playtest server must never quit the game.
var _embedded := false
var _listening := false


func configure(options: Dictionary) -> void:
	port = int(options.get("port", port))
	var seed_value := int(options.get("seed", Time.get_unix_time_from_system() * 1000.0))
	var profile_url := str(options.get("profile-url", OS.get_environment("PROFILE_URL")))
	var profile_secret := str(options.get("profile-secret", OS.get_environment("PROFILE_SECRET")))
	profile_store = D1ProfileStore.new(profile_url, profile_secret, HttpProfileSender.new()) if not profile_url.is_empty() else FileProfileStore.new("user://profiles")
	match_server = MatchServer.new(GameRng.new(seed_value), _clock, ForestContent.load_default(), profile_store)
	transport = WsServerTransport.new(match_server, _clock)


## Listens on 127.0.0.1 for a Playtest inside the client. Returns false instead of
## quitting when the port is taken, so the caller can try the next one.
func listen_embedded(local_port: int) -> bool:
	if match_server == null:
		configure({})
	_embedded = true
	match_server.allow_dev = true  # only the in-client Playtest server; the online server never sets it
	port = local_port
	_listening = transport.listen(port, "127.0.0.1") == OK
	if _listening:
		print("GameServer: listening on ws://127.0.0.1:%d (embedded)" % port)
	return _listening


func _ready() -> void:
	if _embedded:
		return
	if match_server == null:
		configure({})
	var error := transport.listen(port)
	if error != OK:
		printerr("GameServer: cannot listen on port %d (error %d)" % [port, error])
		get_tree().quit(1)
		return
	_listening = true
	print("GameServer: listening on ws://0.0.0.0:%d" % port)


func _process(_delta: float) -> void:
	if not _listening:
		return
	transport.poll()
	match_server.update()
	transport.flush()
	if _clock.now() - _last_report >= 60.0:
		_last_report = _clock.now()
		print("GameServer: %d connection(s)" % transport.peer_count())


func _exit_tree() -> void:
	if transport != null:
		transport.stop()
	if profile_store is D1ProfileStore and profile_store.sender is HttpProfileSender:
		profile_store.sender.stop()
