class_name StoryEncounter
extends Encounter
## Story Event: a piece of the father's trail, told as text, that adds a
## Story Clue to the Match's clue log.
##
## Events with choices are decided with the same rules as Path Voting (one
## vote per human, AI never votes, most votes wins, ties and silence are
## settled by the GameRng). Every outcome is then shown until every human is
## ready or the reading time runs out.
##
## Commands: vote {option} (while choosing)   ready (while reading)

var stage := "outcome"
var event_id := ""
var vote: PathVote = null
var outcome: Dictionary = {}
var result: Dictionary = {}
var ready_slots: Array[int] = []
var deadline := -1.0


func start(run: MatchRun) -> void:
	event_id = str(option.get("site", ""))
	var data := _event(run)
	var choices: Array = data.get("choices", [])
	var choice_options: Array = []
	for choice in choices:
		choice_options.append({"type": "choice", "name": str(choice.get("label", "")), "hint": str(choice.get("hint", ""))})
	run.emit({
		"type": "story_started",
		"event": event_id,
		"title": str(data.get("title", "")),
		"text": str(data.get("text", "")),
		"choices": choice_options,
	})
	if choices.is_empty():
		_show_outcome(run, data.get("outcome", {}))
	else:
		stage = "choosing"
		var seconds := run.content.get_float("rules.story_vote_seconds", 20.0)
		vote = PathVote.new(run.layer, choice_options, run.clock.now() + seconds, seconds)
		deadline = vote.deadline


func handle(run: MatchRun, slot: int, cmd: Dictionary) -> Dictionary:
	match str(cmd.get("type", "")):
		"vote":
			if stage != "choosing":
				return {"ok": false, "error": "wrong_phase"}
			var error := vote.cast(slot, int(cmd.get("option", -1)), run.is_human(slot))
			if not error.is_empty():
				return {"ok": false, "error": error}
			run.emit({"type": "story_vote_cast", "slot": slot})
			if vote.everyone_voted(run.humans()):
				_resolve(run)
			return {"ok": true}
		"ready":
			if stage != "outcome":
				return {"ok": false, "error": "wrong_phase"}
			if ready_slots.has(slot):
				return {"ok": false, "error": "already_ready"}
			ready_slots.append(slot)
			_finish_if_everyone_ready(run)
			return {"ok": true}
	return {"ok": false, "error": "wrong_phase"}


func update(run: MatchRun) -> void:
	if done or run.clock.now() < deadline:
		return
	if stage == "choosing":
		_resolve(run)
	else:
		done = true


func on_control_changed(run: MatchRun, slot: int) -> void:
	if stage == "choosing":
		vote.forget(slot)
		if vote.everyone_voted(run.humans()):
			_resolve(run)
	else:
		_finish_if_everyone_ready(run)


func view(run: MatchRun, viewer_slot: int) -> Dictionary:
	var data := _event(run)
	var out := {
		"kind": "story",
		"stage": stage,
		"title": str(data.get("title", "")),
		"text": str(data.get("text", "")),
		"deadline": deadline,
	}
	if stage == "choosing":
		out["vote"] = vote.view()
	else:
		out["outcome"] = result
		out["ready"] = ready_slots.duplicate()
		out["you_are_ready"] = ready_slots.has(viewer_slot)
	return out


func _event(run: MatchRun) -> Dictionary:
	return run.content.get_dict("story.events.%s" % event_id)


func _resolve(run: MatchRun) -> void:
	var decided := vote.resolve(run.rng)
	var choices: Array = _event(run).get("choices", [])
	var voters := {}
	for slot in vote.votes:
		voters[str(slot)] = vote.votes[slot]
	run.emit({
		"type": "story_choice_resolved",
		"option": decided["option"],
		"label": str(choices[decided["option"]].get("label", "")),
		"tally": decided["tally"],
		"votes": voters,
		"tie_broken": decided["tie_broken"],
		"no_votes": decided["no_votes"],
	})
	_show_outcome(run, choices[decided["option"]].get("outcome", {}))


## Applies an outcome (clue, Gold, Items, healing, EXP) and starts reading.
func _show_outcome(run: MatchRun, data: Dictionary) -> void:
	stage = "outcome"
	outcome = data
	result = {"text": str(data.get("text", "")), "clue": null, "gold": int(data.get("gold", 0)),
			"items": data.get("items", {}), "exp": int(data.get("exp", 0)), "healed": false}
	if data.has("clue") and run.add_clue(str(data["clue"]), "story"):
		result["clue"] = run.clue_view(str(data["clue"]))
	run.add_gold(result["gold"])
	for item in result["items"]:
		run.add_item(item, int(result["items"][item]))
	if data.has("heal_ratio"):
		for character in run.party:
			if character["hp"] > 0:
				character["hp"] = mini(character["max_hp"],
						character["hp"] + int(round(character["max_hp"] * float(data["heal_ratio"]))))
		result["healed"] = true
	for character in run.party:
		run.grant_exp(character["slot"], result["exp"])
	deadline = run.clock.now() + run.content.get_float("rules.story_read_seconds", 25.0)
	run.emit({"type": "story_outcome", "event": event_id, "outcome": result})


func _finish_if_everyone_ready(run: MatchRun) -> void:
	if done or stage != "outcome":
		return
	for slot in run.humans().size():
		if run.is_human(slot) and not ready_slots.has(slot):
			return
	done = true
