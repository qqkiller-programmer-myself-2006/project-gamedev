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
##   craft {recipe}, equip {item, gear_slot},
##   unequip {gear_slot}, invest {stat}, ready    (Rest camp, ADR-0011)
##   vote {option}, ready                         (Story Event choice / reading)

const PARTY_SIZE := 5
## In-Match command types (routed here by MatchServer during a Match).
const COMMANDS: Array[String] = ["vote", "action", "class_choice", "buy", "ready",
		"craft", "equip", "unequip", "invest", "transfer_gold", "transfer_item"]
## Stats a character sheet is built from (crit is a ratio, the rest integers).
const STATS: Array[String] = ["max_hp", "atk", "def", "mag", "res", "spd"]

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
var gold: int:
	get:
		var sum := 0
		for c in party:
			sum += int(c.get("gold", 0))
		return sum
var inventory: Dictionary = {}
## Filled when the Match ends.
var summary: Dictionary = {}
var enemies_defeated := 0
## Gems earned by each Party slot during this Match.
var gems_earned: Array[int] = [0, 0, 0, 0, 0]
var layers_passed := 0
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
var _loadouts: Array = []
var story := false
var story_host := 0
var _layer_start: Dictionary = {}


func _init(match_rng: GameRng, match_clock, forest: ForestContent, humans: Array[bool], match_number: int, loadouts: Array = [], story_mode: bool = false, host_slot: int = 0) -> void:
	rng = match_rng
	clock = match_clock
	content = forest
	_humans = humans.duplicate()
	number = match_number
	_loadouts = loadouts.duplicate(true)
	story = story_mode
	story_host = host_slot
	_started_at = clock.now()
	_create_party()
	add_gold(content.get_int("party.starting_gold", 0))
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


func voters() -> Array[bool]:
	if story:
		var arr: Array[bool] = [false, false, false, false, false]
		arr[story_host] = true
		return arr
	return _humans


func needs_ready(slot: int) -> bool:
	return is_human(slot) and (not story or slot == story_host)


## A slot changes between human and AI control mid-Match.
func set_human(slot: int, human: bool) -> void:
	if _humans[slot] == human:
		return
	_humans[slot] = human
	if not human:
		emit({"type": "slot_ai_takeover", "slot": slot, "character": party[slot]["name"]})
	if phase == "voting" and vote != null:
		vote.forget(slot)
		if vote.everyone_voted(voters()):
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
			if vote.deadline >= 0.0 and now >= vote.deadline:
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
		"story": story,
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
			"kind": str(data.get("kind", "consumable")),
			"category": str(data.get("category", "")),
			"gear_slot": str(data.get("gear", {}).get("slot", "")),
			"target": str(data.get("use", {}).get("target", "")),
		})
	return out


func add_gold(amount: int, reward: bool = false) -> void:
	if amount <= 0 or party.is_empty():
		return
	var split = amount / party.size()
	var remainder = amount % party.size()
	for i in party.size():
		var character: Dictionary = party[i]
		var share: int = split + (remainder if i == 0 else 0)
		var bonus := 0
		if reward and str(character.get("race", "")) == "Kobold":
			bonus = int(round(share * 0.1))
		character["gold"] = int(character.get("gold", 0)) + share + bonus


func collect_ai_gold() -> void:
	var ai_gold := 0
	var human_slots: Array[int] = []
	for character in party:
		if not is_human(character["slot"]):
			var g = int(character.get("gold", 0))
			if g > 0:
				ai_gold += g
				character["gold"] = 0
		else:
			human_slots.append(character["slot"])
	if ai_gold > 0 and not human_slots.is_empty():
		var split = ai_gold / human_slots.size()
		var remainder = ai_gold % human_slots.size()
		for slot in human_slots:
			party[slot]["gold"] = int(party[slot].get("gold", 0)) + split
		if remainder > 0:
			party[human_slots[0]]["gold"] = int(party[human_slots[0]].get("gold", 0)) + remainder
		emit({"type": "ai_gold_transferred", "amount": ai_gold})

func add_item(item: String, count: int = 1) -> void:
	if count <= 0:
		return
	inventory[item] = int(inventory.get(item, 0)) + count


