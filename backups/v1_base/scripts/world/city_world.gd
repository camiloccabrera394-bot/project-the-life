extends Node3D

const INTERIOR_ORIGIN := Vector3(0, -50, 0)

var city_blocks := []  # Para el radar circular del HUD: {"rect": Rect2, "height": float}
var streetlamps := []
var train_cars := []
var rain_particles: GPUParticles3D

var player: Player3D
var payphone: Payphone3D
var hud: GTAHud

var active_mission_state: String = "FIND_PHONE"  # FIND_PHONE -> HUNT_TARGET -> COMPLETE
var target_gps := Vector2(-12.0, -9.5)
var boss_defeated: bool = false
var in_call_dialogue: bool = false
var current_op: Dictionary = {}

func _ready() -> void:
	current_op = GameState.get_current_operation()
	_setup_environment()
	_build_city_grid()
	_build_elevated_train()
	_build_interior()
	_spawn_entities()
	_setup_hud()

func _setup_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()

	if SettingsManager.night_mode:
		# Ciudad Nocturna Cyberpunk
		sky_mat.sky_top_color = Color(0.03, 0.04, 0.10)
		sky_mat.sky_horizon_color = Color(0.18, 0.12, 0.28)
		sky_mat.ground_bottom_color = Color(0.03, 0.03, 0.05)
		sky_mat.ground_horizon_color = Color(0.12, 0.08, 0.18)
	else:
		# Atardecer Dorado estilo captura GTA SA
		sky_mat.sky_top_color = Color(0.14, 0.16, 0.28)
		sky_mat.sky_horizon_color = Color(0.88, 0.48, 0.22)
		sky_mat.ground_bottom_color = Color(0.06, 0.06, 0.09)
		sky_mat.ground_horizon_color = Color(0.45, 0.25, 0.18)

	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.45 if SettingsManager.night_mode else 0.65
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_bloom = 0.22
	env.fog_enabled = true
	env.fog_light_color = Color(0.12, 0.11, 0.18) if SettingsManager.night_mode else Color(0.55, 0.35, 0.24)
	env.fog_density = 0.0045
	we.environment = env
	add_child(we)

	# Luz principal direccional (Luna / Atardecer) con sombras 3D reales
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 35, 0)
	sun.light_color = Color(0.68, 0.78, 1.0) if SettingsManager.night_mode else Color(1.0, 0.72, 0.45)
	sun.light_energy = 0.85 if SettingsManager.night_mode else 1.25
	sun.shadow_enabled = SettingsManager.shadows_enabled
	add_child(sun)

