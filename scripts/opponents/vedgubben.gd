## Vedgubben: lång, tyst, huvud av snidat trä. Första motståndaren.
## Specialregel (kommer sen): kubbar han fäller blir stubbar.
extends Opponent


func _init() -> void:
	display_name = {"sv": "VEDGUBBEN", "en": "THE WOODMAN"}
	lines = {
		"start": {
			"sv": ["Kasta då. Jag har stått här sen 1700-talet.", "Välkommen till ängen. Ingen går hem.", "Glad midsommar. Ta en pinne."],
			"en": ["Throw, then. I've stood here since the 1700s.", "Welcome to the meadow. Nobody goes home.", "Happy midsummer. Take a baton."],
		},
		"miss": {
			"sv": ["Nära. Nej förresten, inte alls nära.", "Gräset tackar för pinnen.", "Min mormor kastar bättre. Hon är en stubbe.", "Hm."],
			"en": ["Close. Actually no, not close at all.", "The grass thanks you for the baton.", "My grandmother throws better. She is a stump.", "Hm."],
		},
		"hit": {
			"sv": ["Aj. Det där var min kusin.", "Du kommer att få höra om det här.", "Han hade familj.", "Okej. Okej okej okej."],
			"en": ["Ouch. That was my cousin.", "You'll be hearing about this.", "He had a family.", "Okay. Okay okay okay."],
		},
		"double": {
			"sv": ["Två på en gång?! Fusk. Jag gillar det.", "Det där var inte snällt."],
			"en": ["Two at once?! Cheating. I like it.", "That was not nice."],
		},
		"helicopter": {
			"sv": ["Helikopterkast! Förbjudet, och dessutom fult.", "Snurra inte pinnen så. Den blir yr.", "Det här är kubb, inte cirkus."],
			"en": ["Helicopter throw! Illegal, and also ugly.", "Don't spin the baton like that. It gets dizzy.", "This is kubb, not the circus."],
		},
		"drop": {
			"sv": ["Du tappade pinnen. Klassiskt.", "Den ville inte följa med dig."],
			"en": ["You dropped the baton. Classic.", "It didn't want to go with you."],
		},
		"sky": {
			"sv": ["Siktar du på månen? Den är upptagen.", "Fel håll."],
			"en": ["Aiming at the moon? It's busy.", "Wrong way."],
		},
		"king_early": {
			"sv": ["Du fällde kungen. Han var min pappa.", "Kungen faller sist. Alla vet det. Nu vet du det."],
			"en": ["You felled the king. He was my father.", "The king falls last. Everyone knows. Now you know."],
		},
		"all_down": {
			"sv": ["Alla mina... barn...", "Nu är det bara han kvar."],
			"en": ["All my... children...", "Now only he remains."],
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
