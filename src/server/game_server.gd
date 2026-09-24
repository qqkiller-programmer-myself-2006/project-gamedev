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


func configure(options: Dictionary) -> void:
	port = int(options.get("port", port))
	var seed_value := int(options.get("seed", Time.get_unix_time_from_system() * 1000.0))
	match_server = MatchServer.new(GameRng.new(seed_value), _clock, ForestContent.load_default())
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
