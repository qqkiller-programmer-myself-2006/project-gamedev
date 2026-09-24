extends Node
## Entry point of every build. "--server" (or a headless display) starts the
## authoritative server; otherwise the game client starts. PC and browser
## clients and the server all come from this one codebase (ADR-0001).


func _ready() -> void:
	var options := LaunchOptions.parse()
	if options.has("server") or DisplayServer.get_name() == "headless":
		var server := GameServer.new()
		server.name = "GameServer"
		server.configure(options)
		add_child(server)
	else:
		var client := ClientApp.new()
		client.name = "ClientApp"
		client.configure(options)
		add_child(client)
