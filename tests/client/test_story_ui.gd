extends "res://tests/test_case.gd"

const VotePanel = preload("res://src/client/match/vote_panel.gd")
const ClassPanel = preload("res://src/client/match/class_panel.gd")

class ToastProbeApp extends ClientApp:
	var last_toast := ""
	var last_toast_seconds := 0.0
	func toast(message: String, seconds: float = 4.0) -> void:
		last_toast = message
		last_toast_seconds = seconds

func _has_text(node: Node, wanted: String) -> bool:
	if node is Label and str(node.text).contains(wanted):
		return true
	if node is Button and str(node.text).contains(wanted):
		return true
	for child in node.get_children():
		if _has_text(child, wanted):
			return true
	return false


func _ui_app() -> ClientApp:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app._overlay_holder = Control.new()
	app.add_child(app._overlay_holder)
	return app


func _vote_view(story: bool) -> Dictionary:
	return {
		"story": story,
		"layers_total": 5,
		"party": [],
		"vote": {"layer": 1, "deadline": -1.0, "voted_slots": [], "options": [
			{"index": 0, "type": "combat", "name": "Trail", "hint": "A fight", "voters": []}
		]}
	}


func test_story_path_choice_hides_vote_status_and_multiplayer_keeps_it() -> void:
	var app := ClientApp.new()
	app.settings = ClientSettings.new()
	app._overlay_holder = Control.new()
	app.add_child(app._overlay_holder)
	var screen := MatchScreen.new()
	screen.app = app
	app.snapshot = {"room": {"your_slot": 0, "slots": []}, "match": {"story": true, "layer": 1}}
	var story := VotePanel.new()
	story.build(screen, app, _vote_view(true))
	assert_true(_has_text(story, "Choose your path"))
	assert_false(_has_text(story, "Ready "), "Story hides multiplayer vote status")
	assert_false(_has_text(story, "Votes:"), "Story hides vote tallies")
	assert_false(_has_text(story, "Vote for this path"), "Story uses choice labels")
	assert_true(_has_text(story, "Choose this path"), "Story uses choice labels")
	app.snapshot["match"]["story"] = false
	var multi := VotePanel.new()
	multi.build(screen, app, _vote_view(false))
	assert_true(_has_text(multi, "Ready "), "Multiplayer keeps vote status")
	assert_true(_has_text(multi, "Votes:"), "Multiplayer keeps vote tallies")
	assert_true(_has_text(multi, "Vote for this path"), "Multiplayer keeps vote labels")
	story.free()
	multi.free()
	screen.free()
	app.free()


func _class_view(deadline: float) -> Dictionary:
	return {
		"encounter": {
			"stage": "offer",
			"outcome_text": "The trial is complete.",
			"class_info": {
				"name": "Scout", "role": "Ranger", "description": "A swift pathfinder.",
				"stats": {"max_hp": 20, "atk": 4, "def": 3, "mag": 2, "res": 2, "spd": 6},
				"skills": []
			},
			"offer": {"you_can_decide": true, "eligible": [0], "decisions": {}, "deadline": deadline}
		}
	}


func test_class_offer_copy_matches_timed_and_story_deadlines() -> void:
	var app := _ui_app()
	var screen := MatchScreen.new()
	screen.app = app
	app.snapshot = {"room": {"your_slot": 0, "slots": []}}
	var story_offer := ClassPanel.new()
	story_offer.build(screen, app, _class_view(-1.0))
	story_offer.tick(screen, app)
	assert_false(_has_text(story_offer, "Offer closes"), "Story class offers have no countdown")
	assert_false(_has_text(story_offer, "Silence counts as declining"), "Story class offers omit timed-deadline copy")
	story_offer.free()

	var timed_offer := ClassPanel.new()
	timed_offer.build(screen, app, _class_view(1000000.0))
	timed_offer.tick(screen, app)
	assert_true(_has_text(timed_offer, "Offer closes"), "Timed class offers keep countdown")
	assert_true(_has_text(timed_offer, "Silence counts as declining"), "Timed class offers keep deadline copy")
	timed_offer.free()
	screen.free()
	app.free()


