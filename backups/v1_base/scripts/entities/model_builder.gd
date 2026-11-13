extends Node
class_name ModelBuilder

static var _toon_shader: Shader = null
static var _outline_shader: Shader = null

static func get_toon_shader() -> Shader:
	if _toon_shader == null:
		_toon_shader = load("res://shaders/toon_base.gdshader")
	return _toon_shader

static func get_outline_shader() -> Shader:
	if _outline_shader == null:
		_outline_shader = load("res://shaders/toon_outline.gdshader")
	return _outline_shader

static func make_toon_material(base_col: Color, emission_col: Color = Color.BLACK, emission_energy: float = 0.0, outline_w: float = 0.022) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = get_toon_shader()
	mat.set_shader_parameter("base_color", base_col)
	mat.set_shader_parameter("emission_color", emission_col)
	mat.set_shader_parameter("emission_energy", emission_energy)

	if outline_w > 0.0:
		var out_mat := ShaderMaterial.new()
		out_mat.shader = get_outline_shader()
		out_mat.set_shader_parameter("outline_width", outline_w)
		mat.next_pass = out_mat

	return mat

static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func build_character_rig(role: String = "player", char_id: String = "nagumo", outfit_id: int = 0, is_boss: bool = false) -> Dictionary:
	var root := Node3D.new()

	var is_nagumo := (char_id == "nagumo")
	var skin_mat := make_toon_material(Color(0.92, 0.75, 0.63))
	var hair_mat := make_toon_material(Color(0.07, 0.07, 0.09))
	var pants_mat := make_toon_material(Color(0.08, 0.09, 0.11))
	var shoe_mat := make_toon_material(Color(0.04, 0.04, 0.05))
	var coat_mat: ShaderMaterial

	if role == "player":
		coat_mat = make_toon_material(Color(0.09, 0.10, 0.13) if is_nagumo else Color(0.11, 0.09, 0.15))
	elif is_boss:
		coat_mat = make_toon_material(Color(0.68, 0.10, 0.15))
	elif role == "enemy":
		coat_mat = make_toon_material(Color(0.14, 0.15, 0.20))
	else:
		var civ_colors := [
			Color(0.18, 0.24, 0.34),
			Color(0.45, 0.27, 0.18),
			Color(0.55, 0.56, 0.60),
			Color(0.58, 0.16, 0.24)
		]
		coat_mat = make_toon_material(civ_colors[outfit_id % civ_colors.size()])

	# Pivotes de piernas (cadera en Y = 0.88)
	var left_leg := Node3D.new()
	left_leg.position = Vector3(-0.13, 0.88, 0)
	root.add_child(left_leg)
	_add_box(left_leg, Vector3(0.18, 0.78, 0.18), Vector3(0, -0.40, 0), pants_mat)
	_add_box(left_leg, Vector3(0.19, 0.12, 0.28), Vector3(0, -0.82, -0.04), shoe_mat)

	var right_leg := Node3D.new()
	right_leg.position = Vector3(0.13, 0.88, 0)
	root.add_child(right_leg)
	_add_box(right_leg, Vector3(0.18, 0.78, 0.18), Vector3(0, -0.40, 0), pants_mat)
	_add_box(right_leg, Vector3(0.19, 0.12, 0.28), Vector3(0, -0.82, -0.04), shoe_mat)

	# Torso (Y = 0.90 a 1.50)
	var torso := Node3D.new()
	torso.position = Vector3(0, 1.18, 0)
	root.add_child(torso)
	_add_box(torso, Vector3(0.46, 0.58, 0.26), Vector3.ZERO, coat_mat)

	# Camisa y detalles de cuello
	if role == "player":
		if is_nagumo:
			var shirt_mat := make_toon_material(Color(0.92, 0.92, 0.95))
			_add_box(torso, Vector3(0.16, 0.36, 0.04), Vector3(0, 0.10, -0.13), shirt_mat)
			_add_box(torso, Vector3(0.05, 0.30, 0.05), Vector3(0, 0.06, -0.14), shoe_mat)
		else:
			var scarf_mat := make_toon_material(Color(0.65, 0.20, 0.92), Color(0.55, 0.15, 0.85), 0.3)
			_add_box(torso, Vector3(0.36, 0.14, 0.30), Vector3(0, 0.28, 0), scarf_mat)
	elif role == "enemy" and not is_boss:
		var tie_mat := make_toon_material(Color(0.85, 0.15, 0.20))
		_add_box(torso, Vector3(0.06, 0.28, 0.04), Vector3(0, 0.08, -0.14), tie_mat)

	# Faldones de la gabardina (ondeantes en protagonistas y boss)
	var coat_left := Node3D.new()
	coat_left.position = Vector3(-0.14, 0.94, 0.08)
	root.add_child(coat_left)
	var coat_right := Node3D.new()
	coat_right.position = Vector3(0.14, 0.94, 0.08)
	root.add_child(coat_right)

	if role == "player" or is_boss:
		_add_box(coat_left, Vector3(0.24, 0.68, 0.12), Vector3(-0.04, -0.34, 0.06), coat_mat, Vector3(12, 0, 8))
		_add_box(coat_right, Vector3(0.24, 0.68, 0.12), Vector3(0.04, -0.34, 0.06), coat_mat, Vector3(12, 0, -8))

	# Brazos
	var left_arm := Node3D.new()
	left_arm.position = Vector3(-0.30, 1.42, 0)
	root.add_child(left_arm)
	_add_box(left_arm, Vector3(0.14, 0.52, 0.14), Vector3(0, -0.24, 0), coat_mat)
	_add_box(left_arm, Vector3(0.11, 0.12, 0.11), Vector3(0, -0.54, 0), skin_mat)

	var right_arm := Node3D.new()
	right_arm.position = Vector3(0.30, 1.42, 0)
	root.add_child(right_arm)
	_add_box(right_arm, Vector3(0.14, 0.52, 0.14), Vector3(0, -0.24, 0), coat_mat)
	_add_box(right_arm, Vector3(0.11, 0.12, 0.11), Vector3(0, -0.54, 0), skin_mat)

	# Soporte de Arma en mano derecha
	var weapon_mount := Node3D.new()
	weapon_mount.position = Vector3(0, -0.52, -0.06)
	right_arm.add_child(weapon_mount)

	# Cabeza y Cabello Anime
	var head := Node3D.new()
	head.position = Vector3(0, 1.63, 0)
	root.add_child(head)

	var head_mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.34
	head_mi.mesh = sm
	head_mi.material_override = skin_mat
	head.add_child(head_mi)

	# Pelo estilizado
	_add_box(head, Vector3(0.33, 0.18, 0.33), Vector3(0, 0.08, 0.02), hair_mat)
	_add_box(head, Vector3(0.28, 0.16, 0.14), Vector3(0, 0.0, 0.12), hair_mat)

	# Gafas de sol para Nagumo
	if role == "player" and is_nagumo:
		_add_box(head, Vector3(0.26, 0.06, 0.06), Vector3(0, 0.02, -0.15), shoe_mat)

	if is_boss:
		root.scale = Vector3(1.15, 1.15, 1.15)

	return {
		"root": root,
		"left_leg": left_leg,
		"right_leg": right_leg,
		"left_arm": left_arm,
		"right_arm": right_arm,
		"coat_left": coat_left,
		"coat_right": coat_right,
		"weapon_mount": weapon_mount,
		"head": head
	}

