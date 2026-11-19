## Spelets huvudnod: meny, runs med riktiga kubbmatcher och träning på Gösta.
##
## En match följer vanliga kubbregler:
##  1. Du kastar dina pinnar mot motståndarens planhalva.
##  2. Kubbar du fällde kastar motståndaren in på din planhalva (fältkubbar).
##  3. Motståndaren kastar sina pinnar mot din planhalva. Fältkubbar måste
##     fällas först, annars reses baslinjekubbarna igen.
##  4. Kubbar han fällde kastar du in på hans planhalva, och så vidare.
##  5. Är alla kubbar på en planhalva fällda får man kasta på kungen.
##     Rör man kungen för tidigt dör man (eller förlorar, om det är han).
##
## World = platsen, Opponent = motståndare, ThrowController = spelarens kast,
## Menu = menyer och butik, Hud = allt på skärmen, Run = runnens tillstånd.
extends Node3D

enum Mode { MENU, MATCH, TRAINING }
enum State { READY, FLYING, BUSY, OVER }
enum Phase { PLAYER, OPP_TOSS, OPP_THROW, PLAYER_TOSS }

const BASE_X := [-2.0, -1.0, 0.0, 1.0, 2.0]
const HALF_THEIRS := Rect2(-2.5, -8.0, 5.0, 4.0)  # x, z, bredd, djup
const HALF_MINE := Rect2(-2.5, -4.0, 5.0, 4.0)
const OPP_Z := -9.3

var mode := Mode.MENU
var state := State.READY
var phase := Phase.PLAYER
var batons_per_turn := 6
var batons_left := 6
var turn := 0
var world: World
var opponent: Opponent
var dog: Dog
var thrower: ThrowController
var camera: Camera3D
var menu: Menu
var hud: Hud
var kubbs: Array[Kubb] = []
var king: Kubb
var batons: Array[RigidBody3D] = []
var current: RigidBody3D       # pinnen eller kubben som är i luften
var current_by_opp := false
var stats := {"throws": 0, "hits": 0, "heli": 0, "longest": 0.0}

var _fly_time := 0.0
var _snapshot := {}
var _fallen_at_snapshot := {}
var _look := Vector3(0, 0.2, -8)
var _last_info := {}
var _last_dist := 0.0
var _hit_this_throw := false
var _pushed := {}
var _shake := 0.0
var _orbit := 0.0
var _idle := 0.0
var _trail_tick := 0
var _settled := false
var _shadow: MeshInstance3D
var _ghost: Node3D
var _trail_mat: Material
var _autotest := false
var _toss_tries := 0
var _match_over := false
var _opp_batons_next := 0
var _triggered := {}
var _baton_hit_done := false
var _pending_fx := 0
var _felled_valid: Array[Kubb] = []
var _line_mark: MeshInstance3D
var _double_next := false
var _streak := 0
var _opp_left := 0
var _opp_total := 0
var _match_teeth := 0
var _cam_z := 0.0


func _ready() -> void:
	randomize()
	_autotest = "--autotest" in OS.get_cmdline_user_args()
	world = World.new()
	add_child(world)
	_set_opponent("vedgubben")
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
	thrower.tossed.connect(_on_tossed)

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
	# kastlinjen när någon får kliva fram till en fältkubb
	_line_mark = PS1.box(Vector3(5.0, 0.006, 0.04), PS1.mat(null, Color(1.0, 0.3, 0.15), Vector2.ONE, 1.0))
	_line_mark.visible = false
	add_child(_line_mark)

	hud = Hud.new()
	add_child(hud)
	menu = Menu.new()
	add_child(menu)
	menu.run_start.connect(_start_run)
	menu.training_pressed.connect(func(): _start(Mode.TRAINING))
	menu.resume_pressed.connect(_resume)
	menu.restart_pressed.connect(func():
		_resume()
		if mode == Mode.MATCH:
			_begin_match()
		else:
			_new_training())
	menu.main_menu_pressed.connect(_to_menu)
	menu.shop_done.connect(_after_shop)
	Run.unlocked.connect(func(t: String): hud.toast(Lang.t("unlocked") + " " + t))
	Lang.changed.connect(_refresh_ui)
	Settings.changed.connect(_refresh_ui)
	Sfx.start_ambience()

	if _autotest:
		_run_autotest()
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_screenshots(a.substr(7))
			return
	_to_menu()


func _set_opponent(id: String) -> void:
	if opponent:
		opponent.queue_free()
	var path := "res://scripts/opponents/%s.gd" % id
	opponent = load(path).new()
	opponent.position = Vector3(0.0, 0, OPP_Z)
	add_child(opponent)
	opponent.spoke.connect(_on_spoke)


func _spawn_kubbs() -> void:
	for side in ["theirs", "mine"]:
		for i in 5:
			var k := Kubb.new()
			k.setup(false, (100 if side == "theirs" else 200) + i)
			add_child(k)
			var z := -World.FIELD_L if side == "theirs" else 0.0
			k.home = Transform3D(Basis(Vector3.UP, randf_range(-0.2, 0.2)), Vector3(BASE_X[i], Kubb.SIZE.y * 0.5, z))
			k.side = side
			kubbs.append(k)
	king = Kubb.new()
	king.setup(true, 77)
	add_child(king)
	king.home = Transform3D(Basis.IDENTITY, Vector3(0, Kubb.KING_SIZE.y * 0.5, -World.FIELD_L * 0.5))
	for k in kubbs + [king]:
		k.landed.connect(func(v: float):
			Sfx.play("clack2", linear_to_db(clampf(v * 0.4, 0.05, 1.0)) - 4.0, 0.8)
			if k.visible and v > 1.0:
				Fx.dust(self, Vector3(k.global_position.x, 0.0, k.global_position.z), clampf(v * 0.3, 0.3, 1.0)))


func _reset_kubbs() -> void:
	for k in kubbs:
		k.side = "theirs" if k.home.origin.z < -1.0 else "mine"
		k.field = false
		k.in_flight = false
		k.go_home()
	king.go_home()


func side_kubbs(side: String, standing_only := false) -> Array[Kubb]:
	var out: Array[Kubb] = []
	for k in kubbs:
		if k.side == side and (not standing_only or not k.is_fallen()):
			out.append(k)
	return out


func fallen_kubbs(side: String) -> Array[Kubb]:
	var out: Array[Kubb] = []
	for k in kubbs:
		if k.side == side and k.is_fallen():
			out.append(k)
	return out


# ---------------------------------------------------------------- lägen

func _to_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	mode = Mode.MENU
	state = State.OVER
	Run.stop()
	thrower.cancel_hold()
	thrower.input_enabled = false
	_clear_batons()
	_set_dog_active(false)
	_set_kubbs_active(true)
	_set_opponent("vedgubben")
	_reset_kubbs()
	for k in kubbs:
		k.set_kind("")
	thrower.throw_z = 0.0
	_line_mark.visible = false
	hud.clear_death()
	hud.center("")
	menu.paused_menu = false
	menu.open("title")
	hud.set_playing(false)
	hud.fade_in()


func _start_run(baton_id: String) -> void:
	Run.start(baton_id)
	_start(Mode.MATCH)


func _start(m: Mode, instant := false) -> void:
	if not instant:
		await hud.fade_out()
	mode = m
	menu.close()
	menu.paused_menu = false
	get_tree().paused = false
	_set_dog_active(m == Mode.TRAINING)
	_set_kubbs_active(m == Mode.MATCH)
	thrower.input_enabled = true
	hud.set_playing(true)
	if m == Mode.MATCH:
		_begin_match()
	else:
		_new_training()
	if not instant:
		hud.fade_in()


