## Spelarens arm. Wii-bowling-kast med musen:
##  - Sikta genom att flytta musen i sidled (utan att hålla in).
##  - Håll vänster knapp och dra NER: armen svingar bakåt (sats).
##  - Svep UPP och släpp: pinnen följer armens fart och vinkel.
## Fart = hur snabbt du sveper. Kastvinkel = var i svingen du släpper.
## Sidledsryck i svepet ger sidofart och snurr runt lodlinjen, och för
## mycket av det blir ett (förbjudet) helikopterkast.
class_name ThrowController
extends Node3D

signal thrown(baton: Baton, info: Dictionary)
signal dropped(baton: Baton)

const ARM_LEN := 0.62
const SHOULDER := Vector3(0.18, 1.38, 0.45)  # relativt spelarens plats
const THETA_MIN := -1.5   # längst bak i satsen
const THETA_MAX := 2.3    # rakt upp och lite till
const HIST := 6           # fysiktick att mäta svepets fart över
const MAX_SPEED := 16.0
const SPIN_FACTOR := 0.7  # ände-över-ände-snurr i förhållande till armen
const SIDE_K := 0.0008    # m/s sidofart per px/s sidledssvep
const YAW_K := 0.003      # rad/s helikoptersnurr per px/s sidledssvep
const MAX_AIM := 0.32

var sens := 1.0           # justeras med +/-
var power_gain := 1.0
var mouse_aim := true     # av i autotestet
var stand_x := 0.0
var aim := 0.0            # positiv = höger
var theta := 0.0          # armvinkel, 0 = rakt ner, positiv = framåt
var holding := false
var baton: Baton

var _drag := Vector2.ZERO
var _frame_dx := 0.0
var _theta_hist: Array[float] = []
var _latx_hist: Array[float] = []
var _press_mouse := Vector2.ZERO
var _arm: MeshInstance3D
var _hand: MeshInstance3D
var _aim_line: MeshInstance3D


func _ready() -> void:
	var skin := PS1.mat(null, Color(0.72, 0.66, 0.58))
	_arm = PS1.box(Vector3(0.075, ARM_LEN, 0.075), PS1.mat(PS1.cloth(), Color(5.5, 5.4, 5.0), Vector2(1, 3)))
	add_child(_arm)
	_hand = PS1.box(Vector3(0.08, 0.09, 0.06), skin)
	add_child(_hand)
	_aim_line = PS1.box(Vector3(0.025, 0.005, 5.0), PS1.mat(null, Color(0.9, 0.85, 0.6), Vector2.ONE, 0.6))
	add_child(_aim_line)


func px_to_rad() -> float:
	return 0.0055 * sens


func give_baton(b: Baton) -> void:
	baton = b
	b.hold()
	holding = false
	theta = 0.0
	_theta_hist.clear()
	_latx_hist.clear()
	_update_pose()


func _unhandled_input(e: InputEvent) -> void:
	if baton == null:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and not holding:
			holding = true
			_drag = Vector2.ZERO
			_press_mouse = get_viewport().get_mouse_position()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif not e.pressed and holding:
			_release()
	elif e is InputEventMouseMotion and holding:
		_drag += e.screen_relative
		_frame_dx += e.screen_relative.x


func _physics_process(dt: float) -> void:
	if baton == null:
		theta = lerpf(theta, 0.0, 0.06)
		_update_pose()
		return
	if holding:
		var k := px_to_rad()
		_drag.y = clampf(_drag.y, -THETA_MAX / k, -THETA_MIN / k)
		theta = -_drag.y * k
	else:
		var mv := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
		stand_x = clampf(stand_x + mv * 1.6 * dt, -2.3, 2.3)
		if mouse_aim:
			var vp := get_viewport()
			var mx := vp.get_mouse_position().x / maxf(vp.get_visible_rect().size.x, 1.0)
			aim = clampf((mx - 0.5) * 2.0, -1.0, 1.0) * MAX_AIM
		theta = lerpf(theta, 0.0, 0.15)
	_theta_hist.push_back(theta)
	_latx_hist.push_back(_frame_dx)
	_frame_dx = 0.0
	while _theta_hist.size() > HIST + 1:
		_theta_hist.pop_front()
		_latx_hist.pop_front()
	_update_pose()


func forward() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, -aim)


func shoulder() -> Vector3:
	return Vector3(stand_x, 0, 0) + SHOULDER


func _update_pose() -> void:
	var f := forward()
	var r := f.cross(Vector3.UP)
	var dir := (f * sin(theta) - Vector3.UP * cos(theta)).normalized()
	var sh := shoulder()
	var hand := sh + dir * ARM_LEN
	var b := Basis(r, dir, r.cross(dir))
	_arm.global_transform = Transform3D(b, sh + dir * ARM_LEN * 0.5)
	_hand.global_transform = Transform3D(b, hand)
	if baton:
		baton.global_transform = Transform3D(b, hand + dir * (Baton.LENGTH * 0.5 - 0.03))
	_aim_line.visible = baton != null
	var start := Vector3(stand_x + SHOULDER.x, 0.012, 0.0)
	_aim_line.global_transform = Transform3D(Basis(Vector3.UP, -aim), start + f * 3.0)


func _release() -> void:
	holding = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().warp_mouse(_press_mouse)
	var dt := 1.0 / Engine.physics_ticks_per_second
	var n := _theta_hist.size()
	var k := mini(HIST, n - 1)
	if k <= 0:
		_drop()
		return
	var omega := (_theta_hist[n - 1] - _theta_hist[n - 1 - k]) / (k * dt)
	var lat := 0.0
	for i in range(n - k, n):
		lat += _latx_hist[i]
	lat /= k * dt
	if omega < 2.0 or theta < 0.0:
		_drop()
	else:
		launch_with(theta, omega, lat)


func _drop() -> void:
	var b := baton
	baton = null
	b.launch(Vector3(0, -0.2, -0.3), Vector3.ZERO)
	dropped.emit(b)


## Själva kastet. Används också av autotestet.
func launch_with(th: float, omega: float, lat_px_s: float) -> void:
	theta = th
	_update_pose()
	var f := forward()
	var r := f.cross(Vector3.UP)
	var radius := ARM_LEN + Baton.LENGTH * 0.5 - 0.03
	var tangent := f * cos(th) + Vector3.UP * sin(th)
	var speed := minf(omega * radius * power_gain, MAX_SPEED)
	var v := tangent * speed + r * lat_px_s * SIDE_K
	var w := r * omega * SPIN_FACTOR + Vector3.UP * lat_px_s * YAW_K
	var b := baton
	baton = null
	b.launch(v, w)
	_aim_line.visible = false
	thrown.emit(b, {"speed": v.length(), "angle": rad_to_deg(th), "lat": lat_px_s})
