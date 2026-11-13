extends Node
class_name PBRMaterials

static var _wet_asphalt_shader: Shader = null
static var _facade_shader: Shader = null
static var _ocean_water_shader: Shader = null

static var _asphalt_noise_tex: Texture2D = null
static var _asphalt_normal_tex: Texture2D = null
static var _concrete_noise_tex: Texture2D = null
static var _concrete_normal_tex: Texture2D = null
static var _fabric_normal_tex: Texture2D = null
static var _water_normal_tex: Texture2D = null

static func ensure_textures() -> void:
	if _asphalt_noise_tex != null:
		return

	var a_noise := FastNoiseLite.new()
	a_noise.seed = 42
	a_noise.frequency = 0.035
	a_noise.fractal_octaves = 4
	var a_img: Image = a_noise.get_seamless_image(256, 256, false, false, 0.12, true)
	var a_nrm: Image = a_img.duplicate() as Image
	a_nrm.bump_map_to_normal_map(3.4)
	a_img.generate_mipmaps()
	a_nrm.generate_mipmaps()
	_asphalt_noise_tex = ImageTexture.create_from_image(a_img)
	_asphalt_normal_tex = ImageTexture.create_from_image(a_nrm)

	var c_noise := FastNoiseLite.new()
	c_noise.seed = 108
	c_noise.frequency = 0.065
	c_noise.fractal_octaves = 4
	var c_img: Image = c_noise.get_seamless_image(256, 256, false, false, 0.12, true)
	var c_nrm: Image = c_img.duplicate() as Image
	c_nrm.bump_map_to_normal_map(2.4)
	c_img.generate_mipmaps()
	c_nrm.generate_mipmaps()
	_concrete_noise_tex = ImageTexture.create_from_image(c_img)
	_concrete_normal_tex = ImageTexture.create_from_image(c_nrm)

	var f_noise := FastNoiseLite.new()
	f_noise.seed = 211
	f_noise.frequency = 0.24
	f_noise.fractal_octaves = 3
	var f_img: Image = f_noise.get_seamless_image(256, 256, false, false, 0.10, true)
	f_img.bump_map_to_normal_map(1.6)
	f_img.generate_mipmaps()
	_fabric_normal_tex = ImageTexture.create_from_image(f_img)

	var w_noise := FastNoiseLite.new()
	w_noise.seed = 777
	w_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	w_noise.frequency = 0.045
	w_noise.fractal_octaves = 3
	var w_img: Image = w_noise.get_seamless_image(256, 256, false, false, 0.15, true)
	var w_nrm: Image = w_img.duplicate() as Image
	w_nrm.bump_map_to_normal_map(2.6)
	w_img.generate_mipmaps()
	w_nrm.generate_mipmaps()
	_water_normal_tex = ImageTexture.create_from_image(w_nrm)

static func get_wet_asphalt_shader() -> Shader:
	if _wet_asphalt_shader == null:
		_wet_asphalt_shader = load("res://shaders/pbr_wet_asphalt.gdshader") as Shader
	return _wet_asphalt_shader

static func get_facade_shader() -> Shader:
	if _facade_shader == null:
		_facade_shader = load("res://shaders/pbr_building_facade.gdshader") as Shader
	return _facade_shader

static func get_ocean_water_shader() -> Shader:
	if _ocean_water_shader == null:
		_ocean_water_shader = load("res://shaders/pbr_ocean_water.gdshader") as Shader
	return _ocean_water_shader

static func make_ocean_water_material(wave_amplitude: float = 0.22, wave_speed: float = 0.95) -> ShaderMaterial:
	ensure_textures()
	var mat := ShaderMaterial.new()
	mat.shader = get_ocean_water_shader()
	mat.set_shader_parameter("albedo_shallow", Color(0.08, 0.38, 0.52, 0.88))
	mat.set_shader_parameter("albedo_deep", Color(0.015, 0.065, 0.16, 0.98))
	mat.set_shader_parameter("foam_color", Color(0.92, 0.96, 1.0, 1.0))
	mat.set_shader_parameter("wave_speed", wave_speed)
	mat.set_shader_parameter("wave_amplitude", wave_amplitude)
	mat.set_shader_parameter("depth_distance", 5.5)
	mat.set_shader_parameter("foam_distance", 0.85)
	mat.set_shader_parameter("roughness", 0.06)
	mat.set_shader_parameter("metallic", 0.10)
	mat.set_shader_parameter("wave_normal_tex", _water_normal_tex)
	return mat

static func make_wet_asphalt_material(wetness: float = 0.88, rain_ripples: float = 1.0, base_col: Color = Color(0.055, 0.060, 0.072)) -> ShaderMaterial:
	ensure_textures()
	var mat := ShaderMaterial.new()
	mat.shader = get_wet_asphalt_shader()
	mat.set_shader_parameter("asphalt_color", base_col)
	mat.set_shader_parameter("wetness", wetness)
	mat.set_shader_parameter("rain_ripples", rain_ripples)
	mat.set_shader_parameter("noise_tex", _asphalt_noise_tex)
	mat.set_shader_parameter("normal_tex", _asphalt_normal_tex)
	return mat

