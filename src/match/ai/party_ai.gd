class_name PartyAi
extends RefCounted
## AI replacement: decides combat actions for Party characters whose slot
## has no human, using a behavior preset per Class. Choices that involve
## chance use the Match's GameRng so a Match replays exactly from its seed.
##
## Every preset first looks after itself: heal with an Item when HP is low,
## Defend when HP is critical and no Item is left. When an enemy has
## telegraphed a dangerous move, Guardians Shield Wall (Party-wide threat) or
## Protect the target, the targeted character Defends, and anyone at or
## below half HP braces for a Party-wide blow. Then:
##   classless  attack (usually the weakest enemy it can reach)
##   swordsman  Power Slash the toughest enemy in reach whenever it is ready,
##              otherwise attack like Classless
##   archer     always picks off the weakest enemy, with Aimed Shot when ready
##   mage       Fireball when two or more enemies stand and it is ready, else
##              Frost Lance or a magic attack on the weakest enemy
##   guardian   Protect the ally with the lowest HP share below 60% that
##              nobody protects yet; Shield Wall when the Party is in danger;
##              otherwise Defend
##   assassin      focus the reachable enemy with the most DoT kinds (ties: the
##              weakest); Prep Time when the weapon is not coated; Inject
##              Venom once the focus carries 2+ DoT kinds; otherwise Poke Up,
##              then Stab, then attack the focus
##   healer        heal the most injured ally (or the Party when two or more
##              allies are hurt), cleanse harmful effects, otherwise Strike
##   support       Rally an ally, Energize a teammate who lacks Energy for a
##              ready expensive Skill, Weaken the most dangerous enemy, then Strike

const LOW_HP := 0.35
const CRITICAL_HP := 0.2
const FOCUS_WEAKEST_CHANCE := 0.7
const NEEDS_PROTECTION := 0.6


static func decide(run: MatchRun, combat: CombatEncounter, slot: int) -> Dictionary:
	var me: Dictionary = run.party[slot]
	var id := CombatEncounter._pid(slot)
	var ratio := float(me["hp"]) / float(me["max_hp"])
	if ratio < LOW_HP:
		var item := _healing_item(run, me) if not combat.trial else ""
		if not item.is_empty():
			return {"actor": id, "action": "item", "item": item,
					"profile": run.content.get_dict("items.%s.use" % item), "targets": [id]}
		if ratio < CRITICAL_HP:
			return {"actor": id, "action": "defend"}
	var preset := str(run.content.get_value("classes.%s.ai" % me["class"], "classless"))
	var threat := combat.pending_threat()
	if not threat.is_empty():
		var reaction := _react_to_threat(run, combat, id, preset, threat, ratio)
		if not reaction.is_empty():
			return reaction

	# Support and Healer have useful non-damaging decisions even when they
	# cannot yet afford a Skill. Let their role preset choose a basic Strike in
	# that case instead of short-circuiting into Focus.
	if preset not in ["support", "healer"]:
		var cheapest := -1
		for skill in combat.class_skills(run, id):
			var cost = combat.skill_energy(run, skill)
			if cheapest == -1 or cost < cheapest:
				cheapest = cost
		if cheapest > 0 and int(me.get("energy", run.content.get_int("rules.energy_start", 1))) < cheapest:
			return {"actor": id, "action": "focus"}

	match preset:
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
		"guardian":
			return _guard(run, combat, id)
		"assassin":
			return _assassin(run, combat, id)
		"healer":
			return _healer(run, combat, id)
		"support":
			return _support(run, combat, id)
	return _basic_attack(run, combat, id)