func _pause() -> void:
	if mode == Mode.MENU or get_tree().paused or menu.visible:
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


func _set_kubbs_active(on: bool) -> void:
	for k in kubbs + [king]:
		if k.home.origin.z < -1.0 or k == king:
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
	if thrower.baton is Baton:
		thrower.baton = null


# ---------------------------------------------------------------- match

func _begin_match() -> void:
	_clear_batons()
	_reset_kubbs()
	_set_opponent(Run.opponent_id() if Run.active else "vedgubben")
	opponent.setup_for_night(Run.night)
	Run.opp_mods = opponent.mods_for_night(Run.night)
	Run.clear_temp()
	_double_next = false
	_streak = 0
	_match_teeth = Run.teeth
	Run.king_shield_left = int(Run.mod("king_shield"))
	_place_deck()
	_opp_batons_next = 0
	_line_mark.visible = false
	turn = 0
	_match_over = false
	stats = {"throws": 0, "hits": 0, "heli": 0, "longest": 0.0}
	hud.clear_death()
	hud.center("")
	_ghost.visible = false
	var intro: String = Lang.t("night") % [Run.night, Run.NIGHTS] + "\n" + opponent.display_name[Lang.current]
	if opponent.rule_text[Lang.current] != "":
		intro += "\n" + opponent.rule_text[Lang.current]
	hud.banner(intro)
	opponent.say("start")
	_start_player_turn()


## Kubbleken ställs upp på hans baslinje (blandad), resten är vanliga.
func _place_deck() -> void:
	var deck: Array = Run.cards.duplicate() if Run.active else []
	deck.shuffle()
	var mm := Run.mod("theirs_mass_mult", 1.0)
	var i := 0
	for k in kubbs:
		if k.home.origin.z < -1.0:
			k.set_kind(deck[i] if i < deck.size() else "", mm)
			i += 1
		else:
			k.set_kind("")


func _start_player_turn() -> void:
	turn += 1
	phase = Phase.PLAYER
	thrower.stand_x = 0.0
	# vanlig kubbregel: står fältkubbar kvar på din planhalva efter hans tur
	# får du kliva fram till linjen genom den som står närmast mitten
	thrower.throw_z = _advance_line("mine")
	_line_mark.visible = thrower.throw_z < -0.05
	if _line_mark.visible:
		_line_mark.global_position = Vector3(0, 0.01, thrower.throw_z)
		hud.flash(Lang.t("advance"))
		Fx.ring(self, Vector3(0, 0, thrower.throw_z), Color(1.0, 0.35, 0.2), 1.5)
		Sfx.play("sparkle", -6.0, 0.8)
	var base := 8 if Settings.rules == "simple" else 6
	batons_per_turn = maxi(1, base + int(Run.mod("batons_add")) + opponent.player_batons_add)
	batons_left = batons_per_turn
	if opponent.player_batons_add < 0 and turn > 0:
		opponent.say("eat")
	# kyrkklockan: var tredje tur välter en slumpad motståndarkubb
	if Run.mod("bell") > 0.0 and turn % 3 == 0:
		var st := side_kubbs("theirs", true)
		if not st.is_empty():
			var k: Kubb = st[randi() % st.size()]
			k.sleeping = false
			k.apply_impulse(Vector3(0, 0, -0.3), Vector3(0, k.height() * 0.45, 0))
			hud.flash(Lang.t("bell"))
			Sfx.play("clack2", 0.0, 0.5)
	_next_baton()


func _next_baton() -> void:
	if mode == Mode.MATCH and batons_left <= 0:
		return
	var b := Baton.new()
	b.setup(Run.cur_baton() if Run.active else "vanlig")
	add_child(b)
	_trail_mat = PS1.mat(null, b.trail_color, Vector2.ONE, 1.0)
	b.body_entered.connect(_on_baton_hit.bind(b))
	batons.append(b)
	current = b
	current_by_opp = false
	thrower.give_baton(b)
	state = State.READY
	_idle = 0.0
	while mode == Mode.TRAINING and batons.size() > 7:
		batons.pop_front().queue_free()
	_refresh_ui()


func _on_thrown(b: RigidBody3D, info: Dictionary) -> void:
	_last_info = info
	if mode == Mode.MATCH:
		batons_left -= 1
		var cost := int(Run.baton_stat("tooth_cost")) if Run.active and Cards.BATONS[Run.cur_baton()].has("tooth_cost") else 0
		if cost > 0:
			Run.add_teeth(-cost)
	stats.throws += 1
	_begin_flight(b)
	Sfx.play("whoosh", -4.0, 0.8 + info.speed * 0.04)
	hud.show_throw(info.speed / ThrowController.MAX_SPEED)
	if info.has("grade"):
		hud.flash(Lang.t("grade_" + info.grade))
		if info.grade == "perfect":
			Sfx.play("click", -2.0, 1.6)
			Sfx.play("sparkle", -4.0)
			Fx.sparks(self, b.global_position, Color(1.0, 0.9, 0.4), 18)
			_streak += 1
			if _streak >= 2 and mode == Mode.MATCH and Run.active:
				# perfekt-svit: en extra tand per kast i rad
				Run.add_teeth(_streak - 1)
				hud.teeth_popup("+%d %s  %s" % [_streak - 1, Lang.t("teeth"), _tl("SVIT x%d", "STREAK x%d") % _streak])
		else:
			_streak = 0
	_refresh_ui()


func _begin_flight(b: RigidBody3D) -> void:
	current = b
	_take_snapshot()
	_fly_time = 0.0
	_hit_this_throw = false
	_pushed.clear()
	_settled = false
	_triggered.clear()
	_baton_hit_done = false
	state = State.FLYING


func _on_dropped(b: RigidBody3D) -> void:
	_say("drop")
	batons.erase(b)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(b.queue_free)
	_next_baton()


func _on_baton_hit(body: Node, b: Baton) -> void:
	if b != current or state != State.FLYING:
		return
	if body == king and mode == Mode.MATCH:
		var side := "mine" if current_by_opp else "theirs"
		if _standing_at_snapshot(side) > 0:
			if not current_by_opp and Run.king_shield_left > 0:
				Run.king_shield_left -= 1
				hud.flash(Lang.t("king_mercy"))
			else:
				_king_touched_early()
				return
	if body is Kubb:
		Sfx.play("clack", 0.0, 1.0 if not body.is_king else 0.7)
		# träff = omkull: en extra knuff högt upp i pinnens riktning
		if not body.is_king and not _pushed.has(body):
			_pushed[body] = true
			var dir := b.linear_velocity
			dir.y = 0.0
			if dir.length() < 0.5:
				dir = body.global_position - b.global_position
				dir.y = 0.0
			dir = dir.normalized()
			var push := 0.35
			if current_by_opp:
				push *= opponent.baton_push
			elif Run.active:
				push *= Run.mod("push_mult", 1.0) * Run.baton_stat("push")
			body.sleeping = false
			body.apply_impulse(dir * push, Vector3(0, body.height() * 0.45, 0))
			Fx.splinters(self, b.global_position, Cards.color(body.kind) * 0.7)
			if mode == Mode.MATCH and not current_by_opp:
				_trigger_hit(body, b)
		elif body.is_king:
			Fx.sparks(self, b.global_position, Color(1.0, 0.3, 0.2), 10)
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
		var sp := b.linear_velocity.length()
		if sp > 1.5:
			Fx.dust(self, Vector3(b.global_position.x, 0.0, b.global_position.z), clampf(sp / 6.0, 0.3, 1.2))


