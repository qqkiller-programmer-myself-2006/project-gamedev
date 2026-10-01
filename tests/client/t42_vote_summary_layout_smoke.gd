extends SceneTree
## T42b responsive layout smoke: vote at 1.0/1.2/1.4, five members, plus
## Summary and camp Tip bounds at large text.

class LayoutMatch extends MatchScreen:
	func build_corner_menu(_host: Control) -> PanelContainer:
		return PanelContainer.new()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var app := ClientApp.new()
	root.add_child(app)
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
			"level": 1, "hp": 40, "max_hp": 40, "controller": "human",
			"atk": 8, "def": 4, "mag": 3, "res": 4, "spd": 5, "exp": 0,
			"gold": 20, "materials": [], "equipment": {}, "inventory": [], "stat_points": 0})
	app.snapshot = {"room": {"your_slot": 0, "host_slot": 0, "slots": slots, "story": false},
		"match": {"phase": "voting", "layer": 1, "layers_total": 5, "gold": 0,
			"clues": [], "story": false, "party": party,
			"vote": {"layer": 1, "deadline": ClientApp._local_now() + 60.0, "seconds": 60.0,
				"voted_slots": [], "options": [
					{"index": 0, "type": "combat", "name": "Wolf Trail", "hint": "A dangerous road.", "voters": [0, 1, 2, 3, 4]},
					{"index": 1, "type": "rest", "name": "Quiet Glade", "hint": "A place to recover.", "voters": []},
					{"index": 2, "type": "merchant", "name": "Forest Market", "hint": "A traveling trader.", "voters": []}]}}}
	var screen := LayoutMatch.new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.setup(app)
	app._current = screen
	screen.refresh(app, true)
	await process_frame
	await process_frame
	for scale in [1.0, 1.2, 1.4]:
		app.close_hints(false)
		app.settings.text_scale = scale
		app.apply_settings()
		app.hint("vote")
		await process_frame
		await process_frame
		_assert_vote_bounds(screen, root, scale)
	app.settings.text_scale = 1.4
	app.apply_settings()
	app.close_hints(false)
	var banner := PanelContainer.new()
	banner.position = Vector2(400, 90)
	banner.size = Vector2(480, 90)
	root.add_child(banner)
	app._banner = banner
	app._banner_until = ClientApp._local_now() + 3.0
	app.snapshot["match"]["phase"] = "victory"
	app.snapshot["match"]["summary"] = {"result": "victory", "title": "The Forest is quiet.", "text": "The end."}
	screen.refresh(app, true)
	await process_frame
	var viewport := root.get_viewport().get_visible_rect()
	var viewport_rect := Rect2(Vector2.ZERO, viewport.size)
	var summary_rect := screen._panel.get_global_rect()
	_assert(summary_rect.position.x >= viewport_rect.position.x and summary_rect.end.x <= viewport_rect.end.x,
		"Summary panel remains horizontally inside viewport: %s" % summary_rect)
	var title := screen._panel.get_child(0) as Control
	var title_rect := title.get_global_rect()
	_assert(viewport_rect.encloses(title_rect), "Summary title remains in viewport")
	_assert(not banner.visible or not title_rect.intersects(banner.get_global_rect()),
		"Summary title does not intersect an active banner")
	await process_frame
	for camp_kind in ["merchant", "rest"]:
		app.close_hints(false)
		app.snapshot["match"]["phase"] = camp_kind
		app.snapshot["match"]["encounter"] = {"kind": camp_kind, "name": "Quiet Camp", "stock": [],
			"ready": [], "humans": 1, "you_are_ready": false, "deadline": null}
		screen.refresh(app, true)
		await process_frame
		await process_frame
		var camp_tip := screen._camp.tips.get_child(0) as Control
		var camp_tip_rect := camp_tip.get_global_rect()
		_assert(camp_tip_rect.position.x >= 0.0 and camp_tip_rect.end.x <= viewport_rect.end.x,
			"%s Tip fits horizontally at 1.4: %s" % [camp_kind, camp_tip_rect])
	root.remove_child(screen)
	screen.free()
	root.remove_child(app)
	app.free()
	banner.free()
	print("T42b vote/Summary layout smoke: %s" % ("FAILED" if not _failures.is_empty() else "passed"))
	quit(1 if not _failures.is_empty() else 0)


var _failures: Array[String] = []


func _assert_vote_bounds(screen: LayoutMatch, window: Window, scale: float) -> void:
	var panel := screen._panel as VotePanel
	var timer_row := panel.get_child(3) as Control
	var progress_bar := timer_row.get_child(timer_row.get_child_count() - 1) as ProgressBar
	var tip := screen._tips.get_child(0) as Control
	var viewport_rect := Rect2(Vector2.ZERO, window.get_viewport().get_visible_rect().size)
	var panel_rect := panel.get_global_rect()
	var timer_rect := timer_row.get_global_rect()
	var bar_rect := progress_bar.get_global_rect()
	var tip_rect := tip.get_global_rect()
	if is_equal_approx(scale, 1.4):
		for child in panel.get_children():
			print("T42b vote child ", child.name, " minimum=", child.get_combined_minimum_size())
	_assert(panel_rect.position.x >= 0.0 and panel_rect.end.x <= viewport_rect.end.x,
		"Vote panel fits horizontally at %s: %s" % [scale, panel_rect])
	_assert(timer_rect.position.x >= 0.0 and timer_rect.end.x <= viewport_rect.end.x,
		"Vote timer row fits horizontally at %s: %s" % [scale, timer_rect])
	_assert(bar_rect.position.x >= 0.0 and bar_rect.end.x <= viewport_rect.end.x,
		"Vote progress bar fits horizontally at %s: %s" % [scale, bar_rect])
	_assert(tip_rect.position.x >= 0.0 and tip_rect.end.x <= viewport_rect.end.x,
		"Vote Tip fits horizontally at %s: %s" % [scale, tip_rect])
	_assert(viewport_rect.encloses(timer_rect), "Vote timer row stays inside viewport: %s" % timer_rect)
	_assert(viewport_rect.encloses(tip_rect), "Vote Tip stays inside viewport: %s" % tip_rect)
	_assert(not tip_rect.intersects(timer_rect), "Tip does not overlap vote status/timer row")
	_assert(not tip_rect.intersects(panel_rect), "Tip stays outside all vote content")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error(message)