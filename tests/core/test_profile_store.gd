extends TestCase

class FakeSender extends RefCounted:
	var calls: Array = []
	func request(method: String, url: String, headers: Dictionary, body: String) -> Dictionary:
		calls.append({"method": method, "url": url, "headers": headers, "body": body})
		return {"body": {"gems": 17, "races_owned": ["Human"]}}


func test_memory_store_normalizes_and_round_trips() -> void:
	var store := MemoryProfileStore.new()
	store.save_profile("a", {"gems": 7, "class_trees": {"rogue": {"might": 2}}})
	var profile := store.load_profile("a")
	assert_eq(profile["gems"], 7)
	assert_true(profile["races_owned"].has("Human"))
	assert_eq(profile["class_trees"]["rogue"]["might"], 2)


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
