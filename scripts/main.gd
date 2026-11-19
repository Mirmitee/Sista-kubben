## Kastprototypen: en runda med 6 pinnar mot Vedgubbens 5 baslinjekubbar.
## Kungen står i mitten och får bara fällas när alla baskubbar ligger.
##
## Strukturen är tänkt att växa: World = platsen, Opponent = motståndare
## (repliker, fusk, eget kast senare), ThrowController = spelarens kast.
## Regelvarianter (riktig/förenklad), kort, tänder och akter kommer ovanpå.
extends Node3D

enum State { READY, FLYING, OVER }

const BATONS_PER_ROUND := 6
const PLAYER_KUBBS_X := [-2.0, -1.0, 0.0, 1.0, 2.0]

var state := State.READY
var batons_left := BATONS_PER_ROUND
var world: World
var opponent: Opponent
var thrower: ThrowController
var camera: Camera3D
var their_kubbs: Array[Kubb] = []
var my_kubbs: Array[Kubb] = []
var king: Kubb
var batons: Array[Baton] = []
var current: Baton
var _fly_time := 0.0
var _snapshot := {}
var _look := Vector3(0, 0.2, -8)
var _last_info := {}
var _last_dist := 0.0
var _autotest := false

var _speech: Label
var _hud: Label
var _hint: Label
var _center: Label
var _speech_tween: Tween


func _ready() -> void:
	randomize()
	_autotest = "--autotest" in OS.get_cmdline_user_args()
	world = World.new()
	add_child(world)
	opponent = preload("res://scripts/opponents/vedgubben.gd").new()
	opponent.position = Vector3(0.0, 0, -10.2)
	add_child(opponent)
	opponent.spoke.connect(_on_spoke)

	camera = Camera3D.new()
	camera.fov = 40
	camera.far = 300
	camera.near = 0.05
	add_child(camera)

	_spawn_kubbs()
	thrower = ThrowController.new()
	add_child(thrower)
	thrower.thrown.connect(_on_thrown)
	thrower.dropped.connect(_on_dropped)
	_build_ui()
	Lang.changed.connect(_refresh_ui)
	_new_round()
	if _autotest:
		_run_autotest()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_screenshots(a.substr(7))


func _spawn_kubbs() -> void:
	for i in 5:
		var k := Kubb.new()
		k.setup(false, 100 + i)
		add_child(k)
		k.home = Transform3D(Basis(Vector3.UP, randf_range(-0.2, 0.2)), Vector3(PLAYER_KUBBS_X[i], Kubb.SIZE.y * 0.5, -World.FIELD_L))
		their_kubbs.append(k)
		var m := Kubb.new()
		m.setup(false, 200 + i)
		add_child(m)
		m.home = Transform3D(Basis(Vector3.UP, randf_range(-0.2, 0.2)), Vector3(PLAYER_KUBBS_X[i], Kubb.SIZE.y * 0.5, 0.0))
		my_kubbs.append(m)
	king = Kubb.new()
	king.setup(true, 77)
	add_child(king)
	king.home = Transform3D(Basis.IDENTITY, Vector3(0, Kubb.KING_SIZE.y * 0.5, -World.FIELD_L * 0.5))


func _new_round() -> void:
	for b in batons:
		b.queue_free()
	batons.clear()
	for k in their_kubbs + my_kubbs + [king]:
		k.go_home()
	batons_left = BATONS_PER_ROUND
	_center.text = ""
	state = State.READY
	_next_baton()
	opponent.say("start")


func _next_baton() -> void:
	if batons_left <= 0:
		return
	var b := Baton.new()
	b.setup()
	add_child(b)
	batons.append(b)
	current = b
	thrower.give_baton(b)
	state = State.READY
	_refresh_ui()


func _on_thrown(b: Baton, info: Dictionary) -> void:
	_last_info = info
	batons_left -= 1
	_take_snapshot()
	_fly_time = 0.0
	state = State.FLYING
	_refresh_ui()


func _on_dropped(b: Baton) -> void:
	opponent.say("drop")
	batons.erase(b)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(b.queue_free)
	_next_baton()


func _take_snapshot() -> void:
	_snapshot.clear()
	for k in their_kubbs + my_kubbs + [king]:
		_snapshot[k] = k.global_transform


func _physics_process(dt: float) -> void:
	if state != State.FLYING or current == null:
		return
	_fly_time += dt
	var moving := false
	for k in their_kubbs + [king]:
		if not k.sleeping and k.linear_velocity.length() > 0.08:
			moving = true
	var gone := current.global_position.y < -2.0 or current.global_position.length() > 40.0
	if (_fly_time > 0.8 and current.is_settled() and not moving) or _fly_time > 7.0 or gone:
		_evaluate()


