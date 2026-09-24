class_name RoomCodes
extends RefCounted
## Room code format: 6 characters from an alphabet without look-alikes
## (no 0/O, 1/I/L), typed case-insensitively.

const LENGTH := 6
const ALPHABET := "ABCDEFGHJKMNPQRSTUVWXYZ23456789"


static func generate(rng: GameRng) -> String:
	var code := ""
	for i in LENGTH:
		code += ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)]
	return code


## Canonical form of what a player typed: upper case, spaces and dashes
## removed. Returns "" when the result cannot be a Room code.
static func normalize(typed: String) -> String:
	var code := typed.strip_edges().to_upper().replace(" ", "").replace("-", "")
	if code.length() != LENGTH:
		return ""
	for ch in code:
		if not ALPHABET.contains(ch):
			return ""
	return code
