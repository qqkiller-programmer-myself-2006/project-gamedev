extends TestCase
## Issue #44 accessibility baseline: important item, status and action state
## must be visible text, not hover-only tooltips.
##
## - Camp shop Buy buttons say "Buy" / "Need X Gold" / "Sold out".
## - Camp recipe rows list materials as have/need with OK/NEED words.
## - Battle status badges show turns left when there is room.
## - The battle timeline shows enemy weakness as text.
## - Buy/Craft/Ready buttons keep stable focus_ids for focus restore.


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


func after_each() -> void:
	if _camp != null and is_instance_valid(_camp):
		_camp.free()
	_camp = null
	if _screen != null and is_instance_valid(_screen):
		_screen.free()
	_screen = null
	if _app != null and is_instance_valid(_app):
		_app.free()
	_app = null


func _make_camp() -> void:
	_app = ClientApp.new()
	_app.settings = ClientSettings.new()
	_app.sounds = SoundBank.new()
	_app._overlay_holder = Control.new()
	_app.add_child(_app._overlay_holder)
	_app.connection = StubConnection.new()
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
		"inventory": [],
	}


func _merchant() -> Dictionary:
	return {
		"kind": "merchant", "name": "Mar", "you_are_ready": false, "ready": [], "humans": 1,
		"stock": [
			{"item": "bread", "name": "Bread", "price": 5, "remaining": 3, "affordable": true},
			{"item": "sword", "name": "Sword", "price": 500, "remaining": 2, "affordable": false},
			{"item": "relic", "name": "Relic", "price": 50, "remaining": 0, "affordable": true},
		],
	}


func _buttons(node: Node) -> Array:
	var out: Array = []
	_collect_buttons(node, out)
	return out


func _collect_buttons(node: Node, out: Array) -> void:
	if node is Button:
		out.append(node)
	for child in node.get_children():
		_collect_buttons(child, out)


func _has_text(node: Node, wanted: String) -> bool:
	if node is Label and str((node as Label).text).contains(wanted):
		return true
	if node is Button and str((node as Button).text).contains(wanted):
		return true
	for child in node.get_children():
		if _has_text(child, wanted):
			return true
	return false


func test_shop_buttons_state_visible_text() -> void:
	_make_camp()
	_camp.build(_view(), _merchant())
	assert_true(_has_text(_camp, "Buy"), "affordable stock keeps a Buy button")
	assert_true(_has_text(_camp, "Need 500 Gold"), "unaffordable stock says Need 500 Gold in the button")
	assert_true(_has_text(_camp, "Sold out"), "empty stock says Sold out in the button")


func test_shop_buttons_keep_focus_ids() -> void:
	_make_camp()
	_camp.build(_view(), _merchant())
	var ids: Array[String] = []
	for button in _buttons(_camp):
		if str(button.get_meta("focus_id", "")).begins_with("buy_"):
			ids.append(str(button.get_meta("focus_id")))
	ids.sort()
	assert_eq(ids, ["buy_bread", "buy_relic", "buy_sword"], "every stock entry keeps a stable buy focus_id")


func test_recipe_materials_visible_with_ok_need() -> void:
	_make_camp()
	var encounter := {
		"kind": "rest", "name": "Camp", "you_are_ready": false, "ready": [], "humans": 1,
		"recipes": [
			{"recipe": "patch", "name": "Patch Up", "category": "Care", "craftable": false,
				"materials": [
					{"item": "herb", "name": "Herb", "need": 2, "have": 1},
					{"item": "cloth", "name": "Cloth", "need": 1, "have": 3},
				]},
		],
	}
	_camp.build(_view(), encounter)
	assert_true(_has_text(_camp, "1/2 Herb NEED"), "missing material shows have/need with NEED")
	assert_true(_has_text(_camp, "3/1 Cloth OK"), "covered material shows have/need with OK")


func test_status_badge_shows_turns_when_not_compact() -> void:
	var token := BattleToken.new()
	token.text_scale = 1.0
	token.setup({
		"id": "p0", "side": "party", "name": "Alice", "kind": "classless",
		"hp": 10, "max_hp": 10, "statuses": [
			{"status": "bleed", "name": "Bleed", "stacks": 2, "turns": 3, "kind": "dot", "color": "#e05a4f"},
		], "acting": false,
	})
	assert_true(_has_text(token, "x2 3t"), "badge shows stacks and turns left as text")
	assert_true(_has_text(token, "BLD"), "badge keeps the status tag")
	token.free()


func test_status_badge_compact_keeps_turns_in_tooltip() -> void:
	var token := BattleToken.new()
	token.text_scale = 1.0
	var statuses: Array = []
	for i in 4:
		statuses.append({"status": "bleed", "name": "Bleed", "stacks": 1, "turns": 2,
				"kind": "dot", "color": "#e05a4f"})
	token.setup({
		"id": "p0", "side": "party", "name": "Alice", "kind": "classless",
		"hp": 10, "max_hp": 10, "statuses": statuses, "acting": false,
	})
	var saw_tooltip := false
	for badge in token._badges.get_children():
		if str(badge.tooltip_text).contains("turn(s) left"):
			saw_tooltip = true
	assert_true(saw_tooltip, "compact badges keep turns left in the tooltip")
	token.free()


func _battle(scale := 1.0) -> BattleView:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app.settings.text_scale = scale
	app.sounds = SoundBank.new()
	app._overlay_holder = Control.new()
	app.add_child(app._overlay_holder)
	app.snapshot = {"room": {"your_slot": 0, "story": false, "slots": []}, "match": {"story": false}}
	var screen := MatchScreen.new()
	screen.app = app
	var battle := BattleView.new()
	battle.setup(screen, app)
	return battle


func test_timeline_shows_weakness_as_text() -> void:
	var battle := _battle()
	var view := {
		"layer": 1, "layers_total": 5, "gold": 0, "story": false,
		"phase": "combat",
		"encounter": {"kind": "combat", "name": "Wolves"},
		"party": [{
			"slot": 0, "name": "Alice", "class": "classless", "class_name": "Classless",
			"level": 1, "hp": 10, "max_hp": 10, "atk": 3, "def": 1, "mag": 1, "res": 1,
			"spd": 10, "exp": 0, "exp_next": 20, "controller": "human",
		}],
	}
	var combat := {
		"actor": "", "round": 1, "your_turn": false,
		"round_order": ["p0", "e0"], "turn_order": ["p0", "e0"],
		"enemies": [{
			"id": "e0", "name": "Grey Wolf", "kind": "grey_wolf", "row": "front",
			"hp": 12, "max_hp": 12, "spd": 13, "weakness": ["fire"],
			"description": "A hungry wolf.",
		}],
	}
	battle.build(view, combat)
	assert_true(_has_text(battle._timeline, "Weak: fire"), "timeline shows enemy weakness as text")
	var screen: MatchScreen = battle._screen
	var app: ClientApp = battle._app
	battle.free()
	screen.free()
	app.free()


func test_combat_log_dock_grows_right_at_large_scale() -> void:
	var battle := _battle(1.45)
	battle.add_log("Bram attacks Wolf A takes 14.")
	var dock := battle._log.get_parent() as Control
	assert_eq(dock.grow_horizontal, Control.GROW_DIRECTION_END,
			"combat log dock must grow right so large text cannot slide off the left edge")
	assert_true(dock.offset_left >= 0.0, "combat log dock stays inside the left edge")
	var screen: MatchScreen = battle._screen
	var app: ClientApp = battle._app
	battle.free()
	screen.free()
	app.free()
