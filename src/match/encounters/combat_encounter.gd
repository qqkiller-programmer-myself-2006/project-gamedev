class_name CombatEncounter
extends Encounter
## Turn-based combat between the Party and a group of enemies.
##
## Turn order is rebuilt every round from Speed (ties: Party before enemies,
## then lower slot / enemy index). A human-controlled character gets an
## Action window; when it runs out the character Defends automatically.
## AI-controlled characters and enemies act after a short, readable delay.
##
## Every action (Attack, Skill, Item, enemy attacks) is described by an
## "action profile" from content data:
##   {"target": "enemy"|"all_enemies"|"ally"|"other_ally"|"all_allies"|"fallen_ally"|"self",
##    "range": "melee"|"ranged",
##    "damage": {"stat": "atk"|"mag", "power": 1.0, "element": "physical"} or {"amount": 18, ...},
##    "heal": 30, "revive_ratio": 0.4,
##    "status": "protect"|"shield_wall", "multiplier": 0.7}
##
## Statuses last until the user's next turn: "protect" redirects damage
## aimed at the protected ally to the protector (reduced by the multiplier);
## "shield_wall" reduces damage taken by the whole Party.
##
## Skills cost Energy and are limited by cooldowns counted in the
## character's own turns (ADR-0009); Energy and cooldowns reset at the
## start of every Combat. Attack, Defend and Item cost 0 Energy.
## Enemies have no Energy.
##
## Status effects (ADR-0010) live in a StatusBook for this Combat only. A
## profile may add them: "apply_status": [{"status": "bleed", "stacks": 1,
## "turns": 3}], "hits": 3 (repeat damage and statuses per hit), damage
## "pierce": 0.5 (ignore that share of DEF/RES) and "per_dot": 0.35 (extra
## power per DoT kind on the target). DoTs tick at the start of a unit's own
## turn, before Energy regen and before it acts. A Class "passive" of
## {"dot_bonus": 0.05, "dot_bonus_cap": 1.4, "dot_out": 1.15, "dot_in": 1.15}
## is Enervation; a buff status with "coats" makes the holder's next
## damaging actions apply another status (Prep Time).
##
## A trial (the Challenge of a Class Encounter) is non-lethal, gives no
## rewards and ends as "timeout" when its round limit passes.
##
## Command: action {slot, action: attack|defend|item|skill, target, item, skill}

const PARTY_PREFIX := "p"
const ENEMY_PREFIX := "e"

var enemies: Array[Dictionary] = []
var round_number := 0
var order: Array[String] = []
var turn_index := -1
var actor := ""
## End of the current human Action window, or -1.
var deadline := -1.0
## When the current AI-controlled character or enemy acts, or -1.
var act_at := -1.0
## ids that Defended and take reduced damage until their next turn.
var defending: Dictionary = {}
## protected ally id -> {"by": protector id, "multiplier": float}
var protected: Dictionary = {}
## protector id -> damage multiplier for the whole Party (Shield Wall)
var shields: Dictionary = {}
## "" while fighting, then "victory", "defeat" or (trials only) "timeout".
var result := ""
var rewards: Dictionary = {}
var defeated_kinds: Array[String] = []
## pid -> {skill id: own turns left before it can be used again}
var cooldowns: Dictionary = {}
## Party ids that already had at least one turn (for first-turn Energy).
var _had_turn: Dictionary = {}
## Status effects on every unit, for this Combat only.
var status_book: StatusBook = null
## status_applied events waiting to be sent after the action that caused them.
var _status_events: Array[Dictionary] = []
## Trial settings: no deaths, no rewards, limited rounds (0 = unlimited).
var trial := false
var round_limit := 0

var _end_at := -1.0


func _init(route_option: Dictionary, enemy_kinds: Array, trial_rounds: int = 0) -> void:
	super(route_option)
	option["enemy_kinds"] = enemy_kinds.duplicate()
	trial = trial_rounds > 0
	round_limit = trial_rounds


