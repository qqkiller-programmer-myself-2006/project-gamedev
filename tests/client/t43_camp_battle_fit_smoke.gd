extends SceneTree
## Run with: godot --headless --path . -s tests/client/t43_camp_battle_fit_smoke.gd
## Checks real global control rects at 1.4 text scale with five party members.

class LayoutMatch extends MatchScreen:
	func build_corner_menu(_host: Control) -> PanelContainer:
		return PanelContainer.new()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var app := ClientApp.new()
	root.add_child(app)
	await process_frame
	app.settings = ClientSettings.new()
	app.settings.text_scale = 1.4
	app.settings.reduced_motion = true
	app.settings.seen_hints = []
	app.apply_settings()
	var slots: Array = []
	var party: Array = []
	for i in 5:
		slots.append({"owner_name": "Player %d" % (i + 1)})
		party.append({"slot": i, "name": "Player %d" % (i + 1), "class_name": "Rogue",
			"class": "rogue", "level": 1, "hp": 40, "max_hp": 40, "energy": 2, "energy_max": 6,
			"controller": "human", "atk": 8, "def": 4, "mag": 3, "res": 4, "spd": 5, "exp": 0,
			"exp_next": 10, "gold": 20, "materials": [], "equipment": {}, "inventory": [], "points": 0,
			"attributes": {"str": 1, "dex": 1, "con": 1, "int": 1, "fth": 1, "cha": 1, "lck": 1},
			"derived": {}, "gear": {"helmet": {"name": "Ironclad Helm of the Mountain"},
				"chest": {"name": "Warden's Reinforced Chestplate"}, "legs": {"name": "Traveler's Hardened Leggings"},
				"boots": {"name": "Swiftwind Leather Boots"}, "weapon": {"name": "Runed Greatsword of Embers"},
				"charm1": {"name": "Pendant of the Ancient Forest"}, "charm2": {"name": "Ring of Unbroken Resolve"},
				"charm3": {"name": "Emblem of the Wandering Star"}}})
	app.snapshot = {"room": {"your_slot": 0, "host_slot": 0, "slots": slots, "story": false},
		"match": {"phase": "merchant", "layer": 1, "layers_total": 5, "gold": 20,
		"clues": [], "story": false, "party": party, "inventory": [
			{"item": "boar_tusk", "name": "Boar Tusk", "count": 2, "kind": "material"},
			{"item": "bramble_wood", "name": "Bramble Wood", "count": 1, "kind": "material"},
			{"item": "forest_tonic", "name": "Forest Tonic", "count": 1, "kind": "consumable"},
			{"item": "ironclad_helm", "name": "Ironclad Helm of the Mountain", "count": 1, "kind": "gear"}], "encounter": {
				"kind": "merchant", "name": "Forest Market", "stock": [
				{"item": "healing_herb", "name": "Healing Herb", "price": 12, "remaining": 5, "affordable": true},
				{"item": "forest_tonic", "name": "Forest Tonic", "price": 27, "remaining": 1, "affordable": true},
				{"item": "spirit_bloom", "name": "Spirit Bloom of the Old Grove", "price": 39, "remaining": 1, "affordable": true},
				{"item": "firebomb", "name": "Firebomb", "price": 42, "remaining": 3, "affordable": false}], "ready": [],
				"humans": 5, "you_are_ready": false, "deadline": null}}}
	var screen := LayoutMatch.new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.setup(app)
	app._current = screen
	screen.refresh(app, true)
	await process_frame
	await process_frame
	_print_camp_minimums(screen._camp)
	var viewport_rect := Rect2(Vector2.ZERO, root.get_viewport().get_visible_rect().size)
	for kind in ["merchant", "rest"]:
		app.snapshot["match"]["phase"] = kind
		var stock: Array = [{"item": "healing_herb", "name": "Healing Herb", "price": 12, "remaining": 5, "affordable": true},
			{"item": "forest_tonic", "name": "Forest Tonic", "price": 27, "remaining": 1, "affordable": true},
			{"item": "spirit_bloom", "name": "Spirit Bloom of the Old Grove", "price": 39, "remaining": 1, "affordable": true},
			{"item": "firebomb", "name": "Firebomb", "price": 42, "remaining": 3, "affordable": false}] if kind == "merchant" else []
		app.snapshot["match"]["encounter"] = {"kind": kind, "name": "Quiet Camp", "stock": stock,
			"ready": [], "humans": 5, "you_are_ready": false, "deadline": null}
		screen.refresh(app, true)
		await process_frame
		await process_frame
		_assert_camp_bounds(screen._camp, viewport_rect, kind)
	app.snapshot["match"]["phase"] = "combat"
	app.snapshot["match"]["encounter"] = {"kind": "combat", "name": "Wolf", "actor": "p0", "round": 1,
		"turn_order": ["p0", "e0", "p1", "p2", "p3", "p4"], "round_order": ["p0", "e0", "p1", "p2", "p3", "p4"],
		"your_turn": true, "deadline": null, "window_seconds": 15.0, "enemies": [{"id": "e0", "name": "Wolf",
			"kind": "wolf", "row": "front", "hp": 30, "max_hp": 30, "weakness": []}], "statuses": {}, "choices": {"skills": {
			"quick_strike": {"name": "Quick Strike", "cooldown": 0, "energy": 1, "affordable": true, "targets": ["e0"]},
			"shadow_step": {"name": "Shadow Step", "cooldown": 0, "energy": 2, "affordable": false, "targets": ["e0"]}},
			"items": {}, "focus": true}}
	screen.refresh(app, true)
	await process_frame
	await process_frame
	screen._battle.add_log("Wren takes 29.")
	await process_frame
	_print_battle_metrics(screen._battle)
	_assert_inside(screen._battle._turn_banner, viewport_rect, "Battle Turn panel")
	_assert_inside(screen._battle._skill_marks, viewport_rect, "Battle status chips")
	for child in screen._battle.get_children():
		if child is PanelContainer and (child as Control).visible:
			_assert_inside(child as Control, viewport_rect, "Battle top-level panel %s" % child.name)
	var action_hud := _find_action_hud(screen._battle)
	_assert_inside(action_hud, viewport_rect, "Battle action HUD panel")
	var chip_row := screen._battle._skill_marks.get_child(0) as Container
	for chip in chip_row.get_children():
		_assert_inside(chip as Control, viewport_rect, "Battle status chip")
	_assert_inside(screen._battle._log.get_parent() as Control, viewport_rect, "Battle log panel")
	_assert_inside(screen._battle._log, viewport_rect, "Battle log")
	_assert(screen._battle._log.size.x >= 210.0 and screen._battle._log.autowrap_mode != TextServer.AUTOWRAP_OFF,
		"Battle log wraps in a readable width at 1.4x")
	_assert(screen._battle._log.get_parsed_text().contains("Wren takes 29."), "Battle log keeps its leading characters")
	root.remove_child(screen)
	screen.free()
	root.remove_child(app)
	app.free()
	print("T43 camp/battle fit smoke: %s" % ("FAILED" if not _failures.is_empty() else "passed"))
	quit(1 if not _failures.is_empty() else 0)


