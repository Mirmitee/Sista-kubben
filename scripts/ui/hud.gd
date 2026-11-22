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
var _deck_bg: Panel
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
	# LAYOUT (640x360), fasta zoner så att inget överlappar:
	#   vänster 6-156: poängpanel uppe, info-panel nere
	#   mitten 162-478: repliker överst, banner/flash/stora texter i mitten, notiser nere
	#   höger 484-634: tänder och kortlista uppe, ödeskort i mitten, mätare nere
	#   botten 334-358: tipsraden
	_speech_box = _panel_box(Vector2(162, 4), 316, Color(0.45, 0.12, 0.08))
	_speech = _mk(8, Color(0.95, 0.85, 0.75), "")
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD
	_speech.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_speech.custom_minimum_size = Vector2(304, 0)
	_speech_box.add_child(_speech)
	_speech_box.visible = false
	_info_box = _panel_box(Vector2(6, 262), 206, Color(0.4, 0.1, 0.08))
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 0)
	iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_box.add_child(iv)
	_phase = _mk(8, Color(1.0, 0.55, 0.3), "")
	_icons = _mk(8, Color(0.95, 0.75, 0.5), "")
	_info = _mk(8, Color(0.9, 0.9, 0.8), "")
	for l in [_phase, _icons, _info]:
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.custom_minimum_size = Vector2(194, 0)
		iv.add_child(l)
	var strip := ColorRect.new()
	strip.color = Color(0.02, 0.0, 0.01, 0.72)
	strip.position = Vector2(0, 345)
	strip.size = Vector2(640, 15)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_root.add_child(strip)
	_hint_strip = strip
	_hint = _label(7, Color(0.78, 0.66, 0.62), Vector2(8, 346), Vector2(624, 13))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.clip_text = true
	_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_center = _label(12, Color(1.0, 0.3, 0.2), Vector2(162, 120), Vector2(316, 110))
	_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center.autowrap_mode = TextServer.AUTOWRAP_WORD
	_flash = _label(13, Color(1.0, 0.85, 0.2), Vector2(162, 158), Vector2(316, 20))
	_flash.autowrap_mode = TextServer.AUTOWRAP_WORD
	_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_teeth = _label(9, Color(1.0, 0.95, 0.75), Vector2(484, 4), Vector2(150, 12))
	_teeth.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cards_box = _panel_box(Vector2(484, 18), 150, Color(0.35, 0.15, 0.3))
	_cards = _mk(7, Color(0.8, 0.75, 0.9), "")
	_cards.custom_minimum_size = Vector2(140, 0)
	_cards.autowrap_mode = TextServer.AUTOWRAP_OFF
	_cards.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_cards.clip_text = true
	_cards_box.add_child(_cards)
	_banner_box = _panel_box(Vector2(162, 56), 316, Color(0.6, 0.15, 0.08))
	_banner = _mk(11, Color(1.0, 0.8, 0.6), "")
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD
	_banner.custom_minimum_size = Vector2(304, 0)
	_banner_box.add_child(_banner)
	_banner_box.modulate.a = 0.0
	_build_score()
	_toast = _label(8, Color(0.6, 1.0, 0.6), Vector2(218, 326), Vector2(280, 14))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	dls.font_size = Settings.fs(24)
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


var _speech_box: PanelContainer
var _info_box: PanelContainer
var _cards_box: PanelContainer
var _banner_box: PanelContainer
var _hint_strip: ColorRect
var _speech_t := 0.0


## Lägsta y under replikrutan (om den syns), så att rutor i mitten inte krockar.
func _below_speech(y: float) -> float:
	if _speech_box.visible:
		return maxf(y, _speech_box.position.y + _speech_box.get_combined_minimum_size().y + 4.0)
	return y


