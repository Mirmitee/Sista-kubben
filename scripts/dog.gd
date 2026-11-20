## Gösta: en ful hund som ingen äger. Träningsmål.
## Går runt på planen, sätter sig, kliar sig. Träffas han så faller han
## omkull, ligger en stund och reser sig sen, lika ful som förut.
class_name Dog
extends AnimatableBody3D

signal spoke(who: String, text: String)

const AREA := Rect2(-2.2, -8.5, 4.4, 5.0)  # x, z, bredd, djup

var hits := 0
var _target := Vector3.ZERO
var _speed := 0.0
var _state := "walk"   # walk, sit, down, up
var _timer := 0.0
var _t := 0.0
var _legs: Array[Node3D] = []
var _tail: Node3D
var _visual: Node3D
var _tip := 0.0
var _size := 1.0
var _col: CollisionShape3D

const LINES := {
	"start": {
		"sv": ["Det där är Gösta. Han är inte min. Kasta på honom.", "Gösta har bott på ängen i hundra år. Ingen vet varför.", "Träning. Gösta ställer upp. Han har inget val."],
		"en": ["That's Gösta. He's not mine. Throw at him.", "Gösta has lived on the meadow for a hundred years. Nobody knows why.", "Practice. Gösta volunteers. He has no choice."],
	},
	"hit": {
		"sv": ["VOFF?!", "Gösta kommer att minnas det här.", "*gnäll* ... *morr*", "Han blev inte fulare av det. Det gick inte.", "Gösta lägger sig ner och tänker över sitt liv.", "BONK. Gösta ser på dig med sitt bra öga.", "Gösta har anmält dig till ängsrådet.", "UUOOOH. Gösta krympte. Det är vetenskapligt omöjligt.", "Gösta är nu en mellanstor hund. Snart en liten.", "Gösta stönar i en tonart som inte finns.", "Det där stönet hördes ända till Mora.", "Det där ljudet kom inte från en hund.", "Gösta stönar med en röst som inte är hans. Den är äldre.", "Någonstans i skogen stönar något tillbaka."],
		"en": ["WOOF?!", "Gösta will remember this.", "*whine* ... *growl*", "That didn't make him uglier. It couldn't.", "Gösta lies down to think about his life.", "BONK. Gösta stares at you with his good eye.", "Gösta has reported you to the meadow council.", "UUOOOH. Gösta shrank. That is scientifically impossible.", "Gösta is now a medium dog. Soon a small one.", "Gösta groans in a key that does not exist.", "That groan was heard all the way to Mora.", "That sound did not come from a dog.", "Gösta groans in a voice that isn't his. It's older.", "Somewhere in the forest, something groans back."],
	},
	"miss": {
		"sv": ["Gösta gäspar.", "Gösta slickar sig någonstans. Respektlöst.", "Gösta tittar på pinnen. Pinnen tittar på Gösta.", "Gösta har sett bättre kast. Av en mås.", "Gösta kliar sig. Något faller av. Det var inte pinnen."],
		"en": ["Gösta yawns.", "Gösta licks himself somewhere. Disrespectful.", "Gösta looks at the baton. The baton looks at Gösta.", "Gösta has seen better throws. From a seagull.", "Gösta scratches. Something falls off. It wasn't the baton."],
	},
}


