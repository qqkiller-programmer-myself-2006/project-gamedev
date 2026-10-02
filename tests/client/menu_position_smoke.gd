extends SceneTree
## Regression coverage for the list-screen Esc menu across supported scales and window sizes.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		for scale in [1.0, 1.4]:
			var app := ClientApp.new()
			app.settings = ClientSettings.new()
			app.settings.text_scale = scale
			app.settings.reduced_motion = true
			app.snapshot = {
				"room": {"your_slot": 0, "host_slot": 0, "slots": []},
				"match": {
					"phase": "idle", "layer": 1, "layers_total": 5,
					"party": _party()
				}
			}
			app._overlay_holder = Control.new()
			app._banner = PanelContainer.new()
			var screen := MatchScreen.new()
			screen.app = app
			root.add_child(screen)
			screen.setup(app)
			app._current = screen
			screen.refresh(app, true)
			await process_frame
			await process_frame

			screen.handle_key(app, KEY_ESCAPE)
			await process_frame
			var menu_rect := screen._list_menu.get_global_rect()
			for card in screen._party.get_children():
				var card_rect := (card as Control).get_global_rect()
				if menu_rect.intersects(card_rect):
					push_error("Esc menu overlaps party card at %s scale %.1f: %s / %s" % [resolution, scale, menu_rect, card_rect])
					failed = true
			for button in _buttons(screen._header_actions):
				var button_rect := button.get_global_rect()
				if menu_rect.intersects(button_rect):
					push_error("Esc menu overlaps header button at %s scale %.1f: %s / %s" % [resolution, scale, menu_rect, button_rect])
					failed = true
			var first_item := screen._list_menu.get_child(0).get_child(0) as Control
			if root.get_viewport().gui_get_focus_owner() != first_item:
				push_error("Esc menu did not focus its first item at %s scale %.1f" % [resolution, scale])
				failed = true
			screen.handle_key(app, KEY_ESCAPE)
			if screen._list_menu.visible:
				push_error("second Esc did not close menu at %s scale %.1f" % [resolution, scale])
				failed = true
			screen.handle_key(app, KEY_ESCAPE)
			screen._set_fullscreen("battle")
			if screen._list_menu.visible:
				push_error("menu stayed open after leaving the list screen at %s scale %.1f" % [resolution, scale])
				failed = true

			root.remove_child(screen)
			screen.free()
			app._overlay_holder.free()
			app._banner.free()
			app.free()
	print("Menu position smoke: %s" % ("FAILED" if failed else "4 scale/resolution combinations passed"))
	quit(1 if failed else 0)


func _party() -> Array[Dictionary]:
	var party: Array[Dictionary] = []
	for slot in 5:
		party.append({
			"slot": slot, "name": "Arin" if slot == 0 else "Hero %d" % slot,
			"level": 1, "hp": 50, "max_hp": 50, "energy": 1, "energy_max": 6,
			"class": "classless", "class_name": "Adventurer", "gold": 0,
			"atk": 8, "def": 3, "mag": 2, "res": 2, "spd": 10, "exp": 0,
			"controller": "ai"
		})
	return party


func _buttons(node: Node) -> Array[Button]:
	var found: Array[Button] = []
	if node is Button:
		found.append(node)
	for child in node.get_children():
		found.append_array(_buttons(child))
	return found
