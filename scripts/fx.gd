## Billiga PS1-effekter: flisor, damm, gnistor, explosioner och blixtar.
## Allt är små lådor som flyger, krymper och försvinner.
class_name Fx
extends RefCounted


class Bit extends MeshInstance3D:
	var vel := Vector3.ZERO
	var grav := 9.8
	var life := 0.6
	var age := 0.0
	var grow := 0.0
	var spin := Vector3.ZERO

	func _process(dt: float) -> void:
		age += dt
		vel.y -= grav * dt
		position += vel * dt
		rotation += spin * dt
		if position.y < 0.005 and grav > 0.0:
			position.y = 0.005
			vel *= 0.3
		var k := 1.0 - age / life
		scale = Vector3.ONE * maxf(k, 0.01) * (1.0 + grow * age)
		if age >= life:
			set_process(false)
			queue_free()

	func _exit_tree() -> void:
		Fx.live = maxi(Fx.live - 1, 0)


static var _mats := {}
static var _bit_meshes := {}
## Antal flygande bitar just nu. Över taket hoppar vi över nya (ingen lagg vid jättesmällar).
static var live := 0
const MAX_BITS := 700


static func _mat(c: Color, emit: float) -> Material:
	var key := "%s_%.2f" % [c.to_html(), emit]
	if not _mats.has(key):
		_mats[key] = PS1.mat(null, c, Vector2.ONE, emit)
	return _mats[key]


static func burst(parent: Node, pos: Vector3, color: Color, n := 8, speed := 2.0, life := 0.6,
		size := 0.02, grav := 9.8, up := 1.0, emit := 0.6, grow := 0.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	if live >= MAX_BITS:
		return
	n = mini(n, MAX_BITS - live)
	var m := _mat(color, emit)
	var bm: BoxMesh = _bit_meshes.get(size)
	if bm == null:
		bm = BoxMesh.new()
		bm.size = Vector3.ONE * size
		_bit_meshes[size] = bm
	live += n
	for i in n:
		var b := Bit.new()
		b.mesh = bm
		b.material_override = m
		var d := Vector3(randf_range(-1, 1), randf_range(0.2, 1.0) * up, randf_range(-1, 1)).normalized()
		b.vel = d * speed * randf_range(0.5, 1.0)
		b.grav = grav
		b.life = life * randf_range(0.7, 1.2)
		b.grow = grow
		b.spin = Vector3(randf_range(-12, 12), randf_range(-12, 12), randf_range(-12, 12))
		parent.add_child(b)
		b.global_position = pos


static func splinters(parent: Node, pos: Vector3, col := Color(0.8, 0.6, 0.4)) -> void:
	burst(parent, pos, col * 0.9, 9, 2.4, 0.55, 0.018, 9.8, 1.0, 0.4)
	burst(parent, pos, Color(1.0, 0.95, 0.8), 3, 1.2, 0.18, 0.03, 0.0, 0.5, 1.0)


static func dust(parent: Node, pos: Vector3, amount := 1.0) -> void:
	var n := int(5 * amount) + 1
	burst(parent, pos + Vector3(0, 0.03, 0), Color(0.28, 0.22, 0.2), n, 0.7 * amount, 0.8, 0.05, -0.25, 0.3, 0.15, 2.5)


static func sparks(parent: Node, pos: Vector3, col := Color(1.0, 0.85, 0.4), n := 14) -> void:
	burst(parent, pos, col, n, 3.0, 0.5, 0.014, 5.0, 1.2, 1.0)


static func confetti(parent: Node, pos: Vector3) -> void:
	for c in [Color(1, 0.2, 0.15), Color(1, 0.9, 0.3), Color(0.3, 1, 0.4), Color(0.4, 0.6, 1), Color(1, 0.4, 0.9)]:
		burst(parent, pos, c, 8, 4.5, 1.6, 0.025, 3.0, 2.0, 0.8)


static func flash_light(parent: Node, pos: Vector3, col: Color, energy := 3.0, rng := 4.0, t := 0.3) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	parent.add_child(l)
	l.global_position = pos + Vector3(0, 0.4, 0)
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, t)
	tw.tween_callback(l.queue_free)