func start(run: MatchRun) -> void:
	var kinds: Array = option["enemy_kinds"]
	status_book = StatusBook.new(run.content)
	for i in kinds.size():
		enemies.append(_make_enemy(run, str(kinds[i]), i))
	_reset_energy(run)
	run.emit({"type": "combat_started", "enemies": _enemy_views()})
	_start_round(run)


func handle(run: MatchRun, slot: int, cmd: Dictionary) -> Dictionary:
	if str(cmd.get("type", "")) != "action":
		return _reject("wrong_phase")
	if not result.is_empty():
		return _reject("wrong_phase")
	var acting := int(cmd.get("slot", slot))
	if acting != slot:
		return _reject("not_your_slot")
	if actor != _pid(slot) or not run.is_human(slot):
		return _reject("not_your_turn")
	if run.clock.now() >= deadline:
		return _reject("action_window_closed")
	var plan := _plan_for(run, slot, cmd)
	if plan.has("error"):
		return _reject(plan["error"])
	_perform(run, plan, false)
	return {"ok": true}


func update(run: MatchRun) -> void:
	var now: float = run.clock.now()
	if not result.is_empty():
		if now >= _end_at:
			done = true
		return
	if actor.is_empty():
		return
	if deadline >= 0.0 and now >= deadline:
		_perform(run, {"actor": actor, "action": "defend"}, true)
	elif act_at >= 0.0 and now >= act_at:
		_act_automatically(run)


func on_control_changed(run: MatchRun, slot: int) -> void:
	if actor == _pid(slot) and result.is_empty() and not run.is_human(slot):
		deadline = -1.0
		act_at = run.clock.now() + run.content.get_float("rules.ai_turn_seconds", 0.8)


func view(run: MatchRun, viewer_slot: int) -> Dictionary:
	var your_turn := viewer_slot >= 0 and actor == _pid(viewer_slot) and run.is_human(viewer_slot) \
			and result.is_empty()
	var defending_ids: Array = defending.keys()
	defending_ids.sort()
	var protected_view := {}
	for ally in protected:
		protected_view[ally] = protected[ally]["by"]
	var out := {
		"kind": "combat",
		"trial": trial,
		"round_limit": round_limit,
		"round": round_number,
		"enemies": _enemy_views(),
		"turn_order": order.slice(maxi(turn_index, 0)),
		"round_order": order.duplicate(),
		"actor": actor,
		"actor_controller": _controller_of(run, actor),
		"deadline": deadline if deadline >= 0.0 else null,
		"your_turn": your_turn,
		"defending": defending_ids,
		"protected": protected_view,
		"shielded": not shields.is_empty(),
		"statuses": status_book.view_all() if status_book != null else {},
		"result": result,
		"rewards": rewards,
	}
	if your_turn:
		out["choices"] = _choices_for(run, viewer_slot)
	return out


# --- Rounds and turns -------------------------------------------------------

func _start_round(run: MatchRun) -> void:
	if trial and round_number >= round_limit:
		_finish(run, "timeout")
		return
	round_number += 1
	var ids: Array[String] = []
	for i in run.party.size():
		if run.party[i]["hp"] > 0:
			ids.append(_pid(i))
	for enemy in enemies:
		if enemy["hp"] > 0:
			ids.append(enemy["id"])
	ids.sort_custom(func(a: String, b: String) -> bool: return _before(run, a, b))
	order = ids
	turn_index = -1
	run.emit({"type": "round_started", "round": round_number, "order": order.duplicate()})
	_next_turn(run)


## True when `a` acts before `b`: higher Speed first, then Party before
## enemies, then lower slot / enemy index.
func _before(run: MatchRun, a: String, b: String) -> bool:
	var sa: int = _unit(run, a)["spd"]
	var sb: int = _unit(run, b)["spd"]
	if sa != sb:
		return sa > sb
	if a[0] != b[0]:
		return a[0] == PARTY_PREFIX
	return int(a.substr(1)) < int(b.substr(1))


func _next_turn(run: MatchRun) -> void:
	while true:
		turn_index += 1
		if turn_index >= order.size():
			_start_round(run)
			return
		var id := order[turn_index]
		if _unit(run, id)["hp"] > 0:
			_begin_turn(run, id)
			return