var _failures: Array[String] = []


func _print_camp_minimums(camp: CampView) -> void:
	for i in camp._columns.get_child_count():
		var child := camp._columns.get_child(i) as Control
		print("T43 camp column %d %s combined_min=%s size=%s rect=%s" % [i, child.name,
			child.get_combined_minimum_size(), child.size, child.get_global_rect()])


func _print_battle_metrics(battle: BattleView) -> void:
	print("T43 battle hud combined_min=", _find_action_hud(battle).get_combined_minimum_size(),
		" rect=", _find_action_hud(battle).get_global_rect())
	print("T43 battle chips combined_min=", battle._skill_marks.get_combined_minimum_size(),
		" rect=", battle._skill_marks.get_global_rect())
	print("T43 battle log combined_min=", battle._log.get_parent().get_combined_minimum_size(),
		" rect=", battle._log.get_parent().get_global_rect(), " text=", battle._log.get_parsed_text())


func _find_action_hud(battle: BattleView) -> Control:
	var row := battle._bottom.get_child(battle._bottom.get_child_count() - 1) as Control
	return row.get_child(0) as Control


func _assert_camp_bounds(camp: CampView, viewport_rect: Rect2, kind: String) -> void:
	for column in camp._columns.get_children():
		var col := column as Control
		_assert_inside(col.get_child(0) as Control, viewport_rect, "%s column heading" % kind)
		_assert_inside(col.get_child(1) as Control, viewport_rect, "%s column panel" % kind)
	var ready := camp._bottom.get_child(0) as Control
	_assert_inside(ready, viewport_rect, "%s Ready button" % kind)
	_assert_inside(camp._hide_button, viewport_rect, "%s Hide button" % kind)
	_assert(str(ready.get_meta("focus_id", "")) == "ready" and ready.focus_mode != Control.FOCUS_NONE,
		"%s Ready button keeps keyboard focus" % kind)
	_assert(not camp._hide_button.tooltip_text.is_empty(), "%s Hide tooltip remains available" % kind)
	if kind == "merchant":
		var left := camp._columns.get_child(0).get_child(1).get_child(0).get_child(1) as Control
		var shop_list := left.get_child(1) as ScrollContainer
		var left_rows := shop_list.get_child(0) as Container
		var inventory := camp._columns.get_child(1).get_child(1).get_child(0).get_child(1) as Control
		var inventory_list := inventory.get_child(1) as ScrollContainer
		var inventory_rows := inventory_list.get_child(0) as Container
		_assert(left_rows.get_child_count() > 0, "Merchant shop items remain visible")
		_assert(inventory_rows.get_child_count() > 0, "Merchant inventory items remain visible")
		_assert(shop_list.size.y > 0.0 and inventory_list.size.y > 0.0,
			"Merchant and inventory lists receive scrollable viewport height")


func _assert_inside(control: Control, viewport_rect: Rect2, label: String) -> void:
	var rect := control.get_global_rect()
	_assert(viewport_rect.encloses(rect), "%s outside viewport: %s viewport=%s" % [label, rect, viewport_rect])


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)
