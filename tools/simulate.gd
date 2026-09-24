extends SceneTree
## Plays many complete Matches with MatchBot and prints balance and pacing
## numbers (see docs/balance.md).
##
##   godot --headless --path . -s tools/simulate.gd -- --seeds=40 --humans=1,2 --pace
##
##   --seeds=N      how many seeds per mode (default 30)
##   --start=N      first seed (default 1000)
##   --humans=1,2   modes to simulate: number of human players
##   --pace         bots take human-like thinking time (MatchBot.HUMAN_PACE)


func _init() -> void:
	var seeds := 30
	var start := 1000
	var modes := [1, 2]
	var pace := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="):
			seeds = int(arg.trim_prefix("--seeds="))
		elif arg.begins_with("--start="):
			start = int(arg.trim_prefix("--start="))
		elif arg.begins_with("--humans="):
			modes = []
			for part in arg.trim_prefix("--humans=").split(","):
				modes.append(int(part))
		elif arg == "--pace":
			pace = true
	for humans in modes:
		_simulate(humans, start, seeds, pace)
	quit(0)


func _simulate(humans: int, start: int, seeds: int, pace: bool) -> void:
	var wins := 0
	var durations: Array = []
	var rounds: Array = []
	var levels: Array = []
	var boss_rounds: Array = []
	var classes := 0.0
	var clues := 0.0
	var defeats_at := {}
	var rejected := 0
	var time_by_part := {}
	for seed_value in range(start, start + seeds):
		var h := MatchHarness.new(seed_value)
		var bot := MatchBot.new(h, h.start_with_humans(humans))
		bot.choose_route = MatchBot.sensible_route
		if pace:
			bot.think = MatchBot.HUMAN_PACE
		bot.on_step = func(v: Dictionary) -> void:
			var part := str(v["phase"])
			if v.get("encounter") != null:
				part = str(v["encounter"].get("kind", part))
			time_by_part[part] = float(time_by_part.get(part, 0.0)) + bot.step
		var view := bot.play_to_end(4 * 3600.0)
		bot.on_step = Callable()
		rejected += bot.commands_rejected
		var summary: Dictionary = view.get("summary", {})
		if summary.get("result") == "victory":
			wins += 1
		else:
			var where := "boss" if bot.events_of_type("boss_started").size() > 0 else "layer %d" % int(summary.get("layer", 0))
			defeats_at[where] = int(defeats_at.get(where, 0)) + 1
		durations.append(float(summary.get("elapsed", 0.0)))
		rounds.append(bot.events_of_type("round_started").size())
		var level_sum := 0.0
		for character in view.get("party", []):
			level_sum += float(character["level"])
		levels.append(level_sum / 5.0)
		classes += float(summary.get("classes_discovered", []).size())
		clues += float(summary.get("clues_found", 0))
		var in_boss := false
		var boss_round_count := 0
		for event in bot.events:
			if event["type"] == "boss_started":
				in_boss = true
			elif in_boss and event["type"] == "round_started":
				boss_round_count += 1
		boss_rounds.append(boss_round_count)
	print("== %d human(s), %d seeds from %d%s ==" % [humans, seeds, start, " (human pace)" if pace else ""])
	print("win rate        %d/%d (%.0f%%)" % [wins, seeds, 100.0 * wins / seeds])
	print("defeats         %s" % [defeats_at])
	print("match minutes   avg %.1f  min %.1f  max %.1f" % [_avg(durations) / 60.0, durations.min() / 60.0, durations.max() / 60.0])
	print("combat rounds   avg %.1f   boss rounds avg %.1f" % [_avg(rounds), _avg(boss_rounds)])
	print("final level     avg %.2f" % _avg(levels))
	print("classes found   avg %.2f   clues avg %.2f" % [classes / seeds, clues / seeds])
	var parts := []
	for part in time_by_part:
		parts.append("%s %.1f" % [part, float(time_by_part[part]) / seeds / 60.0])
	print("minutes by part %s" % ", ".join(parts))
	print("rejected cmds   %d" % rejected)
	print("")


static func _avg(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / values.size()
