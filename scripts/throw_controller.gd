## Spelarens arm. Wii-bowling-kast med musen:
##  - Sikta genom att flytta musen i sidled (utan att hålla in).
##  - Håll vänster knapp och dra NER: armen svingar bakåt (sats).
##  - Svep UPP och släpp.
##
## Kraften kommer från svepets TOPPFART under de senaste 0,2 sekunderna,
## genom en mjuk kurva, så små skillnader i fart ger små skillnader i
## längd. Kastvinkeln är armens vinkel i just det ögonblicket. Därför gör
## det inget om du hinner stanna innan du släpper knappen.
## Sneda svep ger lite sidofart och snurr runt lodlinjen (efter en
## dödzon), och riktigt sneda svep blir förbjudna helikopterkast.
class_name ThrowController
extends Node3D

signal thrown(baton: RigidBody3D, info: Dictionary)
signal dropped(baton: RigidBody3D)
signal tossed(kubb: RigidBody3D)

const ARM_LEN := 0.62
const SHOULDER := Vector3(0.18, 1.38, 0.45)  # relativt spelarens plats
const THETA_MIN := -1.5    # längst bak i satsen
const THETA_MAX := 2.3     # rakt upp och lite till
const PX_TO_RAD := 0.0036  # armens rörelse per pixel (vid känslighet 1)
const WINDOW := 24         # fysiktick (0,2 s) att leta toppfart i
const SMOOTH := 5          # tick att medla farten över
const MAX_SPEED := 10.5    # m/s, kurvans tak (räcker till ~11 m)
const SPEED_K := 1600.0    # px/s där kurvan nått ~63 %
const MIN_PX_S := 350.0    # långsammare än så = du tappar pinnen
const SPIN_FACTOR := 0.75  # ände-över-ände-snurr (rad/s per m/s)
const LAT_DEAD := 450.0    # px/s sidled som ignoreras helt
const SIDE_K := 0.00025    # m/s sidofart per px/s utöver dödzonen
const YAW_K := 0.0025      # rad/s helikoptersnurr per px/s utöver dödzonen
const MAX_AIM := 0.30
## Fart för att nå motståndarens baslinje med ett normalt kast (~35°),
## visas som "söt punkt" på kraftmätaren.
const SWEET_SPEED := 8.7
const PAD_SCALE := 0.45    # gamepad-spakar är snabbare än en mus

## Mätarläget (standard), som i gamla RPG- och golfspel:
## tryck 1 = börja ta sats, kraftmätaren fylls (och töms igen),
## tryck 2 = lås kraften, armen svingar framåt och en markör sveper
##           över precisionsmätaren,
## tryck 3 = släpp. Mitt i det gröna = rakt. Långt ut = snett, och
##           längst ut tappar du greppet och det blir helikopter.
const METER_TIME := 1.45   # sekunder från tom till full kraft
const ACC_TIME := 1.0      # sekunder för markören att svepa över
const METER_ANGLE := 0.62  # kastvinkel i mätarläget (~35°)
const ACC_AIM_ERR := 0.17  # rad sidofel vid markören längst ut
const PERFECT := 0.18      # |markör| under detta = perfekt

var stand_x := 0.0
## kastlinjens z: 0 = baslinjen, negativt = framflyttad till en stående fältkubb
var throw_z := 0.0
var aim := 0.0             # positiv = höger
var theta := 0.0           # armvinkel, 0 = rakt ner, positiv = framåt
var holding := false
var baton                 # Baton, eller en Kubb som ska kastas över
var payload_kubb := false
var mouse_aim := true      # av i autotest/skärmdumpar
## siktmagnet: kubbar du får sikta på just nu (sätts av main varje bild)
var magnet_targets: Array[Vector3] = []
var locked_target := Vector3.INF
var _line_mat: Material
var _line_lock_mat: Material
var _lock_mark: Node3D
const MAGNET := 0.07       # rad: hur nära siktet måste vara för att dras in
var input_enabled := true
var meter := 0.0           # 0..1, för kraftmätaren
var meter_phase := 0       # 0 vila, 1 kraft, 2 precision
var meter_power := 0.0
var meter_cursor := -1.0   # -1..1 på precisionsmätaren
var _meter_t := 0.0

