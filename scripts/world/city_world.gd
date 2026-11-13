extends Node3D

const INTERIOR_ORIGIN := Vector3(0, -50, 0)

var city_blocks := []  # Para el radar circular del HUD: {"rect": Rect2, "height": float}
var streetlamps := []
var train_cars := []
var rain_particles: GPUParticles3D
var wind_particles: GPUParticles3D
var world_env: Environment
var sky_material: ProceduralSkyMaterial
var sun_light: DirectionalLight3D
var lightning_light: DirectionalLight3D
var active_asphalt_mats: Array[ShaderMaterial] = []
var active_facade_mats: Array[ShaderMaterial] = []
var city_vehicles: Array = []

var player: Player3D
var payphone: Payphone3D
var hud: GTAHud

var active_mission_state: String = "FIND_PHONE"  # FIND_PHONE -> HUNT_TARGET -> COMPLETE
var target_gps := Vector2(-12.0, -9.5)
var boss_defeated: bool = false
var in_call_dialogue: bool = false
var current_op: Dictionary = {}
var ch1_sicarios: Array = []
var ch1_briefcase: Pickup3D = null
var ch1_briefcase_collected: bool = false
var sector_manager: WorldSectorManager = null

func _ready() -> void:
	current_op = GameState.get_current_operation()
	_setup_environment()
	_build_city_grid()
	_build_elevated_train()
	_build_interior()
	_setup_open_world_sectors()
	_spawn_entities()
	_setup_hud()
	_setup_chapter_mission()

func _setup_open_world_sectors() -> void:
	sector_manager = WorldSectorManager.new()
	sector_manager.name = "WorldSectorManager"
	add_child(sector_manager)
	sector_manager.initialize_sectors(self)

func _setup_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()

	if SettingsManager.night_mode:
		# Ciudad Nocturna Cinematográfica
		sky_mat.sky_top_color = Color(0.015, 0.022, 0.055)
		sky_mat.sky_horizon_color = Color(0.09, 0.08, 0.14)
		sky_mat.ground_bottom_color = Color(0.02, 0.02, 0.03)
		sky_mat.ground_horizon_color = Color(0.07, 0.06, 0.11)
	else:
		# Atardecer Dorado estilo GTA V
		sky_mat.sky_top_color = Color(0.11, 0.20, 0.38)
		sky_mat.sky_horizon_color = Color(0.95, 0.56, 0.28)
		sky_mat.ground_bottom_color = Color(0.05, 0.05, 0.08)
		sky_mat.ground_horizon_color = Color(0.48, 0.28, 0.20)

	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.65
	env.ambient_light_energy = 0.36 if SettingsManager.night_mode else 0.72

	# Tonemap ACES cinematográfico y Bloom HDR calibrado para neón y faros
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.08
	env.tonemap_white = 6.0

	env.glow_enabled = true
	env.glow_normalized = true
	env.glow_intensity = 0.45
	env.glow_strength = 0.85
	env.glow_bloom = 0.14
	env.glow_hdr_threshold = 1.05

	# Calidad gráfica configurable (SSAO / SSR)
	var qual: String = SettingsManager.graphics_quality
	if qual in ["medium", "high"]:
		env.ssao_enabled = true
		env.ssao_radius = 1.15
		env.ssao_intensity = 1.65
		env.ssao_power = 1.5
	if qual == "high":
		env.ssr_enabled = true
		env.ssr_max_steps = 40
		env.ssr_fade_in = 0.15
		env.ssr_fade_out = 2.0
		env.ssr_depth_tolerance = 0.25

	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.065, 0.10) if SettingsManager.night_mode else Color(0.68, 0.42, 0.28)
	env.fog_density = 0.0040 if SettingsManager.night_mode else 0.0026
	env.fog_sky_affect = 0.45
	we.environment = env
	add_child(we)

	world_env = env
	sky_material = sky_mat

	# Luz principal direccional (Luna / Sol / Atardecer) con cascadas de sombras 3D
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 35, 0) if SettingsManager.night_mode else Vector3(-22, 42, 0)
	sun.light_color = Color(0.62, 0.74, 1.0) if SettingsManager.night_mode else Color(1.0, 0.78, 0.48)
	sun.light_energy = 0.78 if SettingsManager.night_mode else 1.75
	sun.shadow_enabled = SettingsManager.shadows_enabled
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 140.0
	sun.shadow_bias = 0.03
	add_child(sun)
	sun_light = sun

	# Luz instantánea para relámpagos de tormenta eléctrica
	lightning_light = DirectionalLight3D.new()
	lightning_light.rotation_degrees = Vector3(-65.0, 20.0, 0.0)
	lightning_light.light_color = Color(0.85, 0.94, 1.0)
	lightning_light.light_energy = 0.0
	lightning_light.shadow_enabled = false
	add_child(lightning_light)


	# Sondas de reflejo ambiental (exteriores y taller interior)
	for px in [-95.0, 0.0, 95.0]:
		var probe := ReflectionProbe.new()
		probe.position = Vector3(px, 14.0, 0.0)
		probe.size = Vector3(135.0, 42.0, 260.0)
		probe.intensity = 0.90
		probe.update_mode = ReflectionProbe.UPDATE_ONCE
		probe.ambient_mode = ReflectionProbe.AMBIENT_ENVIRONMENT
		add_child(probe)

	var int_probe := ReflectionProbe.new()
	int_probe.position = INTERIOR_ORIGIN + Vector3(0.0, 4.0, 0.0)
	int_probe.size = Vector3(38.0, 10.0, 30.0)
	int_probe.interior = true
	int_probe.box_projection = true
	int_probe.intensity = 1.0
	int_probe.update_mode = ReflectionProbe.UPDATE_ONCE
	int_probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	int_probe.ambient_color = Color(0.14, 0.18, 0.24)
	int_probe.ambient_color_energy = 0.65
	add_child(int_probe)

