## Allt som ritas ovanpå spelet: repliker, pinnar, kubbikoner,
## golf-kraftmätare, tips, popup-text, vinjett och toningar.
class_name Hud
extends CanvasLayer

const VIGNETTE := """
shader_type canvas_item;
void fragment() {
	float v = smoothstep(0.82, 0.32, length(UV - 0.5));
	float scan = mod(FRAGCOORD.y, 2.0) < 1.0 ? 0.88 : 1.0;
	COLOR = vec4(0.0, 0.0, 0.0, 1.0 - v * scan);
}
"""

var _play_root: Control
var _speech: Label
var _info: Label
var _icons: Label
var _hint: Label
var _center: Label
var _flash: Label
var _meter_root: Control
var _meter_fill: ColorRect
var _meter_peak: ColorRect
var _meter_label: Label
var _acc_root: Control
var _acc_cursor: ColorRect
var _acc_green: ColorRect
var _teeth: Label
var _cards: Label
var _phase: Label
var _banner: Label
var _toast: Label
var _fade: ColorRect
var _blood: ColorRect
var _death: Label
var _speech_tween: Tween
var _peak := 0.0
var _meter_hold := 0.0


var _sweet: ColorRect
var _last_teeth := -1
var _card_queue: Array = []
var _card_busy := false
var _deck_box: Label
var _sweet_at := -1.0


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = VIGNETTE
	var sm := ShaderMaterial.new()
	sm.shader = sh
	vig.material = sm
	add_child(vig)

	_play_root = Control.new()
	_play_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_play_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_play_root)
	_speech = _label(8, Color(0.95, 0.85, 0.75), Vector2(8, 6), Vector2(560, 40))
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD
	_info = _label(8, Color(0.9, 0.9, 0.8), Vector2(8, 292))
	_icons = _label(8, Color(0.95, 0.75, 0.5), Vector2(8, 280))
	_hint = _label(8, Color(0.75, 0.6, 0.6), Vector2(8, 330))
	_center = _label(12, Color(1.0, 0.3, 0.2), Vector2(0, 118), Vector2(640, 130))
	_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash = _label(14, Color(1.0, 0.85, 0.2), Vector2(0, 96), Vector2(640, 20))
	_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ver := _label(8, Color(0.8, 0.15, 0.1), Vector2(546, 349))
	ver.text = "SISTA KUBBEN v0.14"
	_teeth = _label(8, Color(1.0, 0.95, 0.75), Vector2(422, 40), Vector2(210, 10))
	_teeth.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cards = _label(8, Color(0.75, 0.7, 0.85), Vector2(422, 52), Vector2(210, 120))
	_cards.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_phase = _label(8, Color(1.0, 0.55, 0.3), Vector2(8, 266), Vector2(320, 10))
	_banner = _label(12, Color(1.0, 0.8, 0.6), Vector2(0, 80), Vector2(640, 90))
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD
	_banner.modulate.a = 0.0
	_build_score()
	_toast = _label(8, Color(0.6, 1.0, 0.6), Vector2(0, 200), Vector2(640, 12))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0

	# golf-kraftmätare: stapel med fyllning, söt punkt och toppmarkering
	_meter_root = Control.new()
	_meter_root.position = Vector2(504, 266)
	_play_root.add_child(_meter_root)
	var mf := Panel.new()
	mf.add_theme_stylebox_override("panel", Art.frame_style(Color(0.55, 0.15, 0.1), Color(0.05, 0.01, 0.02, 0.9), 16, 2))
	mf.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mf.position = Vector2(-3, -3)
	mf.size = Vector2(128, 30)
	mf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meter_root.add_child(mf)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.01, 0.02, 0.85)
	bg.size = Vector2(122, 12)
	_meter_root.add_child(bg)
	_meter_fill = ColorRect.new()
	_meter_fill.position = Vector2(1, 1)
	_meter_fill.size = Vector2(0, 10)
	_meter_fill.color = Color(0.85, 0.2, 0.1)
	_meter_root.add_child(_meter_fill)
	_sweet = ColorRect.new()
	var sx := 1.0 + 120.0 * ThrowController.SWEET_SPEED / ThrowController.MAX_SPEED
	_sweet.position = Vector2(sx - 8, 0)
	_sweet.size = Vector2(16, 12)
	_sweet.color = Color(0.3, 0.8, 0.3, 0.45)
	_meter_root.add_child(_sweet)
	_meter_peak = ColorRect.new()
	_meter_peak.size = Vector2(2, 14)
	_meter_peak.position = Vector2(1, -1)
	_meter_peak.color = Color(1, 0.95, 0.6)
	_meter_root.add_child(_meter_peak)
	_meter_label = _label(8, Color(0.9, 0.8, 0.7), Vector2(504, 254))

	# precisionsmätare för mätarläget: smal grön mitt, gula sidor, röda kanter
	_acc_root = Control.new()
	_acc_root.position = Vector2(504, 280)
	_play_root.add_child(_acc_root)
	for seg in [[0.0, 1.0, Color(0.55, 0.08, 0.05)], [0.075, 0.925, Color(0.75, 0.55, 0.15)], [0.3, 0.7, Color(0.6, 0.65, 0.2)], [0.41, 0.59, Color(0.25, 0.8, 0.3)]]:
		var r := ColorRect.new()
		r.position = Vector2(1 + 120.0 * seg[0], 1)
		r.size = Vector2(120.0 * (seg[1] - seg[0]), 6)
		r.color = seg[2]
		_acc_root.add_child(r)
		_acc_green = r
	_acc_cursor = ColorRect.new()
	_acc_cursor.size = Vector2(2, 10)
	_acc_cursor.position = Vector2(1, -1)
	_acc_cursor.color = Color(1, 1, 1)
	_acc_root.add_child(_acc_cursor)
	_acc_root.visible = false

	_blood = ColorRect.new()
	_blood.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blood.color = Color(0.45, 0.0, 0.02, 0.0)
	_blood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_blood)
	_death = Label.new()
	var dls := LabelSettings.new()
	dls.font_size = 24
	dls.font_color = Color(1.0, 0.85, 0.8)
	dls.shadow_color = Color(0, 0, 0, 1)
	dls.shadow_offset = Vector2(2, 2)
	_death.label_settings = dls
	_death.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death.position = Vector2(0, 100)
	_death.size = Vector2(640, 170)
	_death.modulate.a = 0.0
	add_child(_death)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _label(size: int, color: Color, pos: Vector2, sz := Vector2.ZERO) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.shadow_color = Color(0, 0, 0, 0.9)
	ls.shadow_offset = Vector2(1, 1)
	l.label_settings = ls
	l.position = pos
	if sz != Vector2.ZERO:
		l.size = sz
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_root.add_child(l)
	return l


