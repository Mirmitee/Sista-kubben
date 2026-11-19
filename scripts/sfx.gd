## Ljud som syntas i kod (inga ljudfiler än): trä mot trä, sus, duns,
## syrsor och en låg obehaglig ton i bakgrunden. Låg samplingsfrekvens
## för att det ska låta lagom billigt, som på PS1.
extends Node

const RATE := 22050

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _ambient: AudioStreamPlayer
var _drone: AudioStreamPlayer


func _ready() -> void:
	_streams["clack"] = _make(0.25, _clack)
	_streams["clack2"] = _make(0.3, _clack_low)
	_streams["whoosh"] = _make(0.35, _whoosh)
	_streams["thud"] = _make(0.25, _thud)
	_streams["click"] = _make(0.05, _click)
	_streams["bad"] = _make(0.6, _bad)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_ambient = AudioStreamPlayer.new()
	_ambient.stream = _make(4.0, _crickets, true)
	_ambient.volume_db = -14.0
	add_child(_ambient)
	_drone = AudioStreamPlayer.new()
	_drone.stream = _make(8.0, _drone_fn, true)
	_drone.volume_db = -16.0
	add_child(_drone)


func start_ambience() -> void:
	if not _ambient.playing:
		_ambient.play()
		_drone.play()


func play(name: String, vol_db := 0.0, pitch := 1.0) -> void:
	if not _streams.has(name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[name]
			p.volume_db = vol_db
			p.pitch_scale = pitch * randf_range(0.94, 1.06)
			p.play()
			return


func _make(seconds: float, fn: Callable, loop := false) -> AudioStreamWAV:
	var n := int(seconds * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(fn.get_method())
	var state := {"rng": rng, "lp": 0.0, "lp2": 0.0}
	for i in n:
		var t := float(i) / RATE
		var v: float = clampf(fn.call(t, seconds, state), -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = n
	return s


func _clack(t: float, _d: float, st: Dictionary) -> float:
	var e := exp(-t * 38.0)
	var tone := sin(TAU * 1450.0 * t) * 0.5 + sin(TAU * 2310.0 * t) * 0.3 + sin(TAU * 860.0 * t) * 0.4
	return (tone + st.rng.randf_range(-1, 1) * 0.4 * exp(-t * 120.0)) * e * 0.8


func _clack_low(t: float, _d: float, st: Dictionary) -> float:
	var e := exp(-t * 25.0)
	return (sin(TAU * 620.0 * t) * 0.6 + sin(TAU * 1040.0 * t) * 0.4 + st.rng.randf_range(-1, 1) * 0.3 * exp(-t * 90.0)) * e


func _whoosh(t: float, d: float, st: Dictionary) -> float:
	var env := sin(PI * t / d)
	st.lp = lerpf(st.lp, st.rng.randf_range(-1, 1), 0.08 + 0.1 * env)
	return st.lp * env * 1.6


func _thud(t: float, _d: float, st: Dictionary) -> float:
	st.lp = lerpf(st.lp, st.rng.randf_range(-1, 1), 0.05)
	return (sin(TAU * (90.0 - t * 120.0) * t) * 0.7 + st.lp * 2.0) * exp(-t * 18.0)


func _click(t: float, _d: float, _st: Dictionary) -> float:
	return sin(TAU * 1800.0 * t) * exp(-t * 90.0) * 0.5


func _bad(t: float, _d: float, _st: Dictionary) -> float:
	var f := 140.0 - t * 60.0
	return (sin(TAU * f * t) + sin(TAU * f * 1.06 * t)) * 0.35 * exp(-t * 3.0)


func _crickets(t: float, d: float, st: Dictionary) -> float:
	var v := 0.0
	for k in 3:
		var period := 0.9 + k * 0.37
		var ph := fmod(t + k * 0.31, period)
		if ph < 0.12:
			var chirp := sin(TAU * 4200.0 * (1.0 + k * 0.07) * t) * (0.5 + 0.5 * sin(TAU * 60.0 * t))
			v += chirp * sin(PI * ph / 0.12) * 0.25
	st.lp = lerpf(st.lp, st.rng.randf_range(-1, 1), 0.02)
	# mjuk övergång i loopen
	var edge := clampf(minf(t, d - t) * 8.0, 0.0, 1.0)
	return (v + st.lp * 0.3) * edge


func _drone_fn(t: float, d: float, _st: Dictionary) -> float:
	# låg ton som svävar, med en fel-stämd kvint som kommer och går
	var a := sin(TAU * 55.0 * t) * 0.4 + sin(TAU * 55.5 * t) * 0.3
	var b := sin(TAU * 77.875 * t) * 0.15 * (0.5 + 0.5 * sin(TAU * t / d))
	return a + b
