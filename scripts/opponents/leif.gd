## Leif: lång man i glansig träningsoverall och solglasögon, mitt i natten.
## Har läst reglerna. Alla regler. Även de som inte finns.
## Fusk: hans kubbar är 30 % tyngre ("regelenliga") och natt 2+ kastar han
## en extra pinne ("förlängd tur enligt paragraf 9").
extends Opponent

var _glasses: Node3D


func _init() -> void:
	display_name = {"sv": "LEIF", "en": "LEIF"}
	error_yaw = 0.018
	error_speed = 0.03
	baton_push = 1.3
	rule_text = {"sv": "Har läst reglerna. Hans kubbar är 30 % tyngre. Natt 2 och 3 tar han en extra pinne enligt paragraf 9.",
		"en": "Has read the rules. His kubbs are 30% heavier. On nights 2 and 3 he takes an extra baton per section 9."}
	lines = {
		"start": {"sv": ["Leif. Domare, spelare och förbundsordförande. Jag har delegerat allt till mig själv.", "Har du läst reglerna? Jag har skrivit dem.", "Solglasögonen? Månen är stark i natt. Regel 4."], "en": ["Leif. Referee, player and federation chairman. I delegated everything to myself.", "Have you read the rules? I wrote them.", "The sunglasses? The moon is strong tonight. Rule 4."]},
		"miss": {"sv": ["Miss. Det noteras.", "Enligt paragraf 12 var det där pinsamt.", "Jag skriver ner det i protokollet."], "en": ["Miss. Noted.", "Per section 12, that was embarrassing.", "I'm writing that in the minutes."]},
		"hit": {"sv": ["Det där granskar vi i efterhand.", "Okej. Godkänt. Motvilligt.", "Jag överklagar till mig själv."], "en": ["We'll review that afterwards.", "Okay. Approved. Reluctantly.", "I'm appealing to myself."]},
		"double": {"sv": ["Två? Det kräver en utredning.", "Ogiltigt. Nej. Giltigt. Tyvärr."], "en": ["Two? That requires an inquiry.", "Invalid. No. Valid. Unfortunately."]},
		"close": {"sv": ["Nära räknas inte. Paragraf 1."], "en": ["Close doesn't count. Section 1."]},
		"short": {"sv": ["För kort. Det finns en minimilängd. Jag har just bestämt den."], "en": ["Too short. There's a minimum length. I just decided it."]},
		"long": {"sv": ["Utanför planen. Böter: en tand."], "en": ["Out of bounds. Fine: one tooth."]},
		"helicopter": {"sv": ["HELIKOPTER! Gult kort! Jag har inga kort, men ändå!"], "en": ["HELICOPTER! Yellow card! I don't have cards, but still!"]},
		"drop": {"sv": ["Tappad pinne. Räknas som kast. Regel 7b."], "en": ["Dropped baton. Counts as a throw. Rule 7b."]},
		"sky": {"sv": ["Luftrummet är inte godkänt för kubb."], "en": ["The airspace is not approved for kubb."]},
		"idle": {"sv": ["Tidtagningen pågår. Jag tar tid på allt.", "Kasta inom regelverkets tidsramar, tack."], "en": ["Timekeeping in progress. I time everything.", "Throw within the regulatory time frame, please."]},
		"effect": {"sv": ["Explosioner är INTE godkända!", "Det där står inte i reglerna! Än."], "en": ["Explosions are NOT approved!", "That is not in the rules! Yet."]},
		"advance": {"sv": ["Jag flyttar fram enligt paragraf 3. Den finns."], "en": ["I'm moving up per section 3. It exists."]},
		"my_turn": {"sv": ["Leifs tur. Jag har förberett en powerpoint.", "Uppvärmning först. Regel 2. Klar."], "en": ["Leif's turn. I've prepared a slideshow.", "Warm-up first. Rule 2. Done."]},
		"opp_hit": {"sv": ["Korrekt utfört.", "Lärobokskast. Jag har skrivit läroboken."], "en": ["Correctly executed.", "Textbook throw. I wrote the textbook."]},
		"opp_miss": {"sv": ["Vinden var inte regelenlig.", "Det var en provkastning."], "en": ["The wind was not regulation.", "That was a test throw."]},
		"toss": {"sv": ["Kubbarna placeras enligt bilaga C."], "en": ["The kubbs are placed per appendix C."]},
		"king_early": {"sv": ["KUNGEN! Diskvalificerad! Äntligen en regel som funkar!"], "en": ["THE KING! Disqualified! Finally a rule that works!"]},
		"king_death": {"sv": ["Regelbrott. Straffet är evigt. Det står i finstilt."], "en": ["Rule violation. The penalty is eternal. It's in the fine print."]},
		"opp_king_death": {"sv": ["Jag... jag rörde kungen. Jag diskar mig själv. Det är rättvist."], "en": ["I... I touched the king. I disqualify myself. It's only fair."]},
		"all_down": {"sv": ["Alla kubbar nere. Det måste granskas."], "en": ["All kubbs down. This must be reviewed."]},
		"round_zero": {"sv": ["Noll. Statistiskt intressant."], "en": ["Zero. Statistically interesting."]},
		"king_win": {"sv": ["Du vann. Jag lämnar in en protest. Den kommer att avslås. Av mig."], "en": ["You won. I'm filing a protest. It will be rejected. By me."]},
		"lose": {"sv": ["Leif vinner. Enligt reglerna. Mina regler."], "en": ["Leif wins. By the rules. My rules."]},
		"king_simple": {"sv": ["Kungen återställs. Paragraf 14."], "en": ["The king is reset. Section 14."]},
		"steal": {"sv": ["Poängavdrag enligt paragraf 8.", "Jag drar av poäng för attityd.", "Dina poäng är beslagtagna."], "en": ["Point deduction per section 8.", "I'm deducting points for attitude.", "Your points are confiscated."]},
		"big_score": {"sv": ["Det där måste dopingtestas.", "Orimligt. Jag ringer förbundet. Det är jag."], "en": ["That needs a doping test.", "Unreasonable. I'm calling the federation. That's me."]},
		"night": {"sv": ["Vädret är godkänt. Knappt."], "en": ["The weather is approved. Barely."]},
		"last_words": {"sv": ["Det här... är inte... regelenligt...", "Jag protesterar... mot döden..."], "en": ["This... is not... regulation...", "I protest... against death..."]},
		"chatter": {"sv": ["Visste du att kubb kommer från Gotland? Jag har bevisat det. För mig själv.", "Jag har en visselpipa. Jag får inte använda den. Regel 22.", "Min fru lämnade mig för en mölkky-spelare. Vi pratar inte om det.", "Overallen är i polyester. Det är regelenligt."], "en": ["Did you know kubb comes from Gotland? I proved it. To myself.", "I have a whistle. I'm not allowed to use it. Rule 22.", "My wife left me for a mölkky player. We don't talk about it.", "The tracksuit is polyester. That's regulation."]},
	}