func remove_item(item: String, count: int = 1) -> bool:
	if count <= 0:
		return false
	var current = int(inventory.get(item, 0))
	if current < count:
		return false
	if current == count:
		inventory.erase(item)
	else:
		inventory[item] = current - count
	return true


func award_gems(slot: int, amount: int, source: String = "") -> void:
	if story:
		return
	if slot < 0 or slot >= gems_earned.size() or amount <= 0:
		return
	gems_earned[slot] += amount
	emit({"type": "gems_earned", "slot": slot, "amount": amount, "source": source,
			"total": gems_earned[slot]})


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
		character["points"] = int(character.get("points", 0)) + content.get_int("leveling.points_per_level", 0)
		character["points"] += _tree_level(character, "stat_points")
		if str(character.get("race", "")) == "Human" and int(character["level"]) % 2 == 0:
			character["points"] += 1
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
			"exp_next": _exp_to_next(int(c["level"])),
			"hp": c["hp"],
			"max_hp": c["max_hp"],
			"energy": c.get("energy", content.get_int("rules.energy_start", 1)),
			"energy_max": c.get("energy_max", content.get_int("rules.energy_max", 6)),
			"atk": c["atk"],
			"def": c["def"],
			"mag": c["mag"],
			"res": c["res"],
			"spd": c["spd"],
			"crit": c.get("crit", 0.0),
			"points": int(c.get("points", 0)),
			"race": c.get("race", "") if c.has("race") else "Human",
			"boons": c.get("boons", []).duplicate(),
			"invested": c.get("invested", {}).duplicate(),
			"attributes": c.get("attributes", {}).duplicate(),
			"derived": c.get("derived", {}).duplicate(),
			"gear": _gear_view(c),
			"controller": "human" if _humans[c["slot"]] else "ai",
			"gold": int(c.get("gold", 0)),
			"consumable": c.get("consumable", null),
		})
	return out


## EXP needed to reach the next level from `level` (0 at the level cap).
func _exp_to_next(level: int) -> int:
	var thresholds := content.get_array("leveling.exp_to_next")
	return int(thresholds[level - 1]) if level - 1 < thresholds.size() else 0


func _create_party() -> void:
	var members := content.get_array("party.members")
	var ai_order: Array = content.get_array("party.ai_class_order")
	var claimed: Array = []
	var has_human_loadout := false
	for candidate in _loadouts:
		var candidate_loadout: Dictionary = candidate.get("loadout", candidate) if candidate is Dictionary else {}
		if candidate_loadout is Dictionary and not str(candidate_loadout.get("class", "")).is_empty():
			has_human_loadout = true
			claimed.append(str(candidate_loadout.get("class", "")))
	var ai_index := 0
	for i in PARTY_SIZE:
		var member: Dictionary = members[i] if i < members.size() else {}
		var character := {
			"slot": i,
			"name": str(member.get("name", "Hero %d" % (i + 1))),
			"class": "classless",
			"level": 1,
			"exp": 0,
			"points": 0,
			"invested": {},
			"gear": {},
		}
		var entry: Dictionary = _loadouts[i] if i < _loadouts.size() and _loadouts[i] is Dictionary else {}
		var loadout: Dictionary = entry.get("loadout", entry) if entry is Dictionary else {}
		var profile: Dictionary = entry.get("profile", {}) if entry is Dictionary else {}
		if not _humans[i] and has_human_loadout:
			loadout = {}
			while ai_index < ai_order.size() and claimed.has(str(ai_order[ai_index])): ai_index += 1
			if ai_index < ai_order.size():
				loadout = {"class": str(ai_order[ai_index]), "race": "Human", "boons": []}
				claimed.append(str(ai_order[ai_index]))
				ai_index += 1
		if not loadout.is_empty():
			character["class"] = str(loadout.get("class", "classless"))
			character["race"] = str(loadout.get("race", "Human"))
			character["boons"] = loadout.get("boons", []).duplicate()
		character["_profile"] = ProfileStore.normalize(profile)
		_apply_stats(character)
		character["points"] = _tree_level(character, "stat_points")
		character["hp"] = character["max_hp"]
		character["energy"] = content.get_int("rules.energy_start", 1) + _energy_bonus(character)
		character["energy_max"] = content.get_int("rules.energy_max", 6)
		character["gold"] = 0
		character["consumable"] = null
		party.append(character)


