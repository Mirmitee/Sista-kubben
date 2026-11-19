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
var fullscreen := false
var rules := "real"        # "real" eller "simple"
var show_hints := true
var throw_mode := "meter"  # "meter" (tajmade tryck) eller "drag" (musdrag)


func _ready() -> void:
	load_settings()
	apply()


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
	volume = cf.get_value("ljud", "volume", volume)
	rules = cf.get_value("spel", "rules", rules)
	show_hints = cf.get_value("spel", "show_hints", show_hints)
	throw_mode = cf.get_value("kast", "throw_mode", throw_mode)
	Lang.current = cf.get_value("spel", "lang", Lang.current)


func save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("kast", "sensitivity", sensitivity)
	cf.set_value("kast", "power", power)
	cf.set_value("kast", "aim_assist", aim_assist)
	cf.set_value("kast", "power_meter", power_meter)
	cf.set_value("grafik", "wobble", wobble)
	cf.set_value("grafik", "fullscreen", fullscreen)
	cf.set_value("ljud", "volume", volume)
	cf.set_value("spel", "rules", rules)
	cf.set_value("spel", "show_hints", show_hints)
	cf.set_value("kast", "throw_mode", throw_mode)
	cf.set_value("spel", "lang", Lang.current)
	cf.save(PATH)


func apply() -> void:
	# darr: 0 = stabilt (480 rader), 1 = väldigt darrigt (60 rader)
	RenderingServer.global_shader_parameter_set("ps1_snap", lerpf(480.0, 60.0, wobble))
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	if DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
	changed.emit()


func set_value(key: String, v) -> void:
	set(key, v)
	apply()
	save()
