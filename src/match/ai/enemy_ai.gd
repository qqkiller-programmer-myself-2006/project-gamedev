class_name EnemyAi
extends RefCounted
## Chooses what an enemy does on its turn, according to its content
## "behavior". All choices that involve chance use the Match's GameRng.
##
##   hunt_weakest      attacks the living character with the least HP
##   charge_strongest  attacks the living character with the most HP
##   random            attacks a random living character
##   healer            heals a hurt ally enemy (below 60% HP), else attacks at random


static func decide(run: MatchRun, combat: CombatEncounter, enemy: Dictionary) -> Dictionary:
	var id: String = enemy["id"]
	var attack: Dictionary = combat.attack_profile(run, id)
	var targets := combat.valid_targets(run, id, attack)
	match str(enemy.get("behavior", "random")):
		"hunt_weakest":
			return _attack(id, attack, _extreme_hp(run, combat, targets, true))
		"charge_strongest":
			return _attack(id, attack, _extreme_hp(run, combat, targets, false))
		"healer":
			var heal := _heal_plan(run, combat, enemy)
			if not heal.is_empty():
				return heal
	return _attack(id, attack, str(run.rng.pick(targets)))


static func _attack(id: String, profile: Dictionary, target: String) -> Dictionary:
	return {"actor": id, "action": "attack", "profile": profile, "targets": [target]}


## The target with the lowest (or highest) current HP; ties go to the
## lowest id so the choice is stable.
static func _extreme_hp(run: MatchRun, combat: CombatEncounter, targets: Array[String], lowest: bool) -> String:
	var best := ""
	var best_hp := 0
	for target in targets:
		var hp: int = combat._unit(run, target)["hp"]
		if best.is_empty() or (lowest and hp < best_hp) or (not lowest and hp > best_hp):
			best = target
			best_hp = hp
	return best


static func _heal_plan(run: MatchRun, combat: CombatEncounter, enemy: Dictionary) -> Dictionary:
	var support: Dictionary = run.content.get_dict("enemies.%s.support" % enemy["kind"])
	if support.is_empty():
		return {}
	var threshold := float(support.get("below_ratio", 0.6))
	var hurt := ""
	var hurt_ratio := threshold
	for other in combat.enemies:
		if other["hp"] <= 0:
			continue
		var ratio := float(other["hp"]) / float(other["max_hp"])
		if ratio < hurt_ratio:
			hurt = other["id"]
			hurt_ratio = ratio
	if hurt.is_empty():
		return {}
	return {"actor": enemy["id"], "action": "skill", "skill": str(support.get("name", "Heal")),
			"profile": support, "targets": [hurt]}
