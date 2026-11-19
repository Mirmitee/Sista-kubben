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


func setup() -> void:
	mass = 0.32
	add_child(PS1.cylinder(RADIUS, LENGTH, PS1.mat(PS1.wood(5, Color(0.70, 0.55, 0.38)), Color.WHITE, Vector2(1, 2))))
	var band := PS1.cylinder(RADIUS * 1.08, 0.04, PS1.mat(null, Color(0.55, 0.06, 0.05)))
	band.position.y = LENGTH * 0.5 - 0.03
	add_child(band)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = RADIUS
	cap.height = LENGTH
	col.shape = cap
	add_child(col)
	var pm := PhysicsMaterial.new()
	pm.friction = 0.6
	pm.bounce = 0.15
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