var _drag := Vector2.ZERO
var _frame_d := Vector2.ZERO
var _hist: Array[Vector3] = []  # (theta, vy px/s, vx px/s) per tick
var _press_mouse := Vector2.ZERO
var _arm: MeshInstance3D
var _pad_holding := false
var _pad_last_drag := 0.0
var _pad_last_x := 0.0
var _using_pad := false
var _hand: MeshInstance3D
var _aim_line: MeshInstance3D
var _land_mark: MeshInstance3D
var _mark_mats: Array[Material] = []
## var pinnen landar med kraften som visas just nu (m från kastlinjen), -1 = ingen
var land_dist := -1.0


func _ready() -> void:
	var skin := PS1.mat(null, Color(0.72, 0.66, 0.58))
	_arm = PS1.box(Vector3(0.075, ARM_LEN, 0.075), PS1.mat(PS1.cloth(), Color(5.5, 5.4, 5.0), Vector2(1, 3)))
	add_child(_arm)
	_hand = PS1.box(Vector3(0.08, 0.09, 0.06), skin)
	add_child(_hand)
	_line_mat = PS1.mat(null, Color(0.9, 0.85, 0.6), Vector2.ONE, 0.6)
	_line_lock_mat = PS1.mat(null, Color(0.4, 1.0, 0.45), Vector2.ONE, 1.0)
	_aim_line = PS1.box(Vector3(0.02, 0.005, 1.0), _line_mat)
	# ring runt kubben siktet har låst på
	_lock_mark = Node3D.new()
	_lock_mark.visible = false
	add_child(_lock_mark)
	for i in 8:
		var a := TAU * i / 8.0
		var b := PS1.box(Vector3(0.05, 0.006, 0.02), _line_lock_mat)
		b.position = Vector3(cos(a), 0, sin(a)) * 0.11
		b.rotation.y = -a + PI * 0.5
		_lock_mark.add_child(b)
	add_child(_aim_line)
	# landningskors: följer kraften live medan mätaren fylls
	_land_mark = MeshInstance3D.new()
	_land_mark.visible = false
	add_child(_land_mark)
	for c in [Color(0.3, 1.0, 0.35), Color(1.0, 0.85, 0.25), Color(1.0, 0.3, 0.2)]:
		_mark_mats.append(PS1.mat(null, c, Vector2.ONE, 1.0))
	for a in [0.785, -0.785]:
		var bar := PS1.box(Vector3(0.04, 0.006, 0.34), _mark_mats[0])
		bar.rotation.y = a
		_land_mark.add_child(bar)
	var dot := PS1.box(Vector3(0.36, 0.006, 0.03), _mark_mats[0])
	_land_mark.add_child(dot)


func give_baton(b) -> void:
	payload_kubb = b is Kubb
	baton = b
	b.hold()
	holding = false
	theta = 0.0
	meter_phase = 0
	meter = 0.0
	meter_cursor = -1.0
	_hist.clear()
	_update_pose()


func cancel_hold() -> void:
	meter_phase = 0
	if holding:
		holding = false
		_pad_holding = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_drag = Vector2.ZERO


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and e.screen_relative.length() > 2.0:
		_using_pad = false
	if baton == null or not input_enabled:
		return
	if Settings.throw_mode == "meter" or payload_kubb:
		var press: bool = (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
			or (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_SPACE) \
			or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A)
		if press:
			get_viewport().set_input_as_handled()
			_meter_press()
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and not holding:
			holding = true
			_drag = Vector2.ZERO
			_hist.clear()
			_press_mouse = get_viewport().get_mouse_position()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif not e.pressed and holding:
			_release()
	elif e is InputEventMouseMotion and holding:
		_drag += e.screen_relative
		_frame_d += e.screen_relative


