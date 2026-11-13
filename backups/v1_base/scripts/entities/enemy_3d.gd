extends CharacterBody3D
class_name Enemy3D

signal enemy_killed(is_boss: bool, pos: Vector3)

var is_boss: bool = false
var boss_name: String = ""
var max_health: float = 100.0
var health: float = 100.0
var speed: float = 4.2
var detection_range: float = 28.0
var state: String = "PATROL"  # PATROL, CHASE
var patrol_dir: float = 1.0
var origin_pos: Vector3 = Vector3.ZERO
var anim_phase: float = 0.0
var shoot_timer: float = 0.0

var rig: Dictionary = {}

func setup(pos: Vector3, boss: bool = false, b_name: String = "") -> void:
	global_position = pos
	origin_pos = pos
	is_boss = boss
	boss_name = b_name
	if is_boss:
		max_health = 320.0
		health = 320.0
		speed = 4.8
		detection_range = 36.0

func _ready() -> void:
	add_to_group("enemy")
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.9
	col.shape = cap
	col.position = Vector3(0, 0.95, 0)
	add_child(col)

	rig = ModelBuilder.build_character_rig("enemy", "", 0, is_boss)
	var weapon_mesh := ModelBuilder.build_weapon_mesh("m4" if is_boss else "pistol")
	rig["weapon_mount"].add_child(weapon_mesh)
	rig["right_arm"].rotation_degrees.x = 75.0
	add_child(rig["root"])

func take_damage(amount: float) -> void:
	if health <= 0:
		return
	health -= amount
	state = "CHASE"
	AudioManager.play_sfx("hit")
	if health <= 0:
		enemy_killed.emit(is_boss, global_position)
		queue_free()

func get_hit_by_vehicle(impulse: Vector3) -> void:
	take_damage(impulse.length() * 14.0)

func _physics_process(delta: float) -> void:
	if health <= 0:
		return

	if shoot_timer > 0.0:
		shoot_timer -= delta

	if not is_on_floor():
		velocity.y -= 18.0 * delta

	var players := get_tree().get_nodes_in_group("player")
	var target: Node3D = players[0] as Node3D if players.size() > 0 else null

	if target and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		var eff_range := detection_range
		if bool(target.get("is_crouched")):
			eff_range *= 0.45

		if dist < eff_range and abs(target.global_position.y - global_position.y) < 6.0:
			if state != "CHASE":
				AudioManager.play_sfx("alert", -5.0)
			state = "CHASE"

		if state == "CHASE":
			var to_target := target.global_position - global_position
			to_target.y = 0
			if to_target.length() > 0.1:
				var target_yaw := atan2(-to_target.x, -to_target.z)
				rotation.y = lerp_angle(rotation.y, target_yaw, 0.15)

			if dist > 11.0 and abs(target.global_position.y - global_position.y) < 3.0:
				var move_dir := to_target.normalized()
				velocity.x = move_dir.x * speed
				velocity.z = move_dir.z * speed
				_animate_walk(delta)
			else:
				velocity.x = 0
				velocity.z = 0

			if dist < 38.0 and shoot_timer <= 0.0:
				shoot_timer = 0.85 if is_boss else 1.25
				_fire_at(target.global_position + Vector3(0, 1.2, 0))
		else:
			_patrol(delta)
	else:
		_patrol(delta)

	move_and_slide()

func _patrol(delta: float) -> void:
	velocity.x = patrol_dir * 2.2
	velocity.z = 0
	rotation.y = -PI / 2.0 if patrol_dir > 0 else PI / 2.0
	if abs(global_position.x - origin_pos.x) > 10.0 or is_on_wall():
		patrol_dir *= -1.0
	_animate_walk(delta)

func _animate_walk(delta: float) -> void:
	anim_phase += delta * 8.0
	var swing := sin(anim_phase) * 0.55
	rig["left_leg"].rotation.x = swing
	rig["right_leg"].rotation.x = -swing

func _fire_at(target_pos: Vector3) -> void:
	AudioManager.play_sfx("shoot_tactical", -6.0)
	var origin := global_position + Vector3(0, 1.35, 0) + (-global_transform.basis.z * 0.8)
	var dir := (target_pos - origin).normalized()
	var p := Projectile3D.new()
	p.setup(origin, dir, 16.0 if is_boss else 11.0, 42.0, false, "Enemy")
	get_parent().add_child(p)
