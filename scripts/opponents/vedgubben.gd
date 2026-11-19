## Vedgubben: lång, tyst, huvud av snidat trä. Första motståndaren.
## Specialregel (kommer sen): kubbar han fäller blir stubbar.
extends Opponent


func _init() -> void:
	display_name = {"sv": "VEDGUBBEN", "en": "THE WOODMAN"}
	lines = {
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


func _ready() -> void:
	var robe := PS1.mat(PS1.cloth(), Color(0.8, 0.75, 0.75), Vector2(2, 4))
	var body := PS1.cylinder(0.42, 2.1, robe, 6, 0.22)
	body.position.y = 1.05
	add_child(body)
	var bark := PS1.mat(PS1.wood(21, Color(0.45, 0.36, 0.27)))
	for s in [-1.0, 1.0]:  # alldeles för långa armar
		var arm := PS1.box(Vector3(0.09, 1.55, 0.09), bark)
		arm.position = Vector3(s * 0.38, 1.25, 0.05)
		arm.rotation.z = s * 0.08
		add_child(arm)
		var fingers := PS1.box(Vector3(0.12, 0.22, 0.05), bark)
		fingers.position = Vector3(s * 0.44, 0.40, 0.05)
		add_child(fingers)
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
