extends CharacterBody3D
class_name NPC3D

var walk_axis: String = "x"
var limits: Vector2 = Vector2(-40.0, 40.0)
var walk_dir: float = 1.0
var speed: float = 2.4
var outfit_id: int = 0
var is_alive: bool = true
var panic_timer: float = 0.0
var anim_phase: float = 0.0
var knockback_vel: Vector3 = Vector3.ZERO

var rig: Dictionary = {}

func setup(pos: Vector3, axis: String, lim: Vector2, outfit: int) -> void:
	global_position = pos
	walk_axis = axis
	limits = lim
	outfit_id = outfit

func _ready() -> void:
	add_to_group("civilian")
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)

	rig = ModelBuilder.build_character_rig("civilian", "", outfit_id)
	add_child(rig["root"])

func alert_panic(origin: Vector3) -> void:
	if not is_alive:
		return
	panic_timer = 5.0
	speed = 6.2
	if walk_axis == "x":
		walk_dir = 1.0 if global_position.x > origin.x else -1.0
	else:
		walk_dir = 1.0 if global_position.z > origin.z else -1.0

func get_hit_by_vehicle(impulse: Vector3) -> void:
	if not is_alive:
		return
	is_alive = false
	knockback_vel = impulse + Vector3(0, 5.5, 0)
	collision_layer = 0
	collision_mask = 1  # Solo suelo
	AudioManager.play_sfx("hit")

func _physics_process(delta: float) -> void:
	if not is_alive:
		knockback_vel.y -= 18.0 * delta
		velocity = knockback_vel
		move_and_slide()
		if is_on_floor():
			knockback_vel *= 0.85
			rig["root"].rotation_degrees.x = lerpf(rig["root"].rotation_degrees.x, 86.0, 0.25)
			rig["root"].position.y = lerpf(rig["root"].position.y, 0.2, 0.25)
		return

	if panic_timer > 0.0:
		panic_timer -= delta
		if panic_timer <= 0.0:
			speed = 2.4

	if not is_on_floor():
		velocity.y -= 18.0 * delta

	var move_vec := Vector3.ZERO
	if walk_axis == "x":
		move_vec.x = walk_dir * speed
		if global_position.x < limits.x or global_position.x > limits.y:
			walk_dir *= -1.0
		rotation.y = -PI / 2.0 if walk_dir > 0 else PI / 2.0
	else:
		move_vec.z = walk_dir * speed
		if global_position.z < limits.x or global_position.z > limits.y:
			walk_dir *= -1.0
		rotation.y = PI if walk_dir > 0 else 0.0

	velocity.x = move_vec.x
	velocity.z = move_vec.z
	move_and_slide()

	# Animación de caminata
	anim_phase += delta * (speed * 3.0)
	var swing := sin(anim_phase) * 0.55
	rig["left_leg"].rotation.x = swing
	rig["right_leg"].rotation.x = -swing
	rig["left_arm"].rotation.x = -swing * 0.7
	rig["right_arm"].rotation.x = swing * 0.7
