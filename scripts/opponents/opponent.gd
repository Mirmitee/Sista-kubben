## Basklass för motståndare. Varje motståndare har ett namn, repliker
## på svenska och engelska, ett utseende och (senare) egna fusk/regler
## och ett eget kast. Lägg nya motståndare som egna skript bredvid.
class_name Opponent
extends Node3D

signal spoke(who: String, text: String)

var display_name := {"sv": "???", "en": "???"}
## händelse -> {"sv": [...], "en": [...]}
var lines := {}

var _head: Node3D
var _look_x := 0.0
var _flinch := 0.0
var _t := 0.0


func say(event: String) -> void:
	var e: Dictionary = lines.get(event, {})
	var arr: Array = e.get(Lang.current, [])
	if arr.is_empty():
		return
	spoke.emit(display_name[Lang.current], arr[randi() % arr.size()])


func look_at_x(x: float) -> void:
	_look_x = x


func flinch() -> void:
	_flinch = 1.0


func _process(dt: float) -> void:
	_t += dt
	_flinch = move_toward(_flinch, 0.0, dt * 1.5)
	if _head:
		var target := atan2(-(_look_x - global_position.x), 6.0)
		_head.rotation.y = lerp_angle(_head.rotation.y, target, dt * 2.0)
		_head.rotation.z = sin(_t * 0.7) * 0.06 + _flinch * sin(_t * 40.0) * 0.25
		_head.rotation.x = sin(_t * 0.4) * 0.04