func _physics_process(dt: float) -> void:
	if baton == null:
		theta = lerpf(theta, 0.0, 0.06)
		_update_pose()
		return
	var k := PX_TO_RAD * Settings.sensitivity
	if Settings.throw_mode == "meter" or payload_kubb:
		_meter_tick(dt)
	else:
		_poll_pad(dt, k)
	if meter_phase > 0:
		pass
	elif holding:
		_drag.y = clampf(_drag.y, -THETA_MAX / k, -THETA_MIN / k)
		theta = -_drag.y * k
	else:
		if input_enabled and Run.mod("no_move") == 0.0:
			var mv := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
			mv += float(Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT) or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER))
			mv -= float(Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER))
			stand_x = clampf(stand_x + mv * 1.6 * dt, -2.3, 2.3)
		if _using_pad and input_enabled:
			var ax := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
			if absf(ax) > 0.15:
				aim = clampf(aim + ax * 0.35 * dt, -MAX_AIM, MAX_AIM)
			elif absf(ax) <= 0.15:
				aim = lerpf(aim, _magnet(aim), clampf(dt * 6.0, 0.0, 1.0))
		elif mouse_aim and input_enabled:
			var vp := get_viewport()
			var mx := vp.get_mouse_position().x / maxf(vp.get_visible_rect().size.x, 1.0)
			var target := clampf((mx - 0.5) * 2.0, -1.0, 1.0) * MAX_AIM
			aim = lerpf(aim, _magnet(target), clampf(dt * 10.0, 0.0, 1.0))
		theta = lerpf(theta, 0.0, 0.15)
	# fart i px/s uppåt (positiv = svep upp) och i sidled
	_hist.push_back(Vector3(theta, -_frame_d.y / dt, _frame_d.x / dt))
	_frame_d = Vector2.ZERO
	while _hist.size() > WINDOW + SMOOTH:
		_hist.pop_front()
	if Settings.throw_mode != "meter" and not payload_kubb:
		meter = clampf(_speed_for(_smoothed(_hist.size() - 1).y) / MAX_SPEED, 0.0, 1.0) if holding else 0.0
	_update_pose()


## Gamepad: håll A eller höger avtryckare, dra höger spak ner för sats
## och knuffa upp för att kasta. Vänster spak siktar, LB/RB flyttar.
func _poll_pad(_dt: float, k: float) -> void:
	if Input.get_connected_joypads().is_empty() or baton == null or not input_enabled:
		return
	if absf(Input.get_joy_axis(0, JOY_AXIS_LEFT_X)) > 0.3 or absf(Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)) > 0.3:
		_using_pad = true
	var grab := Input.is_joy_button_pressed(0, JOY_BUTTON_A) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.5
	var sy := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	var sx := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if grab and not holding:
		holding = true
		_pad_holding = true
		_hist.clear()
		_pad_last_drag = 0.0
		_pad_last_x = sx
		_drag = Vector2.ZERO
	elif not grab and _pad_holding:
		_pad_holding = false
		_release()
		return
	if _pad_holding:
		var th := sy * THETA_MIN if sy > 0.0 else -sy * 1.6
		var d := -th / k
		_frame_d.y += (d - _pad_last_drag) * PAD_SCALE
		_frame_d.x += (sx - _pad_last_x) * 300.0
		_pad_last_drag = d
		_pad_last_x = sx
		_drag.y = d


func _meter_press() -> void:
	match meter_phase:
		0:
			meter_phase = 1
			_meter_t = 0.0
			holding = true
		1:
			meter_power = meter
			if payload_kubb:
				_toss_kubb()
				return
			meter_phase = 2
			_meter_t = 0.0
		2:
			_meter_launch()


func _meter_tick(dt: float) -> void:
	if meter_phase == 1:
		_meter_t += dt
		var x := _meter_t / (METER_TIME * Run.mod("meter_time_mult", 1.0))
		if x >= 2.0:
			# mätaren hann tömmas: du tappar pinnen
			meter_phase = 0
			holding = false
			meter = 0.0
			_drop()
			return
		meter = x if x <= 1.0 else 2.0 - x
		theta = -1.35 * meter
	elif meter_phase == 2:
		_meter_t += dt
		var x := _meter_t / (ACC_TIME * Run.mod("acc_time_mult", 1.0))
		meter_cursor = -1.0 + 2.0 * x
		theta = lerpf(-1.35 * meter_power, METER_ANGLE, clampf(x, 0.0, 1.0))
		if meter_cursor > 1.25:
			_meter_launch()  # för sent: kastet går iväg ändå, snett


## Resultatet av precisionen, för texten på skärmen.
func perfect() -> float:
	return minf(PERFECT * Run.mod("green_mult", 1.0), 0.7)


func power_factor() -> float:
	return Settings.power * Run.mod("power_mult", 1.0) * (Run.baton_stat("power") if Run.active else 1.0)


func grade_for(c: float) -> String:
	var a := absf(c)
	if a < perfect():
		return "perfect"
	if a < 0.4:
		return "good"
	if a < 0.85:
		return "off"
	return "fumble"


