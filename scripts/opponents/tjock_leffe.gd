## Tjock-Leffe: nattens boss. Svettigt linne, keps, korv i handen.
## Fusk: äter upp en av dina pinnar varje tur.
## Kastar slarvigt men tungt: när han träffar välter det ordentligt.
extends Opponent

var _belly: Node3D


func _init() -> void:
	display_name = {"sv": "TJOCK-LEFFE", "en": "FAT LEFFE"}
	error_yaw = 0.03
	error_speed = 0.05
	baton_push = 2.0
	player_batons_add = -1
	rule_text = {"sv": "Äter upp en av dina pinnar varje tur. Kastar slarvigt men tungt.",
		"en": "Eats one of your batons every turn. Throws sloppy but heavy."}
	lines = {
		"steal": {"sv": ["Leffe tar poängen! Leffe tar allt som ligger framme!", "Dina poäng är mina nu. Som korvarna på grillfesten.", "Mums. Poäng med senap."], "en": ["Leffe takes the points! Leffe takes anything left out!", "Your points are mine now. Like the sausages at the barbecue.", "Yum. Points with mustard."]},
		"big_score": {"sv": ["Hörru! Det där var inte schysst!", "Leffe har sett det där förut. 1987. Det var Leffe."], "en": ["Hey! That wasn't fair!", "Leffe has seen that before. 1987. It was Leffe."]},
		"night": {"sv": ["Vädret? Leffe svettas oavsett.", "Bra grillväder. Allt väder är grillväder."], "en": ["Weather? Leffe sweats either way.", "Good barbecue weather. All weather is barbecue weather."]},
		"phase2": {"sv": ["OKEJ. Nu tar Leffe av sig kepsen. Det betyder krig.", "Leffe har ätit en korv till. Leffe är starkare nu."], "en": ["OKAY. Leffe takes off his cap. That means war.", "Leffe ate another sausage. Leffe is stronger now."]},
		"phase3": {"sv": ["SISTA KORVEN! LEFFE KASTAR MED BÅDA HÄNDERNA!", "Nu blir det grillfest på riktigt. Ni är grillen."], "en": ["LAST SAUSAGE! LEFFE THROWS WITH BOTH HANDS!", "Now it's a real barbecue. You are the grill."]},
		"last_words": {"sv": ["Säg till mamma... att korven... var god...", "Leffe... är... mätt..."], "en": ["Tell mum... the sausage... was good...", "Leffe... is... full..."]},
		"chatter": {"sv": ["Vet du vad bästa korven är? Nästa.", "Leffe har ett eget kubbset. Hemma. I badkaret.", "Hälsa på grannen. Det var han som var kubben förut.", "Om du vinner bjuder Leffe på korv. Du kommer inte att vinna."], "en": ["Know what the best sausage is? The next one.", "Leffe has his own kubb set. At home. In the bathtub.", "Say hi to the neighbour. He used to be the kubb.", "If you win, Leffe buys the sausages. You won't win."]},
		"start": {
			"sv": ["Tjena. Leffe. Kubb-SM-mästare 1987. Ingen annan kom, men ändå.", "Jag har ätit fjorton korvar idag. Jag är redo.", "Mamma sa att jag inte fick spela med främlingar. Mamma är död."],
			"en": ["Hey. Leffe. Kubb champion 1987. Nobody else showed up, but still.", "I've eaten fourteen sausages today. I'm ready.", "Mum said I couldn't play with strangers. Mum is dead."],
		},
		"eat": {
			"sv": ["*knaster* Mm. Din pinne smakade ek.", "Jag åt en av dina pinnar. Den var hungrig. Nej, jag var det.", "Pinne med senap. Klassiker."],
			"en": ["*crunch* Mm. Your baton tasted of oak.", "I ate one of your batons. It was hungry. No, I was.", "Baton with mustard. A classic."],
		},
		"miss": {
			"sv": ["HAHA. Miss. Som min frus advokat sa.", "Skulle du inte träffa nåt?", "Jag har sett bättre kast på grillfester. Av folk som brann."],
			"en": ["HAHA. Miss. Like my wife's lawyer said.", "Weren't you going to hit something?", "I've seen better throws at barbecues. From people on fire."],
		},
		"close": {"sv": ["Ooo, nästan. Jag svettades till.", "Där brände det. Eller var det korven."], "en": ["Ooo, almost. I broke a sweat.", "That was close. Or was it the sausage."]},
		"short": {"sv": ["Kasta som en karl! Eller som en korv, det funkar också.", "Kort. Som min andning."], "en": ["Throw like a man! Or like a sausage, that works too.", "Short. Like my breath."]},
		"long": {"sv": ["Den landade i min bil. Jag har ingen bil.", "Fint. Hämta den själv."], "en": ["That landed in my car. I don't have a car.", "Nice. Fetch it yourself."]},
		"hit": {"sv": ["AJ! Den var nyköpt!", "Okej okej, du får en korv. Nej. Ingen korv.", "Leffe är inte arg. Leffe är besviken."], "en": ["OW! That one was new!", "Okay okay, you get a sausage. No. No sausage.", "Leffe isn't angry. Leffe is disappointed."]},
		"double": {"sv": ["TVÅ?! Jag ringer förbundet!", "Du har tränat. Det är fult att träna."], "en": ["TWO?! I'm calling the federation!", "You've been training. Training is cheating."]},
		"helicopter": {"sv": ["Helikopter! Det är som på min svensexa.", "Ogiltigt. Och snyggt. Mest ogiltigt."], "en": ["Helicopter! Just like my stag do.", "Invalid. And pretty. Mostly invalid."]},
		"drop": {"sv": ["Halkig pinne? Jag har korvflott på allt.", "Hoppsan. Det händer mig med korvar."], "en": ["Slippery baton? I've got sausage grease on everything.", "Whoops. Happens to me with sausages."]},
		"sky": {"sv": ["Till månen! Ta med en korv till mig."], "en": ["To the moon! Bring me back a sausage."]},
		"idle": {"sv": ["Jag hinner äta tre korvar till. Okej, fyra.", "Kasta nu, jag ska hem och se Bingolotto."], "en": ["I've got time for three more sausages. Okay, four.", "Throw already, I'm going home to watch the bingo."]},
		"effect": {"sv": ["AJ! Det där brände i magen!", "Vem har stoppat smällare i kubbarna? Jag vill också!", "Leffe gillar inte blixtar. Leffe gillar korv."], "en": ["OW! That burned my belly!", "Who put firecrackers in the kubbs? I want some too!", "Leffe doesn't like lightning. Leffe likes sausage."]},
		"advance": {"sv": ["Ha! Du missade. Leffe flyttar fram stolen.", "Kortare promenad för Leffe. Tack!", "Närmare kubbarna, närmare korven."], "en": ["Ha! You missed. Leffe moves his chair up.", "Shorter walk for Leffe. Thanks!", "Closer to the kubbs, closer to the sausage."]},
		"my_turn": {"sv": ["Leffes tur! Akta knäna.", "Nu ska ni få se 1987.", "*rapar* Okej. Nu."], "en": ["Leffe's turn! Mind your knees.", "Now you'll see 1987.", "*burps* Okay. Now."]},
		"opp_hit": {"sv": ["BOOM! Leffe-kraft!", "Det är korven. Korven ger kraft.", "Ha! Ring en ambulans till kubben."], "en": ["BOOM! Leffe power!", "It's the sausage. The sausage gives power.", "Ha! Call an ambulance for that kubb."]},
		"opp_miss": {"sv": ["Svettiga fingrar.", "Det var med flit. Jag är snäll.", "Solen bländade. Det är natt. Ändå."], "en": ["Sweaty fingers.", "That was on purpose. I'm nice.", "The sun blinded me. It's night. Still."]},
		"toss": {"sv": ["Här! Fånga! Nej, fånga inte.", "Dina kubbar. Lite korvflott på dem."], "en": ["Here! Catch! No, don't catch.", "Your kubbs. A bit of sausage grease on them."]},
		"king_early": {"sv": ["Du fällde kungen! HAHA! Leffe vinner!"], "en": ["You felled the king! HAHA! Leffe wins!"]},
		"king_death": {"sv": ["Ooo. Du rörde kungen. Det gör man inte. Inte ens jag.", "Där for du. Vill du ha en korv till begravningen?"], "en": ["Ooo. You touched the king. You don't do that. Not even me.", "There you go. Want a sausage for the funeral?"]},
		"opp_king_death": {"sv": ["Nej! Jag rörde kungen! Det var korvens fel!", "Leffe har förlorat. Leffe går hem och gråter i en korv."], "en": ["No! I touched the king! It was the sausage's fault!", "Leffe lost. Leffe is going home to cry into a sausage."]},
		"all_down": {"sv": ["Alla! Alla mina små kubbar!"], "en": ["All of them! All my little kubbs!"]},
		"round_zero": {"sv": ["Noll! Precis som mitt kolesterol. Nej, tvärtom."], "en": ["Zero! Just like my cholesterol. No, the opposite."]},
		"king_win": {"sv": ["Okej, du vann. Ta en korv. Nej, de är mina."], "en": ["Okay, you won. Have a sausage. No, they're mine."]},
		"lose": {"sv": ["LEFFE VINNER! Igen! Som 1987!", "Du får gå hem. Nej, det får du inte."], "en": ["LEFFE WINS! Again! Like 1987!", "You can go home. No, you can't."]},
		"king_simple": {"sv": ["Kungen reser sig. Han är som jag efter middagen."], "en": ["The king gets up. Like me after dinner."]},
	}


