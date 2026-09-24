class_name PartyAi
extends RefCounted
## AI replacement: decides combat actions for Party characters whose slot
## has no human, using a behavior preset per Class. Choices that involve
## chance use the Match's GameRng so a Match replays exactly from its seed.
##
## Classless preset: heal itself with an Item when HP is low, Defend when HP
## is critical and no Item is left, otherwise attack (usually the weakest
## enemy it can reach).

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
	return _basic_attack(run, combat, id)


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
