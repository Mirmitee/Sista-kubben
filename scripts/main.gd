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
var _touch_t := 0.0
var _extras: Array[Baton] = []
var _homing_targets: Array[Vector3] = []
var _boom_done := false
var _streak := 0
var _opp_left := 0
var _opp_total := 0
var _match_teeth := 0
var _cam_z := 0.0
# poäng (Balatro-stil): marker x multi per kast, mot blodmånens krav
var score := 0
var _charge := 0           # +multi som väntar på nästa kast som fäller
var _throw_xmult := 1.0    # från träffeffekter under kastet
var _batons_bonus_next := 0
var _match_felled := 0
var _throw_no := 0         # vilket kast i turen
var _tier := 0             # hur många av månens krav som nåtts
var _extra_draws := 0
var _fast := false
var _slowmo_on := false


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
	menu.shop_done.connect(_node_done)
	menu.map_pick.connect(_on_map_pick)
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
		if k.side == "gone":
			var show := mode != Mode.TRAINING or k.home.origin.z > -1.0
			k.visible = show
			k.collision_layer = 1 if show else 0
			k.collision_mask = 1 if show else 0
			k.freeze = not show
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
	if mode == Mode.MATCH:
		await hud.fade_out()
		_to_menu()
	Run.start(baton_id)
	menu.open("map")


## Spelaren valde en nod på kartan.
func _on_map_pick(i: int) -> void:
	var n := Run.choose(i)
	match n.type:
		"shop":
			menu.open("shop")
		"fate":
			menu.open("fate_node")
		"grave":
			menu.open("grave")
		_:
			_play_match()


func _node_done() -> void:
	Run.step_done()
	menu.open("map")


func _play_match() -> void:
	menu.close()
	if mode != Mode.MATCH:
		_start(Mode.MATCH)
		return
	await hud.fade_out()
	_begin_match()
	thrower.input_enabled = true
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
	opponent.setup_for_night(Run.night + (1 if Run.is_elite() else 0) + (1 if Run.night > Run.NIGHTS else 0))
	Run.opp_mods = opponent.mods_for_night(Run.night)
	Run.clear_temp()
	_double_next = false
	_streak = 0
	score = 0
	_charge = 0
	_batons_bonus_next = 0
	_match_felled = 0
	_tier = 0
	hud.set_score(0, _target(), true)
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
	var intro: String = Lang.t("night") % [Run.night, Run.nights_text()] + "\n" + (_tl("ELIT: ", "ELITE: ") if Run.is_elite() else "") + opponent.display_name[Lang.current]
	if opponent.rule_text[Lang.current] != "":
		intro += "\n" + opponent.rule_text[Lang.current]
	hud.banner(intro)
	opponent.say("start")
	_start_player_turn()


## Kubbleken ställs upp på hans baslinje (blandad), resten är vanliga.
func _place_deck() -> void:
	# dina 5 kubbar står alltid på samma plats, vänster till höger
	var mm := Run.mod("theirs_mass_mult", 1.0)
	for k in kubbs:
		k.set_kind("")
		k.slot = -1
		k.set_runes("", "", "")
	var row := side_kubbs("theirs")
	row.sort_custom(func(a, b): return a.home.origin.x < b.home.origin.x)
	for i in row.size():
		var id: String = Run.cards[i] if Run.active and i < Run.cards.size() else ""
		row[i].set_kind(id, mm)
		if Run.active and i < 5:
			row[i].slot = i
			row[i].set_runes(Run.enh[i], Run.ed[i], Run.seal[i], mm)
	# motståndarens egna specialkubbar: slump, fler senare nätter och hos bossen
	if not Run.active:
		return
	var n := int(randf() * (1.0 + Run.night * 0.8)) + (1 if Run.is_boss() else 0)
	n = mini(n, 3)
	if n <= 0:
		return
	var theirs := side_kubbs("theirs")
	var free := theirs.filter(func(k): return k.kind == "")
	var used := theirs.filter(func(k): return k.kind != "")
	free.shuffle()
	used.shuffle()
	var ids: Array = Cards.OPP_DEFS.keys()
	var names: Array[String] = []
	for j in n:
		var k: Kubb = null
		if not free.is_empty():
			k = free.pop_back()
		elif not used.is_empty() and randf() < 0.4:
			k = used.pop_back()  # han byter ut en av dina
		if k == null:
			break
		var id: String = ids[randi() % ids.size()]
		k.set_kind(id, mm)
		k.slot = -1
		k.set_runes("", "", "")
		names.append(Cards.title(id))
	if not names.is_empty():
		hud.toast(_tl("HAN HAR SMUGIT IN: ", "HE SNUCK IN: ") + ", ".join(names))


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
	batons_per_turn = maxi(1, base + int(Run.mod("batons_add")) + opponent.player_batons_add + _batons_bonus_next)
	if _batons_bonus_next > 0:
		hud.flash(_tl("+%d PINNE (FJÄDER)", "+%d BATON (FEATHER)") % _batons_bonus_next)
	_batons_bonus_next = 0
	batons_left = batons_per_turn
	_throw_no = 0
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
	if Run.active and mode == Mode.MATCH:
		Run.override = Run.hand.pop_front() if not Run.hand.is_empty() else ""
		if Run.override != "":
			hud.flash(_tl("PINNKORT: ", "BATON CARD: ") + Cards.title(Run.override).to_upper())
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


func _bdef() -> Dictionary:
	return Cards.BATONS.get(Run.cur_baton(), {}) if Run.active else {}