## En pixelram som växer med innehållet (PanelContainer), placerad i en zon.
func _panel_box(pos: Vector2, w: float, edge: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var st := Art.frame_style(edge, Color(0.03, 0.0, 0.02, 0.82), 16, 3)
	st.content_margin_left = 6
	st.content_margin_right = 6
	st.content_margin_top = 3
	st.content_margin_bottom = 3
	pc.add_theme_stylebox_override("panel", st)
	pc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pc.position = pos
	pc.custom_minimum_size = Vector2(w, 0)
	pc.size = Vector2(w, 0)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_root.add_child(pc)
	return pc


func _label(size: int, color: Color, pos: Vector2, sz := Vector2.ZERO) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font_size = Settings.fs(size)
	ls.font_color = color
	ls.outline_size = 2 if ls.font_size <= 12 else 3  # tunn kontur på liten text, annars äter den bokstäverna
	ls.outline_color = Color(0.02, 0.0, 0.01, 0.95)
	ls.shadow_color = Color(0, 0, 0, 0.6)
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
					# bara namnet och antal runor (som prickar), hela texten finns i Tab-vyn
					var nr := 0
					for r in [Run.enh[si], Run.ed[si], Run.seal[si]]:
						if r != "":
							nr += 1
					var nm := Cards.title(Run.cards[si]) if Run.cards[si] != "" else ("vanlig" if Lang.current == "sv" else "plain")
					names.append("%d %s%s" % [si + 1, nm, (" " + "•".repeat(nr)) if nr > 0 else ""])
			if not Run.hand.is_empty():
				var hn: Array[String] = []
				for h in Run.hand:
					hn.append(Cards.title(h))
				names.append(("HAND: " if Lang.current == "sv" else "HAND: ") + ", ".join(hn))
			if Run.borrowed != "":
				names.append("~ " + Cards.title(Run.borrowed))
			if Run.night_mod != "stilla":
				names.append("* " + Cards.night_title(Run.night_mod).to_upper())
			if not Run.keyring.is_empty():
				var kn: Array[String] = []
				for c in Run.keyring:
					kn.append(Cards.charm_title(c))
				for kname in kn:
					names.append("o " + kname)
			for t in Run.temp_names:
				names.append("+ " + t)
			var pt := Run.power_tier()
			if pt > 0:
				names.insert(0, ("MAKT %s" if Lang.current == "sv" else "POWER %s") % Run.roman(pt))
			_cards.text = "\n".join(names)
			if Run.teeth != _last_teeth:
				if _last_teeth >= 0:
					_teeth.pivot_offset = Vector2(150, 6)
					_teeth.scale = Vector2.ONE * 1.25
					var tw := create_tween()
					tw.tween_property(_teeth, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
				_last_teeth = Run.teeth
		else:
			_teeth.text = ""
			_cards.text = ""
	if not i.last.is_empty():
		lines.append(Lang.t("last") % [i.last.speed, int(i.last.angle), i.last_dist])
	if int(i.get("charge", 0)) > 0:
		lines.append(("LADDAT: +%d MULTI PÅ NÄSTA TRÄFF" if Lang.current == "sv" else "CHARGED: +%d MULT ON NEXT HIT") % int(i.charge))
	_info.text = "\n".join(lines)
	_phase.visible = _phase.text != ""
	_icons.visible = _icons.text != ""
	_info_box.size = Vector2(206, 0)
	_info_box.position.y = 342 - _info_box.get_combined_minimum_size().y
	_cards_box.visible = _cards.text != ""
	_cards_box.size = Vector2(150, 0)
	_hint.visible = Settings.show_hints
	_hint_strip.visible = Settings.show_hints
	if Settings.throw_mode == "meter":
		_hint.text = Lang.t("hint_meter2") + "   ·   " + Lang.t("hint3")
	else:
		_hint.text = Lang.t("hint2") + "   ·   " + Lang.t("hint3")
	_meter_root.visible = Settings.power_meter
	_meter_label.visible = Settings.power_meter


var _banner_tw: Tween


var _banner_q: Array[String] = []


## Banners visas en i taget: kommer en ny medan en syns hamnar den i kö.
func banner(text: String) -> void:
	if text == "":
		return
	if _banner_tw and _banner_tw.is_running():
		if _banner_q.size() < 3 and not _banner_q.has(text) and _banner.text != text:
			_banner_q.append(text)
		return
	_play_banner(text)


func _play_banner(text: String) -> void:
	_banner.text = text
	_banner_box.size = Vector2(316, 0)  # krymp till texten
	_banner_box.position.y = _below_speech(56.0)
	if _banner_tw:
		_banner_tw.kill()
	_banner_tw = create_tween()
	_banner_tw.tween_property(_banner_box, "modulate:a", 1.0, 0.3)
	_banner_tw.tween_interval(2.2 + text.length() * 0.025)
	_banner_tw.tween_property(_banner_box, "modulate:a", 0.0, 0.4)
	_banner_tw.tween_callback(_next_banner)


func _next_banner() -> void:
	if not _banner_q.is_empty():
		_play_banner(_banner_q.pop_front())


## Göm bannern direkt (när kort eller utbetalning ska synas).
func hide_banner() -> void:
	if _banner_tw:
		_banner_tw.kill()
	_banner_q.clear()
	_banner_box.modulate.a = 0.0


func toast(text: String) -> void:
	_toast.text = text
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.5)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.6)