static func make_building_facade_material(wall_col: Color, seed_offset: float, night_factor: float, wetness: float) -> ShaderMaterial:
	ensure_textures()
	var mat := ShaderMaterial.new()
	mat.shader = get_facade_shader()
	mat.set_shader_parameter("wall_color", wall_col)
	mat.set_shader_parameter("building_seed", seed_offset)
	mat.set_shader_parameter("night_factor", night_factor)
	mat.set_shader_parameter("wetness", wetness)
	mat.set_shader_parameter("concrete_noise_tex", _concrete_noise_tex)
	mat.set_shader_parameter("concrete_normal_tex", _concrete_normal_tex)
	return mat

static func make_concrete_material(base_col: Color, roughness: float = 0.72, uv_scale: Vector3 = Vector3(0.22, 0.22, 0.22)) -> StandardMaterial3D:
	ensure_textures()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_col
	mat.roughness = roughness
	mat.metallic = 0.02
	mat.normal_enabled = true
	mat.normal_texture = _concrete_normal_tex
	mat.normal_scale = 0.55
	mat.uv1_triplanar = true
	mat.uv1_scale = uv_scale
	return mat

static func make_metal_material(base_col: Color, metallic: float = 0.80, roughness: float = 0.32) -> StandardMaterial3D:
	ensure_textures()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_col
	mat.metallic = metallic
	mat.roughness = roughness
	mat.normal_enabled = true
	mat.normal_texture = _concrete_normal_tex
	mat.normal_scale = 0.22
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.45, 0.45, 0.45)
	return mat

static func make_neon_material(col: Color, energy: float = 3.2) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.18
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy
	return mat

static func make_glass_material(tint: Color, roughness: float = 0.08, emission_col: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = roughness
	mat.metallic = 0.15
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission_col
		mat.emission_energy_multiplier = emission_energy
	return mat

static func make_pbr_standard(base_col: Color, roughness: float = 0.65, metallic: float = 0.0, emission_col: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_col
	mat.roughness = roughness
	mat.metallic = metallic
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission_col
		mat.emission_energy_multiplier = emission_energy
	return mat

static func make_fabric_material(base_col: Color, roughness: float = 0.84, bump_scale: float = 0.28) -> StandardMaterial3D:
	ensure_textures()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_col
	mat.roughness = roughness
	mat.metallic = 0.02
	mat.normal_enabled = true
	mat.normal_texture = _fabric_normal_tex
	mat.normal_scale = bump_scale
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(2.4, 2.4, 2.4)
	return mat

static func make_skin_material(base_col: Color) -> StandardMaterial3D:
	ensure_textures()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_col
	mat.roughness = 0.62
	mat.metallic = 0.0
	mat.subsurf_scatter_enabled = true
	mat.subsurf_scatter_strength = 0.18
	mat.normal_enabled = true
	mat.normal_texture = _fabric_normal_tex
	mat.normal_scale = 0.08
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(3.0, 3.0, 3.0)
	return mat

static func make_leather_material(base_col: Color, roughness: float = 0.24) -> StandardMaterial3D:
	ensure_textures()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_col
	mat.roughness = roughness
	mat.metallic = 0.08
	mat.normal_enabled = true
	mat.normal_texture = _fabric_normal_tex
	mat.normal_scale = 0.15
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(2.0, 2.0, 2.0)
	return mat

static func make_car_paint_material(body_color: Color, roughness: float = 0.16, metallic: float = 0.82) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.88
	mat.clearcoat_roughness = 0.12
	return mat

static func make_brick_material(brick_col: Color, roughness: float = 0.82) -> StandardMaterial3D:
	ensure_textures()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = brick_col
	mat.roughness = roughness
	mat.metallic = 0.02
	mat.normal_enabled = true
	mat.normal_texture = _concrete_normal_tex
	mat.normal_scale = 0.75
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.35, 0.35, 0.35)
	return mat

static func make_billboard_material(tex: Texture2D, emission_strength: float = 1.6) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.25
	mat.metallic = 0.05
	if emission_strength > 0.0:
		mat.emission_enabled = true
		mat.emission_texture = tex
		mat.emission_energy_multiplier = emission_strength
	return mat

static func make_sand_material(base_col: Color = Color(0.84, 0.76, 0.58), roughness: float = 0.88) -> StandardMaterial3D:
	ensure_textures()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_col
	mat.roughness = roughness
	mat.metallic = 0.0
	mat.normal_enabled = true
	mat.normal_texture = _concrete_normal_tex
	mat.normal_scale = 0.35
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.4, 0.4, 0.4)
	return mat

static func make_rock_material(base_col: Color = Color(0.32, 0.30, 0.28), roughness: float = 0.82) -> StandardMaterial3D:
	ensure_textures()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_col
	mat.roughness = roughness
	mat.metallic = 0.05
	mat.normal_enabled = true
	mat.normal_texture = _concrete_normal_tex
	mat.normal_scale = 1.25
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.18, 0.18, 0.18)
	return mat

static func make_wood_material(base_col: Color = Color(0.38, 0.28, 0.18), roughness: float = 0.74) -> StandardMaterial3D:
	ensure_textures()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_col
	mat.roughness = roughness
	mat.metallic = 0.02
	mat.normal_enabled = true
	mat.normal_texture = _fabric_normal_tex
	mat.normal_scale = 0.55
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(0.3, 0.3, 0.3)
	return mat

static func make_foliage_material(base_col: Color = Color(0.18, 0.42, 0.15), roughness: float = 0.45) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_col
	mat.roughness = roughness
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