func _on_thrown(b: RigidBody3D, info: Dictionary) -> void:
	_last_info = info
	_extras.clear()
	_homing_targets.assign(thrower.magnet_targets)
	var bd := _bdef()
	if b is Baton and mode == Mode.MATCH and bd.has("multishot"):
		# multikast: fler pinnar i en solfjäder
		var n: int = bd.multishot
		for j in n - 1:
			var e := Baton.new()
			e.setup(Run.cur_baton())
			add_child(e)
			batons.append(e)
			e.body_entered.connect(_on_baton_hit.bind(e))
			var yaw := (0.12 if j % 2 == 0 else -0.12) * (1 + j / 2)
			e.global_transform = Transform3D(b.global_transform.basis.rotated(Vector3.UP, yaw), b.global_position + Vector3(randf_range(-0.05, 0.05), 0, 0))
			e.launch(b.linear_velocity.rotated(Vector3.UP, yaw), b.angular_velocity.rotated(Vector3.UP, yaw))
			_extras.append(e)
	if mode == Mode.MATCH:
		batons_left -= 1
		_throw_no += 1
		_throw_xmult = 1.0
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
	_touch_t = 0.0
	state = State.FLYING


func _on_dropped(b: RigidBody3D) -> void:
	_say("drop")
	batons.erase(b)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(b.queue_free)
	_next_baton()


func _on_baton_hit(body: Node, b: Baton) -> void:
	if (b != current and not b in _extras) or state != State.FLYING:
		return
	var bd := _bdef() if not current_by_opp else {}
	if bd.has("grenade") and not b.get_meta("boomed", false):
		b.set_meta("boomed", true)
		call_deferred("_explode_at", b.global_position, float(bd.grenade))
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
	var hd: Dictionary = Cards.kdef(k.kind).get("hit", {})
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
		Fx.big_boom(self, k.global_position, f)
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
	if h.has("xmult"):
		_throw_xmult *= float(h.xmult)
		Fx.confetti(self, k.global_position)
		Sfx.play("sparkle", 0.0, 1.4)
		hud.popup_col(camera.unproject_position(k.global_position + Vector3(0, 0.5, 0)), "X%s MULTI" % str(snappedf(float(h.xmult), 0.1)), Color(1.0, 0.3, 0.9), 14)
	if h.has("stick"):
		call_deferred("_stick", b)
		Fx.burst(self, b.global_position, Color(0.9, 0.6, 0.2), 10, 0.8, 0.8, 0.03, 3.0, 0.5, 0.4)


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


## Granatpinnen: explosion var som helst.
func _explode_at(p: Vector3, f: float) -> void:
	Fx.big_boom(self, p, f)
	Sfx.play("boom", 0.0, 1.1)
	_shake = 0.8
	_slowmo()
	for o in kubbs:
		if not o.visible:
			continue
		var d := o.global_position - p
		d.y = 0.0
		var dist := d.length()
		var r := 1.3 * f
		if dist < r:
			o.sleeping = false
			var dir := d.normalized() if dist > 0.01 else Vector3.FORWARD
			o.apply_impulse((dir * 0.5 + Vector3.UP * 0.1) * (1.25 - dist / r), Vector3(0, o.height() * 0.45, 0))


func _stick(b: Baton) -> void:
	if is_instance_valid(b):
		b.linear_velocity = Vector3.ZERO
		b.angular_velocity = Vector3.ZERO
		Sfx.play("thud", -2.0, 0.6)


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
		var fd: Dictionary = Cards.kdef(k.kind).get("fell", {})
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
		if fd.has("lose_teeth"):
			bonus -= int(fd.lose_teeth)
			msg.append(_tl("-%d TÄNDER", "-%d TEETH") % int(fd.lose_teeth))
		if fd.has("lose_baton"):
			batons_left = maxi(batons_left - int(fd.lose_baton), 0)
			msg.append(_tl("DEN ÅT EN PINNE!", "IT ATE A BATON!"))
		if fd.has("topple_mine"):
			var mine := side_kubbs("mine", true).filter(func(o): return not o.field)
			mine.shuffle()
			for o in mine.slice(0, int(fd.topple_mine)):
				o.sleeping = false
				o.apply_impulse(Vector3(randf_range(-0.2, 0.2), 0, 0.45), Vector3(0, o.height() * 0.45, 0))
				Fx.sparks(self, o.global_position, Color(1, 0.1, 0.1), 12)
			msg.append(_tl("DIN KUBB FALLER!", "YOUR KUBB FALLS!"))
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
	# ett dragval per kast som fäller, plus ett per blått sigill
	var draws := 1 + _extra_draws
	_extra_draws = 0
	Run.fate_points = 0
	for di in draws:
		if _match_over:
			return
		var opts := _draw_options()
		if opts.is_empty():
			return
		var pick := 0
		thrower.input_enabled = false
		Sfx.play("sparkle", -4.0, 0.9)
		if not _autotest:
			var views: Array = []
			for o in opts:
				views.append(_choice_view(o))
			pick = await hud.choose_cards(views, _tl("DRA ETT KORT", "DRAW A CARD") + ("  (%d/%d)" % [di + 1, draws] if draws > 1 else ""))
		thrower.input_enabled = true
		_apply_choice(opts[pick])


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
			if not pool.is_empty() and Run.free_slot() >= 0:
				var kid: String = pool[randi() % pool.size()]
				var sl := Run.free_slot()
				Run.put(kid, sl)
				desc = _tl("Kubb %d får ", "Kubb %d gets ") % (sl + 1) + Cards.title(kid) + ": " + Cards.desc(kid) + _tl(" (nästa match)", " (next match)")
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
			if not cp.is_empty() and Run.free_slot() >= 0:
				var kid: String = cp[randi() % cp.size()]
				Run.put(kid, Run.free_slot())
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


# ---------------------------------------------------------------- poäng

const CHIP_COL := Color(0.35, 0.65, 1.0)
const MULT_COL := Color(1.0, 0.3, 0.25)
const XMULT_COL := Color(1.0, 0.35, 1.0)
const TEETH_COL := Color(1.0, 0.9, 0.4)
const TIERS := [1, 2, 4, 8, 16]
const TIER_TEETH := [3, 3, 5, 8, 12]


## Blodmånens krav för matchen (första nivån).
func _target() -> int:
	var n := Run.night if Run.active else 1
	var t := 120.0 * pow(2.4, n - 1)
	if Run.is_boss():
		t *= 1.4
	if Run.is_elite():
		t *= 1.2
	return int(snappedf(t, 10.0))


