class_name StoryLauncher
extends RefCounted

var server: MatchServer
var connection: LocalConnection
var client: ClientApp

func start(client_app: ClientApp, seed_value: int = 0) -> LocalConnection:
	client = client_app
	var actual_seed := seed_value if seed_value != 0 else int(Time.get_ticks_usec())
	server = MatchServer.new(GameRng.new(actual_seed), SystemClock.new(), ForestContent.load_default())
	connection = LocalConnection.new(server)
	client.use_connection(connection)
	connection.start()
	return connection

func stop() -> void:
	if connection != null:
		connection.close("story_stopped")
	connection = null
	server = null
	client = null