## Recomputes a character's stats from its class and level, invested stat
## points and equipped gear (content data).
func _apply_stats(character: Dictionary) -> void:
	Attributes.recalculate(character, content)
	var tree: Dictionary = character.get("_profile", {}).get("class_trees", {}).get(character["class"], {})
	var prestige := int(character.get("_profile", {}).get("prestige", {}).get(character["class"], 0))
	var hp_bonus := 0.02 * int(tree.get("vitality", 0)) + 0.01 * prestige
	character["max_hp"] = int(round(float(character["max_hp"]) * (1.0 + hp_bonus)))
	character["damage_multiplier"] = 1.0 + 0.02 * int(tree.get("might", 0)) + 0.01 * prestige
	character["crit"] = float(character.get("crit", 0.0)) + 0.01 * int(tree.get("precision", 0))
	character["derived"]["initiative"] = float(character["derived"].get("initiative", character["spd"])) + floori(int(tree.get("swiftness", 0)) / 2)


func _tree_level(character: Dictionary, node: String) -> int:
	return int(character.get("_profile", {}).get("class_trees", {}).get(character.get("class", ""), {}).get(node, 0))


func _energy_bonus(character: Dictionary) -> int:
	var bonus := 1 if _tree_level(character, "reserves") >= 5 else 0
	if str(character.get("race", "Human")) == "Lunaeia":
		bonus += 1
	return bonus


# --- Camp: crafting, gear and stat points (ADR-0011) --------------------------

## Crafts `recipe` from the shared inventory. Returns "" or an error code.
func craft(slot: int, recipe: String) -> String:
	var data := content.get_dict("crafting.recipes.%s" % recipe)
	if data.is_empty():
		return "invalid_recipe"
	var materials: Dictionary = data.get("materials", {})
	for item in materials:
		if int(inventory.get(item, 0)) < int(materials[item]):
			return "missing_materials"
	for item in materials:
		_take_item(str(item), int(materials[item]))
	var made := str(data.get("makes", recipe))
	add_item(made, int(data.get("count", 1)))
	emit({"type": "crafted", "slot": slot, "recipe": recipe, "item": made,
			"name": str(content.get_value("items.%s.name" % made, made))})
	return ""


## Puts gear from the shared inventory on the character in `slot`. An empty
## `gear_slot` picks the item's own slot (the first free charm slot for
## charms). Whatever was there goes back to the inventory.
func equip(slot: int, item: String, gear_slot: String = "") -> String:
	if int(inventory.get(item, 0)) <= 0:
		return "item_unavailable"
	var kind := str(content.get_dict("items.%s.gear" % item).get("slot", ""))
	if kind.is_empty():
		return "not_gear"
	if gear_slot.is_empty():
		gear_slot = _free_gear_slot(party[slot], kind)
	if not gear_slots().has(gear_slot) or not gear_slot.begins_with(kind):
		return "wrong_gear_slot"
	var character: Dictionary = party[slot]
	var gear: Dictionary = character["gear"]
	var old_max: int = character["max_hp"]
	_take_item(item, 1)
	if gear.has(gear_slot):
		add_item(str(gear[gear_slot]), 1)
	gear[gear_slot] = item
	_restat(character, old_max)
	emit({"type": "equipped", "slot": slot, "gear_slot": gear_slot, "item": item})
	return ""


func unequip(slot: int, gear_slot: String) -> String:
	var character: Dictionary = party[slot]
	var gear: Dictionary = character["gear"]
	if not gear.has(gear_slot):
		return "nothing_equipped"
	var old_max: int = character["max_hp"]
	add_item(str(gear[gear_slot]), 1)
	gear.erase(gear_slot)
	_restat(character, old_max)
	emit({"type": "unequipped", "slot": slot, "gear_slot": gear_slot})
	return ""


## Spends one stat point of the character in `slot` on `stat`.
func invest(slot: int, stat: String) -> String:
	var character: Dictionary = party[slot]
	if int(character.get("points", 0)) <= 0:
		return "no_points"
	if not content.get_dict("leveling.invest").has(stat):
		return "invalid_stat"
	var old_max: int = character["max_hp"]
	character["points"] = int(character["points"]) - 1
	character["invested"][stat] = int(character["invested"].get(stat, 0)) + 1
	_restat(character, old_max)
	emit({"type": "invested", "slot": slot, "stat": stat, "points": character["points"]})
	return ""


