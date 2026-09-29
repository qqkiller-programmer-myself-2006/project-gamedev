class_name Attributes
extends RefCounted

const ATTRS: Array[String] = ["str", "dex", "con", "int", "fth", "cha", "lck"]
const STATS: Array[String] = ["max_hp", "atk", "def", "mag", "res", "spd"]
const DERIVED: Array[String] = ["initiative", "crit", "crit_damage", "dodge", "block", "block_reduction", "aggro", "lifesteal", "energy_regen", "status_resist"]

static func recalculate(character: Dictionary, content: ForestContent) -> void:
	var base := content.get_dict("classes.%s.base" % character["class"])
	var base_attrs := content.get_dict("classes.%s.attributes" % character["class"])
	var growth := content.get_dict("leveling.growth")
	var invest := content.get_dict("leveling.invest")
	var invested: Dictionary = character.get("invested", {})
	var levels: int = character["level"] - 1
	var race := str(character.get("race", ""))
	var boons: Array = character.get("boons", [])

	if not character.has("attributes"):
		character["attributes"] = {}
	if not character.has("derived"):
		character["derived"] = {}
	
	# 1. Calculate Attributes (Base + Level Investment + Gear)
	for attr in ATTRS:
		var val = int(base_attrs.get(attr, 0)) + int(invest.get(attr, 0)) * int(invested.get(attr, 0))
		character["attributes"][attr] = val
	if race == "Human":
		for attr in ATTRS:
			character["attributes"][attr] += 1
	if race == "Elf":
		character["attributes"]["dex"] += 2
	if boons.has("The Chosen One"):
		for attr in ATTRS:
			character["attributes"][attr] += 2

	# Include gear attributes if they exist
	for item in character.get("gear", {}).values():
		var bonus := content.get_dict("items.%s.gear.stats" % item)
		for attr in ATTRS:
			if bonus.has(attr):
				character["attributes"][attr] += int(bonus[attr])

	# 2. Calculate Stats (Base + Growth + Attributes effect + Gear)
	var attrs: Dictionary = character["attributes"]
	var atk_attr = str(content.get_value("classes.%s.atk_attr" % character["class"], "str"))
	
	for stat in STATS:
		character[stat] = int(base.get(stat, 0)) + int(growth.get(stat, 0)) * levels

	character["max_hp"] += attrs["con"] * 4
	character["atk"] += attrs[atk_attr]
	character["def"] += attrs["con"] / 2
	character["mag"] += attrs["int"]
	character["res"] += attrs["fth"] / 2
	character["spd"] += attrs["dex"] / 2
	
	character["crit"] = float(base.get("crit", 0.0)) + float(attrs["lck"]) * 0.01

	for item in character.get("gear", {}).values():
		var bonus := content.get_dict("items.%s.gear.stats" % item)
		for stat in bonus:
			if stat == "crit":
				character["crit"] = float(character["crit"]) + _gear_stat_bonus(
						float(bonus[stat]), str(item), character, content)
			elif STATS.has(stat):
				character[stat] = float(character[stat]) + _gear_stat_bonus(
						float(bonus[stat]), str(item), character, content)
				
	# 3. Calculate Derived Stats
	var derived: Dictionary = character["derived"]
	if race == "Elf": character["crit"] += 0.05
	if race == "Withered": character["max_hp"] = int(character["max_hp"] * 0.9)
	if race == "Dwarf": character["max_hp"] = int(character["max_hp"] * 1.1)
	if race == "Lunaeia": character["mag"] = int(character["mag"] * 1.1)
	derived["crit_damage"] = content.get_float("rules.crit_multiplier", 1.5) + float(attrs["lck"]) * 0.02
	derived["dodge"] = float(attrs["dex"]) * 0.005
	derived["block"] = float(attrs["con"]) * 0.005
	derived["block_reduction"] = 0.5
	
	var cls = str(character["class"])
	var aggro = content.get_float("classes.%s.aggro" % cls, 1.0)
	derived["aggro"] = aggro
	
	var lifesteal = 0.0
	if race == "Withered":
		lifesteal += 0.05
	for item in character.get("gear", {}).values():
		var bonus := content.get_dict("items.%s.gear.stats" % item)
		if bonus.has("lifesteal"):
			lifesteal += float(bonus["lifesteal"])
	derived["lifesteal"] = lifesteal
	
	derived["energy_regen"] = content.get_int("rules.energy_regen", 1)
	derived["initiative"] = character["spd"]
	derived["status_resist"] = 0.1 if race == "Dwarf" else 0.0
	if boons.has("Potential: Bunny"):
		derived["initiative"] += 3
		derived["dodge"] += 0.15
	if race == "Kobold":
		derived["dodge"] += 0.05
	if boons.has("Alert"):
		derived["initiative"] += 3


## Dwarf Masterwork improves the stats of gear which appears as the output
## of a crafting recipe by 0.75% per current character level.
static func _gear_stat_bonus(value: float, item: String, character: Dictionary,
		content: ForestContent) -> float:
	if str(character.get("race", "")) != "Dwarf":
		return value
	var crafted := false
	for recipe in content.get_dict("crafting.recipes").values():
		if recipe is Dictionary and str(recipe.get("makes", "")) == item:
			crafted = true
			break
	if not crafted:
		return value
	return value * (1.0 + 0.0075 * int(character.get("level", 1)))
