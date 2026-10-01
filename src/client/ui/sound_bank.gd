class_name SoundBank
extends Node
## Short UI and combat cues. Every cue keeps a synthesized fallback and every
## cue also has a visual equivalent in a banner, log line or countdown text.

const RATE := 22050
const SFX_POOL_SIZE := 3
const MUSIC_FADE_SECONDS := 0.6
const HOVER_COOLDOWN_MSEC := 70
const HOVER_VOLUME_DB := -8.0

const CUE_ASSETS := {
	"turn": "res://assets/audio/sfx/ui_turn.ogg",
	"warn": "res://assets/audio/sfx/ui_warn.ogg",
	"hit": "res://assets/audio/sfx/hit.ogg",
	"vote": "res://assets/audio/sfx/ui_vote.ogg",
	"good": "res://assets/audio/sfx/reward_sting.ogg",
	"bad": "res://assets/audio/sfx/defeat_sting.ogg",
	"click": "res://assets/audio/sfx/ui_click.ogg",
	"hover": "res://assets/audio/sfx/ui_hover.ogg",
	"cancel": "res://assets/audio/sfx/ui_cancel.ogg",
	"error": "res://assets/audio/sfx/ui_error.ogg",
	"sword_hit": "res://assets/audio/sfx/sword_hit.ogg",
	"enemy_death": "res://assets/audio/sfx/enemy_death.ogg",
	"player_down": "res://assets/audio/sfx/player_down.ogg",
	"level_up": "res://assets/audio/sfx/level_up.ogg",
	"loot_pickup": "res://assets/audio/sfx/loot_pickup.ogg",
	"victory_sting": "res://assets/audio/sfx/reward_sting.ogg",
	"defeat_sting": "res://assets/audio/sfx/defeat_sting.ogg",
	"magic_cast": "res://assets/audio/sfx/magic_cast.ogg",
	"heal": "res://assets/audio/sfx/heal.ogg",
	"buff": "res://assets/audio/sfx/buff.ogg",
	"debuff": "res://assets/audio/sfx/debuff.ogg",
	"critical": "res://assets/audio/sfx/critical.ogg",
	"miss": "res://assets/audio/sfx/miss.ogg",
}

const MUSIC_ASSETS := {
	"title": "res://assets/audio/music/music_title.ogg",
	"lobby": "res://assets/audio/music/music_title.ogg",
	"forest": "res://assets/audio/music/music_forest.ogg",
	"battle": "res://assets/audio/music/music_battle.ogg",
	"guardian": "res://assets/audio/music/music_guardian.ogg",
	"victory": "res://assets/audio/music/music_victory.ogg",
	"defeat": "res://assets/audio/sfx/defeat_sting.ogg",
}

const FALLBACK_NOTES := {
	"turn": [[660.0, 0.09], [880.0, 0.14]],
	"warn": [[520.0, 0.07], [0.0, 0.05], [520.0, 0.07]],
	"hit": [[-1.0, 0.07]],
	"vote": [[523.0, 0.1], [659.0, 0.1], [784.0, 0.16]],
	"good": [[659.0, 0.1], [784.0, 0.1], [1047.0, 0.22]],
	"bad": [[392.0, 0.16], [311.0, 0.16], [262.0, 0.28]],
	"click": [[1200.0, 0.03]],
	"hover": [[1400.0, 0.02]],
	"cancel": [[600.0, 0.06]],
	"error": [[300.0, 0.08], [220.0, 0.12]],
	"sword_hit": [[-1.0, 0.09]],
	"enemy_death": [[220.0, 0.12], [160.0, 0.18]],
	"player_down": [[180.0, 0.16], [120.0, 0.2]],
	"level_up": [[659.0, 0.08], [784.0, 0.08], [1047.0, 0.15]],
	"loot_pickup": [[880.0, 0.04], [1175.0, 0.09]],
	"victory_sting": [[784.0, 0.08], [988.0, 0.08], [1175.0, 0.2]],
	"defeat_sting": [[392.0, 0.12], [311.0, 0.12], [220.0, 0.24]],
	"magic_cast": [[523.0, 0.05], [784.0, 0.12]],
	"heal": [[659.0, 0.07], [880.0, 0.13]],
	"buff": [[587.0, 0.07], [784.0, 0.12]],
	"debuff": [[440.0, 0.08], [330.0, 0.12]],
	"critical": [[-1.0, 0.12]],
	"miss": [[300.0, 0.08]],
}