func teeth_popup(text: String) -> void:
	var l := _label(8, Color(1.0, 0.95, 0.6), Vector2(6, 146), Vector2(150, 10))
	l.text = text
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", 136.0, 1.6)
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
	_speech_box.visible = text != ""
	_speech_box.size = Vector2(316, 0)
	_speech_t = 4.0 + text.length() * 0.04
	_speech.text = who + ": " + text
	_speech.visible_ratio = 0.0
	if _speech_tween:
		_speech_tween.kill()
	_speech_tween = create_tween()
	_speech_tween.tween_property(_speech, "visible_ratio", 1.0, 0.025 * _speech.text.length())


var _tut_panel: PanelContainer
var _tut_lbl: Label


## Rutan där Gösta förklarar spelet. Tom text gömmer den.
func tutorial(text: String) -> void:
	if _tut_panel == null:
		_tut_panel = _panel_box(Vector2(162, 52), 316, Color(0.9, 0.7, 0.35))
		_tut_lbl = _mk(8, Color(1.0, 0.92, 0.7), "")
		_tut_lbl.custom_minimum_size = Vector2(304, 0)
		_tut_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		_tut_lbl.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
		_tut_panel.add_child(_tut_lbl)
	_tut_panel.visible = text != ""
	_tut_panel.size = Vector2(316, 0)
	_tut_panel.position.y = _below_speech(52.0)
	_tut_lbl.text = text
	if text != "":
		hide_banner()
	# hela texten direkt (rutan får rätt storlek), den tonar in i stället för att skrivas fram
	_tut_panel.modulate.a = 0.0
	create_tween().tween_property(_tut_panel, "modulate:a", 1.0, 0.25)
	_tut_panel.scale = Vector2(1.06, 1.06)
	_tut_panel.pivot_offset = _tut_panel.size * 0.5
	create_tween().tween_property(_tut_panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)


func center(text: String) -> void:
	_center.text = text


func flash(text: String) -> void:
	_flash.text = text
	_flash.modulate.a = 1.0
	# popups håller sig undan från flash-raden medan den syns
	_pop_rects.append([Rect2(162, 156, 316, 24), Time.get_ticks_msec() + 900])
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(_flash, "modulate:a", 0.0, 0.5)


func popup(at: Vector2, text: String) -> void:
	var r := _place_popup(at, text, 12)
	var l := _label(12, Color(1.0, 0.9, 0.3), r.position)
	l.text = text
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 5, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9)
	tw.chain().tween_callback(l.queue_free)


## Du träffade kungen. Skärmen blöder långsamt rött, inga hoppskräck.
func death(title: String, sub: String) -> void:
	_death.text = title + "\n\n" + sub
	_death.visible_ratio = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_blood, "color:a", 0.65, 1.6)
	tw.tween_property(_death, "modulate:a", 1.0, 1.2).set_delay(0.8)
	# texten skrivs fram bokstav för bokstav, som en dödsruna
	tw.tween_property(_death, "visible_ratio", 1.0, 2.4).set_delay(0.9)


func clear_death() -> void:
	_death.visible_ratio = 1.0
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
		pc.position = Vector2(648, 168)
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
		tw.tween_property(pc, "position:x", 489.0, 0.3).set_trans(Tween.TRANS_BACK)
		tw.tween_property(pc, "scale:x", 1.0, 0.35).set_delay(0.1)
		tw.chain().tween_interval(2.6)
		tw.chain().tween_property(pc, "position:x", 648.0, 0.3)
		await tw.finished
		pc.queue_free()
	_card_busy = false


