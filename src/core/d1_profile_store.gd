class_name D1ProfileStore
extends ProfileStore

var base_url: String
var secret: String
var sender

func _init(url: String, auth_secret: String, http_sender = null) -> void:
	base_url = url.trim_suffix("/")
	secret = auth_secret
	sender = http_sender

func load_profile(token: String) -> Dictionary:
	if sender == null:
		return ProfileStore.normalize({})
	var response = sender.request("GET", base_url + "/profiles/" + token, {"Authorization": "Bearer " + secret}, "")
	var parsed = response.get("body", {}) if response is Dictionary else {}
	return ProfileStore.normalize(parsed if parsed is Dictionary else {})

func save_profile(token: String, profile: Dictionary) -> void:
	if sender == null:
		return
	sender.request("PUT", base_url + "/profiles/" + token, {
		"Authorization": "Bearer " + secret,
		"Content-Type": "application/json",
	}, JSON.stringify(ProfileStore.normalize(profile)))

