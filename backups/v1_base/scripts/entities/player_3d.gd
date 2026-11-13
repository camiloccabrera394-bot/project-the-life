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
var weapon_idx: int = 3  # Empieza con Fusil M4 (igual que en la captura)
var shoot_timer: float = 0.0
var anim_phase: float = 0.0

var rig: Dictionary = {}
var weapon_mesh: Node3D = null
var cam_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D

var current_vehicle: Vehicle3D = null
var dialogue_locked: bool = false
var camera_shake: float = 0.0
var mouse_sens: float = 0.0028

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

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.40
	cap.height = 1.85
	col.shape = cap
	col.position = Vector3(0, 0.92, 0)
	add_child(col)

	rig = ModelBuilder.build_character_rig("player", char_id)
	add_child(rig["root"])

	# Cámara en Tercera Persona detrás del protagonista (SpringArm3D evita atravesar edificios)
	cam_pivot = Node3D.new()
	cam_pivot.position = Vector3(0.35, 1.65, 0)
	add_child(cam_pivot)

	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = 4.2
	spring_arm.collision_mask = 1
	cam_pivot.add_child(spring_arm)

	camera = Camera3D.new()
	camera.fov = 65.0
	camera.far = 350.0
	camera.current = true
	spring_arm.add_child(camera)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_equip_weapon(weapon_idx)

func _equip_weapon(idx: int) -> void:
	weapon_idx = clampi(idx, 0, weapons.size() - 1)
	if weapon_mesh and is_instance_valid(weapon_mesh):
		weapon_mesh.queue_free()
	var w: Dictionary = weapons[weapon_idx]
	weapon_mesh = ModelBuilder.build_weapon_mesh(w["id"])
	rig["weapon_mount"].add_child(weapon_mesh)

	# Pose del brazo según el arma
	if w["id"] == "m4":
		rig["right_arm"].rotation_degrees = Vector3(25, 0, -25)
		rig["left_arm"].rotation_degrees = Vector3(15, 0, 10)
	elif w["id"] == "bazooka":
		rig["right_arm"].rotation_degrees = Vector3(85, 0, 0)
		rig["left_arm"].rotation_degrees = Vector3(10, 0, 5)
	elif w["id"] in ["pistol", "smg"]:
		rig["right_arm"].rotation_degrees = Vector3(68, 0, 0)
		rig["left_arm"].rotation_degrees = Vector3(0, 0, 0)
	else:
		rig["right_arm"].rotation_degrees = Vector3(0, 0, 0)
		rig["left_arm"].rotation_degrees = Vector3(0, 0, 0)

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

func _unhandled_input(event: InputEvent) -> void:
	if health <= 0:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if current_vehicle:
			cam_pivot.rotate_y(-event.relative.x * mouse_sens)
		else:
			rotate_y(-event.relative.x * mouse_sens)
		cam_pivot.rotation.x = clampf(cam_pivot.rotation.x - event.relative.y * mouse_sens, deg_to_rad(-35.0), deg_to_rad(30.0))

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

	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: AudioManager.play_sfx("click"); _equip_weapon(0)
		elif event.keycode == KEY_2: AudioManager.play_sfx("click"); _equip_weapon(1)
		elif event.keycode == KEY_3: AudioManager.play_sfx("click"); _equip_weapon(2)
		elif event.keycode == KEY_4: AudioManager.play_sfx("click"); _equip_weapon(3)
		elif event.keycode == KEY_5: AudioManager.play_sfx("click"); _equip_weapon(4)
		elif Input.is_action_just_pressed("weapon_next"):
			AudioManager.play_sfx("click")
			_equip_weapon((weapon_idx + 1) % weapons.size())

