## En run: tre nätter, två matcher per natt (Vedgubben, sen bossen
## Tjock-Leffe). Tänder, kort, vald pinne. Plus meta-progression som
## sparas mellan runs i user://meta.cfg (upplåsta kort, pinnar m.m.).
extends Node

signal unlocked(text: String)

const META_PATH := "user://meta.cfg"
const MAX_CARDS := 5
const NIGHTS := 3
const OPPONENTS := ["vedgubben", "tjock_leffe"]  # gammal ordning (används om ingen karta)
const NORMAL_OPPS := ["vedgubben", "birgit", "mummlan", "leif"]

var active := false
var night := 1
var match_index := 0      # 0..OPPONENTS.size()-1
var teeth := 0
## Dina 5 kubbar på hans baslinje (vänster till höger). Varje plats kan ha
## ett uppgraderingskort ("" = vanlig kubb). Samma kort får sitta på flera.
var cards: Array[String] = ["", "", "", "", ""]
var baton := "vanlig"
## Runor på varje kubb (förstärkning, utgåva, sigill) och vad den vuxit till.
var enh: Array[String] = ["", "", "", "", ""]
var ed: Array[String] = ["", "", "", "", ""]
var seal: Array[String] = ["", "", "", "", ""]
var grow_chips: Array[int] = [0, 0, 0, 0, 0]
var grow_mult: Array[int] = [0, 0, 0, 0, 0]
## Försvarskort på dina 5 kubbar på DIN baslinje.
var def_cards: Array[String] = ["", "", "", "", ""]
## Pinnkort i handen: dina nästa pinnar (en per kast).
var hand: Array[String] = []
var keyring: Array[String] = []        # berlocker (jokrar) hela runnen
var hand_lvl := {}         # kasttyp -> nivå (1 = start), höjs med stjärnkort
var hand_played := {}
var charm_vals := {}
var vouchers: Array[String] = []  # Kråkmors löften
var voucher_offer := ""        # nattens löfte i boden       # växande berlocker: räknare      # kasttyp -> antal gånger den här runnen
var tags: Array[String] = []  # märken från överhoppade matcher
var shop_half := false     # reamärke: boden kostar hälften
var skip_tag := ""        # märket som erbjuds för att hoppa över nästa match
var endless_mode := false
var run_seed := 0  # startade direkt i den oändliga natten
var def_lvl: Array[int] = [0, 0, 0, 0, 0]  # försvarsnivå per plats
var night_mod := "stilla"
var difficulty := "natten"
var daily := false
var sale_id := ""          # Kråkmors REA: ett kort till halva priset
var run_time := 0.0        # sekunder i den här runnen
var tutorial := false
var override := ""
var score_total := 0
var stats := {"kubbs": 0, "wins": 0, "perfect": 0, "combos": 0, "teeth_total": 0}
# karta: lager av noder, man väljer en nod per lager. Nod = {"type", "opp"}
# typer: match, elite, shop, fate, grave, boss
var map: Array = []
var layer := 0
var picked: Array[int] = []
var node := {}
var endless := false
var opp_mods := {}        # motståndarens specialregler för aktuell match
var king_shield_left := 0
var temp_mods := {}       # välsignelser/förbannelser från ödeskort, bara den här matchen
var temp_names: Array[String] = []
var borrowed := ""       # lånad pinne från ödeskort, bara den här matchen
var cards_drawn := 0
var fate_deck: Array[String] = []
var fate_pile: Array[String] = []
var fate_points := 0
const FATE_COST := 1      # ett ödeskort för varje fälld kubb

# meta
var unlocked_cards: Array[String] = []
var unlocked_batons: Array[String] = ["vanlig"]
var lifetime := {"best_throw": 0, "best_score": 0, "runs": 0, "wins": 0, "kubbs": 0, "best_night": 0, "leffe_beaten": 0, "perfect": 0, "combos": 0, "teeth": 0}


func _ready() -> void:
	load_meta()


