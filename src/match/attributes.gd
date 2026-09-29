class_name Attributes
extends RefCounted

const ATTRS: Array[String] = ["str", "dex", "con", "int", "fth", "cha", "lck"]
const STATS: Array[String] = ["max_hp", "atk", "def", "mag", "res", "spd"]
const DERIVED: Array[String] = ["initiative", "crit", "crit_damage", "dodge", "block", "block_reduction", "aggro", "lifesteal", "energy_regen"]

static func recalculate(character: Dictionary, content: ForestContent) -> void:
	var base := content.get_dict("classes.%s.base" % character["class"])
	var base_attrs := content.get_dict("classes.%s.attributes" % character["class"])
	var growth := content.get_dict("leveling.growth")
	var invest := content.get_dict("leveling.invest")
	var invested: Dictionary = character.get("invested", {})
	var levels: int = character["level"] - 1

	if not character.has("attributes"):
		character["attributes"] = {}
	if not character.has("derived"):
		character["derived"] = {}
	
	# 1. Calculate Attributes (Base + Level Investment + Gear)
	for attr in ATTRS:
		var val = int(base_attrs.get(attr, 0)) + int(invest.get(attr, 0)) * int(invested.get(attr, 0))
		character["attributes"][attr] = val

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
				character["crit"] = float(character["crit"]) + float(bonus[stat])
			elif STATS.has(stat):
				character[stat] = int(character[stat]) + int(bonus[stat])
				
	# 3. Calculate Derived Stats
	var derived: Dictionary = character["derived"]
	derived["crit_damage"] = content.get_float("rules.crit_multiplier", 1.5) + float(attrs["lck"]) * 0.02
	derived["dodge"] = float(attrs["dex"]) * 0.005
	derived["block"] = float(attrs["con"]) * 0.005
	derived["block_reduction"] = 0.5
	
	var cls = str(character["class"])
	var aggro = content.get_float("classes.%s.aggro" % cls, 1.0)
	derived["aggro"] = aggro
	
	var lifesteal = 0.0
	for item in character.get("gear", {}).values():
		var bonus := content.get_dict("items.%s.gear.stats" % item)
		if bonus.has("lifesteal"):
			lifesteal += float(bonus["lifesteal"])
	derived["lifesteal"] = lifesteal
	
	derived["energy_regen"] = content.get_int("rules.energy_regen", 1)
	derived["initiative"] = character["spd"]
