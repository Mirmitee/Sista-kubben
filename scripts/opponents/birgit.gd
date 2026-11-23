## Birgit: lång, smal tant i midsommarklänning med blomsterkrans och en hals
## som är lite för lång. Stickar mellan kasten. Ler hela tiden.
## Fusk: hon nynnar, och kraftmätaren går 15 % fortare. Natt 2 och 3 har
## hon dessutom stickat en extra pinne åt sig själv.
extends Opponent

var _needles: Node3D


func _init() -> void:
	display_name = {"sv": "BIRGIT", "en": "BIRGIT"}
	error_yaw = 0.02
	error_speed = 0.032
	rule_text = {"sv": "Hon nynnar. Kraftmätaren går 15 % fortare. Natt 2 och 3 stickar hon en extra pinne åt sig.",
		"en": "She hums. The power meter runs 15% faster. On nights 2 and 3 she knits herself an extra baton."}
	lines = {
		"steal": {"sv": ["Jag lägger dina poäng i syskrinet, vännen.", "Mormor tar det här. Mormor tar allt till slut.", "Tack för poängen, de ska bli grytlappar."], "en": ["I'll put your points in my sewing box, dear.", "Granny takes this. Granny takes everything in the end.", "Thank you for the points, they'll be potholders."]},
		"big_score": {"sv": ["Oj oj oj, så duktig du är. Det kommer att straffa sig.", "Kråkorna såg det där. De berättar för alla.", "Nu blev mormor arg. Mormor blir aldrig arg."], "en": ["Oh my, aren't you clever. That will cost you.", "The crows saw that. They tell everyone.", "Now granny is angry. Granny is never angry."]},
		"night": {"sv": ["Ta på dig en kofta, det är väder i natt.", "Mormor har stickat den här natten själv."], "en": ["Put on a cardigan, there's weather tonight.", "Granny knitted this night herself."]},
		"last_words": {"sv": ["Mina kråkor... ta hand om... nej, ät honom.", "Mormor kommer tillbaka. Mormor kommer alltid tillbaka."], "en": ["My crows... look after... no, eat him.", "Granny will be back. Granny always comes back."]},
		"chatter": {"sv": ["Vill du ha en kaka? Den är bakad på mossa och sorg.", "Min man spelade kubb. Nu är han en kubb.", "Kråkorna säger att du fuskar. Kråkorna ljuger aldrig. Nästan.", "Sitt rakt i ryggen när du kastar, annars växer du snett."], "en": ["Would you like a cookie? Baked with moss and grief.", "My husband played kubb. Now he is a kubb.", "The crows say you cheat. The crows never lie. Almost.", "Stand up straight when you throw, or you'll grow crooked."]},
		"start": {
			"sv": ["Nämen hej lilla vän! Ska vi leka? Vi ska leka.", "Jag har bakat. Du får smaka sen. Om du vinner. Du vinner inte.", "Min Gunnar spelade också kubb. Han ligger under kungen nu.", "Så fin du är. Som en liten fältkubb."],
			"en": ["Well hello little friend! Shall we play? We shall play.", "I've baked. You can have some later. If you win. You won't.", "My Gunnar played kubb too. He lies under the king now.", "Aren't you lovely. Like a little field kubb."],
		},
		"miss": {
			"sv": ["Oj då! Det gör ingenting. Jo, det gör det.", "Du får försöka igen, gubben. Nej förresten, du får inte det.", "Den pinnen ville hem till mamma.", "Hihi. Hihihi. Hihihihi."],
			"en": ["Oops! Never mind. No, actually, mind.", "Try again, dear. Actually, you can't.", "That baton wanted to go home to mummy.", "Hehe. Hehehe. Hehehehe."],
		},
		"close": {
			"sv": ["Nästan! Som när Gunnar nästan kom hem.", "Så nära. Jag kände vinden i håret. Det var ditt hopp."],
			"en": ["Almost! Like when Gunnar almost came home.", "So close. I felt the wind in my hair. That was your hope."],
		},
		"short": {
			"sv": ["Lite kort, lilla vän. Har du ätit ordentligt?", "Kasta längre! Jag lovar att inte stå i vägen. Jag lovar ingenting."],
			"en": ["A bit short, dear. Have you eaten properly?", "Throw further! I promise not to stand in the way. I promise nothing."],
		},
		"long": {
			"sv": ["Den hamnade i rabatten. Mina rosor. MINA ROSOR.", "Långt! Den landade hos grannen. Han är död. Det gör inget."],
			"en": ["That went in the flowerbed. My roses. MY ROSES.", "Long! It landed at the neighbour's. He's dead. It's fine."],
		},
		"hit": {
			"sv": ["Aj aj aj, där åkte en av mina små.", "Duktigt! Du får en kaka. Den är av mossa.", "Oj! Hihi. Det där ska du få igen."],
			"en": ["Oh dear, there goes one of my little ones.", "Well done! You get a biscuit. It's made of moss.", "Oh! Hehe. You'll pay for that."],
		},
		"double": {
			"sv": ["Två på en gång! Du är ju som en liten skördetröska.", "Två! Jag tappade en maska."],
			"en": ["Two at once! You're like a little combine harvester.", "Two! I dropped a stitch."],
		},
		"helicopter": {
			"sv": ["Nej nej nej, så kastar man inte. Det är fult. Gör om.", "Helikopter! Jag ringer polisen. Jag har deras nummer stickat på en kudde."],
			"en": ["No no no, that's not how we throw. It's ugly. Again.", "Helicopter! I'm calling the police. I have their number knitted on a cushion."],
		},
		"drop": {"sv": ["Tappade du den? Stackars händer.", "Ska jag hålla den åt dig? Jag håller hårt."], "en": ["Did you drop it? Poor hands.", "Shall I hold it for you? I hold tight."]},
		"sky": {"sv": ["Den är på väg till himlen. Hälsa Gunnar!", "Högt! Som mitt blodtryck."], "en": ["It's on its way to heaven. Say hi to Gunnar!", "High! Like my blood pressure."]},
		"idle": {
			"sv": ["Jag stickar en tröja åt dig. Den har tre ärmar. Du kommer att behöva dem.", "Ta den tid du behöver. Jag har hela natten. Och nästa.", "Mm mm mmm... *nynnar något som inte finns*"],
			"en": ["I'm knitting you a sweater. It has three sleeves. You'll need them.", "Take your time. I have all night. And the next.", "Mm mm mmm... *hums something that doesn't exist*"],
		},
		"king_early": {"sv": ["Kungen! Fy skäms!"], "en": ["The king! Shame on you!"]},
		"king_death": {
			"sv": ["Nej men lilla vän. Man rör inte kungen. Nu får du stanna hos mig.", "Åh. Åh nej. Ska jag sticka en liten kista?"],
			"en": ["Oh, little friend. You don't touch the king. Now you stay with me.", "Oh. Oh no. Shall I knit you a little coffin?"],
		},
		"effect": {
			"sv": ["Vad var det där?! Mina blommor brann!", "Trolldom! På MIN äng!", "Det där var inte snällt. Jag kommer ihåg sånt."],
			"en": ["What was that?! My flowers burned!", "Witchcraft! On MY meadow!", "That wasn't nice. I remember things like that."],
		},
		"advance": {
			"sv": ["Du lämnade kubbar kvar. Då kommer tant lite närmare.", "Ett litet steg för Birgit. Ett stort steg mot din grav."],
			"en": ["You left kubbs standing. So auntie comes a little closer.", "A small step for Birgit. A big step toward your grave."],
		},
		"my_turn": {
			"sv": ["Min tur! Titta noga nu, så lär du dig.", "Nu ska tant visa. Sitt still.", "*lägger ner stickningen* Nåväl."],
			"en": ["My turn! Watch closely, and you'll learn.", "Now auntie will show you. Sit still.", "*puts down the knitting* Well then."],
		},
		"opp_hit": {"sv": ["Pling! Hihi.", "Där ser du. Erfarenhet.", "Den där kubben kände jag inget för."], "en": ["Ping! Hehe.", "There you go. Experience.", "I never cared for that kubb."]},
		"opp_miss": {"sv": ["Åh, min reumatism.", "Glasögonen! Var är mina glasögon?", "Det var meningen. Jag är snäll mot dig."], "en": ["Oh, my rheumatism.", "My glasses! Where are my glasses?", "I meant that. I'm being kind to you."]},
		"toss": {"sv": ["Här får du tillbaka dem. Ta hand om dem nu.", "Varsågod! De är lite fuktiga."], "en": ["Here, have them back. Take care of them now.", "There you go! They're a little damp."]},
		"opp_king_death": {"sv": ["Nej. NEJ. Gunnar, förlåt mig.", "Jag rörde honom. Jag har inte rört en man sen 1974."], "en": ["No. NO. Gunnar, forgive me.", "I touched him. I haven't touched a man since 1974."]},
		"lose": {"sv": ["Så ja. Nu stannar du här med mig. Vi ska ha så trevligt.", "Kungen föll! Tårta åt alla! Utom dig."], "en": ["There now. Now you stay here with me. We'll have such a nice time.", "The king fell! Cake for everyone! Except you."]},
		"king_simple": {"sv": ["Kungen. Var försiktig."], "en": ["The king. Careful now."]},
		"all_down": {"sv": ["Alla mina små... Nu är det bara kungen och jag.", "Ni får gå och lägga er nu, kubbar."], "en": ["All my little ones... Now it's just the king and me.", "Off to bed now, kubbs."]},
		"round_zero": {"sv": ["Ingen alls? Stackare.", "Noll. Jag stickar in det i din tröja."], "en": ["None at all? Poor thing.", "Zero. I'll knit it into your sweater."]},
		"king_win": {"sv": ["Nämen. Duktig pojke. Eller flicka. Eller vad du nu är där under.", "Du vann. Ta en bulle. Den biter inte. Den kanske biter."], "en": ["Well now. Good boy. Or girl. Or whatever you are under there.", "You won. Have a bun. It doesn't bite. It might bite."]},
	}