func _begin_turn(run: MatchRun, id: String) -> void:
	# DoTs tick before Energy regen and before the unit acts (ADR-0010).
	if not _tick_statuses(run, id):
		return
	actor = id
	defending.erase(id)
	shields.erase(id)
	for ally in protected.keys():
		if protected[ally]["by"] == id:
			protected.erase(ally)
	if cooldowns.has(id):
		for skill in cooldowns[id]:
			cooldowns[id][skill] = maxi(0, int(cooldowns[id][skill]) - 1)
	# Energy starts at energy_start for the whole Party, so each character's
	# first turn in a Combat grants no regen yet; every later own turn
	# (including ones that time out into an automatic Defend) regains
	# energy_regen up to energy_max.
	if id.begins_with(PARTY_PREFIX):
		if _had_turn.has(id):
			var character := _unit(run, id)
			character["energy"] = mini(int(character.get("energy_max",
					run.content.get_int("rules.energy_max", 6))), int(character.get("energy",
					run.content.get_int("rules.energy_start", 1))) + run.content.get_int("rules.energy_regen", 1))
		else:
			_had_turn[id] = true
	deadline = -1.0
	act_at = -1.0
	var now: float = run.clock.now()
	var controller := _controller_of(run, id)
	if controller == "human":
		deadline = now + run.content.get_float("rules.action_window_seconds", 15.0)
	elif controller == "ai":
		act_at = now + run.content.get_float("rules.ai_turn_seconds", 0.8)
	else:
		act_at = now + run.content.get_float("rules.enemy_turn_seconds", 0.9)
	run.emit({
		"type": "turn_started",
		"round": round_number,
		"actor": id,
		"controller": controller,
		"deadline": deadline if deadline >= 0.0 else null,
	})


## DoT damage and status countdown at the start of `id`'s turn. Returns
## false when the unit fell (the Combat has already moved on or ended).
func _tick_statuses(run: MatchRun, id: String) -> bool:
	var unit := _unit(run, id)
	var outcome := status_book.start_turn(id, float(_passive(run, id).get("dot_in", 1.0)))
	for tick in outcome["ticks"]:
		var floor_hp := 1 if trial and id.begins_with(PARTY_PREFIX) else 0
		unit["hp"] = maxi(mini(floor_hp, unit["hp"]), unit["hp"] - int(tick["damage"]))
		var down: bool = unit["hp"] <= 0
		run.emit({"type": "status_tick", "round": round_number, "target": id, "status": tick["status"],
				"name": tick["name"], "damage": tick["damage"], "hp": unit["hp"], "down": down})
		if down:
			if id.begins_with(ENEMY_PREFIX):
				defeated_kinds.append(str(unit["kind"]))
			status_book.clear_unit(id)
			break
	if unit["hp"] > 0:
		for status in outcome["expired"]:
			run.emit({"type": "status_expired", "target": id, "status": status})
		return true
	_after_action(run)
	return false


## Class passive of a Party character (e.g. Enervation), or {}.
func _passive(run: MatchRun, id: String) -> Dictionary:
	if not id.begins_with(PARTY_PREFIX):
		return {}
	return run.content.get_dict("classes.%s.passive" % _unit(run, id)["class"])


## Adds a status from `source` to `target` and queues its event.
func _add_status(run: MatchRun, source: String, target: String, spec: Dictionary) -> Dictionary:
	var status := str(spec.get("status", ""))
	var power := float(_passive(run, source).get("dot_out", 1.0))
	var view := status_book.apply(target, status, int(spec.get("stacks", 1)), int(spec.get("turns", 0)), power)
	var event := {"type": "status_applied", "target": target, "source": source}
	event.merge(view)
	_status_events.append(event)
	return {"status": status, "stacks": view["stacks"], "turns": view["turns"]}


func _act_automatically(run: MatchRun) -> void:
	if actor.begins_with(ENEMY_PREFIX):
		_perform(run, _enemy_plan(run, _unit(run, actor)), false)
	else:
		_perform(run, PartyAi.decide(run, self, int(actor.substr(1))), false)


