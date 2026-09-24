class_name BossEncounter
extends CombatEncounter
## The Guardian Boss that ends the Forest: a Combat whose boss follows a
## move pattern per phase (content "boss"), changes phase at HP thresholds,
## and telegraphs its dangerous moves one turn ahead so the Party can Defend,
## Protect or raise Shield Wall before the blow lands.

const BOSS_ID := "e0"

var phase_index := 0
var pattern_step := 0
## The telegraphed move waiting for the boss's next turn, or {}.
var pending: Dictionary = {}


func start(run: MatchRun) -> void:
	var boss := run.content.get_dict("boss")
	run.emit({
		"type": "boss_started",
		"name": str(boss.get("name", "")),
		"title": str(boss.get("title", "")),
		"text": str(boss.get("intro", "")),
		"phases": _phases(run).size(),
	})
	super.start(run)


func pending_threat() -> Dictionary:
	return pending.duplicate()


func view(run: MatchRun, viewer_slot: int) -> Dictionary:
	var out := super.view(run, viewer_slot)
	var boss := run.content.get_dict("boss")
	var phase: Dictionary = _phases(run)[phase_index]
	out["kind"] = "boss"
	out["boss"] = {
		"name": str(boss.get("name", "")),
		"title": str(boss.get("title", "")),
		"phase": phase_index + 1,
		"phases_total": _phases(run).size(),
		"phase_name": str(phase.get("name", "")),
		"telegraph": pending.duplicate(),
	}
	return out


func _enemy_plan(run: MatchRun, enemy: Dictionary) -> Dictionary:
	if enemy["id"] != BOSS_ID:
		return super._enemy_plan(run, enemy)
	if not pending.is_empty():
		var unleash := pending
		pending = {}
		return _move_plan(run, unleash["move"], unleash["target"])
	var pattern: Array = _phases(run)[phase_index].get("pattern", ["attack"])
	var step := str(pattern[pattern_step % pattern.size()])
	pattern_step += 1
	if step.begins_with("telegraph:"):
		var move := step.trim_prefix("telegraph:")
		var target := _pick_target(run, move)
		var move_data := _move(run, move)
		var target_name := "the Party" if target == "all" else str(_unit(run, target)["name"])
		pending = {
			"move": move,
			"name": str(move_data.get("name", move)),
			"target": target,
			"text": str(move_data.get("telegraph", "")).replace("{target}", target_name),
		}
		var event := pending.duplicate()
		event["type"] = "boss_telegraph"
		run.emit(event)
		return {"actor": BOSS_ID, "action": "charge", "move": move, "move_name": pending["name"]}
	return _move_plan(run, step, _pick_target(run, step))


func _on_action_resolved(run: MatchRun) -> void:
	var boss: Dictionary = _unit(run, BOSS_ID)
	var phases := _phases(run)
	if boss["hp"] <= 0 or phase_index + 1 >= phases.size():
		return
	var next: Dictionary = phases[phase_index + 1]
	if float(boss["hp"]) / float(boss["max_hp"]) > float(next.get("below_ratio", 0.5)):
		return
	phase_index += 1
	pattern_step = 0
	var boost: Dictionary = next.get("boost", {})
	for stat in boost:
		boss[stat] = int(boss[stat]) + int(boost[stat])
	run.emit({
		"type": "boss_phase",
		"phase": phase_index + 1,
		"name": str(next.get("name", "")),
		"text": str(next.get("text", "")),
	})


func _move_plan(run: MatchRun, move: String, target: String) -> Dictionary:
	var data := _move(run, move)
	var profile: Dictionary = data.get("use", attack_profile(run, BOSS_ID))
	var living := valid_targets(run, BOSS_ID, profile)
	var targets: Array = []
	if target == "all":
		targets = living
	elif living.has(target):
		targets = [target]
	else:
		targets = [run.rng.pick(living)]
	return {"actor": BOSS_ID, "action": "attack", "move": move, "move_name": str(data.get("name", move)),
			"profile": profile, "targets": targets}


func _pick_target(run: MatchRun, move: String) -> String:
	var data := _move(run, move)
	var profile: Dictionary = data.get("use", attack_profile(run, BOSS_ID))
	var living := valid_targets(run, BOSS_ID, profile)
	match str(data.get("targeting", "random")):
		"all":
			return "all"
		"strongest":
			return EnemyAi._extreme_hp(run, self, living, false)
		"weakest":
			return EnemyAi._extreme_hp(run, self, living, true)
	return str(run.rng.pick(living))


func _move(run: MatchRun, move: String) -> Dictionary:
	return run.content.get_dict("boss.moves.%s" % move)


func _phases(run: MatchRun) -> Array:
	var phases := run.content.get_array("boss.phases")
	return phases if not phases.is_empty() else [{"name": "", "pattern": ["attack"]}]