func _physics_process(delta: float) -> void:
	if health <= 0 or dialogue_locked:
		return

	if shoot_timer > 0.0:
		shoot_timer -= delta

	# Efecto de temblor de cámara
	if camera_shake > 0.0:
		camera.h_offset = randf_range(-camera_shake, camera_shake) * 0.25
		camera.v_offset = randf_range(-camera_shake, camera_shake) * 0.25
		camera_shake = maxf(0.0, camera_shake - delta * 2.5)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0

	# Zoom de apuntado (Clic Derecho) o conducción
	var aiming := Input.is_action_pressed("aim_mouse") and not current_vehicle
	var target_len := 6.8 if current_vehicle else (2.4 if aiming else 4.2)
	var target_ox := 0.0 if current_vehicle else (0.55 if aiming else 0.35)
	spring_arm.spring_length = lerpf(spring_arm.spring_length, target_len, delta * 10.0)
	cam_pivot.position.x = lerpf(cam_pivot.position.x, target_ox, delta * 10.0)

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

	# Sigilo / Agachado
	is_crouched = Input.is_action_pressed("stealth")
	rig["root"].scale.y = lerpf(rig["root"].scale.y, 0.78 if is_crouched else 1.0, delta * 12.0)

	# Movimiento en 3D respecto a la rotación de la cámara
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	var move_dir := (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var spd := stealth_speed if is_crouched else base_speed

	if move_dir.length() > 0.1:
		velocity.x = move_dir.x * spd
		velocity.z = move_dir.z * spd
		anim_phase += delta * (spd * 1.45)
		var swing := sin(anim_phase) * 0.58
		rig["left_leg"].rotation.x = swing
		rig["right_leg"].rotation.x = -swing
		# Faldones de la gabardina ondeando al correr
		rig["coat_left"].rotation.x = deg_to_rad(14.0 + absf(sin(anim_phase)) * 12.0)
		rig["coat_right"].rotation.x = deg_to_rad(14.0 + absf(cos(anim_phase)) * 12.0)
	else:
		velocity.x = lerpf(velocity.x, 0.0, delta * 12.0)
		velocity.z = lerpf(velocity.z, 0.0, delta * 12.0)
		rig["left_leg"].rotation.x = lerpf(rig["left_leg"].rotation.x, 0.0, delta * 10.0)
		rig["right_leg"].rotation.x = lerpf(rig["right_leg"].rotation.x, 0.0, delta * 10.0)
		var idle_wind := sin(Time.get_ticks_msec() * 0.003) * 3.0
		rig["coat_left"].rotation.x = deg_to_rad(8.0 + idle_wind)
		rig["coat_right"].rotation.x = deg_to_rad(8.0 - idle_wind)

	move_and_slide()

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
	cam_pivot.rotation.y = 0.0
	AudioManager.play_sfx("engine")

func exit_vehicle() -> void:
	if not current_vehicle:
		return
	var exit_pos := current_vehicle.global_position + current_vehicle.global_transform.basis.x * 2.2
	current_vehicle.set_occupied(false)
	current_vehicle = null
	global_position = exit_pos + Vector3(0, 0.2, 0)
	rig["root"].visible = true
	collision_layer = 2
	collision_mask = 1
	cam_pivot.rotation.y = 0.0

func _fire_weapon() -> void:
	var w: Dictionary = weapons[weapon_idx]
	if w["melee"]:
		shoot_timer = w["cooldown"]
		AudioManager.play_sfx(w["sound"])
		rig["right_arm"].rotation_degrees.x = 88.0
		get_tree().create_timer(0.15).timeout.connect(func(): if is_instance_valid(self): rig["right_arm"].rotation_degrees.x = 0.0)
		for en in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(en) and global_position.distance_to(en.global_position) < 2.8:
				var dmg: float = w["damage"] * (3.0 if en.state != "CHASE" else 1.0)
				en.take_damage(dmg)
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

	# Dirección desde la cámara hacia el horizonte
	var cam_fwd := -camera.global_transform.basis.z.normalized()
	var spawn_pos := global_position + Vector3(0, 1.35, 0) + cam_fwd * 1.1
	var proj := Projectile3D.new()
	var spd := 38.0 if w["explosive"] else 90.0
	proj.setup(spawn_pos, cam_fwd, w["damage"], spd, w["explosive"], "Player")
	get_parent().add_child(proj)

	# Alertar transeúntes y enemigos cercanos (si no es pistola silenciada con Shado)
	if not (char_id == "shado" and w["id"] == "pistol"):
		for civ in get_tree().get_nodes_in_group("civilian"):
			if is_instance_valid(civ) and civ.global_position.distance_to(global_position) < 35.0:
				civ.alert_panic(global_position)
		for en in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(en) and en.global_position.distance_to(global_position) < 38.0:
				en.state = "CHASE"
