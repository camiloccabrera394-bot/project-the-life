extends Node3D
class_name CoastalRegionBuilder

# ==============================================================================
# THE LIFE PROJECT — REGIÓN 5: COSTA, PLAYAS, ACANTILADOS Y OCÉANO PBR
# ==============================================================================
# Esta clase construye de forma modular y optimizada la primera región
# de referencia del mundo abierto, conectada directamente con la Gran Ciudad.
#
# Hardware Target: 60 FPS en NVIDIA GeForce 920MX (Godot 4.7 Forward+)
# ==============================================================================

var lighthouse_light: SpotLight3D = null
var lighthouse_beam_mesh: MeshInstance3D = null
var ocean_mesh_instance: MeshInstance3D = null
var ocean_material: ShaderMaterial = null

var coastal_streetlamps: Array[Light3D] = []

func build_coastal_region(parent: Node3D) -> void:
	# 1. Materiales PBR
	var sand_mat := PBRMaterials.make_sand_material(Color(0.86, 0.77, 0.58), 0.88)
	var wet_sand_mat := PBRMaterials.make_sand_material(Color(0.58, 0.50, 0.38), 0.28)
	var rock_mat := PBRMaterials.make_rock_material(Color(0.36, 0.34, 0.32), 0.85)
	var wood_mat := PBRMaterials.make_wood_material(Color(0.42, 0.32, 0.22), 0.72)
	var concrete_mat := PBRMaterials.make_concrete_material(Color(0.38, 0.40, 0.44), 0.65)
	var road_mat := PBRMaterials.make_wet_asphalt_material(0.85 if SettingsManager.rain_enabled else 0.22, 1.0 if SettingsManager.rain_enabled else 0.0)
	var yellow_mat := PBRMaterials.make_pbr_standard(Color(0.88, 0.70, 0.14), 0.55)
	var white_mat := PBRMaterials.make_pbr_standard(Color(0.82, 0.84, 0.88), 0.55)
	var metal_mat := PBRMaterials.make_metal_material(Color(0.65, 0.68, 0.72), 0.85, 0.35)
	var foliage_mat := PBRMaterials.make_foliage_material(Color(0.16, 0.44, 0.14))
	var bark_mat := PBRMaterials.make_wood_material(Color(0.32, 0.24, 0.16), 0.85)

	# 2. Conectores viales: Salida oeste de la ciudad hacia el bulevar costero
	_build_road_connectors(parent, road_mat, yellow_mat)

	# 3. Gran Bulevar Costero (Ocean Boulevard)
	_build_ocean_boulevard(parent, road_mat, yellow_mat, white_mat, concrete_mat)

	# 4. Carretera panorámica de acantilados (Cliffside Highway)
	_build_cliff_highway(parent, road_mat, yellow_mat, metal_mat, rock_mat)

	# 5. Paseo Marítimo con barandillas y escaleras a la playa
	_build_promenade(parent, concrete_mat, wood_mat, metal_mat)

	# 6. Playa de arena dorada y bajíos marinos
	_build_beach_shore(parent, sand_mat, wet_sand_mat)

	# 7. Acantilados rocosos y salientes
	_build_cliffs(parent, rock_mat)

	# 8. Muelle peatonal de madera (Wooden Pier)
	_build_wooden_pier(parent, wood_mat, metal_mat)

	# 9. Faro Costero con linterna giratoria
	_build_lighthouse(parent, concrete_mat, metal_mat)

	# 10. Océano infinito PBR con refracción y olas
	_build_ocean_surface(parent)

	# 11. Vegetación costera optimizada (Palmeras con MultiMesh)
	_build_palm_trees_multimesh(parent, bark_mat, foliage_mat)

	# 12. Puesto de Salvavidas en la playa
	_build_lifeguard_tower(parent, wood_mat, metal_mat)

# ==============================================================================
# SUB-SISTEMAS DE CONSTRUCCIÓN
# ==============================================================================