func _mk(size: int, color: Color, text: String) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font_size = Settings.fs(size)
	ls.font_color = color
	ls.outline_size = 2 if ls.font_size <= 12 else 3  # tunn kontur på liten text, annars äter den bokstäverna
	ls.outline_color = Color(0.02, 0.0, 0.01, 0.95)
	ls.shadow_color = Color(0, 0, 0, 0.6)
	ls.shadow_offset = Vector2(1, 1)
	l.label_settings = ls
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Håll Tab (eller Back på handkontrollen) för att se din lek.
var _board: Board
var _board_bg: Panel


var _deck_was := true
var _deck_tick := 0


func show_deck(on: bool, his: Array = [], board: Array = [], opp_name := "") -> void:
	if not on and not _deck_was:
		return
	_deck_was = on
	if _board == null:
		_board_bg = Panel.new()
		_board_bg.add_theme_stylebox_override("panel", Art.frame_style(Color(0.6, 0.15, 0.1), Color(0.03, 0.0, 0.02, 0.94), 16, 4))
		_board_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_board_bg.position = Vector2(6, 8)
		_board_bg.size = Vector2(208, 346)
		_board_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_play_root.add_child(_board_bg)
		_board = Board.new()
		_board.position = Vector2(6, 10)
		_board.size = Vector2(196, 326)
		_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_board_bg.add_child(_board)
	_board_bg.visible = on
	if on:
		_board.items = board
		_board.opp_name = opp_name
		_play_root.move_child(_board_bg, -1)
	if _deck_box == null:
		_deck_bg = Panel.new()
		_deck_bg.add_theme_stylebox_override("panel", Art.frame_style(Color(0.6, 0.15, 0.1), Color(0.03, 0.0, 0.02, 0.95), 16, 4))
		_deck_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_deck_bg.position = Vector2(220, 8)
		_deck_bg.size = Vector2(414, 346)
		_deck_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_deck_bg.clip_contents = true
		_play_root.add_child(_deck_bg)
		_deck_box = _mk(7, Color(0.95, 0.9, 0.8), "")
		_deck_box.position = Vector2(10, 8)
		_deck_box.size = Vector2(394, 330)
		_deck_box.custom_minimum_size = Vector2(394, 0)
		_deck_box.autowrap_mode = TextServer.AUTOWRAP_WORD
		_deck_bg.add_child(_deck_box)
	_deck_bg.visible = on
	# Tab-vyn tar hela skärmen: göm övriga paneler så inget ligger under texten
	for c in [_speech_box, _cards_box, _score_root, _info_box, _banner_box, _teeth, _meter_root, _toast, _hint, _hint_strip]:
		if c == _banner_box or c == _toast:
			if on:
				c.modulate.a = 0.0
		elif c:
			c.modulate.a = 0.0 if on else 1.0
	_deck_box.visible = on
	if not on:
		_deck_tick = 0
		return
	# texten byggs om var tionde bildruta medan Tab hålls, inte varje
	_deck_tick += 1
	if _deck_tick % 10 != 1:
		return
	_play_root.move_child(_deck_bg, -1)
	var sv := Lang.current == "sv"
	var lines: Array[String] = []
	lines.append(("PINNE: " if sv else "BATON: ") + Cards.title(Run.cur_baton()) + " - " + Cards.desc(Run.cur_baton()))
	lines.append("DINA KUBBAR:" if sv else "YOUR KUBBS:")
	if not Run.keyring.is_empty():
		var kn: Array[String] = []
		for c in Run.keyring:
			kn.append(Cards.charm_title(c) + " (" + Cards.charm_desc(c) + ")")
		lines.append(("NYCKELRING: " if sv else "KEY RING: ") + "  ".join(kn))
	if Run.night_mod != "stilla":
		lines.append(("NATTEN: " if sv else "THE NIGHT: ") + Cards.night_title(Run.night_mod) + " - " + Cards.night_desc(Run.night_mod))
	for i in Run.cards.size():
		var id: String = Run.cards[i]
		var rn: Array[String] = []
		for r in [Run.enh[i], Run.ed[i], Run.seal[i]]:
			if r != "":
				rn.append(Cards.rune_title(r))
		lines.append("  %d " % (i + 1) + ((Cards.title(id) + ": " + Cards.desc(id)) if id != "" else ("vanlig kubb" if sv else "plain kubb")) + (("  [" + ", ".join(rn) + "]") if not rn.is_empty() else ""))
		if id != "":
			var lv: int = Run.def_lvl[i]
			if lv > 0:
				lines[-1] += ("  Försvaret är nivå %s." if sv else "  Defense level %s.") % ["I", "II", "III"][lv]
		if Run.grow_chips[i] > 0 or Run.grow_mult[i] > 0:
			lines.append(("    vuxit: +%d marker, +%d multi" if sv else "    grown: +%d chips, +%d mult") % [Run.grow_chips[i], Run.grow_mult[i]])
	if not Run.temp_names.is_empty():
		lines.append(("DENNA MATCH: " if sv else "THIS MATCH: ") + ", ".join(Run.temp_names))
	for id in his:
		lines.append(("  HANS " if sv else "  HIS ") + Cards.title(id) + ": " + Cards.desc(id))
	lines.append(("Kungens nåd kvar: %d" if sv else "King's mercy left: %d") % Run.king_shield_left)
	lines.append(("MAKT %s (%d poäng: kubbar, runor, berlocker x2, löften, kasttypsnivåer). Syns på pinnen och smällarna." if sv else "POWER %s (%d points: kubbs, runes, charms x2, vouchers, throw levels). Shows on your baton and blasts.") % [Run.roman(Run.power_tier()), Run.power_points()])
	var hl: Array[String] = []
	for hid in Cards.HAND_ORDER:
		if Run.hand_level(hid) > 1:
			hl.append("%s %d" % [Cards.hand_title(hid), Run.hand_level(hid)])
	if not hl.is_empty():
		lines.append(("KASTTYPER: " if sv else "THROW TYPES: ") + ", ".join(hl))
	if not Run.vouchers.is_empty():
		var vn: Array[String] = []
		for vo in Run.vouchers:
			vn.append(Cards.voucher_title(vo))
		lines.append(("LÖFTEN: " if sv else "VOUCHERS: ") + ", ".join(vn))
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
	hide_banner()
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
	if r >= 0:
		Sfx.play("click", -4.0, 1.2)
	if _choice_root:
		_choice_root.queue_free()
		_choice_root = null
	return r