func _goal() -> int:
	return _target() * TIERS[mini(_tier, TIERS.size() - 1)]


func _slot_kubb(i: int) -> Kubb:
	for k in kubbs:
		if k.slot == i and k.visible:
			return k
	return null


func _tick(at: Node3D, text: String, col: Color, step: int, size := 10) -> void:
	var p := camera.unproject_position(at.global_position + Vector3(0, 0.3, 0)) + Vector2(randf_range(-8, 8), -6.0 * (step % 3))
	hud.popup_col(p, text, col, size)
	Sfx.play("click", -7.0, 0.9 + 0.07 * mini(step, 14))
	_shake = maxf(_shake, 0.12)
	if not _autotest:
		await get_tree().create_timer(0.085, true, false, true).timeout


## Vad en fälld kubb ger: lista av [typ, värde, text, färg]. Typer:
## c (marker), m (+multi), x (x multi), t (tänder), s (bara text).
func _kubb_steps(k: Kubb, n: int, first_rep: bool) -> Array:
	var out: Array = []
	var sv := Lang.current == "sv"
	var sl := k.slot
	var d: Dictionary = Cards.kdef(k.kind)
	var sc: Dictionary = d.get("score", {})
	if not sc.is_empty():
		if sc.has("chips"):
			out.append(["c", int(sc.chips), "", CHIP_COL])
		if sc.has("mult"):
			out.append(["m", float(sc.mult), "", MULT_COL])
		if sc.has("per_felled_mult"):
			out.append(["m", float(_match_felled * int(sc.per_felled_mult)), "", MULT_COL])
		if sc.has("per_cursed_mult"):
			var nc := 0
			for c in Run.cards:
				if c != "" and Cards.DEFS[c].get("cursed", false):
					nc += 1
			if nc > 0:
				out.append(["m", float(nc * int(sc.per_cursed_mult)), "", MULT_COL])
		if sc.has("teeth_mult") and Run.teeth >= 5:
			out.append(["m", float(int(Run.teeth / 5) * int(sc.teeth_mult)), "", MULT_COL])
		if sc.has("teeth_chips") and Run.teeth > 0:
			out.append(["c", Run.teeth, "", CHIP_COL])
		if sc.has("combo_mult") and n >= 2:
			out.append(["m", float(n * int(sc.combo_mult)), "", MULT_COL])
		if sc.has("all_enh_mult") and Run.enh.all(func(e): return e != ""):
			out.append(["m", float(sc.all_enh_mult), "", MULT_COL])
		if sc.has("last_xmult") and batons_left == 0:
			out.append(["x", float(sc.last_xmult), "MIDNATT!" if sv else "MIDNIGHT!", XMULT_COL])
		if sc.has("first_xmult") and _throw_no == 1:
			out.append(["x", float(sc.first_xmult), "GRYNING!" if sv else "DAWN!", XMULT_COL])
		if sc.has("perfect_xmult") and _last_info.get("grade", "") == "perfect":
			out.append(["x", float(sc.perfect_xmult), "PERFEKT!" if sv else "PERFECT!", XMULT_COL])
	if sl >= 0:
		if Run.grow_chips[sl] > 0:
			out.append(["c", Run.grow_chips[sl], "", CHIP_COL])
		if Run.grow_mult[sl] > 0:
			out.append(["m", float(Run.grow_mult[sl]), "", MULT_COL])
		if first_rep:
			if sc.has("grow_chips"):
				Run.grow_chips[sl] += int(sc.grow_chips)
				out.append(["s", 0, ("VÄXER +%d" if sv else "GROWS +%d") % int(sc.grow_chips), CHIP_COL])
			if sc.has("miss_grow"):
				Run.grow_mult[sl] = 0
		for r in [Run.enh[sl], Run.ed[sl], Run.seal[sl]]:
			if r == "":
				continue
			var rd: Dictionary = Cards.RUNES[r]
			var col: Color = (rd.col as Color).clamp(Color(0.3, 0.3, 0.3), Color(1, 1, 1))
			if rd.has("chips"):
				out.append(["c", int(rd.chips), "", CHIP_COL])
			if rd.has("mult"):
				out.append(["m", float(rd.mult), "", MULT_COL])
			if rd.has("xmult"):
				out.append(["x", float(rd.xmult), Cards.rune_title(r).to_upper(), XMULT_COL])
			if rd.has("blood") and _match_felled > 0:
				out.append(["m", float(_match_felled), "", MULT_COL])
			if rd.has("lucky"):
				if randf() < 0.25:
					out.append(["m", 15.0, "TUR! +15 MULTI" if sv else "LUCKY! +15 MULT", Color(0.4, 1.0, 0.4)])
				if randf() < 1.0 / 12.0:
					out.append(["t", 10, "", TEETH_COL])
			if rd.has("teeth"):
				out.append(["t", int(rd.teeth), "", TEETH_COL])
			if rd.has("draw") and first_rep:
				_extra_draws += 1
				out.append(["s", 0, "+1 KORT" if sv else "+1 CARD", col])
			if rd.has("frost") and first_rep:
				Run.add_temp("opp_error_mult", float(rd.frost), "")
				out.append(["s", 0, "FROST!", col])
			if rd.has("risk") and randf() < 1.0 / 6.0:
				out.append(["t", -int(rd.risk), "BETT!" if sv else "BITE!", Color(0.6, 0.6, 0.7)])
			if rd.has("shatter") and first_rep and randf() < float(rd.shatter):
				Run.enh[sl] = ""
				k.shatter()
				Fx.burst(self, k.global_position + Vector3(0, 0.08, 0), Color(0.7, 0.9, 1.0), 22, 2.2, 0.8, 0.02, 7.0, 1.2, 1.0)
				Sfx.play("clack2", 0.0, 1.8)
				out.append(["s", 0, "KROSSAD!" if sv else "SHATTERED!", col])
	return out


