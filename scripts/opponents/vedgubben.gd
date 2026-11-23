## Vedgubben: lång, tyst, huvud av snidat trä. Första motståndaren.
## Specialregel (kommer sen): kubbar han fäller blir stubbar.
extends Opponent


func _init() -> void:
	display_name = {"sv": "VEDGUBBEN", "en": "THE WOODMAN"}
	error_yaw = 0.022
	error_speed = 0.035
	rule_text = {"sv": "Natt 2 och 3: han stirrar på dig. Precisionsmarkören går 15 % fortare.",
		"en": "Nights 2 and 3: he stares at you. The accuracy cursor is 15% faster."}
	lines = {
		"steal": {"sv": ["Dina poäng smakar sav. Jag tar dem.", "Varje kubb du tappar blir en årsring i mig.", "Tack. Jag samlar på sånt.", "Jag tar poängen och lägger dem i min stubbe."], "en": ["Your points taste of sap. I'll take them.", "Every kubb you lose becomes a ring in me.", "Thank you. I collect those.", "I take the points and keep them in my stump."]},
		"big_score": {"sv": ["Det knakade i mig. Det var inte bra.", "Så många siffror. Mina rötter skakar.", "Du räknar som en hackspett. Fort och smärtsamt."], "en": ["Something creaked in me. That was not good.", "So many numbers. My roots are shaking.", "You count like a woodpecker. Fast and painful."]},
		"night": {"sv": ["Känner du vädret? Jag gör det. I hela veden.", "Natten har ändrat sig. Det har inte jag."], "en": ["Do you feel the weather? I do. In all my wood.", "The night has changed. I have not."]},
		"last_words": {"sv": ["Jag... blir... bark...", "Plantera mig... någon annanstans..."], "en": ["I... become... bark...", "Plant me... somewhere else..."]},
		"chatter": {"sv": ["Jag var en gång ett träd. Sen blev jag det här. Det var inte en uppgradering.", "Har du sett min yxa? Inte för att jag vill ha den.", "Månen gillar dig inte. Jag gillar dig inte. Gräset är neutralt.", "Midsommar är bara en dag. Den här natten är längre.", "Mina kubbar har namn. Ingen av dem vill säga dem."], "en": ["I was a tree once. Then I became this. It was not an upgrade.", "Have you seen my axe? Not that I want it.", "The moon doesn't like you. I don't like you. The grass is neutral.", "Midsummer is only one day. This night is longer.", "My kubbs have names. None of them will say them."]},
		"start": {
			"sv": ["Kasta då. Jag har stått här sen 1700-talet.", "Välkommen till ängen. Ingen går hem.", "Glad midsommar. Ta en pinne.", "Sex pinnar. Fem kubbar. En kung. Noll chans.", "Har du ätit sill? Det märks.", "Jag har väntat på dig. Inte länge. Bara i trehundra år."],
			"en": ["Throw, then. I've stood here since the 1700s.", "Welcome to the meadow. Nobody goes home.", "Happy midsummer. Take a baton.", "Six batons. Five kubbs. One king. Zero chance.", "Have you eaten herring? I can tell.", "I've been waiting for you. Not long. Just three hundred years."],
		},
		"miss": {
			"sv": ["Nära. Nej förresten, inte alls nära.", "Gräset tackar för pinnen.", "Min mormor kastar bättre. Hon är en stubbe.", "Hm.", "Du siktade väl inte på den där?", "Pinnen ville inte. Jag förstår den.", "Ännu en pinne i gräset. Snart har vi ett staket."],
			"en": ["Close. Actually no, not close at all.", "The grass thanks you for the baton.", "My grandmother throws better. She is a stump.", "Hm.", "You weren't aiming at that, were you?", "The baton didn't want to. I understand it.", "Another baton in the grass. Soon we'll have a fence."],
		},
		"close": {
			"sv": ["Den nuddade nästan. Kubben svimmade nästan.", "Så nära. Kubben svettas.", "Jag hörde den viska 'puh'."],
			"en": ["That almost touched. The kubb almost fainted.", "So close. The kubb is sweating.", "I heard it whisper 'phew'."],
		},
		"short": {
			"sv": ["Kort. Som min tålamodstråd. Nej, den är lång. Tyvärr.", "Pinnen tröttnade halvvägs.", "Kasta längre. Vi bor inte här. Jo, jag gör det."],
			"en": ["Short. Like my patience. No, that's long. Sadly.", "The baton got tired halfway.", "Throw further. We don't live here. Well, I do."],
		},
		"long": {
			"sv": ["Den flög till grannbyn. De vill inte ha den heller.", "För långt! Nu måste någon hämta den. Inte jag.", "Fint kast. Fel kommun."],
			"en": ["That went to the next village. They don't want it either.", "Too far! Now someone has to fetch it. Not me.", "Nice throw. Wrong municipality."],
		},
		"hit": {
			"sv": ["Aj. Det där var min kusin.", "Du kommer att få höra om det här.", "Han hade familj.", "Okej. Okej okej okej.", "Den där kubben var nittio år. Grattis.", "KLONK. Låter som min rygg.", "Bra. Nu är jag lite arg."],
			"en": ["Ouch. That was my cousin.", "You'll be hearing about this.", "He had a family.", "Okay. Okay okay okay.", "That kubb was ninety years old. Congratulations.", "CLONK. Sounds like my back.", "Good. Now I'm slightly angry."],
		},
		"double": {
			"sv": ["Två på en gång?! Fusk. Jag gillar det.", "Det där var inte snällt.", "Två! Jag ringer min advokat. Han är en uggla."],
			"en": ["Two at once?! Cheating. I like it.", "That was not nice.", "Two! I'm calling my lawyer. He's an owl."],
		},
		"helicopter": {
			"sv": ["Helikopterkast! Förbjudet, och dessutom fult.", "Snurra inte pinnen så. Den blir yr.", "Det här är kubb, inte cirkus.", "Helikopter. Vi ställer tillbaka allt och låtsas att det aldrig hände."],
			"en": ["Helicopter throw! Illegal, and also ugly.", "Don't spin the baton like that. It gets dizzy.", "This is kubb, not the circus.", "Helicopter. We put everything back and pretend it never happened."],
		},
		"drop": {
			"sv": ["Du tappade pinnen. Klassiskt.", "Den ville inte följa med dig.", "Svep UPP. Upp är åt himlen. Där månen är."],
			"en": ["You dropped the baton. Classic.", "It didn't want to go with you.", "Swipe UP. Up is towards the sky. Where the moon is."],
		},
		"sky": {
			"sv": ["Siktar du på månen? Den är upptagen.", "Fel håll.", "Den kommer ner. Någon gång. Kanske på dig."],
			"en": ["Aiming at the moon? It's busy.", "Wrong way.", "It'll come down. Eventually. Maybe on you."],
		},
		"idle": {
			"sv": ["Jag har hela natten på mig. Bokstavligen.", "Kasta, eller gå hem. Fast du kan inte gå hem.", "Jag räknar dina andetag. Du är på sexhundra.", "Somnade du? Jag sover aldrig."],
			"en": ["I have all night. Literally.", "Throw, or go home. Though you can't go home.", "I'm counting your breaths. You're at six hundred.", "Did you fall asleep? I never sleep."],
		},
		"king_early": {
			"sv": ["Du fällde kungen. Han var min pappa.", "Kungen faller sist. Alla vet det. Nu vet du det."],
			"en": ["You felled the king. He was my father.", "The king falls last. Everyone knows. Now you know."],
		},
		"king_death": {
			"sv": ["...du rörde honom.", "Nej. Nej nej nej. Inte kungen.", "Det där borde du inte ha gjort."],
			"en": ["...you touched him.", "No. No no no. Not the king.", "You shouldn't have done that."],
		},
		"effect": {
			"sv": ["Vad var det där?! Det står inte i reglerna.", "Mina kubbar ska inte explodera. Det är min grej.", "Fusk! Vackert, men fusk.", "Jag kände det i mina årsringar."],
			"en": ["What was that?! That's not in the rules.", "My kubbs aren't supposed to explode. That's my thing.", "Cheating! Beautiful, but cheating.", "I felt that in my growth rings."],
		},
		"advance": {
			"sv": ["Dina fältkubbar står kvar. Då kliver jag närmare. Hej.", "Ett steg fram. Jag luktar mossa nu, va?", "Närmare. Alltid närmare."],
			"en": ["Your field kubbs still stand. So I step closer. Hello.", "One step forward. I smell of moss now, don't I?", "Closer. Always closer."],
		},
		"my_turn": {
			"sv": ["Min tur. Stå still. Det gör ont mindre då.", "Nu kastar jag. Jag har övat sen svartedöden.", "Titta inte. Eller titta. Det spelar ingen roll."],
			"en": ["My turn. Stand still. It hurts less.", "Now I throw. I've practised since the Black Death.", "Don't look. Or look. It doesn't matter."],
		},
		"opp_hit": {
			"sv": ["Klonk. Det lät som din framtid.", "En till ditt hål i marken.", "Jag är bättre än jag ser ut. Jag ser ut som en vedtrave."],
			"en": ["Clonk. That sounded like your future.", "Another one for your hole in the ground.", "I'm better than I look. I look like a woodpile."],
		},
		"opp_miss": {
			"sv": ["Det var vinden.", "Jag missade med flit. Av medlidande.", "Mina fingrar är av björk. De är stela."],
			"en": ["That was the wind.", "I missed on purpose. Out of pity.", "My fingers are birch. They're stiff."],
		},
		"toss": {
			"sv": ["Här, ta dina kubbar. Jag vill inte ha dem.", "Fältkubbar till dig. Med kärlek. Nej."],
			"en": ["Here, take your kubbs. I don't want them.", "Field kubbs for you. With love. No."],
		},
		"opp_king_death": {
			"sv": ["...jag rörde kungen. Jag rörde min egen pappa. Du vinner.", "Nej. Jag har förlorat. Säg inget till mamma."],
			"en": ["...I touched the king. I touched my own father. You win.", "No. I lost. Don't tell mother."],
		},
		"lose": {
			"sv": ["Sådär. Nu är du en av oss. Ta en plats på ängen.", "Kungen faller. Du också."],
			"en": ["There. Now you're one of us. Take a spot on the meadow.", "The king falls. So do you."],
		},
		"king_simple": {
			"sv": ["Kungen reser sig. Han är förlåtande. Ikväll.", "Vi låtsas att det där inte hände. Förenklade regler, för förenklade människor."],
			"en": ["The king gets back up. He's forgiving. Tonight.", "We'll pretend that didn't happen. Simplified rules, for simplified people."],
		},
		"all_down": {
			"sv": ["Alla mina... barn...", "Nu är det bara han kvar."],
			"en": ["All my... children...", "Now only he remains."],
		},
		"round_zero": {
			"sv": ["Noll. Jag ska rista in det i min panna.", "Inte en enda. Jag är nästan imponerad."],
			"en": ["Zero. I'll carve it into my forehead.", "Not a single one. I'm almost impressed."],
		},
		"king_win": {
			"sv": ["Nästa midsommar. Samma äng.", "Du får behålla dina tänder. Den här gången."],
			"en": ["Next midsummer. Same meadow.", "You may keep your teeth. This time."],
		},
	}