## Matchen avbröts med korten uppe: stäng valet utan att något väljs.
func cancel_choice() -> void:
	if _choice_root:
		fate_chosen.emit(-1)


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
	var l := _mk(12, Color(1, 1, 1), "0")
	l.size = sz
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.pivot_offset = sz * 0.5
	r.add_child(l)
	return l


func _build_score() -> void:
	# Balatro-panel till vänster: månens krav, poäng och stora marker x multi
	_score_root = Control.new()
	_score_root.position = Vector2(9, 9)
	_score_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_root.add_child(_score_root)
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", Art.frame_style(Color(0.6, 0.12, 0.08), Color(0.06, 0.01, 0.03, 0.9), 16, 4))
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.position = Vector2(-3, -3)
	panel.size = Vector2(150, 68)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_root.add_child(panel)
	_score_panel = panel
	_goal_lbl = _mk(7, Color(0.85, 0.5, 0.45), "")
	_goal_lbl.position = Vector2(4, 1)
	_score_root.add_child(_goal_lbl)
	_goal_big = _mk(14, Color(1.0, 0.22, 0.15), "0")
	_goal_big.position = Vector2(4, 10)
	_score_root.add_child(_goal_big)
	_score_lbl = _mk(12, Color(1.0, 0.9, 0.55), "0")
	_score_lbl.position = Vector2(4, 29)
	_score_lbl.pivot_offset = Vector2(0, 8)
	_score_root.add_child(_score_lbl)
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.15, 0.02, 0.03, 0.9)
	_bar_bg.position = Vector2(4, 50)
	_bar_bg.size = Vector2(138, 3)
	_score_root.add_child(_bar_bg)
	_bar = ColorRect.new()
	_bar.position = Vector2(4, 50)
	_bar.size = Vector2(0, 3)
	_score_root.add_child(_bar)
	_tally_root = Control.new()
	_tally_root.position = Vector2(4, 58)
	_score_root.add_child(_tally_root)
	_chips_box = ColorRect.new()
	_mult_box = ColorRect.new()
	_hand_lbl = _mk(8, Color(1.0, 0.95, 0.85), "")
	_hand_lbl.position = Vector2(0, 0)
	_hand_lbl.size = Vector2(138, 12)
	_hand_lbl.clip_text = true
	_hand_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hand_lbl.pivot_offset = Vector2(69, 6)
	_tally_root.add_child(_hand_lbl)
	_chips_lbl = _box(Color(0.12, 0.38, 0.95, 1.0), Vector2(0, 17), Vector2(62, 22), _tally_root, _chips_box)
	var x := _mk(14, Color(1, 0.3, 0.25), "X")
	x.position = Vector2(64, 18)
	_tally_root.add_child(x)
	_mult_lbl = _box(Color(0.95, 0.15, 0.1, 1.0), Vector2(76, 17), Vector2(62, 22), _tally_root, _mult_box)
	_total_lbl = _mk(10, Color(1.0, 0.95, 0.6), "")
	_total_lbl.position = Vector2(0, 41)
	_total_lbl.size = Vector2(138, 14)
	_total_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_total_lbl.pivot_offset = Vector2(69, 7)
	_tally_root.add_child(_total_lbl)
	_flames = Control.new()
	_flames.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tally_root.add_child(_flames)
	_chips_lbl.text = "0"
	_mult_lbl.text = "0"
	_tally_root.visible = false
	_fast_lbl = _label(10, Color(1.0, 0.6, 0.3), Vector2(568, 238))
	_fast_lbl.text = ">> x3"
	_fast_lbl.visible = false


