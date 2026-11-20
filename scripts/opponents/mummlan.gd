## Mummlan: en hopsjunken figur insvept i mossa och filtar. Man ser aldrig
## ansiktet, bara två gula prickar. Mumlar hela tiden, ingen förstår vad.
## Fusk: precisionsmarkören går 15 % fortare och hon stjäl mer poäng.
extends Opponent

var _blanket: Node3D


func _init() -> void:
	display_name = {"sv": "MUMMLAN", "en": "THE MUMBLER"}
	error_yaw = 0.024
	error_speed = 0.04
	steal_bonus = 2.0
	rule_text = {"sv": "Mumlar. Precisionsmarkören går 15 % fortare. Stjäl mer poäng när hon fäller dina kubbar.",
		"en": "Mumbles. The accuracy marker runs 15% faster. Steals more points when she fells your kubbs."}
	lines = {
		"start": {"sv": ["Mmm... mmmhmm... kubb... mm.", "*mummel* ...du luktar levande... *mummel*", "Mmmh. Sitt. Kasta. Mmh."], "en": ["Mmm... mmmhmm... kubb... mm.", "*mumble* ...you smell alive... *mumble*", "Mmmh. Sit. Throw. Mmh."]},
		"miss": {"sv": ["Mm-hm-hm-hm.", "*fnissande mummel*", "Mmm... gräset tackar..."], "en": ["Mm-hm-hm-hm.", "*giggling mumble*", "Mmm... the grass thanks you..."]},
		"hit": {"sv": ["MMMH!", "Mm... min lilla kubb... mm...", "*argt mummel*"], "en": ["MMMH!", "Mm... my little kubb... mm...", "*angry mumble*"]},
		"double": {"sv": ["MMMMMH!! Två!", "*mumlar ett namn. Ditt.*"], "en": ["MMMMMH!! Two!", "*mumbles a name. Yours.*"]},
		"close": {"sv": ["Mm. Nästan. Mm."], "en": ["Mm. Almost. Mm."]},
		"short": {"sv": ["Mm... kort... som livet..."], "en": ["Mm... short... like life..."]},
		"long": {"sv": ["Mmm... skogen tar den..."], "en": ["Mmm... the forest takes it..."]},
		"helicopter": {"sv": ["Mmmh! Snurr snurr! Fel!"], "en": ["Mmmh! Spin spin! Wrong!"]},
		"drop": {"sv": ["Mm-hm. Tappade."], "en": ["Mm-hm. Dropped."]},
		"sky": {"sv": ["Mmm... månen... ser den..."], "en": ["Mmm... the moon... sees it..."]},
		"idle": {"sv": ["*mummel mummel*", "Mm... kasta... mm... innan mossan växer på dig..."], "en": ["*mumble mumble*", "Mm... throw... mm... before the moss grows on you..."]},
		"effect": {"sv": ["MMH?! Det brann!", "*mumlar svordomar*"], "en": ["MMH?! It burned!", "*mumbles curses*"]},
		"advance": {"sv": ["Mm. Närmare. Mm-hm."], "en": ["Mm. Closer. Mm-hm."]},
		"my_turn": {"sv": ["Mmmh. Mumlans tur.", "*mumlar och reser sig, långsamt*"], "en": ["Mmmh. The Mumbler's turn.", "*mumbles and rises, slowly*"]},
		"opp_hit": {"sv": ["Mmmh-hm-hm!", "Mm. Ner med dig."], "en": ["Mmmh-hm-hm!", "Mm. Down you go."]},
		"opp_miss": {"sv": ["Mmh. Filten var i vägen.", "*besviket mummel*"], "en": ["Mmh. The blanket got in the way.", "*disappointed mumble*"]},
		"toss": {"sv": ["Mm. Tillbaka. Mm."], "en": ["Mm. Back. Mm."]},
		"king_early": {"sv": ["MMMH! Kungen! Du rörde! Mm!"], "en": ["MMMH! The king! You touched! Mm!"]},
		"king_death": {"sv": ["Mm... nu är du min... mm..."], "en": ["Mm... now you are mine... mm..."]},
		"opp_king_death": {"sv": ["Mm?! Nej... mm... kungen... nej..."], "en": ["Mm?! No... mm... the king... no..."]},
		"all_down": {"sv": ["Mm... alla... mina... mm..."], "en": ["Mm... all... mine... mm..."]},
		"round_zero": {"sv": ["Mm-hm. Noll. Mm."], "en": ["Mm-hm. Zero. Mm."]},
		"king_win": {"sv": ["Mmmh... du vann... mm... gå nu..."], "en": ["Mmmh... you won... mm... go now..."]},
		"lose": {"sv": ["MMMMMH! Mumlan vinner! Stanna. För alltid. Mm."], "en": ["MMMMMH! The Mumbler wins! Stay. Forever. Mm."]},
		"king_simple": {"sv": ["Mm. Kungen står. Mm."], "en": ["Mm. The king stands. Mm."]},
		"steal": {"sv": ["Mmm... dina poäng... mina nu... mm.", "*mumlar och stoppar poängen i filten*"], "en": ["Mmm... your points... mine now... mm.", "*mumbles and tucks the points into the blanket*"]},
		"big_score": {"sv": ["MMH! För många siffror! Mm!"], "en": ["MMH! Too many numbers! Mm!"]},
		"night": {"sv": ["Mm... vädret... mumlar också..."], "en": ["Mm... the weather... mumbles too..."]},
		"last_words": {"sv": ["Mmmmm... mm... m.", "*mumlar något som låter som ditt födelsedatum*"], "en": ["Mmmmm... mm... m.", "*mumbles something that sounds like your birthday*"]},
		"chatter": {"sv": ["*mummel* ...grannen... mm... under ängen...", "Mm. Jag hade ett ansikte. Mm. Det var fint.", "*mumlar en psalm baklänges*", "Mm... Gösta... mm... han vet..."], "en": ["*mumble* ...the neighbour... mm... under the meadow...", "Mm. I had a face. Mm. It was nice.", "*mumbles a hymn backwards*", "Mm... Gösta... mm... he knows..."]},
	}


