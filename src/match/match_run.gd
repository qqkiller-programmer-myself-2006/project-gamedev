class_name MatchRun
extends RefCounted
## One Match in a room: the Party of five characters and the journey
## through the Forest's Layers to the Guardian Boss. Internal to the Match
## module; MatchServer routes in-Match commands here through Room.
##
## Phases: voting -> travel -> encounter -> (next Layer's voting ...) ->
## boss -> victory | defeat.
##
## In-Match commands:
##   vote {option}
##   action {slot, action, target, item, skill}   (combat, see CombatEncounter)
##   class_choice {accept}                        (Class Encounter offer)
##   buy {item}, ready                            (Merchant)
##   vote {option}, ready                         (Story Event choice / reading)

const PARTY_SIZE := 5
## In-Match command types (routed here by MatchServer during a Match).
const COMMANDS: Array[String] = ["vote", "action", "class_choice", "buy", "ready"]

var number := 1
var phase := "voting"
## Current Layer, 1-based. 0 before the first vote.
var layer := 0
var party: Array[Dictionary] = []
var routes: Array = []
var vote: PathVote = null
var last_vote: Dictionary = {}
var encounter: Encounter = null
## Party-wide resources shared by every character.
var gold := 0
var inventory: Dictionary = {}
## Filled when the Match ends.
var summary: Dictionary = {}
var enemies_defeated := 0
## Class ids taken by at least one character during this Match.
var classes_discovered: Array[String] = []
## Story Clues found, oldest first: {"id", "title", "text", "layer", "source"}
var clues: Array[Dictionary] = []

var rng: GameRng
var clock
var content: ForestContent

var _humans: Array[bool] = []
var _outbox: Array[Dictionary] = []
var _started_at := 0.0
var _phase_deadline := -1.0
var _pending_option: Dictionary = {}


func _init(match_rng: GameRng, match_clock, forest: ForestContent, humans: Array[bool], match_number: int) -> void:
	rng = match_rng
	clock = match_clock
	content = forest
	_humans = humans.duplicate()
	number = match_number
	_started_at = clock.now()
	_create_party()
	gold = content.get_int("party.starting_gold", 0)
	for item in content.get_dict("party.starting_inventory"):
		add_item(item, content.get_int("party.starting_inventory.%s" % item))
	routes = RouteGenerator.generate(rng, content)
	emit({"type": "match_started", "number": number, "party": party_view(), "layers": routes.size()})
	_begin_layer(1)


func is_over() -> bool:
	return phase == "victory" or phase == "defeat"


func is_human(slot: int) -> bool:
	return _humans[slot]


func humans() -> Array[bool]:
	return _humans


## A slot changes between human and AI control mid-Match.
func set_human(slot: int, human: bool) -> void:
	if _humans[slot] == human:
		return
	_humans[slot] = human
	if not human:
		emit({"type": "slot_ai_takeover", "slot": slot, "character": party[slot]["name"]})
	if phase == "voting" and vote != null:
		vote.forget(slot)
		if vote.everyone_voted(_humans):
			_resolve_vote()
	elif phase in ["encounter", "boss"] and encounter != null:
		encounter.on_control_changed(self, slot)
		_after_encounter_step()


func handle(slot: int, cmd: Dictionary) -> Dictionary:
	var kind := str(cmd.get("type", ""))
	if kind == "vote" and phase != "encounter":
		return _handle_vote(slot, cmd)
	if phase in ["encounter", "boss"] and encounter != null:
		var result := encounter.handle(self, slot, cmd)
		_after_encounter_step()
		return result
	return {"ok": false, "error": "wrong_phase"}


func update() -> void:
	var now: float = clock.now()
	match phase:
		"voting":
			if now >= vote.deadline:
				_resolve_vote()
		"travel":
			if now >= _phase_deadline:
				_enter_encounter()
		"encounter", "boss":
			encounter.update(self)
			_after_encounter_step()


func take_outbox() -> Array[Dictionary]:
	var out := _outbox
	_outbox = []
	return out


func emit(event: Dictionary) -> void:
	_outbox.append(event)