static func boom(parent: Node, pos: Vector3, size := 1.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var ball := PS1.sphere(0.5 * size, _mat(Color(1.0, 0.6, 0.2), 1.0), 6, 4)
	parent.add_child(ball)
	ball.global_position = pos + Vector3(0, 0.15, 0)
	ball.scale = Vector3.ONE * 0.1
	var tw := ball.create_tween()
	tw.tween_property(ball, "scale", Vector3.ONE * 1.3, 0.12)
	tw.tween_property(ball, "scale", Vector3.ONE * 0.01, 0.2)
	tw.tween_callback(ball.queue_free)
	burst(parent, pos, Color(1.0, 0.75, 0.25), int(22 * size), 5.0 * size, 0.7, 0.025, 7.0, 1.4, 1.0)
	burst(parent, pos, Color(0.15, 0.12, 0.12), int(10 * size), 1.2, 1.4, 0.09, -0.6, 1.0, 0.1, 2.0)
	flash_light(parent, pos, Color(1.0, 0.55, 0.2), 5.0, 6.0 * size, 0.45)
	# lågor som stiger ur smällen
	burst(parent, pos, Color(1.0, 0.45, 0.1), int(14 * size), 1.4 * size, 0.8, 0.05, -3.0, 2.5, 1.0, -0.5)


## Taggig blixt från himlen ner till pos.
## Gnista som hoppar mellan två punkter (kedjereaktioner).
static func arc(parent: Node, from: Vector3, to: Vector3, col := Color(0.6, 0.85, 1.4)) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var holder := Node3D.new()
	parent.add_child(holder)
	var m := _mat(col, 1.0)
	var a := from
	var segs := 6
	for i in segs:
		var b := from.lerp(to, float(i + 1) / segs)
		if i < segs - 1:
			b += Vector3(randf_range(-0.08, 0.08), randf_range(0.0, 0.12), randf_range(-0.08, 0.08))
		var sl := maxf(a.distance_to(b), 0.01)
		var seg := PS1.box(Vector3(0.025, sl, 0.025), m)
		holder.add_child(seg)
		seg.global_position = (a + b) * 0.5
		var up := (b - a).normalized()
		var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
		seg.global_basis = Basis(side, up, side.cross(up))
		a = b
	var tw := holder.create_tween()
	tw.tween_interval(0.12)
	tw.tween_callback(func(): holder.visible = false)
	tw.tween_interval(0.04)
	tw.tween_callback(func(): holder.visible = true)
	tw.tween_interval(0.1)
	tw.tween_callback(holder.queue_free)
	sparks(parent, to + Vector3(0, 0.05, 0), col, 10)
	flash_light(parent, to, col, 4.0, 4.0, 0.25)


static func zap(parent: Node, pos: Vector3, col := Color(0.75, 0.85, 1.0)) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var holder := Node3D.new()
	parent.add_child(holder)
	var m := _mat(col, 1.0)
	var a := pos + Vector3(randf_range(-1, 1), 7.0, randf_range(-1, 1))
	var segs := 7
	for i in segs:
		var b := a.lerp(pos, float(i + 1) / segs)
		if i < segs - 1:
			b += Vector3(randf_range(-0.35, 0.35), 0, randf_range(-0.35, 0.35))
		var mid := (a + b) * 0.5
		var sl := a.distance_to(b)
		var seg := PS1.box(Vector3(0.05, sl, 0.05), m)
		holder.add_child(seg)
		seg.global_position = mid
		var up := (b - a).normalized()
		var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
		seg.global_basis = Basis(side, up, side.cross(up))
		a = b
	var tw := holder.create_tween()
	tw.tween_interval(0.16)
	tw.tween_callback(func(): holder.visible = false)
	tw.tween_interval(0.05)
	tw.tween_callback(func(): holder.visible = true)
	tw.tween_interval(0.08)
	tw.tween_callback(holder.queue_free)
	sparks(parent, pos + Vector3(0, 0.05, 0), col, 16)
	flash_light(parent, pos, col, 6.0, 8.0, 0.35)


## Platt ring som växer på marken (t.ex. när du kliver fram).
static func ring(parent: Node, pos: Vector3, col: Color, radius := 1.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.global_position = Vector3(pos.x, 0.02, pos.z)
	var m := _mat(col, 1.0)
	for i in 12:
		var a := TAU * i / 12.0
		var b := PS1.box(Vector3(0.12, 0.006, 0.03), m)
		b.position = Vector3(cos(a), 0, sin(a)) * 0.2
		b.rotation.y = -a + PI * 0.5
		holder.add_child(b)
	var tw := holder.create_tween()
	tw.tween_property(holder, "scale", Vector3(radius * 5.0, 1, radius * 5.0), 0.5)
	tw.tween_callback(holder.queue_free)


## 3D-eld: en låga som brinner en stund och spottar upp glödande lådor.
class Fire extends Node3D:
	var life := 1.5
	var power := 1.0
	var age := 0.0
	var _acc := 0.0
	var _light: OmniLight3D

	func _ready() -> void:
		_light = OmniLight3D.new()
		_light.light_color = Color(1.0, 0.5, 0.15)
		_light.omni_range = 1.5 + power
		_light.position.y = 0.25
		add_child(_light)

	func _process(dt: float) -> void:
		age += dt
		var k := clampf(1.0 - age / life, 0.0, 1.0)
		_light.light_energy = (1.5 + randf() * 1.5) * power * k
		_acc += dt * 45.0 * power * k
		while _acc >= 1.0:
			_acc -= 1.0
			var hot := randf()
			var col := Color(1.0, 0.35, 0.05).lerp(Color(1.0, 0.95, 0.4), hot)
			Fx.burst(get_parent(), global_position + Vector3(randf_range(-0.1, 0.1) * power, 0.02, randf_range(-0.1, 0.1) * power),
				col, 1, 0.5 + hot * 0.6, 0.45 + randf() * 0.35, 0.06 + 0.07 * power * randf(), -2.5 - 2.0 * hot, 2.5, 1.0, -0.6)
			if randf() < 0.12:
				Fx.burst(get_parent(), global_position + Vector3(0, 0.25 * power, 0), Color(0.12, 0.08, 0.08), 1, 0.3, 1.4, 0.06 * power, -0.8, 1.0, 0.1, 1.5)
		if age >= life:
			queue_free()


static func fire(parent: Node, pos: Vector3, power := 1.0, life := 1.5) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var f := Fire.new()
	f.power = power
	f.life = life
	parent.add_child(f)
	f.global_position = Vector3(pos.x, 0.0, pos.z)


## Stor explosion: eldklot, chockvåg, eld, rökpelare och flygande skräp.
static func big_boom(parent: Node, pos: Vector3, size := 1.0) -> void:
	boom(parent, pos, size)
	ring(parent, pos, Color(1.0, 0.6, 0.2), 1.2 * size)
	ring(parent, pos, Color(1.0, 0.95, 0.6), 0.7 * size)
	fire(parent, pos, 0.8 * size, 1.6)
	burst(parent, pos + Vector3(0, 0.1, 0), Color(0.3, 0.2, 0.15), int(14 * size), 5.5 * size, 1.3, 0.04, 9.8, 2.0, 0.2)
	burst(parent, pos + Vector3(0, 0.3, 0), Color(0.1, 0.07, 0.07), int(8 * size), 0.6, 2.5, 0.14 * size, -0.5, 2.0, 0.05, 1.8)