# --- Planning and validating actions ----------------------------------------

## Turns a player command into a validated plan, or {"error": code}.
func _plan_for(run: MatchRun, slot: int, cmd: Dictionary) -> Dictionary:
	var me := _pid(slot)
	var action := str(cmd.get("action", ""))
	match action:
		"defend":
			return {"actor": me, "action": "defend"}
		"attack":
			var profile := attack_profile(run, me)
			var target := str(cmd.get("target", ""))
			if not valid_targets(run, me, profile).has(target):
				return {"error": "invalid_target"}
			return {"actor": me, "action": "attack", "profile": profile, "targets": [target]}
		"item":
			var item := str(cmd.get("item", ""))
			if int(run.inventory.get(item, 0)) <= 0:
				return {"error": "item_unavailable"}
			var profile: Dictionary = run.content.get_dict("items.%s.use" % item)
			var targets := _targets_for_command(run, me, profile, str(cmd.get("target", "")))
			if targets.is_empty():
				return {"error": "invalid_target"}
			return {"actor": me, "action": "item", "item": item, "profile": profile, "targets": targets}
		"skill":
			var skill := str(cmd.get("skill", ""))
			if not class_skills(run, me).has(skill):
				return {"error": "skill_unavailable"}
			if _energy_of(run, me) < skill_energy(run, skill):
				return {"error": "not_enough_energy"}
			if skill_cooldown(me, skill) > 0:
				return {"error": "skill_on_cooldown"}
			var profile := skill_profile(run, skill)
			var targets := _targets_for_command(run, me, profile, str(cmd.get("target", "")))
			if targets.is_empty():
				return {"error": "invalid_target"}
			return {"actor": me, "action": "skill", "skill": skill, "profile": profile, "targets": targets}
	return {"error": "invalid_action"}


## Skill ids the character's Class grants (none for Classless).
func class_skills(run: MatchRun, id: String) -> Array:
	if not id.begins_with(PARTY_PREFIX):
		return []
	return run.content.get_array("classes.%s.skills" % _unit(run, id)["class"])


func skill_profile(run: MatchRun, skill: String) -> Dictionary:
	return run.content.get_dict("skills.%s.use" % skill)


## Own turns left before `skill` can be used again by `id` (0 = ready).
func skill_cooldown(id: String, skill: String) -> int:
	return int(cooldowns.get(id, {}).get(skill, 0))


## Energy `skill` costs (Attack, Defend and Item use 0).
func skill_energy(run: MatchRun, skill: String) -> int:
	return run.content.get_int("skills.%s.energy" % skill, 0)


## Current Energy of a Party character (enemies have none: 0).
func _energy_of(run: MatchRun, id: String) -> int:
	if not id.begins_with(PARTY_PREFIX):
		return 0
	return int(_unit(run, id).get("energy", run.content.get_int("rules.energy_start", 1)))


## True when `id` can afford `skill` right now (cooldown ignored).
func can_afford(run: MatchRun, id: String, skill: String) -> bool:
	if not id.begins_with(PARTY_PREFIX):
		return false
	return _energy_of(run, id) >= skill_energy(run, skill)


## Every Party character starts the Combat (or Challenge) at
## energy_start, capped by energy_max.
func _reset_energy(run: MatchRun) -> void:
	for character in run.party:
		character["energy"] = run.content.get_int("rules.energy_start", 1)
		character["energy_max"] = run.content.get_int("rules.energy_max", 6)


## Targets an action with `profile` would hit when the player picked
## `picked`; empty when that choice is not allowed.
func _targets_for_command(run: MatchRun, me: String, profile: Dictionary, picked: String) -> Array:
	var allowed := valid_targets(run, me, profile)
	if str(profile.get("target", "")) in ["all_enemies", "all_allies"]:
		return allowed
	if allowed.has(picked):
		return [picked]
	return []


## The Attack profile of a party member or enemy.
func attack_profile(run: MatchRun, id: String) -> Dictionary:
	if id.begins_with(ENEMY_PREFIX):
		return _unit(run, id).get("attack", {})
	var character: Dictionary = _unit(run, id)
	return run.content.get_dict("classes.%s.attack" % character["class"])


