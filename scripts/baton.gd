## Kastpinne: 30 cm lång, 4,4 cm i diameter. Håller koll på helikopterkast.
class_name Baton
extends RigidBody3D

const LENGTH := 0.30
const RADIUS := 0.022
## Hur mycket pinnen får snurra runt lodlinjen (radianer) innan den
## räknas som helikopterkast. Riktiga kast snurrar ände över ände.
const HELI_LIMIT := PI * 0.8

var in_flight := false
var touched := false
var helicopter := false
var yaw_accum := 0.0
var air_time := 0.0
var release_pos := Vector3.ZERO
var first_contact := Vector3.ZERO
var first_hit: Node = null


var trail_color := Color(0.95, 0.8, 0.6)
var length := LENGTH


## Bygger pinnen. `id` = en pinne ur Cards.BATONS (utseende och fysik).
func setup(id := "vanlig") -> void:
	var d: Dictionary = Cards.BATONS.get(id, Cards.BATONS["vanlig"])
	mass = d.get("mass", 0.42)
	length = LENGTH * float(d.get("len", 1.0))
	var col: Color = d.get("col", Color.WHITE)
	var band_col: Color = d.get("band", Color(0.55, 0.06, 0.05))
	trail_color = d.get("trail", Color(0.95, 0.8, 0.6))
	var glow: float = d.get("glow", 0.0)
	gravity_scale = d.get("grav", 1.0)
	add_child(PS1.cylinder(RADIUS, length, PS1.mat(PS1.wood(5, Color(0.70, 0.55, 0.38)), col, Vector2(1, 2), glow * 0.6)))
	var band := PS1.cylinder(RADIUS * 1.08, 0.04, PS1.mat(null, band_col, Vector2.ONE, maxf(glow, 0.2)))
	band.position.y = length * 0.5 - 0.03
	add_child(band)
	if glow > 0.0:
		var b2 := PS1.cylinder(RADIUS * 1.08, 0.03, PS1.mat(null, band_col, Vector2.ONE, glow))
		b2.position.y = -length * 0.5 + 0.03
		add_child(b2)
	var col_shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = RADIUS
	cap.height = length
	col_shape.shape = cap
	add_child(col_shape)
	var pm := PhysicsMaterial.new()
	pm.friction = 0.6
	pm.bounce = d.get("bounce", 0.15)
	physics_material_override = pm
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 4
	linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	linear_damp = 0.02
	angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	angular_damp = 0.05
	body_entered.connect(_on_body_entered)


func hold() -> void:
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	collision_layer = 0
	collision_mask = 0


func launch(v: Vector3, w: Vector3) -> void:
	collision_layer = 1
	collision_mask = 1
	freeze = false
	linear_velocity = v
	angular_velocity = w
	in_flight = true
	release_pos = global_position


func _physics_process(dt: float) -> void:
	if in_flight and not touched:
		air_time += dt
		yaw_accum += absf(angular_velocity.y) * dt
		if yaw_accum > HELI_LIMIT:
			helicopter = true


func _on_body_entered(body: Node) -> void:
	if not touched:
		touched = true
		first_contact = global_position
		first_hit = body


func is_settled() -> bool:
	return touched and linear_velocity.length() < 0.12 and angular_velocity.length() < 0.5
