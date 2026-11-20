## Huvudmeny, regelval, inställningar, kontroller och pausmeny.
## Allt byggs i kod och byggs om när språket byts.
class_name Menu
extends CanvasLayer

signal run_start(baton_id: String)
signal shop_done
signal map_pick(index: int)
signal training_pressed
signal tutorial_pressed
signal resume_pressed
signal restart_pressed
signal main_menu_pressed

var page := "title"
var paused_menu := false
var _root: Control
var _box: VBoxContainer
var _theme: Theme
var _offers: Array[String] = []
var _rune_offers: Array[String] = []
var _curse := ""
var _fate_offers: Array[String] = []
var _reroll := 2
var _charm_offers: Array[String] = []
var _packs_bought: Array[String] = []
var _pack_kind := ""
var _pack_items: Array[String] = []
const PACKS := {
	"kubb": {"price": 6, "n": 3, "col": Color(0.8, 0.55, 0.3), "sv": ["Kubbpaket", "3 kubbar, ta 1 gratis."], "en": ["Kubb Pack", "3 kubbs, take 1 for free."]},
	"rune": {"price": 5, "n": 3, "col": Color(0.4, 0.7, 1.0), "sv": ["Runpaket", "3 runor, ta 1 gratis."], "en": ["Rune Pack", "3 runes, take 1 for free."]},
	"charm": {"price": 8, "n": 2, "col": Color(0.9, 0.8, 0.4), "sv": ["Berlockpaket", "2 berlocker, ta 1 till nyckelringen."], "en": ["Charm Pack", "2 charms, take 1 for your key ring."]},
}
var _baton_page := 0
const BATONS_PER_PAGE := 4


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
	# pixelramar: ditherad fyllning, ljus innerkant, mörk ytterkant
	var normal := Art.frame_style(Color(0.5, 0.1, 0.07), Color(0.1, 0.03, 0.04, 0.95), 16, 5)
	normal.content_margin_top = 3
	normal.content_margin_bottom = 3
	var hover := Art.frame_style(Color(1.0, 0.45, 0.25), Color(0.35, 0.07, 0.05, 1.0), 16, 5)
	hover.content_margin_top = 3
	hover.content_margin_bottom = 3
	var dis := Art.frame_style(Color(0.25, 0.1, 0.1), Color(0.05, 0.02, 0.03, 0.9), 16, 5)
	dis.content_margin_top = 3
	dis.content_margin_bottom = 3
	t.set_stylebox("disabled", "Button", dis)
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.35, 0.32))
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
	var panel := Art.frame_style(Color(0.55, 0.1, 0.07), Color(0.04, 0.01, 0.02, 0.88), 24, 10)
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
		_packs_bought.clear()
		_gen_shop()
	show_page(p)


func _gen_shop() -> void:
	var pool := Run.shop_pool()
	pool.shuffle()
	_offers.assign(pool.slice(0, 3))
	var rp: Array = Cards.RUNES.keys()
	rp.shuffle()
	_rune_offers.assign(rp.slice(0, 2))
	var fp: Array[String] = []
	for id in Cards.FATE:
		if not Cards.FATE[id].get("cursed", false):
			fp.append(id)
	fp.shuffle()
	_fate_offers.assign(fp.slice(0, 2))
	var cp := Run.cursed_pool()
	_curse = cp[randi() % cp.size()] if not cp.is_empty() and randf() < 0.85 else ""
	_charm_offers.assign(_charm_pool().slice(0, 2))


