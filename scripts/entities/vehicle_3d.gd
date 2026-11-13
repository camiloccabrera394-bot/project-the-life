extends CharacterBody3D
class_name Vehicle3D

var v_type: String = "sports_car"
var max_speed: float = 36.0
var accel: float = 20.0
var turn_speed: float = 2.6
var health: float = 240.0
var max_health: float = 240.0
var speed: float = 0.0
var is_occupied: bool = false
var destroyed: bool = false

var engine_timer: float = 0.0
var horn_timer: float = 0.0
var crash_sfx_timer: float = 0.0
var mesh_data: Dictionary = {}
var wheel_spray_l: GPUParticles3D = null
var wheel_spray_r: GPUParticles3D = null

func setup(pos: Vector3, type_name: String = "sports_car", yaw_rad: float = 0.0) -> void:
	global_position = pos
	v_type = type_name
	rotation.y = yaw_rad
	if type_name == "mafia_sedan":
		max_speed = 28.0
		accel = 15.5
		turn_speed = 2.3
		health = 340.0
	elif type_name == "motorcycle":
		max_speed = 40.0
		accel = 25.0
		turn_speed = 3.2
		health = 140.0
	max_health = health

func _ready() -> void:
	add_to_group("vehicle")
	add_to_group("interactable")

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	if v_type == "motorcycle":
		box.size = Vector3(0.75, 1.1, 2.0)
	else:
		box.size = Vector3(2.15, 1.3, 4.45)
	col.shape = box
	col.position = Vector3(0, box.size.y * 0.5, 0)
	add_child(col)

	mesh_data = ModelBuilder.build_vehicle_mesh(v_type)
	add_child(mesh_data["root"])
	if mesh_data.has("headlight"):
		mesh_data["headlight"].visible = false

	# Partículas de pulverización de agua (wheel spray) sobre asfalto mojado
	if SettingsManager.graphics_quality != "low":
		var spray_mat := StandardMaterial3D.new()
		spray_mat.albedo_color = Color(0.85, 0.92, 1.0, 0.28)
		spray_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		spray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var spray_mesh := SphereMesh.new()
		spray_mesh.radius = 0.12
		spray_mesh.height = 0.20
		spray_mesh.material = spray_mat

		var spm := ParticleProcessMaterial.new()
		spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		spm.emission_box_extents = Vector3(0.15, 0.08, 0.15)
		spm.direction = Vector3(0.0, 0.65, 1.0).normalized()
		spm.spread = 24.0
		spm.initial_velocity_min = 3.5
		spm.initial_velocity_max = 7.5
		spm.gravity = Vector3(0.0, -9.8, 0.0)
		spm.scale_min = 0.5
		spm.scale_max = 2.2

		wheel_spray_l = GPUParticles3D.new()
		wheel_spray_l.amount = 24
		wheel_spray_l.lifetime = 0.35
		wheel_spray_l.process_material = spm
		wheel_spray_l.draw_pass_1 = spray_mesh
		wheel_spray_l.emitting = false

		if v_type == "motorcycle":
			wheel_spray_l.position = Vector3(0.0, 0.15, 0.9)
			add_child(wheel_spray_l)
		else:
			var spm_r := spm.duplicate() as ParticleProcessMaterial
			wheel_spray_r = GPUParticles3D.new()
			wheel_spray_r.amount = 24
			wheel_spray_r.lifetime = 0.35
			wheel_spray_r.process_material = spm_r
			wheel_spray_r.draw_pass_1 = spray_mesh
			wheel_spray_r.emitting = false

			wheel_spray_l.position = Vector3(-0.85, 0.15, 1.35)
			wheel_spray_r.position = Vector3(0.85, 0.15, 1.35)
			add_child(wheel_spray_l)
			add_child(wheel_spray_r)

func get_prompt() -> String:
	if not is_occupied and not destroyed:
		return "[E] CONDUCIR VEHÍCULO"
	return ""

func set_occupied(occ: bool) -> void:
	is_occupied = occ
	if mesh_data.has("headlight"):
		mesh_data["headlight"].visible = occ

func take_damage(amount: float) -> void:
	if destroyed:
		return
	health -= amount
	if health <= 0:
		explode()

func explode() -> void:
	if destroyed:
		return
	destroyed = true
	is_occupied = false
	speed = 0.0
	if mesh_data.has("headlight"):
		mesh_data["headlight"].visible = false

	AudioManager.play_sfx("explosion")
	# Bola de fuego 3D al explotar el auto
	var exp_node := Node3D.new()
	exp_node.global_position = global_position + Vector3(0, 1.0, 0)
	var sph := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.8
	sm.height = 5.6
	sph.mesh = sm
	sph.material_override = ModelBuilder.make_toon_material(Color(1.0, 0.4, 0.1), Color(1.0, 0.65, 0.15), 5.0, 0.0)
	exp_node.add_child(sph)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.15)
	light.light_energy = 7.0
	light.omni_range = 16.0
	exp_node.add_child(light)
	get_parent().add_child(exp_node)
	var tw := get_parent().create_tween()
	tw.tween_property(sph, "scale", Vector3(2.0, 2.0, 2.0), 0.28)
	tw.parallel().tween_property(light, "light_energy", 0.0, 0.45)
	tw.tween_callback(exp_node.queue_free)

	# Notificar al jugador si estaba conduciendo
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p.get("current_vehicle") == self:
			if p.has_method("exit_vehicle"):
				p.call("exit_vehicle")
			if p.has_method("take_damage"):
				p.call("take_damage", 35.0)
		if is_instance_valid(p) and p.has_method("add_camera_shake"):
			p.call("add_camera_shake", 0.9)

	# Cambiar color del chasis a quemado
	for child in mesh_data["root"].get_children():
		if child is MeshInstance3D:
			child.material_override = ModelBuilder.make_toon_material(Color(0.08, 0.08, 0.09))

