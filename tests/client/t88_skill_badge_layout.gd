extends SceneTree
## Regression check for the battle skill badges at the right screen edge.

class FakeMatch extends MatchScreen:
	func build_corner_menu(_host: Control) -> PanelContainer:
		return PanelContainer.new()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		for scale in [1.0, 1.4]:
			root.size = resolution
			var app := ClientApp.new()
			app.settings = ClientSettings.new()
			app.settings.text_scale = scale
			app.settings.reduced_motion = true
			app.snapshot = {"room": {"your_slot": 0, "story": false, "slots": []}, "match": {"story": false}}
			app._overlay_holder = Control.new()
			app.add_child(app._overlay_holder)
			var screen := FakeMatch.new()
			screen.app = app
			app._current = screen
			var battle := BattleView.new()
			root.add_child(battle)
			battle.setup(screen, app)
			screen._battle = battle
			screen._battle_mode = true
			battle._me = "p0"
			var skills := {
				"pierce": {"name": "Pierce", "cooldown": 0, "affordable": true, "energy": 1},
				"slash": {"name": "Slash", "cooldown": 0, "affordable": false, "energy": 2},
				"aim": {"name": "Aim", "cooldown": 2, "affordable": true, "energy": 1},
				"guard": {"name": "Guard", "cooldown": 0, "affordable": true, "energy": 1}}
			battle._combat = {"your_turn": true, "choices": {"skills": skills, "items": {}, "focus": true}}
			var party := [{"slot": 0, "name": "Hero", "level": 1, "class": "classless",
				"class_name": "Adventurer", "hp": 50, "max_hp": 50, "energy": 1,
				"energy_max": 6, "gold": 0}]
			battle._build_bottom({"party": party})
			await process_frame
			await process_frame
			await process_frame
			var skill_row := battle._skill_marks.get_child(0) as HBoxContainer
			var hud_panel := ((battle._bottom.get_child(0) as Control).get_child(0) as Control)
			var hud_rect := Rect2(hud_panel.global_position, hud_panel.size)
			for badge in skill_row.get_children():
				var badge_rect := Rect2(badge.global_position, badge.size)
				if badge_rect.position.x < 0.0 or badge_rect.end.x > resolution.x:
					push_error("skill badge outside %s at scale %.1f: %s" % [resolution, scale, badge_rect])
					failed = true
				if badge_rect.intersects(hud_rect):
					push_error("skill badge overlaps bottom bar at %s scale %.1f: %s / %s" % [resolution, scale, badge_rect, hud_rect])
					failed = true
			battle.free()
			app.free()
	print("T88 battle skill badge layout: %s" % ("FAILED" if failed else "4 combinations passed"))
	quit(1 if failed else 0)
