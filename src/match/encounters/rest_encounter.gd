class_name RestEncounter
extends Encounter
## Rest camp (ADR-0011): every character recovers a share of their max HP
## (content data), then the camp stays open so humans can craft from the
## Party's shared inventory, change their own character's gear and spend
## stat points. The journey continues when every human has pressed Ready or
## the camp timer runs out. AI-controlled slots need no Ready: when the camp
## closes they spend their points and put on gear left in the bag.
##
## Commands: craft {recipe}   equip {item, gear_slot}   unequip {gear_slot}
##           invest {stat}    ready

var healed: Array = []
var ready_slots: Array[int] = []
var deadline := -1.0


func start(run: MatchRun) -> void:
	var ratio := run.content.get_float("encounters.rest.heal_ratio", 0.5)
	for character in run.party:
		var before: int = character["hp"]
		var amount := int(round(character["max_hp"] * ratio))
		character["hp"] = mini(character["max_hp"], maxi(1, character["hp"] + amount))
		healed.append({"slot": character["slot"], "amount": character["hp"] - before, "hp": character["hp"]})
	deadline = run.clock.now() + run.content.get_float("encounters.rest.seconds", 60.0)
	run.emit({"type": "rested", "healed": healed, "deadline": deadline})
	_close_if_everyone_ready(run)


func handle(run: MatchRun, slot: int, cmd: Dictionary) -> Dictionary:
	if done:
		return {"ok": false, "error": "wrong_phase"}
	var error := ""
	match str(cmd.get("type", "")):
		"ready":
			if ready_slots.has(slot):
				return {"ok": false, "error": "already_ready"}
			ready_slots.append(slot)
			run.emit({"type": "rest_ready", "slot": slot, "ready": ready_slots.size(),
					"humans": _human_count(run)})
			_close_if_everyone_ready(run)
			return {"ok": true}
		"craft":
			error = run.craft(slot, str(cmd.get("recipe", "")))
		"equip":
			error = run.equip(slot, str(cmd.get("item", "")), str(cmd.get("gear_slot", "")))
		"unequip":
			error = run.unequip(slot, str(cmd.get("gear_slot", "")))
		"invest":
			error = run.invest(slot, str(cmd.get("stat", "")))
		_:
			error = "wrong_phase"
	if not error.is_empty():
		return {"ok": false, "error": error}
	return {"ok": true}


func update(run: MatchRun) -> void:
	if not done and run.clock.now() >= deadline:
		_close(run)


func on_control_changed(run: MatchRun, slot: int) -> void:
	# A slot handed to AI counts as Ready.
	if not run.is_human(slot):
		ready_slots.erase(slot)
	_close_if_everyone_ready(run)


func view(run: MatchRun, viewer_slot: int) -> Dictionary:
	return {
		"kind": "rest",
		"text": str(run.content.get_value("encounters.rest.text", "")),
		"healed": healed,
		"deadline": deadline,
		"ends_at": deadline,
		"ready": ready_slots.duplicate(),
		"humans": _human_count(run),
		"you_are_ready": ready_slots.has(viewer_slot),
		"recipes": _recipes_view(run),
		"categories": run.content.get_array("crafting.categories"),
		"gear_slots": run.gear_slots(),
		"invest": run.content.get_dict("leveling.invest"),
	}


func _recipes_view(run: MatchRun) -> Array:
	var out: Array = []
	var recipes := run.content.get_dict("crafting.recipes")
	var ids := recipes.keys()
	ids.sort()
	for id in ids:
		var data: Dictionary = recipes[id]
		var makes := str(data.get("makes", id))
		var item := run.content.get_dict("items.%s" % makes)
		var materials: Array = []
		var craftable := true
		for material in data.get("materials", {}):
			var need := int(data["materials"][material])
			var have := int(run.inventory.get(material, 0))
			craftable = craftable and have >= need
			materials.append({"item": material, "name": str(run.content.get_value("items.%s.name" % material, material)),
					"need": need, "have": have})
		out.append({
			"recipe": id,
			"item": makes,
			"name": str(item.get("name", makes)),
			"category": str(item.get("category", "")),
			"description": str(item.get("description", "")),
			"count": int(data.get("count", 1)),
			"materials": materials,
			"craftable": craftable,
		})
	return out


func _human_count(run: MatchRun) -> int:
	var count := 0
	for slot in run.humans().size():
		if run.is_human(slot):
			count += 1
	return count


func _close_if_everyone_ready(run: MatchRun) -> void:
	if done:
		return
	for slot in run.humans().size():
		if run.is_human(slot) and not ready_slots.has(slot):
			return
	_close(run)


func _close(run: MatchRun) -> void:
	for slot in run.party.size():
		if not run.is_human(slot):
			run.camp_ai(slot)
	done = true
	run.emit({"type": "rest_closed"})