func start(baton_id: String, is_daily := false, is_endless := false) -> void:
	daily = is_daily
	if daily:
		# samma natt för alla: fröet är dagens datum
		var d := Time.get_date_dict_from_system()
		seed(hash("%04d-%02d-%02d" % [d.year, d.month, d.day]))
	else:
		randomize()
		run_seed = randi() % 1000000
		seed(run_seed)
	if daily:
		run_seed = -1
	run_time = 0.0
	active = true
	night = 1
	match_index = 0
	teeth = 4
	endless = is_endless
	endless_mode = is_endless
	node = {}
	gen_map()
	cards.assign(["", "", "", "", ""])
	baton = baton_id
	score_total = 0
	randomize_runes()
	keyring.clear()
	hand_lvl = {}
	hand_played = {}
	charm_vals = {}
	vouchers.clear()
	voucher_offer = ""
	tags.clear()
	skips = 0
	shop_half = false
	skip_tag = ""
	def_lvl.assign([0, 0, 0, 0, 0])
	roll_night()

	stats = {"kubbs": 0, "wins": 0, "perfect": 0, "combos": 0, "teeth_total": 0}
	clear_temp()
	cards_drawn = 0
	fate_deck.assign(Cards.FATE_START)
	fate_pile.clear()
	fate_points = 0
	lifetime.runs += 1
	save_meta()


func stop() -> void:
	active = false
	clear_temp()
	opp_mods = {}


func opponent_id() -> String:
	if not node.is_empty():
		return node.get("opp", "vedgubben")
	return OPPONENTS[match_index]


func is_boss() -> bool:
	if not node.is_empty():
		return node.get("type", "") == "boss"
	return match_index == OPPONENTS.size() - 1


func nights_text() -> String:
	return "∞" if endless or night > NIGHTS else str(NIGHTS)


func is_elite() -> bool:
	return node.get("type", "") == "elite"


func _m(t: String) -> Dictionary:
	return {"type": t, "opp": NORMAL_OPPS[randi() % NORMAL_OPPS.size()]}


## En natts karta: match, vila/bod, match eller elit, bod, boss.
func gen_map() -> void:
	var a := {"type": "match", "opp": "vedgubben"}
	var b := {"type": "match", "opp": "birgit"}
	var rest := [{"type": "shop"}, {"type": "fate"}, {"type": "grave"}]
	rest.shuffle()
	var rest2 := [{"type": "shop"}, {"type": "grave"}, {"type": "fate"}]
	rest2.shuffle()
	map = [
		[a, b] if randf() < 0.5 else [b, a],
		rest.slice(0, 2),
		[_m("match"), _m("elite")],
		[{"type": "shop"}, rest2[1]] if rest2[1].type != "shop" else [{"type": "shop"}, {"type": "grave"}],
		[{"type": "boss", "opp": "tjock_leffe"}],
	]
	layer = 0
	picked.clear()


func choose(i: int) -> Dictionary:
	node = map[layer][i]
	picked.append(i)
	return node


## Noden är klar: nästa lager, eller nästa natt med en ny karta.
## Returnerar true om natt 3 just blev klar (och vi inte kör oändligt).
func step_done() -> bool:
	layer += 1
	if layer >= map.size():
		night += 1
		lifetime.best_night = maxi(lifetime.best_night, night)
		if endless_mode:
			lifetime["best_endless"] = maxi(int(lifetime.get("best_endless", 0)), night)
		if endless and night >= 7:
			grant("natt_sju")
		gen_map()
		roll_night()
		save_meta()
		return night == NIGHTS + 1 and not endless
	return false


## Summerar en modifierare från kort, vald pinne och motståndaren.
## Multiplikatorer (namn som slutar på _mult) multipliceras, resten adderas.
func mod(key: String, default := 0.0) -> float:
	if not active:
		return default
	var mult := key.ends_with("_mult")
	var v := 1.0 if mult else 0.0
	for id in cards:
		if id == "":
			continue
		var m: Dictionary = Cards.DEFS[id].get("mods", {})
		if m.has(key):
			v = v * m[key] if mult else v + m[key]
	for c in keyring:
		var cm: Dictionary = Cards.CHARMS[c].mods
		if cm.has(key):
			v = v * cm[key] if mult else v + cm[key]
	for vo in vouchers:
		var vm: Dictionary = Cards.VOUCHERS[vo].mods
		if vm.has(key):
			v = v * vm[key] if mult else v + vm[key]
	var dm: Dictionary = Cards.DIFFICULTY.get(difficulty, {}).get("mods", {})
	if dm.has(key):
		v = v * dm[key] if mult else v + dm[key]
	var nm: Dictionary = Cards.NIGHT_MODS.get(night_mod, {}).get("mods", {})
	if nm.has(key):
		v = v * nm[key] if mult else v + nm[key]
	var b: Dictionary = Cards.BATONS[cur_baton()]
	if b.has(key):
		v = v * b[key] if mult else v + b[key]
	if temp_mods.has(key):
		v = v * temp_mods[key] if mult else v + temp_mods[key]
	if opp_mods.has(key):
		v = v * opp_mods[key] if mult else v + opp_mods[key]
	if not mult and v == 0.0:
		return default
	return v