## Balatro-räkning: varje fälld kubb ger marker och multi, en i taget med
## stigande ton. Sen marker x multi = poäng som tickar in i räknaren.
func _score_throw() -> void:
	if not Run.active or _felled_valid.is_empty():
		return
	var sv := Lang.current == "sv"
	var n := _felled_valid.size()
	_match_felled += n
	var chips := 0
	var mult := 1.0
	var step := 0
	var any: Node3D = _felled_valid[0]
	hud.tally(0, mult, true)
	if _charge > 0:
		mult += _charge
		await _tick(any, ("+%d MULTI (LADDAT)" if sv else "+%d MULT (CHARGED)") % _charge, MULT_COL, step)
		step += 1
		_charge = 0
	for k in _felled_valid:
		var base := 15 if k.field else 10
		chips += base
		Fx.fire(self, k.global_position, 0.6, 1.4)
		hud.tally(chips, mult)
		await _tick(k, "+%d" % base, CHIP_COL, step)
		step += 1
		var reps := 2 if k.slot >= 0 and Run.seal[k.slot] == "rott" else 1
		for r in reps:
			if r == 1:
				await _tick(k, "IGEN!" if sv else "AGAIN!", Color(1, 0.2, 0.2), step, 12)
				step += 1
			for st in _kubb_steps(k, n, r == 0):
				var label: String = st[2]
				match st[0]:
					"c":
						chips += int(st[1])
						if label == "":
							label = "+%d" % int(st[1])
					"m":
						mult += float(st[1])
						if label == "":
							label = ("+%d MULTI" if sv else "+%d MULT") % int(st[1])
					"x":
						mult *= float(st[1])
						Fx.boom(self, k.global_position, 0.35)
						Sfx.play("boom", -10.0, 1.6)
						label = ("X%s " % str(snappedf(float(st[1]), 0.1))) + label
					"t":
						Run.add_teeth(int(st[1]))
						if label == "":
							label = ("%+d TÄNDER" if sv else "%+d TEETH") % int(st[1])
				hud.tally(chips, mult)
				await _tick(k, label, st[3], step, 12 if st[0] == "x" else 10)
				step += 1
	if n >= 2:
		mult += (n - 1) * 2
		hud.tally(chips, mult)
		await _tick(any, ("KOMBO +%d MULTI" if sv else "COMBO +%d MULT") % ((n - 1) * 2), MULT_COL, step, 12)
		step += 1
	if _last_info.get("grade", "") == "perfect":
		mult += 2
		hud.tally(chips, mult)
		await _tick(any, ("PERFEKT +2 MULTI" if sv else "PERFECT +2 MULT"), MULT_COL, step)
		step += 1
	for k in kubbs:
		if k.slot >= 0 and k.visible and not k.is_fallen() and Run.enh[k.slot] == "stal":
			mult *= 1.5
			hud.tally(chips, mult)
			await _tick(k, ("X1.5 STÅL" if sv else "X1.5 STEEL"), XMULT_COL, step, 12)
			step += 1
	if _throw_xmult > 1.0:
		mult *= _throw_xmult
		hud.tally(chips, mult)
		await _tick(any, "X%s MULTI" % str(snappedf(_throw_xmult, 0.1)), XMULT_COL, step, 12)
	var total := int(chips * mult)
	hud.tally_total(total)
	score += total
	Run.score_total += total
	Run.lifetime.best_throw = maxi(Run.lifetime.get("best_throw", 0), total)
	Run.lifetime.best_score = maxi(Run.lifetime.get("best_score", 0), Run.score_total)
	_shake = clampf(0.2 + total / 400.0, 0.2, 1.2)
	Sfx.play("coin", -2.0, clampf(1.6 - total / 2000.0, 0.7, 1.6))
	if total >= 100:
		for k in _felled_valid:
			Fx.fire(self, k.global_position, clampf(total / 300.0, 0.8, 2.2), 2.2)
	if total >= 200:
		Fx.big_boom(self, any.global_position, clampf(total / 600.0, 0.6, 1.6))
		Sfx.play("boom", -3.0, 0.9)
	if total >= 1000:
		hud.big(_tl("SÅ MÅNGA POÄNG ATT MÅNEN BLEV RÄDD", "SO MANY POINTS THE MOON GOT SCARED"), Color(1.0, 0.4, 0.2))
		Fx.confetti(self, any.global_position)
	hud.set_score(score, _goal())
	_check_tier()


func _check_tier() -> void:
	while _tier < TIERS.size() and score >= _target() * TIERS[_tier]:
		var bonus: int = TIER_TEETH[_tier]
		_tier += 1
		Run.add_teeth(bonus)
		var msgs := [_tl("BLODMÅNEN ÄR MÄTT", "THE BLOOD MOON IS FED"), _tl("MÅNEN VILL HA MER", "THE MOON WANTS MORE"),
			_tl("MÅNEN DREGLAR", "THE MOON DROOLS"), _tl("MÅNEN SKRIKER", "THE MOON SCREAMS"), _tl("MÅNEN ÄR DIN", "THE MOON IS YOURS")]
		hud.big(msgs[mini(_tier - 1, msgs.size() - 1)] + "!  +%d %s" % [bonus, Lang.t("teeth")], Color(1.0, 0.25, 0.2))
		Fx.confetti(self, king.global_position + Vector3(0, 0.4, 0))
		Fx.flash_light(self, Vector3(0, 2.0, -8.0), Color(1.0, 0.1, 0.05), 6.0, 14.0, 0.9)
		for bi in 3:
			Fx.big_boom(self, Vector3(randf_range(-2.5, 2.5), 0, randf_range(-8.5, -5.0)), 0.9)
		Sfx.play("boom", 0.0, 0.7)
		Sfx.play("sparkle", 0.0, 0.8)
		Sfx.play("caw", -4.0)
		hud.set_score(score, _goal())
	_refresh_ui()