func _build_road_connectors(parent: Node3D, road_mat: Material, yellow_mat: Material) -> void:
	# Conexión Avenida Central (Z=0) desde X = -190 (borde ciudad) hasta X = -250 (bulevar)
	_solid_box(parent, Vector3(64.0, 0.35, 16.0), Vector3(-220.0, 0.02, 0.0), road_mat)
	_vis_box(parent, Vector3(64.0, 0.05, 0.22), Vector3(-220.0, 0.21, 0.0), yellow_mat)

	# Conexión Avenida Sur (Z=75) desde X = -190 hasta X = -250
	_solid_box(parent, Vector3(64.0, 0.35, 16.0), Vector3(-220.0, 0.02, 75.0), road_mat)
	_vis_box(parent, Vector3(64.0, 0.05, 0.22), Vector3(-220.0, 0.21, 75.0), yellow_mat)

	# Aceras y terreno de transición urbana a costera
	var trans_mat := PBRMaterials.make_concrete_material(Color(0.24, 0.26, 0.28), 0.78)
	_solid_box(parent, Vector3(64.0, 0.50, 40.0), Vector3(-220.0, 0.0, 37.5), trans_mat)
	_solid_box(parent, Vector3(64.0, 0.50, 40.0), Vector3(-220.0, 0.0, -37.5), trans_mat)

func _build_ocean_boulevard(parent: Node3D, road_mat: Material, yellow_mat: Material, white_mat: Material, curb_mat: Material) -> void:
	# Bulevar Costero de 4 carriles a lo largo de X = -252, desde Z = -180 hasta Z = 220 (Longitud 400m)
	_solid_box(parent, Vector3(20.0, 0.35, 400.0), Vector3(-252.0, 0.02, 20.0), road_mat)

	# Doble línea continua amarilla central
	_vis_box(parent, Vector3(0.25, 0.05, 400.0), Vector3(-252.18, 0.21, 20.0), yellow_mat)
	_vis_box(parent, Vector3(0.25, 0.05, 400.0), Vector3(-251.82, 0.21, 20.0), yellow_mat)

	# Líneas blancas de carril y arcén
	_vis_box(parent, Vector3(0.20, 0.05, 400.0), Vector3(-257.0, 0.21, 20.0), white_mat)
	_vis_box(parent, Vector3(0.20, 0.05, 400.0), Vector3(-247.0, 0.21, 20.0), white_mat)

	# Acera este del bulevar (lado ciudad)
	_solid_box(parent, Vector3(5.0, 0.45, 400.0), Vector3(-240.0, 0.05, 20.0), curb_mat)

	# Farolas modernas a lo largo del bulevar
	for z in range(-160, 210, 35):
		_build_boulevard_lamp(parent, Vector3(-241.5, 0.2, float(z)))

func _build_cliff_highway(parent: Node3D, road_mat: Material, yellow_mat: Material, metal_mat: Material, rock_mat: Material) -> void:
	# Carretera sinuosa que sube hacia los acantilados del noroeste desde X=-252, Z=-180 hacia X=-410, Z=-280
	var seg_length := 32.0
	var segments := [
		[Vector3(-256.0, 0.4, -195.0), Vector3(0, -15, 0)],
		[Vector3(-268.0, 2.2, -222.0), Vector3(0, -32, 0)],
		[Vector3(-292.0, 5.8, -244.0), Vector3(0, -48, 0)],
		[Vector3(-324.0, 9.6, -260.0), Vector3(0, -62, 0)],
		[Vector3(-360.0, 13.5, -270.0), Vector3(0, -78, 0)],
		[Vector3(-398.0, 16.0, -272.0), Vector3(0, -90, 0)]
	]

	for seg in segments:
		var pos: Vector3 = seg[0]
		var rot: Vector3 = seg[1]
		# Malla de carretera de tramo
		var sb := StaticBody3D.new()
		sb.position = pos
		sb.rotation_degrees = rot
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(12.0, 0.4, seg_length)
		col.shape = bs
		sb.add_child(col)

		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = bs.size
		mi.mesh = bm
		mi.material_override = road_mat
		sb.add_child(mi)

		# Línea divisoria amarilla
		var line := MeshInstance3D.new()
		var lbm := BoxMesh.new()
		lbm.size = Vector3(0.24, 0.06, seg_length)
		line.mesh = lbm
		line.material_override = yellow_mat
		line.position = Vector3(0, 0.21, 0)
		sb.add_child(line)

		# Quitamiedos metálico en el borde del precipicio (lado oeste)
		var guard := MeshInstance3D.new()
		var gbm := BoxMesh.new()
		gbm.size = Vector3(0.25, 0.95, seg_length)
		guard.mesh = gbm
		guard.material_override = metal_mat
		guard.position = Vector3(-5.8, 0.65, 0)
		sb.add_child(guard)

		parent.add_child(sb)

		# Relleno de roca de acantilado bajo la carretera
		_solid_box(parent, Vector3(16.0, pos.y + 2.0, seg_length), Vector3(pos.x, (pos.y - 1.0) * 0.5, pos.z), rock_mat)

