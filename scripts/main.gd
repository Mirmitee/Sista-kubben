## Spelets huvudnod: meny, match mot Vedgubben och träning på Gösta.
##
## Strukturen är tänkt att växa: World = platsen, Opponent = motståndare
## (repliker, fusk, eget kast senare), ThrowController = spelarens kast,
## Menu = alla menyer, Hud = allt som ritas ovanpå spelet.
extends Node3D

enum Mode { MENU, MATCH, TRAINING }
enum State { READY, FLYING, OVER }

const PLAYER_KUBBS_X := [-2.0, -1.0, 0.0, 1.0, 2.0]

var mode := Mode.MENU
var state := State.READY
var batons_per_round := 6
var batons_left := 6
var world: World
var opponent: Opponent
var dog: Dog
var thrower: ThrowController
var camera: Camera3D
var menu: Menu
var hud: Hud
var their_kubbs: Array[Kubb] = []
var my_kubbs: Array[Kubb] = []
var king: Kubb
var batons: Array[Baton] = []
var current: Baton
var stats := {"throws": 0, "hits": 0, "heli": 0, "longest": 0.0}

var _fly_time := 0.0
var _snapshot := {}
var _look := Vector3(0, 0.2, -8)
var _last_info := {}
var _last_dist := 0.0
var _hit_this_throw := false
var _shake := 0.0
var _orbit := 0.0
var _idle := 0.0
var _trail_tick := 0
var _shadow: MeshInstance3D
var _ghost: Node3D
var _trail_mat: Material
var _autotest := false


func _ready() -> void:
	randomize()
	_autotest = "--autotest" in OS.get_cmdline_user_args()
	world = World.new()
	add_child(world)
	opponent = preload("res://scripts/opponents/vedgubben.gd").new()
	opponent.position = Vector3(0.0, 0, -10.2)
	add_child(opponent)
	opponent.spoke.connect(_on_spoke)
	dog = Dog.new()
	dog.setup()
	add_child(dog)
	dog.spoke.connect(_on_spoke)
	_set_dog_active(false)

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

	_shadow = PS1.box(Vector3(0.09, 0.004, 0.3), PS1.mat(null, Color(0.02, 0.0, 0.01), Vector2.ONE, 1.0))
	_shadow.visible = false
	add_child(_shadow)
	_ghost = Node3D.new()
	var gm := PS1.mat(null, Color(0.9, 0.2, 0.15), Vector2.ONE, 0.8)
	for a in [0.785, -0.785]:
		var bar := PS1.box(Vector3(0.03, 0.004, 0.22), gm)
		bar.rotation.y = a
		_ghost.add_child(bar)
	_ghost.visible = false
	add_child(_ghost)
	_trail_mat = PS1.mat(null, Color(0.95, 0.8, 0.6), Vector2.ONE, 1.0)

	hud = Hud.new()
	add_child(hud)
	menu = Menu.new()
	add_child(menu)
	menu.play_pressed.connect(func(): _start(Mode.MATCH))
	menu.training_pressed.connect(func(): _start(Mode.TRAINING))
	menu.resume_pressed.connect(_resume)
	menu.restart_pressed.connect(func():
		_resume()
		_new_round())
	menu.main_menu_pressed.connect(_to_menu)
	Lang.changed.connect(_refresh_ui)
	Settings.changed.connect(_refresh_ui)
	Sfx.start_ambience()

	if _autotest:
		_start(Mode.MATCH, true)
		_run_autotest()
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_screenshots(a.substr(7))
			return
	_to_menu()


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
	for k in their_kubbs + my_kubbs + [king]:
		k.landed.connect(func(v: float): Sfx.play("clack2", linear_to_db(clampf(v * 0.4, 0.05, 1.0)) - 4.0, 0.8))


# ---------------------------------------------------------------- lägen

func _to_menu() -> void:
	get_tree().paused = false
	mode = Mode.MENU
	thrower.cancel_hold()
	thrower.input_enabled = false
	_clear_batons()
	_set_dog_active(false)
	_set_kubbs_active(true)
	for k in their_kubbs + my_kubbs + [king]:
		k.go_home()
	menu.paused_menu = false
	menu.open("title")
	hud.set_playing(false)
	hud.fade_in()


