## Bygger ängen: mark, plan, björkar, midsommarstång, himmel och blodmåne.
## Plan: 5 x 8 m. Spelarens baslinje z = 0, motståndarens z = -8.
class_name World
extends Node3D

const FIELD_W := 5.0
const FIELD_L := 8.0
const MOON_DIR := Vector3(-0.30, 0.15, -0.94)

var sky: MeshInstance3D
var moon: MeshInstance3D
var _flies: Array[MeshInstance3D] = []
var _fly_seed: Array[Vector3] = []
var _t := 0.0


func _ready() -> void:
	_build_ground()
	_build_lines()
	_build_trees()
	_build_maypole()
	_build_sky()
	_build_fireflies()


func _build_ground() -> void:
	var ground := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(80, 1, 80)
	col.shape = bs
	col.position.y = -0.5
	ground.add_child(col)
	var pm := PhysicsMaterial.new()
	pm.friction = 0.85
	pm.bounce = 0.05
	ground.physics_material_override = pm
	var mi := MeshInstance3D.new()
	var pmesh := PlaneMesh.new()
	pmesh.size = Vector2(80, 80)
	pmesh.subdivide_width = 30
	pmesh.subdivide_depth = 30
	mi.mesh = pmesh
	mi.material_override = PS1.mat(PS1.grass(), Color.WHITE, Vector2(80, 80))
	ground.add_child(mi)
	# klippt gräs på planen
	var lawn := MeshInstance3D.new()
	var lm := PlaneMesh.new()
	lm.size = Vector2(FIELD_W + 0.6, FIELD_L + 0.6)
	lm.subdivide_width = 4
	lm.subdivide_depth = 6
	lawn.mesh = lm
	lawn.material_override = PS1.mat(PS1.grass(), Color(1.25, 1.2, 1.0), Vector2(FIELD_W, FIELD_L))
	lawn.position = Vector3(0, 0.004, -FIELD_L * 0.5)
	ground.add_child(lawn)
	add_child(ground)


func _line(a: Vector3, b: Vector3, m: Material) -> void:
	var d := b - a
	var mi := PS1.box(Vector3(0.04, 0.004, d.length()), m)
	mi.position = (a + b) * 0.5 + Vector3(0, 0.01, 0)
	mi.rotation.y = atan2(d.x, d.z)
	add_child(mi)


func _build_lines() -> void:
	var m := PS1.mat(null, Color(0.72, 0.68, 0.58))
	var hw := FIELD_W * 0.5
	_line(Vector3(-hw, 0, 0), Vector3(hw, 0, 0), m)
	_line(Vector3(-hw, 0, -FIELD_L), Vector3(hw, 0, -FIELD_L), m)
	_line(Vector3(-hw, 0, 0), Vector3(-hw, 0, -FIELD_L), m)
	_line(Vector3(hw, 0, 0), Vector3(hw, 0, -FIELD_L), m)
	for i in 5:  # streckad mittlinje
		var x := -hw + 0.25 + i * 1.0
		_line(Vector3(x, 0, -FIELD_L * 0.5), Vector3(x + 0.5, 0, -FIELD_L * 0.5), m)
	var stake := PS1.mat(PS1.wood(30, Color(0.5, 0.4, 0.3)))
	for x in [-hw, hw]:
		for z in [0.0, -FIELD_L]:
			var s := PS1.cylinder(0.02, 0.3, stake, 4)
			s.position = Vector3(x, 0.15, z)
			add_child(s)


func _build_trees() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1906
	var bark := PS1.mat(PS1.birch(), Color.WHITE, Vector2(1, 4))
	var leaves := PS1.mat(PS1.cloth(), Color(0.55, 1.6, 0.6), Vector2(2, 2))
	var needles := PS1.mat(PS1.cloth(), Color(0.22, 0.75, 0.38), Vector2(3, 3))
	var spruce_bark := PS1.mat(PS1.wood(7, Color(0.35, 0.24, 0.2)), Color.WHITE, Vector2(1, 3))
	var placed := 0
	while placed < 46:
		var p := Vector3(r.randf_range(-26, 26), 0, r.randf_range(-34, 10))
		if absf(p.x) < 5.5 and p.z > -14.0:
			continue
		if p.distance_to(Vector3(0, 0, 2.5)) < 6.0:
			continue
		if p.z < -14.0 and absf(p.x - p.z * 0.32) < 4.0:
			continue  # lämna en glänta mot månen och stången
		if r.randf() < 0.55:
			_spruce(p, r, spruce_bark, needles)
			placed += 1
			continue
		var h := r.randf_range(5.0, 9.5)
		var trunk := PS1.cylinder(r.randf_range(0.09, 0.16), h, bark, 5)
		trunk.position = p + Vector3(0, h * 0.5, 0)
		trunk.rotation.z = r.randf_range(-0.06, 0.06)
		add_child(trunk)
		for k in 3:
			var blob := PS1.sphere(r.randf_range(0.9, 1.6), leaves, 5, 3)
			blob.position = p + Vector3(r.randf_range(-0.7, 0.7), h - 0.5 - k * 1.1, r.randf_range(-0.7, 0.7))
			add_child(blob)
		placed += 1