func _build_city_grid() -> void:
	# Suelo base de la metrópolis (360m x 360m)
	var base_mat := ModelBuilder.make_toon_material(Color(0.12, 0.13, 0.16), Color.BLACK, 0.0, 0.0)
	_create_solid_box(Vector3(380, 1.0, 380), Vector3(0, -0.5, 0), base_mat)

	var road_mat := ModelBuilder.make_toon_material(Color(0.08, 0.09, 0.11), Color.BLACK, 0.0, 0.0)
	var yellow_mat := ModelBuilder.make_toon_material(Color(0.92, 0.76, 0.18), Color(0.8, 0.6, 0.1), 0.1, 0.0)
	var white_mat := ModelBuilder.make_toon_material(Color(0.70, 0.74, 0.80), Color.BLACK, 0.0, 0.0)

	# Avenidas principales en Z = -75, 0, +75 y Bulevares en X = -75, 0, +75
	var road_coords := [-75.0, 0.0, 75.0]
	for rz in road_coords:
		_vis_box(Vector3(360, 0.04, 16.0), Vector3(0, 0.02, rz), road_mat)
		_vis_box(Vector3(360, 0.05, 0.25), Vector3(0, 0.03, rz - 0.3), yellow_mat)
		_vis_box(Vector3(360, 0.05, 0.25), Vector3(0, 0.03, rz + 0.3), yellow_mat)
		for dx in range(-160, 160, 14):
			_vis_box(Vector3(6.0, 0.05, 0.18), Vector3(dx, 0.03, rz - 4.0), white_mat)
			_vis_box(Vector3(6.0, 0.05, 0.18), Vector3(dx, 0.03, rz + 4.0), white_mat)

	for rx in road_coords:
		_vis_box(Vector3(16.0, 0.045, 360), Vector3(rx, 0.025, 0), road_mat)
		_vis_box(Vector3(0.25, 0.055, 360), Vector3(rx - 0.3, 0.035, 0), yellow_mat)
		_vis_box(Vector3(0.25, 0.055, 360), Vector3(rx + 0.3, 0.035, 0), yellow_mat)

	# 16 Manzanas de Edificios Sólidos con ventanas luminosas y azoteas reales
	var block_centers := [-115.0, -37.5, 37.5, 115.0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 77

	var win_mat := ModelBuilder.make_toon_material(Color(0.95, 0.85, 0.50), Color(0.95, 0.80, 0.45), 1.4, 0.0)
	var roof_mat := ModelBuilder.make_toon_material(Color(0.14, 0.15, 0.19), Color.BLACK, 0.0, 0.0)

	for bx in block_centers:
		for bz in block_centers:
			var bw := 50.0
			var bd := 50.0
			var bh := rng.randf_range(16.0, 32.0)
			var label_txt := ""
			var label_col := Color(0.16, 0.88, 0.96)

			if int(bx) == 37 and int(bz) == -37:
				bh = 12.0
				label_txt = "CYBER-GEAR TALLER"
				label_col = Color(0.16, 0.88, 0.96)
			elif int(bx) == -37 and int(bz) == -37:
				bh = 24.0
				label_txt = "HOTEL KUROSHIO"
				label_col = Color(0.95, 0.25, 0.35)
			elif int(bx) == 37 and int(bz) == 37:
				bh = 16.0
				label_txt = "SYNTH-CLUB 404"
				label_col = Color(0.75, 0.25, 0.95)

			var b_col := Color(rng.randf_range(0.10, 0.16), rng.randf_range(0.11, 0.17), rng.randf_range(0.15, 0.22))
			var b_mat := ModelBuilder.make_toon_material(b_col, Color.BLACK, 0.0, 0.0)
			_create_solid_box(Vector3(bw, bh, bd), Vector3(bx, bh * 0.5, bz), b_mat)

			# Pretil de azotea para caminar sin caer
			_vis_box(Vector3(bw, 0.2, bd), Vector3(bx, bh + 0.05, bz), roof_mat)

			# Franjas de ventanas iluminadas en fachada
			for wy in range(4, int(bh) - 2, 4):
				_vis_box(Vector3(bw + 0.1, 1.2, bd - 8.0), Vector3(bx, wy, bz), win_mat)
				_vis_box(Vector3(bw - 8.0, 1.2, bd + 0.1), Vector3(bx, wy, bz), win_mat)

			# Letrero de neón 3D
			if label_txt != "":
				var l3d := Label3D.new()
				l3d.text = label_txt
				l3d.font_size = 96
				l3d.modulate = label_col
				l3d.outline_modulate = Color.BLACK
				l3d.position = Vector3(bx, minf(bh - 2.0, 9.0), bz + bd * 0.5 + 0.3)
				add_child(l3d)

			# Registrar para el radar minimapa
			city_blocks.append({
				"rect": Rect2(bx - bw * 0.5, bz - bd * 0.5, bw, bd),
				"height": bh
			})

	# Farolas con luces OmniLight3D reales
	var pole_mat := ModelBuilder.make_toon_material(Color(0.14, 0.16, 0.20), Color.BLACK, 0.0, 0.0)
	var bulb_mat := ModelBuilder.make_toon_material(Color(1.0, 0.85, 0.50), Color(1.0, 0.72, 0.35), 3.0, 0.0)
	for lx in range(-120, 121, 30):
		if absf(lx) < 12.0 or absf(absf(lx) - 75.0) < 12.0:
			continue
		for lz in [-9.2, 9.2]:
			_vis_box(Vector3(0.25, 6.5, 0.25), Vector3(lx, 3.25, lz), pole_mat)
			_vis_box(Vector3(0.6, 0.3, 0.6), Vector3(lx, 6.5, lz), bulb_mat)
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.70, 0.35)
			l.light_energy = 2.4
			l.omni_range = 18.0
			l.position = Vector3(lx, 6.0, lz)
			add_child(l)