func set_playing(on: bool) -> void:
	_play_root.visible = on


func fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.35)
	await tw.finished


func fade_in() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.6)


func refresh(i: Dictionary) -> void:
	var lines: Array[String] = []
	if i.training:
		lines.append(Lang.t("training_hud") % i.dog_hits)
		_icons.text = ""
		_phase.text = ""
		_teeth.text = ""
		_cards.text = ""
		_score_root.visible = false
	else:
		_score_root.visible = Run.active
		lines.append(Lang.t("hud") % [i.left, i.total])
		_icons.text = Lang.t("kubbs_line") % [i.theirs, i.theirs_field, i.mine, i.mine_field]
		var ph := ""
		match i.phase:
			0: ph = Lang.t("phase_toss_you") if i.toss else Lang.t("phase_you")
			1: ph = Lang.t("phase_opp_toss") % i.opp
			2: ph = Lang.t("phase_opp") % i.opp + ("   %d/%d" % [i.opp_left, i.opp_total] if i.get("opp_total", 0) > 0 else "")
			3: ph = Lang.t("phase_toss_you")
		_phase.text = ph
		if Run.active:
			_teeth.text = Lang.t("teeth_hud") % [Run.teeth, Run.night, Run.nights_text()]
			var names: Array[String] = []
			for si in Run.cards.size():
				var rt := Run.runes_text(si)
				if Run.cards[si] != "" or rt != "":
					names.append("%d %s%s" % [si + 1, Cards.title(Run.cards[si]) if Run.cards[si] != "" else "", (" [" + rt + "]") if rt != "" else ""])
			if not Run.hand.is_empty():
				var hn: Array[String] = []
				for h in Run.hand:
					hn.append(Cards.title(h))
				names.append(("HAND: " if Lang.current == "sv" else "HAND: ") + ", ".join(hn))
			if Run.borrowed != "":
				names.append("~ " + Cards.title(Run.borrowed))
			for t in Run.temp_names:
				names.append("+ " + t)
			_cards.text = "\n".join(names)
			if Run.teeth != _last_teeth:
				if _last_teeth >= 0:
					_teeth.pivot_offset = Vector2(210, 5)
					_teeth.scale = Vector2.ONE * 1.5
					var tw := create_tween()
					tw.tween_property(_teeth, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
				_last_teeth = Run.teeth
		else:
			_teeth.text = ""
			_cards.text = ""
	if not i.last.is_empty():
		lines.append(Lang.t("last") % [i.last.speed, int(i.last.angle), i.last_dist])
	_info.text = "\n".join(lines)
	_hint.visible = Settings.show_hints
	if Settings.throw_mode == "meter":
		_hint.text = Lang.t("hint_meter1") + "\n" + Lang.t("hint_meter2") + "  " + Lang.t("hint3")
	else:
		_hint.text = Lang.t("hint1") + " " + Lang.t("hint2") + "\n" + Lang.t("hint3")
	_meter_root.visible = Settings.power_meter
	_meter_label.visible = Settings.power_meter


func banner(text: String) -> void:
	_banner.text = text
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.4)
	tw.tween_interval(3.0)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.8)