func _build_city_grid() -> void:
	var wetness: float = 0.88 if SettingsManager.rain_enabled else (0.35 if SettingsManager.night_mode else 0.12)
	var ripple_amt: float = 1.0 if SettingsManager.rain_enabled else 0.0
	var night_f: float = 1.0 if SettingsManager.night_mode else 0.0

	# 1. Base territorial de la ciudad (380m x 380m)
	var base_mat := PBRMaterials.make_concrete_material(Color(0.12, 0.13, 0.15), 0.58 if SettingsManager.rain_enabled else 0.82)
	_create_solid_box(Vector3(380, 1.0, 380), Vector3(0, -0.5, 0), base_mat)

	var road_mat := PBRMaterials.make_wet_asphalt_material(wetness, ripple_amt, Color(0.052, 0.056, 0.068))
	active_asphalt_mats.append(road_mat)

	var yellow_mat := PBRMaterials.make_pbr_standard(Color(0.88, 0.70, 0.14), 0.42 if SettingsManager.rain_enabled else 0.65, 0.0, Color(0.75, 0.55, 0.10), 0.05)
	var white_mat := PBRMaterials.make_pbr_standard(Color(0.74, 0.76, 0.80), 0.42 if SettingsManager.rain_enabled else 0.65)
	var sidewalk_mat := PBRMaterials.make_concrete_material(Color(0.22, 0.23, 0.26), 0.74, Vector3(0.35, 0.35, 0.35))
	var curb_mat := PBRMaterials.make_concrete_material(Color(0.46, 0.48, 0.52), 0.68)
	var manhole_mat := PBRMaterials.make_metal_material(Color(0.15, 0.16, 0.18), 0.88, 0.45)
	var iron_mat := PBRMaterials.make_metal_material(Color(0.18, 0.20, 0.24), 0.90, 0.32)

	# Texturas para vallas publicitarias urbanas reales
	var billboard_textures: Array[Texture2D] = []
	var b_names: Array[String] = ["night_city.jpg", "neon_district.jpg", "chop_shop.jpg", "select_bg.jpg"]
	for b_name in b_names:
		var bp: String = "res://assets/images/backgrounds/" + b_name
		if ResourceLoader.exists(bp):
			var bt = load(bp)
			if bt is Texture2D:
				billboard_textures.append(bt)

	# 2. Avenidas principales en Z = -75, 0, +75 y Bulevares en X = -75, 0, +75
	var road_coords := [-75.0, 0.0, 75.0]
	for rz in road_coords:
		_vis_box(Vector3(360, 0.04, 16.0), Vector3(0, 0.02, rz), road_mat)
		# Doble línea amarilla continua central
		_vis_box(Vector3(360, 0.05, 0.22), Vector3(0, 0.03, rz - 0.28), yellow_mat)
		_vis_box(Vector3(360, 0.05, 0.22), Vector3(0, 0.03, rz + 0.28), yellow_mat)
		# Líneas blancas discontinuas de carril
		for dx in range(-160, 160, 14):
			if absf(dx) > 10.0 and absf(absf(dx) - 75.0) > 10.0:
				_vis_box(Vector3(6.0, 0.05, 0.18), Vector3(dx, 0.03, rz - 4.2), white_mat)
				_vis_box(Vector3(6.0, 0.05, 0.18), Vector3(dx, 0.03, rz + 4.2), white_mat)
		# Tapas redondas de alcantarilla en el asfalto
		for mx in [-120.0, -45.0, 45.0, 120.0]:
			_vis_cyl(0.44, 0.03, Vector3(mx, 0.03, rz + 2.5), manhole_mat)

	for rx in road_coords:
		_vis_box(Vector3(16.0, 0.045, 360), Vector3(rx, 0.025, 0), road_mat)
		_vis_box(Vector3(0.22, 0.055, 360), Vector3(rx - 0.28, 0.035, 0), yellow_mat)
		_vis_box(Vector3(0.22, 0.055, 360), Vector3(rx + 0.28, 0.035, 0), yellow_mat)
		for dz in range(-160, 160, 14):
			if absf(dz) > 10.0 and absf(absf(dz) - 75.0) > 10.0:
				_vis_box(Vector3(0.18, 0.055, 6.0), Vector3(rx - 4.2, 0.035, dz), white_mat)
				_vis_box(Vector3(0.18, 0.055, 6.0), Vector3(rx + 4.2, 0.035, dz), white_mat)

	# 3. Pasos de peatones tipo cebra en las 9 intersecciones (-75, 0, 75)
	for ix in road_coords:
		for iz in road_coords:
			for px in [-6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0]:
				_vis_box(Vector3(1.1, 0.055, 3.2), Vector3(ix + px, 0.036, iz - 9.2), white_mat)
				_vis_box(Vector3(1.1, 0.055, 3.2), Vector3(ix + px, 0.036, iz + 9.2), white_mat)
			for pz in [-6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0]:
				_vis_box(Vector3(3.2, 0.055, 1.1), Vector3(ix - 9.2, 0.036, iz + pz), white_mat)
				_vis_box(Vector3(3.2, 0.055, 1.1), Vector3(ix + 9.2, 0.036, iz + pz), white_mat)

	# 4. 16 Manzanas con aceras elevadas (+0.15m), bordillos de hormigón y variedad arquitectónica
	var block_centers := [-115.0, -37.5, 37.5, 115.0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 88

	var roof_mat := PBRMaterials.make_concrete_material(Color(0.14, 0.15, 0.18), 0.72)
	var win_glow_mat := PBRMaterials.make_glass_material(Color(1.0, 0.94, 0.70), 0.12, Color(1.0, 0.88, 0.55), 2.2)
	var brick_mat := PBRMaterials.make_brick_material(Color(0.38, 0.18, 0.15))
	var wood_mat := PBRMaterials.make_pbr_standard(Color(0.32, 0.22, 0.14), 0.82, 0.0)

	var billboard_idx: int = 0

	for bx in block_centers:
		for bz in block_centers:
			var bw := 50.0
			var bd := 50.0
			var sw_size := 58.0

			# Acera elevada +0.15m sólida
			_create_solid_box(Vector3(sw_size, 0.15, sw_size), Vector3(bx, 0.075, bz), sidewalk_mat)
			# Bordillos de hormigón claro en los 4 bordes
			_vis_box(Vector3(sw_size, 0.18, 0.35), Vector3(bx, 0.09, bz - sw_size * 0.5 + 0.17), curb_mat)
			_vis_box(Vector3(sw_size, 0.18, 0.35), Vector3(bx, 0.09, bz + sw_size * 0.5 - 0.17), curb_mat)
			_vis_box(Vector3(0.35, 0.18, sw_size), Vector3(bx - sw_size * 0.5 + 0.17, 0.09, bz), curb_mat)
			_vis_box(Vector3(0.35, 0.18, sw_size), Vector3(bx + sw_size * 0.5 - 0.17, 0.09, bz), curb_mat)

			var is_cyber_gear: bool = (int(bx) == 37 and int(bz) == -37)
			var is_kuroshio: bool = (int(bx) == -37 and int(bz) == -37)
			var is_synth_club: bool = (int(bx) == 37 and int(bz) == 37)

			var bh: float = 24.0

			if is_cyber_gear:
				# TALLER CYBER-GEAR (h = 12.0m para conservar helipuerto, sniper y escaleras de azotea)
				bh = 12.0
				var cg_mat := PBRMaterials.make_metal_material(Color(0.14, 0.16, 0.19), 0.82, 0.38)
				_create_solid_box(Vector3(bw, bh, bd), Vector3(bx, bh * 0.5, bz), cg_mat)
				_vis_box(Vector3(bw, 0.25, bd), Vector3(bx, bh + 0.1, bz), roof_mat)

				# Portones metálicos seccionales enrollables en la fachada sur
				var shutter_mat := PBRMaterials.make_metal_material(Color(0.24, 0.28, 0.32), 0.75, 0.42)
				_vis_box(Vector3(6.5, 4.2, 0.2), Vector3(bx - 8.0, 2.1, bz + bd * 0.5 + 0.1), shutter_mat)
				_vis_box(Vector3(6.5, 4.2, 0.2), Vector3(bx + 8.0, 2.1, bz + bd * 0.5 + 0.1), shutter_mat)
				_vis_box(Vector3(4.5, 0.2, 2.4), Vector3(36.0, 3.2, -12.3 + 1.2), iron_mat)

				# Conductos industriales de ventilación en la azotea
				_vis_cyl(0.75, 3.2, Vector3(bx - 12.0, bh + 1.6, bz - 12.0), iron_mat)
				_vis_box(Vector3(3.2, 1.8, 2.2), Vector3(bx - 14.0, bh + 0.9, bz), cg_mat)

				_add_neon_sign("CYBER-GEAR TALLER", Color(0.16, 0.88, 0.96), Vector3(bx, 9.2, bz + bd * 0.5 + 0.35))

			elif is_kuroshio:
				# HOTEL KUROSHIO (Gran hotel metropolitano de lujo con pórtico de columnas)
				bh = 28.0
				var b_mat := PBRMaterials.make_building_facade_material(Color(0.12, 0.13, 0.16), 42.0, night_f, wetness * 0.8)
				active_facade_mats.append(b_mat)
				_create_solid_box(Vector3(bw, bh, bd), Vector3(bx, bh * 0.5, bz), b_mat)


				# Ático escalonado superior
				_create_solid_box(Vector3(36.0, 6.0, 36.0), Vector3(bx, bh + 3.0, bz), b_mat)
				_vis_box(Vector3(36.0, 0.25, 36.0), Vector3(bx, bh + 6.1, bz), roof_mat)

				# Columnas clásicas en el pórtico de entrada (h = 6.0m)
				var marble_mat := PBRMaterials.make_pbr_standard(Color(0.82, 0.82, 0.84), 0.28, 0.05)
				for col_x in [-6.0, -2.0, 2.0, 6.0]:
					_vis_cyl(0.42, 6.0, Vector3(bx + col_x, 3.0, bz + bd * 0.5 + 1.8), marble_mat)
				_vis_box(Vector3(16.0, 0.6, 3.8), Vector3(bx, 6.3, bz + bd * 0.5 + 1.8), marble_mat)
				_vis_box(Vector3(14.0, 5.2, 0.2), Vector3(bx, 2.6, bz + bd * 0.5 + 0.15), win_glow_mat)

				_add_neon_sign("HOTEL KUROSHIO", Color(0.96, 0.22, 0.32), Vector3(bx, 10.5, bz + bd * 0.5 + 0.35))

			elif is_synth_club:
				# SYNTH-CLUB 404 (Club nocturno ciberpunk)
				bh = 18.0
				var club_mat := PBRMaterials.make_metal_material(Color(0.08, 0.09, 0.12), 0.85, 0.25)
				_create_solid_box(Vector3(bw, bh, bd), Vector3(bx, bh * 0.5, bz), club_mat)
				_vis_box(Vector3(bw, 0.25, bd), Vector3(bx, bh + 0.1, bz), roof_mat)

				# Bandas de neón horizontales magenta/cian en la fachada
				var neon_mag := PBRMaterials.make_neon_material(Color(0.85, 0.18, 0.95), 3.8)
				var neon_cy := PBRMaterials.make_neon_material(Color(0.16, 0.92, 0.98), 3.8)
				_vis_box(Vector3(44.0, 0.18, 0.12), Vector3(bx, 6.0, bz + bd * 0.5 + 0.12), neon_mag)
				_vis_box(Vector3(44.0, 0.18, 0.12), Vector3(bx, 8.5, bz + bd * 0.5 + 0.12), neon_cy)
				_vis_box(Vector3(44.0, 0.18, 0.12), Vector3(bx, 11.0, bz + bd * 0.5 + 0.12), neon_mag)

				_add_neon_sign("SYNTH-CLUB 404", Color(0.85, 0.20, 0.98), Vector3(bx, 14.2, bz + bd * 0.5 + 0.35))

			else:
				# 13 Manzanas con 4 Arquetipos Arquitectónicos Distintos
				var arch_type: int = abs(int(bx * 7 + bz * 13)) % 4

				if arch_type == 0:
					# ARQUETIPO 1: Rascacielos Corporativo de Cristal y Acero (Escalonado en 3 niveles con antena espigada)
					bh = rng.randf_range(38.0, 46.0)
					var b_seed: float = absf(bx * 0.13 + bz * 0.29) + 1.0
					var glass_b_mat := PBRMaterials.make_building_facade_material(Color(0.09, 0.13, 0.18), b_seed, night_f, wetness * 0.8)
					active_facade_mats.append(glass_b_mat)

					# Base podio comercial (48x48 x 12m)

					_create_solid_box(Vector3(48.0, 12.0, 48.0), Vector3(bx, 6.0, bz), glass_b_mat)
					# Torre media retranqueada (36x36 x 16m)
					_create_solid_box(Vector3(36.0, 16.0, 36.0), Vector3(bx, 20.0, bz), glass_b_mat)
					# Torre alta cúspide (26x26)
					var h_top: float = bh - 28.0
					_create_solid_box(Vector3(26.0, h_top, 26.0), Vector3(bx, 28.0 + h_top * 0.5, bz), glass_b_mat)
					_vis_box(Vector3(26.0, 0.25, 26.0), Vector3(bx, bh + 0.1, bz), roof_mat)

					# Marquesina de entrada
					_vis_box(Vector3(12.0, 0.3, 4.0), Vector3(bx, 4.2, bz + 24.0 + 2.0), iron_mat)

					# Aguja / Antena de telecomunicaciones en la azotea (8m) con baliza roja
					_vis_cyl(0.12, 8.0, Vector3(bx, bh + 4.0, bz), iron_mat)
					var beacon_mat := PBRMaterials.make_neon_material(Color(1.0, 0.12, 0.14), 4.5)
					_vis_box(Vector3(0.4, 0.4, 0.4), Vector3(bx, bh + 8.1, bz), beacon_mat)
					var beacon_l := OmniLight3D.new()
					beacon_l.light_color = Color(1.0, 0.12, 0.14)
					beacon_l.light_energy = 2.0
					beacon_l.omni_range = 14.0
					beacon_l.position = Vector3(bx, bh + 8.2, bz)
					add_child(beacon_l)

				elif arch_type == 1:
					# ARQUETIPO 2: Edificio Metropolitano de Ladrillo y Mampostería con Locales Comerciales
					bh = rng.randf_range(22.0, 27.0)
					_create_solid_box(Vector3(bw, bh, bd), Vector3(bx, bh * 0.5, bz), brick_mat)
					_vis_box(Vector3(bw, 0.25, bd), Vector3(bx, bh + 0.1, bz), roof_mat)

					# Cornisas arquitectónicas horizontales de piedra
					var stone_mat := PBRMaterials.make_concrete_material(Color(0.55, 0.52, 0.48), 0.65)
					_vis_box(Vector3(bw + 0.4, 0.45, bd + 0.4), Vector3(bx, 4.8, bz), stone_mat)
					_vis_box(Vector3(bw + 0.4, 0.45, bd + 0.4), Vector3(bx, bh * 0.6, bz), stone_mat)
					_vis_box(Vector3(bw + 0.6, 0.65, bd + 0.6), Vector3(bx, bh + 0.15, bz), stone_mat)

					# Escaparates comerciales en la planta baja con iluminación cálida
					for shop_i in [-14.0, 0.0, 14.0]:
						_vis_box(Vector3(8.0, 3.4, 0.15), Vector3(bx + shop_i, 1.8, bz + bd * 0.5 + 0.1), win_glow_mat)
						_vis_box(Vector3(9.2, 0.25, 1.6), Vector3(bx + shop_i, 3.8, bz + bd * 0.5 + 0.8), iron_mat)

					# Tanque de agua tradicional sobre torre de acero en la azotea
					_vis_cyl(0.08, 3.8, Vector3(bx + 10.0, bh + 1.9, bz + 10.0), iron_mat)
					_vis_cyl(0.08, 3.8, Vector3(bx + 14.0, bh + 1.9, bz + 10.0), iron_mat)
					_vis_cyl(0.08, 3.8, Vector3(bx + 10.0, bh + 1.9, bz + 14.0), iron_mat)
					_vis_cyl(0.08, 3.8, Vector3(bx + 14.0, bh + 1.9, bz + 14.0), iron_mat)
					_vis_cyl(1.85, 3.2, Vector3(bx + 12.0, bh + 5.2, bz + 12.0), wood_mat)
					_vis_cyl(2.0, 0.2, Vector3(bx + 12.0, bh + 6.9, bz + 12.0), iron_mat)

				elif arch_type == 2:
					# ARQUETIPO 3: Torre Comercial con Gran Valla Publicitaria Digital Iluminada
					bh = rng.randf_range(28.0, 35.0)
					var b_seed: float = absf(bx * 0.17 + bz * 0.31) + 1.0
					var dark_c_mat := PBRMaterials.make_building_facade_material(Color(0.11, 0.12, 0.14), b_seed, night_f, wetness * 0.8)
					active_facade_mats.append(dark_c_mat)
					_create_solid_box(Vector3(bw, bh, bd), Vector3(bx, bh * 0.5, bz), dark_c_mat)
					_vis_box(Vector3(bw, 0.25, bd), Vector3(bx, bh + 0.1, bz), roof_mat)


					# Valla publicitaria digital HD mirando a la avenida
					if billboard_textures.size() > 0:
						var tex: Texture2D = billboard_textures[billboard_idx % billboard_textures.size()]
						billboard_idx += 1
						var bb_mat := PBRMaterials.make_billboard_material(tex, 1.8)
						var bb_facing_z: bool = (absf(bz) < 60.0)
						if bb_facing_z:
							var f_dir: float = 1.0 if bz < 0.0 else -1.0
							_vis_box(Vector3(14.0, 7.8, 0.35), Vector3(bx, 16.0, bz + f_dir * (bd * 0.5 + 0.3)), iron_mat)
							_vis_box(Vector3(13.6, 7.4, 0.08), Vector3(bx, 16.0, bz + f_dir * (bd * 0.5 + 0.5)), bb_mat)
							var bb_l := OmniLight3D.new()
							bb_l.light_color = Color(0.85, 0.90, 1.0)
							bb_l.light_energy = 2.5
							bb_l.omni_range = 14.0
							bb_l.position = Vector3(bx, 16.0, bz + f_dir * (bd * 0.5 + 2.5))
							add_child(bb_l)
						else:
							var f_dir: float = 1.0 if bx < 0.0 else -1.0
							_vis_box(Vector3(0.35, 7.8, 14.0), Vector3(bx + f_dir * (bw * 0.5 + 0.3), 16.0, bz), iron_mat)
							_vis_box(Vector3(0.08, 7.4, 13.6), Vector3(bx + f_dir * (bw * 0.5 + 0.5), 16.0, bz), bb_mat)
							var bb_l := OmniLight3D.new()
							bb_l.light_color = Color(0.85, 0.90, 1.0)
							bb_l.light_energy = 2.5
							bb_l.omni_range = 14.0
							bb_l.position = Vector3(bx + f_dir * (bw * 0.5 + 2.5), 16.0, bz)
							add_child(bb_l)

					# Unidades HVAC en azotea
					_vis_box(Vector3(4.2, 2.2, 2.8), Vector3(bx - 10.0, bh + 1.1, bz - 8.0), iron_mat)
					_vis_box(Vector3(3.6, 2.0, 2.4), Vector3(bx - 10.0, bh + 1.0, bz + 8.0), iron_mat)

				else:
					# ARQUETIPO 4: Edificio Brutalista / Corporativo con Aletas Verticales y Antena Parabólica
					bh = rng.randf_range(20.0, 26.0)
					var b_seed: float = absf(bx * 0.23 + bz * 0.19) + 2.0
					var conc_b_mat := PBRMaterials.make_building_facade_material(Color(0.15, 0.16, 0.18), b_seed, night_f, wetness * 0.8)
					active_facade_mats.append(conc_b_mat)
					_create_solid_box(Vector3(bw, bh, bd), Vector3(bx, bh * 0.5, bz), conc_b_mat)
					_vis_box(Vector3(bw, 0.25, bd), Vector3(bx, bh + 0.1, bz), roof_mat)


					# Aletas arquitectónicas verticales en fachada
					var fin_mat := PBRMaterials.make_concrete_material(Color(0.28, 0.30, 0.34), 0.72)
					for fin_i in range(-20, 21, 5):
						_vis_box(Vector3(0.35, bh - 6.0, 0.65), Vector3(bx + float(fin_i), bh * 0.5 + 3.0, bz + bd * 0.5 + 0.35), fin_mat)

					# Antena parabólica satelital en azotea
					_vis_cyl(0.12, 1.8, Vector3(bx - 12.0, bh + 0.9, bz - 12.0), iron_mat)
					_vis_cyl(1.4, 0.25, Vector3(bx - 12.0, bh + 2.0, bz - 12.0), iron_mat, Vector3(38.0, 25.0, 0.0))

			# Registrar para el radar minimapa
			city_blocks.append({
				"rect": Rect2(bx - bw * 0.5, bz - bd * 0.5, bw, bd),
				"height": bh
			})

	# 5. Mobiliario Urbano
	_build_streetlamps()
	_build_traffic_signals(road_coords)
	_build_urban_street_props(block_centers)

func _add_neon_sign(text: String, col: Color, pos: Vector3) -> void:
	var l3d := Label3D.new()
	l3d.text = text
	l3d.font_size = 96
	l3d.modulate = col
	l3d.outline_modulate = Color.BLACK
	l3d.position = pos
	add_child(l3d)

	var neon_l := OmniLight3D.new()
	neon_l.light_color = col
	neon_l.light_energy = 2.8 if SettingsManager.night_mode else 0.9
	neon_l.omni_range = 16.0
	neon_l.distance_fade_enabled = true
	neon_l.distance_fade_begin = 45.0
	neon_l.distance_fade_length = 15.0
	neon_l.position = pos + Vector3(0.0, -1.5, 2.0)
	add_child(neon_l)

func _build_streetlamps() -> void:
	var pole_mat := PBRMaterials.make_metal_material(Color(0.12, 0.14, 0.17), 0.82, 0.32)
	var bulb_mat := PBRMaterials.make_neon_material(Color(1.0, 0.82, 0.52), 4.2)

	# Farolas curvas estilizadas con atenuación suave por distancia
	for lx in range(-120, 121, 30):
		if absf(lx) < 12.0 or absf(absf(lx) - 75.0) < 12.0:
			continue
		for lz in [-9.4, 9.4]:
			var dir_z: float = 1.0 if lz < 0.0 else -1.0
			_vis_cyl(0.14, 6.4, Vector3(lx, 3.2, lz), pole_mat)
			_vis_cyl(0.22, 0.45, Vector3(lx, 0.22, lz), pole_mat)
			_vis_cyl(0.08, 1.8, Vector3(lx, 6.3, lz + dir_z * 0.9), pole_mat, Vector3(90.0, 0.0, 0.0))
			_vis_box(Vector3(0.35, 0.16, 0.72), Vector3(lx, 6.35, lz + dir_z * 1.8), pole_mat)
			_vis_box(Vector3(0.28, 0.06, 0.60), Vector3(lx, 6.26, lz + dir_z * 1.8), bulb_mat)

			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.76, 0.45)
			l.light_energy = 2.8 if SettingsManager.night_mode else 0.75
			l.omni_range = 21.0
			l.distance_fade_enabled = true
			l.distance_fade_begin = 55.0
			l.distance_fade_length = 20.0
			l.position = Vector3(lx, 6.0, lz + dir_z * 1.8)
			add_child(l)
			streetlamps.append(l)