func mods_for_night(_night: int) -> Dictionary:
	return {"meter_time_mult": 0.85}


func setup_for_night(night: int) -> void:
	super.setup_for_night(night)
	if night >= 2:
		extra_batons = 1


func _ready() -> void:
	var dress := PS1.mat(PS1.cloth(), Color(3.2, 3.2, 3.6), Vector2(2, 4))
	var body := PS1.cylinder(0.5, 1.5, dress, 7, 0.2)
	body.position.y = 0.75
	add_child(body)
	var apron := PS1.box(Vector3(0.45, 0.9, 0.04), PS1.mat(null, Color(0.55, 0.12, 0.12)))
	apron.position = Vector3(0, 0.75, 0.3)
	apron.rotation.x = -0.12
	add_child(apron)
	var skin := PS1.mat(null, Color(0.75, 0.68, 0.62))
	var neck := PS1.cylinder(0.05, 0.75, skin, 5)
	neck.position.y = 1.85
	add_child(neck)
	_arm_len = 1.2
	for s in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(s * 0.25, 1.45, 0.05)
		pivot.rotation.z = s * 0.1
		add_child(pivot)
		var arm := PS1.prism(Vector3(0.06, 1.1, 0.06), skin, 0.2, 0.8)
		arm.position.y = -0.55
		pivot.add_child(arm)
		if s > 0:
			_arm_pivot = pivot
		else:
			# stickor i vänsterhanden
			_needles = Node3D.new()
			_needles.position = Vector3(0, -1.1, 0.08)
			pivot.add_child(_needles)
			var nm := PS1.mat(null, Color(0.8, 0.8, 0.85), Vector2.ONE, 0.3)
			for a in [0.5, -0.5]:
				var n := PS1.box(Vector3(0.012, 0.012, 0.35), nm)
				n.rotation.y = a
				_needles.add_child(n)
			var yarn := PS1.sphere(0.06, PS1.mat(null, Color(0.7, 0.1, 0.1)), 5, 3)
			yarn.position = Vector3(0, -0.06, 0.05)
			_needles.add_child(yarn)
	_head = Node3D.new()
	_head.position.y = 2.25
	add_child(_head)
	var skull := PS1.sphere(0.17, skin, 6, 4)
	skull.scale = Vector3(1, 1.2, 1)
	skull.position.y = 0.12
	_head.add_child(skull)
	var hair := PS1.sphere(0.18, PS1.mat(null, Color(0.85, 0.85, 0.82)), 6, 3)
	hair.position = Vector3(0, 0.2, -0.04)
	hair.scale = Vector3(1, 0.7, 1)
	_head.add_child(hair)
	# blomsterkrans
	var cols := [Color(1, 0.9, 0.2), Color(0.9, 0.2, 0.6), Color(0.5, 0.6, 1.0), Color(1, 1, 1)]
	for i in 10:
		var a := TAU * i / 10.0
		var f := PS1.box(Vector3(0.05, 0.035, 0.05), PS1.mat(null, cols[i % cols.size()], Vector2.ONE, 0.4))
		f.position = Vector3(cos(a) * 0.17, 0.3, sin(a) * 0.17)
		_head.add_child(f)
	# för stort leende och små svarta ögon
	var dark := PS1.mat(null, Color(0.02, 0.0, 0.0))
	for ex in [-0.06, 0.06]:
		var eye := PS1.box(Vector3(0.03, 0.02, 0.01), dark)
		eye.position = Vector3(ex, 0.16, 0.165)
		_head.add_child(eye)
	var smile := PS1.box(Vector3(0.16, 0.02, 0.01), PS1.mat(null, Color(0.4, 0.02, 0.04)))
	smile.position = Vector3(0, 0.05, 0.17)
	_head.add_child(smile)


func _process(dt: float) -> void:
	super._process(dt)
	if _needles:
		_needles.rotation.x = sin(_t * 9.0) * 0.25  # hon stickar hela tiden