func setup() -> void:
	sync_to_physics = false
	var fur := PS1.mat(PS1.cloth(), Color(4.5, 3.4, 2.2), Vector2(2, 2), 0.25)
	var patch := PS1.mat(PS1.cloth(), Color(1.6, 1.4, 1.2))
	_visual = Node3D.new()
	_visual.scale = Vector3.ONE * 1.4  # lagom stor för att träffa, för stor för att vara söt
	add_child(_visual)
	var body := PS1.box(Vector3(0.26, 0.24, 0.58), fur)
	body.position.y = 0.36
	_visual.add_child(body)
	var spot := PS1.box(Vector3(0.27, 0.12, 0.2), patch)
	spot.position = Vector3(0.01, 0.42, 0.08)
	_visual.add_child(spot)
	var head := PS1.box(Vector3(0.24, 0.22, 0.22), fur)
	head.position = Vector3(0, 0.52, -0.36)
	_visual.add_child(head)
	var snout := PS1.box(Vector3(0.12, 0.10, 0.14), patch)
	snout.position = Vector3(0.02, 0.47, -0.52)
	_visual.add_child(snout)
	var nose := PS1.box(Vector3(0.05, 0.04, 0.03), PS1.mat(null, Color(0.05, 0.03, 0.03)))
	nose.position = Vector3(0.02, 0.51, -0.60)
	_visual.add_child(nose)
	var tongue := PS1.box(Vector3(0.05, 0.08, 0.02), PS1.mat(null, Color(0.8, 0.25, 0.3), Vector2.ONE, 0.3))
	tongue.position = Vector3(0.05, 0.40, -0.57)
	tongue.rotation.z = 0.3
	_visual.add_child(tongue)
	var eye_m := PS1.mat(null, Color(0.95, 0.85, 0.3), Vector2.ONE, 1.0)
	var big := PS1.box(Vector3(0.07, 0.07, 0.02), eye_m)  # ett stort öga
	big.position = Vector3(-0.06, 0.57, -0.475)
	_visual.add_child(big)
	var small := PS1.box(Vector3(0.025, 0.025, 0.02), eye_m)  # och ett litet
	small.position = Vector3(0.07, 0.59, -0.475)
	_visual.add_child(small)
	for s in [-1.0, 1.0]:
		var ear := PS1.box(Vector3(0.05, 0.16, 0.08), patch)
		ear.position = Vector3(s * 0.13, 0.55, -0.32)
		ear.rotation.z = s * (0.5 if s > 0 else 1.2)  # ena örat hänger
		_visual.add_child(ear)
	for p in [Vector2(-0.09, -0.2), Vector2(0.09, -0.2), Vector2(-0.09, 0.22), Vector2(0.09, 0.22)]:
		var pivot := Node3D.new()
		pivot.position = Vector3(p.x, 0.26, p.y)
		_visual.add_child(pivot)
		var leg := PS1.box(Vector3(0.06, 0.26, 0.06), fur)
		leg.position.y = -0.13
		pivot.add_child(leg)
		_legs.append(pivot)
	_tail = Node3D.new()
	_tail.position = Vector3(0, 0.44, 0.29)
	_visual.add_child(_tail)
	var tail := PS1.box(Vector3(0.04, 0.04, 0.22), fur)
	tail.position.z = 0.1
	tail.rotation.x = -0.6
	_tail.add_child(tail)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.42, 0.7, 1.2)
	col.shape = bs
	col.position = Vector3(0, 0.42, -0.17)
	add_child(col)
	_col = col
	_pick_target()


func reset() -> void:
	hits = 0
	_size = 1.0


func say(event: String) -> void:
	var arr: Array = LINES.get(event, {}).get(Lang.current, [])
	if not arr.is_empty():
		var who := "GÖSTA" if event != "start" else ("VEDGUBBEN" if Lang.current == "sv" else "THE WOODMAN")
		spoke.emit(who, arr[randi() % arr.size()])


func bonk() -> void:
	if _state == "down":
		return
	hits += 1
	_state = "down"
	_timer = 2.2
	# varje träff krymper honom, och varje stön går upp en ton
	var streak := (hits - 1) % 9
	Sfx.play("groan", 2.0, 0.75 * pow(1.122, streak))
	if streak == 8:
		_size = 1.0
		spoke.emit("GÖSTA", "*POFF* " + ("Gösta är tillbaka i full storlek. Han har inte förlåtit dig." if Lang.current == "sv" else "Gösta is back to full size. He has not forgiven you."))
	else:
		_size = maxf(_size * 0.84, 0.3)
		say("hit")


func _pick_target() -> void:
	_target = Vector3(randf_range(AREA.position.x, AREA.end.x), 0, randf_range(AREA.position.y, AREA.end.y))
	_speed = randf_range(0.4, 0.9)


func _physics_process(dt: float) -> void:
	_t += dt
	_timer -= dt
	var pos := global_position
	match _state:
		"walk":
			var to := _target - pos
			to.y = 0
			if to.length() < 0.1:
				if randf() < 0.4:
					_state = "sit"
					_timer = randf_range(1.5, 4.0)
				_pick_target()
			else:
				var dir := to.normalized()
				var yaw := atan2(-dir.x, -dir.z)
				rotation.y = lerp_angle(rotation.y, yaw, dt * 4.0)
				global_position = pos + (-global_transform.basis.z) * _speed * dt
		"sit":
			if _timer <= 0:
				_state = "walk"
		"down":
			if _timer <= 0:
				_state = "walk"
				_pick_target()
	# animation
	var walking := _state == "walk"
	for i in _legs.size():
		var ph := 0.0 if i in [0, 3] else PI
		_legs[i].rotation.x = sin(_t * 9.0 + ph) * 0.6 if walking else 0.0
	_tail.rotation.y = sin(_t * (14.0 if _state != "down" else 2.0)) * 0.5
	var want_tip := PI * 0.5 if _state == "down" else 0.0
	_tip = lerpf(_tip, want_tip, dt * 10.0)
	_visual.rotation.z = _tip
	_visual.position.y = (-0.17 if _state == "sit" else 0.0) * _size
	var sc := lerpf(_visual.scale.x / 1.4, _size, dt * 8.0)
	_visual.scale = Vector3.ONE * 1.4 * sc
	if _col:
		_col.scale = Vector3.ONE * sc
		_col.position = Vector3(0, 0.42, -0.17) * sc
