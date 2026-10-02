class_name BattlePresentation
extends RefCounted
## Pure conversion from a Match view/event to renderer-facing battle data.


static func state(view: Dictionary) -> Dictionary:
	var encounter: Dictionary = _dictionary(view.get("encounter", {}))
	var units: Array[Dictionary] = []
	var party: Variant = view.get("party", [])
	if party is Array:
		for unit_value in party:
			if not unit_value is Dictionary:
				continue
			var unit: Dictionary = unit_value
			var slot := int(unit.get("slot", units.size()))
			units.append({
				"id": str(unit.get("id", "p%d" % slot)),
				"side": "party",
				"slot": slot,
				"class_key": str(unit.get("class", "classless")),
				"name": str(unit.get("name", "")),
				"hp": int(unit.get("hp", 0)),
				"max_hp": int(unit.get("max_hp", 0)),
				"energy": int(unit.get("energy", 0)),
				"alive": int(unit.get("hp", 0)) > 0,
			})

	var enemies: Variant = encounter.get("enemies", [])
	var is_boss := str(encounter.get("kind", "")) == "boss"
	if enemies is Array:
		for i in enemies.size():
			var enemy_value: Variant = enemies[i]
			if not enemy_value is Dictionary:
				continue
			var enemy: Dictionary = enemy_value
			var enemy_slot := int(enemy.get("slot", i))
			var presented_enemy := {
				"id": str(enemy.get("id", "e%d" % i)),
				"side": "enemy",
				"slot": enemy_slot,
				"class_key": str(enemy.get("kind", enemy.get("class", ""))),
				"name": str(enemy.get("name", enemy.get("kind", ""))),
				"hp": int(enemy.get("hp", 0)),
				"max_hp": int(enemy.get("max_hp", 0)),
				"energy": int(enemy.get("energy", 0)),
				"alive": int(enemy.get("hp", 0)) > 0,
				"boss": is_boss,
			}
			if enemy.has("row"):
				presented_enemy["row"] = str(enemy["row"])
			units.append(presented_enemy)

	var mode := str(view.get("mode", encounter.get("mode", "")))
	return {
		"units": units,
		"current_actor": str(encounter.get("actor", "")),
		"mode": mode,
		"targets": _targets_for_mode(encounter, mode, view.get("targets", [])),
	}


static func cues(event: Dictionary) -> Array[Dictionary]:
	if str(event.get("type", "")) != "action_resolved":
		return []

	var actor := str(event.get("actor", ""))
	var action := str(event.get("action", ""))
	var action_cue := ""
	match action:
		"attack":
			action_cue = "strike"
		"skill", "special":
			action_cue = "skill"
		"focus":
			action_cue = "focus"
		"item":
			action_cue = "item"
		"defend":
			action_cue = "guard"
		_:
			return []

	var cues_out: Array[Dictionary] = []
	var skill_id := str(event.get("skill", event.get("move", ""))) if action_cue == "skill" else ""
	var action_target := str(event.get("target", ""))
	if action_target.is_empty():
		var event_targets: Variant = event.get("targets", [])
		if event_targets is Array and not event_targets.is_empty():
			action_target = str(event_targets[0])
	cues_out.append(_cue(action_cue, actor, action_target, skill_id, 0, false))

	var results: Variant = event.get("results", [])
	if results is Array:
		for result_value in results:
			if not result_value is Dictionary:
				continue
			var result: Dictionary = result_value
			var target := str(result.get("target", ""))
			if result.has("damage"):
				var defeated := bool(result.get("down", false))
				cues_out.append(_cue("die" if defeated else "hurt", actor, target, skill_id,
						int(result.get("damage", 0)), bool(result.get("crit", false))))
			elif result.has("heal") or bool(result.get("revived", false)):
				cues_out.append(_cue("heal", actor, target, skill_id, int(result.get("heal", 0)), false))
	return cues_out


static func _targets_for_mode(encounter: Dictionary, mode: String, fallback: Variant) -> Array[String]:
	if fallback is Array:
		var targets: Array[String] = []
		for target in fallback:
			targets.append(str(target))
		if not targets.is_empty():
			return targets

	var choices: Dictionary = _dictionary(encounter.get("choices", {}))
	if mode == "attack":
		return _string_array(_dictionary(choices.get("attack", {})).get("targets", []))
	if mode.begins_with("skill:"):
		var skills: Dictionary = _dictionary(choices.get("skills", {}))
		return _string_array(_dictionary(skills.get(mode.trim_prefix("skill:"), {})).get("targets", []))
	if mode.begins_with("item:"):
		var items: Dictionary = _dictionary(choices.get("items", {}))
		return _string_array(_dictionary(items.get(mode.trim_prefix("item:"), {})).get("targets", []))
	return []


static func _cue(type: String, actor: String, target: String, skill_id: String, amount: int, crit: bool) -> Dictionary:
	return {
		"type": type,
		"actor": actor,
		"target": target,
		"skill_id": skill_id,
		"amount": amount,
		"crit": crit,
	}


static func _string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(str(item))
	return out


static func _dictionary(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}
