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
	_streams["boom"] = _make(0.9, _boom)
	_streams["zap"] = _make(0.5, _zap)
	_streams["sparkle"] = _make(0.4, _sparkle)
	_streams["coin"] = _make(0.25, _coin)
	_streams["caw"] = _make(0.7, _caw)
	_streams["groan"] = _make(0.95, _groan)
	for i in 12:
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


var _caw_t := 25.0
var _music: AudioStreamPlayer
var _music_thread: Thread
var _music_stream: AudioStreamWAV

# Spöklik dragspelsvals i a-moll (egen melodi), spelad långsamt och ostadigt.
const BPM := 66.0
const MELODY := [  # [taktslag, längd, midi]
	[0, 1, 76], [1, 1, 69], [2, 1, 72],
	[3, 1.5, 74], [4.5, 0.5, 77], [5, 1, 76],
	[6, 1, 71], [7, 1, 68], [8, 1, 71],
	[9, 3, 69],
	[12, 1, 72], [13, 1, 77], [14, 1, 81],
	[15, 1.5, 79], [16.5, 0.5, 77], [17, 1, 74],
	[18, 1, 76], [19, 1, 74], [20, 1, 71],
	[21, 2, 69],
]
const BASS := [45, 50, 40, 45, 41, 50, 40, 45]
const CHORDS := [[57, 60, 64], [57, 62, 65], [56, 59, 64], [57, 60, 64], [57, 60, 65], [57, 62, 65], [56, 59, 64], [57, 60, 64]]


func _process(dt: float) -> void:
	if _music_stream and _music == null:
		_music = AudioStreamPlayer.new()
		_music.stream = _music_stream
		add_child(_music)
		_music.play()
	if _music:
		_music.volume_db = linear_to_db(maxf(Settings.music * 0.55, 0.0001))
		# slowmotion: dragspelet saktar ner med tiden
		var want := clampf(0.55 + 0.45 * Engine.time_scale, 0.5, 1.0) * (0.8 if get_tree().paused else 1.0)
		_music.pitch_scale = lerpf(_music.pitch_scale, want, clampf(dt * 6.0, 0.0, 1.0))
	# en kråka någonstans i skogen, då och då
	if _ambient and _ambient.playing:
		_caw_t -= dt
		if _caw_t <= 0.0:
			_caw_t = randf_range(18.0, 45.0)
			play("caw", -16.0, randf_range(0.85, 1.1))


func start_ambience() -> void:
	if _music_thread == null:
		_music_thread = Thread.new()
		_music_thread.start(_build_music)
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


func _boom(t: float, _d: float, st: Dictionary) -> float:
	st.lp = lerpf(st.lp, st.rng.randf_range(-1, 1), 0.04 + 0.2 * exp(-t * 20.0))
	return (st.lp * 3.0 + sin(TAU * (55.0 - t * 30.0) * t) * 0.8) * exp(-t * 4.5)


func _zap(t: float, _d: float, st: Dictionary) -> float:
	var crackle: float = st.rng.randf_range(-1, 1) * (1.0 if st.rng.randf() < 0.3 else 0.2)
	st.lp2 = lerpf(st.lp2, st.rng.randf_range(-1, 1), 0.03)
	return (crackle * exp(-t * 9.0) + st.lp2 * 2.5 * exp(-t * 3.0)) * 0.8


func _sparkle(t: float, _d: float, _st: Dictionary) -> float:
	var f := 1800.0 + floorf(t * 20.0) * 300.0
	return sin(TAU * f * t) * exp(-fmod(t, 0.05) * 60.0) * exp(-t * 5.0) * 0.35


func _coin(t: float, _d: float, _st: Dictionary) -> float:
	var f := 1320.0 if t < 0.07 else 1760.0
	return signf(sin(TAU * f * t)) * 0.18 * exp(-t * 12.0)


