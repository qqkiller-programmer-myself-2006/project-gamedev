class_name NetProtocol
extends RefCounted
## Wire format between clients and the authoritative server: one JSON
## object per WebSocket text message, identified by "t".
##
## client -> server
##   {"t": "cmd", "id": 7, "cmd": {<Match interface command>}}
## server -> client
##   {"t": "welcome", "session": 12, "protocol": 1}
##   {"t": "result", "id": 7, "result": {"ok": true, ...}}
##   {"t": "update", "events": [...], "snapshot": {...}}
##   {"t": "error", "error": "bad_message"}

const VERSION := 1
const DEFAULT_PORT := 8910
## Large enough for any snapshot of a five-player room.
const BUFFER_BYTES := 1 << 20


static func encode(message: Dictionary) -> String:
	return JSON.stringify(message)


## The decoded message, or {} when `text` is not a valid message.
static func decode(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("t"):
		return {}
	return parsed


## JSON turns every number into a float; commands carry integer fields
## (slot, option), so whole numbers are turned back into ints.
static func normalize_numbers(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			return int(value) if value == floor(value) and absf(value) < 1e15 else value
		TYPE_DICTIONARY:
			var out := {}
			for key in value:
				out[key] = normalize_numbers(value[key])
			return out
		TYPE_ARRAY:
			var out := []
			for item in value:
				out.append(normalize_numbers(item))
			return out
	return value