## Vilken kasttyp ett kast är, efter kubbregler. cleared = hans sida tom
## efter kastet, field_cleared = inga fältkubbar kvar.
func hand_of(felled: Array, cleared := false, field_cleared := false) -> String:
	var n := felled.size()
	var field := 0
	for k in felled:
		if k.field:
			field += 1
	var base := n - field
	if cleared:
		return "kungsoppning"
	if n >= 5:
		return "massaker"
	if field >= 2 and field_cleared:
		return "faltstadning"
	if field > 0 and base > 0:
		return "rensning"
	if n >= 3:
		return "trippel"
	if n == 2:
		return "dubbel"
	return "baskubb" if base == 1 else "faltkubb"


## Ta emot ett märke. Returnerar true om ett paket ska öppnas.
func apply_tag(id: String) -> bool:
	match id:
		"tander":
			add_teeth(8 + night - 1)
		"dubbel", "rea":
			tags.append(id)
		"stjarna":
			var best := "faltkubb"
			for h in hand_played:
				if int(hand_played[h]) > int(hand_played.get(best, 0)):
					best = h
			level_hand(best, 2)
		"paket":
			return true
	return false


var skips := 0


func take_tag(id: String) -> bool:
	if id in tags:
		tags.erase(id)
		return true
	return false


## Blodmånens krav för noden man står på.
func preview_target() -> int:
	var n := night if active else 1
	var t := 600.0 * pow(2.8, n - 1)
	if is_boss():
		t *= 1.4
	if is_elite():
		t *= 1.2
	t *= mod("target_mult", 1.0)
	return int(snappedf(t, 10.0))


func seed_text() -> String:
	return "DAGENS" if run_seed < 0 else "%06d" % run_seed


## Ett nytt löfte per natt i boden (inte ett du redan har).
func roll_voucher() -> void:
	var pool: Array = Cards.VOUCHERS.keys().filter(func(id): return not id in vouchers)
	voucher_offer = pool[randi() % pool.size()] if not pool.is_empty() else ""


func star_price() -> int:
	var p := maxi(1, 3 + night - 1 - int(mod("star_discount")))
	return maxi(1, p / 2) if shop_half else p


func charm_val(key: String) -> float:
	return float(charm_vals.get(key, 0.0))


func bump_charm(key: String, by := 1.0) -> void:
	charm_vals[key] = charm_val(key) + by


func hand_level(id: String) -> int:
	return int(hand_lvl.get(id, 1))


## [marker, multi] för en kasttyp på nuvarande nivå.
func hand_base(id: String) -> Array:
	var h: Dictionary = Cards.HANDS[id]
	var l := hand_level(id) - 1
	return [int(h.chips) + int(h.chips_lvl) * l, float(h.mult) + float(h.mult_lvl) * l]


func level_hand(id: String, by := 1) -> void:
	hand_lvl[id] = hand_level(id) + by
	if hand_level(id) >= 5:
		grant("stjarnskadare")


func baton_stat(key: String) -> float:
	return Cards.BATONS.get(cur_baton(), Cards.BATONS["vanlig"]).get(key, 1.0)


## Två ödeskort ur dragbunten (blandas om när den tar slut).
func draw_fate_two() -> Array[String]:
	var out: Array[String] = []
	for i in 2:
		if fate_pile.is_empty():
			fate_pile.assign(fate_deck)
			fate_pile.shuffle()
			for o in out:
				fate_pile.erase(o)
			if fate_pile.is_empty():
				break
		out.append(fate_pile.pop_back())
	return out


## Ett ödeskort ur dragbunten.
func draw_fate_one() -> String:
	if fate_pile.is_empty():
		fate_pile.assign(fate_deck)
		fate_pile.shuffle()
	if fate_pile.is_empty():
		return ""
	return fate_pile.pop_back()


func cur_baton() -> String:
	if override != "":
		return override
	return borrowed if borrowed != "" else baton


## Ny run: kubbarna får slumpade runor. Ingen run är den andra lik.
func randomize_runes() -> void:
	var e := Cards.runes_of("enh")
	var d := Cards.runes_of("ed")
	var sl := Cards.runes_of("seal")
	for i in 5:
		enh[i] = e[randi() % e.size()] if randf() < 0.6 else ""
		ed[i] = d[randi() % d.size()] if randf() < 0.15 else ""
		seal[i] = sl[randi() % sl.size()] if randf() < 0.15 else ""
		grow_chips[i] = 0
		grow_mult[i] = 0