func _evaluate() -> void:
	var b := current
	current = null
	_last_dist = Vector2(b.global_position.x - b.release_pos.x, b.global_position.z - b.release_pos.z).length()
	if b.touched:
		_last_dist = Vector2(b.first_contact.x - b.release_pos.x, b.first_contact.z - b.release_pos.z).length()

	if b.helicopter:
		for k in _snapshot:
			k.teleport(_snapshot[k])
		opponent.say("helicopter")
		_flash(Lang.t("heli"))
		_log("HELIKOPTER yaw=%.2f" % b.yaw_accum)
		_after_throw()
		return

	var newly := 0
	for k in their_kubbs:
		if k.is_fallen() and not k.was_fallen:
			k.was_fallen = true
			newly += 1
	var all_down := _fallen_count() == their_kubbs.size()
	_log("kast: fart %.2f vinkel %d lat %.0f -> landade %.2f m, nya fällda %d, kung %s" % [
		_last_info.get("speed", 0.0), int(_last_info.get("angle", 0.0)), _last_info.get("lat", 0.0),
		_last_dist, newly, str(king.is_fallen())])

	if king.is_fallen():
		# Kungen räknas bara som vinst om alla baskubbar låg innan kastet.
		var had_all := _fallen_before_throw() == their_kubbs.size()
		state = State.OVER
		if had_all:
			opponent.say("king_win")
			_center.text = Lang.t("king_win")
		else:
			opponent.say("king_early")
			_center.text = Lang.t("king_early")
		opponent.flinch()
		_refresh_ui()
		return

	if newly >= 2:
		opponent.say("double")
		opponent.flinch()
	elif newly == 1:
		opponent.say("hit")
		opponent.flinch()
	elif _last_info.get("angle", 0.0) > 95.0:
		opponent.say("sky")
	else:
		opponent.say("miss")

	if all_down and newly > 0:
		opponent.say("all_down")
	_after_throw()


func _fallen_before_throw() -> int:
	var n := 0
	for k in their_kubbs:
		if _snapshot.has(k) and _snapshot[k].basis.y.normalized().dot(Vector3.UP) < 0.5:
			n += 1
	return n


func _fallen_count() -> int:
	var n := 0
	for k in their_kubbs:
		if k.was_fallen:
			n += 1
	return n


func _after_throw() -> void:
	if batons_left > 0:
		_next_baton()
	else:
		state = State.OVER
		var n := _fallen_count()
		_center.text = Lang.t("all_down") if n == their_kubbs.size() else Lang.t("round_over") % [n, their_kubbs.size()]
	_refresh_ui()


func _process(dt: float) -> void:
	var sx := thrower.stand_x
	var cam_pos := Vector3(sx - 0.25, 1.75, 2.1)
	var want := Vector3(sx * 0.4 + thrower.aim * 6.0, 0.15, -8.0)
	if state == State.FLYING and current:
		var p := current.global_position
		want = Vector3(p.x, minf(p.y, 3.0) * 0.6, minf(p.z, -3.0))
	_look = _look.lerp(want, clampf(dt * 3.0, 0.0, 1.0))
	camera.look_at_from_position(cam_pos, _look)
	# höger musknapp: fokusera blicken (zoom)
	var zoom := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	camera.fov = lerpf(camera.fov, 20.0 if zoom else 40.0, clampf(dt * 8.0, 0.0, 1.0))
	world.follow_camera(cam_pos)
	opponent.look_at_x(current.global_position.x if current else sx)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_R:
				if not thrower.holding:
					if current and state == State.FLYING:
						current = null
					_new_round()
			KEY_L:
				Lang.toggle()
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				thrower.sens = minf(thrower.sens + 0.1, 3.0)
				_refresh_ui()
			KEY_MINUS, KEY_KP_SUBTRACT:
				thrower.sens = maxf(thrower.sens - 0.1, 0.3)
				_refresh_ui()
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# ---------------------------------------------------------------- UI

func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.shadow_color = Color(0, 0, 0, 0.9)
	ls.shadow_offset = Vector2(1, 1)
	ls.shadow_size = 0
	l.label_settings = ls
	return l


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	_speech = _label(8, Color(0.95, 0.85, 0.75))
	_speech.position = Vector2(8, 6)
	_speech.size = Vector2(368, 40)
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD
	ui.add_child(_speech)
	_hud = _label(8, Color(0.9, 0.9, 0.8))
	_hud.position = Vector2(8, 238)
	ui.add_child(_hud)
	_hint = _label(8, Color(0.75, 0.6, 0.6))
	_hint.position = Vector2(8, 252)
	ui.add_child(_hint)
	_center = _label(14, Color(1.0, 0.3, 0.2))
	_center.position = Vector2(0, 100)
	_center.size = Vector2(384, 80)
	_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(_center)
	var title := _label(8, Color(0.8, 0.15, 0.1))
	title.text = "SISTA KUBBEN v0.1"
	title.position = Vector2(300, 276)
	ui.add_child(title)