# ---------------------------------------------------------------- kubbleken

## Första träffen på en kubb under ett kast: kubbens egen träffeffekt och
## pinnens (en gång per kast).
func _trigger_hit(k: Kubb, b: Baton) -> void:
	if _triggered.has(k):
		return
	_triggered[k] = true
	var hd: Dictionary = Cards.DEFS.get(k.kind, {}).get("hit", {})
	if not hd.is_empty():
		_do_hit(k, b, hd, Cards.title(k.kind), Cards.color(k.kind))
	if not _baton_hit_done and Run.active:
		_baton_hit_done = true
		var bh: Dictionary = Cards.BATONS.get(Run.cur_baton(), {}).get("hit", {})
		if not bh.is_empty():
			_do_hit(k, b, bh, Cards.title(Run.cur_baton()), Cards.BATONS[Run.cur_baton()].get("trail", Color(1, 0.8, 0.5)))


func _do_hit(k: Kubb, b: Baton, h: Dictionary, label: String, col: Color) -> void:
	hud.popup(camera.unproject_position(k.global_position + Vector3(0, 0.35, 0)), label.to_upper() + "!")
	var side := k.side
	if h.has("boom"):
		var f: float = h.boom
		Fx.boom(self, k.global_position, f)
		_slowmo()
		if randf() < 0.7:
			opponent.say("effect")
		Sfx.play("boom", 0.0, 1.2 - f * 0.2)
		_shake = 0.6 + f * 0.3
		for o in kubbs:
			if o == k or not o.visible:
				continue
			var d := o.global_position - k.global_position
			d.y = 0.0
			var dist := d.length()
			var r := 1.5 * f
			if dist < r:
				o.sleeping = false
				var dir := d.normalized() if dist > 0.01 else Vector3.FORWARD
				o.apply_impulse((dir * 0.55 + Vector3.UP * 0.12) * (1.25 - dist / r), Vector3(0, o.height() * 0.45, 0))
		k.sleeping = false
		k.apply_impulse(Vector3.UP * 0.25 * f, Vector3(0, k.height() * 0.4, 0))
	if h.has("chain"):
		var cands: Array[Kubb] = []
		for o in side_kubbs(side, true):
			if o != k:
				cands.append(o)
		var c := k.global_position
		cands.sort_custom(func(x, y): return x.global_position.distance_to(c) < y.global_position.distance_to(c))
		for i in mini(int(h.chain), cands.size()):
			_topple_later(cands[i], c, 0.15 + 0.15 * i, col)
	if h.has("zap"):
		_zap_random(side, int(h.zap), k)
	if h.has("bounce"):
		call_deferred("_bounce", b)
		Fx.sparks(self, b.global_position, col, 12)
	if h.has("wind"):
		var dirz := -1.0 if side == "theirs" else 1.0
		Sfx.play("whoosh", 0.0, 0.5)
		for o in side_kubbs(side, true):
			if o == k:
				continue
			o.sleeping = false
			o.apply_impulse(Vector3(randf_range(-0.05, 0.05), 0, dirz * 0.3), Vector3(0, o.height() * 0.45, 0))
			Fx.dust(self, Vector3(o.global_position.x, 0.0, o.global_position.z), 0.8)
	if h.has("teleport"):
		call_deferred("_teleport_kubb", k, col)


func _topple_later(o: Kubb, from: Vector3, delay: float, col: Color) -> void:
	_pending_fx += 1
	await get_tree().create_timer(delay, false).timeout
	_pending_fx -= 1
	if not is_instance_valid(o) or mode != Mode.MATCH or o.is_fallen():
		return
	var dir := o.global_position - from
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	o.sleeping = false
	o.apply_impulse(dir * 0.45, Vector3(0, o.height() * 0.45, 0))
	Fx.sparks(self, o.global_position + Vector3(0, 0.12, 0), col, 10)
	Sfx.play("clack", -3.0, 1.3)


func _zap_random(side: String, n: int, except: Kubb = null) -> void:
	var pool: Array[Kubb] = []
	for o in side_kubbs(side, true):
		if o != except:
			pool.append(o)
	pool.shuffle()
	for i in mini(n, pool.size()):
		var o := pool[i]
		Fx.zap(self, o.global_position)
		if i == 0:
			_slowmo()
			if randf() < 0.5:
				opponent.say("effect")
		Sfx.play("zap", 0.0, randf_range(0.9, 1.1))
		_shake = 0.5
		o.sleeping = false
		o.apply_impulse(Vector3(randf_range(-0.4, 0.4), 0.1, randf_range(-0.4, 0.4)).normalized() * 0.45, Vector3(0, o.height() * 0.45, 0))


func _bounce(b: Baton) -> void:
	if not is_instance_valid(b):
		return
	var v := b.linear_velocity
	b.linear_velocity = Vector3(v.x * 0.5, 4.2, v.z * 0.5)
	Sfx.play("whoosh", -2.0, 1.6)


func _teleport_kubb(k: Kubb, col: Color) -> void:
	if not is_instance_valid(k):
		return
	var r := HALF_THEIRS if k.side == "theirs" else HALF_MINE
	var p := Vector3(randf_range(r.position.x + 0.3, r.end.x - 0.3), k.height() * 0.5, randf_range(r.position.y + 0.4, r.end.y - 0.4))
	Fx.sparks(self, k.global_position, col, 16)
	Fx.burst(self, k.global_position, Color(0.8, 0.9, 1.0), 10, 0.6, 1.0, 0.06, -0.5, 1.0, 0.8, 1.5)
	k.teleport(Transform3D(Basis(Vector3.UP, randf() * TAU), p))
	Fx.sparks(self, p, col, 16)
	Sfx.play("sparkle", -2.0, 0.6)


