## Spelplanen sedd uppifrån (håll Tab): var varje kubb står, vilka som
## ligger, vilka som är dina numrerade kubbar och vad de bär.
class_name Board
extends Control

const SCALE := 33.0     # pixlar per meter
var items: Array = []   # [{pos: Vector2(x, z), fallen, kind, slot, side, king, col, rune_col}]
var opp_name := ""
var _t := 0.0


func _process(dt: float) -> void:
	if visible:
		_t += dt
		queue_redraw()


func _p(x: float, z: float) -> Vector2:
	# z = 0 (din baslinje) längst ner, z = -8 (hans) högst upp
	x = clampf(x, -2.8, 2.8)
	z = clampf(z, -8.15, 0.25)
	return Vector2(size.x * 0.5 + x * SCALE, 26 + (8.0 + z) * SCALE)


func _draw() -> void:
	var f := ThemeDB.fallback_font
	var tl := _p(-2.5, -8.0)
	var br := _p(2.5, 0.0)
	# gräs med ditherrutor
	for y in range(int(tl.y), int(br.y), 4):
		for x in range(int(tl.x), int(br.x), 4):
			var k := ((x / 4 + y / 4) % 2)
			draw_rect(Rect2(x, y, 4, 4), Color(0.10, 0.16, 0.08) if k == 0 else Color(0.12, 0.19, 0.09))
	var line := Color(0.85, 0.8, 0.7, 0.8)
	draw_rect(Rect2(tl, br - tl), line, false, 1.0)
	var mid := _p(-2.5, -4.0)
	for x in range(int(tl.x), int(br.x), 6):
		draw_line(Vector2(x, mid.y), Vector2(x + 3, mid.y), line, 1.0)
	draw_string(f, Vector2(tl.x, 10), opp_name, HORIZONTAL_ALIGNMENT_CENTER, br.x - tl.x, 8, Color(1.0, 0.45, 0.35))
	draw_string(f, Vector2(tl.x, br.y + 10), "DU" if Lang.current == "sv" else "YOU", HORIZONTAL_ALIGNMENT_CENTER, br.x - tl.x, 8, Color(0.6, 0.9, 1.0))
	for it in items:
		var p := _p(it.pos.x, it.pos.y)
		var col: Color = it.col
		if it.king:
			draw_rect(Rect2(p - Vector2(6, 6), Vector2(12, 12)), Color(0.05, 0, 0))
			draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), Color(0.9, 0.75, 0.4))
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(0.7, 0.1, 0.05))
			continue
		var sz := Vector2(13, 6) if it.fallen else Vector2(9, 9)
		var r := Rect2(p - sz * 0.5, sz)
		draw_rect(r.grow(1), Color(0.02, 0, 0.02))
		draw_rect(r, col.darkened(0.45) if it.fallen else col)
		if it.rune_col != Color(0, 0, 0, 0):
			draw_rect(r.grow(2), it.rune_col, false, 1.0)
		if it.slot >= 0:
			# dina numrerade kubbar pulserar lite
			var a := 0.6 + 0.4 * sin(_t * 4.0 + it.slot)
			draw_string(f, p + Vector2(-3, -7), str(it.slot + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.95, 0.6, a))
		if it.opp:
			draw_rect(r.grow(3), Color(1, 0.1, 0.05, 0.8), false, 1.0)
