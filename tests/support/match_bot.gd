class_name MatchBot
extends RefCounted
## Scripted player(s) that drive a Match purely through the Match interface:
## it reads each human session's snapshot and sends the commands a sensible
## player would. Used for journey tests, the full-run regression suite and
## the pacing simulation (tools/simulate.gd).

## Default "thinking time" per kind of decision when simulating human pacing
## (seconds of game time before the bot answers). Tests use no delay.
const HUMAN_PACE := {"vote": 10.0, "combat": 8.0, "class": 10.0, "merchant": 25.0, "story": 25.0}

var harness: MatchHarness
var sessions: Array[int] = []
## Events seen by the first session, in order.
var events: Array = []
## Chooses a route option: func(options: Array, slot: int, view: Dictionary) -> int
var choose_route: Callable = func(_options: Array, _slot: int, _view: Dictionary) -> int: return 0
## Decides a Class offer: func(class_id: String, slot: int) -> bool
var accept_class: Callable = func(_class_id: String, _slot: int) -> bool: return true
## Seconds of game time between bot decisions.
var step := 0.5
## Decision kind -> seconds to wait before answering (see HUMAN_PACE).
var think: Dictionary = {}
## Called with the first session's Match snapshot before every step.
var on_step: Callable = Callable()
## Commands the bot sent, and how many were rejected.
var commands_sent := 0
var commands_rejected := 0

## session -> {"key": decision key, "since": clock time it appeared}
var _pending: Dictionary = {}


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
		if on_step.is_valid():
			on_step.call(view)
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
			if not vote["voted_slots"].has(slot) and _ready_to(session, "vote", "vote%d" % view["layer"]):
				_send(session, {"type": "vote", "option": choose_route.call(vote["options"], slot, view)})
		"encounter", "boss":
			var encounter = view["encounter"]
			if encounter != null:
				_act_in_encounter(session, slot, view, encounter)


## A route policy like a thoughtful player's: look for a Class while
## anyone is Classless, rest when hurt, shop when there is Gold to spend,
## otherwise fight for EXP and Gold.
static func sensible_route(options: Array, _slot: int, view: Dictionary) -> int:
	var classless := 0
	var hp := 0.0
	var max_hp := 0.0
	for character in view["party"]:
		if character["class"] == "classless":
			classless += 1
		hp += float(character["hp"])
		max_hp += float(character["max_hp"])
	var best := 0
	var best_score := -1.0
	for option in options:
		var score := 0.0
		match str(option["type"]):
			"class":
				score = 5.0 if classless >= 2 else 1.0
			"merchant":
				score = 4.0 if int(view["gold"]) >= 25 else 0.5
			"rest":
				score = 6.0 if hp / max_hp < 0.55 else 1.0
			"combat":
				score = 3.0
			"treasure", "story":
				score = 2.5
		if score > best_score:
			best = option["index"]
			best_score = score
	return best


func events_of_type(type: String) -> Array:
	var out := []
	for event in events:
		if event["type"] == type:
			out.append(event)
	return out


func _act_in_encounter(session: int, slot: int, view: Dictionary, encounter: Dictionary) -> void:
	var tag := "%d-%s" % [view["layer"], view["phase"]]
	match str(encounter.get("kind", "")):
		"combat", "boss":
			if encounter["your_turn"] and _ready_to(session, "combat", "%s-%d-%s" % [tag, encounter["round"], encounter["actor"]]):
				_fight(session, slot, view, encounter)
		"class":
			if encounter["stage"] == "challenge":
				var trial: Dictionary = encounter["trial"]
				if trial["your_turn"] and _ready_to(session, "combat", "%s-trial-%d" % [tag, trial["round"]]):
					_fight(session, slot, view, trial)
			elif encounter["stage"] == "offer" and encounter["offer"]["you_can_decide"] \
					and _ready_to(session, "class", tag + "-offer"):
				_send(session, {"type": "class_choice", "accept": accept_class.call(encounter["class"], slot)})
		"story":
			if encounter["stage"] == "choosing" and not encounter["vote"]["voted_slots"].has(slot) \
					and _ready_to(session, "story", tag + "-choose"):
				_send(session, {"type": "vote", "option": 0})
			elif encounter["stage"] == "outcome" and not encounter["you_are_ready"] \
					and _ready_to(session, "story", tag + "-read"):
				_send(session, {"type": "ready"})
		"merchant":
			if not encounter["you_are_ready"] and _ready_to(session, "merchant", tag + "-shop"):
				_shop(session, encounter)
				_send(session, {"type": "ready"})