func toast(text: String) -> void:
	_toast.text = text
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.5)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.6)


func teeth_popup(text: String) -> void:
	var l := _label(8, Color(1.0, 0.95, 0.6), Vector2(492, 30), Vector2(140, 10))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.text = text
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", 18.0, 1.6)
	tw.tween_property(l, "modulate:a", 0.0, 1.6).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)


func update_meter(v: float, holding: bool, angle_deg: float) -> void:
	if holding:
		_peak = maxf(_peak, v)
		_meter_hold = 0.0
		_meter_label.text = Lang.t("meter") % int(angle_deg)
	else:
		_meter_hold += get_process_delta_time()
		if _meter_hold > 2.0:
			_peak = 0.0
			_meter_label.text = Lang.t("meter_idle")
	_meter_fill.size.x = 120.0 * (v if holding else _peak)
	_meter_peak.position.x = 1.0 + 120.0 * _peak
	var sweet := ThrowController.SWEET_SPEED / ThrowController.MAX_SPEED
	var d := absf((v if holding else _peak) - sweet)
	_meter_fill.color = Color(0.3, 0.85, 0.3) if d < 0.07 else (Color(0.9, 0.7, 0.2) if d < 0.14 else Color(0.85, 0.2, 0.1))


## Mätarläget: fas 1 = kraft fylls, fas 2 = markören sveper.
func update_timing(phase: int, live: float, locked: float, cursor: float, perfect := 0.18, sweet01 := -1.0, dist := -1.0) -> void:
	_meter_root.visible = true
	if sweet01 > 0.0:
		_sweet_at = lerpf(_sweet_at if _sweet_at > 0.0 else sweet01, sweet01, 0.2)
		_sweet.position.x = 1.0 + 120.0 * _sweet_at - 8.0
	_acc_green.position.x = 1.0 + 60.0 * (1.0 - perfect)
	_acc_green.size.x = 120.0 * perfect
	_acc_root.visible = phase == 2 or _meter_hold < 1.5
	if phase == 1:
		_meter_hold = 0.0
		_peak = live
		_meter_label.text = Lang.t("meter_idle") + ("   %.1f m" % dist if dist >= 0.0 else "")
	elif phase == 2:
		_meter_hold = 0.0
		_peak = locked
		_acc_cursor.position.x = 1.0 + 120.0 * clampf((cursor + 1.0) * 0.5, 0.0, 1.0)
		_meter_label.text = Lang.t("meter_acc")
	else:
		_meter_hold += get_process_delta_time()
		if _meter_hold > 2.0:
			_peak = 0.0
			_meter_label.text = Lang.t("meter_idle")
			_acc_root.visible = false
	_meter_fill.size.x = 120.0 * _peak
	_meter_peak.position.x = 1.0 + 120.0 * _peak
	var sweet := _sweet_at if _sweet_at > 0.0 else ThrowController.SWEET_SPEED / ThrowController.MAX_SPEED
	var d := absf(_peak - sweet)
	_meter_fill.color = Color(0.3, 0.85, 0.3) if d < 0.07 else (Color(0.9, 0.7, 0.2) if d < 0.14 else Color(0.85, 0.2, 0.1))


