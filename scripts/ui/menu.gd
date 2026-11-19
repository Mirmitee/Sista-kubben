## Huvudmeny, regelval, inställningar, kontroller och pausmeny.
## Allt byggs i kod och byggs om när språket byts.
class_name Menu
extends CanvasLayer

signal run_start(baton_id: String)
signal shop_done
signal training_pressed
signal resume_pressed
signal restart_pressed
signal main_menu_pressed

var page := "title"
var paused_menu := false
var _root: Control
var _box: VBoxContainer
var _theme: Theme
var _offers: Array[String] = []
var _curse := ""
var _reroll := 2


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_theme = _make_theme()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = _theme
	add_child(_root)
	Lang.changed.connect(func(): show_page(page))


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 8
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.07, 0.02, 0.03, 0.85)
	normal.border_color = Color(0.45, 0.08, 0.06)
	normal.set_border_width_all(1)
	normal.content_margin_left = 6
	normal.content_margin_right = 6
	normal.content_margin_top = 2
	normal.content_margin_bottom = 2
	var hover := normal.duplicate()
	hover.bg_color = Color(0.30, 0.05, 0.04, 0.95)
	hover.border_color = Color(0.95, 0.3, 0.2)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("focus", "Button", hover)
	t.set_stylebox("pressed", "Button", hover)
	t.set_color("font_color", "Button", Color(0.9, 0.8, 0.7))
	t.set_color("font_hover_color", "Button", Color(1, 0.95, 0.8))
	t.set_color("font_focus_color", "Button", Color(1, 0.95, 0.8))
	t.set_color("font_color", "Label", Color(0.9, 0.82, 0.72))
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.9))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.03, 0.01, 0.02, 0.78)
	panel.border_color = Color(0.35, 0.06, 0.05)
	panel.set_border_width_all(1)
	panel.set_content_margin_all(8)
	t.set_stylebox("panel", "PanelContainer", panel)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(0.2, 0.04, 0.04)
	grab.content_margin_top = 2
	grab.content_margin_bottom = 2
	t.set_stylebox("slider", "HSlider", grab)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.75, 0.12, 0.08)
	fill.content_margin_top = 2
	fill.content_margin_bottom = 2
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	return t


func open(p: String) -> void:
	visible = true
	if p == "shop":
		_reroll = 2
		_gen_shop()
	show_page(p)


func _gen_shop() -> void:
	var pool := Run.shop_pool()
	pool.shuffle()
	_offers.assign(pool.slice(0, 3))
	var cp := Run.cursed_pool()
	_curse = cp[randi() % cp.size()] if not cp.is_empty() and randf() < 0.85 else ""


func close() -> void:
	visible = false


func show_page(p: String) -> void:
	page = p
	for c in _root.get_children():
		c.queue_free()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 3)
	panel.add_child(_box)
	match p:
		"title": _page_title()
		"rules": _page_rules()
		"settings": _page_settings()
		"controls": _page_controls()
		"pause": _page_pause()
		"baton": _page_baton()
		"shop": _page_shop()
		"victory": _page_victory()
	# första knappen får fokus så att tangentbord och gamepad funkar
	await get_tree().process_frame
	for c in _box.get_children():
		if c is Button or c is HSlider or c is CheckButton:
			c.grab_focus()
			break


func _t(sv: String, en: String) -> String:
	return sv if Lang.current == "sv" else en


func _title(text: String, size := 16, color := Color(0.85, 0.12, 0.08)) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_box.add_child(l)


func _text(text: String, color := Color(0.75, 0.65, 0.6)) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	_box.add_child(l)


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(func():
		Sfx.play("click", -8.0)
		cb.call())
	b.focus_entered.connect(func(): Sfx.play("click", -18.0, 0.7))
	_box.add_child(b)
	return b


func _slider(label: String, key: String, lo: float, hi: float, step: float) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.custom_minimum_size.x = 92
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = Settings.get(key)
	s.custom_minimum_size = Vector2(110, 10)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var upd := func(v: float):
		l.text = "%s %.1f" % [label, v]
	upd.call(s.value)
	s.value_changed.connect(func(v: float):
		upd.call(v)
		Settings.set_value(key, v))
	row.add_child(s)
	_box.add_child(row)