func mods_for_night(_night: int) -> Dictionary:
	return {"theirs_mass_mult": 1.3}


func setup_for_night(night: int) -> void:
	super.setup_for_night(night)
	if night >= 2:
		extra_batons = 1


func _ready() -> void:
	var suit := PS1.mat(null, Color(0.15, 0.25, 0.75), Vector2.ONE, 0.25)
	var stripe := PS1.mat(null, Color(0.95, 0.95, 0.95), Vector2.ONE, 0.3)
	var skin := PS1.mat(null, Color(0.85, 0.65, 0.55))
	for s in [-1.0, 1.0]:
		var leg := PS1.box(Vector3(0.14, 1.0, 0.14), suit)
		leg.position = Vector3(s * 0.12, 0.5, 0)
		add_child(leg)
		var ls := PS1.box(Vector3(0.02, 1.0, 0.15), stripe)
		ls.position = Vector3(s * 0.19, 0.5, 0)
		add_child(ls)
	var torso := PS1.box(Vector3(0.46, 0.75, 0.26), suit)
	torso.position.y = 1.38
	add_child(torso)
	var zip := PS1.box(Vector3(0.02, 0.7, 0.01), stripe)
	zip.position = Vector3(0, 1.38, 0.135)
	add_child(zip)
	_head = Node3D.new()
	_head.position.y = 1.95
	add_child(_head)
	var skull := PS1.box(Vector3(0.24, 0.3, 0.24), skin)
	_head.add_child(skull)
	var hair := PS1.box(Vector3(0.26, 0.08, 0.26), PS1.mat(null, Color(0.35, 0.25, 0.15)))
	hair.position.y = 0.17
	_head.add_child(hair)
	_glasses = Node3D.new()
	_head.add_child(_glasses)
	var dark := PS1.mat(null, Color(0.02, 0.02, 0.04), Vector2.ONE, 0.1)
	for ex in [-0.06, 0.06]:
		var lens := PS1.box(Vector3(0.09, 0.05, 0.01), dark)
		lens.position = Vector3(ex, 0.03, 0.125)
		_glasses.add_child(lens)
	var bridge := PS1.box(Vector3(0.2, 0.012, 0.01), dark)
	bridge.position = Vector3(0, 0.05, 0.125)
	_glasses.add_child(bridge)
	var mus := PS1.box(Vector3(0.12, 0.025, 0.01), PS1.mat(null, Color(0.3, 0.2, 0.1)))
	mus.position = Vector3(0, -0.06, 0.125)
	_head.add_child(mus)
	var whistle := PS1.box(Vector3(0.04, 0.03, 0.06), PS1.mat(null, Color(0.9, 0.85, 0.2), Vector2.ONE, 0.5))
	whistle.position = Vector3(0, 1.55, 0.16)
	add_child(whistle)
	_arm_len = 0.9
	for s in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(s * 0.3, 1.7, 0.0)
		add_child(pivot)
		var arm := PS1.box(Vector3(0.1, 0.85, 0.1), suit)
		arm.position.y = -0.43
		pivot.add_child(arm)
		if s > 0:
			_arm_pivot = pivot
		else:
			pivot.rotation.z = -0.25
