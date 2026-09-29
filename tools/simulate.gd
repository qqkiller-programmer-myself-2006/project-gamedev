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
##   --loadout      run both default and pre-match loadout modes


func _init() -> void:
	var seeds := 30
	var start := 1000
	var modes := [1, 2]
	var pace := false
	var loadout_mode := false
	var story_mode := false
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
		elif arg == "--loadout":
			loadout_mode = true
		elif arg == "--story":
			story_mode = true
	if story_mode:
		_simulate(1, start, seeds, pace, true, true)
		quit(0)
		return
	for humans in modes:
		_simulate(humans, start, seeds, pace, false)
		if loadout_mode:
			_simulate(humans, start, seeds, pace, true)
	quit(0)


func _simulate(humans: int, start: int, seeds: int, pace: bool, use_loadout: bool, story_mode: bool = false) -> void:
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
		var sessions: Array[int]
		if use_loadout:
			if story_mode:
				var session := h.server.open_session()
				h.server.command(session, {"type": "create_room", "name": "Story", "story": true})
				sessions = [session]
			else:
				sessions = [h.create_room("P1")]
			for i in range(1, humans):
				sessions.append(h.join("P%d" % (i + 1)))
			if story_mode:
				# Story rooms accept Race/Boons only for the host's own character.
				var story_classes := ["swordsman", "archer", "mage", "guardian", "rogue"]
				for i in 5:
					var pick := {"type": "set_loadout", "slot": i, "class": story_classes[i],
						"race": "Elf" if i == 0 else "Human", "boons": ["Potential: Bunny"] if i == 0 else []}
					var picked: Dictionary = h.server.command(sessions[0], pick)
					assert(picked.get("ok", false), "invalid story loadout: %s" % picked)
			else:
				# Rotate through available starter choices instead of giving every run
				# the same high-survival Archer/Guardian + Bunny loadout.
				var loadout_classes := ["archer", "guardian", "swordsman", "mage", "rogue"]
				var loadout_races := ["Elf", "Human", "Kobold", "Withered"]
				var loadout_boons := [
					["Potential: Bunny"],
					["Critical Healing", "Energy Conserver"],
					["Enervation", "Alert", "Energy Conserver"],
					["Daredevil Impulse", "Energy Conserver"],
					["Alert", "Will of Thiacdemo", "Energy Conserver"],
				]
				var sample := seed_value - start
				for i in humans:
					var choice := {"type": "set_loadout", "class": loadout_classes[(sample + i * 2) % loadout_classes.size()],
						"race": loadout_races[((sample / 5) + i) % loadout_races.size()],
						"boons": loadout_boons[((sample / 20) + i) % loadout_boons.size()]}
					var result: Dictionary = h.server.command(sessions[i], choice)
					assert(result.get("ok", false), "invalid simulated loadout: %s" % result)
			h.start(sessions[0])
		else:
			sessions = h.start_with_humans(humans)
		var bot := MatchBot.new(h, sessions)
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
	print("== %s, %d seeds from %d%s%s ==" % ["story" if story_mode else "%d human(s)" % humans, seeds, start, " (human pace)" if pace else "", " (loadout)" if use_loadout else " (default)"])
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