func _start(m: Mode, instant := false) -> void:
	if not instant:
		await hud.fade_out()
	mode = m
	menu.close()
	menu.paused_menu = false
	get_tree().paused = false
	_set_dog_active(m == Mode.TRAINING)
	_set_kubbs_active(m == Mode.MATCH)
	batons_per_round = 8 if Settings.rules == "simple" else 6
	thrower.input_enabled = true
	hud.set_playing(true)
	_new_round()
	if not instant:
		hud.fade_in()


func _pause() -> void:
	if mode == Mode.MENU or get_tree().paused:
		return
	thrower.cancel_hold()
	get_tree().paused = true
	menu.paused_menu = true
	menu.open("pause")


func _resume() -> void:
	get_tree().paused = false
	menu.close()


func _set_dog_active(on: bool) -> void:
	dog.visible = on
	dog.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	dog.collision_layer = 1 if on else 0
	dog.global_position = Vector3(0.5, 0, -6.0)
	opponent.visible = true


func _set_kubbs_active(on: bool) -> void:
	for k in their_kubbs + [king]:
		k.visible = on
		k.collision_layer = 1 if on else 0
		k.collision_mask = 1 if on else 0
		k.freeze = not on


func _clear_batons() -> void:
	for b in batons:
		if is_instance_valid(b):
			b.queue_free()
	batons.clear()
	current = null
	if thrower.baton:
		thrower.baton = null


func _new_round() -> void:
	_clear_batons()
	for k in their_kubbs + my_kubbs + [king]:
		k.go_home()
	batons_left = batons_per_round
	stats = {"throws": 0, "hits": 0, "heli": 0, "longest": 0.0}
	dog.hits = 0
	hud.center("")
	state = State.READY
	_ghost.visible = false
	_next_baton()
	if mode == Mode.TRAINING:
		dog.say("start")
	else:
		opponent.say("start")


func _next_baton() -> void:
	if mode == Mode.MATCH and batons_left <= 0:
		return
	var b := Baton.new()
	b.setup()
	add_child(b)
	b.body_entered.connect(_on_baton_hit.bind(b))
	batons.append(b)
	current = b
	thrower.give_baton(b)
	state = State.READY
	_idle = 0.0
	# gamla pinnar i träningen städas bort
	while mode == Mode.TRAINING and batons.size() > 7:
		batons.pop_front().queue_free()
	_refresh_ui()


# ---------------------------------------------------------------- kast

func _on_thrown(b: Baton, info: Dictionary) -> void:
	_last_info = info
	if mode == Mode.MATCH:
		batons_left -= 1
	stats.throws += 1
	_take_snapshot()
	_fly_time = 0.0
	_hit_this_throw = false
	state = State.FLYING
	Sfx.play("whoosh", -4.0, 0.8 + info.speed * 0.04)
	hud.show_throw(info.speed / ThrowController.MAX_SPEED)
	if info.has("grade"):
		hud.flash(Lang.t("grade_" + info.grade))
		if info.grade == "perfect":
			Sfx.play("click", -2.0, 1.6)
	_refresh_ui()


func _on_dropped(b: Baton) -> void:
	_say("drop")
	batons.erase(b)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(b.queue_free)
	_next_baton()


func _on_baton_hit(body: Node, b: Baton) -> void:
	if b != current:
		return
	if body is Kubb:
		Sfx.play("clack", 0.0, 1.0 if not body.is_king else 0.7)
		if not _hit_this_throw:
			_hit_this_throw = true
			_slowmo()
			_shake = 0.35
			hud.popup(camera.unproject_position(b.global_position), "KLONK!" if randf() < 0.7 else "BONK!")
	elif body is Dog:
		if not _hit_this_throw:
			_hit_this_throw = true
			dog.bonk()
			_slowmo()
			_shake = 0.5
			hud.popup(camera.unproject_position(b.global_position), "VOFF!")
	else:
		Sfx.play("thud", linear_to_db(clampf(b.linear_velocity.length() / 8.0, 0.1, 1.0)))


func _slowmo() -> void:
	if _autotest:
		return
	Engine.time_scale = 0.3
	await get_tree().create_timer(0.35, true, false, true).timeout
	var tw := create_tween()
	tw.tween_property(Engine, "time_scale", 1.0, 0.08)