func mods_for_night(night: int) -> Dictionary:
	return {"acc_time_mult": 0.85} if night >= 2 else {}


func _ready() -> void:
	var robe := PS1.mat(PS1.cloth(), Color(0.8, 0.75, 0.75), Vector2(2, 4))
	var body := PS1.cylinder(0.42, 2.1, robe, 6, 0.22)
	body.position.y = 1.05
	add_child(body)
	var bark := PS1.mat(PS1.wood(21, Color(0.45, 0.36, 0.27)))
	_arm_len = 1.7
	for s in [-1.0, 1.0]:  # alldeles för långa armar
		var pivot := Node3D.new()
		pivot.position = Vector3(s * 0.38, 2.0, 0.05)
		pivot.rotation.z = s * 0.06
		add_child(pivot)
		var arm := PS1.prism(Vector3(0.09, 1.55, 0.09), bark, 0.2, 0.8)
		arm.position.y = -0.78
		pivot.add_child(arm)
		var fingers := PS1.prism(Vector3(0.12, 0.22, 0.05), bark, 0.2, 0.8)
		fingers.position.y = -1.62
		pivot.add_child(fingers)
		if s > 0:
			_arm_pivot = pivot
	_head = Node3D.new()
	_head.position.y = 2.15
	add_child(_head)
	var skull := PS1.box(Vector3(0.48, 0.66, 0.44), PS1.mat(PS1.wood(13, Color(0.55, 0.45, 0.33))))
	skull.position.y = 0.33
	_head.add_child(skull)
	var face := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.46, 0.6)
	face.mesh = q
	face.material_override = PS1.mat(PS1.face())
	face.position = Vector3(0, 0.33, 0.222)
	_head.add_child(face)
	var glow := PS1.mat(null, Color(1.0, 0.15, 0.08), Vector2.ONE, 1.0)
	for ex in [-0.10, 0.12]:
		var eye := PS1.box(Vector3(0.025, 0.025, 0.01), glow)
		eye.position = Vector3(ex, 0.41, 0.228)
		_head.add_child(eye)