## An AI-controlled character at camp: spends its points on its Class's
## focus stat and puts on any gear left in the bag for its empty slots.
func camp_ai(slot: int) -> void:
	var character: Dictionary = party[slot]
	var focus := str(content.get_value("classes.%s.invest_focus" % character["class"], "max_hp"))
	while int(character.get("points", 0)) > 0:
		if not invest(slot, focus).is_empty():
			break
	var ids := inventory.keys()
	ids.sort()
	for item in ids:
		var kind := str(content.get_dict("items.%s.gear" % item).get("slot", ""))
		if kind.is_empty():
			continue
		while int(inventory.get(item, 0)) > 0:
			var free := _free_gear_slot(character, kind)
			if free.is_empty() or character["gear"].has(free):
				break
			equip(slot, item, free)


## Every equipment slot a character has, e.g. helmet ... charm3.
func gear_slots() -> Array:
	return content.get_array("crafting.gear_slots")


func _free_gear_slot(character: Dictionary, kind: String) -> String:
	var first := ""
	for gear_slot in gear_slots():
		if not str(gear_slot).begins_with(kind):
			continue
		if first.is_empty():
			first = gear_slot
		if not character["gear"].has(gear_slot):
			return gear_slot
	return first


func _take_item(item: String, count: int) -> void:
	inventory[item] = int(inventory.get(item, 0)) - count
	if int(inventory[item]) <= 0:
		inventory.erase(item)


## Rebuilds stats after gear or points change; HP follows any max HP change.
func _restat(character: Dictionary, old_max: int) -> void:
	_apply_stats(character)
	if character["hp"] > 0:
		character["hp"] = clampi(character["hp"] + character["max_hp"] - old_max, 1, character["max_hp"])


func _gear_view(character: Dictionary) -> Dictionary:
	var out := {}
	for gear_slot in character.get("gear", {}):
		var item := str(character["gear"][gear_slot])
		out[gear_slot] = {"item": item, "name": str(content.get_value("items.%s.name" % item, item)),
				"description": str(content.get_value("items.%s.description" % item, ""))}
	return out


# --- Journey ----------------------------------------------------------------

func _begin_layer(next_layer: int) -> void:
	layer = next_layer
	phase = "voting"
	encounter = null
	var seconds := content.get_float("rules.vote_seconds", 20.0)
	var deadline: float = -1.0 if story else clock.now() + seconds
	vote = PathVote.new(layer, routes[layer - 1], deadline, seconds)
	var view := vote.view()
	emit({"type": "vote_started", "layer": layer, "options": view["options"], "deadline": deadline})
	if story:
		_layer_start = {
			"version": 1, "seed": rng.save_state()["seed"], "rng": rng.save_state(), "layer": layer,
			"route": routes.duplicate(true), "party": party.duplicate(true),
			"stash": inventory.duplicate(true), "gold": gold,
			"clues": clues.duplicate(true), "classes_discovered": classes_discovered.duplicate(),
			"enemies_defeated": enemies_defeated, "layers_passed": layers_passed,
			"gems_earned": gems_earned.duplicate(), "last_vote": last_vote.duplicate(true),
		}
		emit({"type": "story_layer_started", "layer": layer})


func export_layer_start() -> Dictionary:
	return _layer_start.duplicate(true) if story else {}