## Fällningseffekter för kubbarna som just fälldes giltigt.
## Returnerar [extra tänder, multiplikator].
func _fell_effects() -> Array:
	var bonus := 0
	var mult := 1.0
	for k in _felled_valid:
		if k.field:
			bonus += int(Run.mod("field_teeth"))
		var fd: Dictionary = Cards.DEFS.get(k.kind, {}).get("fell", {})
		if fd.is_empty():
			continue
		var col := Cards.color(k.kind)
		Fx.sparks(self, k.global_position + Vector3(0, 0.1, 0), col, 20)
		Fx.flash_light(self, k.global_position, col, 2.5, 3.0, 0.4)
		Sfx.play("sparkle", -3.0)
		var msg: Array[String] = []
		bonus += int(fd.get("teeth", 0))
		mult *= float(fd.get("mult", 1.0))
		if fd.has("perfect_mult") and _last_info.get("grade", "") == "perfect":
			mult *= float(fd.perfect_mult)
		if fd.has("baton"):
			batons_left += int(fd.baton)
			batons_per_turn += int(fd.baton)
			msg.append(_tl("+%d PINNE", "+%d BATON") % int(fd.baton))
		if fd.has("opp_skip"):
			_opp_batons_next -= int(fd.opp_skip)
			msg.append(_tl("HAN TAPPAR EN PINNE", "HE LOSES A BATON"))
		if fd.has("opp_plus"):
			_opp_batons_next += int(fd.opp_plus)
			msg.append(_tl("HAN FÅR EN PINNE TILL", "HE GETS AN EXTRA BATON"))
		if fd.has("shield"):
			Run.king_shield_left += int(fd.shield)
			msg.append(_tl("KUNGENS NÅD +1", "KING'S MERCY +1"))
		if fd.has("gamble"):
			var g := int(fd.gamble)
			if randf() < 0.5:
				bonus += g
				msg.append(_tl("JACKPOTT!", "JACKPOT!"))
			else:
				bonus -= g / 2
				msg.append(_tl("NITLOTT.", "NO LUCK."))
		if fd.has("steal"):
			bonus += Run.night * 3
			msg.append(_tl("GRAVRÅN!", "GRAVE ROBBED!"))
		if fd.has("zap"):
			_zap_random(k.side, int(fd.zap), k)
		if fd.has("reraise"):
			var fallen: Array[Kubb] = []
			for o in fallen_kubbs(k.side):
				if o != k and not o in _felled_valid:
					fallen.append(o)
			if fallen.is_empty():
				for o in fallen_kubbs(k.side):
					if o != k:
						fallen.append(o)
			for i in mini(int(fd.reraise), fallen.size()):
				var o: Kubb = fallen[randi() % fallen.size()]
				if o.field:
					o.raise_at(o.global_position)
				else:
					o.go_home()
				Fx.sparks(self, o.global_position, Color(1, 0.3, 0.3), 14)
				msg.append(_tl("EN KUBB RESER SIG!", "A KUBB RISES!"))
		hud.popup(camera.unproject_position(k.global_position + Vector3(0, 0.3, 0)), Cards.title(k.kind) + "!")
		if not msg.is_empty():
			hud.flash(" ".join(msg))
	return [bonus, mult]


func _run_summary() -> String:
	if not Run.active and Run.stats.kubbs == 0:
		return ""
	return _tl("Natt %d. %d kubbar fällda, %d tänder, %d ödeskort.", "Night %d. %d kubbs felled, %d teeth, %d fate cards.") % [
		Run.night, Run.stats.kubbs, Run.stats.teeth_total, Run.cards_drawn]


## Ödespoäng: var tredje fälld kubb drar du två ödeskort och väljer ett.
func _fate_after_throw(newly: int) -> void:
	if not Run.active or _match_over or newly <= 0:
		return
	Run.fate_points += newly
	while Run.fate_points >= Run.FATE_COST and not _match_over:
		Run.fate_points -= Run.FATE_COST
		var two := Run.draw_fate_two()
		if two.is_empty():
			return
		var pick := 0
		if two.size() > 1:
			thrower.input_enabled = false
			Sfx.play("sparkle", -4.0, 0.9)
			if _autotest:
				pick = 0
			else:
				pick = await hud.choose_fate(_fate_view(two[0]), _fate_view(two[1]))
			thrower.input_enabled = true
		_apply_fate(two[pick])


func _fate_view(id: String) -> Array:
	var cursed: bool = Cards.FATE[id].get("cursed", false)
	return [Cards.fate_title(id), Cards.fate_desc(id), Color(0.85, 0.25, 0.9) if cursed else Color(0.5, 0.9, 0.5)]


func _apply_fate(id: String) -> void:
	Run.cards_drawn += 1
	var title := Cards.fate_title(id)
	var desc := Cards.fate_desc(id)
	var col := Color(0.4, 0.9, 0.4)
	var bad: bool = Cards.FATE[id].get("cursed", false)
	match id:
		"kubb":
			var pool := Run.shop_pool()
			if not pool.is_empty() and Run.cards.size() < Run.MAX_CARDS:
				var kid: String = pool[randi() % pool.size()]
				Run.cards.append(kid)
				desc = Cards.title(kid) + ": " + Cards.desc(kid) + _tl(" (står upp nästa match)", " (stands up next match)")
				col = Cards.color(kid) * 0.8
			else:
				Run.add_teeth(3)
				desc = _tl("Leken är full. Du får 3 tänder istället.", "Your deck is full. 3 teeth instead.")
		"pinne":
			var ids: Array = Cards.BATONS.keys()
			ids.erase(Run.cur_baton())
			var bid: String = ids[randi() % ids.size()]
			Run.borrowed = bid
			desc = Cards.title(bid) + ": " + Cards.desc(bid)
			col = Cards.BATONS[bid].get("trail", Color(1, 0.8, 0.5))
		"extra":
			batons_left += 1
			batons_per_turn += 1
		"tander":
			Run.add_teeth(3)
			col = Color(1, 0.9, 0.4)
		"tander_stor":
			Run.add_teeth(7)
			col = Color(1, 0.9, 0.4)
		"ranta":
			var n := mini(6, int(Run.teeth / 4))
			Run.add_teeth(n)
			desc = _tl("+%d tänder.", "+%d teeth.") % n
			col = Color(1, 0.9, 0.4)
		"gront":
			Run.add_temp("green_mult", 1.4, title)
		"lugn":
			Run.add_temp("meter_time_mult", 1.25, title)
			Run.add_temp("acc_time_mult", 1.25, "")
			Run.temp_names.pop_back()
		"dubbel":
			_double_next = true
			col = Color(1, 0.9, 0.4)
		"blixt":
			_zap_random("theirs", 1)
			col = Color(0.7, 0.8, 1.0)
		"skakig":
			Run.add_temp("opp_error_mult", 1.3, title)
		"nad":
			Run.king_shield_left += 1
		"sovpiller":
			_opp_batons_next -= 1
		"forbannad_kubb":
			var cp := Run.cursed_pool()
			if not cp.is_empty() and Run.cards.size() < Run.MAX_CARDS:
				var kid: String = cp[randi() % cp.size()]
				Run.cards.append(kid)
				desc = Cards.title(kid) + ": " + Cards.desc(kid)
			else:
				desc = _tl("Leken är full. Den kryper iväg igen. Puh.", "Your deck is full. It crawls away. Phew.")
		"darr":
			Run.add_temp("acc_time_mult", 0.8, title)
		"hans_pinne":
			_opp_batons_next += 1
	if bad:
		col = Color(0.85, 0.25, 0.9)
		Sfx.play("bad", -8.0, 1.3)
	else:
		Sfx.play("sparkle", -6.0, 1.2)
	hud.fate_card(title, desc, col)
	_refresh_ui()


func _tl(sv: String, en: String) -> String:
	return sv if Lang.current == "sv" else en


func _king_touched_early() -> void:
	state = State.OVER
	current = null
	opponent.flinch()
	_shake = 1.0
	_slowmo()
	Sfx.play("clack", 0.0, 0.5)
	Fx.burst(self, king.global_position + Vector3(0, 0.2, 0), Color(0.9, 0.05, 0.05), 40, 3.5, 1.4, 0.035, 4.0, 1.5, 1.0)
	Fx.flash_light(self, king.global_position, Color(1, 0.1, 0.05), 8.0, 10.0, 1.2)
	if current_by_opp:
		# motståndaren rörde kungen: du vinner
		opponent.say("opp_king_death")
		_win_match()
	else:
		opponent.say("king_death")
		Sfx.play("bad", 0.0, 0.5)
		hud.death(Lang.t("death_title"), Lang.pick("death_sub") + "\n" + _run_summary() + "\n\n" + Lang.t("death_restart"))
		_lose_run()


func _slowmo() -> void:
	if _autotest:
		return
	Engine.time_scale = 0.3
	await get_tree().create_timer(0.35, true, false, true).timeout
	var tw := create_tween()
	tw.tween_property(Engine, "time_scale", 1.0, 0.08)