func rune_on(slot: int, kind: String) -> String:
	if slot < 0 or slot > 4:
		return ""
	match kind:
		"enh": return enh[slot]
		"ed": return ed[slot]
		_: return seal[slot]


func set_rune(slot: int, id: String) -> void:
	match Cards.RUNES[id].kind:
		"enh": enh[slot] = id
		"ed": ed[slot] = id
		_: seal[slot] = id


## Ny natt, nytt väder. Första natten är oftast lugn.
func roll_night() -> void:
	roll_voucher()
	var ids: Array = Cards.NIGHT_MODS.keys()
	ids.erase("stilla")
	night_mod = "stilla" if night == 1 and randf() < 0.5 else str(ids[randi() % ids.size()])


func charm_price(id: String) -> int:
	var p := maxi(1, int(Cards.CHARMS[id].price) + (night - 1) - int(mod("shop_discount")))
	return maxi(1, p / 2) if shop_half else p


func add_charm(id: String) -> bool:
	if keyring.size() >= Cards.MAX_CHARMS or id in keyring:
		return false
	keyring.append(id)
	if keyring.size() >= Cards.MAX_CHARMS:
		grant("full_ring")
	return true


## En bragd låses upp (en gång, sparas mellan runs).
func grant(id: String) -> void:
	if not lifetime.has("bragder"):
		lifetime["bragder"] = []
	if id in lifetime.bragder or not Cards.BRAGDER.has(id):
		return
	lifetime.bragder.append(id)
	save_meta()
	unlocked.emit(("BRAGD: " if Lang.current == "sv" else "FEAT: ") + Cards.pick_title(Cards.BRAGDER, id))


## Vinster och förluster mot varje motståndare.
func note_opp(id: String, won: bool) -> void:
	if not lifetime.has("opp"):
		lifetime["opp"] = {}
	var r: Array = lifetime.opp.get(id, [0, 0])
	r[0 if won else 1] += 1
	lifetime.opp[id] = r


func def_up_price(slot: int) -> int:
	return 5 + 4 * def_lvl[slot]


func upgrade_def(slot: int) -> bool:
	var p := def_up_price(slot)
	if def_lvl[slot] >= 2 or teeth < p or cards[slot] == "":
		return false
	teeth -= p
	def_lvl[slot] += 1
	return true


func def_price(id: String) -> int:
	return maxi(1, int(Cards.DEFENSE[id].price) - int(mod("shop_discount")))


func buy_def(id: String, slot: int) -> bool:
	var p := def_price(id)
	if teeth < p:
		return false
	teeth -= p
	def_cards[slot] = id
	return true


func defs_used() -> int:
	return def_cards.filter(func(c): return c != "").size()


func rune_price(id: String) -> int:
	var p := maxi(1, int(Cards.RUNES[id].price) - int(mod("shop_discount")))
	return maxi(1, p / 2) if shop_half else p


func buy_rune(id: String, slot: int) -> bool:
	var p := rune_price(id)
	if teeth < p:
		return false
	teeth -= p
	set_rune(slot, id)
	return true


## Text om runorna på en kubb, t.ex. "Glas, Folie".
func runes_text(slot: int) -> String:
	var parts: Array[String] = []
	for r in [enh[slot], ed[slot], seal[slot]]:
		if r != "":
			parts.append(Cards.rune_title(r))
	return ", ".join(parts)


## Ny match: ödeskortens tillfälliga effekter försvinner.
func clear_temp() -> void:
	temp_mods = {}
	temp_names.clear()
	borrowed = ""
	hand.clear()
	override = ""


func add_temp(key: String, v: float, name: String) -> void:
	if key.ends_with("_mult"):
		temp_mods[key] = temp_mods.get(key, 1.0) * v
	else:
		temp_mods[key] = temp_mods.get(key, 0.0) + v
	if name != "":
		temp_names.append(name)


func add_teeth(n: int) -> void:
	teeth = maxi(teeth + n, 0)
	if n > 0:
		stats.teeth_total += n
		lifetime.teeth += n


func note_perfect() -> void:
	stats.perfect += 1
	lifetime.perfect += 1


func note_combo() -> void:
	stats.combos += 1
	lifetime.combos += 1


