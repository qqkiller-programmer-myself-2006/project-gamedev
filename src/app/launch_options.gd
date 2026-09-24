class_name LaunchOptions
extends RefCounted
## Options after "--" on the command line (--server, --port=8910,
## --url=ws://host:8910, --name=Ann) or, in a browser build, from the page
## URL (?server=wss://host&name=Ann).


static func parse() -> Dictionary:
	var options := {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var pair := arg.trim_prefix("--").split("=", true, 1)
		options[pair[0]] = pair[1] if pair.size() > 1 else true
	if OS.has_feature("web"):
		var query = JavaScriptBridge.eval("window.location.search", true)
		if typeof(query) == TYPE_STRING:
			for part in str(query).trim_prefix("?").split("&", false):
				var pair := part.split("=", true, 1)
				var key := pair[0].uri_decode()
				options["url" if key == "server" else key] = pair[1].uri_decode() if pair.size() > 1 else true
	return options