func _build_promenade(parent: Node3D, concrete_mat: Material, wood_mat: Material, metal_mat: Material) -> void:
	# Plataforma peatonal del paseo marítimo en X = -272, ancho 18m, largo 380m a altura Y = +2.2m
	_solid_box(parent, Vector3(18.0, 1.2, 380.0), Vector3(-272.0, 1.6, 20.0), concrete_mat)

	# Pasarela superior de tablas de madera marina
	_vis_box(parent, Vector3(8.0, 0.08, 380.0), Vector3(-274.0, 2.25, 20.0), wood_mat)

	# Barandilla protectora náutica continua frente al mar (en X = -280.8)
	var rail_height := 1.05
	_solid_box(parent, Vector3(0.15, rail_height, 380.0), Vector3(-280.8, 2.7, 20.0), metal_mat)

	# Postes náuticos y farolas costeras
	for z in range(-150, 190, 25):
		_build_coastal_lamp(parent, Vector3(-280.2, 2.2, float(z)))

	# 3 Grandes escaleras de descenso a la playa
	for ez in [-80.0, 20.0, 120.0]:
		_build_beach_stairs(parent, Vector3(-281.0, 0.0, ez), concrete_mat, metal_mat)

func _build_beach_stairs(parent: Node3D, base_pos: Vector3, step_mat: Material, rail_mat: Material) -> void:
	var num_steps := 8
	var step_w := 6.0
	var step_d := 1.2
	var step_h := 0.28
	for i in range(num_steps):
		var sx := base_pos.x - (i * step_d)
		var sy := 2.2 - (i * step_h)
		_solid_box(parent, Vector3(step_d, 0.35, step_w), Vector3(sx, sy, base_pos.z), step_mat)
	# Pasamanos lateral
	_solid_box(parent, Vector3(num_steps * step_d, 0.1, 0.1), Vector3(base_pos.x - 4.5, 1.6, base_pos.z - 3.0), rail_mat)
	_solid_box(parent, Vector3(num_steps * step_d, 0.1, 0.1), Vector3(base_pos.x - 4.5, 1.6, base_pos.z + 3.0), rail_mat)

func _build_beach_shore(parent: Node3D, sand_mat: Material, wet_sand_mat: Material) -> void:
	# Arena alta y seca: desde X = -281 hasta X = -330, ancho Z de -170 a 210
	_solid_box(parent, Vector3(50.0, 1.0, 380.0), Vector3(-305.0, 0.5, 20.0), sand_mat)

	# Arena húmeda con leve pendiente hacia la línea de marea: desde X = -330 a X = -370
	_solid_box(parent, Vector3(40.0, 0.8, 380.0), Vector3(-350.0, -0.1, 20.0), wet_sand_mat)

	# Lecho marino arenoso sumergido bajo el agua (para absorción PBR en el shader de agua)
	_solid_box(parent, Vector3(80.0, 1.0, 420.0), Vector3(-410.0, -2.5, 20.0), wet_sand_mat)
	_solid_box(parent, Vector3(120.0, 1.0, 460.0), Vector3(-510.0, -7.5, 20.0), wet_sand_mat)

