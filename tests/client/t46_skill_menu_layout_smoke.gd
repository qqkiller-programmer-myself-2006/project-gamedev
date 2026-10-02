extends SceneTree
## Run with: godot --headless --path . -s tests/client/t46_skill_menu_layout_smoke.gd
## Checks battle layout with real global rectangles at normal and 1.4x text.

class LayoutMatch extends MatchScreen:
	func build_corner_menu(_host: Control, _with_corner: bool = true) -> PanelContainer:
		return PanelContainer.new()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Tr.setup("en")
	root.size = Vector2i(1280, 720)
	var app := ClientApp.new()
	root.add_child(app)
	await process_frame
	var skills := {
		"quick_strike": {"name": "Quick Strike", "cooldown": 0, "energy": 1, "affordable": true,
			"targets": ["e0"], "target": "single_enemy", "description": "A quick attack."},
		"shadow_step": {"name": "Shadow Step", "cooldown": 1, "energy": 2, "affordable": true,
			"targets": ["e0"], "target": "single_enemy", "description": "Move through shadows."},
		"shield_wall": {"name": "Shield Wall", "cooldown": 0, "energy": 2, "affordable": false,
			"targets": ["p0"], "target": "self", "description": "Raise a sturdy defense."},
		"forest_bloom": {"name": "Forest Bloom", "cooldown": 0, "energy": 3, "affordable": true,
			"targets": ["e0"], "target": "all_enemies", "description": "Bloom with forest energy."},
		"poison_blade": {"name": "Poison Blade", "cooldown": 0, "energy": 2, "affordable": true,
			"targets": ["e0"], "target": "single_enemy", "description": "Coat the blade in poison."},
		"evasive_roll": {"name": "Evasive Roll", "cooldown": 2, "energy": 1, "affordable": true,
			"targets": ["p0"], "target": "self", "description": "Roll away from danger."},
		"venom_burst": {"name": "Venom Burst", "cooldown": 0, "energy": 3, "affordable": true,
			"targets": ["e0"], "target": "single_enemy", "description": "Burst venom at an enemy."},
	}
	var party: Array = []
	var slots: Array = []
	for i in 5:
		slots.append({"owner_name": "Player %d" % (i + 1)})
		party.append({"slot": i, "name": "Player %d" % (i + 1), "class_name": "Rogue", "class": "rogue",
			"level": 1, "hp": 40, "max_hp": 40, "energy": 2, "energy_max": 6, "controller": "human",
			"atk": 8, "def": 4, "mag": 3, "res": 4, "spd": 5, "exp": 0, "exp_next": 10, "gold": 20,
			"materials": [], "equipment": {}, "inventory": [], "points": 0,
			"attributes": {"str": 1, "dex": 1, "con": 1, "int": 1, "fth": 1, "cha": 1, "lck": 1},
			"derived": {}})
	app.snapshot = {"room": {"your_slot": 0, "host_slot": 0, "slots": slots, "story": false},
		"match": {"phase": "combat", "layer": 1, "layers_total": 5, "gold": 20, "clues": [],
			"story": false, "party": party, "inventory": [{"item": "healing_herb", "name": "Healing Herb",
				"count": 1, "description": "Restore a little Health."}], "encounter": {"kind": "combat", "name": "Boar",
			"actor": "p0", "round": 1, "turn_order": ["p0", "e0"], "round_order": ["p0", "e0"], "your_turn": true,
			"deadline": null, "window_seconds": 15.0,
			"enemies": [{"id": "e0", "name": "Thornback Boar Lord", "level": 12, "kind": "boar",
				"row": "front", "hp": 30, "max_hp": 30, "weakness": []}], "statuses": {},
			"choices": {"attack": {"targets": ["e0"]}, "skills": skills,
				"items": {"healing_herb": {"count": 1, "targets": ["p0"]}}, "focus": true}}}}
	var screen := LayoutMatch.new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.setup(app)
	app._current = screen
	var viewport_rect := Rect2(Vector2.ZERO, root.get_viewport().get_visible_rect().size)
	for language in ["en", "th"]:
		for text_scale in [1.0, 1.4]:
			app.settings = ClientSettings.new()
			app.settings.text_scale = text_scale
			app.settings.reduced_motion = true
			app.settings.seen_hints = []
			app.apply_settings()
			Tr.setup(language)
			screen.combat_mode = "skills"
			screen.refresh(app, true)
			await process_frame
			await process_frame
			var battle := screen._battle as BattleView
			var menu := battle._combat_grid as Control
			var chips := battle._skill_marks as Control
			var log := battle._log.get_parent() as Control
			var menu_rect := menu.get_global_rect()
			_assert(menu != null and menu.visible, "Skill menu visible at %s scale %s" % [language, text_scale])
			_assert(chips != null and chips.visible, "Status chips visible at %s scale %s" % [language, text_scale])
			_assert_inside(menu, viewport_rect, "Skill menu at %s scale %s" % [language, text_scale])
			_assert_inside(chips, viewport_rect, "Status chips at %s scale %s" % [language, text_scale])
			_assert_inside(log, viewport_rect, "Battle log at %s scale %s" % [language, text_scale])
			_assert_not_intersect(menu, chips, "Skill menu / status chips at %s scale %s" % [language, text_scale])
			_assert_not_intersect(menu, log, "Skill menu / battle log at %s scale %s" % [language, text_scale])
			_assert_not_intersect(chips, log, "Status chips / battle log at %s scale %s" % [language, text_scale])
			var scroll := menu as ScrollContainer
			_assert(scroll != null and scroll.get_child_count() == 1, "Skill menu uses a scrollable grid")
			var boar_plate: Control = null
			if scroll != null and scroll.get_child_count() > 0:
				var holder := scroll.get_child(0) as PanelContainer
				var grid := holder.get_child(0) as GridContainer
				_assert(grid.get_child_count() == 9 and battle._choices.size() == 9,
					"Strike, Guard and skills remain reachable with keys 1-9")
				if text_scale > 1.0:
					_assert(grid.get_combined_minimum_size().y > scroll.size.y,
						"Long skill grids scroll inside their viewport at 1.4x")
				for card_value in grid.get_children():
					var card := card_value as Button
					_assert(card.focus_mode == Control.FOCUS_ALL and not card.tooltip_text.is_empty(),
						"Skill card keeps focus and tooltip: %s" % card.name)
					_assert(card.size.y >= card.get_child(0).get_combined_minimum_size().y,
						"Skill card height contains its name and cost lines: %s" % card.name)
				boar_plate = battle._enemy_plates.get_child(0) as Control
				var labels := _find_labels(boar_plate)
				var name_label: Label = null
				var level_label: Label = null
				for label in labels:
					if label.text == Tr.t("Thornback Boar Lord"):
						name_label = label
					elif label.text == Tr.t("Lv 12"):
						level_label = label
				_assert(name_label != null and name_label.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS,
					"Enemy name truncates with ellipsis at %s scale %s" % [language, text_scale])
				_assert(level_label != null and level_label.size.x > 0,
					"Enemy level remains visible at %s scale %s" % [language, text_scale])
			print("T46 %s scale=%s menu=%s chips=%s log=%s" % [language, text_scale,
				menu.get_global_rect(), chips.get_global_rect(), log.get_global_rect()])
			screen.combat_mode = "attack"
			battle.refresh_action_panel()
			await process_frame
			await process_frame
			var prompt := battle.get_node_or_null("BattleTargetPrompt") as Control
			chips = battle._skill_marks
			_assert(prompt != null and prompt.visible, "Target prompt visible at %s scale %s" % [language, text_scale])
			if prompt != null:
				_assert_inside(prompt, viewport_rect, "Target prompt at %s scale %s" % [language, text_scale])
				_assert(not prompt.get_global_rect().intersects(menu_rect),
					"Target prompt / skill menu at %s scale %s" % [language, text_scale])
				_assert_not_intersect(prompt, log, "Target prompt / battle log at %s scale %s" % [language, text_scale])
				_assert_not_intersect(prompt, chips, "Target prompt / status chips at %s scale %s" % [language, text_scale])
				_assert_not_intersect(prompt, boar_plate, "Target prompt / enemy nameplate at %s scale %s" % [language, text_scale])
			screen.combat_mode = "items"
			battle.refresh_action_panel()
			await process_frame
			await process_frame
			var item_scroll := battle._combat_grid as ScrollContainer
			var item_holder := item_scroll.get_child(0) as PanelContainer
			var item_grid := item_holder.get_child(0) as GridContainer
			var item_labels := _find_labels(item_grid.get_child(0))
			var item_name_found := false
			for item_label in item_labels:
				if item_label.text.ends_with(Tr.t("Healing Herb")) and item_label.size.x > 0 and item_label.size.y > 0:
					item_name_found = true
			_assert(item_name_found, "Item card keeps its name visible at %s scale %s" % [language, text_scale])
	root.remove_child(screen)
	screen.free()
	root.remove_child(app)
	app.free()
	print("T46 skill menu layout smoke: %s" % ("FAILED" if not _failures.is_empty() else "passed"))
	quit(1 if not _failures.is_empty() else 0)


var _failures: Array[String] = []


func _find_labels(root_node: Node) -> Array[Label]:
	var found: Array[Label] = []
	if root_node is Label:
		found.append(root_node as Label)
	for child in root_node.get_children():
		found.append_array(_find_labels(child))
	return found


func _assert_inside(control: Control, viewport_rect: Rect2, label: String) -> void:
	var rect := control.get_global_rect()
	_assert(viewport_rect.encloses(rect), "%s outside viewport: %s viewport=%s" % [label, rect, viewport_rect])


func _assert_not_intersect(a: Control, b: Control, label: String) -> void:
	_assert(not a.get_global_rect().intersects(b.get_global_rect()),
		"%s intersect: %s / %s" % [label, a.get_global_rect(), b.get_global_rect()])


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)