func _build_traffic_signals(road_coords: Array) -> void:
	var signal_post_mat := PBRMaterials.make_metal_material(Color(0.16, 0.18, 0.20), 0.85, 0.35)
	var signal_box_mat := PBRMaterials.make_metal_material(Color(0.08, 0.09, 0.10), 0.80, 0.40)
	var red_l_mat := PBRMaterials.make_neon_material(Color(0.98, 0.12, 0.12), 4.5)
	var amb_l_mat := PBRMaterials.make_neon_material(Color(0.98, 0.72, 0.10), 4.5)
	var grn_l_mat := PBRMaterials.make_neon_material(Color(0.12, 0.95, 0.35), 4.5)

	for ix in road_coords:
		for iz in road_coords:
			for corner in [Vector2(-9.2, -9.2), Vector2(9.2, 9.2)]:
				var sx: float = ix + corner.x
				var sz: float = iz + corner.y
				_vis_cyl(0.14, 5.6, Vector3(sx, 2.8, sz), signal_post_mat)
				var arm_dir: float = -1.0 if corner.x > 0.0 else 1.0
				_vis_cyl(0.08, 4.6, Vector3(sx + arm_dir * 2.3, 5.4, sz), signal_post_mat, Vector3(0.0, 0.0, 90.0))
				var box_pos := Vector3(sx + arm_dir * 3.8, 5.2, sz)
				_vis_box(Vector3(0.36, 1.0, 0.32), box_pos, signal_box_mat)
				_vis_box(Vector3(0.18, 0.22, 0.05), box_pos + Vector3(0.0, 0.32, -0.17), red_l_mat)
				_vis_box(Vector3(0.18, 0.22, 0.05), box_pos + Vector3(0.0, 0.0, -0.17), amb_l_mat)
				_vis_box(Vector3(0.18, 0.22, 0.05), box_pos + Vector3(0.0, -0.32, -0.17), grn_l_mat)