func snapshot(viewer_slot: int) -> Dictionary:
	return {
		"number": number,
		"phase": phase,
		"layer": layer,
		"layers_total": routes.size(),
		"party": party_view(),
		"vote": vote.view() if phase == "voting" and vote != null else null,
		"last_vote": last_vote,
		"encounter": _encounter_view(viewer_slot),
		"gold": gold,
		"inventory": inventory_view(),
		"clues": clues.duplicate(true),
		"summary": summary,
		"elapsed": clock.now() - _started_at,
	}


func inventory_view() -> Array:
	var out: Array = []
	var ids := inventory.keys()
	ids.sort()
	for item in ids:
		var data := content.get_dict("items.%s" % item)
		out.append({
			"item": item,
			"name": str(data.get("name", item)),
			"description": str(data.get("description", "")),
			"count": inventory[item],
			"target": str(data.get("use", {}).get("target", "")),
		})
	return out


func add_gold(amount: int) -> void:
	gold += amount


func add_item(item: String, count: int = 1) -> void:
	if count <= 0:
		return
	inventory[item] = int(inventory.get(item, 0)) + count


## Records a Story Clue once. Returns false if it was already found.
func add_clue(id: String, source: String) -> bool:
	for clue in clues:
		if clue["id"] == id:
			return false
	var clue := clue_view(id)
	clue["layer"] = layer
	clue["source"] = source
	clues.append(clue)
	emit({"type": "clue_found", "clue": clue})
	return true


func clue_view(id: String) -> Dictionary:
	var data := content.get_dict("story.clues.%s" % id)
	return {"id": id, "title": str(data.get("title", id)), "text": str(data.get("text", ""))}


func has_clue(id: String) -> bool:
	for clue in clues:
		if clue["id"] == id:
			return true
	return false


## Gives a character a new Class: stats are rebuilt from the Class at the
## current level and HP grows by any gain in max HP.
func change_class(slot: int, class_id: String) -> void:
	var character: Dictionary = party[slot]
	var old_max: int = character["max_hp"]
	character["class"] = class_id
	_apply_stats(character)
	character["hp"] = clampi(character["hp"] + character["max_hp"] - old_max, 1, character["max_hp"])
	if not classes_discovered.has(class_id):
		classes_discovered.append(class_id)
	emit({"type": "class_changed", "slot": slot, "class": class_id,
			"class_name": str(content.get_value("classes.%s.name" % class_id, class_id))})


## Adds EXP to a character and applies any level-ups (content leveling data).
func grant_exp(slot: int, amount: int) -> void:
	var character: Dictionary = party[slot]
	character["exp"] += amount
	var thresholds := content.get_array("leveling.exp_to_next")
	while character["level"] - 1 < thresholds.size() and character["exp"] >= int(thresholds[character["level"] - 1]):
		character["exp"] -= int(thresholds[character["level"] - 1])
		var old_max: int = character["max_hp"]
		character["level"] += 1
		_apply_stats(character)
		if character["hp"] > 0:
			character["hp"] = mini(character["max_hp"], character["hp"] + character["max_hp"] - old_max)
		emit({"type": "level_up", "slot": slot, "level": character["level"], "max_hp": character["max_hp"]})