func _caw(t: float, _d: float, st: Dictionary) -> float:
	# två hesa kraxanden
	var local := fmod(t, 0.33)
	if local > 0.26:
		return 0.0
	var f := 520.0 - local * 700.0
	var saw := fmod(t * f, 1.0) * 2.0 - 1.0
	st.lp = lerpf(st.lp, st.rng.randf_range(-1, 1), 0.3)
	return (saw * 0.5 + st.lp * 0.5) * sin(PI * local / 0.26) * 0.6


func _build_music() -> void:
	var beats := 24.0
	var secs := beats * 60.0 / BPM
	var st := _make_rate(secs, _accordion, 11025, true)
	call_deferred("_music_ready", st)


func _music_ready(st: AudioStreamWAV) -> void:
	_music_thread.wait_to_finish()
	_music_stream = st


func _make_rate(seconds: float, fn: Callable, rate: int, loop: bool) -> AudioStreamWAV:
	var n := int(seconds * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var state := {"rng": rng, "lp": 0.0, "lp2": 0.0, "rate": float(rate)}
	for i in n:
		var t := float(i) / rate
		var v: float = clampf(fn.call(t, seconds, state), -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 30000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = n
	return s


static func _midi(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


## En dragspelston: tre lite ostämda tungor (musette) och en oktav under.
static func _reed(f: float, t: float) -> float:
	var a := fmod(t * f * 0.996, 1.0) * 2.0 - 1.0
	var b := fmod(t * f * 1.005, 1.0) * 2.0 - 1.0
	var c := 1.0 if fmod(t * f * 0.5, 1.0) < 0.5 else -1.0
	return a * 0.45 + b * 0.4 + c * 0.2


func _accordion(t: float, d: float, st: Dictionary) -> float:
	var bps := BPM / 60.0
	# bandet som går för sakta: tonhöjden svajar och sjunker lite i slutet
	var wob := 1.0 + 0.012 * sin(TAU * 0.13 * t) - 0.02 * pow(t / d, 3.0)
	var beat := t * bps
	var v := 0.0
	for m in MELODY:
		var s0: float = m[0]
		var s1: float = s0 + m[1]
		if beat >= s0 and beat < s1 + 0.15:
			var nt := (beat - s0) / bps
			var env := minf(nt / 0.05, 1.0) * (1.0 if beat < s1 else maxf(1.0 - (beat - s1) / 0.15, 0.0))
			v += _reed(_midi(m[2]) * wob, t) * env * 0.42
	var bar := int(beat / 3.0) % 8
	var bb := fmod(beat, 3.0)
	if bb < 0.8:
		var env := minf(bb / 0.03, 1.0) * (1.0 - bb / 0.8)
		v += _reed(_midi(BASS[bar]) * wob, t) * env * 0.4
	elif bb >= 1.0:
		var cb := fmod(bb - 1.0, 1.0)
		if cb < 0.45:
			var env := minf(cb / 0.03, 1.0) * (1.0 - cb / 0.45)
			for n in CHORDS[bar]:
				v += _reed(_midi(n) * wob, t) * env * 0.13
	# bälgen andas
	v *= 0.85 + 0.15 * sin(TAU * 5.2 * t)
	st.lp = lerpf(st.lp, v, 0.35)
	return st.lp * 1.0 + st.rng.randf_range(-1, 1) * 0.01


func _groan(t: float, d: float, _st: Dictionary) -> float:
	# ett långt, plågat "uuoooh" från en hund som har fått nog
	var f0 := 190.0 - t * 70.0 + sin(TAU * 6.0 * t) * 6.0 * t
	var f1 := 420.0 + t * 260.0
	var f2 := 820.0 + t * 200.0
	var v := 0.0
	for k in range(1, 14):
		var fk := f0 * k
		var a := exp(-pow((fk - f1) / 130.0, 2)) + 0.55 * exp(-pow((fk - f2) / 220.0, 2))
		v += sin(TAU * f0 * k * t) * a
	var env := minf(t * 12.0, 1.0) * clampf((d - t) * 3.0, 0.0, 1.0)
	return v * 0.32 * env