func _build_urban_street_props(block_centers: Array) -> void:
	var hydrant_red := PBRMaterials.make_metal_material(Color(0.85, 0.14, 0.16), 0.78, 0.32)
	var hydrant_brass := PBRMaterials.make_metal_material(Color(0.88, 0.72, 0.24), 0.95, 0.18)
	var dumpster_green := PBRMaterials.make_metal_material(Color(0.12, 0.28, 0.20), 0.75, 0.45)
	var plastic_lid := PBRMaterials.make_pbr_standard(Color(0.06, 0.06, 0.07), 0.80, 0.05)
	var bench_wood := PBRMaterials.make_pbr_standard(Color(0.42, 0.26, 0.16), 0.72, 0.0)
	var bench_iron := PBRMaterials.make_metal_material(Color(0.14, 0.15, 0.17), 0.88, 0.30)
	var glass_panel := PBRMaterials.make_glass_material(Color(0.18, 0.24, 0.30), 0.08)

	# 1. Bocas de Incendio (Hidrantes) en las esquinas
	for hx in [-84.0, -66.0, -9.0, 9.0, 66.0, 84.0]:
		for hz in [-84.0, 84.0]:
			_vis_cyl(0.16, 0.72, Vector3(hx, 0.44, hz), hydrant_red)
			_vis_cyl(0.19, 0.15, Vector3(hx, 0.76, hz), hydrant_red)
			_vis_cyl(0.08, 0.36, Vector3(hx, 0.52, hz), hydrant_brass, Vector3(0.0, 0.0, 90.0))

	# 2. Contenedores de Basura Industriales
	for dx in [-105.0, -32.0, 42.0, 105.0]:
		for dz in [-66.5, 66.5]:
			_create_solid_box(Vector3(2.6, 1.4, 1.5), Vector3(dx, 0.8, dz), dumpster_green)
			_vis_box(Vector3(2.65, 0.12, 1.55), Vector3(dx, 1.52, dz), plastic_lid)

	# 3. Paradas de Autobús con Marquesina Acristalada y Banco
	for bx in [-35.0, 35.0]:
		var bz: float = -9.2
		_vis_box(Vector3(4.8, 0.14, 2.0), Vector3(bx, 2.7, bz - 1.0), bench_iron)
		_vis_box(Vector3(4.4, 2.4, 0.06), Vector3(bx, 1.35, bz - 1.9), glass_panel)
		_vis_cyl(0.06, 2.7, Vector3(bx - 2.3, 1.35, bz - 1.0), bench_iron)
		_vis_cyl(0.06, 2.7, Vector3(bx + 2.3, 1.35, bz - 1.0), bench_iron)
		_vis_box(Vector3(3.2, 0.08, 0.42), Vector3(bx, 0.52, bz - 1.4), bench_wood)
		_vis_box(Vector3(0.06, 0.45, 0.42), Vector3(bx - 1.3, 0.30, bz - 1.4), bench_iron)
		_vis_box(Vector3(0.06, 0.45, 0.42), Vector3(bx + 1.3, 0.30, bz - 1.4), bench_iron)

	# 4. Bancos de Calle
	for wx in [-95.0, -65.0, 65.0, 95.0]:
		for wz in [-9.4, 9.4]:
			_vis_box(Vector3(2.2, 0.08, 0.45), Vector3(wx, 0.52, wz), bench_wood)
			_vis_box(Vector3(0.08, 0.45, 0.45), Vector3(wx - 0.9, 0.30, wz), bench_iron)
			_vis_box(Vector3(0.08, 0.45, 0.45), Vector3(wx + 0.9, 0.30, wz), bench_iron)
			_vis_box(Vector3(2.2, 0.38, 0.06), Vector3(wx, 0.74, wz - 0.22 if wz < 0 else wz + 0.22), bench_wood)

