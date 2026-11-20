## Basklass för motståndare. Varje motståndare har ett namn, repliker
## på svenska och engelska, ett utseende, ett eget kast (en arm som
## svingar), hur träffsäker den är och egna fusk/specialregler.
## Lägg nya motståndare som egna skript bredvid.
class_name Opponent
extends Node3D

signal spoke(who: String, text: String)

var display_name := {"sv": "???", "en": "???"}
## händelse -> {"sv": [...], "en": [...]}
var lines := {}
## Kastfel: sidled (rad) och fart (andel). Natten gör dem bättre.
var error_yaw := 0.03
var error_speed := 0.05
var baton_push := 1.0     # hur hårt hans pinnar knuffar
var player_batons_add := 0  # fusk som påverkar spelarens pinnar
var extra_batons := 0       # fler pinnar för motståndaren
var steal_bonus := 0.0      # extra multi när han stjäl poäng
var phase := 1              # bossfas
## Svårighet: alla motståndare kastar så här mycket bättre än förut.
const DIFFICULTY := 0.85
var rule_text := {"sv": "", "en": ""}

var _head: Node3D
var _arm_pivot: Node3D
var _arm_len := 1.0
var _look_x := 0.0
var _flinch := 0.0
var _t := 0.0
var _swing := 0.0         # armens vinkel (positiv = bakåt)


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


## Modifierare för Run (t.ex. snabbare markör). Överskrids per motståndare.
func mods_for_night(_night: int) -> Dictionary:
	return {}


func setup_for_night(night: int) -> void:
	var k := maxf(pow(0.8, night - 1), 0.25) * DIFFICULTY
	error_yaw *= k
	error_speed *= k


func hand_pos() -> Vector3:
	if _arm_pivot == null:
		return global_position + Vector3(0.4, 1.2, 0.4)
	return _arm_pivot.global_transform * Vector3(0, -_arm_len, 0.05)


## Ta sats och svinga. Awaita den: returnerar när handen är i släppläget.
func swing_back_and_forth() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_swing", 1.1, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "_swing", -0.55, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	var back := create_tween()
	back.tween_property(self, "_swing", 0.0, 0.6).set_delay(0.2)


func walk_to_z(z: float, t := 0.8) -> void:
	if absf(position.z - z) < 0.02:
		return
	var tw := create_tween()
	tw.tween_property(self, "position:z", z, t).set_trans(Tween.TRANS_SINE)
	await tw.finished


func walk_to_x(x: float, t := 0.6) -> void:
	var tw := create_tween()
	tw.tween_property(self, "position:x", x, t).set_trans(Tween.TRANS_SINE)
	await tw.finished


func _process(dt: float) -> void:
	_t += dt
	_flinch = move_toward(_flinch, 0.0, dt * 1.5)
	if _arm_pivot:
		_arm_pivot.rotation.x = _swing
	if _head:
		var target := atan2(-(_look_x - global_position.x), 6.0)
		_head.rotation.y = lerp_angle(_head.rotation.y, target, dt * 2.0)
		_head.rotation.z = sin(_t * 0.7) * 0.06 + _flinch * sin(_t * 40.0) * 0.25
		_head.rotation.x = sin(_t * 0.4) * 0.04
