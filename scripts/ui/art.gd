## Procedurell pixelart för korten och UI:t: ditherade bakgrunder,
## ramar med hörnprydnader och små ikoner per korttyp. Allt ritas pixel
## för pixel i en Image och visas med nearest-filter.
class_name Art
extends RefCounted

const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

static var _cache := {}


static func _bayer(x: int, y: int) -> float:
	return (BAYER[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0


## Färg kvantiserad till `levels` steg med ordnad dithering.
static func _dq(c: Color, x: int, y: int, levels := 6.0) -> Color:
	var t := _bayer(x, y) - 0.5
	return Color(
		clampf(floor(c.r * levels + t + 0.5) / levels, 0, 1),
		clampf(floor(c.g * levels + t + 0.5) / levels, 0, 1),
		clampf(floor(c.b * levels + t + 0.5) / levels, 0, 1), c.a)


static func _hash(x: int, y: int, s: int) -> float:
	var h := (x * 374761393 + y * 668265263 + s * 2147483647) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 1000) / 1000.0


static func _rect(img: Image, x0: int, y0: int, w: int, h: int, c: Color) -> void:
	for y in range(maxi(y0, 0), mini(y0 + h, img.get_height())):
		for x in range(maxi(x0, 0), mini(x0 + w, img.get_width())):
			img.set_pixel(x, y, c)


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


static func _line(img: Image, a: Vector2i, b: Vector2i, c: Color, thick := 1) -> void:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var p := Vector2(a).lerp(Vector2(b), float(i) / maxf(n, 1))
		_rect(img, int(p.x) - thick / 2, int(p.y) - thick / 2, thick, thick, c)


static func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


## Ramen: mörk ytterkant, ljus innerkant, hörnprydnader (små romber).
static func _frame(img: Image, col: Color, notch := true) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var dark := Color(0.03, 0.0, 0.02)
	var light := col.lightened(0.35)
	var mid := col.darkened(0.2)
	for x in w:
		for y in [0, h - 1]:
			_px(img, x, y, dark)
		for y in [1, h - 2]:
			_px(img, x, y, light if y == 1 else mid)
	for y in h:
		for x in [0, w - 1]:
			_px(img, x, y, dark)
		for x in [1, w - 2]:
			_px(img, x, y, light if x == 1 else mid)
	# skugga innanför
	for x in range(2, w - 2):
		_px(img, x, 2, img.get_pixel(x, 2).darkened(0.35))
	if not notch:
		return
	for c in [Vector2i(3, 3), Vector2i(w - 4, 3), Vector2i(3, h - 4), Vector2i(w - 4, h - 4)]:
		_px(img, c.x, c.y, light)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			_px(img, c.x + d.x, c.y + d.y, mid)
		_px(img, c.x + 1, c.y + 1, dark)
		_px(img, c.x - 1, c.y - 1, dark)
		_px(img, c.x + 1, c.y - 1, dark)
		_px(img, c.x - 1, c.y + 1, dark)


## Ditherad gradient med lite brus (som gammalt tryckt papper i mörker).
static func _bg(img: Image, top: Color, bottom: Color, seed: int, levels := 7.0) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		var k := float(y) / maxf(h - 1, 1)
		for x in w:
			var c := top.lerp(bottom, k)
			var n := _hash(x / 2, y / 2, seed) * 0.06 - 0.03
			c = Color(c.r + n, c.g + n, c.b + n)
			# vinjett mot kanterna
			var ex := absf(float(x) / w - 0.5) * 2.0
			c = c.darkened(pow(ex, 3.0) * 0.35)
			img.set_pixel(x, y, _dq(c, x, y, levels))


## Ett kort: ram, ditherad bakgrund, ikonruta och typ-band.
## kind: kubb, cursed, opp, baton, enh, ed, seal, fate, fate_bad, pinnkort
static func card(kind: String, col: Color, w: int, h: int, seed := 1) -> ImageTexture:
	var key := "card_%s_%s_%d_%d_%d" % [kind, col.to_html(), w, h, seed]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c := col.clamp(Color(0.12, 0.12, 0.12), Color(1, 1, 1))
	if kind == "cursed" or kind == "fate_bad":
		c = Color(0.7, 0.2, 0.85)
	elif kind == "opp":
		c = Color(0.85, 0.12, 0.1)
	_bg(img, c.darkened(0.55), Color(0.04, 0.0, 0.03), seed)
	# ikonruta högst upp
	var iw := mini(60, w - 16)
	var ih := 40
	var ix := (w - iw) / 2
	var iy := 6
	_rect(img, ix - 1, iy - 1, iw + 2, ih + 2, Color(0.02, 0.0, 0.02))
	for y in ih:
		for x in iw:
			var k := float(y) / ih
			var bc := Color(0.08, 0.04, 0.07).lerp(c.darkened(0.7), k)
			img.set_pixel(ix + x, iy + y, _dq(bc, x, y, 5.0))
	_rect(img, ix - 1, iy + ih + 1, iw + 2, 1, c.lightened(0.2))
	# ikonen ritas i halv upplösning och förstoras 2x: tjocka pixlar
	var ic := Image.create(iw / 2, ih / 2, false, Image.FORMAT_RGBA8)
	ic.fill(Color(0, 0, 0, 0))
	icon(ic, kind, c, Vector2i(iw / 4, ih / 4), seed)
	for y in ic.get_height():
		for x in ic.get_width():
			var p := ic.get_pixel(x, y)
			if p.a > 0.5:
				_rect(img, ix + x * 2, iy + y * 2, 2, 2, p)
	_frame(img, c)
	var t := _tex(img)
	_cache[key] = t
	return t


## Rita en ikon centrerad i o.
static func icon(img: Image, kind: String, c: Color, o: Vector2i, seed := 1) -> void:
	var dark := Color(0.03, 0.0, 0.02)
	var hi := c.lightened(0.5)
	match kind:
		"kubb", "cursed", "opp":
			# en kubb i trä med runband och skugga
			var wood := Color(0.62, 0.45, 0.28).lerp(c, 0.45)
			_rect(img, o.x - 5, o.y + 9, 12, 2, Color(0, 0, 0, 0.6))
			for y in range(-10, 9):
				for x in range(-5, 6):
					var shade := 1.0 - (x + 5) / 14.0
					var grain := 0.08 if (_hash(x, y / 3, seed) > 0.7) else 0.0
					var wc := wood.darkened(0.35 - shade * 0.35 + grain)
					_px(img, o.x + x, o.y + y, _dq(wc, x, y, 6.0))
			_rect(img, o.x - 5, o.y - 10, 11, 1, wood.lightened(0.3))
			var band := Color(1.0, 0.1, 0.05) if kind == "opp" else (Color(0.8, 0.2, 1.0) if kind == "cursed" else hi)
			_rect(img, o.x - 5, o.y + 3, 11, 2, band)
			_px(img, o.x - 1, o.y - 4, dark)
			_px(img, o.x + 2, o.y - 4, dark)
			if kind == "cursed" or kind == "opp":
				_line(img, Vector2i(o.x - 2, o.y - 1), Vector2i(o.x + 3, o.y - 1), dark)  # sur mun
			for y in range(-10, 9):
				_px(img, o.x - 6, o.y + y, dark)
				_px(img, o.x + 6, o.y + y, dark)
		"baton", "pinnkort":
			# en pinne snett över rutan med lindning och fart-streck
			var wood2 := Color(0.7, 0.5, 0.3).lerp(c, 0.5)
			_line(img, Vector2i(o.x - 13, o.y + 9), Vector2i(o.x + 13, o.y - 9), dark, 4)
			_line(img, Vector2i(o.x - 13, o.y + 8), Vector2i(o.x + 12, o.y - 9), wood2, 2)
			_line(img, Vector2i(o.x - 12, o.y + 7), Vector2i(o.x + 11, o.y - 9), wood2.lightened(0.3), 1)
			_line(img, Vector2i(o.x - 2, o.y + 2), Vector2i(o.x + 1, o.y - 1), hi, 3)
			if kind == "pinnkort":
				for i in 3:
					_line(img, Vector2i(o.x - 17 + i * 3, o.y + 2 + i * 3), Vector2i(o.x - 12 + i * 3, o.y + 2 + i * 3), hi.darkened(0.3))
		"enh":
			# slipad ädelsten
			for y in range(-9, 10):
				var half := 9 - absi(y)
				for x in range(-half, half + 1):
					var g := c.lightened(0.25 - (y + x) * 0.03)
					_px(img, o.x + x, o.y + y, _dq(g, x, y, 6.0))
			_line(img, Vector2i(o.x - 4, o.y - 4), Vector2i(o.x - 1, o.y - 7), Color(1, 1, 1))
			_px(img, o.x + 3, o.y - 1, Color(1, 1, 1))
			for y in range(-9, 10):
				var half2 := 9 - absi(y)
				_px(img, o.x - half2 - 1, o.y + y, dark)
				_px(img, o.x + half2 + 1, o.y + y, dark)
		"ed":
			# regnbågsskimrande stjärna
			for y in range(-10, 11):
				for x in range(-10, 11):
					var r := absf(x) + absf(y) * 0.45 if absi(x) > absi(y) else absf(y) + absf(x) * 0.45
					if r < 9.0:
						var hc := Color.from_hsv(fmod((x + y + 20) / 28.0 + seed * 0.1, 1.0), 0.6, 1.0)
						_px(img, o.x + x, o.y + y, _dq(hc.lerp(c, 0.3), x, y, 5.0))
			_px(img, o.x, o.y, Color(1, 1, 1))
		"seal":
			# vaxsigill med tryck
			for y in range(-9, 10):
				for x in range(-9, 10):
					var d := sqrt(x * x + y * y)
					if d < 8.5 + _hash(x, y, 7) * 1.2:
						var sc := c.darkened(0.15 + d * 0.03)
						_px(img, o.x + x, o.y + y, _dq(sc, x, y, 6.0))
			for a in 8:
				var ang := TAU * a / 8.0
				_px(img, o.x + int(cos(ang) * 5), o.y + int(sin(ang) * 5), c.lightened(0.4))
			_rect(img, o.x - 1, o.y - 1, 3, 3, c.lightened(0.5))
		"fate", "fate_bad":
			# ett öga som stirrar
			for x in range(-12, 13):
				var hh := int(6.0 * (1.0 - pow(x / 12.0, 2.0)))
				for y in range(-hh, hh + 1):
					_px(img, o.x + x, o.y + y, Color(0.92, 0.88, 0.8) if kind == "fate" else Color(0.75, 0.6, 0.7))
				_px(img, o.x + x, o.y - hh - 1, dark)
				_px(img, o.x + x, o.y + hh + 1, dark)
			for y in range(-5, 6):
				for x in range(-5, 6):
					if x * x + y * y < 26:
						_px(img, o.x + x, o.y + y, _dq(c.darkened(0.2), x, y, 5.0))
			_rect(img, o.x - 2, o.y - 2, 4, 4, dark)
			_px(img, o.x - 3, o.y - 3, Color(1, 1, 1))
			if kind == "fate_bad":
				for i in 4:
					_px(img, o.x - 6 + i * 4, o.y + 8 + (i % 2), Color(0.8, 0.0, 0.05))
		"charm":
			# nyckelring: en ring med en liten nyckel som dinglar
			var metal := Color(0.75, 0.72, 0.65)
			for a in 28:
				var ang := TAU * a / 28.0
				_px(img, o.x + int(cos(ang) * 7), o.y - 4 + int(sin(ang) * 7), metal.darkened(0.3 * sin(ang + 1.0)))
				_px(img, o.x + int(cos(ang) * 6), o.y - 4 + int(sin(ang) * 6), dark)
			_line(img, Vector2i(o.x + 2, o.y + 3), Vector2i(o.x + 5, o.y + 9), dark, 2)
			# varje berlock får en egen dingeltingest: kula, tand, ben, fjäder eller öga
			var cx := o.x + 6
			var cy := o.y + 11
			match absi(seed) % 5:
				0:
					for y in range(-3, 4):
						for x in range(-3, 4):
							if x * x + y * y <= 9:
								_px(img, cx + x, cy + y, _dq(c.lightened(0.15 - y * 0.05), x, y, 5.0))
					_px(img, cx - 1, cy - 1, Color(1, 1, 1))
				1:
					# tand
					var tc := Color(0.95, 0.92, 0.8)
					_rect(img, cx - 3, cy - 3, 7, 4, tc)
					_rect(img, cx - 3, cy + 1, 2, 3, tc)
					_rect(img, cx + 2, cy + 1, 2, 3, tc)
					_px(img, cx - 2, cy - 2, Color(1, 1, 1))
					_px(img, cx + 3, cy + 3, Color(0.6, 0.1, 0.05))
				2:
					# ben
					var bc := Color(0.9, 0.86, 0.75)
					_line(img, Vector2i(cx - 3, cy - 3), Vector2i(cx + 3, cy + 3), bc, 2)
					for p in [Vector2i(-4, -3), Vector2i(-3, -4), Vector2i(4, 3), Vector2i(3, 4)]:
						_rect(img, cx + p.x - 1, cy + p.y - 1, 2, 2, bc)
				3:
					# kråkfjäder
					_line(img, Vector2i(cx, cy - 4), Vector2i(cx + 1, cy + 5), dark, 1)
					for y in range(-3, 5):
						var hw := 2 - absi(y - 1) / 2
						for x in range(-hw, hw + 1):
							_px(img, cx + x, cy + y, _dq(c.darkened(0.5).lerp(Color(0.1, 0.1, 0.2), 0.5), x, y, 4.0))
				_:
					# glasöga
					for y in range(-3, 4):
						for x in range(-3, 4):
							if x * x + y * y <= 9:
								_px(img, cx + x, cy + y, Color(0.92, 0.9, 0.85))
					_rect(img, cx - 1, cy - 1, 2, 2, c.darkened(0.2))
					_px(img, cx, cy, dark)
			_line(img, Vector2i(o.x - 3, o.y + 3), Vector2i(o.x - 6, o.y + 11), c.darkened(0.3), 2)
			_rect(img, o.x - 8, o.y + 10, 3, 2, c.darkened(0.3))
		"def":
			# sköld med nitar
			for y in range(-9, 10):
				var half := 8 if y < 2 else 8 - (y - 1)
				for x in range(-half, half + 1):
					var g := c.darkened(0.1 + (x + 8) * 0.025)
					_px(img, o.x + x, o.y + y, _dq(g, x, y, 6.0))
				_px(img, o.x - half - 1, o.y + y, dark)
				_px(img, o.x + half + 1, o.y + y, dark)
			_rect(img, o.x - 1, o.y - 8, 2, 16, hi)
			for p in [Vector2i(-5, -6), Vector2i(5, -6), Vector2i(-5, 1), Vector2i(5, 1)]:
				_px(img, o.x + p.x, o.y + p.y, Color(1, 1, 0.8))
		"pack":
			# folieförpackning med rivkant och en kråka på
			for y in range(-11, 12):
				for x in range(-8, 9):
					var sh := Color.from_hsv(fmod((x - y + 30) / 40.0 + seed * 0.07, 1.0), 0.35, 1.0)
					_px(img, o.x + x, o.y + y, _dq(c.lerp(sh, 0.35).darkened(absf(x) * 0.02), x, y, 6.0))
			for x in range(-8, 9):
				_px(img, o.x + x, o.y - 11 + (x % 2), dark)
				_px(img, o.x + x, o.y + 11 - (x % 2), dark)
			_rect(img, o.x - 3, o.y - 2, 6, 4, dark)
			_px(img, o.x + 3, o.y - 1, Color(1, 0.8, 0.2))
			_line(img, Vector2i(o.x - 6, o.y + 1), Vector2i(o.x - 3, o.y - 1), dark)
			_line(img, Vector2i(o.x + 5, o.y + 1), Vector2i(o.x + 2, o.y - 1), dark)
		_:
			_rect(img, o.x - 4, o.y - 4, 8, 8, c)


## Pixelram som StyleBoxTexture (9-slice) för paneler och knappar.
static func frame_style(col: Color, fill: Color, size := 16, margin := 4) -> StyleBoxTexture:
	var key := "frame_%s_%s_%d" % [col.to_html(), fill.to_html(), size]
	var t: ImageTexture
	if _cache.has(key):
		t = _cache[key]
	else:
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		for y in size:
			for x in size:
				img.set_pixel(x, y, _dq(fill.lerp(fill.darkened(0.4), float(y) / size), x, y, 8.0))
		_frame(img, col, false)
		# små nitar i hörnen
		for c in [Vector2i(3, 3), Vector2i(size - 4, 3), Vector2i(3, size - 4), Vector2i(size - 4, size - 4)]:
			_px(img, c.x, c.y, col.lightened(0.5))
		t = _tex(img)
		_cache[key] = t
	var sb := StyleBoxTexture.new()
	sb.texture = t
	sb.texture_margin_left = 5
	sb.texture_margin_right = 5
	sb.texture_margin_top = 5
	sb.texture_margin_bottom = 5
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin
	sb.content_margin_bottom = margin
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return sb


## Kortet som StyleBoxTexture (sträcks inte: kortet ritas i rätt storlek).
static func card_style(kind: String, col: Color, w: int, h: int, seed := 1, margin_top := 50) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = card(kind, col, w, h, seed)
	sb.texture_margin_left = 6
	sb.texture_margin_right = 6
	sb.texture_margin_top = 50
	sb.texture_margin_bottom = 6
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = margin_top
	sb.content_margin_bottom = 5
	return sb