func _build_elevated_train() -> void:
	# Puente elevado de hormigón y acero con celosía y vías dobles
	var steel_mat := PBRMaterials.make_metal_material(Color(0.15, 0.17, 0.21), 0.85, 0.38)
	var pillar_mat := PBRMaterials.make_concrete_material(Color(0.24, 0.26, 0.30), 0.78)
	var rail_mat := PBRMaterials.make_metal_material(Color(0.68, 0.72, 0.78), 0.95, 0.22)
	var sleeper_mat := PBRMaterials.make_pbr_standard(Color(0.28, 0.22, 0.16), 0.85, 0.0)

	# Tablero principal del puente elevado
	_create_solid_box(Vector3(360.0, 1.2, 7.6), Vector3(0, 9.5, 0), steel_mat)

	# Pilares macizos de soporte de hormigón y vigas transversales
	for px in range(-150, 151, 30):
		_create_solid_box(Vector3(1.6, 9.0, 1.6), Vector3(px, 4.5, -3.5), pillar_mat)
		_create_solid_box(Vector3(1.6, 9.0, 1.6), Vector3(px, 4.5, 3.5), pillar_mat)
		_create_solid_box(Vector3(1.8, 0.8, 8.6), Vector3(px, 8.6, 0), steel_mat)

	# Barandillas de celosía Warren en los laterales del puente
	for side_z in [-3.7, 3.7]:
		_vis_box(Vector3(360.0, 0.22, 0.15), Vector3(0, 10.8, side_z), steel_mat)
		_vis_box(Vector3(360.0, 0.22, 0.15), Vector3(0, 10.3, side_z), steel_mat)
		for gx in range(-175, 176, 5):
			_vis_cyl(0.04, 1.0, Vector3(float(gx), 10.5, side_z), steel_mat)

	# Doble vía férrea con traviesas y rieles de acero brillante
	for tx in range(-178, 179, 2):
		_vis_box(Vector3(0.26, 0.10, 2.6), Vector3(float(tx), 10.15, -1.6), sleeper_mat)
		_vis_box(Vector3(0.26, 0.10, 2.6), Vector3(float(tx), 10.15, 1.6), sleeper_mat)

	_vis_box(Vector3(360.0, 0.12, 0.08), Vector3(0, 10.25, -2.25), rail_mat)
	_vis_box(Vector3(360.0, 0.12, 0.08), Vector3(0, 10.25, -0.95), rail_mat)
	_vis_box(Vector3(360.0, 0.12, 0.08), Vector3(0, 10.25, 0.95), rail_mat)
	_vis_box(Vector3(360.0, 0.12, 0.08), Vector3(0, 10.25, 2.25), rail_mat)

	# Metro nocturno pasando periódicamente por las vías elevadas
	var train_mat := PBRMaterials.make_car_paint_material(Color(0.72, 0.14, 0.18), 0.22, 0.65)
	var win_mat := PBRMaterials.make_glass_material(Color(1.0, 0.94, 0.70), 0.10, Color(1.0, 0.88, 0.55), 2.4)
	var head_neon := PBRMaterials.make_neon_material(Color(1.0, 0.96, 0.86), 5.0)

	for i in range(4):
		var car := Node3D.new()
		car.position = Vector3(-160.0 + i * 15.5, 11.8, 0)
		_vis_box_on(car, Vector3(14.0, 3.2, 3.5), Vector3.ZERO, train_mat)
		_vis_box_on(car, Vector3(12.2, 1.1, 3.6), Vector3(0, 0.45, 0), win_mat)
		if i == 3:
			_vis_box_on(car, Vector3(0.2, 0.45, 0.95), Vector3(7.1, 0.2, 0), head_neon)
			var spot := SpotLight3D.new()
			spot.light_color = Color(1.0, 0.96, 0.85)
			spot.light_energy = 5.5
			spot.spot_range = 45.0
			spot.spot_angle = 32.0
			spot.rotation_degrees = Vector3(0, -90, 0)
			spot.position = Vector3(7.2, 0.2, 0)
			car.add_child(spot)

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
		var q_rain: int = 350 if SettingsManager.graphics_quality == "low" else (650 if SettingsManager.graphics_quality == "medium" else 950)
		rain_particles.amount = q_rain
		rain_particles.lifetime = 0.95
		var pm := ParticleProcessMaterial.new()
		pm.particle_flag_align_y = true
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(26.0, 1.0, 26.0)
		pm.direction = Vector3(0.14, -1.0, 0.0)
		pm.spread = 3.5
		pm.initial_velocity_min = 26.0
		pm.initial_velocity_max = 34.0
		rain_particles.process_material = pm

		var drop_mesh := BoxMesh.new()
		drop_mesh.size = Vector3(0.024, 0.92, 0.024)
		var drop_mat := StandardMaterial3D.new()
		drop_mat.albedo_color = Color(0.72, 0.86, 1.0, 0.38)
		drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		drop_mesh.material = drop_mat
		rain_particles.draw_pass_1 = drop_mesh
		rain_particles.position = Vector3(0, 16.0, 0)
		rain_particles.emitting = false
		player.add_child(rain_particles)

		# Partículas de hojas y papeles urbanos mecidas por el viento
		wind_particles = GPUParticles3D.new()
		wind_particles.amount = 40
		wind_particles.lifetime = 2.4
		var wpm := ParticleProcessMaterial.new()
		wpm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		wpm.emission_box_extents = Vector3(22.0, 3.0, 22.0)
		wpm.direction = Vector3(1.0, -0.15, 0.2)
		wpm.spread = 24.0
		wpm.initial_velocity_min = 6.0
		wpm.initial_velocity_max = 16.0
		wpm.angular_velocity_min = -180.0
		wpm.angular_velocity_max = 180.0
		wpm.scale_min = 0.5
		wpm.scale_max = 1.3
		wind_particles.process_material = wpm

		var leaf_mesh := QuadMesh.new()
		leaf_mesh.size = Vector2(0.18, 0.12)
		var leaf_mat := StandardMaterial3D.new()
		leaf_mat.albedo_color = Color(0.85, 0.85, 0.88, 0.85)
		leaf_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		leaf_mesh.material = leaf_mat
		wind_particles.draw_pass_1 = leaf_mesh
		wind_particles.position = Vector3(0, 2.5, 0)
		wind_particles.emitting = false
		player.add_child(wind_particles)


		# Vapor atmosférico sutil saliendo de rejillas callejeras
		if SettingsManager.graphics_quality != "low":
			var steam_mat := StandardMaterial3D.new()
			steam_mat.albedo_color = Color(0.75, 0.82, 0.92, 0.065)
			steam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			steam_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
			steam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			var steam_mesh := SphereMesh.new()
			steam_mesh.radius = 0.45
			steam_mesh.height = 0.70
			steam_mesh.material = steam_mat

			for sx in [-30.0, -10.0, 22.0]:
				var steam := GPUParticles3D.new()
				steam.amount = 22
				steam.lifetime = 2.6
				var spm := ParticleProcessMaterial.new()
				spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
				spm.emission_box_extents = Vector3(0.45, 0.05, 0.45)
				spm.direction = Vector3(0.08, 1.0, 0.0)
				spm.spread = 18.0
				spm.initial_velocity_min = 0.9
				spm.initial_velocity_max = 1.6
				spm.gravity = Vector3(0.2, 0.4, 0.0)
				spm.scale_min = 0.8
				spm.scale_max = 2.2
				steam.process_material = spm
				steam.draw_pass_1 = steam_mesh
				steam.position = Vector3(sx, 0.15, -6.2 if sx < 0.0 else 6.2)
				add_child(steam)

	# 2. Cabina Telefónica sonando bajo las vías del tren (X=-12, Z=-9.5)
	payphone = Payphone3D.new()
	payphone.global_position = Vector3(-12.0, 0, -9.5)
	add_child(payphone)

	# 3. Vehículos estacionados en la avenida urbana y en la costa
	var veh_configs := [
		[Vector3(-42.0, 0.1, -3.5), "sports_car", -PI / 2.0],
		[Vector3(-25.0, 0.1, 4.0), "mafia_sedan", -PI / 2.0],
		[Vector3(8.0, 0.1, -3.5), "motorcycle", 0.0],
		[Vector3(24.0, 0.1, 4.0), "sports_car", PI / 2.0],
		[Vector3(-256.0, 0.25, -10.0), "sports_car", -PI / 2.0],
		[Vector3(-256.0, 0.25, 45.0), "mafia_sedan", -PI / 2.0],
		[Vector3(-398.0, 16.3, -272.0), "sports_car", 0.0]
	]
	for vc in veh_configs:
		var v := Vehicle3D.new()
		v.setup(vc[0], vc[1], vc[2])
		add_child(v)
		city_vehicles.append(v)


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
	hud.update_weapon(player.weapons[player.weapon_idx])
	hud.update_health(player.health, player.max_health)
	hud.update_cash(GameState.cash)

	player.health_changed.connect(func(hp, mhp): hud.update_health(hp, mhp))
	player.weapon_changed.connect(func(w): hud.update_weapon(w))
	player.prompt_changed.connect(func(txt): hud.set_prompt(txt))
	player.payphone_called.connect(func(first_line):
		in_call_dialogue = true
		player.dialogue_locked = true
		hud.set_letterbox(true)
		hud.set_subtitle(first_line + "  [ESPACIO / CLIC]")
	)
	player.player_died.connect(func():
		get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")
	)
	payphone.call_finished.connect(func():
		in_call_dialogue = false
		player.dialogue_locked = false
		hud.set_letterbox(false)
		if CampaignManager.current_chapter == CampaignManager.CHAPTER_01:
			active_mission_state = "CH1_GO_HOTEL"
			target_gps = Vector2(-37.5, -11.0)
			hud.set_subtitle("Misión: Desplázate al pórtico del Hotel Kuroshio (al noroeste) y busca el maletín de evidencias.")
		else:
			active_mission_state = "HUNT_TARGET"
			target_gps = Vector2(36.0, -12.3)
			hud.set_subtitle("Misión: Entra al Taller Cyber-Gear [E] (o escala por la azotea) y elimina a " + current_op["target_name"] + ".")
	)

