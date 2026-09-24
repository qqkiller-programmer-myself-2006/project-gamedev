class_name TreasureEncounter
extends Encounter
## Treasure: a few seeded rolls on the content loot table add Gold and Items
## to the Party's shared pool, then the journey continues after a short pause.

var found := {"gold": 0, "items": {}}
var ends_at := -1.0


func start(run: MatchRun) -> void:
	var loot := run.content.get_array("encounters.treasure.loot")
	var weights: Array = []
	for entry in loot:
		weights.append(float(entry.get("weight", 1.0)))
	for roll in run.content.get_int("encounters.treasure.rolls", 1):
		var index := run.rng.weighted_index(weights)
		if index < 0:
			continue
		var entry: Dictionary = loot[index]
		if entry.has("gold"):
			var span: Array = entry["gold"]
			found["gold"] += run.rng.randi_range(int(span[0]), int(span[1]))
		if entry.has("item"):
			var item := str(entry["item"])
			found["items"][item] = int(found["items"].get(item, 0)) + int(entry.get("count", 1))
	run.add_gold(found["gold"])
	for item in found["items"]:
		run.add_item(item, found["items"][item])
	ends_at = run.clock.now() + run.content.get_float("encounters.treasure.seconds", 4.0)
	run.emit({"type": "treasure_found", "gold": found["gold"], "items": found["items"]})


func update(run: MatchRun) -> void:
	if run.clock.now() >= ends_at:
		done = true


func view(run: MatchRun, _viewer_slot: int) -> Dictionary:
	return {
		"kind": "treasure",
		"text": str(run.content.get_value("encounters.treasure.text", "")),
		"found": found,
		"ends_at": ends_at,
	}