func _build_cliffs(parent: Node3D, rock_mat: Material) -> void:
	# Muralla escarpada de acantilados en el extremo noroeste (X entre -320 y -460, Z entre -120 y -300)
	var cliff_blocks := [
		[Vector3(70.0, 18.0, 80.0), Vector3(-360.0, 8.0, -170.0)],
		[Vector3(90.0, 22.0, 90.0), Vector3(-410.0, 10.0, -230.0)],
		[Vector3(65.0, 15.0, 70.0), Vector3(-330.0, 6.5, -250.0)],
		[Vector3(80.0, 26.0, 80.0), Vector3(-430.0, 12.0, -150.0)]
	]
	for cb in cliff_blocks:
		_solid_box(parent, cb[0], cb[1], rock_mat)

	# Rocas de rompiente semihundidas en la orilla para generar espuma de rompiente
	var breaker_rocks := [
		[Vector3(9.0, 4.5, 11.0), Vector3(-325.0, 0.2, -60.0)],
		[Vector3(12.0, 5.0, 8.0), Vector3(-340.0, 0.4, 45.0)],
		[Vector3(14.0, 6.0, 14.0), Vector3(-370.0, 0.8, -120.0)],
		[Vector3(10.0, 4.0, 12.0), Vector3(-355.0, 0.1, 140.0)],
		[Vector3(16.0, 7.5, 15.0), Vector3(-420.0, 1.5, -100.0)]
	]
	for br in breaker_rocks:
		_solid_box(parent, br[0], br[1], rock_mat)

func _build_wooden_pier(parent: Node3D, wood_mat: Material, metal_mat: Material) -> void:
	# Muelle de madera que avanza desde el paseo marítimo (X = -281) hasta mar adentro (X = -365) en Z = -30
	var pier_length := 84.0
	var pier_width := 8.5
	var pier_pos_x := -281.0 - (pier_length * 0.5)
	var pier_y := 2.2

	# Tablones de la plataforma del muelle
	_solid_box(parent, Vector3(pier_length, 0.4, pier_width), Vector3(pier_pos_x, pier_y, -30.0), wood_mat)

	# Barandillas de madera
	_solid_box(parent, Vector3(pier_length, 0.9, 0.12), Vector3(pier_pos_x, pier_y + 0.65, -30.0 + (pier_width * 0.5)), wood_mat)
	_solid_box(parent, Vector3(pier_length, 0.9, 0.12), Vector3(pier_pos_x, pier_y + 0.65, -30.0 - (pier_width * 0.5)), wood_mat)

	# Pilotes de soporte cilíndricos clavados en el fondo marino
	for px in range(-288, -360, 9):
		for pz in [-33.5, -26.5]:
			_vis_cyl(parent, 0.35, 6.5, Vector3(float(px), 0.0, pz), wood_mat)

	# Glorieta / Mirador al final del muelle
	_solid_box(parent, Vector3(16.0, 0.4, 18.0), Vector3(-365.0, pier_y, -30.0), wood_mat)
	_solid_box(parent, Vector3(16.0, 0.9, 0.15), Vector3(-365.0, pier_y + 0.65, -39.0), wood_mat)
	_solid_box(parent, Vector3(16.0, 0.9, 0.15), Vector3(-365.0, pier_y + 0.65, -21.0), wood_mat)
	_solid_box(parent, Vector3(0.15, 0.9, 18.0), Vector3(-373.0, pier_y + 0.65, -30.0), wood_mat)

	# Bolardos náuticos de amarre
	for bz in [-37.0, -30.0, -23.0]:
		_vis_cyl(parent, 0.22, 0.65, Vector3(-371.5, pier_y + 0.45, bz), metal_mat)