func _setup_chapter_mission() -> void:
	var cur_chap: String = CampaignManager.current_chapter
	var p_name: String = "Nagumo" if GameState.selected_char == "nagumo" else "Shado"

	if cur_chap == CampaignManager.CHAPTER_01:
		active_mission_state = "CH1_ANSWER_CALL"
		target_gps = Vector2(-12.0, -9.5)
		hud.set_subtitle("Cipher: El teléfono público suena bajo las vías del tren. Acércate y responde [E].")
		var lines: Array = [
			"Cipher: Al habla... Sé que sobreviviste a la emboscada de la cena, " + p_name + ".",
			"Cipher: La masacre no fue una simple purga. El Director Kuroshio vendió tu cabeza a un consorcio internacional.",
			"Cipher: Un escuadrón de limpieza de Kuroshio está ahora mismo en el Hotel Kuroshio destruyendo registros y discos de seguridad.",
			"Cipher: Si quieres la verdad y el nombre del ejecutor que disparó, ve al pórtico del Hotel Kuroshio y recupera el maletín de pruebas antes de que lo quemen.",
			"Cipher: Ten cuidado: los sicarios están armados hasta los dientes. No dejes testigos."
		]
		payphone.set_dialogue_lines(lines)
	else:
		active_mission_state = "HUNT_TARGET"
		target_gps = Vector2(36.0, -12.3)
		hud.set_subtitle("Cipher: Rodrigo 'El Chacal' está en el Taller Cyber-Gear al este. Elimínalo para vengar la traición.")

