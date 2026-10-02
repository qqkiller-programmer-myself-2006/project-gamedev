extends "res://tests/test_case.gd"
## T34 (#86): camp build() rebuilds its columns on every update. The rebuild
## must preserve scroll positions and search focus/text, and typing shortcut
## keys (r, 1-9) into a search box must never fire Ready/buy/craft.
##
## Note: the headless runner executes tests inside SceneTree._init, so
## Engine.get_main_loop() is null and no Viewport exists. These tests
## therefore drive the snapshot/restore helpers and the suppression
## predicate directly instead of using real GUI focus.


class StubConnection extends ServerConnection:
	var sent: Array = []

	func is_open() -> bool:
		return true

	func send_command(cmd: Dictionary) -> int:
		sent.append(cmd)
		return sent.size()


var _app: ClientApp = null
var _screen: MatchScreen = null
var _camp: CampView = null
var _stub: StubConnection = null


func after_each() -> void:
	if _camp != null and is_instance_valid(_camp):
		_camp.free()
	_camp = null
	if _screen != null and is_instance_valid(_screen):
		_screen.free()
	_screen = null
	if _app != null and is_instance_valid(_app):
		if _app.sounds != null and is_instance_valid(_app.sounds):
			_app.sounds.free()
		_app.free()
	_app = null
	_stub = null


func _make_camp() -> void:
	_app = ClientApp.new()
	_app.settings = ClientSettings.new()
	_app.sounds = SoundBank.new()
	_app._overlay_holder = Control.new()
	_app.add_child(_app._overlay_holder)
	_stub = StubConnection.new()
	_app.connection = _stub
	_app.snapshot = {"room": {"your_slot": 0, "story": false, "slots": []}, "match": {"story": false}}
	_screen = MatchScreen.new()
	_screen.app = _app
	_camp = CampView.new()
	_camp.setup(_screen, _app)