func _build_lighthouse(parent: Node3D, concrete_mat: Material, metal_mat: Material) -> void:
	# Faro sobre la cumbre del acantilado en X = -410, Y = 21.0, Z = -160
	var base_pos := Vector3(-410.0, 21.0, -160.0)

	# Base octogonal / cilíndrica de mampostería
	_vis_cyl(parent, 4.5, 3.0, base_pos + Vector3(0, 1.5, 0), concrete_mat)

	# Fuste cónico / cilíndrico de la torre (altura 22m)
	var tower_mat := PBRMaterials.make_concrete_material(Color(0.88, 0.85, 0.82), 0.62)
	_vis_cyl(parent, 3.4, 20.0, base_pos + Vector3(0, 13.0, 0), tower_mat)

	# Anillos decorativos de color rojo náutico
	var red_mat := PBRMaterials.make_pbr_standard(Color(0.78, 0.16, 0.12), 0.48)
	_vis_cyl(parent, 3.48, 2.5, base_pos + Vector3(0, 8.0, 0), red_mat)
	_vis_cyl(parent, 3.48, 2.5, base_pos + Vector3(0, 16.0, 0), red_mat)

	# Galería y balcón exterior del faro
	_vis_cyl(parent, 4.2, 0.5, base_pos + Vector3(0, 23.2, 0), concrete_mat)
	_solid_box(parent, Vector3(8.4, 1.1, 0.15), base_pos + Vector3(0, 24.0, 4.1), metal_mat)
	_solid_box(parent, Vector3(8.4, 1.1, 0.15), base_pos + Vector3(0, 24.0, -4.1), metal_mat)

	# Linterna de cristal
	var glass_mat := PBRMaterials.make_glass_material(Color(0.8, 0.9, 1.0, 0.35), 0.05, Color(1.0, 0.95, 0.7), 2.5)
	_vis_cyl(parent, 2.8, 3.5, base_pos + Vector3(0, 25.0, 0), glass_mat)

	# Cúpula de remate
	_vis_cyl(parent, 3.0, 1.4, base_pos + Vector3(0, 27.2, 0), red_mat)

	# Foco giratorio nocturno (SpotLight3D)
	var pivot := Node3D.new()
	pivot.name = "LighthousePivot"
	pivot.position = base_pos + Vector3(0, 25.0, 0)
	parent.add_child(pivot)

	var spot := SpotLight3D.new()
	spot.name = "LighthouseBeam"
	spot.light_color = Color(1.0, 0.92, 0.68)
	spot.light_energy = 8.5
	spot.spot_range = 380.0
	spot.spot_angle = 18.0
	spot.spot_attenuation = 1.0
	spot.shadow_enabled = true
	pivot.add_child(spot)
	lighthouse_light = spot

	# Cono volumétrico translúcido para el haz visual del faro
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.3
	cm.bottom_radius = 18.0
	cm.height = 140.0
	beam.mesh = cm
	var beam_mat := StandardMaterial3D.new()
	beam_mat.albedo_color = Color(1.0, 0.95, 0.72, 0.08)
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam.material_override = beam_mat
	beam.position = Vector3(0, 0, -70.0)
	beam.rotation_degrees = Vector3(90, 0, 0)
	pivot.add_child(beam)
	lighthouse_beam_mesh = beam

func _build_ocean_surface(parent: Node3D) -> void:
	# Océano PBR infinito cubriendo desde X = -310 hasta X = -1400 y Z de -800 a 800
	ocean_material = PBRMaterials.make_ocean_water_material(0.24, 0.95)

	var ocean_node := MeshInstance3D.new()
	ocean_node.name = "OceanSurfacePBR"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1100.0, 1600.0)
	plane.subdivide_width = 72
	plane.subdivide_depth = 96
	ocean_node.mesh = plane
	ocean_node.material_override = ocean_material
	ocean_node.position = Vector3(-860.0, 0.0, 0.0)
	parent.add_child(ocean_node)
	ocean_mesh_instance = ocean_node