func _spawn_ch1_encounter() -> void:
	# 1. Maletín dorado en el pórtico de mármol del Hotel Kuroshio
	ch1_briefcase = Pickup3D.new()
	ch1_briefcase.setup(Vector3(-37.5, 0.45, -11.2), "briefcase", 1)
	ch1_briefcase.item_collected.connect(func(_type):
		ch1_briefcase_collected = true
		AudioManager.play_sfx("alert")
		if ch1_sicarios.is_empty():
			_trigger_ch1_escape()
		else:
			hud.set_subtitle("¡Maletín asegurado! Ahora neutraliza a los sicarios restantes de Kuroshio.")
	)
	add_child(ch1_briefcase)

	# 2. Dos sicarios de limpieza
	var s_spawns := [
		Vector3(-42.0, 0.5, -11.0),
		Vector3(-33.0, 0.5, -11.0)
	]
	for sp in s_spawns:
		var en := Enemy3D.new()
		en.setup(sp, false, "Sicario de Limpieza")
		en.enemy_killed.connect(func(_boss, _pos):
			ch1_sicarios.erase(en)
			if ch1_sicarios.is_empty() and ch1_briefcase_collected:
				_trigger_ch1_escape()
			elif ch1_sicarios.is_empty() and not ch1_briefcase_collected:
				target_gps = Vector2(-37.5, -11.2)
				hud.set_subtitle("¡Sicarios neutralizados! Recoge el maletín dorado en los escalones del hotel.")
		)
		add_child(en)
		ch1_sicarios.append(en)

func _trigger_ch1_escape() -> void:
	active_mission_state = "CH1_ESCAPE"
	target_gps = Vector2(-65.0, 0.0)
	hud.set_subtitle("Cipher: 'Los datos señalan que Rodrigo El Chacal opera en el taller Cyber-Gear'. ¡Aléjate de la zona caliente!")

func _on_chapter_1_completed() -> void:
	var rewards: Dictionary = CampaignManager.complete_chapter(CampaignManager.CHAPTER_01)
	hud.update_cash(GameState.cash)
	AudioManager.play_sfx("alert")
	hud.show_mission_completed(
		"CAPÍTULO 1",
		"UNA LLAMADA EN LA OSCURIDAD",
		int(rewards.get("cash", 750)),
		str(rewards.get("weapon", "m4")),
		"Capítulo 2: Sombras del pasado",
		func():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/ui/mission_board.tscn")
	)

func _on_enemy_killed(is_boss: bool, pos: Vector3) -> void:
	GameState.cash += 500 if is_boss else 150
	hud.update_cash(GameState.cash)

	var pk := Pickup3D.new()
	pk.setup(pos + Vector3(0, 0.2, 0), "ammo" if randf() < 0.7 else "medkit", 30)
	add_child(pk)

	if is_boss:
		active_mission_state = "COMPLETE"
		if CampaignManager.current_chapter == CampaignManager.CHAPTER_02:
			var rewards: Dictionary = CampaignManager.complete_chapter(CampaignManager.CHAPTER_02)
			hud.update_cash(GameState.cash)
			AudioManager.play_sfx("alert")
			hud.show_mission_completed(
				"CAPÍTULO 2",
				"SOMBRAS DEL PASADO",
				int(rewards.get("cash", 1200)),
				str(rewards.get("weapon", "smg")),
				"Capítulo 3: La lista negra",
				func():
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					get_tree().change_scene_to_file("res://scenes/ui/mission_board.tscn")
			)
		else:
			GameState.mark_operation_completed(current_op["id"])
			hud.set_subtitle("¡OBJETIVO ELIMINADO! Has vengado a tu madre (+$500). Regresa al menú [ESC].")

func _process(delta: float) -> void:
	# Actualización del ciclo dinámico de tiempo, cielo, iluminación y clima
	_update_dynamic_environment(delta)

	# Mover el metro elevado
	for car in train_cars:
		car.position.x += 24.0 * delta
		if car.position.x > 190.0:
			car.position.x = -190.0

	# Lógica interactiva del Capítulo 1
	if CampaignManager.current_chapter == CampaignManager.CHAPTER_01:
		if active_mission_state == "CH1_GO_HOTEL":
			var hotel_pos := Vector3(-37.5, 0.5, -11.0)
			if player and player.global_position.distance_to(hotel_pos) < 22.0:
				active_mission_state = "CH1_COMBAT"
				target_gps = Vector2(-37.5, -11.2)
				hud.set_subtitle("¡Alerta! Sicarios de limpieza de Kuroshio te han visto. ¡Elimínalos y recupera el maletín!")
				_spawn_ch1_encounter()
		elif active_mission_state == "CH1_ESCAPE":
			var escape_pos := Vector3(-65.0, 0.5, 0.0)
			var in_veh: bool = (player != null and player.current_vehicle != null)
			if player and (player.global_position.distance_to(escape_pos) < 18.0 or in_veh):
				active_mission_state = "CH1_COMPLETE"
				_on_chapter_1_completed()

	# Avanzar diálogo del teléfono
	if in_call_dialogue and (Input.is_action_just_pressed("stealth") or Input.is_action_just_pressed("fire_mouse") or Input.is_action_just_pressed("ui_accept")):
		var next_line := payphone.advance_dialogue()
		if next_line != "":
			hud.set_subtitle(next_line + "  [ESPACIO / CLIC]")

	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/ui/mission_board.tscn")

	if hud and player:
		hud.update_radar(player.global_position, player.get_camera_yaw(), target_gps, city_blocks)