## ids a unit may target with `profile`.
func valid_targets(run: MatchRun, id: String, profile: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var on_enemy_side := id.begins_with(ENEMY_PREFIX)
	match str(profile.get("target", "enemy")):
		"enemy", "all_enemies":
			if on_enemy_side:
				for i in run.party.size():
					if run.party[i]["hp"] > 0:
						out.append(_pid(i))
			else:
				var melee := str(profile.get("range", "ranged")) == "melee"
				var front_alive := false
				for enemy in enemies:
					if enemy["hp"] > 0 and enemy["row"] == "front":
						front_alive = true
				for enemy in enemies:
					if enemy["hp"] <= 0:
						continue
					if melee and front_alive and enemy["row"] != "front":
						continue
					out.append(enemy["id"])
		"other_ally":
			if not on_enemy_side:
				for i in run.party.size():
					if run.party[i]["hp"] > 0 and _pid(i) != id:
						out.append(_pid(i))
		"ally", "all_allies":
			if on_enemy_side:
				for enemy in enemies:
					if enemy["hp"] > 0:
						out.append(enemy["id"])
			else:
				for i in run.party.size():
					if run.party[i]["hp"] > 0:
						out.append(_pid(i))
		"fallen_ally":
			if not on_enemy_side:
				for i in run.party.size():
					if run.party[i]["hp"] <= 0:
						out.append(_pid(i))
		"self":
			out.append(id)
	return out


## What the human whose turn it is may do right now (for the client UI).
func _choices_for(run: MatchRun, slot: int) -> Dictionary:
	var me := _pid(slot)
	var items := {}
	for item in run.inventory:
		if int(run.inventory[item]) <= 0:
			continue
		var profile: Dictionary = run.content.get_dict("items.%s.use" % item)
		items[item] = {
			"count": run.inventory[item],
			"target": str(profile.get("target", "")),
			"targets": valid_targets(run, me, profile),
		}
	var skills := {}
	for skill in class_skills(run, me):
		var profile := skill_profile(run, skill)
		var ready := skill_cooldown(me, skill) == 0 and can_afford(run, me, skill)
		skills[skill] = {
			"name": run.content.get_value("skills.%s.name" % skill, skill),
			"description": str(run.content.get_value("skills.%s.description" % skill, "")),
			"cooldown": skill_cooldown(me, skill),
			"energy": skill_energy(run, skill),
			"affordable": can_afford(run, me, skill),
			"target": str(profile.get("target", "")),
			"targets": valid_targets(run, me, profile) if ready else [],
		}
	return {
		"attack": {"targets": valid_targets(run, me, attack_profile(run, me))},
		"defend": true,
		"items": items,
		"skills": skills,
	}


# --- Resolving actions ------------------------------------------------------

## Applies a validated plan: {"actor", "action", "profile", "targets", ...}.
func _perform(run: MatchRun, plan: Dictionary, automatic: bool) -> void:
	var id: String = plan["actor"]
	var event := {
		"type": "action_resolved",
		"round": round_number,
		"actor": id,
		"action": plan["action"],
		"automatic": automatic,
		"results": [],
	}
	match plan["action"]:
		"defend":
			defending[id] = true
		"charge":
			event["move"] = plan["move"]
			event["move_name"] = plan.get("move_name", plan["move"])
		"attack", "skill", "item":
			if plan.has("item"):
				event["item"] = plan["item"]
				run.inventory[plan["item"]] = int(run.inventory[plan["item"]]) - 1
				if int(run.inventory[plan["item"]]) <= 0:
					run.inventory.erase(plan["item"])
			if plan.has("move"):
				event["move"] = plan["move"]
				event["move_name"] = plan.get("move_name", plan["move"])
			if plan.has("skill"):
				event["skill"] = plan["skill"]
				if id.begins_with(PARTY_PREFIX):
					var cost := skill_energy(run, plan["skill"])
					event["energy_spent"] = cost
					var character := _unit(run, id)
					character["energy"] = maxi(0, int(character.get("energy", cost)) - cost)
					event["energy"] = character["energy"]
					var cooldown := run.content.get_int("skills.%s.cooldown" % plan["skill"])
					if not cooldowns.has(id):
						cooldowns[id] = {}
					cooldowns[id][plan["skill"]] = cooldown + 1 if cooldown > 0 else 0
			event["results"] = _apply_profile(run, id, plan["profile"], plan["targets"])
			if plan["action"] != "item":
				_apply_coating(run, id, event["results"])
	run.emit(event)
	for status_event in _status_events:
		run.emit(status_event)
	_status_events.clear()
	_after_action(run)


func _apply_profile(run: MatchRun, source: String, profile: Dictionary, targets: Array) -> Array:
	var results: Array = []
	var statuses: Array = profile.get("apply_status", [])
	var per_hit := bool(profile.get("status_per_hit", false))
	for target in targets:
		var unit := _unit(run, target)
		var entry := {"target": target}
		if profile.has("damage"):
			var guard := _protector_of(run, target)
			var multiplier := 1.0
			if not guard.is_empty():
				entry = {"target": guard, "protected": target}
				multiplier = float(protected[target]["multiplier"])
			var struck := _unit(run, entry["target"])
			var hits := maxi(1, int(profile.get("hits", 1)))
			for n in hits:
				var hit := _hit(run, source, struck, profile["damage"], multiplier)
				if n == 0:
					entry.merge(hit)
				else:
					entry["damage"] = int(entry["damage"]) + int(hit["damage"])
					entry["crit"] = bool(entry["crit"]) or bool(hit["crit"])
					if hit.has("down"):
						entry["down"] = true
				if hits > 1:
					var each: Array = entry.get("hits", [])
					each.append(hit["damage"])
					entry["hits"] = each
				if per_hit and struck["hp"] > 0:
					for spec in statuses:
						entry["applied"] = entry.get("applied", []) + [_add_status(run, source, entry["target"], spec)]
				if struck["hp"] <= 0:
					break
		if profile.has("heal") and unit["hp"] > 0:
			var before: int = unit["hp"]
			unit["hp"] = mini(unit["max_hp"], unit["hp"] + int(profile["heal"]))
			entry["heal"] = unit["hp"] - before
		if profile.has("revive_ratio") and unit["hp"] <= 0:
			unit["hp"] = maxi(1, int(round(unit["max_hp"] * float(profile["revive_ratio"]))))
			entry["revived"] = true
		match str(profile.get("status", "")):
			"protect":
				protected[target] = {"by": source, "multiplier": float(profile.get("multiplier", 1.0))}
				entry["status"] = "protected"
			"shield_wall":
				shields[source] = float(profile.get("multiplier", 1.0))
				entry["status"] = "shielded"
		if not entry.has("target"):
			entry["target"] = target
		if not per_hit and _unit(run, entry["target"])["hp"] > 0:
			for spec in statuses:
				entry["applied"] = entry.get("applied", []) + [_add_status(run, source, entry["target"], spec)]
		entry["hp"] = _unit(run, entry["target"])["hp"]
		results.append(entry)
	return results


## A coated weapon (a buff status with "coats", e.g. Prep Time) adds its
## status to every foe the holder's action damaged, using one charge.
func _apply_coating(run: MatchRun, source: String, results: Array) -> void:
	for held in status_book.view(source):
		var coats := run.content.get_dict("statuses.%s.coats" % held["status"])
		if coats.is_empty():
			continue
		var landed := false
		for entry in results:
			var target := str(entry["target"])
			if entry.has("damage") and target[0] != source[0] and _unit(run, target)["hp"] > 0:
				entry["applied"] = entry.get("applied", []) + [_add_status(run, source, target, coats)]
				landed = true
		if not landed:
			continue
		status_book.spend_charge(source, held["status"])
		if not status_book.has(source, held["status"]):
			_status_events.append({"type": "status_expired", "target": source, "status": held["status"]})


## Computes and applies one damage instance. Returns what happened.
func _hit(run: MatchRun, source: String, target: Dictionary, damage: Dictionary, multiplier: float = 1.0) -> Dictionary:
	var rules := run.content
	var attacker := _unit(run, source)
	var element := str(damage.get("element", "physical"))
	var target_id := _id_of(target)
	var dots := status_book.distinct_dots(target_id)
	var amount := 0.0
	if damage.has("amount"):
		amount = float(damage["amount"])
	else:
		var stat := str(damage.get("stat", "atk"))
		var guard_stat := "def" if stat == "atk" else "res"
		var power := float(damage.get("power", 1.0)) + float(damage.get("per_dot", 0.0)) * dots
		var pierce := clampf(float(damage.get("pierce", 0.0)), 0.0, 1.0)
		amount = float(attacker[stat]) * power \
				- float(target[guard_stat]) * rules.get_float("rules.defense_factor", 0.5) * (1.0 - pierce)
		amount = maxf(1.0, amount)
		var variance := rules.get_float("rules.damage_variance", 0.1)
		amount *= run.rng.randf_range(1.0 - variance, 1.0 + variance)
	var crit := false
	if not damage.has("amount"):
		crit = bool(damage.get("always_crit", false)) or run.rng.chance(float(attacker.get("crit", 0.0)))
	if crit:
		amount *= rules.get_float("rules.crit_multiplier", 1.5)
	var weak: bool = target.get("weakness", []).has(element)
	if weak:
		amount *= rules.get_float("rules.weakness_multiplier", 1.5)
	var passive := _passive(run, source)
	if passive.has("dot_bonus"):
		amount *= minf(float(passive.get("dot_bonus_cap", 1.4)), 1.0 + float(passive["dot_bonus"]) * dots)
	if defending.has(target_id):
		amount *= rules.get_float("rules.defend_multiplier", 0.5)
	if target_id.begins_with(PARTY_PREFIX):
		for shield in shields.values():
			amount *= float(shield)
	amount *= multiplier
	var dealt := maxi(1, int(round(amount)))
	var floor_hp := 1 if trial and target_id.begins_with(PARTY_PREFIX) else 0
	target["hp"] = maxi(mini(floor_hp, target["hp"]), target["hp"] - dealt)
	var out := {"damage": dealt, "crit": crit, "weak": weak, "element": element}
	if target["hp"] <= 0:
		out["down"] = true
		if target_id.begins_with(ENEMY_PREFIX):
			defeated_kinds.append(str(target["kind"]))
	return out


## True when the Party should brace: less than half of its total HP is
## left (fallen characters count as empty).
func party_in_danger(run: MatchRun) -> bool:
	var hp := 0
	var max_hp := 0
	for character in run.party:
		hp += int(character["hp"])
		max_hp += int(character["max_hp"])
	return max_hp > 0 and hp * 2 < max_hp


## The living ally protecting `target` from harm, or "".
func _protector_of(run: MatchRun, target: String) -> String:
	if not protected.has(target):
		return ""
	var guard: String = protected[target]["by"]
	if _unit(run, guard)["hp"] <= 0:
		return ""
	return guard


## What an enemy does on its turn. Subclasses (the Guardian Boss) override.
func _enemy_plan(run: MatchRun, enemy: Dictionary) -> Dictionary:
	return EnemyAi.decide(run, self, enemy)


## Called after every action, before checking for the end of the fight.
func _on_action_resolved(_run: MatchRun) -> void:
	pass


## A dangerous attack an enemy has announced and will unleash on its next
## turn: {"move", "name", "target": pid or "all"}, or {} when none.
func pending_threat() -> Dictionary:
	return {}


func _after_action(run: MatchRun) -> void:
	_on_action_resolved(run)
	if _all_down(enemies):
		_finish(run, "victory")
	elif _all_down(run.party):
		_finish(run, "defeat")
	else:
		_next_turn(run)


func _finish(run: MatchRun, outcome: String) -> void:
	result = outcome
	status_book.clear()
	actor = ""
	deadline = -1.0
	act_at = -1.0
	if outcome == "victory" and not trial:
		rewards = _grant_rewards(run)
	run.emit({"type": "combat_ended", "result": outcome, "rewards": rewards})
	_end_at = run.clock.now() + run.content.get_float("rules.combat_end_seconds", 3.0)


func _grant_rewards(run: MatchRun) -> Dictionary:
	var exp := 0
	var gold := 0
	var items := {}
	for enemy in enemies:
		var reward: Dictionary = enemy.get("rewards", {})
		exp += int(reward.get("exp", 0))
		gold += int(reward.get("gold", 0))
		for drop in reward.get("drops", []):
			if run.rng.chance(float(drop.get("chance", 0.0))):
				var item := str(drop["item"])
				items[item] = int(items.get(item, 0)) + 1
	run.add_gold(gold)
	for item in items:
		run.add_item(item, items[item])
	var clue := _roll_clue(run)
	var ratio := run.content.get_float("rules.revive_hp_ratio", 0.3)
	for character in run.party:
		if character["hp"] <= 0:
			character["hp"] = maxi(1, int(round(character["max_hp"] * ratio)))
	for character in run.party:
		run.grant_exp(character["slot"], exp)
	var granted := {"exp": exp, "gold": gold, "items": items}
	if not clue.is_empty():
		granted["clue"] = run.clue_view(clue)
	return granted


## Sometimes a won fight turns up a Story Clue nobody has found yet.
func _roll_clue(run: MatchRun) -> String:
	var unfound: Array = []
	for id in run.content.get_array("story.combat_clues.pool"):
		if not run.has_clue(str(id)):
			unfound.append(str(id))
	if unfound.is_empty() or not run.rng.chance(run.content.get_float("story.combat_clues.chance", 0.0)):
		return ""
	var id: String = run.rng.pick(unfound)
	run.add_clue(id, "combat")
	return id


# --- Helpers ----------------------------------------------------------------

func _make_enemy(run: MatchRun, kind: String, index: int) -> Dictionary:
	var data := run.content.get_dict("enemies.%s" % kind)
	var stats: Dictionary = data.get("stats", {})
	var enemy := {
		"id": "%s%d" % [ENEMY_PREFIX, index],
		"kind": kind,
		"name": str(data.get("name", kind.capitalize())),
		"row": str(data.get("row", "front")),
		"behavior": str(data.get("behavior", "random")),
		"description": str(data.get("description", "")),
		"attack": data.get("attack", {"target": "enemy", "damage": {"stat": "atk", "power": 1.0}}),
		"weakness": data.get("weakness", []),
		"rewards": data.get("rewards", {}),
	}
	for stat in ["max_hp", "atk", "def", "mag", "res", "spd"]:
		enemy[stat] = int(stats.get(stat, 0))
	enemy["crit"] = float(stats.get("crit", 0.0))
	enemy["hp"] = enemy["max_hp"]
	return enemy


func _enemy_views() -> Array:
	var out: Array = []
	for enemy in enemies:
		out.append({
			"id": enemy["id"],
			"kind": enemy["kind"],
			"name": enemy["name"],
			"hp": enemy["hp"],
			"max_hp": enemy["max_hp"],
			"spd": enemy["spd"],
			"row": enemy["row"],
			"weakness": enemy["weakness"],
			"description": enemy["description"],
			"statuses": status_book.view(enemy["id"]) if status_book != null else [],
		})
	return out


func _unit(run: MatchRun, id: String) -> Dictionary:
	if id.begins_with(PARTY_PREFIX):
		return run.party[int(id.substr(1))]
	return enemies[int(id.substr(1))]


func _id_of(unit: Dictionary) -> String:
	if unit.has("slot"):
		return _pid(unit["slot"])
	return unit["id"]


func _controller_of(run: MatchRun, id: String) -> String:
	if id.is_empty():
		return ""
	if id.begins_with(ENEMY_PREFIX):
		return "enemy"
	return "human" if run.is_human(int(id.substr(1))) else "ai"


static func _pid(slot: int) -> String:
	return "%s%d" % [PARTY_PREFIX, slot]


static func _all_down(units: Array) -> bool:
	for unit in units:
		if unit["hp"] > 0:
			return false
	return true


static func _reject(error: String) -> Dictionary:
	return {"ok": false, "error": error}
