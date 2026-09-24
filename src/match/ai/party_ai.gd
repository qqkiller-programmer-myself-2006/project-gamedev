class_name PartyAi
extends RefCounted
## AI replacement: decides combat actions for Party characters whose slot
## has no human, using a behavior preset per Class. Choices that involve
## chance use the Match's GameRng so a Match replays exactly from its seed.
##
## Every preset first looks after itself: heal with an Item when HP is low,
## Defend when HP is critical and no Item is left. Then:
##   classless  attack (usually the weakest enemy it can reach)
##   swordsman  Power Slash the toughest enemy in reach whenever it is ready,
##              otherwise attack like Classless
##   archer     always picks off the weakest enemy, with Aimed Shot when ready
##   mage       Fireball when two or more enemies stand and it is ready, else
##              Frost Lance or a magic attack on the weakest enemy

const LOW_HP := 0.35
const CRITICAL_HP := 0.2
const FOCUS_WEAKEST_CHANCE := 0.7


static func decide(run: MatchRun, combat: CombatEncounter, slot: int) -> Dictionary:
	var me: Dictionary = run.party[slot]
	var id := CombatEncounter._pid(slot)
	var ratio := float(me["hp"]) / float(me["max_hp"])
	if ratio < LOW_HP:
		var item := _healing_item(run)
		if not item.is_empty():
			return {"actor": id, "action": "item", "item": item,
					"profile": run.content.get_dict("items.%s.use" % item), "targets": [id]}
		if ratio < CRITICAL_HP:
			return {"actor": id, "action": "defend"}
	match str(run.content.get_value("classes.%s.ai" % me["class"], "classless")):
		"swordsman":
			var slash := _ready_skill(run, combat, id, "power_slash")
			if not slash.is_empty():
				return _skill_on(run, combat, id, "power_slash", toughest(run, combat, slash))
		"archer":
			var aimed := _ready_skill(run, combat, id, "aimed_shot")
			if not aimed.is_empty():
				return _skill_on(run, combat, id, "aimed_shot", weakest(run, combat, aimed))
			return _attack_weakest(run, combat, id)
		"mage":
			var fire := _ready_skill(run, combat, id, "fireball")
			if fire.size() >= 2:
				return {"actor": id, "action": "skill", "skill": "fireball",
						"profile": combat.skill_profile(run, "fireball"), "targets": fire}
			var lance := _ready_skill(run, combat, id, "frost_lance")
			if not lance.is_empty():
				return _skill_on(run, combat, id, "frost_lance", weakest(run, combat, lance))
			return _attack_weakest(run, combat, id)
	return _basic_attack(run, combat, id)


static func _attack_weakest(run: MatchRun, combat: CombatEncounter, id: String) -> Dictionary:
	var profile := combat.attack_profile(run, id)
	return {"actor": id, "action": "attack", "profile": profile,
			"targets": [weakest(run, combat, combat.valid_targets(run, id, profile))]}


## Targets for `skill` if `id` has it ready, else an empty array.
static func _ready_skill(run: MatchRun, combat: CombatEncounter, id: String, skill: String) -> Array[String]:
	if not combat.class_skills(run, id).has(skill) or combat.skill_cooldown(id, skill) > 0:
		return []
	return combat.valid_targets(run, id, combat.skill_profile(run, skill))


static func _skill_on(run: MatchRun, combat: CombatEncounter, id: String, skill: String, target: String) -> Dictionary:
	return {"actor": id, "action": "skill", "skill": skill, "profile": combat.skill_profile(run, skill),
			"targets": [target]}


## Enemy id with the most current HP among `targets` (ties: lowest id).
static func toughest(run: MatchRun, combat: CombatEncounter, targets: Array[String]) -> String:
	var best := ""
	var best_hp := 0
	for target in targets:
		var hp: int = combat._unit(run, target)["hp"]
		if best.is_empty() or hp > best_hp:
			best = target
			best_hp = hp
	return best


static func _basic_attack(run: MatchRun, combat: CombatEncounter, id: String) -> Dictionary:
	var profile := combat.attack_profile(run, id)
	var targets := combat.valid_targets(run, id, profile)
	var target := ""
	if run.rng.chance(FOCUS_WEAKEST_CHANCE):
		target = weakest(run, combat, targets)
	else:
		target = str(run.rng.pick(targets))
	return {"actor": id, "action": "attack", "profile": profile, "targets": [target]}


## Enemy id with the least current HP among `targets` (ties: lowest id).
static func weakest(run: MatchRun, combat: CombatEncounter, targets: Array[String]) -> String:
	var best := ""
	var best_hp := 0
	for target in targets:
		var hp: int = combat._unit(run, target)["hp"]
		if best.is_empty() or hp < best_hp:
			best = target
			best_hp = hp
	return best


## The cheapest Item in the shared inventory that heals an ally, or "".
static func _healing_item(run: MatchRun) -> String:
	var best := ""
	var best_heal := 0
	for item in run.inventory:
		if int(run.inventory[item]) <= 0:
			continue
		var use := run.content.get_dict("items.%s.use" % item)
		if str(use.get("target", "")) != "ally" or not use.has("heal"):
			continue
		var heal := int(use["heal"])
		if best.is_empty() or heal < best_heal:
			best = item
			best_heal = heal
	return best