func _take_snapshot() -> void:
	_snapshot.clear()
	_fallen_at_snapshot.clear()
	for k in kubbs + [king]:
		_snapshot[k] = k.global_transform
		_fallen_at_snapshot[k] = k.is_fallen()


func _standing_at_snapshot(side: String, field_only := false) -> int:
	var n := 0
	for k in kubbs:
		if k.side == side and not _fallen_at_snapshot.get(k, false) and (not field_only or k.field):
			n += 1
	return n


func _physics_process(dt: float) -> void:
	if state == State.READY and mode == Mode.MATCH and not thrower.holding:
		_idle += dt
		if _idle > 14.0:
			_idle = 0.0
			opponent.say("idle")
	if state != State.FLYING or current == null or not is_instance_valid(current):
		_shadow.visible = false
		return
	_fly_time += dt
	var p := current.global_position
	_shadow.visible = not current.touched and current is Baton
	_shadow.global_transform = Transform3D(Basis(Vector3.UP, current.global_rotation.y), Vector3(p.x, 0.014, p.z))
	_trail_tick += 1
	if not current.touched and _trail_tick % 3 == 0:
		_spawn_trail(p)
	var moving := false
	for k in kubbs + [king]:
		if k.visible and not k.sleeping and k.linear_velocity.length() > 0.08 and k != current:
			moving = true
	var gone := p.y < -2.0 or p.length() > 40.0
	if (_fly_time > 0.8 and current.is_settled() and not moving and _pending_fx <= 0) or _fly_time > 7.0 or gone:
		state = State.BUSY
		_settled = true
		if current is Kubb:
			return  # kubbkast hanteras av den som väntar på dem
		if current_by_opp:
			_evaluate_opp()
		else:
			_evaluate()


func _spawn_trail(p: Vector3) -> void:
	var t := PS1.box(Vector3(0.025, 0.025, 0.025), _trail_mat)
	add_child(t)
	t.global_position = p
	var tw := create_tween()
	tw.tween_property(t, "scale", Vector3.ONE * 0.01, 0.45)
	tw.tween_callback(t.queue_free)


func _wait_settled() -> void:
	while not _settled:
		await get_tree().physics_frame


## Fallna kubbar på en planhalva sedan snapshot, med regeln att
## fältkubbar måste fällas först. Kubbar på egen planhalva reses.
func _apply_hits(target: String) -> int:
	var had_field := _standing_at_snapshot(target, true) > 0
	var valid := 0
	_felled_valid.clear()
	var reraised := false
	for k in kubbs:
		var was: bool = _fallen_at_snapshot.get(k, false)
		if was or not k.is_fallen():
			continue
		if k.side != target:
			k.teleport(_snapshot[k])  # egen kubb: reses
		elif had_field and not k.field:
			k.teleport(_snapshot[k])  # baslinjekubb före fältkubbar: reses
			reraised = true
		else:
			valid += 1
			_felled_valid.append(k)
	if reraised:
		hud.flash(Lang.t("field_first"))
	return valid


func _evaluate() -> void:
	var b: Baton = current
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
		_next_baton()
		return

	if b.helicopter:
		for k in _snapshot:
			k.teleport(_snapshot[k])
		stats.heli += 1
		_say("helicopter")
		Sfx.play("bad", -4.0)
		hud.flash(Lang.t("heli"))
		_after_throw()
		return

	var all_down_before := _standing_at_snapshot("theirs") == 0
	var newly := _apply_hits("theirs")
	stats.hits += newly
	_log("kast: fart %.2f vinkel %d -> landade %.2f m, nya fällda %d, kung %s" % [
		_last_info.get("speed", 0.0), int(_last_info.get("angle", 0.0)), _last_dist, newly, str(king.is_fallen())])

	if king.is_fallen():
		if all_down_before:
			opponent.flinch()
			opponent.say("king_win")
			_award(0, true)
			_win_match()
			return
		king.teleport(_snapshot[king])  # (kungens nåd släppte igenom)

	if newly > 0:
		var fe := _fell_effects()
		var dm := 2.0 if _double_next else 1.0
		_double_next = false
		_award(newly, false, fe[0], fe[1] * dm)
	if newly >= 2:
		opponent.say("double")
		opponent.flinch()
	elif newly == 1:
		opponent.say("hit")
		opponent.flinch()
	elif _last_info.get("angle", 0.0) > 95.0:
		opponent.say("sky")
	elif land.z > -6.3 and side_kubbs("theirs", true).all(func(k): return not k.field):
		opponent.say("short")
	elif land.z < -9.5 or absf(land.x) > 3.5:
		opponent.say("long")
	elif _near_miss(b):
		opponent.say("close")
	else:
		opponent.say("miss")
	if newly > 0 and side_kubbs("theirs", true).is_empty():
		opponent.say("all_down")
	if newly > 0 and Run.active:
		await _fate_after_throw(newly)
	_after_throw()


## Tänder och kombos för ett kast.
func _award(n: int, king_win: bool, bonus := 0, xmult := 1.0) -> void:
	if not Run.active:
		return
	var per := 1 + int(Run.mod("teeth_kubb_add"))
	var t := n * per + bonus
	var parts: Array[String] = []
	if n >= 2:
		var combo := int(3 * (n - 1) * Run.mod("combo_mult", 1.0))
		t += combo
		Run.note_combo()
		parts.append(Lang.t("combo") % n)
		var names := ["", "", _tl("DUBBELKLONK!", "DOUBLE CLONK!"), _tl("TRIPPELKLONK!", "TRIPLE CLONK!"), _tl("KVADRUPELKLONK!", "QUADRUPLE CLONK!")]
		hud.flash(names[n] if n < names.size() else _tl("MASSAKER PÅ ÄNGEN!", "MEADOW MASSACRE!"))
	if _last_info.get("grade", "") == "perfect":
		t += 1 + int(Run.mod("perfect_teeth"))
		Run.note_perfect()
	if king_win:
		t += 5
		parts.append(Lang.t("king_bonus"))
	var mult := Run.mod("last_baton_mult", 1.0) if batons_left == 0 else Run.mod("other_baton_mult", 1.0)
	t = int(t * mult * xmult)
	if xmult > 1.0:
		parts.append("x%s" % str(snappedf(xmult, 0.1)))
	Run.on_kubbs(n)
	if t > 0:
		Run.add_teeth(t)
		hud.teeth_popup("+%d %s %s" % [t, Lang.t("teeth"), " ".join(parts)])
		Sfx.play("coin", -6.0)
	elif t < 0:
		Run.add_teeth(t)
		hud.teeth_popup("%d %s" % [t, Lang.t("teeth")])
		Sfx.play("bad", -6.0, 1.4)
	_refresh_ui()


func _near_miss(b: Baton) -> bool:
	for k in side_kubbs("theirs", true):
		if k.global_position.distance_to(b.global_position) < 0.45:
			return true
	return false


func _say(event: String) -> void:
	if mode == Mode.TRAINING:
		dog.say("miss")
	else:
		opponent.say(event)


func _after_throw() -> void:
	if _match_over:
		return
	if mode == Mode.TRAINING or batons_left > 0:
		_next_baton()
	else:
		_end_player_turn()
	_refresh_ui()


# ---------------------------------------------------------------- turer