func _build_elevated_train() -> void:
	# Puente elevado de hormigón y acero cruzando por arriba de Z = 0 en Y = 9.0m
	var steel_mat := ModelBuilder.make_toon_material(Color(0.15, 0.17, 0.21))
	var pillar_mat := ModelBuilder.make_toon_material(Color(0.24, 0.26, 0.30))

	_create_solid_box(Vector3(360.0, 1.2, 7.0), Vector3(0, 9.5, 0), steel_mat)
	for px in range(-150, 151, 30):
		_create_solid_box(Vector3(1.4, 9.0, 1.4), Vector3(px, 4.5, -3.2), pillar_mat)
		_create_solid_box(Vector3(1.4, 9.0, 1.4), Vector3(px, 4.5, 3.2), pillar_mat)

	# Metro nocturno pasando periódicamente por las vías elevadas
	var train_mat := ModelBuilder.make_toon_material(Color(0.75, 0.16, 0.20))
	var win_mat := ModelBuilder.make_toon_material(Color(1.0, 0.92, 0.60), Color(1.0, 0.88, 0.50), 2.0)
	for i in range(4):
		var car := Node3D.new()
		car.position = Vector3(-160.0 + i * 15.5, 11.4, 0)
		_vis_box_on(car, Vector3(14.0, 3.0, 3.4), Vector3.ZERO, train_mat)
		_vis_box_on(car, Vector3(12.0, 1.0, 3.5), Vector3(0, 0.4, 0), win_mat)
		add_child(car)
		train_cars.append(car)

func _build_interior() -> void:
	# Taller Clandestino interior ubicado en Y = -50
	InteriorBuilder.build_chop_shop(self, INTERIOR_ORIGIN, func(p):
		p.global_position = Vector3(36.0, 0.5, -10.5)
	)

	# Puerta en fachada del Taller Cyber-Gear (X=36, Z=-12.5)
	var door := Door3D.new()
	door.setup(Vector3(36.0, 0, -12.3), "ENTRAR AL TALLER CYBER-GEAR", func(p):
		p.global_position = INTERIOR_ORIGIN + Vector3(0, 0.5, 10.0)
	)
	add_child(door)

	# Escaleras de incendio para subir a la azotea del Taller (h = 12.0m)
	var ladder_up := Ladder3D.new()
	ladder_up.setup(Vector3(15.5, 0, -12.3), Vector3(16.5, 12.2, -16.0), "SUBIR A LA AZOTEA CYBER-GEAR")
	add_child(ladder_up)

	var ladder_down := Ladder3D.new()
	ladder_down.setup(Vector3(16.5, 12.0, -13.5), Vector3(15.5, 0.5, -10.2), "BAJAR A LA CALLE")
	add_child(ladder_down)

	# Helipuerto "H" en la azotea de Cyber-Gear (X=37.5, Y=12.15, Z=-37.5)
	var heli := Label3D.new()
	heli.text = "H"
	heli.font_size = 240
	heli.modulate = Color(0.95, 0.80, 0.15)
	heli.rotation_degrees = Vector3(-90, 0, 0)
	heli.position = Vector3(37.5, 12.15, -37.5)
	add_child(heli)

func _spawn_entities() -> void:
	# 1. Protagonista en la Avenida Central mirando hacia las vías elevadas
	player = Player3D.new()
	player.global_position = Vector3(-55.0, 0.5, 3.5)
	player.rotation.y = -PI / 2.0  # Mirando hacia +X
	add_child(player)

	# Lluvia 3D pegada sobre el jugador si está activada
	if SettingsManager.rain_enabled:
		rain_particles = GPUParticles3D.new()
		rain_particles.amount = 650
		rain_particles.lifetime = 1.0
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(24.0, 1.0, 24.0)
		pm.direction = Vector3(0.12, -1.0, 0.0)
		pm.spread = 4.0
		pm.initial_velocity_min = 24.0
		pm.initial_velocity_max = 32.0
		rain_particles.process_material = pm

		var drop_mesh := BoxMesh.new()
		drop_mesh.size = Vector3(0.03, 0.85, 0.03)
		var drop_mat := StandardMaterial3D.new()
		drop_mat.albedo_color = Color(0.65, 0.82, 1.0, 0.45)
		drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		drop_mesh.material = drop_mat
		rain_particles.draw_pass_1 = drop_mesh
		rain_particles.position = Vector3(0, 16.0, 0)
		player.add_child(rain_particles)

	# 2. Cabina Telefónica sonando bajo las vías del tren (X=-12, Z=-9.5)
	payphone = Payphone3D.new()
	payphone.global_position = Vector3(-12.0, 0, -9.5)
	add_child(payphone)

	# 3. Vehículos estacionados en la avenida
	var veh_configs := [
		[Vector3(-42.0, 0.1, -3.5), "sports_car", -PI / 2.0],
		[Vector3(-25.0, 0.1, 4.0), "mafia_sedan", -PI / 2.0],
		[Vector3(8.0, 0.1, -3.5), "motorcycle", 0.0],
		[Vector3(24.0, 0.1, 4.0), "sports_car", PI / 2.0]
	]
	for vc in veh_configs:
		var v := Vehicle3D.new()
		v.setup(vc[0], vc[1], vc[2])
		add_child(v)

	# 4. Transeúntes realistas caminando por las aceras
	if SettingsManager.pedestrians_enabled:
		for i in range(18):
			var civ := NPC3D.new()
			var cx := randf_range(-100.0, 100.0)
			var cz := -9.5 if i % 2 == 0 else 9.5
			civ.setup(Vector3(cx, 0.5, cz), "x", Vector2(-120.0, 120.0), i % 4)
			add_child(civ)

	# 5. Enemigos en la calle, en la azotea y el Boss dentro del Taller (Y = -50)
	var enemy_spawns := [
		[Vector3(18.0, 0.5, -5.0), false, ""],
		[Vector3(34.0, 0.5, -8.0), false, ""],
		[Vector3(30.0, 12.6, -26.0), false, ""],  # Francotirador en azotea
		[INTERIOR_ORIGIN + Vector3(-5.0, 0.5, -4.0), false, ""],
		[INTERIOR_ORIGIN + Vector3(6.0, 0.5, -2.0), false, ""],
		[INTERIOR_ORIGIN + Vector3(0.0, 0.5, -10.0), true, current_op["target_name"]]
	]
	for es in enemy_spawns:
		var en := Enemy3D.new()
		en.setup(es[0], es[1], es[2])
		en.enemy_killed.connect(_on_enemy_killed)
		add_child(en)