## Guld: tänder för kubbar som står kvar när din tur slutar.
func _stand_effects() -> void:
	if not Run.active or mode != Mode.MATCH:
		return
	for k in kubbs:
		if k.slot >= 0 and k.visible and not k.is_fallen():
			var r: String = Run.enh[k.slot]
			if r != "" and Cards.RUNES[r].has("stand_teeth"):
				var t: int = Cards.RUNES[r].stand_teeth
				Run.add_teeth(t)
				Fx.sparks(self, k.global_position + Vector3(0, 0.1, 0), Color(1.0, 0.85, 0.3), 12)
				await _tick(k, ("+%d TÄNDER (GULD)" if Lang.current == "sv" else "+%d TEETH (GOLD)") % t, TEETH_COL, 4)
	_refresh_ui()


## När en kubb kastas in och landar.
func _toss_effects(k: Kubb) -> void:
	if not Run.active or mode != Mode.MATCH:
		return
	var sv := Lang.current == "sv"
	var effects: Array = []
	var cd: Dictionary = Cards.kdef(k.kind).get("toss", {})
	if not cd.is_empty():
		effects.append([cd, Cards.color(k.kind)])
	if k.slot >= 0:
		for r in [Run.enh[k.slot], Run.seal[k.slot]]:
			if r != "" and Cards.RUNES[r].has("toss"):
				effects.append([Cards.RUNES[r].toss, Cards.RUNES[r].col])
	if effects.is_empty():
		return
	Fx.ring(self, k.global_position, Color(1.0, 0.8, 0.3), 0.6)
	Sfx.play("sparkle", -5.0, 1.3)
	var step := 0
	for e in effects:
		var t: Dictionary = e[0]
		var col: Color = (e[1] as Color).clamp(Color(0.3, 0.3, 0.3), Color(1, 1, 1))
		if t.has("teeth"):
			Run.add_teeth(int(t.teeth))
			await _tick(k, ("+%d TÄNDER" if sv else "+%d TEETH") % int(t.teeth), TEETH_COL, step)
		if t.has("grow_chips") and k.slot >= 0:
			Run.grow_chips[k.slot] += int(t.grow_chips)
			await _tick(k, ("+%d MARKER FÖR ALLTID" if sv else "+%d CHIPS FOREVER") % int(t.grow_chips), CHIP_COL, step)
		if t.has("grow_mult") and k.slot >= 0:
			Run.grow_mult[k.slot] += int(t.grow_mult)
			await _tick(k, ("+%d MULTI FÖR ALLTID" if sv else "+%d MULT FOREVER") % int(t.grow_mult), MULT_COL, step)
		if t.has("charge"):
			_charge += int(t.charge)
			await _tick(k, ("+%d MULTI LADDAT" if sv else "+%d MULT CHARGED") % int(t.charge), MULT_COL, step)
		if t.has("baton_next"):
			_batons_bonus_next += int(t.baton_next)
			await _tick(k, ("+%d PINNE NÄSTA TUR" if sv else "+%d BATON NEXT TURN") % int(t.baton_next), col, step)
		if t.has("rune") and k.slot >= 0:
			var es := Cards.runes_of("enh")
			var nid: String = es[randi() % es.size()]
			Run.enh[k.slot] = nid
			k.set_runes(Run.enh[k.slot], Run.ed[k.slot], Run.seal[k.slot])
			await _tick(k, Cards.rune_title(nid).to_upper() + "!", Cards.RUNES[nid].col, step, 12)
		step += 1
	_refresh_ui()


# ---------------------------------------------------------------- dragning

## Tre kort att välja mellan: ett ödeskort ur din lek, ett pinnkort och
## en runa eller ny kubb.
func _draw_options() -> Array[String]:
	var out: Array[String] = []
	var f := Run.draw_fate_one()
	if f != "":
		out.append("f:" + f)
	var pk: Array = Cards.PINNKORT.keys()
	out.append("p:" + str(pk[randi() % pk.size()]))
	var pool := Run.shop_pool()
	if randf() < 0.65 or pool.is_empty():
		var r := randf()
		var kind := "enh" if r < 0.7 else ("ed" if r < 0.85 else "seal")
		var rs := Cards.runes_of(kind)
		out.append("r:" + rs[randi() % rs.size()])
	else:
		out.append("k:" + pool[randi() % pool.size()])
	return out


func _choice_view(o: String) -> Array:
	var id := o.substr(2)
	var sv := Lang.current == "sv"
	match o.substr(0, 2):
		"f:":
			var v := _fate_view(id)
			v.append("ÖDESKORT" if sv else "FATE CARD")
			return v
		"p:":
			return [Cards.pk_title(id), Cards.pk_desc(id), Cards.BATONS[Cards.PINNKORT[id][0]].get("trail", Color(1, 0.8, 0.5)), "PINNKORT" if sv else "BATON CARD"]
		"r:":
			var kinds := {"enh": ["RUNA", "RUNE"], "ed": ["UTGÅVA", "EDITION"], "seal": ["SIGILL", "SEAL"]}
			var kn: Array = kinds[Cards.RUNES[id].kind]
			return [Cards.rune_title(id), Cards.rune_desc(id) + (" Fastnar på en av dina kubbar." if sv else " Sticks to one of your kubbs."), (Cards.RUNES[id].col as Color).clamp(Color(0.3, 0.3, 0.3), Color(1, 1, 1)), kn[0] if sv else kn[1]]
		_:
			return [Cards.title(id), Cards.desc(id), (Cards.color(id) * 0.8).clamp(Color(0.3, 0.3, 0.3), Color(1, 1, 1)), "NY KUBB" if sv else "NEW KUBB"]


