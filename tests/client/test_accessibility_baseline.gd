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


func test_enemy_weakness_stays_available_in_token_tooltip() -> void:
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
	assert_false(_has_text(battle._timeline, "Weak: fire"), "party column contains only party members")
	assert_true(battle._tokens["e0"].tooltip_text.contains("Weak to: fire"), "enemy weakness remains in tooltip")
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


func test_battle_timeline_starts_clear_of_corner_controls() -> void:
	var battle := _battle()
	var timeline := battle._timeline_scroll.get_parent() as Control
	assert_true(timeline.offset_left >= 0.0 and timeline.custom_minimum_size.x >= 200.0,
			"initiative list remains in its own left lane")
	assert_true(timeline.offset_left + timeline.custom_minimum_size.x < 1280.0 - 96.0,
			"initiative list ends before the top-right corner controls")
	battle._combat = {"round": 2, "round_order": [], "turn_order": []}
	battle._build_timeline({})
	assert_eq((battle._turn_banner.get_child(0) as Label).text, Tr.t("Turn 2"),
			"the turn title stays in its fixed banner outside the scrolling cards")

func test_primary_battle_actions_are_keyboard_focusable() -> void:
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
		"actor": "p0", "round": 1, "your_turn": true, "deadline": -1,
		"round_order": ["p0", "e0"], "turn_order": ["p0", "e0"],
		"choices": {"focus": true, "skills": {"slash": {"name": "Slash", "energy": 1,
			"cooldown": 0, "affordable": true, "targets": ["e0"]}}, "items": {"potion": {}}},
		"enemies": [{"id": "e0", "name": "Grey Wolf", "kind": "grey_wolf", "row": "front",
			"hp": 12, "max_hp": 12, "spd": 13}],
	}
	battle.build(view, combat)
	var found := {}
	for button in _buttons(battle):
		found[str(button.get_meta("focus_id", ""))] = button.focus_mode
	assert_eq(found.get("action_fight", Control.FOCUS_NONE), Control.FOCUS_ALL, "Fight is keyboard focusable")
	assert_eq(found.get("action_items", Control.FOCUS_NONE), Control.FOCUS_ALL, "Items is keyboard focusable")
	assert_eq(found.get("action_focus", Control.FOCUS_NONE), Control.FOCUS_ALL, "Focus is keyboard focusable")
	battle.theme = UiKit.make_theme(1.0)
	var focus_button: Button = null
	for button in _buttons(battle):
		if str(button.get_meta("focus_id", "")) == "action_fight":
			focus_button = button
			break
	assert_true(focus_button != null, "Battle Fight control exists for focus verification")
	if focus_button != null:
		assert_true(focus_button.get_theme_stylebox("focus") != null, "Battle focus has the visible gold theme style")
	var screen: MatchScreen = battle._screen
	var app: ClientApp = battle._app
	battle.free()
	screen.free()
	app.free()


func test_summary_keeps_one_outcome_heading_and_hides_timeline() -> void:
	var battle := _battle()
	battle._combat = {"result": "victory", "trial": false, "rewards": {}}
	battle._build_result()
	assert_eq(battle._center_text.text, "Victory!", "summary has one victory heading")
	assert_false(battle._timeline.visible, "turn order is hidden in summary")