func show_throw(v: float) -> void:
	_peak = v
	_meter_hold = 0.0


func speech(who: String, text: String) -> void:
	_speech.text = who + ": " + text
	_speech.visible_ratio = 0.0
	if _speech_tween:
		_speech_tween.kill()
	_speech_tween = create_tween()
	_speech_tween.tween_property(_speech, "visible_ratio", 1.0, 0.025 * _speech.text.length())


func center(text: String) -> void:
	_center.text = text


func flash(text: String) -> void:
	_flash.text = text
	_flash.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(_flash, "modulate:a", 0.0, 0.5)


func popup(at: Vector2, text: String) -> void:
	var l := _label(12, Color(1.0, 0.9, 0.3), at - Vector2(20, 10))
	l.text = text
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 24, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9)
	tw.chain().tween_callback(l.queue_free)


## Du träffade kungen. Skärmen blöder långsamt rött, inga hoppskräck.
func death(title: String, sub: String) -> void:
	_death.text = title + "\n\n" + sub
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_blood, "color:a", 0.65, 1.6)
	tw.tween_property(_death, "modulate:a", 1.0, 1.2).set_delay(0.8)


func clear_death() -> void:
	_blood.color.a = 0.0
	_death.modulate.a = 0.0


## Ödeskortet glider in från höger, vänds och glider ut igen.
func fate_card(title: String, desc: String, col: Color) -> void:
	_card_queue.append([title, desc, col])
	if not _card_busy:
		_show_cards()


func _show_cards() -> void:
	_card_busy = true
	while not _card_queue.is_empty():
		var c: Array = _card_queue.pop_front()
		var pc := PanelContainer.new()
		var st := Art.frame_style((c[2] as Color).clamp(Color(0.25, 0.25, 0.25), Color(1, 1, 1)), Color(0.06, 0.02, 0.04, 0.96), 16, 6)
		pc.add_theme_stylebox_override("panel", st)
		pc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pc.custom_minimum_size = Vector2(140, 0)
		pc.size = Vector2(140, 60)
		pc.position = Vector2(648, 176)
		pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 1)
		pc.add_child(v)
		v.add_child(_mk(6, Color(0.7, 0.6, 0.5), "ÖDESKORT" if Lang.current == "sv" else "FATE CARD"))
		v.add_child(_mk(8, (c[2] as Color).lightened(0.3), c[0]))
		var d := _mk(7, Color(0.9, 0.85, 0.8), c[1])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD
		d.custom_minimum_size = Vector2(132, 0)
		v.add_child(d)
		_play_root.add_child(pc)
		pc.pivot_offset = Vector2(70, 30)
		pc.scale = Vector2(0.05, 1.0)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(pc, "position:x", 494.0, 0.3).set_trans(Tween.TRANS_BACK)
		tw.tween_property(pc, "scale:x", 1.0, 0.35).set_delay(0.1)
		tw.chain().tween_interval(2.6)
		tw.chain().tween_property(pc, "position:x", 648.0, 0.3)
		await tw.finished
		pc.queue_free()
	_card_busy = false


func _mk(size: int, color: Color, text: String) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.shadow_color = Color(0, 0, 0, 0.9)
	ls.shadow_offset = Vector2(1, 1)
	l.label_settings = ls
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Håll Tab (eller Back på handkontrollen) för att se din lek.
var _board: Board
var _board_bg: Panel