func _apply_choice(o: String) -> void:
	var id := o.substr(2)
	var v := _choice_view(o)
	match o.substr(0, 2):
		"f:":
			_apply_fate(id)
			return
		"p:":
			var p: Array = Cards.PINNKORT[id]
			for i in int(p[1]):
				Run.hand.append(p[0])
			Run.cards_drawn += 1
			hud.fate_card(v[0], v[1], v[2])
			Sfx.play("whoosh", -4.0, 1.5)
		"r:":
			var kind: String = Cards.RUNES[id].kind
			var free: Array[int] = []
			for i in 5:
				if Run.rune_on(i, kind) == "":
					free.append(i)
			var sl: int = free[randi() % free.size()] if not free.is_empty() else randi() % 5
			Run.set_rune(sl, id)
			Run.cards_drawn += 1
			var k := _slot_kubb(sl)
			if k:
				k.set_runes(Run.enh[sl], Run.ed[sl], Run.seal[sl])
				Fx.ring(self, k.global_position, Cards.RUNES[id].col, 0.6)
				Fx.sparks(self, k.global_position + Vector3(0, 0.1, 0), Cards.RUNES[id].col, 16)
			hud.fate_card(v[0], _tl("Kubb %d: ", "Kubb %d: ") % (sl + 1) + Cards.rune_desc(id), v[2])
			Sfx.play("sparkle", -3.0, 1.1)
		"k:":
			var sl := Run.free_slot()
			if sl < 0:
				sl = randi() % 5
			var old: String = Run.cards[sl]
			Run.put(id, sl)
			Run.cards_drawn += 1
			var k := _slot_kubb(sl)
			if k:
				k.set_kind(id)
				k.set_runes(Run.enh[sl], Run.ed[sl], Run.seal[sl])
				Fx.ring(self, k.global_position, Cards.color(id), 0.6)
			var extra := (_tl(" (ersätter %s)", " (replaces %s)") % Cards.title(old)) if old != "" else ""
			hud.fate_card(v[0], _tl("Kubb %d: ", "Kubb %d: ") % (sl + 1) + Cards.desc(id) + extra, v[2])
			Sfx.play("clack", -3.0, 1.4)
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
	_slowmo_on = true
	Engine.time_scale = 0.3
	await get_tree().create_timer(0.35, true, false, true).timeout
	var tw := create_tween()
	tw.tween_property(Engine, "time_scale", 1.0, 0.08)
	tw.tween_callback(func(): _slowmo_on = false)


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
	var bdp := _bdef() if not current_by_opp else {}
	if current is Baton and not current.touched:
		if bdp.has("homing") and not _homing_targets.is_empty():
			# styr mjukt mot närmaste giltiga kubb
			var cp := current.global_position
			var best := _homing_targets[0]
			for t in _homing_targets:
				if Vector2(t.x - cp.x, t.z - cp.z).length() < Vector2(best.x - cp.x, best.z - cp.z).length():
					best = t
			var v: Vector3 = current.linear_velocity
			var flat := Vector3(v.x, 0, v.z)
			var want := Vector3(best.x - cp.x, 0, best.z - cp.z).normalized() * flat.length()
			flat = flat.lerp(want, clampf(dt * 2.5 * float(bdp.homing), 0.0, 1.0))
			current.linear_velocity = Vector3(flat.x, v.y, flat.z)
		if bdp.has("boomerang"):
			# bumerangen svänger lite åt vänster i luften
			var v2: Vector3 = current.linear_velocity
			current.linear_velocity = v2 + Vector3(v2.z, 0, -v2.x).normalized() * dt * 1.4
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
	if current.touched:
		_touch_t += dt
	else:
		_touch_t = 0.0
	# vänta aldrig länge på något som bara glider eller gungar
	var slow_enough := _touch_t > 2.2 and current.linear_velocity.length() < 0.8
	if (_fly_time > 0.8 and current.is_settled() and not moving and _pending_fx <= 0) or slow_enough or _touch_t > 3.5 or _fly_time > 6.0 or gone:
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
		await _score_throw()
		if _match_over:
			return
	elif Run.active:
		# envisa kubben växer av dina missar
		for i in 5:
			if Run.cards[i] != "" and Cards.DEFS[Run.cards[i]].get("score", {}).has("miss_grow"):
				Run.grow_mult[i] += int(Cards.DEFS[Run.cards[i]].score.miss_grow)
				var ek := _slot_kubb(i)
				if ek:
					hud.popup_col(camera.unproject_position(ek.global_position + Vector3(0, 0.3, 0)), _tl("+1 MULTI (ENVIS)", "+1 MULT (STUBBORN)"), Color(1.0, 0.35, 0.3), 8)
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
	if newly == 0 and not _hit_this_throw and _bdef().has("boomerang"):
		# bumerangen kommer tillbaka
		batons_left += 1
		hud.flash(_tl("BUMERANGEN KOM TILLBAKA!", "THE BOOMERANG CAME BACK!"))
		Sfx.play("whoosh", -2.0, 1.4)
		b.hold()
		var tw := create_tween()
		tw.tween_property(b, "global_position", thrower.shoulder() + Vector3(0, 0.3, -0.5), 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(b.queue_free)
		batons.erase(b)
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

func _simple() -> bool:
	return Settings.rules == "simple"


## Förenklade regler: fällda kubbar flyger iväg ut i mörkret och är borta.
func _throw_away(list: Array[Kubb]) -> void:
	for k in list:
		if _match_over:
			return
		Fx.dust(self, Vector3(k.global_position.x, 0.0, k.global_position.z), 1.0)
		Fx.sparks(self, k.global_position, Color(0.9, 0.3, 0.2), 8)
		Sfx.play("whoosh", -6.0, 1.3)
		var from := k.global_position
		var to := from + Vector3(randf_range(-1, 1) * 3.0, 2.5, -4.0 if k.side == "theirs" else 4.0)
		k.hold()
		var tw := create_tween()
		tw.tween_property(k, "global_position", to, 0.35)
		tw.parallel().tween_property(k, "rotation", Vector3(randf() * 6, randf() * 6, randf() * 6), 0.35)
		await tw.finished
		k.remove()
	_refresh_ui()


func _end_player_turn() -> void:
	state = State.BUSY
	thrower.input_enabled = false
	Run.override = ""
	await get_tree().create_timer(0.35).timeout
	await _stand_effects()
	_ghost.visible = false
	_line_mark.visible = false
	# 2. motståndaren kastar in kubbarna du fällde på din planhalva
	phase = Phase.OPP_TOSS
	_refresh_ui()
	if turn == 1:
		hud.toast(_tl("HÅLL F FÖR ATT SNABBSPOLA HANS TUR", "HOLD F TO FAST-FORWARD HIS TURN"))
	var fallen := fallen_kubbs("theirs")
	if _simple():
		# förenklat: fällda kubbar kastas bort, inget fram och tillbaka
		await _throw_away(fallen)
	elif not fallen.is_empty():
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
	await get_tree().create_timer(0.45).timeout
	var opp_n := maxi(1, 6 + int(Run.mod("opp_batons_add")) + _opp_batons_next + opponent.extra_batons)
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
	await get_tree().create_timer(0.3).timeout
	opponent.walk_to_x(0.0)
	opponent.walk_to_z(OPP_Z, 0.9)
	_line_mark.visible = false
	# 4. du kastar in kubbarna han fällde på hans planhalva (från baslinjen)
	phase = Phase.PLAYER_TOSS
	thrower.throw_z = 0.0
	var mine_fallen := fallen_kubbs("mine")
	_clear_batons()
	thrower.input_enabled = true
	if _simple():
		await _throw_away(mine_fallen)
		mine_fallen.clear()
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
			_toss_effects(k)
			return
		hud.flash(Lang.t("toss_out"))
	# två miss: du placerar den (långt från honom)
	k.side = "mine"
	k.raise_at(Vector3(randf_range(-2.0, 2.0), 0, -0.7))
	_toss_effects(k)


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
			_toss_effects(k)
			return
		if Run.mod("toss_forgive") > 0.0:
			k.side = "theirs"
			k.raise_at(Vector3(clampf(p.x, -2.2, 2.2), 0, clampf(p.z, -7.7, -4.3)))
			_toss_effects(k)
			return
		hud.flash(Lang.t("toss_out"))
	# två miss: motståndaren placerar den där den är svårast att träffa
	k.side = "theirs"
	k.raise_at(Vector3(randf_range(-2.2, 2.2), 0, -7.6))
	_toss_effects(k)


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
	if Run.is_elite():
		reward = int(reward * 1.5)
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
		menu.open("map")


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
	_update_magnet()
	# hans tur går lite fortare, och håll F för att snabbspola
	if not _slowmo_on and not _autotest:
		var want := 1.0
		if mode == Mode.MATCH and not _match_over and not menu.visible and (phase == Phase.OPP_TOSS or phase == Phase.OPP_THROW):
			want = 3.0 if Input.is_key_pressed(KEY_F) or Input.is_joy_button_pressed(0, JOY_BUTTON_Y) else 1.3
		if not get_tree().paused and absf(Engine.time_scale - want) > 0.01:
			Engine.time_scale = want
	var ff := Engine.time_scale > 2.0
	if ff != _fast:
		_fast = ff
		hud.fast(ff)
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
	var deck_on := mode == Mode.MATCH and Run.active and not menu.visible and (Input.is_key_pressed(KEY_TAB) or Input.is_joy_button_pressed(0, JOY_BUTTON_BACK))
	var his: Array = []
	if deck_on:
		for k in kubbs:
			if Cards.OPP_DEFS.has(k.kind) and not his.has(k.kind):
				his.append(k.kind)
	hud.show_deck(deck_on, his)
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


## Siktmagneten: vilka kubbar spelaren får sikta på just nu.
func _update_magnet() -> void:
	thrower.magnet_targets.clear()
	if mode == Mode.MENU or phase != Phase.PLAYER or thrower.payload_kubb:
		return
	if mode == Mode.TRAINING:
		thrower.magnet_targets.append(dog.global_position)
		return
	var st := side_kubbs("theirs", true)
	var field := st.filter(func(k): return k.field)
	var pool: Array = field if not field.is_empty() else st
	for k in pool:
		thrower.magnet_targets.append(k.global_position)
	if st.is_empty():
		thrower.magnet_targets.append(king.global_position)


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
	# förenklade regler: fällda kubbar kastas bort
	var old_rules := Settings.rules
	Settings.rules = "simple"
	Run.start("vanlig")
	_start(Mode.MATCH, true)
	await _wait_ready()
	batons_left = 1
	thrower.stand_x = -0.18
	thrower.aim = 0.0
	await get_tree().physics_frame
	var ft := Time.get_ticks_msec()
	thrower.launch_with(0.6, 2900.0, 0.0)
	while state == State.FLYING:
		await get_tree().physics_frame
	print("TEST pinnen stannade efter %.1f s speltid" % _fly_time)
	var t1 := Time.get_ticks_msec()
	while (phase != Phase.PLAYER or state != State.READY) and Time.get_ticks_msec() - t1 < 90000:
		await get_tree().physics_frame
		if _match_over:
			break
	print("   fas %d tillstånd %d över %s pinnar %d" % [phase, state, _match_over, batons_left])
	var gone := kubbs.filter(func(k): return k.side == "gone").size()
	print("TEST förenklat: borta %d, hans stående %d, mina stående %d, fältkubbar %d" % [gone, side_kubbs("theirs", true).size(), side_kubbs("mine", true).size(), _count_field("mine") + _count_field("theirs")])
	Settings.rules = old_rules
	_match_over = true
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
	print("TEST poäng efter krutkubben: %d (krav %d, nivå %d), runor %s" % [score, _target(), _tier, str(Run.enh)])
	# runor: glas+holo+rött sigill på en kubb, fäll den manuellt
	var rk := _slot_kubb(3)
	Run.enh[3] = "glas"
	Run.ed[3] = "holo"
	Run.seal[3] = "rott"
	rk.set_runes("glas", "holo", "rott")
	_felled_valid.clear()
	_felled_valid.append(rk)
	var s0 := score
	await _score_throw()
	print("TEST glas+holo+rött sigill: +%d poäng (väntat (10+0)*(1+10+10)*2*2 eller utan glas)" % (score - s0))
	Run.cards[2] = "myrstack"
	Run.enh[2] = "barnsten"
	var tk2 := _slot_kubb(2)
	tk2.set_kind("myrstack")
	_toss_effects(tk2)
	await get_tree().create_timer(0.5).timeout
	print("TEST inkast myrstack+bärnsten: växt marker %d multi %d" % [Run.grow_chips[2], Run.grow_mult[2]])
	for o in ["p:pk_granat", "r:folie", "k:snoboll"]:
		_apply_choice(o)
	print("TEST dragning: hand %s, utgåvor %s, kort %s, alternativ %s" % [str(Run.hand), str(Run.ed), str(Run.cards), str(_draw_options())])
	_next_baton()
	print("TEST pinnkort i handen ger pinne: %s" % Run.cur_baton())
	print("TEST antal: runor %d, pinnkort %d" % [Cards.RUNES.size(), Cards.PINNKORT.size()])
	for id in Cards.FATE:
		_apply_fate(id)
	Run.fate_points = 0
	await _fate_after_throw(7)
	print("TEST ödespoäng kvar %d (av 7 fällda, kostnad %d)" % [Run.fate_points, Run.FATE_COST])
	print("TEST ödeskort dragna %d, lek %d, lånad pinne '%s', denna match %s" % [Run.cards_drawn, Run.slots_used(), Run.borrowed, str(Run.temp_names)])
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
	for bid in ["trepinnen", "granatpinne", "bumerang", "malsokare"]:
		Run.start(bid)
		_start(Mode.MATCH, true)
		await _wait_ready()
		batons_left = 5
		thrower.stand_x = 0.4
		thrower.aim = 0.03
		_update_magnet()
		thrower.magnet_targets.assign(thrower.magnet_targets)
		await get_tree().physics_frame
		var bl := batons_left
		thrower.launch_with(0.6, 2900.0 if bid != "bumerang" else 1500.0, 0.0)
		while state == State.FLYING:
			await get_tree().physics_frame
		await get_tree().physics_frame
		print("TEST %s: fällda %d, pinnar %d -> %d, extra pinnar i luften %d" % [bid, fallen_kubbs("theirs").size(), bl, batons_left, _extras.size()])
	_match_over = true
	Run.stop()
	# butik och kort
	Run.start("vanlig")
	Run.teeth = 20
	print("TEST köp %s: %s, tänder kvar %d, pinnar per tur %d" % ["bjorkkubb", Run.buy("bjorkkubb"), Run.teeth, 6 + int(Run.mod("batons_add"))])
	print("TEST grönt med midsommarkubben: före %.2f" % thrower.perfect())
	Run.buy("stangkubb")
	print("   efter %.2f" % thrower.perfect())
	# kartan: gå igenom tre nätter och in i den oändliga
	Run.start("vanlig")
	var won := false
	var path: Array[String] = []
	for guard in 40:
		var n := Run.choose(randi() % Run.map[Run.layer].size())
		path.append(n.type + ("/" + n.opp if n.has("opp") else ""))
		if n.type in ["match", "elite", "boss"]:
			if Run.advance():
				won = true
				break
		else:
			Run.step_done()
	print("TEST karta: %d noder, vann runnen %s, natt %d, %s" % [path.size(), won, Run.night, Run.nights_text()])
	print("   väg: %s" % ", ".join(path.slice(0, 5)))
	Run.endless = true
	print("TEST oändlig natt: %s" % Run.nights_text())
	_set_opponent("birgit")
	opponent.setup_for_night(2)
	print("TEST Birgit: %s, extra pinnar %d, fel %.3f" % [opponent.display_name.sv, opponent.extra_batons, opponent.error_yaw])
	_set_opponent("vedgubben")
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
	var mt := Time.get_ticks_msec()
	while Sfx._music_stream == null and Time.get_ticks_msec() - mt < 20000:
		await get_tree().process_frame
	print("TEST musik klar: %s (%.1f s ljud)" % [Sfx._music_stream != null, Sfx._music_stream.get_length() if Sfx._music_stream else 0.0])
	if Sfx._music_stream and OS.get_environment("MUSIK_WAV") != "":
		Sfx._music_stream.save_to_wav(OS.get_environment("MUSIK_WAV"))
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
	Run.cards.assign(["krakkubb", "", "krutkubb", "tummkubb", "krutkubb"])
	menu.open("shop")
	for i in 5:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_butik.png")
	menu._pending = menu._offers[0]
	menu.show_page("slot")
	for i in 5:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_plats.png")
	Run.choose(0)
	Run.step_done()
	menu.open("map")
	for i in 5:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_karta.png")
	menu.open("baton")
	for i in 5:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_pinne.png")
	Run.node = {"type": "match", "opp": "birgit"}
	_start(Mode.MATCH, true)
	thrower.mouse_aim = false
	for i in 40:
		await get_tree().process_frame
	hud.choose_cards([_choice_view("f:gront"), _choice_view("p:pk_granat"), _choice_view("r:glas")], _tl("DRA ETT KORT", "DRAW A CARD"))
	for i in 20:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_birgit.png")
	hud.fate_chosen.emit(0)
	for i in 200:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_birgit2.png")
	Run.node = {"type": "boss", "opp": "tjock_leffe"}
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
	# poängräkning med eld
	Run.node = {"type": "match", "opp": "vedgubben"}
	Run.enh.assign(["glas", "multi", "stal", "bonus", "lycka"])
	Run.ed.assign(["", "holo", "", "poly", ""])
	Run.seal.assign(["rott", "", "", "", "blatt"])
	_start(Mode.MATCH, true)
	thrower.mouse_aim = false
	for i in 40:
		await get_tree().process_frame
	_felled_valid.clear()
	for si in [0, 1, 3]:
		var sk := _slot_kubb(si)
		sk.apply_impulse(Vector3(0, 0, -0.4), Vector3(0, 0.07, 0))
		_felled_valid.append(sk)
	for i in 30:
		await get_tree().process_frame
	_score_throw()
	for i in 40:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_poang.png")
	for i in 60:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_poang2.png")
	Fx.big_boom(self, side_kubbs("theirs")[2].global_position, 1.3)
	for i in 8:
		await get_tree().process_frame
	vp.get_texture().get_image().save_png(prefix + "_boom.png")
	get_tree().quit()
