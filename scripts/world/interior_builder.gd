extends Node
class_name InteriorBuilder

static func build_chop_shop(parent: Node3D, origin: Vector3, exit_callback: Callable) -> void:
	# Habitación interior de 36m x 28m ubicada en una zona separada (ej. Y = -60) para transiciones instantáneas
	var root := Node3D.new()
	root.name = "InteriorRoom"
	root.position = origin
	parent.add_child(root)

	var floor_mat := PBRMaterials.make_wet_asphalt_material(0.55, 0.0, Color(0.08, 0.09, 0.11))
	var wall_mat := PBRMaterials.make_concrete_material(Color(0.16, 0.18, 0.22), 0.82)
	var neon_cyan := PBRMaterials.make_neon_material(Color(0.16, 0.85, 0.96), 3.4)
	var neon_red := PBRMaterials.make_neon_material(Color(0.95, 0.18, 0.24), 3.4)
	var tool_mat := PBRMaterials.make_metal_material(Color(0.72, 0.12, 0.14), 0.72, 0.30)
	var lift_mat := PBRMaterials.make_metal_material(Color(0.20, 0.24, 0.30), 0.85, 0.38)

	# Suelo y Techo
	_solid_box(root, Vector3(36, 0.6, 28), Vector3(0, -0.3, 0), floor_mat)
	_solid_box(root, Vector3(36, 0.6, 28), Vector3(0, 8.3, 0), wall_mat)

	# 4 Paredes sólidas
	_solid_box(root, Vector3(36, 8, 1), Vector3(0, 4, -14), wall_mat)
	_solid_box(root, Vector3(36, 8, 1), Vector3(0, 4, 14), wall_mat)
	_solid_box(root, Vector3(1, 8, 28), Vector3(-18, 4, 0), wall_mat)
	_solid_box(root, Vector3(1, 8, 28), Vector3(18, 4, 0), wall_mat)

	# Tiras de luz neón en el techo
	for lx in [-9.0, 0.0, 9.0]:
		_vis_box(root, Vector3(6.0, 0.15, 0.3), Vector3(lx, 7.8, -4), neon_cyan)
		_vis_box(root, Vector3(6.0, 0.15, 0.3), Vector3(lx, 7.8, 4), neon_red)
		var l := OmniLight3D.new()
		l.light_color = Color(0.75, 0.92, 1.0) if int(lx) == 0 else Color(0.95, 0.55, 0.65)
		l.light_energy = 2.8
		l.omni_range = 18.0
		l.position = Vector3(lx, 6.5, 0)
		root.add_child(l)

	# 2 Elevadores Hidráulicos con Autos Deportivos encima
	for cx in [-8.0, 6.0]:
		_solid_box(root, Vector3(0.4, 2.2, 0.4), Vector3(cx - 1.6, 1.1, -6), lift_mat)
		_solid_box(root, Vector3(0.4, 2.2, 0.4), Vector3(cx + 1.6, 1.1, -6), lift_mat)
		var car_data := ModelBuilder.build_vehicle_mesh("sports_car")
		car_data["root"].position = Vector3(cx, 1.4, -6)
		root.add_child(car_data["root"])

	# Cajas de herramientas rojas, bancos de trabajo y pilas de neumáticos
	_solid_box(root, Vector3(2.4, 1.2, 1.1), Vector3(-14, 0.6, -9), tool_mat)
	_solid_box(root, Vector3(2.4, 1.2, 1.1), Vector3(14, 0.6, -9), tool_mat)
	_solid_box(root, Vector3(3.2, 1.3, 1.8), Vector3(0, 0.65, 2), lift_mat)
	_solid_box(root, Vector3(1.8, 1.4, 1.8), Vector3(-6, 0.7, 5), tool_mat)

	# Pilas de neumáticos PBR
	var rubber_mat := PBRMaterials.make_pbr_standard(Color(0.065, 0.068, 0.075), 0.85, 0.02)
	for ty in [0.18, 0.52, 0.86, 1.20]:
		_vis_cyl(root, 0.42, 0.30, Vector3(-13.5, ty, -5.5), rubber_mat)
		_vis_cyl(root, 0.42, 0.30, Vector3(-12.5, ty, -5.5), rubber_mat)
	for ty in [0.18, 0.52, 0.86]:
		_vis_cyl(root, 0.42, 0.30, Vector3(-13.0, ty, -4.6), rubber_mat)

	# Grúa pluma de motor / Polipasto hidráulico en rojo industrial
	_solid_box(root, Vector3(0.18, 2.2, 0.18), Vector3(12.5, 1.1, -4.5), tool_mat)
	_vis_box(root, Vector3(1.4, 0.16, 0.16), Vector3(11.9, 2.1, -4.5), tool_mat)
	_vis_cyl(root, 0.02, 0.65, Vector3(11.3, 1.8, -4.5), lift_mat)

	# Terminal de diagnóstico con monitor CRT verde fosforito
	var screen_mat := PBRMaterials.make_neon_material(Color(0.15, 0.95, 0.45), 2.8)
	_vis_box(root, Vector3(0.65, 0.45, 0.38), Vector3(0.0, 1.55, 2.0), tool_mat)
	_vis_box(root, Vector3(0.55, 0.35, 0.04), Vector3(0.0, 1.55, 1.79), screen_mat)

	# Puerta de salida de regreso a la ciudad
	var door := Door3D.new()
	door.setup(Vector3(0, 0, 12.6), "SALIR A LA AVENIDA", exit_callback)
	root.add_child(door)

static func _vis_cyl(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
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


static func _solid_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
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

static func _vis_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