static func valid_story_save(data: Dictionary, forest: ForestContent) -> bool:
	if int(data.get("version", -1)) != 1:
		return false
	var route = data.get("route")
	var saved_party = data.get("party")
	var next_layer := int(data.get("layer", 0))
	if not (route is Array) or not (saved_party is Array) or saved_party.size() != PARTY_SIZE:
		return false
	if next_layer < 1 or next_layer > route.size() or route.size() != forest.get_int("journey.layers", 5):
		return false
	if not (data.get("rng") is Dictionary) or not (data.get("stash") is Dictionary) or not (data.get("clues") is Array):
		return false
	var gems_earned = data.get("gems_earned")
	if not (gems_earned is Array) or gems_earned.size() != PARTY_SIZE:
		return false
	var saved_gold = data.get("gold")
	if not _is_whole_number(saved_gold) or int(saved_gold) < 0 or int(saved_gold) > 1000000:
		return false
	var valid_clues := forest.get_dict("story.clues")
	var seen_clues := {}
	for clue in data["clues"]:
		if not (clue is Dictionary) or not _has_exact_keys(clue,
				["id", "title", "text", "layer", "source"]):
			return false
		if not (clue["id"] is String) or not (clue["title"] is String) \
				or not (clue["text"] is String) or not _is_whole_number(clue["layer"]) \
				or not (clue["source"] is String):
			return false
		var clue_id := str(clue["id"])
		if not valid_clues.has(clue_id) or seen_clues.has(clue_id):
			return false
		var canonical: Dictionary = valid_clues[clue_id]
		if clue["title"] != str(canonical.get("title", clue_id)) \
				or clue["text"] != str(canonical.get("text", "")):
			return false
		if int(clue["layer"]) < 1 or int(clue["layer"]) > forest.get_int("journey.layers", 5) \
				or str(clue["source"]) not in ["story", "combat"]:
			return false
		seen_clues[clue_id] = true
	for item in data["stash"]:
		if str(item).is_empty() or not forest.get_value("items.%s" % item, null):
			return false
		if not (data["stash"][item] is int or data["stash"][item] is float) or int(data["stash"][item]) <= 0:
			return false
	var max_level = forest.get_int("rules.max_level", 20)
	var pts_per_lvl = forest.get_int("leveling.points_per_level", 0)
	var party_gold := 0
	for character in saved_party:
		if not (character is Dictionary): return false
		for key in ["class", "hp", "max_hp", "level", "points", "invested", "attributes", "gear", "gold"]:
			if not character.has(key): return false
		if not (character["class"] is String) or not forest.get_dict("classes").has(character["class"]):
			return false
		if not _is_whole_number(character["level"]) or not _is_whole_number(character["points"]) \
				or not _is_whole_number(character["gold"]):
			return false
		var level = int(character["level"])
		if level < 1 or level > max_level or int(character["points"]) < 0 \
				or int(character["gold"]) < 0 or int(character["gold"]) > 1000000:
			return false
		if not (character["attributes"] is Dictionary) or not (character["invested"] is Dictionary) \
				or not (character["gear"] is Dictionary):
			return false
		for gear_slot in character["gear"]:
			var item = str(character["gear"][gear_slot])
			if item.is_empty() or not forest.get_value("items.%s" % item, null):
				return false
		var consumable = character.get("consumable")
		if consumable != null:
			if not (consumable is Dictionary) or not consumable.has("item") or not consumable.has("count"):
				return false
			var item = str(consumable["item"])
			if item.is_empty() or not forest.get_value("items.%s" % item, null):
				return false
		var expected_total: int = (level - 1) * pts_per_lvl
		if str(character.get("race", "")) == "Human":
			expected_total += floori(float(level) / 2.0)
		var invested: Dictionary = character.get("invested", {})
		var sum_invested := 0
		for stat in invested:
			if stat not in Attributes.ATTRS or not _is_whole_number(invested[stat]) or int(invested[stat]) < 0:
				return false
			sum_invested += int(invested[stat])
		if sum_invested + int(character.get("points", 0)) != expected_total:
			return false
		var saved_boons = character.get("boons", [])
		if not saved_boons is Array:
			return false
		var expected := {
			"class": character["class"], "level": level,
			"race": str(character.get("race", "")),
			"boons": saved_boons.duplicate(),
			"invested": invested.duplicate(true), "gear": character["gear"].duplicate(true),
			"attributes": {}, "derived": {},
		}
		Attributes.recalculate(expected, forest)
		var attributes: Dictionary = character["attributes"]
		if not _has_exact_keys(attributes, Attributes.ATTRS):
			return false
		for stat in Attributes.ATTRS:
			if not _is_whole_number(attributes[stat]) \
					or int(attributes[stat]) != int(expected["attributes"][stat]):
				return false
		party_gold += int(character["gold"])
	if party_gold != int(saved_gold):
		return false
	return true


static func _is_whole_number(value) -> bool:
	return value is int or (value is float and is_equal_approx(value, floorf(value)))