func _refresh_ui() -> void:
	var lines := [Lang.t("hud") % [batons_left, BATONS_PER_ROUND, _fallen_count(), their_kubbs.size()]
		+ "   " + Lang.t("sens") % thrower.sens]
	if not _last_info.is_empty():
		lines.append(Lang.t("last") % [_last_info.speed, int(_last_info.angle), _last_dist])
	_hud.text = "\n".join(lines)
	_hud.position.y = 238 - (10 if lines.size() > 1 else 0)
	_hint.text = Lang.t("hint1") + " " + Lang.t("hint2") + "\n" + Lang.t("hint3")
	_hint.position.y = 254


func _on_spoke(who: String, text: String) -> void:
	_speech.text = who + ": " + text
	_speech.visible_ratio = 0.0
	if _speech_tween:
		_speech_tween.kill()
	_speech_tween = create_tween()
	_speech_tween.tween_property(_speech, "visible_ratio", 1.0, 0.02 * _speech.text.length())
	_log("[%s] %s" % [who, text])


func _flash(text: String) -> void:
	_center.text = text
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_callback(func(): if state != State.OVER: _center.text = "")


func _log(s: String) -> void:
	if _autotest or OS.is_debug_build():
		print(s)


# ---------------------------------------------------------------- autotest
# Kör: godot --headless --fixed-fps 120 -- --autotest

func _wait_ready() -> void:
	while state != State.READY or thrower.baton == null:
		await get_tree().physics_frame


func _run_autotest() -> void:
	thrower.mouse_aim = false
	# låt kubbarna stå still en stund: ingen ska ramla av sig själv
	for i in 240:
		await get_tree().physics_frame
	var standing := 0
	for k in their_kubbs + my_kubbs + [king]:
		if not k.is_fallen():
			standing += 1
	print("TEST stående efter 2 s: %d/11" % standing)
	var cases := []
	if "--sweep" in OS.get_cmdline_user_args():
		for o in range(110, 128, 1):
			cases.append([0.6, o / 10.0, 0.0, 0.0, -0.18, "svep %.1f" % (o / 10.0)])
	else: cases = [
		# [theta, omega, lat px/s, aim, stand_x, namn]
		[0.6, 11.7, 0.0, 0.0, -0.18, "rakt på mittkubben"],
		[0.5, 12.0, 0.0, 0.0, -2.18, "vänster kubb"],
		[0.7, 7.0, 0.0, 0.0, 0.0, "för svagt"],
		[0.6, 11.5, 1300.0, 0.0, 1.0, "helikopter"],
		[0.55, 12.0, 0.0, 0.0, 1.82, "höger kubb"],
		[1.9, 12.0, 0.0, 0.0, 0.0, "mot månen"],
	]
	for c in cases:
		await _wait_ready()
		if state == State.OVER or "--sweep" in OS.get_cmdline_user_args():
			_new_round()
			await _wait_ready()
		thrower.stand_x = c[4]
		thrower.aim = c[3]
		await get_tree().physics_frame
		print("TEST %s" % c[5])
		thrower.launch_with(c[0], c[1], c[2])
		var b := batons[-1]
		await get_tree().physics_frame
		while state == State.FLYING:
			await get_tree().physics_frame
		print("   slut %s" % str(b.global_position.snapped(Vector3.ONE * 0.01)))
		print("   -> heli=%s yaw=%.2f luft=%.2fs träff=%s" % [b.helicopter, b.yaw_accum, b.air_time, b.first_hit.name if b.first_hit else "-"])
	print("TEST klart, fällda %d" % _fallen_count())
	get_tree().quit()


# Kör: godot --rendering-driver opengl3 -- --shot=/sökväg/bild
func _screenshots(prefix: String) -> void:
	thrower.mouse_aim = false
	thrower.stand_x = -0.18
	for i in 40:
		await get_tree().process_frame
	thrower.theta = -0.9
	thrower.set_physics_process(false)
	thrower._update_pose()
	for i in 5:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(prefix + "_1.png")
	thrower.set_physics_process(true)
	thrower.launch_with(0.6, 11.7, 0.0)
	for i in 50:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(prefix + "_2.png")
	while state == State.FLYING:
		await get_tree().process_frame
	for i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(prefix + "_3.png")
	get_tree().quit()