func _toggle(label: String, key: String) -> void:
	var b := _button("", func(): pass)
	var upd := func():
		b.text = "%s: %s" % [label, _t("PÅ", "ON") if Settings.get(key) else _t("AV", "OFF")]
	upd.call()
	b.pressed.connect(func():
		Settings.set_value(key, not Settings.get(key))
		upd.call())


func _page_title() -> void:
	_title("SISTA KUBBEN", 24)
	_title(_t("en midsommar du aldrig glömmer", "a midsummer you'll never forget"), 8, Color(0.7, 0.5, 0.45))
	_box.add_child(HSeparator.new())
	_button(_t("SPELA", "PLAY"), func(): show_page("rules"))
	_button(_t("TRÄNA PÅ GÖSTA (HUNDEN)", "PRACTICE ON GÖSTA (THE DOG)"), func(): training_pressed.emit())
	_button(_t("INSTÄLLNINGAR", "SETTINGS"), func(): show_page("settings"))
	_button(_t("KONTROLLER", "CONTROLS"), func(): show_page("controls"))
	_button(_t("SPRÅK: SVENSKA", "LANGUAGE: ENGLISH"), func():
		Lang.toggle()
		Settings.save())
	_button(_t("AVSLUTA", "QUIT"), func(): get_tree().quit())


func _page_rules() -> void:
	_title(_t("VÄLJ REGLER", "CHOOSE RULES"), 12)
	_button(_t("RIKTIG KUBB", "REAL KUBB"), func():
		Settings.set_value("rules", "real")
		show_page("baton"))
	_text(_t("  6 pinnar per tur. Rör du kungen för tidigt dör du.", "  6 batons per turn. Touch the king too early and you die."))
	_button(_t("FÖRENKLAD", "SIMPLIFIED"), func():
		Settings.set_value("rules", "simple")
		show_page("baton"))
	_text(_t("  8 pinnar per tur. Samma död.", "  8 batons per turn. Same death."))
	_button(_t("TILLBAKA", "BACK"), func(): show_page("pause" if paused_menu else "title"))


func _page_settings() -> void:
	_title(_t("INSTÄLLNINGAR", "SETTINGS"), 12)
	var mb := _button("", func(): pass)
	var upd_mode := func():
		mb.text = _t("KASTSÄTT: ", "THROW STYLE: ") + (_t("MÄTARE (TAJMING)", "METER (TIMING)") if Settings.throw_mode == "meter" else _t("MUSDRAG", "MOUSE SWIPE"))
	upd_mode.call()
	mb.pressed.connect(func():
		Settings.set_value("throw_mode", "drag" if Settings.throw_mode == "meter" else "meter")
		upd_mode.call())
	_slider(_t("MUSKÄNSLIGHET", "MOUSE SENS"), "sensitivity", 0.3, 2.5, 0.1)
	_slider(_t("KASTKRAFT", "THROW POWER"), "power", 0.5, 1.5, 0.05)
	_slider(_t("VOLYM", "VOLUME"), "volume", 0.0, 1.0, 0.05)
	_slider(_t("PS1-DARR", "PS1 WOBBLE"), "wobble", 0.0, 1.0, 0.1)
	_toggle(_t("HELSKÄRM", "FULLSCREEN"), "fullscreen")
	_toggle(_t("SIKTHJÄLP", "AIM ASSIST"), "aim_assist")
	_toggle(_t("KRAFTMÄTARE", "POWER METER"), "power_meter")
	_toggle(_t("TIPS PÅ SKÄRMEN", "ON-SCREEN TIPS"), "show_hints")
	_button(_t("TILLBAKA", "BACK"), func(): show_page("pause" if paused_menu else "title"))