func price(id: String) -> int:
	var d: Dictionary = Cards.DEFS[id]
	if d.get("cursed", false):
		return 0
	var p := maxi(1, int(d.price) + (night - 1) - int(mod("shop_discount")))
	if shop_half:
		p = maxi(1, p / 2)
	return maxi(1, p / 2) if id == sale_id else p


func is_unlocked_baton(id: String) -> bool:
	return not Cards.BATONS[id].has("unlock") or id in unlocked_batons


## Efter vunnen match: nästa motståndare eller nästa natt. Returnerar
## true om hela runnen är vunnen.
## Efter vunnen match. Returnerar true om hela runnen (tre nätter) är vunnen.
func advance() -> bool:
	stats.wins += 1
	lifetime.wins += 1
	if opponent_id() == "tjock_leffe":
		lifetime.leffe_beaten += 1
	var won := step_done()
	check_unlocks()
	save_meta()
	return won


func on_kubbs(n: int) -> void:
	stats.kubbs += n
	lifetime.kubbs += n


func end_run() -> void:
	lifetime.best_night = maxi(lifetime.best_night, night)
	if endless_mode:
		lifetime["best_endless"] = maxi(int(lifetime.get("best_endless", 0)), night)
	check_unlocks()
	save_meta()
	active = false


# ---------------------------------------------------------------- butik

func shop_pool() -> Array[String]:
	var pool: Array[String] = []
	for id in Cards.DEFS:
		var d: Dictionary = Cards.DEFS[id]
		if d.get("cursed", false):
			continue
		if d.has("unlock") and not id in unlocked_cards:
			continue
		pool.append(id)
	return pool


func cursed_pool() -> Array[String]:
	var pool: Array[String] = []
	for id in Cards.DEFS:
		if Cards.DEFS[id].get("cursed", false):
			pool.append(id)
	return pool


## Köp ett kort och sätt det på kubb nummer `slot` (0-4). Ett kort som
## redan satt där försvinner.
func buy(id: String, slot := -1) -> bool:
	var p := price(id)
	if slot < 0:
		slot = free_slot()
	if slot < 0 or teeth < p:
		return false
	teeth -= p
	put(id, slot)
	return true


func put(id: String, slot: int) -> void:
	cards[slot] = id
	grow_chips[slot] = 0
	grow_mult[slot] = 0


func free_slot() -> int:
	return cards.find("")


func slots_used() -> int:
	return cards.filter(func(c): return c != "").size()


## Ta bort kortet från en kubb. Vanliga kort ger halva priset tillbaka.
func sell(slot: int) -> void:
	var id: String = cards[slot]
	if id == "":
		return
	cards[slot] = ""
	def_lvl[slot] = 0
	var d: Dictionary = Cards.DEFS[id]
	if not d.get("cursed", false):
		teeth += int(d.price / 2)


# ---------------------------------------------------------------- meta

func check_unlocks() -> void:
	for kind in ["baton", "card"]:
		var defs: Dictionary = Cards.BATONS if kind == "baton" else Cards.DEFS
		var list: Array[String] = unlocked_batons if kind == "baton" else unlocked_cards
		for id in defs:
			var d: Dictionary = defs[id]
			if not d.has("unlock") or id in list:
				continue
			if float(lifetime.get(d.unlock[0], 0)) >= float(d.unlock[1]):
				list.append(id)
				var what := ("Pinnen " if kind == "baton" else "Kubben ") if Lang.current == "sv" else ("Baton: " if kind == "baton" else "Kubb: ")
				unlocked.emit(what + Cards.title(id) + " (" + Cards.unlock_text(id) + ")")


func load_meta() -> void:
	var cf := ConfigFile.new()
	if cf.load(META_PATH) != OK:
		return
	var uc: Array = cf.get_value("meta", "cards", [])
	var ub: Array = cf.get_value("meta", "batons", ["vanlig"])
	unlocked_cards.assign(uc)
	unlocked_batons.assign(ub)
	if not "vanlig" in unlocked_batons:
		unlocked_batons.append("vanlig")
	var lt: Dictionary = cf.get_value("meta", "lifetime", {})
	for k in lt:
		lifetime[k] = lt[k]


func save_meta() -> void:
	var cf := ConfigFile.new()
	cf.set_value("meta", "cards", unlocked_cards)
	cf.set_value("meta", "batons", unlocked_batons)
	cf.set_value("meta", "lifetime", lifetime)
	cf.save(META_PATH)
