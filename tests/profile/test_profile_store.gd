extends TestCase

class RetryHttpSender extends HttpProfileSender:
	var attempts := 0
	func _perform(_method: String, _url: String, _headers: Dictionary, _body: String) -> Dictionary:
		attempts += 1
		return {"status": 500 if attempts == 1 else 204, "body": null}

class ConflictHttpSender extends HttpProfileSender:
	var attempts := 0
	func _perform(_method: String, _url: String, _headers: Dictionary, _body: String) -> Dictionary:
		attempts += 1
		return {"status": 409, "body": null}

class DrainHttpSender extends HttpProfileSender:
	var saved_urls: Array[String] = []
	func _perform(_method: String, url: String, _headers: Dictionary, _body: String) -> Dictionary:
		saved_urls.append(url)
		return {"status": 204, "body": null}

class FailureStore extends ProfileStore:
	var failures: Array[Dictionary] = []
	func take_save_failures() -> Array[Dictionary]:
		var out := failures.duplicate(true)
		failures.clear()
		return out

class ManualSender extends RefCounted:
	var calls: Array[Dictionary] = []
	var results: Array[Dictionary] = []
	func enqueue_save_with_context(url: String, _headers: Dictionary, body: String, session_id: int) -> void:
		calls.append({"url": url, "body": body, "session_id": session_id})
	func take_save_results() -> Array[Dictionary]:
		var out := results.duplicate(true)
		results.clear()
		return out
	func finish_call(index: int, status: int) -> void:
		results.append({"url": calls[index]["url"], "status": status,
			"session_id": calls[index]["session_id"]})

class FakeSender extends RefCounted:
	var calls: Array = []
	var responses: Array = []
	func request(method: String, url: String, headers: Dictionary, body: String) -> Dictionary:
		calls.append({"method": method, "url": url, "headers": headers, "body": body})
		return responses.pop_front() if not responses.is_empty() else {"status": 200, "body": {"gems": 17, "races_owned": ["Human"]}}
	func enqueue_save(url: String, headers: Dictionary, body: String) -> void:
		calls.append({"method": "PUT", "url": url, "headers": headers, "body": body})


func test_memory_store_normalizes_and_round_trips() -> void:
	var store := MemoryProfileStore.new()
	store.save_profile("a", {"gems": 7, "class_trees": {"assassin": {"might": 2}}})
	var profile := store.load_profile("a")
	assert_eq(profile["gems"], 7)
	assert_true(profile["races_owned"].has("Human"))
	assert_eq(profile["class_trees"]["assassin"]["might"], 2)


func test_file_store_round_trip_in_a_temp_directory() -> void:
	var directory := "user://t5-profile-store-test"
	var store := FileProfileStore.new(directory)
	store.save_profile("0123456789abcdef0123456789abcdef", {"gems": 23, "prestige": {"mage": 2}})
	var loaded := FileProfileStore.new(directory).load_profile("0123456789abcdef0123456789abcdef")
	assert_eq(loaded["gems"], 23)
	assert_eq(loaded["prestige"]["mage"], 2)


func test_d1_store_builds_authenticated_get_and_put_requests() -> void:
	var sender := FakeSender.new()
	var store := D1ProfileStore.new("https://profiles.example/", "secret", sender)
	var token := "abcdefabcdefabcdefabcdefabcdefab"
	var loaded := store.load_profile(token)
	store.save_profile(token, {"gems": 9})
	assert_eq(loaded["gems"], 17)
	assert_eq(sender.calls.size(), 2)
	assert_eq(sender.calls[0]["method"], "GET")
	assert_eq(sender.calls[0]["url"], "https://profiles.example/profiles/" + token)
	assert_eq(sender.calls[0]["headers"]["Authorization"], "Bearer secret")
	assert_eq(sender.calls[1]["method"], "PUT")
	assert_eq(sender.calls[1]["headers"]["Content-Type"], "application/json")
	assert_eq(JSON.parse_string(sender.calls[1]["body"])["gems"], 9)
	assert_eq(JSON.parse_string(sender.calls[1]["body"])["version"], 1)


func test_game_server_configure_builds_d1_store_with_http_sender() -> void:
	var game_server := GameServer.new()
	game_server.configure({"seed": 1, "profile-url": "https://profiles.example", "profile-secret": "secret"})
	assert_true(game_server.profile_store is D1ProfileStore)
	assert_true(game_server.profile_store.sender is HttpProfileSender)
	game_server.profile_store.sender.stop()
	game_server.free()


func test_d1_store_handles_missing_and_unavailable_profiles_safely() -> void:
	var sender := FakeSender.new()
	var store := D1ProfileStore.new("https://profiles.example", "secret", sender)
	sender.responses.append({"status": 404, "body": null})
	assert_false(store.load_profile("token").has("_unavailable"))
	sender.responses.append({"status": 500, "body": {"error": "down"}})
	var unavailable := store.load_profile("token")
	assert_true(unavailable["_unavailable"])
	store.save_profile_async("token", unavailable)
	store.save_profile("token", unavailable)
	assert_eq(sender.calls.size(), 2)