func show_deck(on: bool, his: Array = [], board: Array = [], opp_name := "") -> void:
	if _board == null:
		_board_bg = Panel.new()
		_board_bg.add_theme_stylebox_override("panel", Art.frame_style(Color(0.6, 0.15, 0.1), Color(0.03, 0.0, 0.02, 0.94), 16, 4))
		_board_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_board_bg.position = Vector2(14, 34)
		_board_bg.size = Vector2(200, 322)
		_board_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_play_root.add_child(_board_bg)
		_board = Board.new()
		_board.position = Vector2(4, 8)
		_board.size = Vector2(192, 308)
		_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_board_bg.add_child(_board)
	_board_bg.visible = on
	if on:
		_board.items = board
		_board.opp_name = opp_name
		_play_root.move_child(_board_bg, -1)
	if _deck_box == null:
		_deck_box = _label(8, Color(0.95, 0.9, 0.8), Vector2(234, 44), Vector2(392, 300))
		_deck_box.autowrap_mode = TextServer.AUTOWRAP_WORD
		var bg := Panel.new()
		bg.add_theme_stylebox_override("panel", Art.frame_style(Color(0.6, 0.15, 0.1), Color(0.03, 0.0, 0.02, 0.92), 16, 4))
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.show_behind_parent = true
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.offset_left = -6
		bg.offset_top = -6
		bg.offset_right = 6
		bg.offset_bottom = 6
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_deck_box.add_child(bg)
	_deck_box.visible = on
	if not on:
		return
	_play_root.move_child(_deck_box, -1)
	var sv := Lang.current == "sv"
	var lines: Array[String] = []
	lines.append(("PINNE: " if sv else "BATON: ") + Cards.title(Run.cur_baton()) + " - " + Cards.desc(Run.cur_baton()))
	lines.append("DINA KUBBAR (vänster till höger):" if sv else "YOUR KUBBS (left to right):")
	for i in Run.cards.size():
		var id: String = Run.cards[i]
		lines.append("  %d " % (i + 1) + ((Cards.title(id) + ": " + Cards.desc(id)) if id != "" else ("vanlig kubb" if sv else "plain kubb")))
		for r in [Run.enh[i], Run.ed[i], Run.seal[i]]:
			if r != "":
				lines.append("      * " + Cards.rune_title(r) + ": " + Cards.rune_desc(r))
		if Run.grow_chips[i] > 0 or Run.grow_mult[i] > 0:
			lines.append(("      vuxit: +%d marker, +%d multi" if sv else "      grown: +%d chips, +%d mult") % [Run.grow_chips[i], Run.grow_mult[i]])
	if not Run.temp_names.is_empty():
		lines.append(("DENNA MATCH: " if sv else "THIS MATCH: ") + ", ".join(Run.temp_names))
	for id in his:
		lines.append(("  HANS " if sv else "  HIS ") + Cards.title(id) + ": " + Cards.desc(id))
	lines.append(("Kungens nåd kvar: %d" if sv else "King's mercy left: %d") % Run.king_shield_left)
	if not Run.hand.is_empty():
		var hn: Array[String] = []
		for h in Run.hand:
			hn.append(Cards.title(h))
		lines.append(("PINNKORT I HANDEN: " if sv else "BATON CARDS IN HAND: ") + ", ".join(hn))
	_deck_box.text = "\n".join(lines)


signal fate_chosen(index: int)
var _choice_root: Control


## Två ödeskort i mitten av skärmen. Klicka på ett, eller tryck 1 / 2.
func choose_fate(a: Array, b: Array) -> int:
	return await choose_cards([a, b], "ÖDET ERBJUDER. VÄLJ ETT." if Lang.current == "sv" else "FATE OFFERS. CHOOSE ONE.")


var _choice_n := 2