func _party_view(story: bool) -> Dictionary:
	return {
		"story": story,
		"party": [{
			"slot": 0, "name": "Alice", "level": 1, "class_name": "Classless", "controller": "human",
			"hp": 10, "max_hp": 10, "atk": 1, "def": 1, "mag": 1, "res": 1, "spd": 1, "exp": 0
		}]
	}


func test_story_party_cards_hide_player_badge_and_owner() -> void:
	var app := _ui_app()
	app.snapshot = {"room": {"story": true, "your_slot": 0, "slots": [{"owner_name": "Owner Name"}]}}
	var story_screen := MatchScreen.new()
	story_screen.app = app
	story_screen._party = UiKit.vbox(6)
	story_screen.add_child(story_screen._party)
	story_screen._build_party(_party_view(true))
	assert_false(_has_text(story_screen._party, "PLAYER"), "Story hides controller badge")
	assert_false(_has_text(story_screen._party, "Owner Name"), "Story hides owner name")
	story_screen.free()

	app.snapshot = {"room": {"story": false, "your_slot": 0, "slots": [{"owner_name": "Owner Name"}]}}
	var multi_screen := MatchScreen.new()
	multi_screen.app = app
	multi_screen._party = UiKit.vbox(6)
	multi_screen.add_child(multi_screen._party)
	multi_screen._build_party(_party_view(false))
	assert_true(_has_text(multi_screen._party, "PLAYER"), "Multiplayer keeps controller badge")
	assert_true(_has_text(multi_screen._party, "Owner Name"), "Multiplayer keeps owner name")
	multi_screen.free()
	app.free()


func test_story_panel_stays_hidden_after_forced_refresh() -> void:
	var app := _ui_app()
	app.settings.reduced_motion = true
	app.snapshot = {
		"room": {"story": true, "your_slot": 0, "slots": []},
		"match": {"story": true, "phase": "voting", "layer": 1, "layers_total": 5,
			"clues": [], "party": [], "vote": {"layer": 1, "deadline": -1.0, "voted_slots": [], "options": []}}
	}
	var screen := MatchScreen.new()
	app.add_child(screen)
	screen.app = app
	screen._top = UiKit.flow(4)
	screen._party = UiKit.vbox(4)
	screen._center_scroll = ScrollContainer.new()
	screen._center = MarginContainer.new()
	screen.add_child(screen._top)
	screen.add_child(screen._party)
	screen.add_child(screen._center)
	screen._story_director = StoryDirector.new()
	screen._story_director.current = Control.new()
	screen.refresh(app, true)
	assert_false(screen._panel.visible, "Story presentation keeps the rebuilt panel hidden")
	screen._story_director.current.free()
	screen._story_director.free()
	app.free()


func test_story_log_hides_join_and_host_lines() -> void:
	var app := _ui_app()
	app.snapshot = {"room": {"story": true}}
	var screen := MatchScreen.new()
	screen.app = app
	assert_eq(screen.describe({"type": "player_joined", "name": "Traveller", "slot": 0}), "")
	assert_eq(screen.describe({"type": "host_changed", "name": "Traveller"}), "")
	app.snapshot = {"room": {"story": false}}
	assert_eq(screen.describe({"type": "player_joined", "name": "Traveller", "slot": 0}), "Traveller joined (slot 1).")
	assert_eq(screen.describe({"type": "host_changed", "name": "Traveller"}), "Traveller is now the Host.")
	screen.free()
	app.free()


func test_story_title_explains_isolated_profile_policy() -> void:
	var app := _ui_app()
	var title := TitleScreen.new()
	app.add_child(title)
	title._app = app
	title._show_play()
	assert_true(_has_text(title, "Human only"))
	assert_true(_has_text(title, "no online Races, Boons, or class-tree bonuses"))
	app.free()


func test_lobby_shows_profile_unavailable_notice() -> void:
	var app := ToastProbeApp.new()
	var lobby := LobbyScreen.new()
	lobby.show_events(app, [{"type": "profile_unavailable"}])
	assert_eq(app.last_toast, UiText.error("profile_unavailable"))
	assert_eq(app.last_toast_seconds, 6.0)
	lobby.free()
	app.free()
