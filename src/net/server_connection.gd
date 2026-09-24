class_name ServerConnection
extends RefCounted
## What the client needs from "the server": send Match interface commands,
## receive results, events and snapshots. NetClient does this over a real
## WebSocket; LocalConnection talks to an in-process MatchServer (tools and
## UI previews only). Neither decides anything about the game.

signal opened(session: int)
signal closed(reason: String)
signal update_received(events: Array, snapshot: Dictionary)
signal result_received(id: int, cmd: Dictionary, result: Dictionary)
## The server could not understand a message we sent.
signal server_error(error: String)

var session := 0


func poll() -> void:
	pass


## Sends a command and returns its request id (0 when it could not be sent).
func send_command(_cmd: Dictionary) -> int:
	return 0


func is_open() -> bool:
	return false


func close(_reason: String = "closed") -> void:
	pass