func _end_player_turn() -> void:
	state = State.BUSY
	thrower.input_enabled = false
	await get_tree().create_timer(0.8).timeout
	_ghost.visible = false
	_line_mark.visible = false
	# 2. motståndaren kastar in kubbarna du fällde på din planhalva
	phase = Phase.OPP_TOSS
	_refresh_ui()
	var fallen := fallen_kubbs("theirs")
	if not fallen.is_empty():
		opponent.say("toss")
		for k in fallen:
			await _opp_toss(k)
			if _match_over:
				return
	_clear_batons()
	# 3. motståndarens pinnar (han kliver fram om dina fältkubbar står kvar)
	phase = Phase.OPP_THROW
	_refresh_ui()
	opponent.say("my_turn")
	var adv := _advance_line("theirs")
	if adv > -World.FIELD_L + 0.05:
		hud.flash(Lang.t("opp_advance"))
		opponent.say("advance")
		_line_mark.visible = true
		_line_mark.global_position = Vector3(0, 0.01, adv)
		Fx.ring(self, Vector3(0, 0, adv), Color(1.0, 0.35, 0.2), 1.5)
		await opponent.walk_to_z(clampf(adv - 1.0, OPP_Z, -5.0), 0.9)
	await get_tree().create_timer(1.0).timeout
	var opp_n := maxi(1, 6 + int(Run.mod("opp_batons_add")) + _opp_batons_next)
	_opp_batons_next = 0
	_opp_total = opp_n
	_opp_left = opp_n
	for i in opp_n:
		if _match_over:
			return
		_opp_left = opp_n - i
		_refresh_ui()
		await _opp_throw()
		if _match_over:
			return
	await get_tree().create_timer(0.6).timeout
	opponent.walk_to_x(0.0)
	opponent.walk_to_z(OPP_Z, 0.9)
	_line_mark.visible = false
	# 4. du kastar in kubbarna han fällde på hans planhalva (från baslinjen)
	phase = Phase.PLAYER_TOSS
	thrower.throw_z = 0.0
	var mine_fallen := fallen_kubbs("mine")
	_clear_batons()
	thrower.input_enabled = true
	for k in mine_fallen:
		if _match_over:
			return
		await _player_toss(k)
	thrower.input_enabled = true
	_start_player_turn()


## Kastlinjen för den som kastar MOT andra sidan: står fältkubbar kvar på
## planhalvan `side` (kastarens egen) flyttas linjen fram till den fältkubb
## som står närmast mittlinjen. Annars baslinjen. Returnerar z.
func _advance_line(side: String) -> float:
	var base := 0.0 if side == "mine" else -World.FIELD_L
	var best := base
	for k in side_kubbs(side, true):
		if not k.field:
			continue
		var z := k.global_position.z
		if side == "mine":
			best = minf(best, z)
		else:
			best = maxf(best, z)
	if side == "mine":
		return clampf(best, -World.FIELD_L * 0.5 + 0.3, 0.0)
	return clampf(best, -World.FIELD_L, -World.FIELD_L * 0.5 - 0.3)


func _opp_target() -> Kubb:
	var field: Array[Kubb] = []
	var base: Array[Kubb] = []
	for k in side_kubbs("mine", true):
		(field if k.field else base).append(k)
	var pool := field if not field.is_empty() else base
	if pool.is_empty():
		return king
	# närmast honom först
	pool.sort_custom(func(a, b): return a.global_position.z < b.global_position.z)
	return pool[0] if randf() < 0.7 else pool[randi() % pool.size()]


func _opp_throw() -> void:
	var target := _opp_target()
	var tp := target.global_position
	await opponent.walk_to_x(clampf(tp.x * 0.7, -2.2, 2.2), 0.5)
	await opponent.swing_back_and_forth()
	var b := Baton.new()
	b.setup()
	add_child(b)
	_trail_mat = PS1.mat(null, Color(0.95, 0.8, 0.6), Vector2.ONE, 1.0)
	b.body_entered.connect(_on_baton_hit.bind(b))
	batons.append(b)
	var from := opponent.hand_pos()
	var aim_pt := tp + (Vector3(from.x, 0, from.z) - Vector3(tp.x, 0, tp.z)).normalized() * 0.12
	var v := _ballistic(from, aim_pt, 0.62)
	var err := opponent.error_yaw * Run.mod("opp_error_mult", 1.0)
	v = v.rotated(Vector3.UP, randfn(0.0, err)) * (1.0 + randfn(0.0, opponent.error_speed * Run.mod("opp_error_mult", 1.0)))
	var f := Vector3(v.x, 0, v.z).normalized()
	var r := f.cross(Vector3.UP)
	b.global_transform = Transform3D(Basis(r, Vector3.UP, r.cross(Vector3.UP)), from)
	b.launch(v, r * v.length() * 0.75)
	current_by_opp = true
	_last_info = {"speed": v.length(), "angle": 35.0}
	Sfx.play("whoosh", -6.0, 0.9)
	_begin_flight(b)
	await _wait_settled()
	_log("   motst. kast mot %s från %s fart %.1f -> första träff %s, slut %s" % [str(tp.snapped(Vector3.ONE * 0.01)), str(from.snapped(Vector3.ONE * 0.01)), v.length(), str(b.first_contact.snapped(Vector3.ONE * 0.01)), str(b.global_position.snapped(Vector3.ONE * 0.01))])


func _evaluate_opp() -> void:
	current = null
	if _match_over:
		return
	var all_down_before := _standing_at_snapshot("mine") == 0
	var newly := _apply_hits("mine")
	if king.is_fallen():
		if all_down_before:
			opponent.say("lose")
			hud.death(Lang.t("lost_title"), Lang.t("lost_sub") + "\n" + _run_summary() + "\n\n" + Lang.t("death_restart"))
			_lose_run()
			return
		king.teleport(_snapshot[king])
	opponent.say("opp_hit" if newly > 0 else "opp_miss")
	if newly > 0:
		hud.popup(camera.unproject_position(Vector3(0, 0.2, -1.5)), "AJ!")
	_refresh_ui()


## Ballistisk startfart från a till b med given vinkel.
func _ballistic(a: Vector3, b: Vector3, angle: float) -> Vector3:
	var flat := Vector3(b.x - a.x, 0, b.z - a.z)
	var d := flat.length()
	var h := a.y - b.y
	var c := cos(angle)
	var denom := 2.0 * c * c * (d * tan(angle) + h)
	var v := sqrt(9.81 * d * d / maxf(denom, 0.01))
	return flat.normalized() * v * c + Vector3.UP * v * sin(angle)


func _in_half(p: Vector3, side: String) -> bool:
	var r := HALF_THEIRS if side == "theirs" else HALF_MINE
	return p.x > r.position.x and p.x < r.end.x and p.z > r.position.y and p.z < r.end.y


