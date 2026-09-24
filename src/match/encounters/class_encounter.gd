class_name ClassEncounter
extends Encounter
## Class Encounter: a Challenge that can offer a Tier 1 Class.
##
## 1. challenge: a non-lethal trial fight against the Class's trainer with a
##    round limit. Beating the trainer in time passes (and grants a little
##    EXP to everyone); otherwise it fails and no Class is offered. HP returns
##    to what it was before the trial.
## 2. offer: every Classless character may take the Class. Humans answer
##    with class_choice {accept} before the deadline (no answer = decline).
##    AI-controlled characters decide on their own, in slot order: they
##    accept unless `rules.ai_class_cap` characters already have that Class,
##    so the AI keeps the Party varied. Humans may take a Class however many
##    characters have it. If nobody is Classless, passing grants mastery EXP
##    instead.
##
## Command: class_choice {accept: bool}   (during the offer)

var class_id: String
var stage := "challenge"
var passed := false
## slot -> true (accepted) / false (declined), for every eligible slot.
var decisions: Dictionary = {}
var eligible: Array[int] = []
var deadline := -1.0

var _trial: CombatEncounter = null
var _hp_before: Array[int] = []


func _init(route_option: Dictionary) -> void:
	super(route_option)
	class_id = str(option.get("class_id", "swordsman"))


func start(run: MatchRun) -> void:
	var challenge := run.content.get_dict("classes.%s.challenge" % class_id)
	run.emit({
		"type": "class_challenge_started",
		"class": class_id,
		"class_info": class_info(run, class_id),
		"text": str(challenge.get("intro", "")),
	})
	for character in run.party:
		_hp_before.append(character["hp"])
	var trainer := str(challenge.get("trainer", ""))
	_trial = CombatEncounter.new({"type": "combat", "site": option["site"], "name": option["name"]},
			[trainer], int(challenge.get("rounds", 3)))
	_trial.start(run)


func handle(run: MatchRun, slot: int, cmd: Dictionary) -> Dictionary:
	var kind := str(cmd.get("type", ""))
	if stage == "challenge" and kind == "action":
		var result := _trial.handle(run, slot, cmd)
		_advance(run)
		return result
	if kind != "class_choice" or stage != "offer":
		return {"ok": false, "error": "wrong_phase"}
	if not eligible.has(slot) or not run.is_human(slot):
		return {"ok": false, "error": "not_eligible"}
	if decisions.has(slot):
		return {"ok": false, "error": "already_decided"}
	_decide(run, slot, bool(cmd.get("accept", false)))
	_close_offer_if_settled(run)
	return {"ok": true}


func update(run: MatchRun) -> void:
	if stage == "challenge":
		_trial.update(run)
		_advance(run)
	elif stage == "offer" and run.clock.now() >= deadline:
		for slot in eligible:
			if not decisions.has(slot):
				_decide(run, slot, false)
		_close_offer_if_settled(run)


func on_control_changed(run: MatchRun, slot: int) -> void:
	if stage == "challenge":
		_trial.on_control_changed(run, slot)
	elif stage == "offer" and eligible.has(slot) and not decisions.has(slot) and not run.is_human(slot):
		_decide(run, slot, _ai_accepts(run))
		_close_offer_if_settled(run)


func view(run: MatchRun, viewer_slot: int) -> Dictionary:
	var challenge := run.content.get_dict("classes.%s.challenge" % class_id)
	var out := {
		"kind": "class",
		"stage": stage,
		"class": class_id,
		"class_info": class_info(run, class_id),
		"intro": str(challenge.get("intro", "")),
		"passed": passed,
	}
	if stage == "challenge":
		out["trial"] = _trial.view(run, viewer_slot)
	else:
		out["outcome_text"] = str(challenge.get("pass" if passed else "fail", ""))
		var decided := {}
		for slot in decisions:
			decided[str(slot)] = decisions[slot]
		out["offer"] = {
			"eligible": eligible.duplicate(),
			"decisions": decided,
			"deadline": deadline,
			"you_can_decide": eligible.has(viewer_slot) and not decisions.has(viewer_slot) \
					and run.is_human(viewer_slot),
		}
	return out


## Name, role, description, stats and Skills of a Class (for tooltips).
static func class_info(run: MatchRun, id: String) -> Dictionary:
	var data := run.content.get_dict("classes.%s" % id)
	var skills: Array = []
	for skill in data.get("skills", []):
		var info := run.content.get_dict("skills.%s" % skill)
		skills.append({
			"id": skill,
			"name": str(info.get("name", skill)),
			"description": str(info.get("description", "")),
			"cooldown": int(info.get("cooldown", 0)),
		})
	return {
		"id": id,
		"name": str(data.get("name", id)),
		"role": str(data.get("role", "")),
		"description": str(data.get("description", "")),
		"stats": data.get("stats", {}),
		"skills": skills,
	}


func _advance(run: MatchRun) -> void:
	if stage != "challenge" or _trial.result.is_empty():
		return
	passed = _trial.result == "victory"
	for i in run.party.size():
		run.party[i]["hp"] = mini(run.party[i]["max_hp"], _hp_before[i])
	var challenge := run.content.get_dict("classes.%s.challenge" % class_id)
	run.emit({
		"type": "class_challenge_ended",
		"class": class_id,
		"passed": passed,
		"text": str(challenge.get("pass" if passed else "fail", "")),
	})
	if not passed:
		stage = "result"
		done = true
		return
	var pass_exp := run.content.get_int("class_encounters.pass_exp", 0)
	for character in run.party:
		run.grant_exp(character["slot"], pass_exp)
	for character in run.party:
		if character["class"] == "classless":
			eligible.append(character["slot"])
	if eligible.is_empty():
		var bonus := run.content.get_int("class_encounters.mastery_exp", 0)
		for character in run.party:
			run.grant_exp(character["slot"], bonus)
		stage = "result"
		done = true
		return
	stage = "offer"
	deadline = run.clock.now() + run.content.get_float("rules.class_offer_seconds", 20.0)
	run.emit({
		"type": "class_offered",
		"class": class_id,
		"class_info": class_info(run, class_id),
		"eligible": eligible.duplicate(),
		"deadline": deadline,
	})
	for slot in eligible:
		if not run.is_human(slot):
			_decide(run, slot, _ai_accepts(run))
	_close_offer_if_settled(run)


## AI takes the Class unless enough of the Party already has it.
func _ai_accepts(run: MatchRun) -> bool:
	var holders := 0
	for character in run.party:
		if character["class"] == class_id:
			holders += 1
	return holders < run.content.get_int("rules.ai_class_cap", 2)


func _decide(run: MatchRun, slot: int, accept: bool) -> void:
	decisions[slot] = accept
	run.emit({"type": "class_choice", "slot": slot, "class": class_id, "accepted": accept})
	if accept:
		run.change_class(slot, class_id)


func _close_offer_if_settled(run: MatchRun) -> void:
	if stage != "offer" or decisions.size() < eligible.size():
		return
	stage = "result"
	done = true
	var takers: Array = []
	for slot in eligible:
		if decisions[slot]:
			takers.append(slot)
	run.emit({"type": "class_offer_closed", "class": class_id, "accepted_by": takers})
