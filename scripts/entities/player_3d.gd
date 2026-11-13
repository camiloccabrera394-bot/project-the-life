extends CharacterBody3D
class_name Player3D

signal health_changed(hp, max_hp)
signal weapon_changed(weapon_dict)
signal prompt_changed(text)
signal player_died
signal payphone_called(first_line)

var char_id: String = "nagumo"
var max_health: float = 120.0
var health: float = 120.0
var base_speed: float = 7.2
var stealth_speed: float = 4.2
var is_crouched: bool = false

var weapons := []
var weapon_idx: int = 3  # Empieza con Fusil M4
var shoot_timer: float = 0.0
var anim_phase: float = 0.0

var rig: Dictionary = {}
var weapon_mesh: Node3D = null
var col_shape: CollisionShape3D
var col_capsule: CapsuleShape3D
var punch_timer: float = 0.0
var cam_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D

var cam_yaw: float = 0.0
var cam_pitch: float = deg_to_rad(-8.0)
var cam_dist_idx: int = 1  # 0 = Cerca, 1 = Media, 2 = Lejos
var cam_idle_timer: float = 0.0
var fire_face_timer: float = 0.0
var cur_shoulder_x: float = 0.42

var current_vehicle: Vehicle3D = null
var dialogue_locked: bool = false
var camera_shake: float = 0.0
var mouse_sens: float = 0.0028

func get_camera_yaw() -> float:
	return cam_yaw

func _ready() -> void:
	add_to_group("player")
	char_id = GameState.selected_char
	var cfg: Dictionary = GameState.CHARACTERS.get(char_id, GameState.CHARACTERS["nagumo"])
	max_health = cfg["health"]
	health = max_health
	base_speed = cfg["speed"]
	stealth_speed = cfg["stealth_speed"]

	# Inicializar inventario de 5 armas
	for w in GameState.WEAPONS_DATA:
		var copy_w: Dictionary = w.duplicate()
		copy_w["ammo_clip"] = w["clip"]
		copy_w["ammo_reserve"] = w["reserve"]
		weapons.append(copy_w)

	col_shape = CollisionShape3D.new()
	col_capsule = CapsuleShape3D.new()
	col_capsule.radius = 0.38
	col_capsule.height = 1.85
	col_shape.shape = col_capsule
	col_shape.position = Vector3(0, 0.925, 0)
	add_child(col_shape)

	rig = ModelBuilder.build_character_rig("player", char_id)
	add_child(rig["root"])

	# Cámara en Tercera Persona desacoplada (seguimiento fluido, cuerpo completo y colisión esférica)
	cam_yaw = rotation.y
	cam_pitch = deg_to_rad(-8.0)

	cam_pivot = Node3D.new()
	cam_pivot.top_level = true
	cam_pivot.global_position = global_position + Vector3(0.0, 1.24, 0.0)
	cam_pivot.rotation = Vector3(cam_pitch, cam_yaw, 0.0)
	add_child(cam_pivot)

	spring_arm = SpringArm3D.new()
	var cam_shape := SphereShape3D.new()
	cam_shape.radius = 0.24
	spring_arm.shape = cam_shape
	spring_arm.spring_length = 4.6
	spring_arm.collision_mask = 1
	spring_arm.margin = 0.14
	spring_arm.position = Vector3(cur_shoulder_x, 0.0, 0.0)
	spring_arm.add_excluded_object(get_rid())
	cam_pivot.add_child(spring_arm)

	camera = Camera3D.new()
	camera.fov = 58.0
	camera.far = 380.0
	camera.current = true
	spring_arm.add_child(camera)

	call_deferred("_capture_mouse")
	_equip_weapon(weapon_idx)

func _capture_mouse() -> void:
	if health > 0:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and health > 0:
		call_deferred("_capture_mouse")
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _equip_weapon(idx: int) -> void:
	weapon_idx = clampi(idx, 0, weapons.size() - 1)
	if weapon_mesh and is_instance_valid(weapon_mesh):
		weapon_mesh.queue_free()
	var w: Dictionary = weapons[weapon_idx]
	weapon_mesh = ModelBuilder.build_weapon_mesh(w["id"], char_id)
	rig["weapon_mount"].add_child(weapon_mesh)
	weapon_changed.emit(w)