static func build_weapon_mesh(weapon_id: String) -> Node3D:
	var w_node := Node3D.new()
	var gun_mat := make_toon_material(Color(0.14, 0.16, 0.20), Color.BLACK, 0.0, 0.015)
	var dark_mat := make_toon_material(Color(0.06, 0.07, 0.08), Color.BLACK, 0.0, 0.015)

	if weapon_id == "fists":
		return w_node
	elif weapon_id == "pistol":
		_add_box(w_node, Vector3(0.06, 0.08, 0.28), Vector3(0, 0, -0.10), gun_mat)
		_add_box(w_node, Vector3(0.05, 0.14, 0.08), Vector3(0, -0.08, 0.0), dark_mat)
	elif weapon_id == "smg":
		_add_box(w_node, Vector3(0.08, 0.12, 0.45), Vector3(0, 0, -0.18), gun_mat)
		_add_box(w_node, Vector3(0.05, 0.22, 0.07), Vector3(0, -0.14, -0.14), dark_mat)
	elif weapon_id == "m4":
		_add_box(w_node, Vector3(0.08, 0.13, 0.88), Vector3(0, 0, -0.32), gun_mat)
		_add_box(w_node, Vector3(0.06, 0.06, 0.28), Vector3(0, 0.09, -0.22), dark_mat)  # Asa
		_add_box(w_node, Vector3(0.05, 0.22, 0.08), Vector3(0, -0.15, -0.26), dark_mat) # Cargador
	elif weapon_id == "bazooka":
		var rpg_mat := make_toon_material(Color(0.22, 0.30, 0.18), Color.BLACK, 0.0, 0.018)
		var rocket_mat := make_toon_material(Color(0.75, 0.18, 0.14), Color.BLACK, 0.0, 0.015)
		_add_cyl(w_node, 0.09, 1.35, Vector3(0, 0.12, -0.25), rpg_mat, Vector3(90, 0, 0))
		_add_cyl(w_node, 0.10, 0.25, Vector3(0, 0.12, -0.96), rocket_mat, Vector3(90, 0, 0))

	return w_node

