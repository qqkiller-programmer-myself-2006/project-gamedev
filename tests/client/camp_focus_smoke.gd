extends SceneTree
## T34 (#86) live smoke check: runs inside a real SceneTree with a real
## Viewport, so grab_focus()/gui_get_focus_owner() are genuine GUI focus.
## Run: godot --headless --path . -s tests/client/camp_focus_smoke.gd
## Verifies: search text + focus survive camp.build(); r/1 handled while the
## search is focused send zero commands; scroll positions survive; shortcuts
## still fire once the editor is unfocused. Quits 0 on success, 1 on failure.


class StubConnection extends ServerConnection:
	var sent: Array = []

	func is_open() -> bool:
		return true

	func send_command(cmd: Dictionary) -> int:
		sent.append(cmd)
		return sent.size()


var _failures: Array[String] = []
var _ran := false


## Runs once on the first frame, when the native tree (and root viewport)
## is up, then quits. Everything checked here is synchronous on purpose:
## the unit suite must also pass without any frame ever running.
func _process(_delta: float) -> bool:
	if _ran:
		return true
	_ran = true
	_run()
	if _failures.is_empty():
		print("[SMOKE] 0 failed: camp focus/scroll smoke passed")
		quit(0)
	else:
		print("[SMOKE] %d failed:" % _failures.size())
		for failure in _failures:
			print("[SMOKE-FAIL] %s" % failure)
		quit(1)
	return true


func _check(condition: bool, label: String) -> void:
	if condition:
		print("[SMOKE-PASS] %s" % label)
	else:
		_failures.append(label)


func _run() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app.sounds = SoundBank.new()
	app._overlay_holder = Control.new()
	app.add_child(app._overlay_holder)
	var stub := StubConnection.new()
	app.connection = stub
	app.snapshot = {"room": {"your_slot": 0, "story": false, "slots": []}, "match": {"story": false}}
	var screen := MatchScreen.new()
	screen.app = app
	var camp := CampView.new()
	camp.setup(screen, app)
	root.add_child(camp)

	var view := {
		"layer": 1, "layers_total": 5, "gold": 100, "story": false,
		"party": [{
			"slot": 0, "name": "Alice", "level": 1, "gold": 100,
			"hp": 10, "max_hp": 10, "energy": 2, "exp": 0, "exp_next": 10,
			"points": 0,
			"attributes": {"str": 1, "dex": 1, "con": 1, "int": 1, "fth": 1, "cha": 1, "lck": 1},
			"derived": {}, "gear": {},
		}],
		"inventory": [
			{"item": "potion", "name": "Potion", "count": 2, "kind": "consumable"},
			{"item": "sword", "name": "Sword", "count": 1, "kind": "gear"},
		],
	}
	var encounter := {
		"kind": "merchant", "name": "Mar", "you_are_ready": false, "ready": [], "humans": 1,
		"stock": [
			{"item": "sword", "name": "Sword", "price": 10, "remaining": 3, "affordable": true},
			{"item": "potion", "name": "Potion", "price": 5, "remaining": 2, "affordable": true},
		],
	}
	camp.build(view, encounter)

	# Simulate typing "r1" into the left search and focusing it for real.
	var search := camp._find_by_focus_id(camp, "camp_search_left") as LineEdit
	_check(search is LineEdit, "left search box exists with its focus_id")
	_check((camp._find_by_focus_id(camp, "camp_search_inventory") as LineEdit) is LineEdit,
			"inventory search box exists with its focus_id")
	search.text = "r1"
	search.text_changed.emit("r1")
	search.caret_column = 2
	search.grab_focus()
	_check(camp.get_viewport().gui_get_focus_owner() == search, "search really holds GUI focus")

	# Scroll all three regions, then rebuild (as a friend buy / Ready would).
	var before: Array = []
	camp._collect_scrolls(camp._columns, before)
	_check(before.size() >= 3, "left, inventory and stat scrolls exist")
	var probe := [137, 42, 7]
	for i in before.size():
		(before[i] as ScrollContainer).scroll_vertical = probe[i % probe.size()]
	var snap := camp._snapshot_camp_state()
	_check(str(snap.get("focus_id", "")) == "camp_search_left", "snapshot captures the focused search")
	camp.build(view, encounter)

	var owner := camp.get_viewport().gui_get_focus_owner()
	_check(owner is LineEdit, "focus returns to a text box after the update")
	_check(owner != null and str(owner.get_meta("focus_id", "")) == "camp_search_left",
			"focus returns to the left search after the update")
	_check(owner != null and (owner as LineEdit).text == "r1", "search text survives the update")
	_check(owner != null and (owner as LineEdit).caret_column == 2, "caret survives the update")

	stub.sent.clear()
	_check(camp.handle_key(KEY_R), "r is swallowed while searching")
	_check(camp.handle_key(KEY_1), "1 is swallowed while searching")
	_check(stub.sent.is_empty(), "typing r1 sends neither Ready nor a buy")

	var after: Array = []
	camp._collect_scrolls(camp._columns, after)
	_check(after.size() == before.size(), "scroll set is stable across the rebuild")
	for i in after.size():
		_check((after[i] as ScrollContainer).scroll_vertical == int(snap["scrolls"][i]["v"]),
				"scroll %d keeps its position across the update" % i)

	if owner != null:
		owner.release_focus()
	_check(camp.get_viewport().gui_get_focus_owner() != search, "focus can leave the search")
	stub.sent.clear()
	_check(camp.handle_key(KEY_R), "r readies once the editor is unfocused")
	_check(stub.sent.size() == 1 and str(stub.sent[0].get("type", "")) == "ready",
			"unfocused r sends exactly one Ready")

	root.remove_child(camp)
	camp.free()
	screen.free()
	app.sounds.free()
	app.free()
