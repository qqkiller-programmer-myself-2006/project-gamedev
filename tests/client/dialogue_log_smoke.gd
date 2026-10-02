extends SceneTree
## Verifies Story dialogue stays above the real MatchScreen event log.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		for scale in [1.0, 1.4]:
			var viewport := SubViewport.new()
			viewport.size = resolution
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(viewport)
			var app := ClientApp.new()
			app.settings = ClientSettings.new()
			app.settings.text_scale = scale
			app.settings.reduced_motion = true
			app.story_launcher = StoryLauncher.new()
			app.snapshot = {"room": {"your_slot": 0, "host_slot": 0, "slots": []},
				"match": {"number": 1, "layer": 1, "phase": "travel", "party": _party()}}
			app._overlay_holder = Control.new()
			app.add_child(app._overlay_holder)
			var screen := MatchScreen.new()
			screen.app = app
			screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			viewport.add_child(screen)
			screen.setup(app)
			app._current = screen
			screen._story_director.observe([], app.snapshot)
			await process_frame
			await process_frame
			await process_frame

			var dialogue := screen._story_director.current as DialoguePanel
			if dialogue == null:
				push_error("Story prologue dialogue did not open at %s scale %.1f" % [resolution, scale])
				failed = true
			else:
				var dialogue_rect: Rect2 = dialogue.get_global_rect()
				var log_rect: Rect2 = (screen._log.get_parent() as Control).get_global_rect()
				var header_rect: Rect2 = screen._top.get_global_rect()
				var party_rect: Rect2 = screen._party_scroll.get_global_rect()
				var viewport_rect := Rect2(Vector2.ZERO, resolution)
				if dialogue_rect.intersects(log_rect):
					push_error("Dialogue overlaps log at %s scale %.1f: %s / %s" % [resolution, scale, dialogue_rect, log_rect])
					failed = true
				if not viewport_rect.encloses(dialogue_rect):
					push_error("Dialogue leaves viewport at %s scale %.1f: %s" % [resolution, scale, dialogue_rect])
					failed = true
				if dialogue_rect.intersects(header_rect):
					push_error("Dialogue overlaps header at %s scale %.1f: %s / %s" % [resolution, scale, dialogue_rect, header_rect])
					failed = true
				if dialogue_rect.intersects(party_rect):
					push_error("Dialogue overlaps party column at %s scale %.1f: %s / %s" % [resolution, scale, dialogue_rect, party_rect])
					failed = true
				print("Dialogue/log at %s scale %.1f: %s / %s" % [resolution, scale, dialogue_rect, log_rect])

			viewport.remove_child(screen)
			screen.free()
			app.free()
			root.remove_child(viewport)
			viewport.free()
	print("Dialogue/log smoke: %s" % ("FAILED" if failed else "4 scale/resolution combinations passed"))
	quit(1 if failed else 0)


func _party() -> Array[Dictionary]:
	var party: Array[Dictionary] = []
	for slot in 5:
		party.append({"slot": slot, "name": "Arin" if slot == 0 else "Hero %d" % slot,
			"level": 1, "hp": 50, "max_hp": 50, "energy": 1, "energy_max": 6,
			"class": "classless", "class_name": "Adventurer", "gold": 0,
			"atk": 8, "def": 3, "mag": 2, "res": 2, "spd": 10, "exp": 0,
			"controller": "ai"})
	return party
