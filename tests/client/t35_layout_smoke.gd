extends SceneTree
## Run with: godot --headless --path . -s tests/client/t35_layout_smoke.gd

class FakeMatch extends MatchScreen:
	var tip_target: Container
	var tip_width_value := 210.0

	func build_corner_menu(_host: Control) -> PanelContainer:
		return PanelContainer.new()

	func tip_slot() -> Container:
		return tip_target

	func tip_width() -> float:
		return tip_width_value


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		for scale in [1.0, 1.2, 1.4]:
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
			battle._region.text = "Forest (1/5)"
			var scroll := battle._timeline_scroll
			for i in 10:
				var card := PanelContainer.new()
				card.custom_minimum_size = Vector2(150, 70 * scale)
				card.set_meta("actor_id", "p%d" % i)
				battle._timeline.add_child(card)
			battle._combat = {"actor": "p9"}
			await process_frame
			await process_frame
			var actor := battle._timeline.get_child(9) as Control
			var needed_scroll := actor.global_position.y + actor.size.y > scroll.global_position.y + scroll.size.y
			battle._show_current_actor()
			await process_frame
			if (needed_scroll and scroll.scroll_vertical <= 0) or not Rect2(scroll.global_position, scroll.size).encloses(Rect2(actor.global_position, actor.size)):
				push_error("actor clipped at %s scale %.1f" % [resolution, scale])
				failed = true
			screen.tip_target = battle.tips
			app.hint("combat")
			await process_frame
			await process_frame
			var tip := battle.tips.get_child(0) as Control
			var tip_body := tip.get_child(0).get_child(1) as Control
			if tip_body.size.y > 92 * scale + 1:
				push_error("battle Tip body exceeds height cap at %s scale %.1f" % [resolution, scale])
				failed = true
			if Rect2(tip.global_position, tip.size).intersects(Rect2(battle._region.global_position, battle._region.size)):
				push_error("battle Tip covers region at %s scale %.1f" % [resolution, scale])
				failed = true
			if resolution == Vector2i(1280, 720) and scale in [1.0, 1.4]:
				var party: Array[Dictionary] = []
				for slot in 5:
					party.append({"slot": slot, "name": "Hero %d" % slot, "level": 1,
						"hp": 50, "max_hp": 50, "energy": 1, "energy_max": 6,
						"class": "classless", "class_name": "Adventurer", "gold": 0,
						"spd": 10, "controller": "ai"})
				var combat_view := {"party": party, "layer": 1}
				battle._me = "p0"
				battle._combat = {"actor": "p0", "round": 1, "turn_order": ["p0"],
					"your_turn": true, "choices": {"skills": {}, "items": {}, "focus": true}}
				battle._build_timeline(combat_view)
				battle._build_bottom(combat_view)
				await process_frame
				await process_frame
				await process_frame
				await process_frame
				var column_rect := Rect2(battle._timeline_scroll.global_position, battle._timeline_scroll.size)
				var bottom_row := battle._bottom.get_child(0) as Control
				var hud_panel := bottom_row.get_child(0) as Control
				var hud_rect := Rect2(hud_panel.global_position, hud_panel.size)
				if hud_rect.end.x > 1251.0:
					push_error("combat bottom bar exceeds viewport at scale %.1f: %s" % [scale, hud_rect])
					failed = true
				if column_rect.end.y > hud_rect.position.y:
					push_error("party column reaches behind the HUD at scale %.1f" % scale)
					failed = true
				var actions := hud_panel.get_child(0).get_child(1) as Control
				for button in actions.get_children():
					var button_rect := Rect2(button.global_position, button.size)
					if button_rect.position.x < 0.0 or button_rect.end.x > 1280.0:
						push_error("combat action button outside viewport at scale %.1f: %s" % [scale, button_rect])
						failed = true
				if scale == 1.0:
					var turn_rect := Rect2(battle._turn_banner.global_position, battle._turn_banner.size)
					var first_card := battle._timeline.get_child(0) as Control
					if turn_rect.position.y < 57.0 or turn_rect.end.y + 6.0 > first_card.global_position.y:
						push_error("Turn banner overlaps or crowds the party column: %s / %s" % [turn_rect, column_rect])
						failed = true
					if battle._timeline.get_child_count() != 5:
						push_error("expected all five party cards")
						failed = true
					for card_node in battle._timeline.get_children():
						var card_rect := Rect2(card_node.global_position, card_node.size)
						if not column_rect.encloses(card_rect) or card_rect.end.y > hud_rect.position.y:
							push_error("party card is clipped or behind the HUD: %s" % card_rect)
							failed = true
					var party_scrollbar := battle._timeline_scroll.get_v_scroll_bar()
					var max_scroll := maxf(0.0, party_scrollbar.max_value - party_scrollbar.page)
					if max_scroll > 0.0:
						push_error("five-member party unexpectedly scrolls: max value %.1f" % max_scroll)
						failed = true
			app.close_hints(false)
			battle.free()
			var camp := CampView.new()
			root.add_child(camp)
			camp.setup(screen, app)
			screen.tip_target = camp.tips
			screen.tip_width_value = 390.0
			screen._camp_mode = true
			var view := {"layer": 1, "layers_total": 5, "gold": 100, "story": false,
				"party": [{"slot": 0, "name": "Alice", "level": 1, "gold": 100,
					"hp": 10, "max_hp": 10, "energy": 2, "exp": 0, "exp_next": 10,
					"points": 0, "attributes": {"str": 1, "dex": 1, "con": 1, "int": 1,
						"fth": 1, "cha": 1, "lck": 1}, "derived": {}, "gear": {}}],
				"inventory": [{"item": "potion", "name": "Potion", "count": 2, "kind": "consumable"}]}
			var encounter := {"kind": "merchant", "name": "Mar", "you_are_ready": false,
				"ready": [], "humans": 1, "stock": [{"item": "potion", "name": "Potion",
					"price": 5, "remaining": 2, "affordable": true}]}
			camp.build(view, encounter)
			await process_frame
			await process_frame
			var camp_tip := camp.tips.get_child(0) as Control
			var camp_body := camp_tip.get_child(0).get_child(1) as Control
			if camp_body.size.y > 16 * scale + 1:
				push_error("camp Tip body exceeds height cap at %s scale %.1f" % [resolution, scale])
				failed = true
			var tip_rect := Rect2(camp_tip.global_position, camp_tip.size)
			for target in [camp._columns.get_child(0).get_child(1),
					camp._columns.get_child(2).get_child(1), camp._bottom.get_child(0)]:
				if tip_rect.intersects(Rect2(target.global_position, target.size)):
					push_error("camp Tip covers %s at %s scale %.1f" % [target.name, resolution, scale])
					failed = true
			app.close_hints(false)
			camp.free()
			app._current = null
			screen.free()
			app.free()
	print("T35 layout smoke: %s" % ("FAILED" if failed else "6 combinations passed"))
	quit(1 if failed else 0)