static func _has_exact_keys(data: Dictionary, keys: Array) -> bool:
	if data.size() != keys.size():
		return false
	for key in keys:
		if not data.has(key):
			return false
	return true


func restore_layer_start(data: Dictionary) -> void:
	routes = data["route"].duplicate(true)
	party.clear()
	for character in data["party"]:
		party.append(character.duplicate(true))
	inventory = data["stash"].duplicate(true)
	clues.clear()
	for clue in data["clues"]:
		clues.append(clue.duplicate(true))
	classes_discovered.clear()
	for class_id in data.get("classes_discovered", []):
		classes_discovered.append(str(class_id))
	enemies_defeated = int(data.get("enemies_defeated", 0))
	layers_passed = int(data.get("layers_passed", 0))
	for i in gems_earned.size():
		gems_earned[i] = int(data.get("gems_earned", [0, 0, 0, 0, 0])[i])
	last_vote = data.get("last_vote", {}).duplicate(true)
	rng.restore_state(data["rng"])
	_begin_layer(int(data["layer"]))


## DEV ONLY (Playtest, see DevJump): drops the current Vote/Encounter and starts
## `option` on `to_layer` right away; an empty option starts the Guardian Boss.
func dev_jump(to_layer: int, option: Dictionary) -> void:
	vote = null
	_pending_option = {}
	_phase_deadline = -1.0
	if option.is_empty():
		layer = routes.size()
		layers_passed = routes.size()
		_reach_boss()
		return
	layer = to_layer
	layers_passed = to_layer - 1
	_pending_option = option
	_enter_encounter()


func _handle_vote(slot: int, cmd: Dictionary) -> Dictionary:
	if phase != "voting":
		return {"ok": false, "error": "wrong_phase"}
	var error := vote.cast(slot, int(cmd.get("option", -1)), is_human(slot))
	if not error.is_empty():
		return {"ok": false, "error": error}
	emit({"type": "vote_cast", "layer": layer, "slot": slot})
	if vote.everyone_voted(voters()):
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
	layers_passed += 1
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
	var reached_boss := phase == "boss"
	phase = outcome
	var base_gems := layers_passed * content.get_int("meta.gems.layer", 10)
	if outcome == "victory":
		base_gems += content.get_int("meta.gems.boss", 50)
	base_gems += clues.size() * content.get_int("meta.gems.story_clue", 5)
	for slot in gems_earned.size():
		gems_earned[slot] += base_gems
	encounter = null
	vote = null
	var ending := content.get_dict("ending.%s" % outcome)
	summary = {
		"result": outcome,
		"reached_boss": reached_boss,
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
		"gems_earned": gems_earned.duplicate(),
	}
	emit({"type": "match_ended", "result": outcome, "summary": summary})


func _encounter_view(viewer_slot: int) -> Variant:
	if phase not in ["encounter", "boss"] or encounter == null:
		return null
	var actor_slot := viewer_slot
	if story:
		var actor_id := ""
		if encounter is CombatEncounter:
			actor_id = str(encounter.actor)
		elif encounter is ClassEncounter and encounter.stage == "challenge":
			actor_id = str(encounter._trial.actor)
		if actor_id.begins_with("p"):
			actor_slot = int(actor_id.substr(1))
	var view := encounter.view(self, actor_slot)
	view["type"] = encounter.option["type"]
	view["name"] = encounter.option["name"]
	return view

func transfer_item(slot: int, item: String, to: int) -> String:
	if str(content.get_value("items.%s.kind" % item, "")) != "consumable":
		return "not_consumable"
	if to < 0 or to >= party.size():
		return "invalid_target"
	if not remove_item(item, 1):
		return "not_in_stash"
	var target_char = party[to]
	if target_char["consumable"] != null:
		var current = target_char["consumable"]
		if current["item"] == item:
			current["count"] = int(current["count"]) + 1
		else:
			# Swap
			var old_item = current["item"]
			var old_count = current["count"]
			add_item(old_item, old_count)
			target_char["consumable"] = {"item": item, "count": 1}
	else:
		target_char["consumable"] = {"item": item, "count": 1}
	emit({"type": "item_transferred", "from": slot, "to": to, "item": item})
	return ""
