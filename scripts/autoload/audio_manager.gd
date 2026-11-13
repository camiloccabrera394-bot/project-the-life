extends Node

var sounds := {}
var players := []
var ambient_rain_player: AudioStreamPlayer
var ambient_wind_player: AudioStreamPlayer
const MAX_PLAYERS := 12

func _ready() -> void:
	for i in range(MAX_PLAYERS):
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)

	ambient_rain_player = AudioStreamPlayer.new()
	ambient_rain_player.volume_db = -80.0
	add_child(ambient_rain_player)

	ambient_wind_player = AudioStreamPlayer.new()
	ambient_wind_player.volume_db = -80.0
	add_child(ambient_wind_player)

	_generate_all_sfx()

func _generate_all_sfx() -> void:
	sounds["shoot_tactical"] = _make_wav(0.16, func(t): return randf_range(-1.0, 1.0) * exp(-t * 26.0) * 0.75)
	sounds["shoot_silent"] = _make_wav(0.11, func(t): return (sin(TAU * 190.0 * t) * 0.4 + randf_range(-0.5, 0.5) * 0.6) * exp(-t * 38.0) * 0.45)
	sounds["explosion"] = _make_wav(0.45, func(t): return (sin(TAU * 55.0 * t) * 0.6 + randf_range(-1.0, 1.0) * 0.7) * exp(-t * 6.5) * 0.9)
	sounds["hit"] = _make_wav(0.11, func(t: float) -> float: return (sin(TAU * 92.0 * t) * 0.65 + randf_range(-0.4, 0.4) * 0.35) * exp(-t * 32.0) * 0.65)
	sounds["alert"] = _make_wav(0.18, func(t: float) -> float: return sin(TAU * (450.0 + t * 2400.0) * t) * exp(-t * 9.0) * 0.4)
	sounds["click"] = _make_wav(0.04, func(t: float) -> float: return sin(TAU * 1150.0 * t) * exp(-t * 80.0) * 0.28)
	sounds["takedown"] = _make_wav(0.22, func(t: float) -> float: return sin(TAU * 85.0 * t) * exp(-t * 14.0) * 0.85)
	sounds["engine"] = _make_wav(0.36, func(t: float) -> float: return (sin(TAU * 48.0 * t) * 0.55 + sin(TAU * 96.0 * t) * 0.28 + sin(TAU * 24.0 * t) * 0.25) * sin(PI * clampf(t / 0.36, 0.0, 1.0)) * 0.26)
	sounds["horn"] = _make_wav(0.25, func(t): return (sin(TAU * 340.0 * t) + sin(TAU * 425.0 * t)) * 0.22)
	# Efectos climáticos procedurales realistas
	sounds["thunder"] = _make_wav(1.8, func(t: float) -> float: return (sin(TAU * 42.0 * t) * 0.65 + sin(TAU * 84.0 * t) * 0.35 + randf_range(-0.35, 0.35) * 0.45) * exp(-t * 1.5) * 0.95)
	sounds["wind"] = _make_wav(1.6, func(t: float) -> float: return (sin(TAU * (70.0 + 25.0 * sin(TAU * 0.4 * t)) * t) * 0.38 + randf_range(-0.25, 0.25) * 0.35) * sin(PI * clampf(t / 1.6, 0.0, 1.0)) * 0.4)

	var rain_wav := _make_wav(1.5, func(t: float) -> float: return randf_range(-0.4, 0.4) * (0.8 + 0.2 * sin(TAU * 3.5 * t)) * 0.32)
	rain_wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambient_rain_player.stream = rain_wav

	var wind_wav := _make_wav(2.0, func(t: float) -> float: return (sin(TAU * 65.0 * t) * 0.25 + randf_range(-0.3, 0.3) * 0.35) * 0.3)
	wind_wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambient_wind_player.stream = wind_wav

func update_ambient_weather(rain_intensity: float, wind_strength: float) -> void:
	if SettingsManager.is_muted or not SettingsManager.sfx_enabled:
		if ambient_rain_player.playing: ambient_rain_player.stop()
		if ambient_wind_player.playing: ambient_wind_player.stop()
		return

	# Control de audio ambiental de lluvia
	if rain_intensity > 0.05:
		if not ambient_rain_player.playing:
			ambient_rain_player.play()
		ambient_rain_player.volume_db = lerpf(-30.0, -8.0, rain_intensity)
	else:
		if ambient_rain_player.playing:
			ambient_rain_player.volume_db = lerpf(ambient_rain_player.volume_db, -80.0, 0.1)
			if ambient_rain_player.volume_db < -50.0:
				ambient_rain_player.stop()

	# Control de audio ambiental de viento
	if wind_strength > 1.8:
		if not ambient_wind_player.playing:
			ambient_wind_player.play()
		ambient_wind_player.volume_db = lerpf(-28.0, -10.0, clampf((wind_strength - 1.8) / 1.7, 0.0, 1.0))
	else:
		if ambient_wind_player.playing:
			ambient_wind_player.volume_db = lerpf(ambient_wind_player.volume_db, -80.0, 0.1)
			if ambient_wind_player.volume_db < -50.0:
				ambient_wind_player.stop()


func _make_wav(duration: float, sample_fn: Callable) -> AudioStreamWAV:
	var mix_rate := 22050
	var count := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)

	for i in range(count):
		var t := float(i) / float(mix_rate)
		var v := clampf(sample_fn.call(t), -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav

func play_sfx(sfx_name: String, vol_db: float = 0.0) -> void:
	if SettingsManager.is_muted or not SettingsManager.sfx_enabled:
		return
	var stream: AudioStream = sounds.get(sfx_name)
	if not stream:
		return

	for p in players:
		if not p.playing:
			p.stream = stream
			p.volume_db = vol_db
			p.play()
			return
	# Si todos están ocupados, reutilizar el primero
	players[0].stream = stream
	players[0].volume_db = vol_db
	players[0].play()
