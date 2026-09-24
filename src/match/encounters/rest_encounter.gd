class_name RestEncounter
extends Encounter
## Rest: every character recovers a share of their max HP (content data),
## then the journey continues after a short pause.

var healed: Array = []
var ends_at := -1.0


func start(run: MatchRun) -> void:
	var ratio := run.content.get_float("encounters.rest.heal_ratio", 0.5)
	for character in run.party:
		var before: int = character["hp"]
		var amount := int(round(character["max_hp"] * ratio))
		character["hp"] = mini(character["max_hp"], maxi(1, character["hp"] + amount))
		healed.append({"slot": character["slot"], "amount": character["hp"] - before, "hp": character["hp"]})
	ends_at = run.clock.now() + run.content.get_float("encounters.rest.seconds", 4.0)
	run.emit({"type": "rested", "healed": healed})


func update(run: MatchRun) -> void:
	if run.clock.now() >= ends_at:
		done = true


func view(run: MatchRun, _viewer_slot: int) -> Dictionary:
	return {
		"kind": "rest",
		"text": str(run.content.get_value("encounters.rest.text", "")),
		"healed": healed,
		"ends_at": ends_at,
	}
