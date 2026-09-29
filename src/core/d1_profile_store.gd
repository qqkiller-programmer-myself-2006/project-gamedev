class_name D1ProfileStore
extends ProfileStore

var base_url: String
var secret: String
var sender
var _versions: Dictionary = {}

func _init(url: String, auth_secret: String, http_sender = null) -> void:
	base_url = url.trim_suffix("/")
	secret = auth_secret
	sender = http_sender

func load_profile(token: String) -> Dictionary:
	if sender == null:
		return _unavailable_profile()
	var response = sender.request("GET", base_url + "/profiles/" + token, {"Authorization": "Bearer " + secret}, "")
	if not response is Dictionary:
		return _unavailable_profile()
	var status := int(response.get("status", 0))
	if status == 404:
		return ProfileStore.normalize({})
	if status != 200 or not response.get("body") is Dictionary:
		return _unavailable_profile()
	return ProfileStore.normalize(response["body"])

func save_profile(token: String, profile: Dictionary) -> void:
	save_profile_async(token, profile)

func save_profile_async(token: String, profile: Dictionary) -> void:
	if sender == null or bool(profile.get("_unavailable", false)):
		return
	var next := _next_version_profile(token, profile)
	sender.enqueue_save(base_url + "/profiles/" + token, {"Authorization": "Bearer " + secret, "Content-Type": "application/json"}, JSON.stringify(next))

func _next_version_profile(token: String, profile: Dictionary) -> Dictionary:
	var next := ProfileStore.normalize(profile)
	var version := maxi(int(next.get("version", 0)), int(_versions.get(token, 0))) + 1
	_versions[token] = version
	next["version"] = version
	return next

func _unavailable_profile() -> Dictionary:
	var profile := ProfileStore.normalize({})
	profile["_unavailable"] = true
	return profile