func _setup_hud() -> void:
	hud = GTAHud.new()
	add_child(hud)
	hud.set_subtitle("Informante: Busca la cabina telefónica que suena bajo las vías del tren [E].")
	hud.update_weapon(player.weapons[player.weapon_idx])
	hud.update_health(player.health, player.max_health)
	hud.update_cash(GameState.cash)

	player.health_changed.connect(func(hp, mhp): hud.update_health(hp, mhp))
	player.weapon_changed.connect(func(w): hud.update_weapon(w))
	player.prompt_changed.connect(func(txt): hud.set_prompt(txt))
	player.payphone_called.connect(func(first_line):
		in_call_dialogue = true
		player.dialogue_locked = true
		hud.set_subtitle(first_line + "  [ESPACIO / CLIC]")
	)
	player.player_died.connect(func():
		get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")
	)
	payphone.call_finished.connect(func():
		in_call_dialogue = false
		player.dialogue_locked = false
		active_mission_state = "HUNT_TARGET"
		target_gps = Vector2(36.0, -12.3)
		hud.set_subtitle("Misión: Entra al Taller Cyber-Gear [E] (o escala por la azotea) y elimina a " + current_op["target_name"] + ".")
	)

func _on_enemy_killed(is_boss: bool, pos: Vector3) -> void:
	GameState.cash += 500 if is_boss else 150
	hud.update_cash(GameState.cash)

	var pk := Pickup3D.new()
	pk.setup(pos + Vector3(0, 0.2, 0), "ammo" if randf() < 0.7 else "medkit", 30)
	add_child(pk)

	if is_boss:
		active_mission_state = "COMPLETE"
		GameState.mark_operation_completed(current_op["id"])
		hud.set_subtitle("¡OBJETIVO ELIMINADO! Has vengado a tu madre (+$500). Regresa al tablero [ESC].")

func _process(delta: float) -> void:
	# Mover el metro elevado
	for car in train_cars:
		car.position.x += 24.0 * delta
		if car.position.x > 190.0:
			car.position.x = -190.0

	# Avanzar diálogo del teléfono
	if in_call_dialogue and (Input.is_action_just_pressed("stealth") or Input.is_action_just_pressed("fire_mouse") or Input.is_action_just_pressed("ui_accept")):
		var next_line := payphone.advance_dialogue()
		if next_line != "":
			hud.set_subtitle(next_line + "  [ESPACIO / CLIC]")

	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/ui/mission_board.tscn")

	if hud and player:
		hud.update_radar(player.global_position, player.rotation.y, target_gps, city_blocks)

func _create_solid_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var sb := StaticBody3D.new()
	sb.position = pos
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	sb.add_child(col)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	sb.add_child(mi)
	add_child(sb)

func _vis_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	_vis_box_on(self, size, pos, mat)

func _vis_box_on(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