static func _healer(run: MatchRun, combat: CombatEncounter, id: String) -> Dictionary:
	var hurt: Array[String] = []
	var lowest := ""
	var lowest_ratio := 0.6
	for slot in run.party.size():
		var ally: Dictionary = run.party[slot]
		if int(ally["hp"]) <= 0:
			continue
		var ratio := float(ally["hp"]) / float(ally["max_hp"])
		if ratio < 0.6:
			hurt.append(_party_id(slot))
			if lowest.is_empty() or ratio < lowest_ratio:
				lowest = _party_id(slot)
				lowest_ratio = ratio
	if hurt.size() >= 2:
		var wave := _ready_skill(run, combat, id, "renewing_wave")
		if not wave.is_empty():
			return {"actor": id, "action": "skill", "skill": "renewing_wave",
					"profile": combat.skill_profile(run, "renewing_wave"), "targets": wave}
	if not lowest.is_empty():
		var mend := _ready_skill(run, combat, id, "mending_light")
		if mend.has(lowest):
			return _skill_on(run, combat, id, "mending_light", lowest)
	var afflicted := _most_harmfully_afflicted(run, combat)
	if not afflicted.is_empty() and _ready_skill(run, combat, id, "cleanse").has(afflicted):
		return _skill_on(run, combat, id, "cleanse", afflicted)
	return _attack_weakest(run, combat, id)


static func _support(run: MatchRun, combat: CombatEncounter, id: String) -> Dictionary:
	var rally := _ready_skill(run, combat, id, "rally")
	for ally_id in rally:
		if ally_id != id and not combat.status_book.has(ally_id, "rally"):
			return _skill_on(run, combat, id, "rally", ally_id)
	var energy_target := _ally_needing_energy(run, combat, id)
	if not energy_target.is_empty() and _ready_skill(run, combat, id, "energize").has(energy_target):
		return _skill_on(run, combat, id, "energize", energy_target)
	var dangerous := _most_dangerous_enemy(run, combat, id)
	if not dangerous.is_empty() and not combat.status_book.has(dangerous, "weakened") \
			and _ready_skill(run, combat, id, "weaken").has(dangerous):
		return _skill_on(run, combat, id, "weaken", dangerous)
	return _attack_weakest(run, combat, id)


static func _most_harmfully_afflicted(run: MatchRun, combat: CombatEncounter) -> String:
	var best := ""
	var best_score := 0
	for slot in run.party.size():
		var id := _party_id(slot)
		if int(run.party[slot]["hp"]) <= 0:
			continue
		var score := 0
		for status in combat.status_book.view(id):
			var kind := str(run.content.get_value("statuses.%s.kind" % status["status"], "dot"))
			var negative := bool(run.content.get_value("statuses.%s.negative" % status["status"], kind == "dot"))
			if negative:
				score += 2 if kind == "dot" else 1
		if score > best_score:
			best = id
			best_score = score
	return best


static func _ally_needing_energy(run: MatchRun, combat: CombatEncounter, id: String) -> String:
	var best := ""
	var best_need := 0
	for slot in run.party.size():
		var ally_id := _party_id(slot)
		if ally_id == id or int(run.party[slot]["hp"]) <= 0:
			continue
		var ally: Dictionary = run.party[slot]
		var energy := int(ally.get("energy", 0))
		var need := 0
		for skill in combat.class_skills(run, ally_id):
			var cost := combat.skill_energy(run, skill)
			if cost < 2 or cost <= energy or combat.skill_cooldown(ally_id, skill) > 0:
				continue
			need = maxi(need, cost - energy)
		if need > best_need:
			best = ally_id
			best_need = need
	return best


static func _most_dangerous_enemy(run: MatchRun, combat: CombatEncounter, id: String) -> String:
	var candidates := combat.valid_targets(run, id, combat.skill_profile(run, "weaken"))
	var best := ""
	var best_power := -1
	for enemy_id in candidates:
		var enemy: Dictionary = combat._unit(run, enemy_id)
		var power := int(enemy.get("atk", 0)) + int(enemy.get("mag", 0))
		if power > best_power:
			best = enemy_id
			best_power = power
	return best


static func _party_id(slot: int) -> String:
	return CombatEncounter._pid(slot)


