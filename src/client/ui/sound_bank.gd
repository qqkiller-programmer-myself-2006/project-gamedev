class_name SoundBank
extends Node
## Short synthesized sound cues (no audio assets). Every cue also has a
## visual equivalent in the UI (banner, log line or countdown text).

const RATE := 22050

var _players: Dictionary = {}


func _ready() -> void:
	_add("turn", [[660.0, 0.09], [880.0, 0.14]], 0.35)
	_add("warn", [[520.0, 0.07], [0.0, 0.05], [520.0, 0.07]], 0.3)
	_add("hit", [[-1.0, 0.07]], 0.25)
	_add("vote", [[523.0, 0.1], [659.0, 0.1], [784.0, 0.16]], 0.3)
	_add("good", [[659.0, 0.1], [784.0, 0.1], [1047.0, 0.22]], 0.3)
	_add("bad", [[392.0, 0.16], [311.0, 0.16], [262.0, 0.28]], 0.3)
	_add("click", [[1200.0, 0.03]], 0.15)


func play(cue: String) -> void:
	if _players.has(cue):
		_players[cue].play()


## Master volume from 0 to 1.
static func set_volume(volume: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, volume <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.001)))


## notes: [[frequency, seconds], ...]; frequency 0 is silence, -1 is noise.
func _add(cue: String, notes: Array, gain: float) -> void:
	var data := PackedByteArray()
	var phase := 0.0
	var noise := 12345
	for note in notes:
		var frequency: float = note[0]
		var samples := int(RATE * float(note[1]))
		for i in samples:
			var envelope := minf(1.0, minf(i / 200.0, (samples - i) / 400.0))
			var value := 0.0
			if frequency > 0.0:
				phase += TAU * frequency / RATE
				value = sin(phase)
			elif frequency < 0.0:
				noise = (noise * 1103515245 + 12345) & 0x7fffffff
				value = float(noise % 2000) / 1000.0 - 1.0
			var sample := int(clampf(value * envelope * gain, -1.0, 1.0) * 32767.0)
			data.append(sample & 0xff)
			data.append((sample >> 8) & 0xff)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	_players[cue] = player