static func build_vehicle_mesh(v_type: String) -> Dictionary:
	var root := Node3D.new()
	var tire_mat := make_toon_material(Color(0.05, 0.05, 0.06))
	var glass_mat := make_toon_material(Color(0.08, 0.12, 0.18))
	var brake_mat := make_toon_material(Color(0.8, 0.1, 0.1), Color(1.0, 0.12, 0.15), 1.8, 0.01)
	var head_mat := make_toon_material(Color(1.0, 0.95, 0.75), Color(1.0, 0.92, 0.70), 2.5, 0.01)

	if v_type == "motorcycle":
		var moto_mat := make_toon_material(Color(0.60, 0.14, 0.78))
		_add_box(root, Vector3(0.55, 0.55, 1.95), Vector3(0, 0.62, 0), moto_mat)
		_add_cyl(root, 0.34, 0.22, Vector3(0, 0.34, -0.78), tire_mat, Vector3(0, 0, 90))
		_add_cyl(root, 0.34, 0.22, Vector3(0, 0.34, 0.78), tire_mat, Vector3(0, 0, 90))
		_add_box(root, Vector3(0.32, 0.14, 0.08), Vector3(0, 0.75, 0.98), brake_mat)
		_add_box(root, Vector3(0.34, 0.16, 0.08), Vector3(0, 0.85, -0.98), head_mat)
		return {"root": root, "brake_mat": brake_mat}

	var is_sport := (v_type == "sports_car")
	var body_col := Color(0.10, 0.52, 0.85) if is_sport else Color(0.09, 0.10, 0.13)
	var body_mat := make_toon_material(body_col)

	# Chasis inferior
	_add_box(root, Vector3(2.1, 0.68, 4.4), Vector3(0, 0.58, 0), body_mat)
	# Cabina superior
	_add_box(root, Vector3(1.75, 0.56, 2.2), Vector3(0, 1.15, 0.15), glass_mat)
	# Alerón deportivo
	if is_sport:
		_add_box(root, Vector3(2.05, 0.08, 0.35), Vector3(0, 1.12, 1.98), tire_mat)
		_add_box(root, Vector3(0.08, 0.24, 0.22), Vector3(-0.85, 0.98, 1.98), tire_mat)
		_add_box(root, Vector3(0.08, 0.24, 0.22), Vector3(0.85, 0.98, 1.98), tire_mat)

	# 4 Ruedas
	for wx in [-1.02, 1.02]:
		for wz in [-1.35, 1.35]:
			_add_cyl(root, 0.38, 0.28, Vector3(wx, 0.38, wz), tire_mat, Vector3(0, 0, 90))

	# Faros delanteros (-Z) y Luces de freno traseras (+Z)
	_add_box(root, Vector3(0.45, 0.16, 0.06), Vector3(-0.68, 0.62, -2.21), head_mat)
	_add_box(root, Vector3(0.45, 0.16, 0.06), Vector3(0.68, 0.62, -2.21), head_mat)

	_add_box(root, Vector3(0.48, 0.16, 0.06), Vector3(-0.68, 0.66, 2.21), brake_mat)
	_add_box(root, Vector3(0.48, 0.16, 0.06), Vector3(0.68, 0.66, 2.21), brake_mat)

	# Neón bajo el chasis
	var underglow := OmniLight3D.new()
	underglow.light_color = Color(0.16, 0.88, 1.0) if is_sport else Color(0.95, 0.18, 0.25)
	underglow.light_energy = 2.2
	underglow.omni_range = 6.0
	underglow.position = Vector3(0, 0.25, 0)
	root.add_child(underglow)

	# Focos de carretera hacia adelante (-Z)
	var spot_l := SpotLight3D.new()
	spot_l.light_color = Color(1.0, 0.96, 0.82)
	spot_l.light_energy = 4.5
	spot_l.spot_range = 32.0
	spot_l.spot_angle = 36.0
	spot_l.position = Vector3(0, 0.72, -2.25)
	root.add_child(spot_l)

	return {"root": root, "brake_mat": brake_mat, "headlight": spot_l}