static func _assassin(run: MatchRun, combat: CombatEncounter, id: String) -> Dictionary:
	var reach := combat.valid_targets(run, id, combat.attack_profile(run, id))
	var focus := ""
	var focus_dots := -1
	var focus_hp := 0
	for target in reach:
		var dots := combat.status_book.distinct_dots(target)
		var hp: int = combat._unit(run, target)["hp"]
		if dots > focus_dots or (dots == focus_dots and hp < focus_hp):
			focus = target
			focus_dots = dots
			focus_hp = hp
	if not combat.status_book.has(id, "venom_coat") and not _ready_skill(run, combat, id, "prep_time").is_empty():
		return _skill_on(run, combat, id, "prep_time", id)
	if focus_dots >= 2 and _ready_skill(run, combat, id, "inject_venom").has(focus):
		return _skill_on(run, combat, id, "inject_venom", focus)
	for skill in ["poke_up", "stab"]:
		if _ready_skill(run, combat, id, skill).has(focus):
			return _skill_on(run, combat, id, skill, focus)
	return {"actor": id, "action": "attack", "profile": combat.attack_profile(run, id), "targets": [focus]}


static func _react_to_threat(run: MatchRun, combat: CombatEncounter, id: String, preset: String,
		threat: Dictionary, ratio: float) -> Dictionary:
	var target := str(threat.get("target", ""))
	if preset == "guardian":
		if target == "all" and not _ready_skill(run, combat, id, "shield_wall").is_empty():
			return _skill_on(run, combat, id, "shield_wall", id)
		if target != "all" and target != id and _ready_skill(run, combat, id, "protect").has(target) \
				and not combat.protected.has(target):
			return _skill_on(run, combat, id, "protect", target)
	if target == id or (target == "all" and ratio <= 0.5):
		return {"actor": id, "action": "defend"}
	return {}


static func _guard(run: MatchRun, combat: CombatEncounter, id: String) -> Dictionary:
	if combat.party_in_danger(run) and not _ready_skill(run, combat, id, "shield_wall").is_empty():
		return _skill_on(run, combat, id, "shield_wall", id)
	var candidates := _ready_skill(run, combat, id, "protect")
	var ward := ""
	var ward_ratio := NEEDS_PROTECTION
	for ally in candidates:
		if combat.protected.has(ally):
			continue
		var unit: Dictionary = combat._unit(run, ally)
		var ratio := float(unit["hp"]) / float(unit["max_hp"])
		if ratio < ward_ratio:
			ward = ally
			ward_ratio = ratio
	if not ward.is_empty():
		return _skill_on(run, combat, id, "protect", ward)
	return {"actor": id, "action": "defend"}


static func _attack_weakest(run: MatchRun, combat: CombatEncounter, id: String) -> Dictionary:
	var profile := combat.attack_profile(run, id)
	return {"actor": id, "action": "attack", "profile": profile,
			"targets": [weakest(run, combat, combat.valid_targets(run, id, profile))]}


## Targets for `skill` if `id` has it ready and can afford it, else empty.
static func _ready_skill(run: MatchRun, combat: CombatEncounter, id: String, skill: String) -> Array[String]:
	if not combat.class_skills(run, id).has(skill) or combat.skill_cooldown(id, skill) > 0:
		return []
	if not combat.can_afford(run, id, skill):
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

## Returns the ID of the best healing item available in the Stash or the character's Consumable slot, or "" if none.
static func _healing_item(run: MatchRun, me: Dictionary) -> String:
	var best := ""
	var best_heal := 0
	var stash := run.inventory.duplicate()
	if me.get("consumable") != null:
		var slot_item = str(me["consumable"]["item"])
		var slot_count = int(me["consumable"]["count"])
		if slot_count > 0:
			stash[slot_item] = int(stash.get(slot_item, 0)) + slot_count

	for item in stash:
		if int(stash[item]) <= 0:
			continue
		var use := run.content.get_dict("items.%s.use" % item)
		if str(use.get("target", "")) != "ally" or not use.has("heal"):
			continue
		var heal := int(use["heal"])
		if best.is_empty() or heal < best_heal:
			best = item
			best_heal = heal
	return best