func mods_for_night(_night: int) -> Dictionary:
	return {"acc_time_mult": 0.85}


func _ready() -> void:
	var moss := PS1.mat(PS1.grass(), Color(0.55, 0.75, 0.45), Vector2(2, 2))
	var wool := PS1.mat(PS1.cloth(), Color(1.4, 1.1, 0.9), Vector2(2, 3))
	_blanket = Node3D.new()
	add_child(_blanket)
	var body := PS1.cylinder(0.6, 1.3, wool, 7, 0.35)
	body.position.y = 0.65
	_blanket.add_child(body)
	var hump := PS1.sphere(0.55, moss, 7, 4)
	hump.position = Vector3(0, 1.3, -0.1)
	hump.scale = Vector3(1.0, 0.8, 1.0)
	_blanket.add_child(hump)
	for i in 6:
		var tuft := PS1.box(Vector3(0.18, 0.1, 0.18), moss)
		var a := TAU * i / 6.0
		tuft.position = Vector3(cos(a) * 0.45, 0.9 + (i % 2) * 0.3, sin(a) * 0.45)
		tuft.rotation.y = a
		_blanket.add_child(tuft)
	_head = Node3D.new()
	_head.position = Vector3(0, 1.45, 0.25)
	add_child(_head)
	var hood := PS1.sphere(0.3, wool, 6, 4)
	_head.add_child(hood)
	var hole := PS1.box(Vector3(0.3, 0.2, 0.05), PS1.mat(null, Color(0.01, 0.0, 0.01)))
	hole.position = Vector3(0, -0.02, 0.27)
	_head.add_child(hole)
	var eye_m := PS1.mat(null, Color(1.0, 0.85, 0.2), Vector2.ONE, 1.2)
	for ex in [-0.06, 0.06]:
		var eye := PS1.box(Vector3(0.025, 0.025, 0.01), eye_m)
		eye.position = Vector3(ex, 0.0, 0.3)
		_head.add_child(eye)
	_arm_len = 1.0
	var pivot := Node3D.new()
	pivot.position = Vector3(0.45, 1.2, 0.1)
	add_child(pivot)
	var arm := PS1.box(Vector3(0.08, 1.0, 0.08), PS1.mat(null, Color(0.35, 0.3, 0.25)))
	arm.position.y = -0.5
	pivot.add_child(arm)
	_arm_pivot = pivot


func _process(dt: float) -> void:
	super._process(dt)
	if _blanket:
		# hon andas. Ojämnt.
		var b := 1.0 + sin(_t * 1.7) * 0.03 + sin(_t * 4.3) * 0.01
		_blanket.scale = Vector3(b, 2.0 - b, b)
