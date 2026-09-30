class_name D1ProfileStore
extends ProfileStore

var base_url: String
var secret: String
var sender
var _session_writes: Dictionary = {}

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

func save_profile_async(token: String, profile: Dictionary, session_id: int = 0) -> void:
	if sender == null or bool(profile.get("_unavailable", false)):
		return
	if session_id <= 0 or not sender.has_method("take_save_results"):
		# This path also supports injected senders used by tests.
		var next := _next_version_profile(profile)
		sender.enqueue_save(_url(token), _headers(), JSON.stringify(next))
		profile["version"] = next["version"]
		return
	if not _session_writes.has(session_id):
		_session_writes[session_id] = {"token": token, "version": int(profile.get("version", 0)),
			"profile": profile, "active": false, "pending": false, "stale": false,
			"disconnected": false}
	var state: Dictionary = _session_writes[session_id]
	if bool(state["stale"]):
		return
	state["profile"] = profile
	if bool(state["active"]):
		state["pending"] = true
		return
	_send_session_save(session_id, state)

func _send_session_save(session_id: int, state: Dictionary) -> void:
	var next := ProfileStore.normalize(state["profile"])
	next["version"] = int(state["version"]) + 1
	state["active"] = true
	sender.enqueue_save_with_context(_url(str(state["token"])), _headers(), JSON.stringify(next), session_id)

func _url(token: String) -> String:
	return base_url + "/profiles/" + token

func _headers() -> Dictionary:
	return {"Authorization": "Bearer " + secret, "Content-Type": "application/json"}

func _next_version_profile(profile: Dictionary) -> Dictionary:
	var next := ProfileStore.normalize(profile)
	# Each session advances the version it loaded. A stale session must receive
	# a 409 from D1 instead of outbidding a newer session on this server.
	next["version"] = int(next.get("version", 0)) + 1
	return next

func take_save_failures() -> Array[Dictionary]:
	var failures: Array[Dictionary] = []
	if sender == null or not sender.has_method("take_save_results"):
		return failures
	for result in sender.take_save_results():
		var url := str(result.get("url", ""))
		var status := int(result.get("status", 0))
		var session_id := int(result.get("session_id", 0))
		if _session_writes.has(session_id):
			var state: Dictionary = _session_writes[session_id]
			if status in [200, 204]:
				state["version"] = int(state["version"]) + 1
				state["profile"]["version"] = state["version"]
				state["active"] = false
				if bool(state["pending"]):
					state["pending"] = false
					_send_session_save(session_id, state)
				elif bool(state["disconnected"]):
					_session_writes.erase(session_id)
				continue
			state["active"] = false
			state["pending"] = false
			if status == 409:
				state["stale"] = true
			if bool(state["disconnected"]):
				_session_writes.erase(session_id)
		failures.append({"token": url.get_file(), "status": status, "session_id": session_id})
	return failures

func forget_session(session_id: int) -> void:
	if not _session_writes.has(session_id):
		return
	var state: Dictionary = _session_writes[session_id]
	state["disconnected"] = true
	if not bool(state["active"]):
		_session_writes.erase(session_id)

func _unavailable_profile() -> Dictionary:
	var profile := ProfileStore.normalize({})
	profile["_unavailable"] = true
	return profile