func _take_snapshot() -> void:
	_snapshot.clear()
	for k in their_kubbs + my_kubbs + [king]:
		_snapshot[k] = k.global_transform


func _physics_process(dt: float) -> void:
	if state == State.READY and mode != Mode.MENU and not thrower.holding:
		_idle += dt
		if _idle > 14.0:
			_idle = 0.0
			if mode == Mode.MATCH:
				opponent.say("idle")
	if state != State.FLYING or current == null:
		_shadow.visible = false
		return
	_fly_time += dt
	# skugga och spår
	var p := current.global_position
	_shadow.visible = not current.touched
	_shadow.global_transform = Transform3D(Basis(Vector3.UP, current.global_rotation.y), Vector3(p.x, 0.014, p.z))
	_trail_tick += 1
	if not current.touched and _trail_tick % 3 == 0:
		_spawn_trail(p)
	var moving := false
	for k in their_kubbs + [king]:
		if k.visible and not k.sleeping and k.linear_velocity.length() > 0.08:
			moving = true
	var gone := p.y < -2.0 or p.length() > 40.0
	if (_fly_time > 0.8 and current.is_settled() and not moving) or _fly_time > 7.0 or gone:
		_evaluate()


func _spawn_trail(p: Vector3) -> void:
	var t := PS1.box(Vector3(0.025, 0.025, 0.025), _trail_mat)
	add_child(t)
	t.global_position = p
	var tw := create_tween()
	tw.tween_property(t, "scale", Vector3.ONE * 0.01, 0.45)
	tw.tween_callback(t.queue_free)


func _evaluate() -> void:
	var b := current
	current = null
	var land := b.first_contact if b.touched else b.global_position
	_last_dist = Vector2(land.x - b.release_pos.x, land.z - b.release_pos.z).length()
	if b.touched:
		_ghost.global_position = Vector3(land.x, 0.016, land.z)
		_ghost.visible = Settings.aim_assist
	stats.longest = maxf(stats.longest, _last_dist)

	if mode == Mode.TRAINING:
		if not _hit_this_throw:
			dog.say("miss")
		_after_throw()
		return

	if b.helicopter:
		for k in _snapshot:
			k.teleport(_snapshot[k])
		stats.heli += 1
		_say("helicopter")
		Sfx.play("bad", -4.0)
		hud.flash(Lang.t("heli"))
		_log("HELIKOPTER yaw=%.2f" % b.yaw_accum)
		_after_throw()
		return

	var newly := 0
	for k in their_kubbs:
		if k.is_fallen() and not k.was_fallen:
			k.was_fallen = true
			newly += 1
	stats.hits += newly
	var all_down := _fallen_count() == their_kubbs.size()
	_log("kast: fart %.2f vinkel %d lat %.0f -> landade %.2f m, nya fällda %d, kung %s" % [
		_last_info.get("speed", 0.0), int(_last_info.get("angle", 0.0)), _last_info.get("lat", 0.0),
		_last_dist, newly, str(king.is_fallen())])

	if king.is_fallen():
		opponent.flinch()
		var had_all := _fallen_before_throw() == their_kubbs.size()
		if had_all:
			state = State.OVER
			opponent.say("king_win")
			hud.center(Lang.t("king_win") + "\n" + _summary())
		elif Settings.rules == "simple":
			opponent.say("king_simple")
			king.go_home()
			_after_throw()
		else:
			state = State.OVER
			opponent.say("king_early")
			Sfx.play("bad", 0.0, 0.7)
			hud.center(Lang.t("king_early"))
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
	elif land.z > -6.3:
		opponent.say("short")
	elif land.z < -9.5 or absf(land.x) > 3.5:
		opponent.say("long")
	elif _near_miss(b):
		opponent.say("close")
	else:
		opponent.say("miss")

	if all_down and newly > 0:
		opponent.say("all_down")
	_after_throw()


func _near_miss(b: Baton) -> bool:
	for k in their_kubbs:
		if not k.was_fallen and k.global_position.distance_to(b.global_position) < 0.45:
			return true
	return false


func _say(event: String) -> void:
	if mode == Mode.TRAINING:
		dog.say("miss")
	else:
		opponent.say(event)


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


func _summary() -> String:
	return Lang.t("summary") % [stats.hits, stats.throws, stats.longest, stats.heli]