func test_d1_store_advances_one_loaded_profile_across_saves() -> void:
	var sender := FakeSender.new()
	var store := D1ProfileStore.new("https://profiles.example", "secret", sender)
	var profile := {"gems": 1, "version": 0}
	store.save_profile_async("token", profile)
	profile["gems"] = 8
	store.save_profile_async("token", profile)
	assert_eq(sender.calls.size(), 2)
	assert_eq(JSON.parse_string(sender.calls[1]["body"])["gems"], 8)
	assert_eq(JSON.parse_string(sender.calls[1]["body"])["version"], 2)


func test_d1_sessions_keep_their_loaded_base_version() -> void:
	var sender := FakeSender.new()
	var store := D1ProfileStore.new("https://profiles.example", "secret", sender)
	var first := store.load_profile("same-token")
	var second := store.load_profile("same-token")
	first["version"] = 5
	second["version"] = 5
	store.save_profile_async("same-token", first)
	store.save_profile_async("same-token", second)
	assert_eq(JSON.parse_string(sender.calls[2]["body"])["version"], 6)
	assert_eq(JSON.parse_string(sender.calls[3]["body"])["version"], 6)


func test_d1_serializes_one_sessions_saves_and_stops_after_conflict() -> void:
	var sender := ManualSender.new()
	var store := D1ProfileStore.new("https://profiles.example", "secret", sender)
	var profile := {"version": 5, "gems": 1}
	store.save_profile_async("token", profile, 12)
	profile["gems"] = 8
	store.save_profile_async("token", profile, 12)
	assert_eq(sender.calls.size(), 1)
	sender.finish_call(0, 204)
	assert_eq(store.take_save_failures().size(), 0)
	assert_eq(sender.calls.size(), 2)
	assert_eq(JSON.parse_string(sender.calls[1]["body"])["version"], 7)
	assert_eq(JSON.parse_string(sender.calls[1]["body"])["gems"], 8)
	sender.finish_call(1, 409)
	var failures := store.take_save_failures()
	assert_eq(failures.size(), 1)
	assert_eq(failures[0]["session_id"], 12)
	store.save_profile_async("token", profile, 12)
	assert_eq(sender.calls.size(), 2)


func test_http_sender_retries_failed_save_then_succeeds() -> void:
	var sender := RetryHttpSender.new()
	sender.enqueue_save("https://profiles.example/profiles/token", {}, "{}")
	var deadline := Time.get_ticks_msec() + 3000
	while sender.attempts < 2 and Time.get_ticks_msec() < deadline:
		OS.delay_msec(10)
	sender.stop()
	assert_eq(sender.attempts, 2)


func test_http_sender_does_not_retry_conflict() -> void:
	var sender := ConflictHttpSender.new()
	sender.enqueue_save_with_context("https://profiles.example/profiles/token", {}, "{}", 7)
	sender.stop()
	assert_eq(sender.attempts, 1)
	var failures := sender.take_save_results()
	assert_eq(failures.size(), 1)
	assert_eq(failures[0]["status"], 409)
	assert_eq(failures[0]["session_id"], 7)


func test_http_sender_drains_queued_saves_on_stop() -> void:
	var sender := DrainHttpSender.new()
	sender.enqueue_save("https://profiles.example/profiles/a", {}, "{}")
	sender.enqueue_save("https://profiles.example/profiles/b", {}, "{}")
	sender.stop()
	assert_eq(sender.saved_urls.size(), 2)


func test_match_server_delivers_save_failure_to_owning_session() -> void:
	var store := FailureStore.new()
	var server := MatchServer.new(GameRng.new(1), SystemClock.new(), ForestContent.load_default(), store)
	var owner := server.open_session()
	var other := server.open_session()
	server._sessions[owner]["token"] = "same-token"
	server._sessions[other]["token"] = "same-token"
	store.failures.append({"token": "same-token", "status": 409, "session_id": owner})
	server.update()
	assert_eq(server.take_events(owner)[0]["type"], "profile_save_failed")
	assert_eq(server.take_events(other).size(), 0)


func test_legacy_rogue_profile_keys_migrate_to_assassin() -> void:
	var normalized := ProfileStore.normalize({
		"class_trees": {"rogue": {"might": 2}},
		"prestige": {"rogue": 3},
		"last_loadout": {"class": "rogue", "race": "Elf"},
	})
	assert_eq(normalized["class_trees"]["assassin"]["might"], 2)
	assert_false(normalized["class_trees"].has("rogue"))
	assert_eq(normalized["prestige"]["assassin"], 3)
	assert_eq(normalized["last_loadout"]["class"], "assassin")