## 2-3 kort i mitten. view = [titel, text, färg, (typ)]. Klicka eller 1/2/3.
func choose_cards(opts: Array, header: String) -> int:
	_choice_n = opts.size()
	_choice_root = Control.new()
	_choice_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_play_root.add_child(_choice_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.0, 0.02, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_root.add_child(dim)
	var head := _mk(12, Color(1.0, 0.85, 0.5), header)
	head.position = Vector2(0, 62)
	head.size = Vector2(640, 16)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_root.add_child(head)
	var w := 180.0 if opts.size() <= 2 else 168.0
	var gap := 20.0 if opts.size() <= 2 else 12.0
	var x0 := (640.0 - (w * opts.size() + gap * (opts.size() - 1))) * 0.5
	for i in opts.size():
		var c: Array = opts[i]
		var btn := Button.new()
		btn.position = Vector2(x0 + i * (w + gap), 90)
		btn.size = Vector2(w, 150)
		btn.focus_mode = Control.FOCUS_ALL
		var kind: String = c[4] if c.size() > 4 else "fate"
		var cc := (c[2] as Color).clamp(Color(0.2, 0.2, 0.2), Color(1, 1, 1))
		var st := Art.card_style(kind, cc, int(w), 150, i * 7 + 3)
		var sth := Art.card_style(kind, cc.lightened(0.3), int(w), 150, i * 7 + 3)
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", sth)
		btn.add_theme_stylebox_override("focus", sth)
		btn.add_theme_stylebox_override("pressed", sth)
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		btn.mouse_entered.connect(func(): btn.grab_focus())
		btn.focus_entered.connect(func():
			Sfx.play("click", -12.0, 1.8)
			var tw2 := btn.create_tween()
			tw2.tween_property(btn, "position:y", 84.0, 0.08))
		btn.focus_exited.connect(func():
			var tw2 := btn.create_tween()
			tw2.tween_property(btn, "position:y", 90.0, 0.08))
		var v := VBoxContainer.new()
		v.position = Vector2(7, 49)
		v.size = Vector2(w - 14, 96)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(v)
		v.add_child(_mk(7, (c[2] as Color).lightened(0.2), "%d  %s" % [i + 1, c[3] if c.size() > 3 else ""]))
		var t := _mk(10, (c[2] as Color).lightened(0.3), c[0])
		t.autowrap_mode = TextServer.AUTOWRAP_WORD
		t.custom_minimum_size = Vector2(w - 14, 0)
		v.add_child(t)
		var d := _mk(7 if opts.size() > 2 else 8, Color(0.9, 0.85, 0.8), c[1])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD
		d.custom_minimum_size = Vector2(w - 14, 0)
		v.add_child(d)
		var idx := i
		btn.pressed.connect(func(): fate_chosen.emit(idx))
		_choice_root.add_child(btn)
		btn.pivot_offset = btn.size * 0.5
		btn.scale = Vector2(0.05, 1)
		var tw := create_tween()
		tw.tween_interval(0.1 * i)
		tw.tween_property(btn, "scale:x", 1.0, 0.25).set_trans(Tween.TRANS_BACK)
		if i == 0:
			btn.call_deferred("grab_focus")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var r: int = await fate_chosen
	Sfx.play("click", -4.0, 1.2)
	_choice_root.queue_free()
	_choice_root = null
	return r


func _unhandled_key_input(e: InputEvent) -> void:
	if _choice_root and e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_1:
			fate_chosen.emit(0)
			get_viewport().set_input_as_handled()
		elif e.keycode == KEY_2:
			fate_chosen.emit(1)
			get_viewport().set_input_as_handled()
		elif e.keycode == KEY_3 and _choice_n >= 3:
			fate_chosen.emit(2)
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- poäng

var _score_root: Control
var _score_lbl: Label
var _goal_lbl: Label
var _bar_bg: ColorRect
var _bar: ColorRect
var _tally_root: Control
var _chips_lbl: Label
var _mult_lbl: Label
var _total_lbl: Label
var _fast_lbl: Label
var _score := 0
var _shown := 0.0
var _goal := 1
var _tick_t := 0.0
var _tally_tw: Tween


func _box(col: Color, pos: Vector2, sz: Vector2, parent: Control, r: ColorRect = null) -> Label:
	if r == null:
		r = ColorRect.new()
	r.color = col
	r.position = pos
	r.size = sz
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	r.pivot_offset = sz * 0.5
	var fr := Panel.new()
	fr.add_theme_stylebox_override("panel", Art.frame_style(col.lightened(0.45), col, 16, 2))
	fr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fr.size = sz
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.color = Color(0, 0, 0, 0)
	r.add_child(fr)
	var l := _mk(14, Color(1, 1, 1), "0")
	l.size = sz
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.pivot_offset = sz * 0.5
	r.add_child(l)
	return l


func _build_score() -> void:
	# Balatro-panel till vänster: månens krav, poäng och stora marker x multi
	_score_root = Control.new()
	_score_root.position = Vector2(6, 52)
	_score_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_root.add_child(_score_root)
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", Art.frame_style(Color(0.6, 0.12, 0.08), Color(0.06, 0.01, 0.03, 0.9), 16, 4))
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.position = Vector2(-3, -3)
	panel.size = Vector2(132, 100)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_root.add_child(panel)
	_goal_lbl = _mk(7, Color(0.85, 0.5, 0.45), "")
	_goal_lbl.position = Vector2(4, 2)
	_score_root.add_child(_goal_lbl)
	_goal_big = _mk(14, Color(1.0, 0.22, 0.15), "0")
	_goal_big.position = Vector2(4, 10)
	_score_root.add_child(_goal_big)
	_score_lbl = _mk(12, Color(1.0, 0.9, 0.55), "0")
	_score_lbl.position = Vector2(4, 28)
	_score_lbl.pivot_offset = Vector2(0, 8)
	_score_root.add_child(_score_lbl)
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.15, 0.02, 0.03, 0.9)
	_bar_bg.position = Vector2(4, 44)
	_bar_bg.size = Vector2(118, 3)
	_score_root.add_child(_bar_bg)
	_bar = ColorRect.new()
	_bar.position = Vector2(4, 44)
	_bar.size = Vector2(0, 3)
	_score_root.add_child(_bar)
	_tally_root = Control.new()
	_tally_root.position = Vector2(4, 52)
	_score_root.add_child(_tally_root)
	_chips_box = ColorRect.new()
	_mult_box = ColorRect.new()
	_chips_lbl = _box(Color(0.12, 0.38, 0.95, 1.0), Vector2(0, 0), Vector2(52, 22), _tally_root, _chips_box)
	var x := _mk(14, Color(1, 0.3, 0.25), "X")
	x.position = Vector2(54, 2)
	_tally_root.add_child(x)
	_mult_lbl = _box(Color(0.95, 0.15, 0.1, 1.0), Vector2(66, 0), Vector2(52, 22), _tally_root, _mult_box)
	_total_lbl = _mk(10, Color(1.0, 0.95, 0.6), "")
	_total_lbl.position = Vector2(0, 24)
	_total_lbl.size = Vector2(118, 12)
	_total_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_total_lbl.pivot_offset = Vector2(59, 6)
	_tally_root.add_child(_total_lbl)
	_flames = Control.new()
	_flames.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tally_root.add_child(_flames)
	_chips_lbl.text = "0"
	_mult_lbl.text = "0"
	_fast_lbl = _label(10, Color(1.0, 0.6, 0.3), Vector2(568, 238))
	_fast_lbl.text = ">> x3"
	_fast_lbl.visible = false


