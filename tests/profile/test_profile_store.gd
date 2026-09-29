extends TestCase

class RetryHttpSender extends HttpProfileSender:
	var attempts := 0
	func _perform(_method: String, _url: String, _headers: Dictionary, _body: String) -> Dictionary:
		attempts += 1
		return {"status": 500 if attempts == 1 else 204, "body": null}

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


func test_d1_store_uses_async_sender_and_newest_queued_payload() -> void:
	var sender := FakeSender.new()
	var store := D1ProfileStore.new("https://profiles.example", "secret", sender)
	store.save_profile_async("token", {"gems": 1})
	store.save_profile_async("token", {"gems": 8})
	assert_eq(sender.calls.size(), 2)
	assert_eq(JSON.parse_string(sender.calls[1]["body"])["gems"], 8)
	assert_eq(JSON.parse_string(sender.calls[1]["body"])["version"], 2)


func test_http_sender_retries_failed_save_then_succeeds() -> void:
	var sender := RetryHttpSender.new()
	sender.enqueue_save("https://profiles.example/profiles/token", {}, "{}")
	var deadline := Time.get_ticks_msec() + 3000
	while sender.attempts < 2 and Time.get_ticks_msec() < deadline:
		OS.delay_msec(10)
	sender.stop()
	assert_eq(sender.attempts, 2)


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