var _players: Dictionary = {}
var _player_indices: Dictionary = {}
var _music_players: Array[AudioStreamPlayer] = []
var _music_tween: Tween
var _music_track := ""
var _music_active_index := -1
var _last_hover_msec := -1


func _ready() -> void:
	_ensure_bus("SFX")
	_ensure_bus("Music")
	for cue in CUE_ASSETS:
		_register_cue(cue, str(CUE_ASSETS[cue]))
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "MusicPlayer%d" % i
		player.bus = "Music"
		player.volume_db = -80.0
		player.finished.connect(_on_music_finished.bind(i))
		add_child(player)
		_music_players.append(player)


func play(cue: String) -> void:
	if not _players.has(cue):
		return
	if cue == "hover" and _hover_is_rate_limited(Time.get_ticks_msec()):
		return
	var pool: Array = _players[cue]
	var index := int(_player_indices.get(cue, 0))
	var player: AudioStreamPlayer = pool[index]
	_player_indices[cue] = (index + 1) % pool.size()
	player.play()


## Returns true when a hover should be suppressed; passing time keeps the
## throttle deterministic in tests and avoids coupling it to audio playback.
func _hover_is_rate_limited(now_msec: int) -> bool:
	if _last_hover_msec >= 0 and now_msec - _last_hover_msec < HOVER_COOLDOWN_MSEC:
		return true
	_last_hover_msec = now_msec
	return false


func has_cue(cue: String) -> bool:
	return _players.has(cue) and not (_players[cue] as Array).is_empty()


func cue_names() -> Array[String]:
	var names: Array[String] = []
	for cue in _players:
		names.append(str(cue))
	return names


func play_music(track: String) -> void:
	if not MUSIC_ASSETS.has(track):
		return
	if _should_skip_music(track):
		return
	if not is_inside_tree() or _music_players.size() < 2:
		return
	var path := str(MUSIC_ASSETS[track])
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = track != "defeat"
	if _music_tween != null and _music_tween.is_running():
		_music_tween.kill()
	var incoming_index := 0 if _music_active_index != 0 else 1
	var incoming := _music_players[incoming_index]
	var outgoing_index := _music_active_index
	incoming.stop()
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()
	_music_track = track
	_music_active_index = incoming_index
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(incoming, "volume_db", 0.0, MUSIC_FADE_SECONDS)
	if outgoing_index >= 0:
		var outgoing := _music_players[outgoing_index]
		_music_tween.tween_property(outgoing, "volume_db", -80.0, MUSIC_FADE_SECONDS)
		_music_tween.chain().tween_callback(outgoing.stop)


func _should_skip_music(track: String) -> bool:
	if _music_track != track:
		return false
	if track == "defeat":
		return true
	return (
		_music_active_index >= 0
		and _music_active_index < _music_players.size()
		and _music_players[_music_active_index].playing
	)


func stop_music() -> void:
	if not is_inside_tree() or _music_players.is_empty():
		return
	if _music_tween != null and _music_tween.is_running():
		_music_tween.kill()
	_music_track = ""
	_music_active_index = -1
	_music_tween = create_tween().set_parallel(true)
	for player in _music_players:
		_music_tween.tween_property(player, "volume_db", -80.0, MUSIC_FADE_SECONDS)
	_music_tween.chain().tween_callback(_stop_music_players)


func _stop_music_players() -> void:
	for player in _music_players:
		player.stop()


## Master volume from 0 to 1.
static func set_volume(volume: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, volume <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.001)))


static func set_music_volume(volume: float) -> void:
	var bus := AudioServer.get_bus_index("Music")
	if bus >= 0:
		AudioServer.set_bus_mute(bus, volume <= 0.001)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.001)))


func _register_cue(cue: String, path: String) -> void:
	var stream: AudioStream = load(path) if not path.is_empty() and ResourceLoader.exists(path) else null
	if stream == null:
		stream = _make_tone(FALLBACK_NOTES[cue], 0.3 if cue != "click" else 0.15)
	var pool: Array[AudioStreamPlayer] = []
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "%sPlayer%d" % [cue.capitalize(), i]
		player.stream = stream
		player.bus = "SFX"
		if cue == "hover":
			player.volume_db = HOVER_VOLUME_DB
		add_child(player)
		pool.append(player)
	_players[cue] = pool
	_player_indices[cue] = 0


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _on_music_finished(_index: int) -> void:
	# Keep the one-shot selected so repeated state refreshes do not restart it.
	pass


## Build the original compact fallback tone; cues continue to work if assets
## are absent or have not been imported yet.
func _make_tone(notes: Array, gain: float) -> AudioStreamWAV:
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
	return stream
