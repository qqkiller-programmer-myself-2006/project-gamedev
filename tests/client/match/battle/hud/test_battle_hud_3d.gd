extends TestCase
## Focused layout and state checks for the optional Battle3D HUD.

var _pressed_commands: Array[String] = []

func test_command_fan_has_five_commands_and_selects_the_current_action() -> void:
	var hud := BattleHud3D.new()
	hud.size = Vector2(1280, 720)
	hud.render(_view(), _combat(), _party(), "skills", [], "", "12s", 1.4, {})
	var buttons: Array[Node] = hud.find_children("*", "Button", true, false)
	assert_eq(buttons.size(), 6, "Five commands and disabled Auto placeholder")
	var skill_button: Button = hud._fan[1]
	assert_true(skill_button.custom_minimum_size.x > hud._fan[0].custom_minimum_size.x,
		"selected Skill grows beyond an inactive command")
	assert_eq(hud._fan_backgrounds[1].color, UiKit.BATTLE_RED)
	assert_eq(hud._fan_backgrounds[0].color, UiKit.BATTLE_DARK)
	hud.set_countdown("3s", true)
	assert_eq(hud._countdown.text, "3s", "countdown updates without rebuilding HUD controls")
	hud.free()


func test_unavailable_commands_are_disabled_and_have_explanations() -> void:
	var hud := BattleHud3D.new()
	hud.size = Vector2(1920, 1080)
	var combat := _combat()
	combat["choices"]["focus"] = false
	combat["choices"]["items"] = {}
	hud.render(_view(), combat, _party(), "", [], "", "", 1.4, {})
	assert_true(hud._fan[2].disabled, "Focus is disabled when the combat snapshot disallows it")
	assert_true(hud._fan[3].disabled, "Item is disabled when none are available")
	assert_true(hud._fan[2].tooltip_text.length() > 10, "unavailable command explains its state")
	hud.free()


func test_every_command_button_routes_to_its_action() -> void:
	_pressed_commands.clear()
	var callbacks := {
		"strike": Callable(self, "_record_command").bind("strike"),
		"skill": Callable(self, "_record_command").bind("skill"),
		"focus": Callable(self, "_record_command").bind("focus"),
		"item": Callable(self, "_record_command").bind("item"),
		"guard": Callable(self, "_record_command").bind("guard"),
	}
	var hud := BattleHud3D.new()
	hud.render(_view(), _combat(), _party(), "", [], "", "15s", 1.0, callbacks)
	for button in hud._fan:
		button.emit_signal("pressed")
	assert_eq(_pressed_commands, ["strike", "skill", "focus", "item", "guard"])
	hud.free()


func test_party_and_target_panels_render_health_energy_and_status() -> void:
	var hud := BattleHud3D.new()
	hud.size = Vector2(1280, 720)
	var party := _party()
	party[0]["statuses"] = [{"name": "Poison"}]
	hud.render(_view(), _combat(), party, "attack", ["e0"], "e0", "15s", 1.4, {})
	var panels: Array[Node] = hud.find_children("*", "PanelContainer", true, false)
	assert_true(panels.size() >= 5, "target, turn order and party status are visible panels")
	assert_eq(hud._fan.size(), 5)
	assert_eq(hud._selected_command, 0)
	var labels: Array[Node] = hud.find_children("*", "Label", true, false)
	var saw_status := false
	for label in labels:
		if (label as Label).text.contains("Poison"):
			saw_status = true
	assert_true(saw_status, "status effects appear on the matching Party plate")
	var energy_bars := hud.find_children("*", "ProgressBar", true, false)
	assert_true(energy_bars.size() >= 2, "party plates display HP and Energy bars")
	hud.free()


func _view() -> Dictionary:
	return {"party": _party()}


func _party() -> Array:
	return [{"slot": 0, "name": "Aya", "class": "assassin", "hp": 12, "max_hp": 20,
		"energy": 1, "energy_max": 6}]


func _combat() -> Dictionary:
	return {"actor": "p0", "your_turn": true, "turn_order": ["p0", "e0"],
		"enemies": [{"id": "e0", "name": "Wolf", "hp": 8, "max_hp": 10}],
		"choices": {"attack": {"targets": ["e0"]}, "skills": {"slash": {}}, "focus": true,
			"items": {"tonic": {}}}}


func _record_command(action: String) -> void:
	_pressed_commands.append(action)