func add_ammo(amount: int) -> void:
	for w in weapons:
		if not w["melee"]:
			w["ammo_reserve"] += (2 if w["id"] == "bazooka" else amount)
	weapon_changed.emit(weapons[weapon_idx])

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)

func take_damage(amount: float) -> void:
	if health <= 0:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	add_camera_shake(0.35)
	if health <= 0:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player_died.emit()

func add_camera_shake(amt: float) -> void:
	if SettingsManager.screen_shake:
		camera_shake = minf(1.2, camera_shake + amt)

func _input(event: InputEvent) -> void:
	if health <= 0:
		return

	if event is InputEventMouseMotion and not dialogue_locked:
		var is_captured: bool = (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
		var is_dragging: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
		if is_captured or is_dragging:
			cam_yaw -= event.relative.x * mouse_sens
			var pitch_min: float = deg_to_rad(-38.0) if current_vehicle else deg_to_rad(-48.0)
			var pitch_max: float = deg_to_rad(18.0) if current_vehicle else deg_to_rad(32.0)
			cam_pitch = clampf(cam_pitch - event.relative.y * mouse_sens, pitch_min, pitch_max)
			cam_idle_timer = 0.0

	elif event is InputEventMouseButton:
		if event.pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				AudioManager.play_sfx("click")
				_equip_weapon((weapon_idx - 1 + weapons.size()) % weapons.size())
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				AudioManager.play_sfx("click")
				_equip_weapon((weapon_idx + 1) % weapons.size())

	elif event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_1: AudioManager.play_sfx("click"); _equip_weapon(0)
		elif event.keycode == KEY_2: AudioManager.play_sfx("click"); _equip_weapon(1)
		elif event.keycode == KEY_3: AudioManager.play_sfx("click"); _equip_weapon(2)
		elif event.keycode == KEY_4: AudioManager.play_sfx("click"); _equip_weapon(3)
		elif event.keycode == KEY_5: AudioManager.play_sfx("click"); _equip_weapon(4)
		elif event.is_action_pressed("weapon_next"):
			AudioManager.play_sfx("click")
			_equip_weapon((weapon_idx + 1) % weapons.size())
		elif event.is_action_pressed("camera_distance"):
			cam_dist_idx = (cam_dist_idx + 1) % 3
			AudioManager.play_sfx("click", -6.0)

func _update_camera(delta: float) -> void:
	cam_idle_timer += delta

	# Efecto de temblor de cámara
	if camera_shake > 0.0:
		camera.h_offset = randf_range(-camera_shake, camera_shake) * 0.22
		camera.v_offset = randf_range(-camera_shake, camera_shake) * 0.22
		camera_shake = maxf(0.0, camera_shake - delta * 2.5)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0

	var target_dist: float = 4.6
	var target_fov: float = 58.0
	var target_shoulder_x: float = 0.42
	var target_anchor: Vector3 = global_position + Vector3(0.0, 1.24, 0.0)
	var follow_rate: float = 14.0

	if current_vehicle and is_instance_valid(current_vehicle):
		var is_moto: bool = (current_vehicle.v_type == "motorcycle")
		var spd_ratio: float = clampf(absf(current_vehicle.speed) / maxf(1.0, current_vehicle.max_speed), 0.0, 1.0)
		if absf(current_vehicle.speed) > 2.5 and cam_idle_timer > 1.35:
			cam_yaw = lerp_angle(cam_yaw, current_vehicle.rotation.y, minf(1.0, delta * 2.8))

		var moto_dists: Array[float] = [4.2, 5.4, 6.8]
		var car_dists: Array[float] = [5.4, 7.0, 8.8]
		var base_dist: float = moto_dists[cam_dist_idx] if is_moto else car_dists[cam_dist_idx]
		target_dist = base_dist + spd_ratio * 0.9
		target_fov = 62.0 + spd_ratio * 13.0
		target_shoulder_x = 0.0
		target_anchor = current_vehicle.global_position + Vector3(0.0, 1.42 if is_moto else 1.72, 0.0)
		follow_rate = 24.0
	else:
		var aiming: bool = Input.is_action_pressed("aim_mouse") and not dialogue_locked
		var foot_dists: Array[float] = [3.3, 4.6, 6.1]
		target_dist = 2.05 if aiming else foot_dists[cam_dist_idx]
		target_fov = 48.0 if aiming else 58.0
		target_shoulder_x = 0.62 if aiming else 0.42
		var crouch_drop: float = -0.35 if is_crouched else 0.0
		var pivot_h: float = (1.46 if aiming else 1.24) + crouch_drop
		target_anchor = global_position + Vector3(0.0, pivot_h, 0.0)
		follow_rate = 14.0

	# Salto instantáneo si el jugador se teletransporta (puerta interior o escalera de azotea)
	if cam_pivot.global_position.distance_to(target_anchor) > 8.0:
		cam_pivot.global_position = target_anchor
	else:
		var t_xz: float = 1.0 - exp(-follow_rate * delta)
		var t_y: float = 1.0 - exp(-(follow_rate * 0.72) * delta)
		cam_pivot.global_position.x = lerpf(cam_pivot.global_position.x, target_anchor.x, t_xz)
		cam_pivot.global_position.z = lerpf(cam_pivot.global_position.z, target_anchor.z, t_xz)
		cam_pivot.global_position.y = lerpf(cam_pivot.global_position.y, target_anchor.y, t_y)

	cam_pivot.rotation = Vector3(cam_pitch, cam_yaw, 0.0)

	# Evitar que el desplazamiento lateral al hombro atraviese paredes a la derecha
	var safe_shoulder: float = target_shoulder_x
	if safe_shoulder > 0.01:
		var cam_right: Vector3 = cam_pivot.global_transform.basis.x
		var space_state := get_world_3d().direct_space_state
		var r_query := PhysicsRayQueryParameters3D.create(
			cam_pivot.global_position,
			cam_pivot.global_position + cam_right * (safe_shoulder + 0.30),
			1
		)
		var ex_list: Array[RID] = [get_rid()]
		if current_vehicle and is_instance_valid(current_vehicle):
			ex_list.append(current_vehicle.get_rid())
		r_query.exclude = ex_list
		var hit := space_state.intersect_ray(r_query)
		if hit:
			var hit_pos: Vector3 = hit["position"] as Vector3
			safe_shoulder = maxf(0.0, cam_pivot.global_position.distance_to(hit_pos) - 0.30)

	var cam_lerp: float = 1.0 - exp(-12.0 * delta)
	cur_shoulder_x = lerpf(cur_shoulder_x, safe_shoulder, cam_lerp)
	spring_arm.position.x = cur_shoulder_x
	spring_arm.spring_length = lerpf(spring_arm.spring_length, target_dist, cam_lerp)
	camera.fov = lerpf(camera.fov, target_fov, cam_lerp)

func _physics_process(delta: float) -> void:
	if health <= 0:
		return

	_update_camera(delta)

	if dialogue_locked:
		return

	if shoot_timer > 0.0:
		shoot_timer -= delta
	if fire_face_timer > 0.0:
		fire_face_timer -= delta
	if punch_timer > 0.0:
		punch_timer -= delta

	# Si está conduciendo un vehículo
	if current_vehicle and is_instance_valid(current_vehicle):
		global_position = current_vehicle.global_position
		rotation.y = lerp_angle(rotation.y, current_vehicle.rotation.y, delta * 8.0)
		if Input.is_action_just_pressed("interact"):
			exit_vehicle()
		return

	# Gravedad
	if not is_on_floor():
		velocity.y -= 20.0 * delta

	# Sigilo / Agachado anatómico (baja la cápsula sin deformar la cabeza ni el arma)
	is_crouched = Input.is_action_pressed("stealth")
	var target_h: float = 1.32 if is_crouched else 1.85
	col_capsule.height = lerpf(col_capsule.height, target_h, delta * 12.0)
	col_shape.position.y = col_capsule.height * 0.5

	# Movimiento en 3D respecto a la orientación de la cámara (órbita libre estilo GTA V)
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	var cam_basis := Basis(Vector3.UP, cam_yaw)
	var move_dir := (cam_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var spd := stealth_speed if is_crouched else base_speed
	var aiming := Input.is_action_pressed("aim_mouse")

	if aiming or fire_face_timer > 0.0:
		rotation.y = lerp_angle(rotation.y, cam_yaw, minf(1.0, delta * 18.0))
	elif move_dir.length() > 0.1:
		var move_yaw: float = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, move_yaw, minf(1.0, delta * 12.0))

	if move_dir.length() > 0.1:
		velocity.x = move_dir.x * spd
		velocity.z = move_dir.z * spd
	else:
		velocity.x = lerpf(velocity.x, 0.0, delta * 12.0)
		velocity.z = lerpf(velocity.z, 0.0, delta * 12.0)

	move_and_slide()

	var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
	if horiz_speed > 0.25:
		anim_phase += delta * (horiz_speed * 1.45)

	var cur_w: Dictionary = weapons[weapon_idx]
	ModelBuilder.animate_character_rig(
		rig,
		horiz_speed / maxf(1.0, base_speed),
		anim_phase,
		is_crouched,
		delta,
		str(cur_w["id"]),
		aiming or fire_face_timer > 0.0,
		cam_pitch,
		punch_timer
	)

	# Disparar arma o golpear
	var w: Dictionary = weapons[weapon_idx]
	var wants_fire := false
	if w["auto"]:
		wants_fire = Input.is_action_pressed("fire_mouse") or Input.is_action_pressed("shoot")
	else:
		wants_fire = Input.is_action_just_pressed("fire_mouse") or Input.is_action_just_pressed("shoot")

	if wants_fire and shoot_timer <= 0.0:
		_fire_weapon()

	# Comprobar objetos interactuables cercanos (Teléfono, Auto, Escalera, Puerta)
	_check_interactables()

func _check_interactables() -> void:
	var best_obj: Node3D = null
	var best_dist := 4.5
	var prompt := ""

	for node in get_tree().get_nodes_in_group("interactable"):
		if node is Node3D and is_instance_valid(node) and node.has_method("get_prompt"):
			var n3d: Node3D = node
			var d: float = global_position.distance_to(n3d.global_position)
			if d < best_dist:
				var p: String = n3d.get_prompt()
				if p != "":
					best_dist = d
					best_obj = n3d
					prompt = p

	prompt_changed.emit(prompt)

	if Input.is_action_just_pressed("interact") and best_obj:
		if best_obj is Vehicle3D:
			enter_vehicle(best_obj)
		elif best_obj is Payphone3D:
			var first_line: String = best_obj.interact()
			if first_line != "":
				payphone_called.emit(first_line)
		elif best_obj.has_method("interact"):
			best_obj.interact(self)

func enter_vehicle(veh: Vehicle3D) -> void:
	current_vehicle = veh
	veh.set_occupied(true)
	rig["root"].visible = false
	collision_layer = 0
	collision_mask = 0
	rotation.y = veh.rotation.y
	cam_yaw = veh.rotation.y
	cam_pitch = clampf(cam_pitch, deg_to_rad(-28.0), deg_to_rad(14.0))
	cam_idle_timer = 0.0
	spring_arm.add_excluded_object(veh.get_rid())
	AudioManager.play_sfx("engine")

func exit_vehicle() -> void:
	if not current_vehicle:
		return
	var veh: Vehicle3D = current_vehicle
	var space_state := get_world_3d().direct_space_state
	var exit_pos: Vector3 = veh.global_position + Vector3(0.0, 1.8, 0.0)
	var sides: Array[Vector3] = [veh.global_transform.basis.x * 2.2, -veh.global_transform.basis.x * 2.2]
	for side_dir in sides:
		var candidate: Vector3 = veh.global_position + side_dir
		var q := PhysicsRayQueryParameters3D.create(veh.global_position + Vector3(0, 0.9, 0), candidate + Vector3(0, 0.9, 0), 1)
		q.exclude = [veh.get_rid(), get_rid()]
		if not space_state.intersect_ray(q):
			exit_pos = candidate
			break

	veh.set_occupied(false)
	current_vehicle = null
	global_position = exit_pos + Vector3(0, 0.2, 0)
	rig["root"].visible = true
	collision_layer = 2
	collision_mask = 1
	spring_arm.clear_excluded_objects()
	spring_arm.add_excluded_object(get_rid())
	cam_pitch = deg_to_rad(-8.0)

func _fire_weapon() -> void:
	var w: Dictionary = weapons[weapon_idx]
	fire_face_timer = 0.55
	rotation.y = cam_yaw

	if w["melee"]:
		shoot_timer = w["cooldown"]
		punch_timer = 0.24
		AudioManager.play_sfx(w["sound"])
		for en in get_tree().get_nodes_in_group("enemy"):
			if en is Node3D and is_instance_valid(en) and global_position.distance_to((en as Node3D).global_position) < 2.8:
				var dmg: float = float(w["damage"]) * (3.0 if str(en.get("state")) != "CHASE" else 1.0)
				if en.has_method("take_damage"):
					en.call("take_damage", dmg)
		return

	if w["ammo_clip"] <= 0:
		if w["ammo_reserve"] > 0:
			var needed: int = w["clip"] - w["ammo_clip"]
			var xfer: int = mini(needed, w["ammo_reserve"])
			w["ammo_clip"] += xfer
			w["ammo_reserve"] -= xfer
		else:
			return

	w["ammo_clip"] -= 1
	if w["ammo_clip"] == 0 and w["ammo_reserve"] > 0:
		var needed: int = w["clip"] - w["ammo_clip"]
		var xfer: int = mini(needed, w["ammo_reserve"])
		w["ammo_clip"] += xfer
		w["ammo_reserve"] -= xfer

	weapon_changed.emit(w)
	shoot_timer = w["cooldown"]
	AudioManager.play_sfx(w["sound"])
	add_camera_shake(0.65 if w["explosive"] else 0.14)

	# Apuntado exacto desde la retícula de la cámara al objetivo
	var cam_fwd: Vector3 = -camera.global_transform.basis.z.normalized()
	var ray_start: Vector3 = camera.global_position + cam_fwd * (spring_arm.get_hit_length() + 0.45)
	var space_state := get_world_3d().direct_space_state
	var aim_query := PhysicsRayQueryParameters3D.create(ray_start, ray_start + cam_fwd * 200.0)
	var ex: Array[RID] = [get_rid()]
	if current_vehicle and is_instance_valid(current_vehicle):
		ex.append(current_vehicle.get_rid())
	aim_query.exclude = ex
	var aim_hit := space_state.intersect_ray(aim_query)
	var aim_target: Vector3 = (aim_hit["position"] as Vector3) if aim_hit else (ray_start + cam_fwd * 150.0)

	var spawn_pos: Vector3 = global_position + Vector3(0.0, 1.05 if is_crouched else 1.38, 0.0) + (-global_transform.basis.z * 0.85)
	var raw_dir: Vector3 = aim_target - spawn_pos
	var shot_dir: Vector3 = raw_dir.normalized() if raw_dir.length_squared() > 0.001 else cam_fwd
	var proj := Projectile3D.new()
	var spd: float = 38.0 if w["explosive"] else 90.0
	proj.setup(spawn_pos, shot_dir, w["damage"], spd, w["explosive"], "Player")
	get_parent().add_child(proj)

	# Alertar transeúntes y enemigos cercanos (si no es pistola silenciada con Shado)
	if not (char_id == "shado" and w["id"] == "pistol"):
		for civ in get_tree().get_nodes_in_group("civilian"):
			if civ is Node3D and is_instance_valid(civ) and (civ as Node3D).global_position.distance_to(global_position) < 35.0:
				if civ.has_method("alert_panic"):
					civ.call("alert_panic", global_position)
		for en in get_tree().get_nodes_in_group("enemy"):
			if en is Node3D and is_instance_valid(en) and (en as Node3D).global_position.distance_to(global_position) < 38.0:
				en.set("state", "CHASE")