func _meter_launch() -> void:
	var c := meter_cursor
	meter_phase = 0
	holding = false
	meter = meter_power
	launch_meter(meter_power, c)


## Mätarkast: kraft 0..1, markörens läge -1..1. Används också av autotestet.
func launch_meter(power01: float, cursor: float) -> void:
	var speed := MAX_SPEED * clampf(power01, 0.0, 1.0) * power_factor()
	var grade := grade_for(cursor)
	# I det gröna går pinnen exakt dit siktlinjen pekar. Utanför växer felet
	# från noll vid kanten av det gröna.
	var p := perfect()
	var err := signf(cursor) * maxf(absf(cursor) - p, 0.0) / (1.0 - p)
	var th := METER_ANGLE + err * 0.08 + randfn(0.0, 0.01 + absf(err) * 0.03)
	var saved := aim
	# lite naturlig spridning även i det gröna, mer ju längre ut markören är
	aim += err * ACC_AIM_ERR + randfn(0.0, 0.006 + absf(err) * 0.03)
	theta = th
	_update_pose()
	var f := forward()
	var r := f.cross(Vector3.UP)
	var v := (f * cos(th) + Vector3.UP * sin(th)) * speed
	var w := r * speed * SPIN_FACTOR
	if grade == "fumble":
		w += Vector3.UP * signf(cursor) * 7.0  # greppet släpper: helikopter
	var b = baton
	baton = null
	aim = saved
	b.launch(v, w)
	_aim_line.visible = false
	thrown.emit(b, {"speed": v.length(), "angle": rad_to_deg(th), "lat": 0.0, "grade": grade})


## Kasta över en kubb: kraften styr längden, siktet riktningen.
func _toss_kubb() -> void:
	meter_phase = 0
	holding = false
	var th := 0.75
	var speed := 9.5 * clampf(meter_power, 0.0, 1.0)
	launch_kubb(th, speed)


func launch_kubb(th: float, speed: float) -> void:
	theta = th
	_update_pose()
	var f := forward()
	var r := f.cross(Vector3.UP)
	var k = baton
	baton = null
	payload_kubb = false
	k.launch((f * cos(th) + Vector3.UP * sin(th)) * speed, r * speed * 0.6)
	_aim_line.visible = false
	tossed.emit(k)


## Drar siktet mot närmaste giltiga kubb när du siktar nära den.
func _magnet(raw: float) -> float:
	locked_target = Vector3.INF
	if not Settings.aim_assist or payload_kubb or magnet_targets.is_empty():
		return raw
	var sx := stand_x + SHOULDER.x
	var best := INF
	var best_a := raw
	for t in magnet_targets:
		var a := atan2(t.x - sx, -(t.z - throw_z))
		var d := absf(a - raw)
		if d < best:
			best = d
			best_a = a
			if d < MAGNET:
				locked_target = t
	if best < MAGNET:
		return lerpf(raw, best_a, 0.45)
	return raw


func forward() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, -aim)


func shoulder() -> Vector3:
	return Vector3(stand_x, 0, throw_z) + SHOULDER


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
		var off: float = 0.06 if payload_kubb else (baton.length if baton is Baton else Baton.LENGTH) * 0.5 - 0.03
		baton.global_transform = Transform3D(b, hand + dir * off)
	_aim_line.visible = baton != null and Run.mod("no_aim_line") == 0.0
	var locked := locked_target != Vector3.INF and baton != null
	_aim_line.material_override = _line_lock_mat if locked else _line_mat
	_lock_mark.visible = locked and _aim_line.visible
	if _lock_mark.visible:
		_lock_mark.global_position = Vector3(locked_target.x, 0.015, locked_target.z)
		_lock_mark.rotation.y += 0.03
	var length := 8.6 if Settings.aim_assist else 3.0
	var start := Vector3(stand_x + SHOULDER.x, 0.012, throw_z)
	_aim_line.global_transform = Transform3D(Basis(Vector3.UP, -aim).scaled(Vector3(1, 1, length)), start + f * length * 0.5)
	# sikthjälp: var pinnen landar, live medan kraften fylls och låst efteråt
	_land_mark.visible = baton != null and Settings.aim_assist and meter_phase in [1, 2] \
		and Run.mod("no_aim_line") == 0.0
	land_dist = -1.0
	if _land_mark.visible:
		var p01 := meter if meter_phase == 1 else meter_power
		var d := predict_distance(p01)
		land_dist = d
		# grönt = landar vid hans baslinje, gult = kort, rött = långt
		var lo := World.FIELD_L + throw_z - 0.45
		var hi := World.FIELD_L + throw_z + 0.6
		if payload_kubb:  # en kubb ska landa i hans planhalva
			lo = World.FIELD_L * 0.5 + 0.3
			hi = World.FIELD_L - 0.3
		var m: Material = _mark_mats[0]
		if d < lo:
			m = _mark_mats[1]
		elif d > hi:
			m = _mark_mats[2]
		for c in _land_mark.get_children():
			c.material_override = m
		var pulse := 1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.012)
		_land_mark.global_transform = Transform3D(Basis(Vector3.UP, -aim).scaled(Vector3.ONE * pulse), start + f * d + Vector3(0, 0.004, 0))