func _after_throw() -> void:
	if mode == Mode.TRAINING or batons_left > 0:
		_next_baton()
	else:
		state = State.OVER
		var n := _fallen_count()
		var head := Lang.t("all_down") if n == their_kubbs.size() else Lang.t("round_over") % [n, their_kubbs.size()]
		hud.center(head + "\n" + _summary())
		if n == 0:
			opponent.say("round_zero")
	_refresh_ui()


# ---------------------------------------------------------------- kamera

func _process(dt: float) -> void:
	var sx := thrower.stand_x
	var cam_pos: Vector3
	var want: Vector3
	if mode == Mode.MENU:
		_orbit += dt * 0.05
		cam_pos = Vector3(sin(_orbit) * 5.5, 1.6 + sin(_orbit * 2.3) * 0.2, -4.0 + cos(_orbit) * 7.5)
		want = Vector3(0, 1.2, -9.0)
		_look = _look.lerp(want, clampf(dt * 2.0, 0.0, 1.0))
	else:
		cam_pos = Vector3(sx - 0.25, 1.75, 2.1)
		want = Vector3(sx * 0.4 + thrower.aim * 6.0, 0.15, -8.0)
		if state == State.FLYING and current:
			var p := current.global_position
			want = Vector3(p.x, minf(p.y, 3.0) * 0.6, minf(p.z, -3.0))
		_look = _look.lerp(want, clampf(dt * 3.0, 0.0, 1.0))
	_shake = move_toward(_shake, 0.0, dt)
	var jitter := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.06
	camera.look_at_from_position(cam_pos + jitter, _look)
	var zoom := mode != Mode.MENU and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	camera.fov = lerpf(camera.fov, 20.0 if zoom else 40.0, clampf(dt * 8.0, 0.0, 1.0))
	world.follow_camera(cam_pos)
	if mode == Mode.MENU:
		opponent.look_at_x(cam_pos.x)
	else:
		opponent.look_at_x(current.global_position.x if current else sx)
	if mode != Mode.MENU:
		if Settings.throw_mode == "meter":
			hud.update_timing(thrower.meter_phase, thrower.meter, thrower.meter_power, thrower.meter_cursor)
		else:
			hud.update_meter(thrower.meter, thrower.holding, rad_to_deg(thrower.theta))


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_START):
		if mode == Mode.MENU:
			menu.back()
		else:
			_pause()
		return
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_F11:
				Settings.set_value("fullscreen", not Settings.fullscreen)
			KEY_L:
				Lang.toggle()
				Settings.save()
			KEY_H:
				Settings.set_value("show_hints", not Settings.show_hints)
			KEY_R:
				if mode != Mode.MENU and not thrower.holding:
					_new_round()
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				Settings.set_value("sensitivity", minf(Settings.sensitivity + 0.1, 2.5))
			KEY_MINUS, KEY_KP_SUBTRACT:
				Settings.set_value("sensitivity", maxf(Settings.sensitivity - 0.1, 0.3))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and thrower and thrower.holding:
		thrower.cancel_hold()


# ---------------------------------------------------------------- UI

func _refresh_ui() -> void:
	if hud == null:
		return
	var fallen: Array[bool] = []
	for k in their_kubbs:
		fallen.append(k.was_fallen)
	hud.refresh(mode == Mode.TRAINING, batons_left, batons_per_round, fallen, dog.hits, _last_info, _last_dist)