func _build_palm_trees_multimesh(parent: Node3D, bark_mat: Material, leaf_mat: Material) -> void:
	# Troncos y copas de palmeras generados con MultiMeshInstance3D para cero impacto de rendimiento
	var palm_positions: Array[Vector3] = []

	# Palmeras a lo largo de la mediana ajardinada del Bulevar Costero (X = -262)
	for z in range(-150, 190, 22):
		palm_positions.append(Vector3(-262.0, 0.25, float(z)))

	# Palmeras en el Paseo Marítimo (X = -278)
	for z in range(-130, 170, 28):
		palm_positions.append(Vector3(-278.0, 2.2, float(z)))

	# Palmeras tropicales en la playa de arena
	for z in [-110.0, -40.0, 10.0, 70.0, 130.0]:
		palm_positions.append(Vector3(-295.0, 0.6, z))
		palm_positions.append(Vector3(-315.0, 0.4, z + 12.0))

	var count := palm_positions.size()

	# 1. MultiMesh de Troncos
	var trunk_mm := MultiMesh.new()
	trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
	trunk_mm.instance_count = count
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.38
	trunk_mesh.height = 7.5
	trunk_mm.mesh = trunk_mesh

	var trunk_mmi := MultiMeshInstance3D.new()
	trunk_mmi.multimesh = trunk_mm
	trunk_mmi.material_override = bark_mat
	parent.add_child(trunk_mmi)

	# 2. MultiMesh de Hojas/Copas
	var frond_mm := MultiMesh.new()
	frond_mm.transform_format = MultiMesh.TRANSFORM_3D
	frond_mm.instance_count = count * 5
	var frond_mesh := BoxMesh.new()
	frond_mesh.size = Vector3(4.2, 0.08, 0.95)
	frond_mm.mesh = frond_mesh

	var frond_mmi := MultiMeshInstance3D.new()
	frond_mmi.multimesh = frond_mm
	frond_mmi.material_override = leaf_mat
	parent.add_child(frond_mmi)

	var frond_idx := 0
	for i in range(count):
		var pos: Vector3 = palm_positions[i]
		# Ligera curvatura orgánica en el tronco
		var trunk_t := Transform3D(Basis(), pos + Vector3(0, 3.75, 0))
		trunk_mm.set_instance_transform(i, trunk_t)

		# Colisión individual para no atravesar el tronco de la palmera
		var col := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = 0.4
		cs.height = 7.5
		col.shape = cs
		var sb := StaticBody3D.new()
		sb.position = pos + Vector3(0, 3.75, 0)
		sb.add_child(col)
		parent.add_child(sb)

		# 5 Hojas desplegadas en abanico
		for f in range(5):
			var ang := (f * PI * 2.0 / 5.0) + (i * 0.4)
			var b := Basis(Vector3.UP, ang).rotated(Vector3(cos(ang), 0, sin(ang)), 0.32)
			var f_t := Transform3D(b, pos + Vector3(0, 7.3, 0))
			frond_mm.set_instance_transform(frond_idx, f_t)
			frond_idx += 1

func _build_lifeguard_tower(parent: Node3D, wood_mat: Material, metal_mat: Material) -> void:
	# Caseta de salvavidas estilo Baywatch en X = -320, Z = 25 sobre la arena
	var pos := Vector3(-320.0, 0.4, 25.0)
	# 4 Pilotes de elevación de madera
	_vis_cyl(parent, 0.15, 3.2, pos + Vector3(-1.8, 1.6, -1.8), wood_mat)
	_vis_cyl(parent, 0.15, 3.2, pos + Vector3(1.8, 1.6, -1.8), wood_mat)
	_vis_cyl(parent, 0.15, 3.2, pos + Vector3(-1.8, 1.6, 1.8), wood_mat)
	_vis_cyl(parent, 0.15, 3.2, pos + Vector3(1.8, 1.6, 1.8), wood_mat)

	# Cabina principal
	var cab_mat := PBRMaterials.make_pbr_standard(Color(0.85, 0.22, 0.18), 0.55)
	_solid_box(parent, Vector3(4.2, 2.5, 4.2), pos + Vector3(0, 4.2, 0), cab_mat)

	# Techo a dos aguas
	_solid_box(parent, Vector3(4.8, 0.25, 4.8), pos + Vector3(0, 5.5, 0), wood_mat)

	# Escalera de acceso frontal
	_solid_box(parent, Vector3(1.2, 0.15, 3.5), pos + Vector3(2.5, 1.6, 0), wood_mat)

