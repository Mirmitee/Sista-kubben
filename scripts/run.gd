## En run: tre nätter, två matcher per natt (Vedgubben, sen bossen
## Tjock-Leffe). Tänder, kort, vald pinne. Plus meta-progression som
## sparas mellan runs i user://meta.cfg (upplåsta kort, pinnar m.m.).
extends Node

signal unlocked(text: String)

const META_PATH := "user://meta.cfg"
const MAX_CARDS := 5
const NIGHTS := 3
const OPPONENTS := ["vedgubben", "tjock_leffe"]  # per natt, sista = boss

var active := false
var night := 1
var match_index := 0      # 0..OPPONENTS.size()-1
var teeth := 0
var cards: Array[String] = []
var baton := "vanlig"
var stats := {"kubbs": 0, "wins": 0, "perfect": 0, "combos": 0, "teeth_total": 0}
var opp_mods := {}        # motståndarens specialregler för aktuell match
var king_shield_left := 0
var temp_mods := {}       # välsignelser/förbannelser från ödeskort, bara den här matchen
var temp_names: Array[String] = []
var borrowed := ""       # lånad pinne från ödeskort, bara den här matchen
var cards_drawn := 0

# meta
var unlocked_cards: Array[String] = []
var unlocked_batons: Array[String] = ["vanlig"]
var lifetime := {"runs": 0, "wins": 0, "kubbs": 0, "best_night": 0, "leffe_beaten": 0, "perfect": 0, "combos": 0, "teeth": 0}


func _ready() -> void:
	load_meta()


func start(baton_id: String) -> void:
	active = true
	night = 1
	match_index = 0
	teeth = 4
	cards.clear()
	baton = baton_id
	stats = {"kubbs": 0, "wins": 0, "perfect": 0, "combos": 0, "teeth_total": 0}
	clear_temp()
	cards_drawn = 0
	lifetime.runs += 1
	save_meta()


func stop() -> void:
	active = false
	clear_temp()
	opp_mods = {}


func opponent_id() -> String:
	return OPPONENTS[match_index]


func is_boss() -> bool:
	return match_index == OPPONENTS.size() - 1


## Summerar en modifierare från kort, vald pinne och motståndaren.
## Multiplikatorer (namn som slutar på _mult) multipliceras, resten adderas.
func mod(key: String, default := 0.0) -> float:
	if not active:
		return default
	var mult := key.ends_with("_mult")
	var v := 1.0 if mult else 0.0
	for id in cards:
		var m: Dictionary = Cards.DEFS[id].get("mods", {})
		if m.has(key):
			v = v * m[key] if mult else v + m[key]
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


func baton_stat(key: String) -> float:
	return Cards.BATONS.get(cur_baton(), Cards.BATONS["vanlig"]).get(key, 1.0)


func cur_baton() -> String:
	return borrowed if borrowed != "" else baton


## Ny match: ödeskortens tillfälliga effekter försvinner.
func clear_temp() -> void:
	temp_mods = {}
	temp_names.clear()
	borrowed = ""


func add_temp(key: String, v: float, name: String) -> void:
	if key.ends_with("_mult"):
		temp_mods[key] = temp_mods.get(key, 1.0) * v
	else:
		temp_mods[key] = temp_mods.get(key, 0.0) + v
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
	return maxi(1, int(d.price) - int(mod("shop_discount")))


func is_unlocked_baton(id: String) -> bool:
	return not Cards.BATONS[id].has("unlock") or id in unlocked_batons


## Efter vunnen match: nästa motståndare eller nästa natt. Returnerar
## true om hela runnen är vunnen.
func advance() -> bool:
	stats.wins += 1
	lifetime.wins += 1
	if opponent_id() == "tjock_leffe":
		lifetime.leffe_beaten += 1
	match_index += 1
	if match_index >= OPPONENTS.size():
		match_index = 0
		night += 1
		lifetime.best_night = maxi(lifetime.best_night, night)
	check_unlocks()
	save_meta()
	return night > NIGHTS


func on_kubbs(n: int) -> void:
	stats.kubbs += n
	lifetime.kubbs += n


func end_run() -> void:
	lifetime.best_night = maxi(lifetime.best_night, night)
	check_unlocks()
	save_meta()
	active = false


# ---------------------------------------------------------------- butik

func shop_pool() -> Array[String]:
	var pool: Array[String] = []
	for id in Cards.DEFS:
		var d: Dictionary = Cards.DEFS[id]
		if d.get("cursed", false) or id in cards:
			continue
		if d.has("unlock") and not id in unlocked_cards:
			continue
		pool.append(id)
	return pool


func cursed_pool() -> Array[String]:
	var pool: Array[String] = []
	for id in Cards.DEFS:
		if Cards.DEFS[id].get("cursed", false) and not id in cards:
			pool.append(id)
	return pool


func buy(id: String) -> bool:
	var p := price(id)
	if cards.size() >= MAX_CARDS or teeth < p:
		return false
	teeth -= p
	cards.append(id)
	return true


func sell(id: String) -> void:
	if not id in cards:
		return
	cards.erase(id)
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