func test_merchant_and_rest_primary_actions_are_keyboard_focusable() -> void:
	_make_camp()
	_camp.build(_view(), _merchant())
	var merchant_ids := {}
	for button in _buttons(_camp):
		merchant_ids[str(button.get_meta("focus_id", ""))] = button.focus_mode
	assert_eq(merchant_ids.get("buy_bread", Control.FOCUS_NONE), Control.FOCUS_ALL, "Buy is keyboard focusable")
	assert_eq(merchant_ids.get("ready", Control.FOCUS_NONE), Control.FOCUS_ALL, "Merchant Ready is keyboard focusable")
	var rest := {
		"kind": "rest", "name": "Camp", "you_are_ready": false, "ready": [], "humans": 1,
		"recipes": [{"recipe": "patch", "name": "Patch Up", "category": "Care", "craftable": true,
			"materials": []}],
	}
	_app.settings.text_scale = 1.4
	_camp.build(_view(), rest)
	var rest_ids := {}
	for button in _buttons(_camp):
		rest_ids[str(button.get_meta("focus_id", ""))] = button.focus_mode
	assert_eq(rest_ids.get("craft_patch", Control.FOCUS_NONE), Control.FOCUS_ALL, "Craft is keyboard focusable")
	assert_eq(rest_ids.get("ready", Control.FOCUS_NONE), Control.FOCUS_ALL, "Rest Ready is keyboard focusable")
	_camp.theme = UiKit.make_theme(1.4)
	var ready_button: Button = null
	for button in _buttons(_camp):
		if str(button.get_meta("focus_id", "")) == "ready":
			ready_button = button
			break
	assert_true(ready_button != null, "camp Ready control exists for focus verification")
	if ready_button != null:
		assert_true(ready_button.get_theme_stylebox("focus") != null, "camp focus has the visible gold theme style")


func test_reduced_motion_keeps_action_announcement_visible() -> void:
	var battle := _battle()
	battle._app.settings.reduced_motion = true
	battle.announce("Alice attacks Grey Wolf")
	assert_true(battle._banner.visible, "reduced motion leaves the action banner visible")
	assert_eq(battle._banner_label.text, "Alice attacks Grey Wolf", "the action result stays readable")
	var screen: MatchScreen = battle._screen
	var app: ClientApp = battle._app
	battle.free()
	screen.free()
	app.free()


func test_reduced_motion_applies_hp_change_without_a_tween() -> void:
	var token := BattleToken.new()
	var data := {"id": "p0", "side": "party", "name": "Alice", "kind": "classless",
		"hp": 20, "max_hp": 30, "energy": 3, "energy_max": 6, "statuses": [], "reduced_motion": true}
	token.setup(data)
	data["hp"] = 10
	token.update_data(data)
	assert_eq(token._hp_bar.value, 10.0, "reduced motion applies the HP update immediately without a tween")
	token.free()


func test_combat_ended_keeps_final_reduced_motion_hit_bars() -> void:
	var battle := _battle()
	var screen: MatchScreen = battle._screen
	var app: ClientApp = battle._app
	screen._battle = battle
	screen._battle_mode = true
	screen._log = RichTextLabel.new()
	screen.add_child(screen._log)
	var token := BattleToken.new()
	var data := {"id": "p0", "side": "party", "name": "Alice", "kind": "classless",
		"hp": 20, "max_hp": 30, "energy": 3, "energy_max": 6, "statuses": [], "reduced_motion": true}
	token.setup(data)
	data["hp"] = 10
	data["energy"] = 2
	token.update_data(data)
	battle._tokens["p0"] = token
	screen.show_events(app, [{"type": "combat_ended", "result": "victory", "rewards": {}}])
	assert_eq([token._hp_bar.value, token._energy_bar.value], [10.0, 2.0],
			"combat_ended keeps the final HP/Energy snapshot visible")
	token.free()
	battle.free()
	screen.free()
	app.free()


func test_summary_clears_floating_combat_feedback() -> void:
	var battle := _battle()
	var screen: MatchScreen = battle._screen
	var app: ClientApp = battle._app
	var number := Label.new()
	screen.add_child(number)
	number.add_to_group("combat_floating_text")
	screen._floating_numbers.append(number)
	screen._float_busy_until["e0"] = Time.get_ticks_msec() + 1000
	var generation_before := screen._float_generation
	screen._clear_floating_numbers()
	assert_true(number.is_queued_for_deletion(), "summary removes any number still over the party panel")
	assert_eq(screen._float_busy_until, {}, "summary clears scheduled numbers so nothing appears afterward")
	assert_eq(screen._float_generation, generation_before + 1, "summary invalidates floating calls already waiting on their queue")
	battle._banner.visible = true
	battle._combat = {"result": "victory", "trial": false, "rewards": {}}
	battle._build_result()
	assert_false(battle._banner.visible, "summary removes the action banner")
	battle.free()
	screen.free()
	app.free()