func _charm_pool() -> Array[String]:
	var out: Array[String] = []
	for id in Cards.CHARMS:
		if not id in Run.keyring:
			out.append(id)
	out.shuffle()
	return out


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
		"shop2": _page_shop2()
		"pack": _page_pack()
		"victory": _page_victory()
		"slot": _page_slot()
		"fate_deck": _page_fate_deck()
		"map": _page_map()
		"fate_node": _page_fate_node()
		"grave": _page_grave()
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
	if Run.lifetime.runs > 0:
		_text(_t("Runs %d   Vinster %d   Bästa natt %d   Kubbar %d   Pinnar %d/%d", "Runs %d   Wins %d   Best night %d   Kubbs %d   Batons %d/%d") % [
			Run.lifetime.runs, Run.lifetime.wins, mini(Run.lifetime.best_night, 3), Run.lifetime.kubbs,
			Cards.BATONS.keys().filter(func(id): return Run.is_unlocked_baton(id)).size(), Cards.BATONS.size()], Color(0.6, 0.5, 0.45))
		_text(_t("Bästa kast %d poäng   Bästa run %d poäng", "Best throw %d points   Best run %d points") % [int(Run.lifetime.get("best_throw", 0)), int(Run.lifetime.get("best_score", 0))], Color(1.0, 0.75, 0.4))
	_box.add_child(HSeparator.new())
	_button(_t("SPELA", "PLAY"), func(): show_page("rules"))
	_button(_t("LÄR DIG SPELA (GÖSTA FÖRKLARAR)", "LEARN TO PLAY (GÖSTA EXPLAINS)"), func(): tutorial_pressed.emit())
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
	_text(_t("  8 pinnar per tur. Fällda kubbar kastas bort, inget inkast. Samma död.", "  8 batons per turn. Felled kubbs are thrown away, no tossing back. Same death."))
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
	_slider(_t("MUSIK", "MUSIC"), "music", 0.0, 1.0, 0.05)
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
	if Run.active:
		var names: Array[String] = []
		for i in Run.cards.size():
			if Run.cards[i] != "":
				names.append("%d %s" % [i + 1, Cards.title(Run.cards[i])])
		_text(_t("Pinne: %s   Kubbar: %s", "Baton: %s   Kubbs: %s") % [Cards.title(Run.cur_baton()), ", ".join(names) if not names.is_empty() else "-"], Color(1.0, 0.9, 0.6))
		if not Run.temp_names.is_empty():
			_text(_t("Denna match: ", "This match: ") + ", ".join(Run.temp_names), Color(0.7, 1.0, 0.7))
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
	var kind := "cursed" if cursed else ("baton" if Cards.BATONS.has(id) else "kubb")
	var st := Art.card_style(kind, (Cards.color(id) * 0.75).clamp(Color(0.2, 0.2, 0.2), Color(1, 1, 1)), 112, 150, id.hash() % 97)
	pc.add_theme_stylebox_override("panel", st)
	pc.custom_minimum_size = Vector2(112, 150)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	pc.add_child(v)
	# färgprov: kubbens/pinnens ved och typ av effekt
	var sw := HBoxContainer.new()
	sw.add_theme_constant_override("separation", 2)
	var tag := Label.new()
	tag.add_theme_font_size_override("font_size", 6)
	if d.has("hit") and d.has("fell"):
		tag.text = _t("TRÄFF+FÄLLD", "HIT+FELL")
	elif d.has("hit"):
		tag.text = _t("TRÄFF", "HIT")
	elif d.has("fell"):
		tag.text = _t("FÄLLD", "FELLED")
	elif d.has("score") and d.has("toss"):
		tag.text = _t("POÄNG+INKAST", "SCORE+TOSS")
	elif d.has("score"):
		tag.text = _t("POÄNG", "SCORE")
	elif d.has("toss"):
		tag.text = _t("INKAST", "TOSS")
	elif Cards.DEFS.has(id):
		tag.text = _t("PASSIV", "PASSIVE")
	tag.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5))
	sw.add_child(tag)
	v.add_child(sw)
	var t := Label.new()
	t.text = Cards.title(id)
	t.add_theme_color_override("font_color", Color(1.0, 0.5, 0.9) if cursed else Color(1.0, 0.85, 0.5))
	v.add_child(t)
	var dl := Label.new()
	dl.text = Cards.desc(id)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD
	dl.custom_minimum_size = Vector2(100, 50)
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
	var ids: Array = Cards.BATONS.keys()
	var pages := int(ceil(ids.size() / float(BATONS_PER_PAGE)))
	_baton_page = clampi(_baton_page, 0, pages - 1)
	var got := 0
	for id in ids:
		if Run.is_unlocked_baton(id):
			got += 1
	_text(_t("Upplåsta %d/%d   Sida %d/%d", "Unlocked %d/%d   Page %d/%d") % [got, ids.size(), _baton_page + 1, pages], Color(1.0, 0.9, 0.6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	_box.add_child(row)
	for n in range(_baton_page * BATONS_PER_PAGE, mini(ids.size(), (_baton_page + 1) * BATONS_PER_PAGE)):
		var id: String = ids[n]
		if Run.is_unlocked_baton(id):
			_card_panel(id, row, "", _t("VÄLJ", "PICK"), func(): run_start.emit(id))
		else:
			var pc := PanelContainer.new()
			pc.custom_minimum_size = Vector2(70, 92)
			var l := Label.new()
			l.text = _t("LÅST\n???\n\n", "LOCKED\n???\n\n") + Cards.unlock_text(id)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD
			l.custom_minimum_size = Vector2(64, 0)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pc.add_child(l)
			row.add_child(pc)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 4)
	_box.add_child(nav)
	var prev := Button.new()
	prev.text = _t("< FÖRRA", "< PREV")
	prev.disabled = _baton_page == 0
	prev.pressed.connect(func():
		_baton_page -= 1
		Sfx.play("click", -6.0)
		show_page("baton"))
	nav.add_child(prev)
	var nxt := Button.new()
	nxt.text = _t("NÄSTA >", "NEXT >")
	nxt.disabled = _baton_page >= pages - 1
	nxt.pressed.connect(func():
		_baton_page += 1
		Sfx.play("click", -6.0)
		show_page("baton"))
	nav.add_child(nxt)
	_button(_t("TILLBAKA", "BACK"), func(): show_page("rules"))


func _page_shop() -> void:
	_title(_t("KRÅKMORS BOD", "CROW MOTHER'S SHOP"), 12)
	_text(_t("Tänder %d   Uppgraderade kubbar %d/5   Natt %d", "Teeth %d   Upgraded kubbs %d/5   Night %d") % [
		Run.teeth, Run.slots_used(), Run.night], Color(1.0, 0.9, 0.6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	_box.add_child(row)
	for id in _offers:
		var price := Run.price(id)
		var ok := Run.teeth >= price
		_card_panel(id, row, _t("%d tänder", "%d teeth") % price, _t("KÖP", "BUY"), func():
			_pending = id
			show_page("slot"), ok)
	if _curse != "":
		_card_panel(_curse, row, _t("GRATIS...", "FREE..."), _t("TA", "TAKE"), func():
			_pending = _curse
			show_page("slot"))
	# runor: förstärkningar, utgåvor, sigill för en av dina kubbar
	var rrow := HFlowContainer.new()
	rrow.custom_minimum_size.x = 600
	_box.add_child(rrow)
	var rl := Label.new()
	rl.text = _t("RUNOR:", "RUNES:")
	rl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	rrow.add_child(rl)
	for id in _rune_offers:
		var rb := Button.new()
		var rprice := Run.rune_price(id)
		rb.text = _t("%s (%d)", "%s (%d)") % [Cards.rune_title(id), rprice]
		rb.tooltip_text = Cards.rune_desc(id)
		rb.disabled = Run.teeth < rprice
		rb.pressed.connect(func():
			_pending = "r:" + id
			show_page("slot"))
		rrow.add_child(rb)
	# ödesleken: köp nya ödeskort, bränn dåliga
	var frow := HFlowContainer.new()
	frow.custom_minimum_size.x = 600
	_box.add_child(frow)
	var fl := Label.new()
	fl.text = _t("ÖDESLEK %d kort:", "FATE DECK %d cards:") % Run.fate_deck.size()
	fl.add_theme_color_override("font_color", Color(0.75, 0.9, 0.6))
	frow.add_child(fl)
	for id in _fate_offers:
		var fb := Button.new()
		var fprice: int = Cards.FATE[id].price
		fb.text = _t("KÖP %s (%d)", "BUY %s (%d)") % [Cards.fate_title(id), fprice]
		fb.tooltip_text = Cards.fate_desc(id)
		fb.disabled = Run.teeth < fprice
		fb.pressed.connect(func():
			if Run.teeth >= fprice:
				Run.teeth -= fprice
				Run.fate_deck.append(id)
				Run.fate_pile.append(id)
				_fate_offers.erase(id)
				Sfx.play("sparkle", -6.0)
				show_page("shop"))
		frow.add_child(fb)
	var fdb := Button.new()
	fdb.text = _t("BRÄNN ÖDESKORT...", "BURN FATE CARDS...")
	fdb.pressed.connect(func(): show_page("fate_deck"))
	frow.add_child(fdb)
	var row2 := HBoxContainer.new()
	_box.add_child(row2)
	var rr := Button.new()
	rr.text = _t("NYA KUBBAR (%d tänder)", "REROLL (%d teeth)") % _reroll
	rr.disabled = Run.teeth < _reroll
	rr.pressed.connect(func():
		Run.teeth -= _reroll
		_reroll += 1
		_gen_shop()
		Sfx.play("click", -6.0)
		show_page("shop"))
	row2.add_child(rr)
	var row3 := HFlowContainer.new()
	row3.custom_minimum_size.x = 600
	_box.add_child(row3)
	for i in Run.cards.size():
		var id: String = Run.cards[i]
		if id == "":
			continue
		var sb := Button.new()
		var cursed: bool = Cards.DEFS[id].get("cursed", false)
		sb.text = "%d " % (i + 1) + (_t("SÄLJ ", "SELL ") if not cursed else _t("KASTA ", "DROP ")) + Cards.title(id)
		sb.tooltip_text = Cards.desc(id)
		var slot := i
		sb.pressed.connect(func():
			Run.sell(slot)
			show_page("shop"))
		row3.add_child(sb)
	_text(_t("Din pinne: %s. Dina 5 kubbar står på hans baslinje, varje kubb kan bära ett kort.", "Your baton: %s. Your 5 kubbs stand on his baseline, each can carry one card.") % Cards.title(Run.baton), Color(0.8, 0.7, 0.6))
	var tips := [
		_t("\"Fäll fältkubbarna, annars kliver han fram och andas på dig.\"", "\"Fell the field kubbs, or he steps up and breathes on you.\""),
		_t("\"Leffe blir sämre av korv. Alla blir det.\"", "\"Leffe gets worse from sausage. Everyone does.\""),
		_t("\"Krutkubben mitt i raden. Lita på mig. Jag har bara ett öga kvar.\"", "\"Powder kubb in the middle of the row. Trust me. I have one eye left.\""),
		_t("\"Perfekta kast i rad ger tänder. Jag tar dem sen.\"", "\"Perfect throws in a row give teeth. I'll take them later.\""),
		_t("\"Håll Tab under matchen så ser du din lek. Eller blunda. Samma sak.\"", "\"Hold Tab during the match to see your deck. Or close your eyes. Same thing.\""),
		_t("\"Ödeskorten ljuger aldrig. Ibland.\"", "\"The fate cards never lie. Sometimes.\""),
		_t("\"Rör inte kungen. Han är kittlig och hämndlysten.\"", "\"Don't touch the king. He's ticklish and vengeful.\""),
		_t("\"Förbannade kubbar ger mest. Det är därför de är förbannade.\"", "\"Cursed kubbs pay the most. That's why they're cursed.\""),
	]
	_text(_t("Kråkmors spådom: ", "Crow Mother foretells: ") + tips[(Run.night * 7 + Run.match_index * 3 + Run.teeth) % tips.size()], Color(0.75, 0.6, 0.85))
	_button(_t("BAKFICKAN: PAKET, BERLOCKER, FÖRSVAR >", "BACK POCKET: PACKS, CHARMS, DEFENSE >"), func(): show_page("shop2"))
	_button(_t("TILLBAKA TILL KARTAN", "BACK TO THE MAP"), func(): shop_done.emit())


## Litet pixelkort med titel, text och en knapp.
func _mini_card(kind: String, col: Color, title: String, desc: String, foot: String, btn: String, cb: Callable, enabled := true, parent: Container = null) -> void:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Art.card_style(kind, (col * 0.8).clamp(Color(0.2, 0.2, 0.2), Color(1, 1, 1)), 112, 150, title.hash() % 97))
	pc.custom_minimum_size = Vector2(112, 150)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	pc.add_child(v)
	var t := Label.new()
	t.text = title
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	v.add_child(t)
	var dl := Label.new()
	dl.text = desc
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD
	dl.custom_minimum_size = Vector2(100, 50)
	dl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.7))
	v.add_child(dl)
	if foot != "":
		var fl := Label.new()
		fl.text = foot
		fl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
		v.add_child(fl)
	var b := Button.new()
	b.text = btn
	b.disabled = not enabled
	b.pressed.connect(func():
		Sfx.play("click", -6.0)
		cb.call())
	v.add_child(b)
	(parent if parent else _box).add_child(pc)