var _goal_big: Label
var _chips_box: ColorRect
var _mult_box: ColorRect
var _flames: Control
var _chips_v := 0
var _mult_v := 0.0
var _heat := 0.0
var _flame_t := 0.0


func set_score(v: int, goal: int, instant := false) -> void:
	_score = v
	_goal = maxi(goal, 1)
	if instant:
		_shown = v
	_goal_lbl.text = "BLODMÅNEN KRÄVER" if Lang.current == "sv" else "THE BLOOD MOON DEMANDS"
	_goal_big.text = _fmt(_goal)
	_pulse(_goal_big, 1.3)


func _fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = " " + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


func _pulse(l: Label, k := 1.4) -> void:
	l.scale = Vector2.ONE * k
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


## Marker x multi under räkningen.
func tally(chips: int, mult: float, reset := false) -> void:
	if _tally_tw:
		_tally_tw.kill()
	if reset:
		_total_lbl.text = ""
	_chips_v = chips
	_mult_v = mult
	_heat = maxf(_heat, clampf(log(maxf(chips * mult, 1.0)) / log(10.0) - 1.0, 0.0, 4.0))
	var ct := _fmt(chips)
	var mt := str(snappedf(mult, 0.1)) if mult < 100.0 else _fmt(int(mult))
	if _chips_lbl.text != ct:
		_chips_lbl.text = ct
		_pulse(_chips_lbl, 1.7)
		_jolt(_chips_box)
	if _mult_lbl.text != mt:
		_mult_lbl.text = mt
		_pulse(_mult_lbl, 1.7)
		_jolt(_mult_box)