## Gran: mörk stam och fyra–fem sexkantiga kjolar som smalnar av uppåt.
func _spruce(p: Vector3, r: RandomNumberGenerator, bark: Material, needles: Material) -> void:
	var h := r.randf_range(6.0, 11.0)
	var trunk := PS1.cylinder(0.14, h * 0.5, bark, 5, 0.1)
	trunk.position = p + Vector3(0, h * 0.25, 0)
	add_child(trunk)
	var tiers := r.randi_range(4, 5)
	var base_r := r.randf_range(1.5, 2.2)
	for k in tiers:
		var f := float(k) / float(tiers)
		var tr := base_r * (1.0 - f * 0.72)
		var th := h * 0.36 * (1.0 - f * 0.35)
		var cone := PS1.cylinder(tr, th, needles, 6, 0.0)
		cone.position = p + Vector3(0, h * 0.18 + f * h * 0.72 + th * 0.5, 0)
		cone.rotation.y = r.randf() * TAU
		cone.rotation.z = r.randf_range(-0.05, 0.05)
		add_child(cone)


func _build_maypole() -> void:
	# midsommarstången, i siluett mot månen
	var base := Vector3(-13.0, 0, -40.0)
	var green := PS1.mat(PS1.cloth(), Color(0.6, 1.4, 0.6))
	var pole := PS1.cylinder(0.14, 12.0, green, 5)
	pole.position = base + Vector3(0, 6.0, 0)
	add_child(pole)
	var bar := PS1.box(Vector3(3.6, 0.22, 0.22), green)
	bar.position = base + Vector3(0, 10.2, 0)
	add_child(bar)
	for s in [-1.0, 1.0]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.75
		tm.outer_radius = 0.95
		tm.rings = 8
		tm.ring_segments = 4
		ring.mesh = tm
		ring.material_override = green
		ring.position = base + Vector3(s * 1.6, 9.2, 0)
		ring.rotation.x = PI * 0.5
		add_child(ring)


func _build_sky() -> void:
	sky = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 120
	sm.height = 240
	sm.radial_segments = 16
	sm.rings = 8
	sky.mesh = sm
	sky.material_override = PS1.sky_mat()
	add_child(sky)
	moon = PS1.sphere(9.0, PS1.mat(null, Color(0.85, 0.09, 0.05), Vector2.ONE, 1.0, false), 10, 6)
	add_child(moon)


func _build_fireflies() -> void:
	var m := PS1.mat(null, Color(0.9, 1.0, 0.4), Vector2.ONE, 1.0)
	var r := RandomNumberGenerator.new()
	r.seed = 99
	for i in 28:
		var f := PS1.box(Vector3(0.035, 0.035, 0.035), m)
		add_child(f)
		_flies.append(f)
		_fly_seed.append(Vector3(r.randf_range(-9, 9), r.randf_range(0.3, 2.2), r.randf_range(-16, 3)))


func follow_camera(cam_pos: Vector3) -> void:
	sky.global_position = cam_pos
	moon.global_position = cam_pos + MOON_DIR.normalized() * 100.0


func _process(dt: float) -> void:
	_t += dt
	for i in _flies.size():
		var s := _fly_seed[i]
		var ph := float(i) * 1.7
		_flies[i].position = s + Vector3(sin(_t * 0.3 + ph) * 1.2, sin(_t * 0.9 + ph) * 0.3, cos(_t * 0.25 + ph) * 1.2)
		_flies[i].visible = sin(_t * 1.3 + ph * 3.0) > -0.3