var _goal_big: Label
var _hand_lbl: Label
var _shown_i := -1
var _score_panel: Panel
var _tally_on := false
var _show_tw: Tween


var _steal_lbl: Label


## Hans poäng räknas med samma rutor, fast röda och baklänges.
func tally_steal(on: bool) -> void:
	if _steal_lbl == null:
		_steal_lbl = _mk(8, Color(1.0, 0.25, 0.2), "")
		_steal_lbl.position = Vector2(0, 0)
		_steal_lbl.size = Vector2(138, 12)
		_steal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_tally_root.add_child(_steal_lbl)
	_steal_lbl.text = ("HAN STJÄL DINA POÄNG" if Lang.current == "sv" else "HE STEALS YOUR POINTS") if on else ""
	_hand_lbl.visible = not on
	_tally_root.modulate = Color(1.0, 0.55, 0.55, _tally_root.modulate.a) if on else Color(1, 1, 1, _tally_root.modulate.a)


## Rutorna syns bara medan ett kast räknas.
func _tally_show(on: bool) -> void:
	if on == _tally_on:
		return
	_tally_on = on
	if _show_tw:
		_show_tw.kill()
	_show_tw = create_tween().set_parallel(true)
	if on:
		hide_banner()
		_tally_root.visible = true
		_tally_root.modulate.a = 0.0
		_tally_root.scale = Vector2(1.0, 0.2)
		_show_tw.tween_property(_score_panel, "size:y", 126.0, 0.15)
		if _extra:
			_extra.visible = false
		_show_tw.tween_property(_tally_root, "modulate:a", 1.0, 0.12)
		_show_tw.tween_property(_tally_root, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	else:
		_show_tw.tween_property(_tally_root, "modulate:a", 0.0, 0.25)
		_show_tw.tween_property(_score_panel, "size:y", 68.0, 0.3).set_delay(0.15)
		_show_tw.chain().tween_callback(func():
			_tally_root.visible = false
			if _extra:
				_extra.visible = true)
var _chips_box: ColorRect
var _mult_box: ColorRect
var _flames: Control
var _chips_v := 0
var _mult_v := 0.0
var _heat := 0.0
var _flame_t := 0.0


func set_score(v: int, goal: int, instant := false) -> void:
	_score = v
	_shown_i = -1
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
	_tally_show(true)
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
		_total_lbl.text = ""
		_hand_lbl.text = ""
		_tally_show(false))


## Flytande siffra i valfri färg.
var _pop_rects: Array = []  # [Rect2, tid] för popups som nyss dykt upp