func _opp_toss(k: Kubb) -> void:
	for attempt in 2:
		var tp := Vector3(randf_range(-2.0, 2.0), 0, randf_range(-3.5, -0.8))
		await opponent.walk_to_x(clampf(tp.x * 0.5, -2.0, 2.0), 0.35)
		await opponent.swing_back_and_forth()
		var from := opponent.hand_pos()
		k.hold()
		k.global_position = from
		var v := _ballistic(from, tp, 0.8)
		v = v.rotated(Vector3.UP, randfn(0.0, 0.05)) * (1.0 + randfn(0.0, 0.07))
		k.launch(v, Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
		current_by_opp = true
		_begin_flight(k)
		await _wait_settled()
		var p := k.global_position
		if _in_half(p, "mine"):
			k.side = "mine"
			k.raise_at(p)
			return
		hud.flash(Lang.t("toss_out"))
	# två miss: du placerar den (långt från honom)
	k.side = "mine"
	k.raise_at(Vector3(randf_range(-2.0, 2.0), 0, -0.7))


func _player_toss(k: Kubb) -> void:
	for attempt in 2:
		state = State.READY
		thrower.give_baton(k)
		hud.flash(Lang.t("toss_now"))
		_refresh_ui()
		if _autotest:
			await get_tree().physics_frame
			thrower.aim = randf_range(-0.1, 0.1)
			thrower.meter_power = 0.68
			thrower.call_deferred("launch_kubb", 0.75, 9.5 * 0.68)
		var got = await thrower.tossed
		current_by_opp = false
		_begin_flight(got)
		Sfx.play("whoosh", -6.0, 0.7)
		await _wait_settled()
		var p := k.global_position
		if _in_half(p, "theirs"):
			k.side = "theirs"
			k.raise_at(p)
			return
		if Run.mod("toss_forgive") > 0.0:
			k.side = "theirs"
			k.raise_at(Vector3(clampf(p.x, -2.2, 2.2), 0, clampf(p.z, -7.7, -4.3)))
			return
		hud.flash(Lang.t("toss_out"))
	# två miss: motståndaren placerar den där den är svårast att träffa
	k.side = "theirs"
	k.raise_at(Vector3(randf_range(-2.2, 2.2), 0, -7.6))


func _on_tossed(_k: RigidBody3D) -> void:
	pass


# ---------------------------------------------------------------- vinst/förlust

func _win_match() -> void:
	if _match_over:
		return
	_match_over = true
	state = State.OVER
	thrower.cancel_hold()
	var reward := 8 + Run.night * 2 + int(Run.mod("win_teeth_add")) + maxi(batons_left, 0)
	reward += mini(5, int(Run.teeth / 5)) * int(Run.mod("interest"))
	Fx.confetti(self, king.global_position + Vector3(0, 0.3, 0))
	Sfx.play("sparkle", 0.0, 1.0)
	Run.add_teeth(reward)
	var won_all := Run.advance()
	hud.center(Lang.t("win_title") % reward + "\n" + _summary() + "\n" + _tl("Tänder den här matchen: %d", "Teeth this match: %d") % maxi(Run.teeth - _match_teeth, 0))
	await get_tree().create_timer(3.0).timeout
	if mode != Mode.MATCH:
		return
	if won_all:
		menu.open("victory")
	else:
		menu.open("shop")


func _after_shop() -> void:
	menu.close()
	await hud.fade_out()
	_begin_match()
	thrower.input_enabled = true
	hud.fade_in()


func _lose_run() -> void:
	if _match_over:
		return
	_match_over = true
	state = State.OVER
	thrower.cancel_hold()
	Run.end_run()


func _summary() -> String:
	return Lang.t("summary") % [stats.hits, stats.throws, stats.longest, stats.heli]


func _new_training() -> void:
	_clear_batons()
	_reset_kubbs()
	stats = {"throws": 0, "hits": 0, "heli": 0, "longest": 0.0}
	dog.hits = 0
	hud.center("")
	hud.clear_death()
	_ghost.visible = false
	phase = Phase.PLAYER
	_match_over = false
	thrower.throw_z = 0.0
	_line_mark.visible = false
	for k in kubbs:
		k.set_kind("")
	_next_baton()
	dog.say("start")


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
		_cam_z = lerpf(_cam_z, thrower.throw_z, clampf(dt * 2.5, 0.0, 1.0))
		cam_pos = Vector3(sx - 0.25, 1.75, 2.1 + _cam_z)
		want = Vector3(sx * 0.4 + thrower.aim * 6.0, 0.15, -8.0)
		if phase == Phase.OPP_THROW or phase == Phase.OPP_TOSS:
			want = Vector3(opponent.position.x * 0.6, 0.9, -7.5)
		if state == State.FLYING and current and is_instance_valid(current):
			var p := current.global_position
			want = Vector3(p.x, minf(p.y, 3.0) * 0.6, minf(p.z, -2.0))
		_look = _look.lerp(want, clampf(dt * 3.0, 0.0, 1.0))
	_shake = move_toward(_shake, 0.0, dt)
	var jitter := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.06
	camera.look_at_from_position(cam_pos + jitter, _look)
	hud.show_deck(mode == Mode.MATCH and Run.active and not menu.visible and (Input.is_key_pressed(KEY_TAB) or Input.is_joy_button_pressed(0, JOY_BUTTON_BACK)))
	var zoom := mode != Mode.MENU and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	camera.fov = lerpf(camera.fov, 20.0 if zoom else 40.0, clampf(dt * 8.0, 0.0, 1.0))
	world.follow_camera(cam_pos)
	if mode == Mode.MENU:
		opponent.look_at_x(cam_pos.x)
	else:
		opponent.look_at_x(current.global_position.x if current and is_instance_valid(current) else sx)
	if mode != Mode.MENU:
		if Settings.throw_mode == "meter" or thrower.payload_kubb:
			var tgt := World.FIELD_L * 0.75 if thrower.payload_kubb else World.FIELD_L + thrower.throw_z
			hud.update_timing(thrower.meter_phase, thrower.meter, thrower.meter_power, thrower.meter_cursor, thrower.perfect(),
				thrower.power_for_distance(tgt) if thrower.baton else -1.0, thrower.land_dist)
		else:
			hud.update_meter(thrower.meter, thrower.holding, rad_to_deg(thrower.theta))


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_START):
		if mode == Mode.MENU:
			menu.back()
		elif _match_over and mode == Mode.MATCH and not menu.visible:
			_to_menu()
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
				if mode == Mode.TRAINING and not thrower.holding:
					_new_training()
				elif mode == Mode.MATCH and _match_over and not menu.visible and not Run.active:
					_start_run(Run.baton)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and thrower and thrower.holding:
		thrower.cancel_hold()


# ---------------------------------------------------------------- UI

func _refresh_ui() -> void:
	if hud == null:
		return
	var info := {
		"training": mode == Mode.TRAINING,
		"left": batons_left, "total": batons_per_turn,
		"theirs": side_kubbs("theirs", true).size(), "theirs_field": _count_field("theirs"),
		"mine": side_kubbs("mine", true).size(), "mine_field": _count_field("mine"),
		"dog_hits": dog.hits, "last": _last_info, "last_dist": _last_dist,
		"phase": phase, "opp": opponent.display_name[Lang.current],
		"toss": thrower.payload_kubb,
		"opp_left": _opp_left, "opp_total": _opp_total,
	}
	hud.refresh(info)


func _count_field(side: String) -> int:
	var n := 0
	for k in side_kubbs(side, true):
		if k.field:
			n += 1
	return n


func _on_spoke(who: String, text: String) -> void:
	hud.speech(who, text)
	_log("[%s] %s" % [who, text])


func _log(s: String) -> void:
	if _autotest or OS.is_debug_build():
		print(s)


# ---------------------------------------------------------------- autotest
# Kör: godot --headless --fixed-fps 120 -- --autotest

func _wait_ready() -> void:
	while state != State.READY or thrower.baton == null or not thrower.baton is Baton:
		await get_tree().physics_frame