func _view() -> Dictionary:
	return {
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


func _merchant() -> Dictionary:
	return {
		"kind": "merchant", "name": "Mar", "you_are_ready": false, "ready": [], "humans": 1,
		"stock": [
			{"item": "sword", "name": "Sword", "price": 10, "remaining": 3, "affordable": true},
			{"item": "potion", "name": "Potion", "price": 5, "remaining": 2, "affordable": true},
		],
	}


func _search(which: String) -> LineEdit:
	return _camp._find_by_focus_id(_camp, which) as LineEdit


func test_search_boxes_have_distinct_focus_ids() -> void:
	_make_camp()
	_camp.build(_view(), _merchant())
	var left := _search("camp_search_left")
	var inv := _search("camp_search_inventory")
	assert_true(left is LineEdit, "left search box keeps focus_id camp_search_left")
	assert_true(inv is LineEdit, "inventory search box keeps focus_id camp_search_inventory")
	assert_true(left != inv, "the two search boxes are distinct controls")


func test_camp_backdrop_tracks_the_current_layer() -> void:
	_make_camp()
	var view := _view()
	view["layer"] = 5
	_camp.build(view, _merchant())
	assert_eq(_camp._backdrop.backdrop_name, "cave")


func test_update_keeps_search_text() -> void:
	_make_camp()
	var view := _view()
	var encounter := _merchant()
	_camp.build(view, encounter)
	# Typing updates the filter member, which the rebuild re-applies.
	# (Emit the signal: headless assignment to .text is not a keystroke.)
	_search("camp_search_left").text_changed.emit("r1")
	assert_eq(_camp._left_search, "r1", "typing reaches the filter member")
	_camp.build(view, encounter)
	assert_eq(_search("camp_search_left").text, "r1", "search text survives the update")


func test_restore_applies_focus_text_and_caret_to_new_box() -> void:
	_make_camp()
	var view := _view()
	var encounter := _merchant()
	_camp.build(view, encounter)
	var old := _search("camp_search_left")
	old.text = "r1"
	old.caret_column = 2
	# Snapshot the focused state the way build() would with a real viewport,
	# then rebuild (which frees the old box) and restore onto the new one.
	var snap := {"scrolls": [], "focus_id": "camp_search_left", "edit_text": "r1", "caret": 2}
	_camp.build(view, encounter)
	_camp._restore_camp_state(snap)
	var fresh := _search("camp_search_left")
	assert_true(fresh is LineEdit, "a new left search box exists after the update")
	assert_true(fresh != old, "restore targets the rebuilt box, not the freed one")
	assert_eq(fresh.text, "r1", "restore re-applies the search text")
	assert_eq(fresh.caret_column, 2, "restore re-applies the caret position")


func test_text_editors_suppress_shortcuts() -> void:
	assert_true(CampView._is_text_editor(LineEdit.new()), "LineEdit suppresses shortcuts")
	assert_true(CampView._is_text_editor(TextEdit.new()), "TextEdit suppresses shortcuts")
	assert_true(CampView._is_text_editor(CodeEdit.new()), "CodeEdit suppresses shortcuts")
	assert_false(CampView._is_text_editor(Button.new()), "buttons keep shortcuts")
	assert_false(CampView._is_text_editor(null), "no focus keeps shortcuts")


func test_shortcuts_still_fire_without_text_focus() -> void:
	_make_camp()
	_camp.build(_view(), _merchant())
	_stub.sent.clear()
	assert_true(_camp.handle_key(KEY_R), "r still readies when no text editor is focused")
	assert_true(_camp.handle_key(KEY_1), "1 requests purchase confirmation")
	assert_eq(_stub.sent.size(), 1, "a purchase does not send before confirmation")
	assert_eq(str(_stub.sent[0].get("type", "")), "ready", "r sends Ready")
	var dialogs := _app._overlay_holder.find_children("*", "ConfirmDialog", true, false)
	var dialog := dialogs[0] as ConfirmDialog if not dialogs.is_empty() else null
	assert_true(dialog is ConfirmDialog, "1 opens a purchase confirmation")
	for button in dialog.find_children("*", "Button", true, false):
		if (button as Button).text.begins_with("Buy "):
			(button as Button).pressed.emit()
	assert_eq(_stub.sent.size(), 2, "confirming sends the purchase")
	assert_eq(str(_stub.sent[1].get("type", "")), "buy", "confirmation sends a buy")
	assert_eq(str(_stub.sent[1].get("item", "")), "sword", "confirmation buys the first stock entry")


func test_scroll_positions_survive_update() -> void:
	_make_camp()
	var view := _view()
	var encounter := _merchant()
	_camp.build(view, encounter)
	var before: Array = []
	_camp._collect_scrolls(_camp._columns, before)
	assert_true(before.size() >= 3, "left, inventory and stat scrolls exist")
	var probe := [137, 42, 7]
	for i in before.size():
		(before[i] as ScrollContainer).scroll_vertical = probe[i % probe.size()]
	var snap := _camp._snapshot_camp_state()
	assert_eq((snap["scrolls"] as Array).size(), before.size(), "snapshot covers every scroll")
	_camp.build(view, encounter)
	var after: Array = []
	_camp._collect_scrolls(_camp._columns, after)
	assert_eq(after.size(), before.size(), "scroll set is stable across the rebuild")
	for i in after.size():
		assert_eq((after[i] as ScrollContainer).scroll_vertical, int(snap["scrolls"][i]["v"]),
				"scroll %d keeps its position across the update" % i)


func _has_text(node: Node, wanted: String) -> bool:
	if node is Label and str((node as Label).text).contains(wanted):
		return true
	if node is Button and str((node as Button).text).contains(wanted):
		return true
	for child in node.get_children():
		if _has_text(child, wanted):
			return true
	return false


func test_rest_camp_builds_and_keeps_search_ids() -> void:
	_make_camp()
	var encounter := {
		"kind": "rest", "name": "Camp", "you_are_ready": false, "ready": [], "humans": 1,
		"recipes": [
			{"recipe": "patch", "name": "Patch Up", "category": "Care", "craftable": true, "materials": []},
		],
	}
	_camp.build(_view(), encounter)
	assert_true(_has_text(_camp, "Patch Up"), "rest camp lists its recipes")
	assert_true(_search("camp_search_left") is LineEdit, "rest keeps the left search focus_id")
	assert_true(_search("camp_search_inventory") is LineEdit, "rest keeps the inventory search focus_id")
	_stub.sent.clear()
	assert_true(_camp.handle_key(KEY_1), "craft shortcut still fires with no text editor focused")
	assert_eq(str(_stub.sent[0].get("type", "")), "craft", "1 crafts the first recipe at a rest camp")


func test_reset_clears_search_state() -> void:
	_make_camp()
	_camp.build(_view(), _merchant())
	_camp._left_search = "sword"
	_camp._inventory_search = "potion"
	_camp.reset()
	assert_eq(_camp._left_search, "", "phase reset clears the left search")
	assert_eq(_camp._inventory_search, "", "phase reset clears the inventory search")