## Hittar en plats för en popup som inte krockar med de senaste.
func _place_popup(at: Vector2, text: String, size: int) -> Rect2:
	var fsz := Settings.fs(size)
	var w := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x + 6.0
	var h := float(fsz) + 4.0
	var now := Time.get_ticks_msec()
	var keep: Array = []
	for pr in _pop_rects:
		if now - int(pr[1]) < 800:
			keep.append(pr)
	_pop_rects = keep
	var r := Rect2(at.x - w * 0.5, at.y - h * 0.5, w, h)
	r.position.x = clampf(r.position.x, 4.0, 636.0 - w)
	r.position.y = clampf(r.position.y, 70.0, 250.0)
	# äldre popups stiger uppåt, så en ny läggs under dem (eller ovanför om det är fullt)
	var dir := 1.0
	for _i in 10:
		var hit := false
		for pr in _pop_rects:
			if (pr[0] as Rect2).grow(1.0).intersects(r):
				hit = true
				var o: Rect2 = pr[0]
				r.position.y = (o.end.y + 1.0) if dir > 0.0 else (o.position.y - h - 1.0)
				break
		if not hit:
			break
		if r.position.y > 250.0:
			dir = -1.0
			r.position.y = 250.0
	r.position.y = clampf(r.position.y, 64.0, 258.0)
	_pop_rects.append([r, now])
	return r


func popup_col(at: Vector2, text: String, col: Color, size := 10) -> void:
	var r := _place_popup(at, text, size)
	var l := _label(size, col, r.position)
	l.text = text
	l.pivot_offset = r.size * 0.5
	l.scale = Vector2.ONE * 1.6
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
	tw.tween_property(l, "position:y", l.position.y - 5, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.55)
	tw.chain().tween_callback(l.queue_free)


## Stor text som skakar in mitt på skärmen.
func big(text: String, col: Color) -> void:
	var wait := 0.7 * _big_n
	_big_n += 1
	var l := _label(13, col, Vector2(162, 188 + 30 * (_big_n % 3)), Vector2(316, 20))
	l.modulate.a = 0.0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.text = text
	l.pivot_offset = Vector2(158, 10)
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
	if _speech_t > 0.0:
		_speech_t -= dt
		if _speech_t <= 0.0:
			var tw := create_tween()
			tw.tween_property(_speech_box, "modulate:a", 0.0, 0.4)
			tw.tween_callback(func():
				_speech_box.visible = false
				_speech_box.modulate.a = 1.0)
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
	if int(_shown) != _shown_i:
		_shown_i = int(_shown)
		_score_lbl.text = ("POÄNG " if Lang.current == "sv" else "SCORE ") + _fmt(_shown_i)
	# eld ur rutorna när siffrorna är stora
	_heat = move_toward(_heat, 0.0, dt * 0.6)
	if _heat > 0.15 and _flames.is_visible_in_tree() and _flames.get_child_count() < 90:
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
				fr.position = box.position + Vector2(randf_range(0, 62 - sz), randf_range(-2, 6))
				_flames.add_child(fr)
				var tw := fr.create_tween().set_parallel(true)
				var life := randf_range(0.35, 0.6 + _heat * 0.12)
				tw.tween_property(fr, "position:y", fr.position.y - randf_range(8, 14 + _heat * 6), life)
				tw.tween_property(fr, "position:x", fr.position.x + randf_range(-3, 3), life)
				tw.tween_property(fr, "size", Vector2.ONE, life)
				tw.tween_property(fr, "modulate:a", 0.0, life)
				tw.chain().tween_callback(fr.queue_free)
	var f := clampf(_shown / float(_goal), 0.0, 1.0)
	_bar.size.x = 138.0 * f
	_bar.color = Color(0.85, 0.1, 0.08).lerp(Color(1.0, 0.8, 0.2), f)


## Nollställ räkningsrutorna helt (match slut mitt i en räkning).
func tally_reset() -> void:
	if _tally_tw:
		_tally_tw.kill()
	if _show_tw:
		_show_tw.kill()
	_chips_lbl.text = "0"
	_mult_lbl.text = "0"
	_total_lbl.text = ""
	_tally_root.visible = false
	_tally_root.modulate.a = 0.0
	_score_panel.size.y = 68.0
	_hand_lbl.text = ""
	if _extra:
		_extra.visible = true
	_tally_on = false
	_heat = 0.0
	tally_steal(false)


var _red: ColorRect


