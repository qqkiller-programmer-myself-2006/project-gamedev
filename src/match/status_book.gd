class_name StatusBook
extends RefCounted
## Status effects on every unit of one Combat (ADR-0010).
##
## Each status is data, defined in content under `statuses.<id>`, so a new
## kind needs no code:
##   {"name": "Bleed", "kind": "dot"|"buff", "damage": 3, "turns": 3,
##    "tick_every": 1, "max_stacks": 5, "charges": 3, "color": "#e0473f",
##    "description": "..."}
## A DoT deals `damage` x stacks (x the applier's and receiver's modifiers)
## at the start of every `tick_every`-th turn of the afflicted unit, ignoring
## DEF/RES. `color` is the badge and floating-number colour clients use. Every
## status loses one turn at the start of its holder's turn and is removed at
## zero. Reapplying adds stacks (up to max_stacks) and keeps the longer
## duration. The book lives inside one Combat, so everything is cleared when
## the Combat (or Challenge) ends.

var _content: ForestContent
## unit id -> Array of {"status", "stacks", "turns", "charges", "power"}
var _on: Dictionary = {}


func _init(content: ForestContent) -> void:
	_content = content


## Adds `stacks` of `status` to `unit_id`. `power` scales its DoT damage
## (the applier's outgoing DoT modifier). Returns the resulting entry view,
## or {} when `status` is not defined in content.
func apply(unit_id: String, status: String, stacks: int, turns: int, power: float = 1.0) -> Dictionary:
	var info := _content.get_dict("statuses.%s" % status)
	if info.is_empty():
		push_warning("StatusBook: unknown status '%s'" % status)
		return {}
	var list: Array = _on.get(unit_id, [])
	var entry: Dictionary = {}
	for existing in list:
		if existing["status"] == status:
			entry = existing
	var max_stacks := int(info.get("max_stacks", 1))
	if turns <= 0:
		turns = int(info.get("turns", 1))
	if entry.is_empty():
		entry = {"status": status, "stacks": 0, "turns": 0, "age": 0,
				"charges": int(info.get("charges", 0)), "power": power}
		list.append(entry)
	else:
		entry["charges"] = maxi(int(entry["charges"]), int(info.get("charges", 0)))
		entry["power"] = maxf(float(entry["power"]), power)
	entry["stacks"] = mini(max_stacks, int(entry["stacks"]) + maxi(1, stacks))
	entry["turns"] = maxi(int(entry["turns"]), turns)
	_on[unit_id] = list
	return _view_entry(entry)


## Start of `unit_id`'s turn: DoTs deal damage, then every status loses a
## turn. Returns {"ticks": [{status, name, damage}], "expired": [status ids]}.
## Damage is not applied here; the caller owns HP. `taken` multiplies DoT
## damage the unit receives.
func start_turn(unit_id: String, taken: float = 1.0) -> Dictionary:
	var ticks: Array = []
	var expired: Array = []
	var kept: Array = []
	for entry in _on.get(unit_id, []):
		var info := _content.get_dict("statuses.%s" % entry["status"])
		entry["age"] = int(entry.get("age", 0)) + 1
		var every := maxi(1, int(info.get("tick_every", 1)))
		if str(info.get("kind", "dot")) == "dot" and int(entry["age"]) % every == 0:
			var amount := float(info.get("damage", 0)) * int(entry["stacks"]) * float(entry["power"]) * taken
			ticks.append({"status": entry["status"], "name": str(info.get("name", entry["status"])),
					"damage": maxi(1, int(round(amount))), "color": str(info.get("color", "#ffffff"))})
		entry["turns"] = int(entry["turns"]) - 1
		if int(entry["turns"]) > 0:
			kept.append(entry)
		else:
			expired.append(entry["status"])
	if kept.is_empty():
		_on.erase(unit_id)
	else:
		_on[unit_id] = kept
	return {"ticks": ticks, "expired": expired}


## Uses one charge of `status` on `unit_id` (e.g. a coated weapon landing a
## hit). Returns true when a charge was spent; the status goes when empty.
func spend_charge(unit_id: String, status: String) -> bool:
	var list: Array = _on.get(unit_id, [])
	for entry in list:
		if entry["status"] == status and int(entry["charges"]) > 0:
			entry["charges"] = int(entry["charges"]) - 1
			if int(entry["charges"]) <= 0:
				list.erase(entry)
				if list.is_empty():
					_on.erase(unit_id)
			return true
	return false


func has(unit_id: String, status: String) -> bool:
	for entry in _on.get(unit_id, []):
		if entry["status"] == status:
			return true
	return false


## Number of different DoT kinds on `unit_id`.
func distinct_dots(unit_id: String) -> int:
	var count := 0
	for entry in _on.get(unit_id, []):
		if str(_content.get_value("statuses.%s.kind" % entry["status"], "dot")) == "dot":
			count += 1
	return count


func clear() -> void:
	_on.clear()


func clear_unit(unit_id: String) -> void:
	_on.erase(unit_id)


## Statuses on `unit_id` for snapshots: [{status, name, kind, stacks, turns, charges}].
func view(unit_id: String) -> Array:
	var out: Array = []
	for entry in _on.get(unit_id, []):
		out.append(_view_entry(entry))
	return out


## Every afflicted unit: {unit id: view}.
func view_all() -> Dictionary:
	var out := {}
	for unit_id in _on:
		out[unit_id] = view(unit_id)
	return out


func _view_entry(entry: Dictionary) -> Dictionary:
	var info := _content.get_dict("statuses.%s" % entry["status"])
	return {
		"status": entry["status"],
		"name": str(info.get("name", entry["status"])),
		"kind": str(info.get("kind", "dot")),
		"stacks": int(entry["stacks"]),
		"turns": int(entry["turns"]),
		"charges": int(entry["charges"]),
		"tick_every": maxi(1, int(info.get("tick_every", 1))),
		"color": str(info.get("color", "#ffffff")),
	}