## Andra sidan av boden: boosterpaket, berlocker till nyckelringen och
## uppgradering av försvar.
func _page_shop2() -> void:
	_title(_t("KRÅKMORS BAKFICKA", "CROW MOTHER'S BACK POCKET"), 12)
	_text(_t("Tänder %d   Nyckelring %d/%d", "Teeth %d   Key ring %d/%d") % [Run.teeth, Run.keyring.size(), Cards.MAX_CHARMS], Color(1.0, 0.9, 0.6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	_box.add_child(row)
	for pk in PACKS:
		var d: Dictionary = PACKS[pk]
		var pr := maxi(1, int(d.price) - int(Run.mod("shop_discount")))
		var done: bool = pk in _packs_bought
		var full: bool = pk == "charm" and Run.keyring.size() >= Cards.MAX_CHARMS
		var kind: String = pk
		_mini_card("pack", d.col, d[Lang.current][0], d[Lang.current][1], _t("%d tänder", "%d teeth") % pr,
			_t("ÖPPNAT", "OPENED") if done else _t("ÖPPNA", "OPEN"), func():
				if Run.teeth < pr:
					return
				Run.teeth -= pr
				_packs_bought.append(kind)
				_open_pack(kind), not done and not full and Run.teeth >= pr, row)
	for id in _charm_offers:
		var cpr := Run.charm_price(id)
		var cid: String = id
		_mini_card("charm", Cards.CHARMS[id].col, Cards.charm_title(id), Cards.charm_desc(id), _t("%d tänder", "%d teeth") % cpr, _t("KÖP", "BUY"), func():
			if Run.teeth >= cpr and Run.add_charm(cid):
				Run.teeth -= cpr
				_charm_offers.erase(cid)
				Sfx.play("coin", -4.0, 1.3)
			show_page("shop2"), Run.teeth >= cpr and Run.keyring.size() < Cards.MAX_CHARMS, row)
	# nyckelringen
	var kr := HFlowContainer.new()
	kr.custom_minimum_size.x = 600
	_box.add_child(kr)
	var kl := Label.new()
	kl.text = _t("NYCKELRING:", "KEY RING:")
	kl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	kr.add_child(kl)
	if Run.keyring.is_empty():
		var el := Label.new()
		el.text = _t("tom. Den skramlar ändå.", "empty. It rattles anyway.")
		kr.add_child(el)
	for c in Run.keyring:
		var cb := Button.new()
		var cid2: String = c
		cb.text = _t("SÄLJ %s (+%d)", "SELL %s (+%d)") % [Cards.charm_title(c), int(Cards.CHARMS[c].price / 2)]
		cb.tooltip_text = Cards.charm_desc(c)
		cb.pressed.connect(func():
			Run.keyring.erase(cid2)
			Run.teeth += int(Cards.CHARMS[cid2].price / 2)
			Sfx.play("click", -6.0)
			show_page("shop2"))
		kr.add_child(cb)
	# försvar
	var dr := HFlowContainer.new()
	dr.custom_minimum_size.x = 600
	_box.add_child(dr)
	var dlb := Label.new()
	dlb.text = _t("FÖRSVAR:", "DEFENSE:")
	dlb.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	dr.add_child(dlb)
	var any := false
	for i in 5:
		var cid3: String = Run.cards[i]
		if cid3 == "":
			continue
		var df := Cards.def_of(cid3)
		if df == "":
			continue
		any = true
		var lvl: int = Run.def_lvl[i]
		var ub := Button.new()
		var slot := i
		var roman := ["I", "II", "III"]
		if lvl >= 2:
			ub.text = "%d %s III (MAX)" % [i + 1, Cards.def_title(df)]
			ub.disabled = true
		else:
			var up := Run.def_up_price(i)
			ub.text = "%d %s %s > %s (%d)" % [i + 1, Cards.def_title(df), roman[lvl], roman[lvl + 1], up]
			ub.disabled = Run.teeth < up
		ub.tooltip_text = Cards.def_desc(df) + " " + Cards.def_level_text(df, mini(lvl + 1, 2))
		ub.pressed.connect(func():
			if Run.upgrade_def(slot):
				Sfx.play("clack2", -2.0, 0.7)
			show_page("shop2"))
		dr.add_child(ub)
	if not any:
		var nl := Label.new()
		nl.text = _t("Inga försvar än. Köp kubbkort, varje kort har ett försvar.", "No defenses yet. Buy kubb cards, each card has a defense.")
		dr.add_child(nl)
	_text(_t("Kråkmor: \"Paket är som ägg. Man vet aldrig vad som kläcks. Ofta en kråka.\"", "Crow Mother: \"Packs are like eggs. You never know what hatches. Usually a crow.\""), Color(0.75, 0.6, 0.85))
	_button(_t("< TILLBAKA TILL BODEN", "< BACK TO THE SHOP"), func(): show_page("shop"))


var _pack_after := "shop2"


func _pack_done() -> void:
	var p := _pack_after
	_pack_after = "shop2"
	show_page(p)


## Belöning efter vunnen match: ett gratis boosterpaket, välj 1.
func reward_pack() -> void:
	visible = true
	_pack_after = "map"
	var r := randf()
	var kind := "kubb" if r < 0.45 else ("rune" if r < 0.8 else "charm")
	if kind == "charm" and Run.keyring.size() >= Cards.MAX_CHARMS:
		kind = "rune"
	if kind == "kubb" and Run.shop_pool().is_empty():
		kind = "rune"
	_open_pack(kind)


func _open_pack(kind: String) -> void:
	_pack_kind = kind
	_pack_items.clear()
	var n: int = PACKS[kind].n
	match kind:
		"kubb":
			var pool := Run.shop_pool()
			pool.shuffle()
			_pack_items.assign(pool.slice(0, n))
		"rune":
			var rp: Array = Cards.RUNES.keys()
			rp.shuffle()
			_pack_items.assign(rp.slice(0, n))
		"charm":
			_pack_items.assign(_charm_pool().slice(0, n))
	Sfx.play("sparkle", 0.0, 0.9)
	Sfx.play("clack2", -4.0, 0.6)
	show_page("pack")


func _page_pack() -> void:
	var d: Dictionary = PACKS[_pack_kind]
	var reward := _pack_after == "map"
	_title((_t("BELÖNING: ", "REWARD: ") if reward else "") + d[Lang.current][0].to_upper() + _t(" ÖPPNAT!", " OPENED!"), 14, (d.col as Color).clamp(Color(0.3, 0.3, 0.3), Color(1, 1, 1)))
	_text(_t("Välj ett. Resten tar kråkorna.", "Pick one. The crows take the rest."))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	_box.add_child(row)
	for id in _pack_items:
		var iid: String = id
		match _pack_kind:
			"kubb":
				_card_panel(id, row, _t("GRATIS", "FREE"), _t("TA", "TAKE"), func():
					_pending = "pk:" + iid
					show_page("slot"))
			"rune":
				var rk: String = Cards.RUNES[id].get("kind", "enh")
				_mini_card(rk if rk in ["enh", "ed", "seal"] else "enh", Cards.RUNES[id].col, Cards.rune_title(id), Cards.rune_desc(id), _t("GRATIS", "FREE"), _t("TA", "TAKE"), func():
					_pending = "pr:" + iid
					show_page("slot"), true, row)
			"charm":
				_mini_card("charm", Cards.CHARMS[id].col, Cards.charm_title(id), Cards.charm_desc(id), _t("GRATIS", "FREE"), _t("TA", "TAKE"), func():
					Run.add_charm(iid)
					_charm_offers.erase(iid)
					Sfx.play("coin", -4.0, 1.3)
					_pack_done(), Run.keyring.size() < Cards.MAX_CHARMS, row)
	# paketet poppar in
	row.pivot_offset = Vector2(180, 75)
	row.scale = Vector2(0.6, 0.6)
	row.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(row, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_property(row, "modulate:a", 1.0, 0.2)
	_button(_t("HOPPA ÖVER", "SKIP"), func(): _pack_done())


func _page_victory() -> void:
	_title(_t("DU ÖVERLEVDE MIDSOMMAR", "YOU SURVIVED MIDSUMMER"), 12)
	_text(_t("Tre nätter. Ingen ska få veta vad du såg.", "Three nights. Nobody will know what you saw."))
	_text(_t("Fällda kubbar: %d   Kombos: %d   Perfekta: %d   Tänder totalt: %d", "Kubbs felled: %d   Combos: %d   Perfects: %d   Teeth total: %d") % [
		Run.stats.kubbs, Run.stats.combos, Run.stats.perfect, Run.stats.teeth_total])
	_text(_t("Men natten tar inte slut. Den har aldrig tagit slut.", "But the night doesn't end. It never has."), Color(0.8, 0.4, 0.4))
	_button(_t("IN I DEN OÄNDLIGA NATTEN", "INTO THE ENDLESS NIGHT"), func():
		Run.endless = true
		Sfx.play("bad", -4.0, 0.6)
		show_page("map"))
	_button(_t("TILL HUVUDMENYN", "MAIN MENU"), func(): main_menu_pressed.emit())


var _pending := ""


func _page_fate_deck() -> void:
	_title(_t("DIN ÖDESLEK", "YOUR FATE DECK"), 14)
	_text(_t("Tänder %d. Bränn ett kort för 2 tänder (minst 2 kort kvar).", "Teeth %d. Burn a card for 2 teeth (at least 2 cards remain).") % Run.teeth, Color(1.0, 0.9, 0.6))
	var row := HFlowContainer.new()
	row.custom_minimum_size.x = 580
	_box.add_child(row)
	var burned := {}
	for id in Run.fate_deck:
		if burned.has(id) or Run.fate_deck.size() <= 2:
			continue
		burned[id] = true
		var bb := Button.new()
		bb.text = _t("BRÄNN %s (2)", "BURN %s (2)") % Cards.fate_title(id)
		bb.tooltip_text = Cards.fate_desc(id)
		bb.disabled = Run.teeth < 2
		bb.pressed.connect(func():
			if Run.teeth >= 2 and Run.fate_deck.size() > 2:
				Run.teeth -= 2
				Run.fate_deck.erase(id)
				Run.fate_pile.erase(id)
				Sfx.play("bad", -8.0, 1.5)
				show_page("fate_deck"))
		row.add_child(bb)
	_button(_t("TILLBAKA TILL BODEN", "BACK TO THE SHOP"), func(): show_page("shop"))


## Välj vilken av dina 5 kubbar kortet ska sitta på.
func _page_slot() -> void:
	_title(_t("VILKEN KUBB?", "WHICH KUBB?"), 14)
	var is_rune := _pending.begins_with("r:") or _pending.begins_with("pr:")
	var rid := _pending.substr(_pending.find(":") + 1) if is_rune else ""
	if is_rune:
		_text(Cards.rune_title(rid) + ": " + Cards.rune_desc(rid), Color(0.6, 0.85, 1.0))
	else:
		var kid := _pending.trim_prefix("pk:")
		_text(Cards.title(kid) + ": " + Cards.desc(kid), Color(1.0, 0.85, 0.5))
	_text(_t("Dina kubbar på hans baslinje, vänster till höger. Ett gammalt kort på kubben försvinner.", "Your kubbs on his baseline, left to right. An old card on that kubb is lost."))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	_box.add_child(row)
	for i in 5:
		var cur: String = Run.cards[i]
		var b := Button.new()
		var rt := Run.runes_text(i)
		b.text = "%d\n%s%s" % [i + 1, Cards.title(cur) if cur != "" else _t("vanlig", "plain"), ("\n" + rt) if rt != "" else ""]
		b.tooltip_text = Cards.desc(cur) if cur != "" else ""
		b.custom_minimum_size = Vector2(88, 48)
		var slot := i
		b.pressed.connect(func():
			var id := _pending
			if id.begins_with("pr:"):
				Run.set_rune(slot, id.substr(3))
				Sfx.play("sparkle", -4.0, 1.2)
				_pending = ""
				_pack_done()
				return
			if id.begins_with("pk:"):
				Run.put(id.substr(3), slot)
				Sfx.play("clack", -6.0, 1.4)
				_pending = ""
				_pack_done()
				return
			if id.begins_with("r:"):
				if Run.buy_rune(id.substr(2), slot):
					_rune_offers.erase(id.substr(2))
					Sfx.play("sparkle", -4.0, 1.2)
				_pending = ""
				show_page("shop")
				return
			var cursed: bool = Cards.DEFS[id].get("cursed", false)
			if Run.buy(id, slot):
				if id == _curse:
					_curse = ""
				else:
					_offers.erase(id)
				Sfx.play("bad" if cursed else "clack", -6.0, 1.2 if cursed else 1.4)
			_pending = ""
			show_page("shop"))
		row.add_child(b)
	_button(_t("ÅNGRA", "CANCEL"), func():
		var was_pack := _pending.begins_with("pk:") or _pending.begins_with("pr:")
		_pending = ""
		if was_pack:
			show_page("pack")
		else:
			show_page("shop"))


func _node_name(n: Dictionary) -> String:
	var opp_name := {"vedgubben": _t("VEDGUBBEN", "THE WOODMAN"), "birgit": "BIRGIT", "tjock_leffe": _t("TJOCK-LEFFE", "FAT LEFFE")}
	match n.type:
		"match": return _t("MATCH: ", "MATCH: ") + opp_name.get(n.opp, "?")
		"elite": return _t("ELIT: ", "ELITE: ") + opp_name.get(n.opp, "?")
		"boss": return "BOSS: " + opp_name.get(n.opp, "?")
		"shop": return _t("KRÅKMORS BOD", "CROW MOTHER'S SHOP")
		"fate": return _t("ÖDESSTENEN", "THE FATE STONE")
		"grave": return _t("GRAVGÅRDEN", "THE GRAVEYARD")
	return "?"


func _node_desc(n: Dictionary) -> String:
	match n.type:
		"match": return _t("Vanlig match.", "Regular match.")
		"elite": return _t("Svårare. 50 % fler tänder.", "Harder. 50% more teeth.")
		"boss": return _t("Han äter dina pinnar.", "He eats your batons.")
		"shop": return _t("Köp kubbar och ödeskort.", "Buy kubbs and fate cards.")
		"fate": return _t("Välj ett gratis ödeskort.", "Pick a free fate card.")
		"grave": return _t("Gräv efter tänder eller begrav en kubb.", "Dig for teeth or bury a kubb.")
	return ""


func _page_map() -> void:
	_title(_t("NATT %d AV %s", "NIGHT %d OF %s") % [Run.night, Run.nights_text()], 14)
	_text(_t("Tänder %d   Uppgraderade kubbar %d/5   Ödesleken %d", "Teeth %d   Upgraded kubbs %d/5   Fate deck %d") % [
		Run.teeth, Run.slots_used(), Run.fate_deck.size()], Color(1.0, 0.9, 0.6))
	if Run.night_mod != "":
		_text(_t("Nattens väder: ", "Tonight's weather: ") + Cards.night_title(Run.night_mod).to_upper() + ". " + Cards.night_desc(Run.night_mod), (Cards.NIGHT_MODS[Run.night_mod].col as Color).clamp(Color(0.4, 0.4, 0.4), Color(1, 1, 1)))
	for li in Run.map.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		_box.add_child(row)
		var nodes: Array = Run.map[li]
		for ni in nodes.size():
			var n: Dictionary = nodes[ni]
			if li == Run.layer:
				var b := Button.new()
				b.text = _node_name(n)
				b.tooltip_text = _node_desc(n)
				b.custom_minimum_size = Vector2(140, 0)
				var idx: int = ni
				b.pressed.connect(func():
					Sfx.play("clack", -6.0, 1.2)
					map_pick.emit(idx))
				row.add_child(b)
			else:
				var l := Label.new()
				var done := li < Run.layer
				var chosen := done and Run.picked.size() > li and Run.picked[li] == ni
				l.text = ("> " if chosen else "") + _node_name(n)
				l.custom_minimum_size = Vector2(140, 0)
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				var c := Color(0.45, 0.35, 0.3)
				if chosen:
					c = Color(0.6, 0.9, 0.5)
				elif not done:
					c = Color(0.85, 0.7, 0.6)
				l.add_theme_color_override("font_color", c)
				row.add_child(l)
	if Run.layer < Run.map.size():
		var hints: Array[String] = []
		for n in Run.map[Run.layer]:
			hints.append(_node_name(n) + ": " + _node_desc(n))
		_text("  ".join(hints), Color(0.7, 0.6, 0.55))
	_text(_t("Välj väg. Ängen minns vilken.", "Choose your path. The meadow remembers which."), Color(0.7, 0.5, 0.8))


var _fate_free: Array[String] = []


func _page_fate_node() -> void:
	_title(_t("ÖDESSTENEN", "THE FATE STONE"), 14)
	_text(_t("En sten med tre ristningar. En av dem lägger sig i din ödeslek.", "A stone with three carvings. One of them joins your fate deck."))
	if _fate_free.is_empty():
		var fp: Array[String] = []
		for id in Cards.FATE:
			if not Cards.FATE[id].get("cursed", false):
				fp.append(id)
		fp.shuffle()
		_fate_free.assign(fp.slice(0, 3))
	for id in _fate_free:
		var b := Button.new()
		b.text = Cards.fate_title(id) + ": " + Cards.fate_desc(id)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		b.custom_minimum_size = Vector2(560, 0)
		b.pressed.connect(func():
			Run.fate_deck.append(id)
			Run.fate_pile.append(id)
			_fate_free.clear()
			Sfx.play("sparkle", -4.0)
			shop_done.emit())
		_box.add_child(b)
	_button(_t("TA INGET (+2 tänder)", "TAKE NOTHING (+2 teeth)"), func():
		Run.add_teeth(2)
		_fate_free.clear()
		shop_done.emit())


var _dug := false


func _page_grave() -> void:
	_title(_t("GRAVGÅRDEN", "THE GRAVEYARD"), 14)
	_text(_t("Kors av björk. Någon har grävt här förut. Någon gräver fortfarande.", "Birch crosses. Someone has dug here before. Someone is still digging."))
	_text(_t("Tänder %d", "Teeth %d") % Run.teeth, Color(1.0, 0.9, 0.6))
	if not _dug:
		_button(_t("GRÄV (5-9 tänder, eller något annat)", "DIG (5-9 teeth, or something else)"), func():
			_dug = true
			if randf() < 0.2:
				var cp := Run.cursed_pool()
				if not cp.is_empty():
					var id: String = cp[randi() % cp.size()]
					var sl := Run.free_slot()
					if sl < 0:
						sl = randi() % 5
					Run.put(id, sl)
					_last_grave = _t("Något grep tag i din hand. %s följer med dig.", "Something grabbed your hand. %s comes with you.") % Cards.title(id)
					Sfx.play("bad", -4.0, 0.7)
					show_page("grave")
					return
			var n := randi_range(5, 9)
			Run.add_teeth(n)
			_last_grave = _t("Du hittade %d tänder. Inga av dem är dina. Än.", "You found %d teeth. None of them are yours. Yet.") % n
			Sfx.play("coin", -4.0)
			show_page("grave"))
	if _last_grave != "":
		_text(_last_grave, Color(0.8, 0.7, 0.9))
	if Run.slots_used() > 0:
		_text(_t("Begrav ett kort från en kubb (förbannade ger 3 tänder):", "Bury a card from a kubb (cursed ones give 3 teeth):"))
		var row := HFlowContainer.new()
		row.custom_minimum_size.x = 580
		_box.add_child(row)
		for i in Run.cards.size():
			var id: String = Run.cards[i]
			if id == "":
				continue
			var b := Button.new()
			b.text = "%d " % (i + 1) + _t("BEGRAV ", "BURY ") + Cards.title(id)
			b.tooltip_text = Cards.desc(id)
			var slot := i
			b.pressed.connect(func():
				Run.cards[slot] = ""
				if Cards.DEFS[id].get("cursed", false):
					Run.add_teeth(3)
				Sfx.play("thud", -4.0, 0.7)
				show_page("grave"))
			row.add_child(b)
	_button(_t("LÄMNA GRAVGÅRDEN", "LEAVE THE GRAVEYARD"), func():
		_dug = false
		_last_grave = ""
		shop_done.emit())


var _last_grave := ""


func back() -> bool:
	## Esc i menyn. Returnerar true om den hanterades.
	if page == "baton":
		show_page("rules")
		return true
	if page in ["settings", "controls", "rules"]:
		show_page("pause" if paused_menu else "title")
		return true
	return false