## Kort röd blink när han stjäl.
func red_flash() -> void:
	if _red == null:
		_red = ColorRect.new()
		_red.set_anchors_preset(Control.PRESET_FULL_RECT)
		_red.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_red.color = Color(0.7, 0.0, 0.02, 0.0)
		add_child(_red)
	_red.color.a = 0.35
	var tw := create_tween()
	tw.tween_property(_red, "color:a", 0.0, 0.5)


## Nyckelringen skramlar när en berlock slår till.
func jingle() -> void:
	_icons.pivot_offset = Vector2(0, 5)
	var tw := create_tween()
	for k in 4:
		tw.tween_property(_icons, "rotation", (0.06 if k % 2 == 0 else -0.06), 0.05)
	tw.tween_property(_icons, "rotation", 0.0, 0.05)
	_pulse(_teeth, 1.25)


var _extra: Label


## Liten rad under poängen: hur mycket han stulit, ungefär hur många tänder du får, klocka.
func set_extra(stolen: int, teeth: int, clock: String) -> void:
	if _extra == null:
		_extra = _mk(7, Color(0.85, 0.6, 0.5), "")
		_extra.position = Vector2(4, 54)
		_extra.size = Vector2(142, 10)
		_score_root.add_child(_extra)
	if stolen < 0:
		_extra.text = ""
		return
	var sv := Lang.current == "sv"
	var t := ("STULET %d  ~%d TÄNDER" if sv else "STOLEN %d  ~%d TEETH") % [stolen, teeth]
	if clock != "":
		t += "  " + clock
	if _extra.text != t:
		_extra.text = t
	_extra.visible = not _tally_on


## Kasttypen (som Balatros händer): namn och nivå ovanför rutorna.
func tally_hand(name: String, lvl: int, col := Color(1.0, 0.95, 0.85)) -> void:
	_tally_show(true)
	_hand_lbl.text = "%s  niv. %d" % [name, lvl] if Lang.current == "sv" else "%s  lvl %d" % [name, lvl]
	_hand_lbl.label_settings.font_color = col
	_pulse(_hand_lbl, 1.2)


var _cash: PanelContainer


## Utbetalningen efter en vinst: rader som tickar fram med mynt-ljud.
func cash_out(title: String, rows: Array, total: int) -> void:
	if _cash:
		_cash.queue_free()
	hide_banner()
	_cash = PanelContainer.new()
	_cash.add_theme_stylebox_override("panel", Art.frame_style(Color(0.9, 0.7, 0.2), Color(0.06, 0.02, 0.02, 0.94), 24, 10))
	_cash.position = Vector2(170, 60)
	_cash.custom_minimum_size = Vector2(300, 0)
	add_child(_cash)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	_cash.add_child(v)
	var t := _mk(14, Color(1.0, 0.85, 0.3), title)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var sum := 0
	for r in rows:
		var h := HBoxContainer.new()
		var a := _mk(9, Color(0.9, 0.82, 0.72), str(r[0]))
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(a)
		var n := int(r[1])
		var b := _mk(10, Color(1.0, 0.95, 0.6) if n > 0 else Color(0.6, 0.45, 0.4), ("+%d" % n) if n > 0 else "-")
		h.add_child(b)
		h.modulate.a = 0.0
		v.add_child(h)
		var tw := create_tween()
		tw.tween_property(h, "modulate:a", 1.0, 0.12)
		await get_tree().create_timer(0.28, true, false, true).timeout
		if not is_instance_valid(v):
			return
		if n > 0:
			sum += n
			Sfx.play("coin", -4.0, 1.0 + 0.1 * v.get_child_count())
			_pulse(b, 1.8)
	var tot := _mk(16, Color(1.0, 0.95, 0.75), ("TÄNDER +%d" if Lang.current == "sv" else "TEETH +%d") % total)
	tot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tot.pivot_offset = Vector2(120, 10)
	v.add_child(tot)
	_pulse(tot, 2.2)
	Sfx.play("sparkle", -2.0, 1.2)
	await get_tree().create_timer(1.8, true, false, true).timeout
	if _cash == null or not is_instance_valid(_cash):
		return
	var ft := create_tween()
	ft.tween_property(_cash, "modulate:a", 0.0, 0.3)
	await ft.finished
	if _cash:
		_cash.queue_free()
		_cash = null