## True once the decision identified by `key` has been on screen for the
## thinking time of `kind`.
func _ready_to(session: int, kind: String, key: String) -> bool:
	var delay := float(think.get(kind, 0.0))
	if delay <= 0.0:
		return true
	var now: float = harness.clock.now()
	var pending: Dictionary = _pending.get(session, {})
	if pending.get("key", "") != key:
		_pending[session] = {"key": key, "since": now}
		return false
	return now - float(pending["since"]) >= delay


## Shopping policy: one of the best healing Item the Party can afford, plus
## a Spirit Bloom when Gold allows.
func _shop(session: int, encounter: Dictionary) -> void:
	for wanted in ["tonic", "herb"]:
		for entry in encounter["stock"]:
			if entry["item"] == wanted and entry["affordable"]:
				_send(session, {"type": "buy", "item": wanted})
				return


## Combat policy (a careful but not perfect human):
## 1. Defend against a Boss blow telegraphed at you (or Shield Wall a
##    Party-wide one if you can).
## 2. Revive a fallen ally or heal one below 40% HP when an Item allows it.
## 3. Use a ready Skill where it makes sense.
## 4. Attack the weakest enemy in reach.
func _fight(session: int, slot: int, view: Dictionary, encounter: Dictionary) -> void:
	var me := "p%d" % slot
	var choices: Dictionary = encounter["choices"]
	var skills: Dictionary = choices["skills"]
	var threat: Dictionary = encounter.get("boss", {}).get("telegraph", {})
	if threat.get("target", "") == "all" and _skill_ready(skills, "shield_wall"):
		_act(session, slot, {"action": "skill", "skill": "shield_wall", "target": me})
		return
	if threat.get("target", "") == me:
		_act(session, slot, {"action": "defend"})
		return
	for item in choices["items"]:
		var info: Dictionary = choices["items"][item]
		if info["target"] == "fallen_ally" and not info["targets"].is_empty():
			_act(session, slot, {"action": "item", "item": item, "target": info["targets"][0]})
			return
	var hurt := _most_hurt(view, 0.4, [])
	if not hurt.is_empty():
		for item in choices["items"]:
			var info: Dictionary = choices["items"][item]
			if info["target"] == "ally" and info["targets"].has(hurt):
				_act(session, slot, {"action": "item", "item": item, "target": hurt})
				return
	var enemies: Array = encounter["enemies"]
	for skill in skills:
		var info: Dictionary = skills[skill]
		if info["cooldown"] > 0 or not info.get("affordable", true) or info["targets"].is_empty():
			continue
		match str(info["target"]):
			"all_enemies":
				if info["targets"].size() >= 2:
					_act(session, slot, {"action": "skill", "skill": skill})
					return
			"enemy":
				_act(session, slot, {"action": "skill", "skill": skill, "target": _weakest(enemies, info["targets"])})
				return
			"other_ally":
				var ward := _most_hurt(view, 0.5, [me] + encounter.get("protected", {}).keys())
				if not ward.is_empty() and info["targets"].has(ward):
					_act(session, slot, {"action": "skill", "skill": skill, "target": ward})
					return
	_act(session, slot, {"action": "attack", "target": _weakest(enemies, choices["attack"]["targets"])})


func _act(session: int, slot: int, cmd: Dictionary) -> void:
	var full := {"type": "action", "slot": slot}
	full.merge(cmd)
	_send(session, full)


func _send(session: int, cmd: Dictionary) -> void:
	commands_sent += 1
	if not harness.server.command(session, cmd).get("ok", false):
		commands_rejected += 1


static func _skill_ready(skills: Dictionary, skill: String) -> bool:
	return skills.has(skill) and skills[skill]["cooldown"] == 0 \
			and bool(skills[skill].get("affordable", true)) and not skills[skill]["targets"].is_empty()


## Living ally id with the lowest HP share under `limit`, skipping `exclude`.
static func _most_hurt(view: Dictionary, limit: float, exclude: Array) -> String:
	var hurt := ""
	var hurt_ratio := limit
	for character in view["party"]:
		var id := "p%d" % character["slot"]
		var ratio := float(character["hp"]) / float(character["max_hp"])
		if character["hp"] > 0 and ratio < hurt_ratio and not exclude.has(id):
			hurt = id
			hurt_ratio = ratio
	return hurt


static func _weakest(enemies: Array, allowed: Array) -> String:
	var weakest := ""
	var weakest_hp := 0
	for enemy in enemies:
		if allowed.has(enemy["id"]) and (weakest.is_empty() or enemy["hp"] < weakest_hp):
			weakest = enemy["id"]
			weakest_hp = enemy["hp"]
	return weakest


func _collect_events() -> void:
	events.append_array(harness.server.take_events(sessions[0]))
	for i in range(1, sessions.size()):
		harness.server.take_events(sessions[i])


func _match_of(session: int) -> Dictionary:
	var view = harness.server.snapshot(session)["match"]
	return view if view != null else {}