func _page_controls() -> void:
	_title(_t("KONTROLLER", "CONTROLS"), 12)
	_text(_t("KASTSÄTT MÄTARE (STANDARD)", "THROW STYLE METER (DEFAULT)"), Color(0.9, 0.3, 0.2))
	_text(_t("Klick / mellanslag / A: 1) ta sats  2) lås kraften  3) släpp i gröna",
		"Click / space / A: 1) wind up  2) lock power  3) release in the green"))
	_text(_t("KASTSÄTT MUSDRAG", "THROW STYLE MOUSE SWIPE"), Color(0.9, 0.3, 0.2))
	_text(_t("Flytta musen i sidled ... sikta\nHåll vänster knapp, dra NER ... ta sats\nSvep UPP och släpp ... kasta\nHöger knapp ... zooma\nA / D ... gå längs baslinjen\nR ... ny runda    H ... visa tips\nL ... språk    F11 ... helskärm    Esc ... paus",
		"Move mouse sideways ... aim\nHold left button, drag DOWN ... wind up\nSwipe UP and let go ... throw\nRight button ... zoom\nA / D ... walk along the baseline\nR ... new round    H ... show tips\nL ... language    F11 ... fullscreen    Esc ... pause"))
	_text("GAMEPAD", Color(0.9, 0.3, 0.2))
	_text(_t("Vänster spak ... sikta    LB / RB ... gå\nHåll A eller RT, höger spak NER ... ta sats\nKnuffa höger spak UPP och släpp ... kasta\nStart ... paus",
		"Left stick ... aim    LB / RB ... walk\nHold A or RT, right stick DOWN ... wind up\nFlick right stick UP and let go ... throw\nStart ... pause"))
	_button(_t("TILLBAKA", "BACK"), func(): show_page("pause" if paused_menu else "title"))


func _page_pause() -> void:
	_title(_t("PAUS", "PAUSED"), 16)
	_text(_t("Vedgubben väntar. Han är bra på att vänta.", "The Woodman waits. He's good at waiting."))
	_button(_t("FORTSÄTT", "RESUME"), func(): resume_pressed.emit())
	_button(_t("BÖRJA OM RUNDAN", "RESTART ROUND"), func(): restart_pressed.emit())
	_button(_t("INSTÄLLNINGAR", "SETTINGS"), func(): show_page("settings"))
	_button(_t("KONTROLLER", "CONTROLS"), func(): show_page("controls"))
	_button(_t("TILL HUVUDMENYN", "MAIN MENU"), func(): main_menu_pressed.emit())
	_button(_t("AVSLUTA SPELET", "QUIT GAME"), func(): get_tree().quit())


func _unhandled_input(e: InputEvent) -> void:
	if not visible or not paused_menu:
		return
	var esc: bool = e.is_action_pressed("ui_cancel") or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_START)
	if esc:
		get_viewport().set_input_as_handled()
		if not back():
			resume_pressed.emit()


func _card_panel(id: String, parent: Container, price_text: String, action_text: String, cb: Callable, enabled := true) -> void:
	var d: Dictionary = Cards.DEFS.get(id, Cards.BATONS.get(id, {}))
	var cursed: bool = d.get("cursed", false)
	var pc := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.12, 0.02, 0.10, 0.95) if cursed else Color(0.10, 0.06, 0.03, 0.95)
	st.border_color = Color(0.7, 0.1, 0.6) if cursed else Color(0.8, 0.6, 0.3)
	st.set_border_width_all(1)
	st.set_content_margin_all(3)
	pc.add_theme_stylebox_override("panel", st)
	pc.custom_minimum_size = Vector2(86, 92)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	pc.add_child(v)
	var t := Label.new()
	t.text = Cards.title(id)
	t.add_theme_color_override("font_color", Color(1.0, 0.5, 0.9) if cursed else Color(1.0, 0.85, 0.5))
	v.add_child(t)
	var dl := Label.new()
	dl.text = Cards.desc(id)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD
	dl.custom_minimum_size = Vector2(80, 46)
	dl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.7))
	v.add_child(dl)
	if price_text != "":
		var pl := Label.new()
		pl.text = price_text
		pl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
		v.add_child(pl)
	var b := Button.new()
	b.text = action_text
	b.disabled = not enabled
	b.pressed.connect(func():
		Sfx.play("click", -6.0)
		cb.call())
	v.add_child(b)
	parent.add_child(pc)