func _physics_process(delta: float) -> void:
	if destroyed:
		return

	if crash_sfx_timer > 0.0:
		crash_sfx_timer -= delta

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = -0.1

	if not is_occupied:
		speed = lerpf(speed, 0.0, delta * 3.5)
	else:
		var fwd := Input.get_action_strength("move_forward")
		var back := Input.get_action_strength("move_back")
		var left := Input.get_action_strength("move_left")
		var right := Input.get_action_strength("move_right")
		var braking := Input.is_action_pressed("stealth")

		if braking:
			speed = lerpf(speed, 0.0, delta * 6.0)
		elif fwd > 0:
			speed = minf(max_speed, speed + accel * delta)
			engine_timer += delta
			if engine_timer > 0.26:
				engine_timer = 0.0
				AudioManager.play_sfx("engine", -16.0)
		elif back > 0:
			speed = maxf(-max_speed * 0.45, speed - accel * 1.2 * delta)
		else:
			speed = lerpf(speed, 0.0, delta * 1.8)

		if absf(speed) > 0.5:
			var steer_dir := 1.0 if speed > 0 else -1.0
			var drift_mult := 1.4 if braking else 1.0
			rotation.y += (left - right) * turn_speed * steer_dir * drift_mult * delta

		# Bocina [H]
		if horn_timer > 0.0:
			horn_timer -= delta
		if Input.is_action_just_pressed("horn") and horn_timer <= 0.0:
			horn_timer = 0.5
			AudioManager.play_sfx("horn")
			for civ in get_tree().get_nodes_in_group("civilian"):
				if civ is Node3D and is_instance_valid(civ) and (civ as Node3D).global_position.distance_to(global_position) < 22.0:
					if civ.has_method("alert_panic"):
						civ.call("alert_panic", global_position)

	var forward_dir := -global_transform.basis.z
	velocity.x = forward_dir.x * speed
	velocity.z = forward_dir.z * speed
	move_and_slide()

	# Si choca fuerte contra un edificio sólido o pared vertical (nunca el suelo)
	if get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var c := get_slide_collision(i)
			var collider: Object = c.get_collider()
			var nrm: Vector3 = c.get_normal()
			if collider is Node and absf(speed) > 5.0:
				var cnode: Node = collider as Node
				if cnode.is_in_group("civilian") and cnode.has_method("get_hit_by_vehicle"):
					cnode.call("get_hit_by_vehicle", forward_dir * speed * 0.85)
				elif cnode.is_in_group("enemy") and cnode.has_method("get_hit_by_vehicle"):
					cnode.call("get_hit_by_vehicle", forward_dir * speed * 0.85)
				elif collider is StaticBody3D and absf(nrm.y) < 0.45:
					var travel_dir: Vector3 = forward_dir * signf(speed)
					if travel_dir.dot(nrm) < -0.25 and absf(speed) > 7.0:
						if crash_sfx_timer <= 0.0:
							AudioManager.play_sfx("hit")
							crash_sfx_timer = 0.35
						speed *= 0.32

	# Comprobar atropellos por proximidad cuando va rápido
	if is_occupied and absf(speed) > 6.0:
		for civ in get_tree().get_nodes_in_group("civilian"):
			if civ is Node3D and is_instance_valid(civ) and bool(civ.get("is_alive")) and (civ as Node3D).global_position.distance_to(global_position) < 2.6:
				civ.call("get_hit_by_vehicle", forward_dir * speed * 0.9)
		for en in get_tree().get_nodes_in_group("enemy"):
			if en is Node3D and is_instance_valid(en) and (en as Node3D).global_position.distance_to(global_position) < 2.6:
				en.call("get_hit_by_vehicle", forward_dir * speed * 0.9)

	# Pulverización de agua en ruedas al circular sobre asfalto mojado
	var spray_active: bool = false
	if is_on_floor() and absf(speed) > 5.5 and is_instance_valid(TimeWeatherManager):
		if TimeWeatherManager.wetness > 0.30:
			spray_active = true

	if wheel_spray_l and is_instance_valid(wheel_spray_l):
		wheel_spray_l.emitting = spray_active
	if wheel_spray_r and is_instance_valid(wheel_spray_r):
		wheel_spray_r.emitting = spray_active

	# Encendido reactivo de faros en noche o tormenta
	var headlights_on: bool = is_occupied
	if not headlights_on and is_instance_valid(TimeWeatherManager):
		if TimeWeatherManager.night_factor > 0.35 or TimeWeatherManager.current_weather in [TimeWeatherManager.WEATHER_THUNDERSTORM, TimeWeatherManager.WEATHER_FOGGY]:
			headlights_on = true
	if mesh_data.has("headlight") and is_instance_valid(mesh_data["headlight"]):
		mesh_data["headlight"].visible = headlights_on
