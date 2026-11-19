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
	_speech = _label(8, Color(0.95, 0.85, 0.75), Vector2(8, 6), Vector2(368, 40))
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD
	_info = _label(8, Color(0.9, 0.9, 0.8), Vector2(8, 228))
	_icons = _label(8, Color(0.95, 0.75, 0.5), Vector2(8, 218))
	_hint = _label(8, Color(0.75, 0.6, 0.6), Vector2(8, 256))
	_center = _label(12, Color(1.0, 0.3, 0.2), Vector2(0, 90), Vector2(384, 100))
	_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash = _label(14, Color(1.0, 0.85, 0.2), Vector2(0, 70), Vector2(384, 20))
	_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ver := _label(8, Color(0.8, 0.15, 0.1), Vector2(300, 277))
	ver.text = "SISTA KUBBEN v0.9.2"
	_teeth = _label(8, Color(1.0, 0.95, 0.75), Vector2(166, 30), Vector2(210, 10))
	_teeth.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cards = _label(8, Color(0.75, 0.7, 0.85), Vector2(226, 40), Vector2(150, 60))
	_cards.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_phase = _label(8, Color(1.0, 0.55, 0.3), Vector2(8, 204), Vector2(240, 10))
	_banner = _label(12, Color(1.0, 0.8, 0.6), Vector2(0, 60), Vector2(384, 80))
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD
	_banner.modulate.a = 0.0
	_toast = _label(8, Color(0.6, 1.0, 0.6), Vector2(0, 150), Vector2(384, 12))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0

	# golf-kraftmätare: stapel med fyllning, söt punkt och toppmarkering
	_meter_root = Control.new()
	_meter_root.position = Vector2(254, 200)
	_play_root.add_child(_meter_root)
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
	_meter_label = _label(8, Color(0.9, 0.8, 0.7), Vector2(254, 188))

	# precisionsmätare för mätarläget: smal grön mitt, gula sidor, röda kanter
	_acc_root = Control.new()
	_acc_root.position = Vector2(254, 214)
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
	_death.position = Vector2(0, 80)
	_death.size = Vector2(384, 130)
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
	else:
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
			for id in Run.cards:
				names.append(Cards.title(id))
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
	var l := _label(8, Color(1.0, 0.95, 0.6), Vector2(236, 22), Vector2(140, 10))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.text = text
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", 6.0, 1.6)
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
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.06, 0.02, 0.04, 0.95)
		st.border_color = c[2]
		st.set_border_width_all(2)
		st.set_content_margin_all(4)
		pc.add_theme_stylebox_override("panel", st)
		pc.custom_minimum_size = Vector2(120, 0)
		pc.size = Vector2(120, 60)
		pc.position = Vector2(392, 108)
		pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 1)
		pc.add_child(v)
		v.add_child(_mk(6, Color(0.7, 0.6, 0.5), "ÖDESKORT" if Lang.current == "sv" else "FATE CARD"))
		v.add_child(_mk(8, (c[2] as Color).lightened(0.3), c[0]))
		var d := _mk(7, Color(0.9, 0.85, 0.8), c[1])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD
		d.custom_minimum_size = Vector2(112, 0)
		v.add_child(d)
		_play_root.add_child(pc)
		pc.pivot_offset = Vector2(60, 30)
		pc.scale = Vector2(0.05, 1.0)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(pc, "position:x", 258.0, 0.3).set_trans(Tween.TRANS_BACK)
		tw.tween_property(pc, "scale:x", 1.0, 0.35).set_delay(0.1)
		tw.chain().tween_interval(2.6)
		tw.chain().tween_property(pc, "position:x", 392.0, 0.3)
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
func show_deck(on: bool, his: Array = []) -> void:
	if _deck_box == null:
		_deck_box = _label(8, Color(0.95, 0.9, 0.8), Vector2(20, 40), Vector2(344, 160))
		_deck_box.autowrap_mode = TextServer.AUTOWRAP_WORD
		var bg := ColorRect.new()
		bg.color = Color(0.02, 0.0, 0.02, 0.85)
		bg.show_behind_parent = true
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_deck_box.add_child(bg)
	_deck_box.visible = on
	if not on:
		return
	var sv := Lang.current == "sv"
	var lines: Array[String] = []
	lines.append(("PINNE: " if sv else "BATON: ") + Cards.title(Run.cur_baton()) + " - " + Cards.desc(Run.cur_baton()))
	lines.append(("KUBBLEKEN %d/%d" if sv else "KUBB DECK %d/%d") % [Run.cards.size(), Run.MAX_CARDS])
	for id in Run.cards:
		lines.append("  " + Cards.title(id) + ": " + Cards.desc(id))
	if not Run.temp_names.is_empty():
		lines.append(("DENNA MATCH: " if sv else "THIS MATCH: ") + ", ".join(Run.temp_names))
	for id in his:
		lines.append(("  HANS " if sv else "  HIS ") + Cards.title(id) + ": " + Cards.desc(id))
	lines.append(("Kungens nåd kvar: %d" if sv else "King's mercy left: %d") % Run.king_shield_left)
	_deck_box.text = "\n".join(lines)


signal fate_chosen(index: int)
var _choice_root: Control


## Två ödeskort i mitten av skärmen. Klicka på ett, eller tryck 1 / 2.
func choose_fate(a: Array, b: Array) -> int:
	_choice_root = Control.new()
	_choice_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_play_root.add_child(_choice_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.0, 0.02, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_root.add_child(dim)
	var head := _mk(12, Color(1.0, 0.85, 0.5), "ÖDET ERBJUDER. VÄLJ ETT." if Lang.current == "sv" else "FATE OFFERS. CHOOSE ONE.")
	head.position = Vector2(0, 46)
	head.size = Vector2(384, 16)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_root.add_child(head)
	var opts := [a, b]
	for i in 2:
		var c: Array = opts[i]
		var btn := Button.new()
		btn.position = Vector2(52 + i * 148, 72)
		btn.size = Vector2(132, 112)
		btn.focus_mode = Control.FOCUS_ALL
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.08, 0.02, 0.05, 0.97)
		st.border_color = c[2]
		st.set_border_width_all(2)
		var sth := st.duplicate()
		sth.bg_color = Color(0.22, 0.05, 0.08, 0.97)
		sth.border_color = (c[2] as Color).lightened(0.4)
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", sth)
		btn.add_theme_stylebox_override("focus", sth)
		btn.add_theme_stylebox_override("pressed", sth)
		var v := VBoxContainer.new()
		v.position = Vector2(6, 6)
		v.size = Vector2(120, 100)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(v)
		v.add_child(_mk(7, Color(0.7, 0.6, 0.5), "%d" % (i + 1)))
		var t := _mk(10, (c[2] as Color).lightened(0.3), c[0])
		t.autowrap_mode = TextServer.AUTOWRAP_WORD
		t.custom_minimum_size = Vector2(120, 0)
		v.add_child(t)
		var d := _mk(8, Color(0.9, 0.85, 0.8), c[1])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD
		d.custom_minimum_size = Vector2(120, 0)
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
