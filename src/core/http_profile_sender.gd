class_name HttpProfileSender
extends RefCounted
## Synchronous bounded GETs plus a single background worker for fire-and-forget saves.

const TIMEOUT_SECONDS := 3.0
var _mutex := Mutex.new()
var _semaphore := Semaphore.new()
var _pending: Dictionary = {}
var _stopping := false
var _thread := Thread.new()

func _init() -> void:
	_thread.start(_save_worker)

func request(method: String, url: String, headers: Dictionary, body: String) -> Dictionary:
	return _perform(method, url, headers, body)

func enqueue_save(url: String, headers: Dictionary, body: String) -> void:
	_mutex.lock()
	if not _stopping:
		_pending[url] = {"url": url, "headers": headers.duplicate(), "body": body}
		_semaphore.post()
	_mutex.unlock()

func stop() -> void:
	_mutex.lock()
	_stopping = true
	_semaphore.post()
	_mutex.unlock()
	if _thread.is_started():
		_thread.wait_to_finish()

func _save_worker() -> void:
	while true:
		_semaphore.wait()
		_mutex.lock()
		if _stopping:
			_mutex.unlock()
			return
		var batch := _pending.values()
		_pending.clear()
		_mutex.unlock()
		for item in batch:
			for attempt in 4:
				var response := _perform("PUT", item.url, item.headers, item.body)
				if int(response.get("status", 0)) in [200, 204]:
					break
				if attempt < 3:
					if not _wait_or_stop(500 * (1 << attempt)):
						return

func _wait_or_stop(milliseconds: int) -> bool:
	var remaining := milliseconds
	while remaining > 0:
		if _stopping:
			return false
		var slice := mini(remaining, 25)
		OS.delay_msec(slice)
		remaining -= slice
	return not _stopping

func _perform(method: String, url: String, headers: Dictionary, body: String) -> Dictionary:
	var parsed := url
	var scheme_end := parsed.find("://")
	if scheme_end < 0:
		return {"status": 0, "body": null}
	var scheme := parsed.substr(0, scheme_end).to_lower()
	var remainder := parsed.substr(scheme_end + 3)
	var slash := remainder.find("/")
	var authority := remainder if slash < 0 else remainder.substr(0, slash)
	var path := "/" if slash < 0 else remainder.substr(slash)
	var host := authority
	var port := 443 if scheme == "https" else 80
	var colon := authority.rfind(":")
	if colon >= 0 and not authority.contains("]:"):
		host = authority.substr(0, colon)
		port = int(authority.substr(colon + 1))
	var client := HTTPClient.new()
	var tls := TLSOptions.client() if scheme == "https" else null
	if client.connect_to_host(host, port, tls) != OK:
		return {"status": 0, "body": null}
	var started := Time.get_ticks_msec()
	while client.get_status() in [HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING]:
		if _stopping:
			return {"status": 0, "body": null}
		client.poll()
		if Time.get_ticks_msec() - started >= TIMEOUT_SECONDS * 1000:
			return {"status": 0, "body": null}
		OS.delay_msec(5)
	var packed_headers := PackedStringArray()
	for key in headers:
		packed_headers.append("%s: %s" % [key, headers[key]])
	var verb := HTTPClient.METHOD_GET if method == "GET" else HTTPClient.METHOD_PUT
	if client.request(verb, path, packed_headers, body) != OK:
		return {"status": 0, "body": null}
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		if _stopping:
			return {"status": 0, "body": null}
		client.poll()
		if Time.get_ticks_msec() - started >= TIMEOUT_SECONDS * 1000:
			return {"status": 0, "body": null}
		OS.delay_msec(5)
	if not client.has_response():
		return {"status": 0, "body": null}
	var bytes := PackedByteArray()
	while client.get_status() == HTTPClient.STATUS_BODY:
		if _stopping:
			return {"status": 0, "body": null}
		client.poll()
		var chunk := client.read_response_body_chunk()
		if not chunk.is_empty():
			bytes.append_array(chunk)
		if Time.get_ticks_msec() - started >= TIMEOUT_SECONDS * 1000:
			return {"status": 0, "body": null}
		OS.delay_msec(5)
	var text := bytes.get_string_from_utf8()
	var parsed_body = JSON.parse_string(text) if not text.is_empty() else null
	return {"status": client.get_response_code(), "body": parsed_body}
