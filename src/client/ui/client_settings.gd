class_name ClientSettings
extends RefCounted
## Per-player client preferences, remembered on this device
## (user://settings.cfg; IndexedDB in browsers).

const PATH := "user://settings.cfg"
const TEXT_SCALES := [0.85, 1.0, 1.2, 1.45]

var text_scale := 1.0
var reduced_motion := false
var volume := 0.8
var player_name := ""
var server_url := ""
var seen_hints: Array = []


static func load_saved() -> ClientSettings:
	var settings := ClientSettings.new()
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		settings.text_scale = float(file.get_value("display", "text_scale", 1.0))
		settings.reduced_motion = bool(file.get_value("display", "reduced_motion", false))
		settings.volume = clampf(float(file.get_value("audio", "volume", 0.8)), 0.0, 1.0)
		settings.player_name = str(file.get_value("player", "name", ""))
		settings.server_url = str(file.get_value("player", "server_url", ""))
		settings.seen_hints = file.get_value("help", "seen_hints", [])
	return settings


func save() -> void:
	var file := ConfigFile.new()
	file.set_value("display", "text_scale", text_scale)
	file.set_value("display", "reduced_motion", reduced_motion)
	file.set_value("audio", "volume", volume)
	file.set_value("player", "name", player_name)
	file.set_value("player", "server_url", server_url)
	file.set_value("help", "seen_hints", seen_hints)
	file.save(PATH)
