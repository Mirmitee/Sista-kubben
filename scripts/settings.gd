## Inställningar som sparas i user://settings.cfg.
extends Node

signal changed

const PATH := "user://settings.cfg"

var sensitivity := 1.0     # musens känslighet i kastet
var power := 1.0           # kraftmultiplikator
var aim_assist := true     # visa var förra pinnen landade + lång siktlinje
var power_meter := true    # mätare under svepet
var wobble := 0.5          # PS1-darr 0..1
var volume := 0.8
var music := 0.6
var fullscreen := false
## Skärmläge: "windowed", "fullscreen" (kantlös helskärm) eller "exclusive".
var window_mode := ""
## Fönsterstorlek (index i RESOLUTIONS), -1 = största som får plats.
var resolution := -1
## Skalning: "pixel" = hela pixlar (skarp text, ev. svarta kanter), "fill" = fyll fönstret.
var scaling := "pixel"
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(2560, 1440), Vector2i(3440, 1440), Vector2i(3840, 1600), Vector2i(3840, 2160), Vector2i(5120, 1440)]
var rules := "real"        # "real" eller "simple"
var show_hints := true
var throw_mode := "meter"  # "meter" (tajmade tryck) eller "drag" (musdrag)
var shake := 1.0           # skärmskakning 0..1.5
var show_timer := false    # visa tid för runnen
var difficulty := "natten"


const FONT := preload("res://fonts/tiny5.ttf")
## Textstorlek: 1.0 = normal, 1.15 = stor.
var text_scale := 1.0


func _ready() -> void:
	load_settings()
	apply()
	# tydlig pixelfont överallt (menyer, HUD och 3D-siffror)
	ThemeDB.fallback_font = FONT
	ThemeDB.fallback_font_size = fs(8)


## Tiny5 är ritad på ett rutnät och blir bara skarp i vissa storlekar
## (12, 18, 24, 36 px). Alla gamla storlekar knäpps till närmaste skarpa steg,
## så att varje pixel i bokstäverna blir lika stor och texten lätt att läsa.
func fs(size: int) -> int:
	var want := size * 1.25 * text_scale
	if want < 15.0:
		return 12
	if want < 21.0:
		return 18
	if want < 30.0:
		return 24
	return 36


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	sensitivity = cf.get_value("kast", "sensitivity", sensitivity)
	power = cf.get_value("kast", "power", power)
	aim_assist = cf.get_value("kast", "aim_assist", aim_assist)
	power_meter = cf.get_value("kast", "power_meter", power_meter)
	wobble = cf.get_value("grafik", "wobble", wobble)
	fullscreen = cf.get_value("grafik", "fullscreen", fullscreen)
	window_mode = cf.get_value("grafik", "window_mode", "fullscreen" if fullscreen else "windowed")
	resolution = cf.get_value("grafik", "resolution", resolution)
	scaling = cf.get_value("grafik", "scaling", scaling)
	volume = cf.get_value("ljud", "volume", volume)
	music = cf.get_value("ljud", "music", music)
	rules = cf.get_value("spel", "rules", rules)
	show_hints = cf.get_value("spel", "show_hints", show_hints)
	throw_mode = cf.get_value("kast", "throw_mode", throw_mode)
	shake = cf.get_value("grafik", "shake", shake)
	show_timer = cf.get_value("spel", "show_timer", show_timer)
	difficulty = cf.get_value("spel", "difficulty", difficulty)
	text_scale = cf.get_value("grafik", "text_scale", text_scale)
	Lang.current = cf.get_value("spel", "lang", Lang.current)


func save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("kast", "sensitivity", sensitivity)
	cf.set_value("kast", "power", power)
	cf.set_value("kast", "aim_assist", aim_assist)
	cf.set_value("kast", "power_meter", power_meter)
	cf.set_value("grafik", "wobble", wobble)
	cf.set_value("grafik", "fullscreen", fullscreen)
	cf.set_value("grafik", "window_mode", window_mode)
	cf.set_value("grafik", "resolution", resolution)
	cf.set_value("grafik", "scaling", scaling)
	cf.set_value("ljud", "volume", volume)
	cf.set_value("ljud", "music", music)
	cf.set_value("spel", "rules", rules)
	cf.set_value("spel", "show_hints", show_hints)
	cf.set_value("kast", "throw_mode", throw_mode)
	cf.set_value("spel", "lang", Lang.current)
	cf.set_value("grafik", "shake", shake)
	cf.set_value("spel", "show_timer", show_timer)
	cf.set_value("spel", "difficulty", difficulty)
	cf.set_value("grafik", "text_scale", text_scale)
	cf.save(PATH)


func apply() -> void:
	# darr: 0 = stabilt (480 rader), 1 = väldigt darrigt (60 rader)
	RenderingServer.global_shader_parameter_set("ps1_snap", lerpf(480.0, 60.0, wobble))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	if DisplayServer.get_name() != "headless":
		_apply_display()
	changed.emit()


## Största fönsterstorleken som får plats på skärmen (utan att täcka aktivitetsfältet).
func fit_resolution() -> int:
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).size
	# största (till ytan) som får plats, med lite marginal för fönsterramen
	var best := 0
	for i in RESOLUTIONS.size():
		var r := RESOLUTIONS[i]
		if r.x <= usable.x - 16 and r.y <= usable.y - 48 and r.x * r.y > RESOLUTIONS[best].x * RESOLUTIONS[best].y:
			best = i
	return best


## Storlekar som får plats på skärmen (för fönsterläge).
func fitting_resolutions() -> Array[int]:
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).size
	var out: Array[int] = []
	for i in RESOLUTIONS.size():
		if RESOLUTIONS[i].x <= usable.x - 16 and RESOLUTIONS[i].y <= usable.y - 48:
			out.append(i)
	if out.is_empty():
		out.append(0)
	return out


func window_size() -> Vector2i:
	return RESOLUTIONS[clampi(resolution if resolution >= 0 else fit_resolution(), 0, RESOLUTIONS.size() - 1)]


func _apply_display() -> void:
	if window_mode == "":
		window_mode = "fullscreen" if fullscreen else "windowed"
	fullscreen = window_mode != "windowed"
	var root := get_tree().root
	# hela pixlar: 640x360 skalas x2, x3, x4 ... så att varje bokstav blir lika skarp
	root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER if scaling == "pixel" else Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	# 3D behöver inte ritas i 4K: den delas ändå i PS1-pixlar. Spara grafikkortet.
	var h := float(DisplayServer.window_get_size().y)
	root.scaling_3d_scale = clampf(1080.0 / maxf(h, 1.0), 0.25, 1.0)
	var want := DisplayServer.WINDOW_MODE_WINDOWED
	match window_mode:
		"fullscreen": want = DisplayServer.WINDOW_MODE_FULLSCREEN
		"exclusive": want = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if DisplayServer.window_get_mode() != want:
		DisplayServer.window_set_mode(want)
	if want == DisplayServer.WINDOW_MODE_WINDOWED:
		var sz := window_size()
		if DisplayServer.window_get_size() != sz:
			DisplayServer.window_set_size(sz)
			var scr := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
			DisplayServer.window_set_position(scr.position + (scr.size - sz) / 2)


func set_value(key: String, v) -> void:
	set(key, v)
	apply()
	save()
