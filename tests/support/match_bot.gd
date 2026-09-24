class_name MatchBot
extends RefCounted
## Scripted player(s) that drive a Match purely through the Match interface:
## it reads each human session's snapshot and sends the commands a sensible
## player would. Used for journey tests and the full-run regression suite.

var harness: MatchHarness
var sessions: Array[int] = []
## Events seen by the first session, in order.
var events: Array = []
## Chooses a route option: func(options: Array, slot: int) -> int
var choose_route: Callable = func(_options: Array, _slot: int) -> int: return 0
## Decides a Class offer: func(class_id: String, slot: int) -> bool
var accept_class: Callable = func(_class_id: String, _slot: int) -> bool: return true
## Seconds of game time between bot decisions.
var step := 0.5


func _init(match_harness: MatchHarness, human_sessions: Array[int]) -> void:
	harness = match_harness
	sessions = human_sessions


## Plays until `stop` returns true for the first session's Match snapshot,
## the Match is over, or `max_seconds` of game time pass. Returns the final
## Match snapshot.
func play_until(stop: Callable, max_seconds: float = 7200.0) -> Dictionary:
	var elapsed := 0.0
	while elapsed < max_seconds:
		_collect_events()
		var view := _match_of(sessions[0])
		if view.is_empty() or view["phase"] in ["victory", "defeat"] or stop.call(view):
			return view
		for session in sessions:
			act(session)
		_collect_events()
		harness.advance(step, step)
		elapsed += step
	return _match_of(sessions[0])


## Plays until the Match ends (Victory or Defeat).
func play_to_end(max_seconds: float = 7200.0) -> Dictionary:
	return play_until(func(_v: Dictionary) -> bool: return false, max_seconds)


## Makes one decision for `session` if it has something to do.
func act(session: int) -> void:
	var snap := harness.server.snapshot(session)
	var view = snap["match"]
	if view == null or snap["room"] == null:
		return
	var slot: int = snap["room"]["your_slot"]
	if slot < 0:
		return
	match view["phase"]:
		"voting":
			var vote: Dictionary = view["vote"]
			if not vote["voted_slots"].has(slot):
				var option: int = choose_route.call(vote["options"], slot)
				harness.server.command(session, {"type": "vote", "option": option})
		"encounter":
			var encounter = view["encounter"]
			if encounter == null:
				return
			match str(encounter.get("kind", "")):
				"combat", "boss":
					if encounter["your_turn"]:
						_fight(session, slot, view, encounter)
				"story":
					if encounter["stage"] == "choosing" and not encounter["vote"]["voted_slots"].has(slot):
						harness.server.command(session, {"type": "vote", "option": 0})
					elif encounter["stage"] == "outcome" and not encounter["you_are_ready"]:
						harness.server.command(session, {"type": "ready"})
				"merchant":
					if not encounter["you_are_ready"]:
						_shop(session, encounter)
						harness.server.command(session, {"type": "ready"})
				"class":
					if encounter["stage"] == "challenge" and encounter["trial"]["your_turn"]:
						_fight(session, slot, view, encounter["trial"])
					elif encounter["stage"] == "offer" and encounter["offer"]["you_can_decide"]:
						harness.server.command(session, {"type": "class_choice",
								"accept": accept_class.call(encounter["class"], slot)})


## Shopping policy: buy one of the best healing Item the Party can afford.
func _shop(session: int, encounter: Dictionary) -> void:
	for wanted in ["tonic", "herb", "spirit_bloom"]:
		for entry in encounter["stock"]:
			if entry["item"] == wanted and entry["affordable"]:
				harness.server.command(session, {"type": "buy", "item": wanted})
				return


## Combat policy: Defend when the Boss has telegraphed a blow at you, heal
## the most hurt ally below 40% HP when an Item allows it, otherwise attack
## the weakest enemy in reach.
func _fight(session: int, slot: int, view: Dictionary, encounter: Dictionary) -> void:
	var choices: Dictionary = encounter["choices"]
	var threat: Dictionary = encounter.get("boss", {}).get("telegraph", {})
	if threat.get("target", "") == "p%d" % slot:
		harness.server.command(session, {"type": "action", "slot": slot, "action": "defend"})
		return
	var hurt := ""
	var hurt_ratio := 0.4
	for character in view["party"]:
		var ratio := float(character["hp"]) / float(character["max_hp"])
		if character["hp"] > 0 and ratio < hurt_ratio:
			hurt = "p%d" % character["slot"]
			hurt_ratio = ratio
	if not hurt.is_empty():
		for item in choices["items"]:
			var info: Dictionary = choices["items"][item]
			if info["target"] == "ally" and info["targets"].has(hurt):
				harness.server.command(session, {"type": "action", "slot": slot, "action": "item",
						"item": item, "target": hurt})
				return
	var targets: Array = choices["attack"]["targets"]
	var weakest := ""
	var weakest_hp := 0
	for enemy in encounter["enemies"]:
		if targets.has(enemy["id"]) and (weakest.is_empty() or enemy["hp"] < weakest_hp):
			weakest = enemy["id"]
			weakest_hp = enemy["hp"]
	harness.server.command(session, {"type": "action", "slot": slot, "action": "attack", "target": weakest})


func events_of_type(type: String) -> Array:
	var out := []
	for event in events:
		if event["type"] == type:
			out.append(event)
	return out


func _collect_events() -> void:
	events.append_array(harness.server.take_events(sessions[0]))
	for i in range(1, sessions.size()):
		harness.server.take_events(sessions[i])


func _match_of(session: int) -> Dictionary:
	var view = harness.server.snapshot(session)["match"]
	return view if view != null else {}