func _ready() -> void:
	var shirt := PS1.mat(PS1.cloth(), Color(6.0, 5.6, 4.6), Vector2(2, 2))
	var skin := PS1.mat(null, Color(0.80, 0.55, 0.48))
	var shorts := PS1.mat(PS1.cloth(), Color(1.2, 1.8, 3.2))
	for s in [-1.0, 1.0]:
		var leg := PS1.prism(Vector3(0.2, 0.55, 0.2), skin, 0.2, 0.8)
		leg.position = Vector3(s * 0.2, 0.28, 0)
		add_child(leg)
	var pants := PS1.prism(Vector3(0.75, 0.3, 0.5), shorts, 0.2, 0.8)
	pants.position.y = 0.66
	add_child(pants)
	_belly = PS1.sphere(0.55, shirt, 8, 5)
	_belly.position = Vector3(0, 1.15, 0.08)
	_belly.scale = Vector3(1.1, 1.0, 1.05)
	add_child(_belly)
	var stain := PS1.box(Vector3(0.18, 0.12, 0.02), PS1.mat(null, Color(0.55, 0.45, 0.15)))  # senapsfläck
	stain.position = Vector3(-0.15, 1.25, 0.66)
	add_child(stain)
	_arm_len = 0.85
	for s in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(s * 0.6, 1.5, 0.05)
		pivot.rotation.z = s * 0.25
		add_child(pivot)
		var arm := PS1.prism(Vector3(0.18, 0.8, 0.18), skin, 0.2, 0.8)
		arm.position.y = -0.4
		pivot.add_child(arm)
		if s > 0:
			_arm_pivot = pivot
		else:
			var korv := PS1.cylinder(0.04, 0.32, PS1.mat(null, Color(0.6, 0.22, 0.12)), 5)
			korv.position = Vector3(0, -0.85, 0.1)
			korv.rotation.x = PI * 0.5
			pivot.add_child(korv)
	_head = Node3D.new()
	_head.position.y = 1.72
	add_child(_head)
	var head := PS1.sphere(0.2, skin, 6, 4)
	head.position.y = 0.12
	_head.add_child(head)
	var cap := PS1.prism(Vector3(0.36, 0.1, 0.36), PS1.mat(null, Color(0.7, 0.08, 0.06)), 0.2, 0.8)
	cap.position.y = 0.28
	_head.add_child(cap)
	var brim := PS1.box(Vector3(0.3, 0.03, 0.2), PS1.mat(null, Color(0.7, 0.08, 0.06)))
	brim.position = Vector3(0, 0.24, 0.24)
	_head.add_child(brim)
	var eye_m := PS1.mat(null, Color(0.05, 0.02, 0.02))
	for ex in [-0.07, 0.07]:
		var eye := PS1.box(Vector3(0.035, 0.02, 0.02), eye_m)
		eye.position = Vector3(ex, 0.16, 0.19)
		_head.add_child(eye)
	var mouth := PS1.box(Vector3(0.1, 0.02, 0.02), PS1.mat(null, Color(0.35, 0.05, 0.05)))
	mouth.position = Vector3(0, 0.05, 0.19)
	_head.add_child(mouth)


func _process(dt: float) -> void:
	super(dt)
	if _belly:
		_belly.scale.y = 1.0 + sin(_t * 2.2) * 0.03  # han andas tungt
