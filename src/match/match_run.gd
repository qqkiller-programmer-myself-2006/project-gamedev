class_name MatchRun
extends RefCounted
## One Match in a room: the Party of five characters and the journey
## through the Forest. Internal to the Match module.

const PARTY_SIZE := 5
## In-Match command types (routed here by MatchServer during a Match).
const COMMANDS: Array[String] = []

var number := 1
var phase := "journey"
var party: Array[Dictionary] = []

var _rng: GameRng
var _clock
var _content: ForestContent
var _humans: Array[bool] = []
var _outbox: Array[Dictionary] = []
var _started_at := 0.0


func _init(rng: GameRng, clock, content: ForestContent, humans: Array[bool], match_number: int) -> void:
	_rng = rng
	_clock = clock
	_content = content
	_humans = humans.duplicate()
	number = match_number
	_started_at = _clock.now()
	_create_party()
	_emit({"type": "match_started", "number": number, "party": _party_view()})


func is_over() -> bool:
	return phase == "victory" or phase == "defeat"


func is_human(slot: int) -> bool:
	return _humans[slot]


## A slot changes between human and AI control mid-Match.
func set_human(slot: int, human: bool) -> void:
	if _humans[slot] == human:
		return
	_humans[slot] = human
	if not human:
		_emit({"type": "slot_ai_takeover", "slot": slot, "character": party[slot]["name"]})


func handle(_slot: int, cmd: Dictionary) -> Dictionary:
	return {"ok": false, "error": "unknown_command"}


func update() -> void:
	pass


func take_outbox() -> Array[Dictionary]:
	var out := _outbox
	_outbox = []
	return out


func snapshot(_viewer_slot: int) -> Dictionary:
	return {
		"number": number,
		"phase": phase,
		"party": _party_view(),
		"elapsed": _clock.now() - _started_at,
	}


func _create_party() -> void:
	var members := _content.get_array("party.members")
	for i in PARTY_SIZE:
		var member: Dictionary = members[i] if i < members.size() else {}
		var character := {
			"slot": i,
			"name": str(member.get("name", "Hero %d" % (i + 1))),
			"class": "classless",
			"level": 1,
			"exp": 0,
		}
		_apply_stats(character)
		character["hp"] = character["max_hp"]
		party.append(character)


## Recomputes a character's stats from its class and level (content data).
func _apply_stats(character: Dictionary) -> void:
	var base := _content.get_dict("classes.%s.stats" % character["class"])
	var growth := _content.get_dict("leveling.growth")
	var levels: int = character["level"] - 1
	for stat in ["max_hp", "atk", "def", "mag", "res", "spd"]:
		character[stat] = int(base.get(stat, 0)) + int(growth.get(stat, 0)) * levels
	character["crit"] = float(base.get("crit", 0.0))


func _party_view() -> Array:
	var out: Array = []
	for c in party:
		out.append({
			"slot": c["slot"],
			"name": c["name"],
			"class": c["class"],
			"level": c["level"],
			"exp": c["exp"],
			"hp": c["hp"],
			"max_hp": c["max_hp"],
			"atk": c["atk"],
			"def": c["def"],
			"mag": c["mag"],
			"res": c["res"],
			"spd": c["spd"],
			"controller": "human" if _humans[c["slot"]] else "ai",
		})
	return out


func _emit(event: Dictionary) -> void:
	_outbox.append(event)