func party_view() -> Array:
	var out: Array = []
	for c in party:
		out.append({
			"slot": c["slot"],
			"name": c["name"],
			"class": c["class"],
			"class_name": str(content.get_value("classes.%s.name" % c["class"], c["class"])),
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


func _create_party() -> void:
	var members := content.get_array("party.members")
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
	var base := content.get_dict("classes.%s.stats" % character["class"])
	var growth := content.get_dict("leveling.growth")
	var levels: int = character["level"] - 1
	for stat in ["max_hp", "atk", "def", "mag", "res", "spd"]:
		character[stat] = int(base.get(stat, 0)) + int(growth.get(stat, 0)) * levels
	character["crit"] = float(base.get("crit", 0.0))


# --- Journey ----------------------------------------------------------------

func _begin_layer(next_layer: int) -> void:
	layer = next_layer
	phase = "voting"
	encounter = null
	var deadline: float = clock.now() + content.get_float("rules.vote_seconds", 20.0)
	vote = PathVote.new(layer, routes[layer - 1], deadline)
	var view := vote.view()
	emit({"type": "vote_started", "layer": layer, "options": view["options"], "deadline": deadline})


func _handle_vote(slot: int, cmd: Dictionary) -> Dictionary:
	if phase != "voting":
		return {"ok": false, "error": "wrong_phase"}
	var error := vote.cast(slot, int(cmd.get("option", -1)), is_human(slot))
	if not error.is_empty():
		return {"ok": false, "error": error}
	emit({"type": "vote_cast", "layer": layer, "slot": slot})
	if vote.everyone_voted(_humans):
		_resolve_vote()
	return {"ok": true}


func _resolve_vote() -> void:
	var result := vote.resolve(rng)
	var chosen: Dictionary = vote.options[result["option"]]
	var voters := {}
	for slot in vote.votes:
		voters[str(slot)] = vote.votes[slot]
	last_vote = {
		"layer": layer,
		"option": result["option"],
		"type": chosen["type"],
		"name": chosen["name"],
		"tally": result["tally"],
		"votes": voters,
		"tie_broken": result["tie_broken"],
		"no_votes": result["no_votes"],
	}
	var event := last_vote.duplicate(true)
	event["type"] = "vote_resolved"
	event["encounter_type"] = chosen["type"]
	emit(event)
	vote = null
	_pending_option = chosen
	var travel := content.get_float("rules.travel_seconds", 0.0)
	if travel <= 0.0:
		_enter_encounter()
	else:
		phase = "travel"
		_phase_deadline = clock.now() + travel


func _enter_encounter() -> void:
	phase = "encounter"
	encounter = _make_encounter(_pending_option)
	emit({
		"type": "encounter_started",
		"layer": layer,
		"encounter_type": _pending_option["type"],
		"name": _pending_option["name"],
	})
	encounter.start(self)
	_after_encounter_step()


func _make_encounter(option: Dictionary) -> Encounter:
	match str(option["type"]):
		"combat":
			return CombatEncounter.new(option, EnemyGroups.pick(rng, content, layer, str(option["site"])))
		"class":
			return ClassEncounter.new(option)
		"merchant":
			return MerchantEncounter.new(option)
		"rest":
			return RestEncounter.new(option)
		"treasure":
			return TreasureEncounter.new(option)
		"story":
			return StoryEncounter.new(option)
	return PlaceholderEncounter.new(option)


## Moves the journey on once the current Encounter has finished.
func _after_encounter_step() -> void:
	if phase not in ["encounter", "boss"] or encounter == null or not encounter.done:
		return
	if encounter is CombatEncounter:
		enemies_defeated += encounter.defeated_kinds.size()
		if encounter.result == "defeat":
			_end_match("defeat")
			return
	if phase == "boss":
		_end_match("victory")
		return
	emit({"type": "encounter_completed", "layer": layer, "encounter_type": encounter.option["type"]})
	if layer < routes.size():
		_begin_layer(layer + 1)
	else:
		_reach_boss()


func _reach_boss() -> void:
	phase = "boss"
	var boss := content.get_dict("boss")
	encounter = BossEncounter.new({"type": "boss", "site": "guardian", "name": str(boss.get("name", "Guardian"))},
			content.get_array("boss.enemies"))
	emit({"type": "boss_reached", "layer": layer})
	encounter.start(self)
	_after_encounter_step()


func _end_match(outcome: String) -> void:
	phase = outcome
	encounter = null
	vote = null
	var ending := content.get_dict("ending.%s" % outcome)
	summary = {
		"result": outcome,
		"title": str(ending.get("title", "")),
		"text": str(ending.get("text", "")),
		"layer": layer,
		"layers_total": routes.size(),
		"elapsed": clock.now() - _started_at,
		"enemies_defeated": enemies_defeated,
		"classes_discovered": classes_discovered.duplicate(),
		"clues_found": clues.size(),
		"clues": clues.duplicate(true),
		"gold": gold,
		"party": party_view(),
	}
	emit({"type": "match_ended", "result": outcome, "summary": summary})


func _encounter_view(viewer_slot: int) -> Variant:
	if phase not in ["encounter", "boss"] or encounter == null:
		return null
	var view := encounter.view(self, viewer_slot)
	view["type"] = encounter.option["type"]
	view["name"] = encounter.option["name"]
	return view