func _build_boulevard_lamp(parent: Node3D, pos: Vector3) -> void:
	var post_mat := PBRMaterials.make_metal_material(Color(0.24, 0.26, 0.30), 0.85, 0.3)
	_vis_cyl(parent, 0.14, 6.2, pos + Vector3(0, 3.1, 0), post_mat)
	_solid_box(parent, Vector3(1.6, 0.12, 0.12), pos + Vector3(-0.7, 6.1, 0), post_mat)

	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.90, 0.72)
	lamp.light_energy = 2.4
	lamp.omni_range = 18.0
	lamp.omni_attenuation = 1.4
	lamp.position = pos + Vector3(-1.4, 5.9, 0)
	parent.add_child(lamp)
	coastal_streetlamps.append(lamp)

func _build_coastal_lamp(parent: Node3D, pos: Vector3) -> void:
	var post_mat := PBRMaterials.make_metal_material(Color(0.20, 0.22, 0.24), 0.90, 0.25)
	_vis_cyl(parent, 0.10, 4.2, pos + Vector3(0, 2.1, 0), post_mat)

	var lamp := OmniLight3D.new()
	lamp.light_color = Color(0.95, 0.85, 0.65)
	lamp.light_energy = 1.8
	lamp.omni_range = 14.0
	lamp.position = pos + Vector3(0, 4.2, 0)
	parent.add_child(lamp)
	coastal_streetlamps.append(lamp)

# ==============================================================================
# CICLO Y ACTUALIZACIÓN AMBIENTAL
# ==============================================================================

func update_coastal_environment(delta: float, night_factor: float, is_storm: bool, wind_strength: float) -> void:
	# 1. Rotación continua de la linterna del faro en la noche
	if is_instance_valid(lighthouse_light):
		var pivot: Node3D = lighthouse_light.get_parent() as Node3D
		if pivot:
			pivot.rotate_y(delta * 0.75)
		# El haz de luz es más brillante y visible de noche o en tormenta
		var target_energy: float = 8.5 if (night_factor > 0.35 or is_storm) else 0.0
		lighthouse_light.light_energy = lerpf(lighthouse_light.light_energy, target_energy, delta * 2.0)

	if is_instance_valid(lighthouse_beam_mesh):
		var beam_alpha: float = 0.09 if (night_factor > 0.35 or is_storm) else 0.0
		var bm: StandardMaterial3D = lighthouse_beam_mesh.material_override as StandardMaterial3D
		if bm:
			bm.albedo_color.a = lerpf(bm.albedo_color.a, beam_alpha, delta * 2.0)

	# 2. Encendido reactivo de farolas costeras
	var lamp_energy: float = 2.2 if (night_factor > 0.40 or is_storm) else 0.0
	for lamp in coastal_streetlamps:
		if is_instance_valid(lamp):
			lamp.light_energy = lerpf(lamp.light_energy, lamp_energy, delta * 2.5)

	# 3. Olas dinámicas reactivas al viento y clima
	if ocean_material:
		var wave_amp: float = 0.45 if is_storm else (0.22 + wind_strength * 0.06)
		var wave_spd: float = 1.6 if is_storm else 0.95
		ocean_material.set_shader_parameter("wave_amplitude", wave_amp)
		ocean_material.set_shader_parameter("wave_speed", wave_spd)

# ==============================================================================
# HELPERS DE GEOMETRÍA
# ==============================================================================

func _solid_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
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

	parent.add_child(sb)

func _vis_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

func _vis_cyl(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
