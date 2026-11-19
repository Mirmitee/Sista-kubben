## En kubb (7x7x15 cm) eller kungen (9x9x30 cm), med riktig fysik.
class_name Kubb
extends RigidBody3D

## när kubben slår i något med viss fart (för ljud)
signal landed(speed: float)

const SIZE := Vector3(0.07, 0.15, 0.07)
const KING_SIZE := Vector3(0.09, 0.30, 0.09)

var is_king := false
var home: Transform3D
var was_fallen := false
var side := "theirs"      # planhalvan den står på: "theirs" eller "mine"
var field := false        # fältkubb (inkastad) eller baslinjekubb
var in_flight := false
var touched := false
var kind := ""            # specialkubb ur kubbleken ("" = vanlig)
var _seed := 1
var _mesh: MeshInstance3D
var _rune: Node3D
var _cap: MeshInstance3D


func setup(king: bool, seed := 1) -> void:
	is_king = king
	var size := KING_SIZE if king else SIZE
	mass = 1.7 if king else 0.3
	# tyngdpunkten lite högt upp gör kubbarna lättare att välta
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, size.y * 0.18, 0)
	var tint := Color(1.25, 1.15, 1.05) if king else Color(1.2, 1.15, 1.1)
	# lite självlysande så de syns i skymningen (som att de fångar månljuset)
	_seed = seed
	_mesh = PS1.box(size, PS1.mat(PS1.wood(seed), tint, Vector2.ONE, 0.35))
	add_child(_mesh)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	add_child(col)
	var pm := PhysicsMaterial.new()
	pm.friction = 0.4
	pm.bounce = 0.12
	physics_material_override = pm
	can_sleep = true
	contact_monitor = true
	max_contacts_reported = 2
	body_entered.connect(func(_b):
		touched = true
		var v := linear_velocity.length()
		if v > 0.5:
			landed.emit(v))
	if king:
		# krona av fyra pinnar och en spets
		var cm := PS1.mat(PS1.wood(9, Color(0.75, 0.58, 0.30)))
		for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var p := PS1.box(Vector3(0.022, 0.035, 0.022), cm)
			p.position = Vector3(c.x * 0.032, size.y * 0.5 + 0.017, c.y * 0.032)
			add_child(p)
		var tip := PS1.box(Vector3(0.03, 0.05, 0.03), PS1.mat(null, Color(0.6, 0.08, 0.06)))
		tip.position = Vector3(0, size.y * 0.5 + 0.025, 0)
		add_child(tip)


func height() -> float:
	return (KING_SIZE if is_king else SIZE).y


func is_fallen() -> bool:
	return global_transform.basis.y.normalized().dot(Vector3.UP) < 0.71  # lutar mer än 45° = fälld


func teleport(t: Transform3D) -> void:
	PhysicsServer3D.body_set_state(get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, t)
	global_transform = t
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true


func go_home() -> void:
	teleport(home)
	was_fallen = false


# ---- när kubben kastas över till andra planhalvan

func hold() -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	collision_layer = 0
	collision_mask = 0
	in_flight = false


func launch(v: Vector3, w: Vector3) -> void:
	collision_layer = 1
	collision_mask = 1
	freeze = false
	touched = false
	linear_velocity = v
	angular_velocity = w
	in_flight = true


func is_settled() -> bool:
	return touched and linear_velocity.length() < 0.12 and angular_velocity.length() < 0.6


## Res kubben där den landade (som fältkubb).
func raise_at(p: Vector3) -> void:
	in_flight = false
	teleport(Transform3D(Basis(Vector3.UP, randf() * TAU), Vector3(p.x, height() * 0.5, p.z)))
	field = true


## Gör kubben till en specialkubb ur kubbleken (eller vanlig med "").
## Färgad ved, ett lysande runband och en topp i samma färg.
func set_kind(id: String, mass_mult := 1.0) -> void:
	kind = id
	if is_king:
		return
	var d: Dictionary = Cards.DEFS.get(id, {})
	var tint: Color = d.get("col", Color(1.2, 1.15, 1.1))
	_mesh.material_override = PS1.mat(PS1.wood(_seed), tint, Vector2.ONE, 0.35 if id == "" else 0.5)
	mass = 0.3 * float(d.get("mass", 1.0)) * mass_mult
	if _rune:
		_rune.queue_free()
		_rune = null
		_cap = null
	if id == "":
		return
	_rune = Node3D.new()
	add_child(_rune)
	var cursed: bool = d.get("cursed", false)
	var glow := Color(0.9, 0.2, 1.0) if cursed else (tint * 0.8).clamp(Color(0.25, 0.25, 0.25), Color(1, 1, 1))
	var rm := PS1.mat(null, glow, Vector2.ONE, 0.95)
	var band := PS1.box(Vector3(SIZE.x * 1.06, 0.016, SIZE.z * 1.06), rm)
	band.position.y = 0.025
	_rune.add_child(band)
	# märke ovanpå som visar vad kubben gör: träff = spets, fällning = platta
	var cap: MeshInstance3D
	if d.has("hit"):
		cap = PS1.box(Vector3(0.025, 0.03, 0.025), rm)
		cap.position.y = SIZE.y * 0.5 + 0.015
		cap.rotation = Vector3(0.6, 0.78, 0)
	else:
		cap = PS1.box(Vector3(0.05, 0.008, 0.05), rm)
		cap.position.y = SIZE.y * 0.5 + 0.004
	_rune.add_child(cap)
	_cap = cap


func _process(dt: float) -> void:
	if _cap and visible:
		_cap.rotate_y(dt * 2.2)  # specialkubbarnas märke snurrar sakta, de lever
