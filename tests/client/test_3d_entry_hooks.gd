extends TestCase


func test_title_home_hook_is_opt_in_and_story_station_opens_existing_screen() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app.options = {"3d": true}
	var title := TitleScreen.new()
	title.setup(app)
	title._open_play()
	assert_eq(title._view, "home3d")
	assert_true(title._home3d is Home3D)
	title._home3d.teleport(title._home3d.station_position("story"))
	assert_true(title._home3d.activate_nearest_station())
	assert_eq(title._view, "play")
	assert_true(title._content != null)
	title.free()
	app.free()

	app = ClientApp.new()
	app.settings = ClientSettings.new()
	app.options = {}
	title = TitleScreen.new()
	title.setup(app)
	title._open_play()
	assert_eq(title._view, "play")
	assert_eq(title._home3d, null)
	title.free()
	app.free()


func test_battle_stage_hook_is_opt_in() -> void:
	for enabled in [false, true]:
		var app := ClientApp.new()
		app.settings = ClientSettings.new()
		app.options = {"3d": true} if enabled else {}
		var screen := MatchScreen.new()
		screen.app = app
		screen.anchors = {}
		var battle := BattleView.new()
		battle.setup(screen, app)
		assert_eq(battle._use_3d, enabled)
		assert_eq(battle._stage is Battle3DStage, enabled)
		assert_eq(battle._backdrop.visible, not enabled)
		battle.free()
		screen.free()
		app.free()
