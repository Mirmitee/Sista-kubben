## Fabrik för PS1-material och små procedurella texturer (32x32 osv).
## Allt ritas i kod så att projektet inte behöver importera bilder än.
class_name PS1
extends RefCounted

const SHADER := preload("res://shaders/ps1.gdshader")
const SKY_SHADER := preload("res://shaders/ps1_sky.gdshader")

static var _tex_cache := {}


static func mat(tex: Texture2D = null, tint := Color.WHITE, uv_scale := Vector2.ONE,
		emission := 0.0, fog := true) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("use_texture", tex != null)
	if tex:
		m.set_shader_parameter("albedo_tex", tex)
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("uv_scale", uv_scale)
	m.set_shader_parameter("emission", emission)
	if not fog:
		m.set_shader_parameter("fog_start", 9000.0)
		m.set_shader_parameter("fog_end", 10000.0)
	return m


static func sky_mat() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SKY_SHADER
	return m


static func _finish(key: String, img: Image) -> ImageTexture:
	var t := ImageTexture.create_from_image(img)
	_tex_cache[key] = t
	return t


static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func wood(seed := 1, base := Color(0.80, 0.64, 0.42)) -> ImageTexture:
	var key := "wood%d" % seed
	if _tex_cache.has(key):
		return _tex_cache[key]
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var r := _rng(seed)
	var phase := r.randf() * 10.0
	for y in 32:
		for x in 32:
			var g := sin((x + sin(y * 0.33 + phase) * 2.5) * 1.15) * 0.5 + 0.5
			var c := base.lerp(base * 0.55, g * 0.55 + r.randf_range(-0.08, 0.08))
			img.set_pixel(x, y, c)
	# en kvist, eller ett öga, vem vet
	var kx := r.randi_range(6, 25)
	var ky := r.randi_range(6, 25)
	for y in range(-3, 4):
		for x in range(-2, 3):
			if x * x + y * y * 0.5 < 5.0:
				img.set_pixel(kx + x, ky + y, base * 0.35)
	return _finish(key, img)


static func grass() -> ImageTexture:
	if _tex_cache.has("grass"):
		return _tex_cache["grass"]
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var r := _rng(42)
	var base := Color(0.20, 0.30, 0.13)
	for y in 32:
		for x in 32:
			img.set_pixel(x, y, base.lerp(Color(0.10, 0.17, 0.08), r.randf()))
	for i in 40:  # strån
		var x := r.randi_range(0, 31)
		var y := r.randi_range(0, 28)
		for k in 3:
			img.set_pixel(x, y + k, Color(0.30, 0.42, 0.18))
	for i in 3:  # midsommarblommor
		var fc: Color = [Color(0.9, 0.9, 0.8), Color(0.95, 0.85, 0.3), Color(0.7, 0.1, 0.1)][i]
		img.set_pixel(r.randi_range(0, 31), r.randi_range(0, 31), fc)
	return _finish("grass", img)


static func birch() -> ImageTexture:
	if _tex_cache.has("birch"):
		return _tex_cache["birch"]
	var img := Image.create(16, 32, false, Image.FORMAT_RGB8)
	var r := _rng(7)
	for y in 32:
		for x in 16:
			img.set_pixel(x, y, Color(0.82, 0.80, 0.74).lerp(Color(0.6, 0.6, 0.58), r.randf() * 0.4))
	for i in 9:
		var x0 := r.randi_range(0, 12)
		var y := r.randi_range(0, 31)
		for x in r.randi_range(2, 6):
			img.set_pixel((x0 + x) % 16, y, Color(0.06, 0.05, 0.05))
	return _finish("birch", img)


static func cloth() -> ImageTexture:
	if _tex_cache.has("cloth"):
		return _tex_cache["cloth"]
	var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
	var r := _rng(3)
	for y in 16:
		for x in 16:
			var v := 0.10 + r.randf() * 0.05 + (0.03 if (x + y) % 4 == 0 else 0.0)
			img.set_pixel(x, y, Color(v * 1.1, v * 0.9, v * 0.8))
	return _finish("cloth", img)


## Vedgubbens ansikte: snidat trä, tomma ögon, för många tänder.
static func face() -> ImageTexture:
	if _tex_cache.has("face"):
		return _tex_cache["face"]
	var img := Image.create(32, 40, false, Image.FORMAT_RGB8)
	var r := _rng(13)
	var base := Color(0.55, 0.45, 0.33)
	for y in 40:
		for x in 32:
			var g := sin((x + sin(y * 0.25) * 2.0) * 1.0) * 0.5 + 0.5
			img.set_pixel(x, y, base.lerp(base * 0.6, g * 0.5 + r.randf_range(-0.07, 0.07)))
	var dark := Color(0.04, 0.02, 0.02)
	for e in [Vector2i(9, 14), Vector2i(23, 15)]:  # ögonhålor, lite sneda
		for y in range(-4, 5):
			for x in range(-3, 4):
				if x * x / 9.0 + y * y / 16.0 <= 1.0:
					img.set_pixel(e.x + x, e.y + y, dark)
	for y in range(18, 25):  # näsa
		img.set_pixel(16, y, base * 0.45)
	for x in range(6, 27):  # mun
		var wob := int(sin(x * 0.9) * 1.2)
		for y in range(30, 35):
			img.set_pixel(x, y + wob, dark)
		if x % 2 == 0:
			img.set_pixel(x, 30 + wob, Color(0.85, 0.82, 0.70))
			img.set_pixel(x, 34 + wob, Color(0.80, 0.78, 0.66))
	for i in 3:  # sprickor
		var x := r.randi_range(2, 29)
		var y := r.randi_range(0, 10)
		for k in r.randi_range(5, 14):
			x = clampi(x + r.randi_range(-1, 1), 0, 31)
			img.set_pixel(x, mini(y + k, 39), base * 0.3)
	return _finish("face", img)


static func box(size: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	return mi


static func cylinder(radius: float, height: float, m: Material, segs := 6, top := -1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = radius
	cm.top_radius = radius if top < 0.0 else top
	cm.height = height
	cm.radial_segments = segs
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = m
	return mi


static func sphere(radius: float, m: Material, segs := 6, rings := 4) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = segs
	sm.rings = rings
	mi.mesh = sm
	mi.material_override = m
	return mi