func _on_spoke(who: String, text: String) -> void:
	hud.speech(who, text)
	_log("[%s] %s" % [who, text])


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
	Settings.throw_mode = "drag"
	for i in 240:
		await get_tree().physics_frame
	var standing := 0
	for k in their_kubbs + my_kubbs + [king]:
		if not k.is_fallen():
			standing += 1
	print("TEST stående efter 2 s: %d/11" % standing)
	var cases := []
	if "--sweep" in OS.get_cmdline_user_args():
		for px in range(1500, 6001, 500):
			cases.append([0.6, float(px), 0.0, 0.0, -0.18, "svep %d px/s" % px])
	else:
		cases = [
			# [vinkel, svep upp px/s, sidled px/s, sikte, plats, namn]
			[0.6, 2900.0, 0.0, 0.0, -0.18, "rakt på mittkubben"],
			[0.5, 3100.0, 0.0, 0.0, -2.18, "vänster kubb"],
			[0.7, 1200.0, 0.0, 0.0, 0.0, "för svagt"],
			[0.6, 2900.0, 700.0, 0.0, 0.0, "lite snett (ska INTE bli helikopter)"],
			[0.6, 2900.0, 2200.0, 0.0, 1.0, "väldigt snett (helikopter)"],
			[0.55, 3000.0, 0.0, 0.0, 1.82, "höger kubb"],
			[1.9, 3000.0, 0.0, 0.0, 0.0, "mot månen"],
			[0.6, 9000.0, 0.0, 0.0, 0.0, "maxfart"],
		]
	for c in cases:
		while state == State.FLYING:
			await get_tree().physics_frame
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
		print("   slut %s heli=%s yaw=%.2f luft=%.2fs" % [str(b.global_position.snapped(Vector3.ONE * 0.01)), b.helicopter, b.yaw_accum, b.air_time])
	# mätarläget
	Settings.throw_mode = "meter"
	var sweet := ThrowController.SWEET_SPEED / ThrowController.MAX_SPEED
	for mc in [[sweet, 0.0, -0.18, "mätare perfekt"], [sweet, 0.5, -0.18, "mätare snett"], [sweet, 0.95, 0.0, "mätare fummel"], [0.5, 0.0, 0.0, "mätare halv kraft"]]:
		while state == State.FLYING:
			await get_tree().physics_frame
		_new_round()
		await _wait_ready()
		thrower.stand_x = mc[2]
		thrower.aim = 0.0
		await get_tree().physics_frame
		print("TEST %s" % mc[3])
		thrower.launch_meter(mc[0], mc[1])
		var mb := batons[-1]
		await get_tree().physics_frame
		while state == State.FLYING:
			await get_tree().physics_frame
		print("   slut %s heli=%s" % [str(mb.global_position.snapped(Vector3.ONE * 0.01)), mb.helicopter])
	# tajmingflödet med riktiga tryck
	while state == State.FLYING:
		await get_tree().physics_frame
	_new_round()
	await _wait_ready()
	thrower._meter_press()
	for i in 100:
		await get_tree().physics_frame
	thrower._meter_press()
	for i in 36:
		await get_tree().physics_frame
	print("TEST tajming: kraft %.2f markör %.2f" % [thrower.meter_power, thrower.meter_cursor])
	thrower._meter_press()
	while state == State.FLYING or thrower.baton == null:
		await get_tree().physics_frame
	Settings.throw_mode = "drag"
	# träning: kasta på hunden
	_start(Mode.TRAINING, true)
	for i in 3:
		await _wait_ready()
		dog.set_physics_process(false)
		dog.global_position = Vector3(-0.18 + 0.18, 0, -6.0)
		dog.rotation.y = PI * 0.5
		thrower.stand_x = -0.18
		thrower.aim = 0.0
		await get_tree().physics_frame
		thrower.launch_with(0.6, 2050.0 + i * 100.0, 0.0)
		while state == State.FLYING:
			await get_tree().physics_frame
	print("TEST hundträffar %d/3" % dog.hits)
	print("TEST klart")
	get_tree().quit()


# Kör: godot --rendering-driver opengl3 -- --shot=/sökväg/bild
func _screenshots(prefix: String) -> void:
	var vp := get_viewport()
	_to_menu()
	for i in 90:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_meny.png")
	menu.show_page("settings")
	for i in 5:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_installningar.png")
	_start(Mode.MATCH, true)
	thrower.mouse_aim = false
	thrower.stand_x = -0.18
	for i in 40:
		await get_tree().process_frame
	thrower.theta = -0.9
	thrower.set_physics_process(false)
	thrower._update_pose()
	thrower.meter_phase = 2
	thrower.meter_power = 0.81
	thrower.meter_cursor = -0.25
	for i in 3:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_sats.png")
	thrower.set_physics_process(true)
	thrower.meter_phase = 0
	thrower.launch_meter(0.83, 0.05)
	for i in 45:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_flygning.png")
	_start(Mode.TRAINING, true)
	for i in 60:
		await get_tree().process_frame
	dog.global_position = Vector3(0.3, 0, -4.5)
	dog.rotation.y = 2.2
	for i in 5:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_gosta.png")
	_pause()
	for i in 5:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_paus.png")
	get_tree().quit()