func _run_autotest() -> void:
	thrower.mouse_aim = false
	Settings.throw_mode = "drag"
	Run.start("vanlig")
	_start(Mode.MATCH, true)
	for i in 240:
		await get_tree().physics_frame
	var standing := 0
	for k in kubbs + [king]:
		if not k.is_fallen():
			standing += 1
	print("TEST stående efter 2 s: %d/11" % standing)
	var cases := [
		# [vinkel, svep upp px/s, sidled px/s, sikte, plats, namn]
		[0.6, 2900.0, 0.0, 0.0, -0.18, "rakt på mittkubben"],
		[0.5, 3100.0, 0.0, 0.0, -2.18, "vänster kubb"],
		[0.6, 2900.0, 2200.0, 0.0, 1.0, "väldigt snett (helikopter)"],
		[0.55, 3000.0, 0.0, 0.0, 1.82, "höger kubb"],
	]
	for c in cases:
		await _wait_ready()
		batons_left = 99
		thrower.stand_x = c[4]
		thrower.aim = c[3]
		await get_tree().physics_frame
		print("TEST %s" % c[5])
		thrower.launch_with(c[0], c[1], c[2])
		var b: Baton = batons[-1]
		await get_tree().physics_frame
		while state == State.FLYING or state == State.BUSY:
			await get_tree().physics_frame
		print("   slut %s heli=%s  tänder %d" % [str(b.global_position.snapped(Vector3.ONE * 0.01)), b.helicopter, Run.teeth])
	# en hel tur: sista pinnen, motståndaren kastar in, kastar, du kastar in
	await _wait_ready()
	batons_left = 1
	print("TEST hel tur. Deras stående %d, fallna %d" % [side_kubbs("theirs", true).size(), fallen_kubbs("theirs").size()])
	thrower.launch_meter(0.1, 0.0)
	var t0 := Time.get_ticks_msec()
	while phase != Phase.OPP_THROW and Time.get_ticks_msec() - t0 < 60000:
		await get_tree().physics_frame
	print("   inkastat hos mig: fältkubbar %d" % _count_field("mine"))
	while phase != Phase.PLAYER or state != State.READY:
		await get_tree().physics_frame
		if _match_over:
			break
	print("   tillbaka till min tur %d. Mina stående %d (fält %d), deras stående %d (fält %d), över=%s" % [
		turn, side_kubbs("mine", true).size(), _count_field("mine"), side_kubbs("theirs", true).size(), _count_field("theirs"), _match_over])
	# kungen för tidigt
	await _wait_ready()
	batons_left = 3
	thrower.stand_x = -0.18
	thrower.aim = 0.0
	await get_tree().physics_frame
	thrower.launch_with(0.6, 1250.0, 0.0)
	while state == State.FLYING:
		await get_tree().physics_frame
	print("TEST på kungen: över=%s run aktiv=%s" % [_match_over, Run.active])
	# kubbleken och fältkubbsregeln
	Run.start("krutpinne")
	Run.cards.assign(["krutkubb", "dominokubb", "askkubb", "tandkubb", "pinnkubb"])
	_start(Mode.MATCH, true)
	await _wait_ready()
	var kinds: Array[String] = []
	for k in side_kubbs("theirs"):
		kinds.append(k.kind if k.kind != "" else "-")
	print("TEST kubbleken på hans baslinje: %s" % ", ".join(kinds))
	var mid: Kubb = null
	for k in side_kubbs("theirs"):
		if absf(k.home.origin.x) < 0.1:
			mid = k
	mid.set_kind("krutkubb")
	var teeth0 := Run.teeth
	batons_left = 5
	thrower.stand_x = -0.18
	thrower.aim = 0.0
	await get_tree().physics_frame
	thrower.launch_with(0.6, 2900.0, 0.0)
	while state == State.FLYING:
		await get_tree().physics_frame
	print("TEST krutkubb i mitten: fällda %d, tänder %d -> %d" % [fallen_kubbs("theirs").size(), teeth0, Run.teeth])
	for id in Cards.FATE:
		_apply_fate(id)
	Run.fate_points = 0
	await _fate_after_throw(7)
	print("TEST ödespoäng kvar %d (av 7 fällda, kostnad %d)" % [Run.fate_points, Run.FATE_COST])
	print("TEST ödeskort dragna %d, lek %d, lånad pinne '%s', denna match %s" % [Run.cards_drawn, Run.cards.size(), Run.borrowed, str(Run.temp_names)])
	thrower.meter_phase = 1
	thrower.meter = 0.6
	thrower._update_pose()
	print("TEST landningsmärke live: %.2f m, kraft för baslinjen %.2f" % [thrower.land_dist, thrower.power_for_distance(World.FIELD_L)])
	thrower.meter_phase = 0
	# en stående fältkubb på min sida: jag får kliva fram
	var fk: Kubb = side_kubbs("mine")[0]
	fk.field = true
	fk.raise_at(Vector3(0.6, 0, -2.6))
	_start_player_turn()
	print("TEST kliva fram: kastlinje z %.2f (fältkubb på -2.60)" % thrower.throw_z)
	var tk: Kubb = side_kubbs("theirs")[0]
	tk.field = true
	tk.raise_at(Vector3(-0.5, 0, -5.4))
	print("TEST hans kastlinje: z %.2f (fältkubb på -5.40)" % _advance_line("theirs"))
	print("TEST antal kubbar %d, pinnar %d" % [Cards.DEFS.size(), Cards.BATONS.size()])
	_match_over = true
	Run.stop()
	# butik och kort
	Run.start("vanlig")
	Run.teeth = 20
	print("TEST köp %s: %s, tänder kvar %d, pinnar per tur %d" % ["bjorkkubb", Run.buy("bjorkkubb"), Run.teeth, 6 + int(Run.mod("batons_add"))])
	print("TEST grönt med midsommarkubben: före %.2f" % thrower.perfect())
	Run.buy("stangkubb")
	print("   efter %.2f" % thrower.perfect())
	# träning
	_start(Mode.TRAINING, true)
	for i in 3:
		await _wait_ready()
		dog.set_physics_process(false)
		dog.global_position = Vector3(0, 0, -6.0)
		dog.rotation.y = PI * 0.5
		thrower.stand_x = -0.18
		thrower.aim = 0.0
		await get_tree().physics_frame
		thrower.launch_with(0.6, 2050.0 + i * 100.0, 0.0)
		while state == State.FLYING or state == State.BUSY:
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
	Run.start("vanlig")
	Run.teeth = 14
	Run.cards.assign(["krakkubb", "tummkubb", "krutkubb"])
	menu.open("shop")
	for i in 5:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_butik.png")
	menu.open("baton")
	for i in 5:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_pinne.png")
	Run.match_index = 1
	_start(Mode.MATCH, true)
	thrower.mouse_aim = false
	thrower.stand_x = -0.18
	for i in 40:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_leffe.png")
	thrower.meter_phase = 1
	thrower._meter_t = 0.75 * ThrowController.METER_TIME
	hud.fate_card("Lånad pinne", "Istappen: Kall. Flyger 10 % längre, knuffar 40 % hårdare.", Color(0.7, 0.95, 1.0))
	for i in 30:
		await get_tree().process_frame
	thrower.meter_phase = 0
	vp.get_texture().get_image().save_png(prefix + "_kraft.png")
	var bk: Kubb = side_kubbs("theirs")[1]
	Fx.boom(self, bk.global_position)
	Fx.zap(self, side_kubbs("theirs")[3].global_position)
	for i in 4:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_effekt.png")
	_clear_batons()
	thrower.input_enabled = false
	phase = Phase.OPP_THROW
	opponent.say("my_turn")
	_opp_throw()
	for i in 70:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_leffekast.png")
	get_tree().quit()