func _page_baton() -> void:
	_title(_t("VÄLJ PINNE", "CHOOSE BATON"), 12)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	_box.add_child(row)
	for id in Cards.BATONS:
		if id in Run.unlocked_batons:
			_card_panel(id, row, "", _t("VÄLJ", "PICK"), func(): run_start.emit(id))
		else:
			var pc := PanelContainer.new()
			pc.custom_minimum_size = Vector2(70, 92)
			var l := Label.new()
			l.text = _t("LÅST\n???", "LOCKED\n???")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pc.add_child(l)
			row.add_child(pc)
	_text(_t("Fler pinnar låses upp när du vinner matcher och fäller kubbar.", "More batons unlock as you win matches and fell kubbs."))
	_button(_t("TILLBAKA", "BACK"), func(): show_page("rules"))


func _page_shop() -> void:
	_title(_t("KRÅKMORS BOD", "CROW MOTHER'S SHOP"), 12)
	_text(_t("Tänder %d   Kort %d/%d   Nästa: natt %d, %s", "Teeth %d   Cards %d/%d   Next: night %d, %s") % [
		Run.teeth, Run.cards.size(), Run.MAX_CARDS, Run.night, Run.opponent_id().replace("_", "-").capitalize()], Color(1.0, 0.9, 0.6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	_box.add_child(row)
	for id in _offers:
		var price: int = Cards.DEFS[id].price
		var ok := Run.teeth >= price and Run.cards.size() < Run.MAX_CARDS
		_card_panel(id, row, _t("%d tänder", "%d teeth") % price, _t("KÖP", "BUY"), func():
			if Run.buy(id):
				_offers.erase(id)
				Sfx.play("clack", -6.0, 1.4)
				show_page("shop"), ok)
	if _curse != "":
		var ok := Run.cards.size() < Run.MAX_CARDS
		_card_panel(_curse, row, _t("GRATIS...", "FREE..."), _t("TA", "TAKE"), func():
			if Run.buy(_curse):
				_curse = ""
				Sfx.play("bad", -6.0, 1.2)
				show_page("shop"), ok)
	var row2 := HBoxContainer.new()
	_box.add_child(row2)
	var rr := Button.new()
	rr.text = _t("NYA KORT (%d tänder)", "REROLL (%d teeth)") % _reroll
	rr.disabled = Run.teeth < _reroll
	rr.pressed.connect(func():
		Run.teeth -= _reroll
		_reroll += 1
		_gen_shop()
		Sfx.play("click", -6.0)
		show_page("shop"))
	row2.add_child(rr)
	var row3 := HFlowContainer.new()
	row3.custom_minimum_size.x = 360
	_box.add_child(row3)
	for id in Run.cards:
		var sb := Button.new()
		var cursed: bool = Cards.DEFS[id].get("cursed", false)
		sb.text = (_t("SÄLJ ", "SELL ") if not cursed else _t("KASTA ", "DROP ")) + Cards.title(id)
		sb.tooltip_text = Cards.desc(id)
		sb.pressed.connect(func():
			Run.sell(id)
			show_page("shop"))
		row3.add_child(sb)
	_text(_t("Kråkmor: \"Förbannade saker är gratis. Det kostar senare.\"", "Crow Mother: \"Cursed things are free. They cost later.\""), Color(0.7, 0.5, 0.8))
	_button(_t("FORTSÄTT TILL NÄSTA MATCH", "ON TO THE NEXT MATCH"), func(): shop_done.emit())


func _page_victory() -> void:
	_title(_t("DU ÖVERLEVDE MIDSOMMAR", "YOU SURVIVED MIDSUMMER"), 12)
	_text(_t("Tre nätter. Ingen ska få veta vad du såg.", "Three nights. Nobody will know what you saw."))
	_text(_t("Fällda kubbar: %d   Kombos: %d   Perfekta: %d   Tänder totalt: %d", "Kubbs felled: %d   Combos: %d   Perfects: %d   Teeth total: %d") % [
		Run.stats.kubbs, Run.stats.combos, Run.stats.perfect, Run.stats.teeth_total])
	_button(_t("TILL HUVUDMENYN", "MAIN MENU"), func(): main_menu_pressed.emit())


func back() -> bool:
	## Esc i menyn. Returnerar true om den hanterades.
	if page == "baton":
		show_page("rules")
		return true
	if page in ["settings", "controls", "rules"]:
		show_page("pause" if paused_menu else "title")
		return true
	return false