## Hur långt (m) ett kast med kraft 0..1 går, för markeringen och mätaren.
func predict_distance(p01: float) -> float:
	var g: float = 9.81 * (baton.gravity_scale if baton is RigidBody3D else 1.0)
	var v: float
	var ang: float
	if payload_kubb:
		v = 9.5 * clampf(p01, 0.0, 1.0)
		ang = 0.75
	else:
		v = MAX_SPEED * clampf(p01, 0.0, 1.0) * power_factor()
		ang = METER_ANGLE
	var vy := v * sin(ang)
	var vx := v * cos(ang)
	var h := 0.75
	return maxf(vx * (vy + sqrt(vy * vy + 2.0 * g * h)) / g - 0.2, 0.0)


## Kraft 0..1 som landar på avståndet d (för gröna fältet på mätaren).
func power_for_distance(d: float) -> float:
	var lo := 0.0
	var hi := 1.0
	for i in 18:
		var mid := (lo + hi) * 0.5
		if predict_distance(mid) < d:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5


## Medelvärde av (theta, vy, vx) över SMOOTH tick som slutar vid i.
func _smoothed(i: int) -> Vector3:
	var a := maxi(0, i - SMOOTH + 1)
	var s := Vector3.ZERO
	for j in range(a, i + 1):
		s += _hist[j]
	s /= float(i - a + 1)
	s.x = _hist[i].x  # vinkeln tar vi exakt
	return s


func _speed_for(px_s: float) -> float:
	if px_s <= 0.0:
		return 0.0
	return MAX_SPEED * (1.0 - exp(-px_s * Settings.sensitivity / SPEED_K)) * power_factor()


func _release() -> void:
	holding = false
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().warp_mouse(_press_mouse)
	if _hist.size() < 2:
		_drop()
		return
	# hitta toppfarten i fönstret
	var best := Vector3.ZERO
	var best_i := -1
	for i in range(maxi(0, _hist.size() - WINDOW), _hist.size()):
		var s := _smoothed(i)
		if s.y > best.y:
			best = s
			best_i = i
	if best_i < 0 or best.y * Settings.sensitivity < MIN_PX_S or best.x < -0.1:
		_drop()
		return
	launch_with(clampf(best.x, 0.0, THETA_MAX), best.y, best.z)


func _drop() -> void:
	if payload_kubb:
		meter_phase = 0
		holding = false
		return  # en kubb tappar man inte, man får försöka igen
	var b = baton
	baton = null
	b.launch(Vector3(0, -0.2, -0.3), Vector3.ZERO)
	dropped.emit(b)


## Själva kastet: armvinkel, svepfart uppåt (px/s), svepfart i sidled (px/s).
## Används också av autotestet.
func launch_with(th: float, up_px_s: float, lat_px_s: float) -> void:
	theta = th
	_update_pose()
	var f := forward()
	var r := f.cross(Vector3.UP)
	var tangent := f * cos(th) + Vector3.UP * sin(th)
	var speed := _speed_for(up_px_s)
	var lat := signf(lat_px_s) * maxf(absf(lat_px_s) - LAT_DEAD, 0.0)
	var v := tangent * speed + r * lat * SIDE_K
	var w := r * speed * SPIN_FACTOR + Vector3.UP * lat * YAW_K
	var b = baton
	baton = null
	b.launch(v, w)
	_aim_line.visible = false
	thrown.emit(b, {"speed": v.length(), "angle": rad_to_deg(th), "lat": lat_px_s})