func _update_dynamic_environment(delta: float) -> void:
	var tw = TimeWeatherManager
	if not tw:
		return

	var h_frac: float = float(tw.hour) + float(tw.minute) / 60.0
	var night_f: float = tw.night_factor

	# 1. Ciclo Solar y Lunar Orbital (FASE 2)
	if is_instance_valid(sun_light):
		var sun_pitch: float = 0.0
		var sun_yaw: float = 0.0
		var sun_color := Color(1.0, 0.94, 0.88)
		var sun_energy: float = 1.35

		if h_frac >= 5.5 and h_frac <= 19.0:
			# Día / Atardecer (Sol)
			var day_progress: float = (h_frac - 5.5) / 13.5
			sun_pitch = -sin(day_progress * PI) * 68.0
			sun_yaw = lerpf(-85.0, 85.0, day_progress)

			if h_frac < 7.5:
				# Amanecer dorado/rosado suave
				var dawn_p: float = (h_frac - 5.5) / 2.0
				sun_color = Color(1.0, 0.65, 0.40).lerp(Color(1.0, 0.88, 0.70), dawn_p)
				sun_energy = lerpf(0.5, 1.25, dawn_p)
			elif h_frac > 17.0:
				# Atardecer cálido rojizo
				var dusk_p: float = (h_frac - 17.0) / 2.0
				sun_color = Color(1.0, 0.88, 0.70).lerp(Color(1.0, 0.48, 0.22), dusk_p)
				sun_energy = lerpf(1.25, 0.45, dusk_p)
			else:
				# Mediodía / Tarde plena
				sun_color = Color(1.0, 0.96, 0.90)
				sun_energy = 1.45
		else:
			# Noche / Madrugada (Luna)
			var night_progress: float = (h_frac - 19.0) / 10.5 if h_frac >= 19.0 else (h_frac + 5.0) / 10.5
			sun_pitch = -sin(night_progress * PI) * 44.0
			sun_yaw = lerpf(95.0, -85.0, night_progress)
			sun_color = Color(0.62, 0.76, 1.0)
			sun_energy = 0.32

		# Atenuación por nubosidad o lluvia
		if tw.current_weather in [TimeWeatherManager.WEATHER_CLOUDY, TimeWeatherManager.WEATHER_LIGHT_RAIN]:
			sun_energy *= 0.65
			sun_color = sun_color.lerp(Color(0.7, 0.75, 0.8), 0.45)
		elif tw.current_weather == TimeWeatherManager.WEATHER_MODERATE_RAIN:
			sun_energy *= 0.45
			sun_color = sun_color.lerp(Color(0.55, 0.6, 0.68), 0.6)
		elif tw.current_weather == TimeWeatherManager.WEATHER_THUNDERSTORM:
			sun_energy *= 0.22
			sun_color = Color(0.35, 0.4, 0.5)

		sun_light.rotation_degrees = sun_light.rotation_degrees.lerp(Vector3(sun_pitch, sun_yaw, 0.0), delta * 4.0)
		sun_light.light_color = sun_light.light_color.lerp(sun_color, delta * 3.0)
		sun_light.light_energy = lerpf(sun_light.light_energy, sun_energy, delta * 3.0)

	# 2. Relámpagos durante Tormenta Eléctrica (FASE 5)
	if is_instance_valid(lightning_light):
		lightning_light.light_energy = tw.lightning_flash_energy

	# 3. Transiciones del Cielo Procedural y Niebla Atmosférica (FASE 3)
	if is_instance_valid(sky_material) and is_instance_valid(world_env):
		var target_top := Color(0.12, 0.26, 0.55)
		var target_horiz := Color(0.68, 0.82, 0.95)
		var target_ground := Color(0.18, 0.19, 0.22)
		var target_fog_col := Color(0.65, 0.75, 0.88)
		var target_fog_density: float = 0.0024 * tw.fog_density_mult

		if night_f > 0.05:
			# Noche profunda
			var night_top := Color(0.012, 0.018, 0.045)
			var night_horiz := Color(0.055, 0.065, 0.11)
			var night_ground := Color(0.02, 0.02, 0.03)
			var night_fog := Color(0.04, 0.05, 0.08)
			target_top = target_top.lerp(night_top, night_f)
			target_horiz = target_horiz.lerp(night_horiz, night_f)
			target_ground = target_ground.lerp(night_ground, night_f)
			target_fog_col = target_fog_col.lerp(night_fog, night_f)
		else:
			if h_frac < 8.0:
				target_horiz = Color(0.96, 0.58, 0.38)
				target_top = Color(0.15, 0.20, 0.42)
			elif h_frac > 17.0:
				target_horiz = Color(0.96, 0.48, 0.20)
				target_top = Color(0.18, 0.16, 0.35)

		# Cielo plomizo en tormenta o nublado
		if tw.current_weather in [TimeWeatherManager.WEATHER_CLOUDY, TimeWeatherManager.WEATHER_MODERATE_RAIN, TimeWeatherManager.WEATHER_THUNDERSTORM]:
			var storm_grey := Color(0.20, 0.22, 0.26)
			target_top = target_top.lerp(storm_grey, 0.75)
			target_horiz = target_horiz.lerp(storm_grey * 1.2, 0.75)
			target_fog_col = target_fog_col.lerp(storm_grey, 0.75)

		sky_material.sky_top_color = sky_material.sky_top_color.lerp(target_top, delta * 2.0)
		sky_material.sky_horizon_color = sky_material.sky_horizon_color.lerp(target_horiz, delta * 2.0)
		sky_material.ground_horizon_color = sky_material.ground_horizon_color.lerp(target_ground, delta * 2.0)
		world_env.fog_light_color = world_env.fog_light_color.lerp(target_fog_col, delta * 2.0)
		world_env.fog_density = lerpf(world_env.fog_density, target_fog_density, delta * 1.5)

	# 4. Actualización de Materiales Shaders (Asfalto y Fachadas) (FASE 4)
	for a_mat in active_asphalt_mats:
		a_mat.set_shader_parameter("wetness", tw.wetness)
		a_mat.set_shader_parameter("rain_ripples", tw.rain_ripples)

	for f_mat in active_facade_mats:
		f_mat.set_shader_parameter("night_factor", night_f)
		f_mat.set_shader_parameter("wetness", tw.wetness * 0.8)

	# 5. Farolas Urbanas Reactivas a la Luz del Sol (FASE 7)
	var streetlamp_target_energy: float = 2.8 if (night_f > 0.40 or tw.current_weather in [TimeWeatherManager.WEATHER_THUNDERSTORM, TimeWeatherManager.WEATHER_FOGGY]) else 0.0
	for lamp in streetlamps:
		if is_instance_valid(lamp) and lamp is Light3D:
			lamp.light_energy = lerpf(lamp.light_energy, streetlamp_target_energy, delta * 2.5)

	# 6. Partículas de Lluvia y Viento Reactivas (FASE 4 y FASE 5)
	if is_instance_valid(rain_particles):
		rain_particles.emitting = (tw.rain_intensity > 0.03)
		var ppm: ParticleProcessMaterial = rain_particles.process_material as ParticleProcessMaterial
		if ppm:
			ppm.direction = Vector3(tw.wind_vector.x * 0.35 * tw.wind_strength, -1.0, tw.wind_vector.y * 0.35 * tw.wind_strength)

	if is_instance_valid(wind_particles):
		wind_particles.emitting = (tw.wind_strength > 1.4 or tw.current_weather == TimeWeatherManager.WEATHER_STRONG_WIND)

	# 7. Actualización del Gestor de Sectores del Mundo Abierto (Costa, Océano PBR, Faro, LODs)
	if is_instance_valid(sector_manager) and is_instance_valid(player):
		var is_storm: bool = (tw.current_weather == TimeWeatherManager.WEATHER_THUNDERSTORM)
		sector_manager.update_sectors(delta, player.global_position, night_f, is_storm, tw.wind_strength)


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

func _vis_cyl(radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	_vis_cyl_on(self, radius, height, pos, mat, rot)

func _vis_cyl_on(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