func _jolt(r: ColorRect) -> void:
	r.scale = Vector2(1.18, 1.25)
	r.rotation = randf_range(-0.12, 0.12)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(r, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	tw.tween_property(r, "rotation", 0.0, 0.2)


func tally_total(total: int) -> void:
	_total_lbl.text = "= " + _fmt(total)
	_pulse(_total_lbl, 2.0)
	_heat = maxf(_heat, clampf(log(maxf(total, 1.0)) / log(10.0) - 1.0, 0.0, 4.0) + 0.5)
	# efter en stund nollas rutorna igen, som i Balatro
	_tally_tw = create_tween()
	_tally_tw.tween_interval(1.8)
	_tally_tw.tween_callback(func():
		_chips_lbl.text = "0"
		_mult_lbl.text = "0"
		_total_lbl.text = "")


## Flytande siffra i valfri färg.
func popup_col(at: Vector2, text: String, col: Color, size := 10) -> void:
	var l := _label(size, col, at - Vector2(text.length() * size * 0.25, 8))
	l.text = text
	l.pivot_offset = Vector2(text.length() * size * 0.25, 6)
	l.scale = Vector2.ONE * 1.6
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
	tw.tween_property(l, "position:y", l.position.y - 20, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.55)
	tw.chain().tween_callback(l.queue_free)


## Stor text som skakar in mitt på skärmen.
func big(text: String, col: Color) -> void:
	var wait := 0.7 * _big_n
	_big_n += 1
	var l := _label(14, col, Vector2(0, 150), Vector2(640, 20))
	l.modulate.a = 0.0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.text = text
	l.pivot_offset = Vector2(320, 10)
	l.scale = Vector2.ONE * 1.8
	l.rotation = randf_range(-0.15, 0.15)
	var tw := create_tween()
	tw.tween_interval(wait)
	tw.tween_callback(func():
		l.modulate.a = 1.0
		Sfx.play("clack2", -6.0, 0.6))
	tw.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(l, "rotation", 0.0, 0.25)
	tw.tween_interval(0.5)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		_big_n -= 1
		l.queue_free())


var _big_n := 0


func fast(on: bool) -> void:
	if _fast_lbl:
		_fast_lbl.visible = on


func _process(dt: float) -> void:
	if _score_lbl == null:
		return
	if absf(_shown - _score) > 0.5:
		var step := maxf(absf(_score - _shown) * dt * 5.0, 1.0)
		_shown = move_toward(_shown, _score, step)
		_tick_t -= dt
		if _tick_t <= 0.0:
			_tick_t = 0.045
			Sfx.play("click", -14.0, 1.6 + randf() * 0.3)
			_score_lbl.scale = Vector2.ONE * 1.15
	else:
		_shown = _score
	_score_lbl.scale = _score_lbl.scale.lerp(Vector2.ONE, clampf(dt * 10.0, 0.0, 1.0))
	_score_lbl.text = ("POÄNG " if Lang.current == "sv" else "SCORE ") + _fmt(int(_shown))
	# eld ur rutorna när siffrorna är stora
	_heat = move_toward(_heat, 0.0, dt * 0.6)
	if _heat > 0.15 and _flames.is_visible_in_tree():
		_flame_t -= dt
		if _flame_t <= 0.0:
			_flame_t = 0.03 / clampf(_heat, 0.3, 4.0)
			for bi in 2:
				var box := _chips_box if bi == 0 else _mult_box
				var fr := ColorRect.new()
				var sz := randf_range(2.0, 3.0 + _heat * 1.5)
				fr.size = Vector2(sz, sz)
				fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var hot := randf()
				fr.color = (Color(0.4, 0.75, 1.0) if bi == 0 else Color(1.0, 0.55, 0.15)).lerp(Color(1, 1, 0.8), hot * 0.5)
				fr.position = box.position + Vector2(randf_range(0, 52 - sz), randf_range(-2, 6))
				_flames.add_child(fr)
				var tw := fr.create_tween().set_parallel(true)
				var life := randf_range(0.35, 0.6 + _heat * 0.12)
				tw.tween_property(fr, "position:y", fr.position.y - randf_range(8, 14 + _heat * 6), life)
				tw.tween_property(fr, "position:x", fr.position.x + randf_range(-3, 3), life)
				tw.tween_property(fr, "size", Vector2.ONE, life)
				tw.tween_property(fr, "modulate:a", 0.0, life)
				tw.chain().tween_callback(fr.queue_free)
	var f := clampf(_shown / float(_goal), 0.0, 1.0)
	_bar.size.x = 110.0 * f
	_bar.color = Color(0.85, 0.1, 0.08).lerp(Color(1.0, 0.8, 0.2), f)
