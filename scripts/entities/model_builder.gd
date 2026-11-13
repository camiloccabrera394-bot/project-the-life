extends Node
class_name ModelBuilder

# Alias compatible para transiciones suaves mientras todo pasa a PBR realista
static func make_toon_material(base_col: Color, emission_col: Color = Color.BLACK, emission_energy: float = 0.0, _outline_w: float = 0.0) -> StandardMaterial3D:
	return PBRMaterials.make_pbr_standard(base_col, 0.55, 0.10, emission_col, emission_energy)

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

static func _add_cyl(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO, top_r: float = -1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_r < 0.0 else top_r
	mesh.height = height
	mesh.radial_segments = 14
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

static func _add_capsule(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO, scale_vec: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scale_vec
	parent.add_child(mi)
	return mi

static func _add_sphere(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, scale_vec: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 14
	mesh.rings = 8
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scale_vec
	parent.add_child(mi)
	return mi

static func _try_load_external_glb(char_id: String) -> Node3D:
	if char_id == "":
		return null
	var glb_path: String = "res://assets/models/characters/%s.glb" % char_id
	if ResourceLoader.exists(glb_path):
		var res: Resource = ResourceLoader.load(glb_path)
		if res is PackedScene:
			var inst: Node = (res as PackedScene).instantiate()
			if inst is Node3D:
				return inst as Node3D
	return null

static func build_character_rig(role: String = "player", char_id: String = "nagumo", outfit_id: int = 0, is_boss: bool = false) -> Dictionary:
	var root := Node3D.new()
	var is_nagumo: bool = (char_id == "nagumo")

	# Soporte opcional para modelos .glb externos si se añaden en res://assets/models/characters/
	if role == "player":
		var ext_model: Node3D = _try_load_external_glb(char_id)
		if ext_model != null:
			root.add_child(ext_model)
			var dummy_hip := Node3D.new()
			var dummy_torso := Node3D.new()
			var dummy_l_leg := Node3D.new()
			var dummy_r_leg := Node3D.new()
			var dummy_l_knee := Node3D.new()
			var dummy_r_knee := Node3D.new()
			var dummy_l_ankle := Node3D.new()
			var dummy_r_ankle := Node3D.new()
			var dummy_l_arm := Node3D.new()
			var dummy_r_arm := Node3D.new()
			var dummy_l_elbow := Node3D.new()
			var dummy_r_elbow := Node3D.new()
			var dummy_coat_l := Node3D.new()
			var dummy_coat_r := Node3D.new()
			var dummy_coat_b := Node3D.new()
			var dummy_head := Node3D.new()
			var dummy_mount := Node3D.new()
			dummy_mount.position = Vector3(0.24, 1.32, -0.35)
			root.add_child(dummy_mount)
			return {
				"root": root, "external": true, "role": role, "char_id": char_id,
				"hip": dummy_hip, "torso": dummy_torso,
				"left_leg": dummy_l_leg, "right_leg": dummy_r_leg,
				"left_knee": dummy_l_knee, "right_knee": dummy_r_knee,
				"left_ankle": dummy_l_ankle, "right_ankle": dummy_r_ankle,
				"left_arm": dummy_l_arm, "right_arm": dummy_r_arm,
				"left_elbow": dummy_l_elbow, "right_elbow": dummy_r_elbow,
				"coat_left": dummy_coat_l, "coat_right": dummy_coat_r, "coat_back": dummy_coat_b,
				"weapon_mount": dummy_mount, "head": dummy_head
			}

	# --- Materiales PBR realistas por tipo de superficie ---
	var skin_col: Color = Color(0.84, 0.65, 0.52)
	if role == "player" and not is_nagumo:
		skin_col = Color(0.88, 0.72, 0.60)
	elif role == "civilian":
		var civ_skins: Array[Color] = [
			Color(0.86, 0.68, 0.55), Color(0.76, 0.55, 0.42),
			Color(0.90, 0.74, 0.62), Color(0.58, 0.40, 0.30)
		]
		skin_col = civ_skins[outfit_id % civ_skins.size()]

	var skin_mat := PBRMaterials.make_skin_material(skin_col)
	var hair_col: Color = Color(0.035, 0.038, 0.048) if (role != "player" or is_nagumo) else Color(0.025, 0.042, 0.064)
	if role == "civilian" and outfit_id % 4 == 1:
		hair_col = Color(0.24, 0.14, 0.09)
	var hair_mat := PBRMaterials.make_pbr_standard(hair_col, 0.42, 0.04)

	var pants_mat := PBRMaterials.make_fabric_material(Color(0.065, 0.068, 0.078), 0.78, 0.24)
	var shoe_mat := PBRMaterials.make_leather_material(Color(0.03, 0.03, 0.035), 0.16)
	var belt_mat := PBRMaterials.make_leather_material(Color(0.045, 0.04, 0.038), 0.30)
	var silver_mat := PBRMaterials.make_metal_material(Color(0.82, 0.84, 0.88), 0.94, 0.20)
	var coat_mat: StandardMaterial3D

	if role == "player":
		# Ambos protagonistas visten gabardina negra elegante fiel a sus retratos oficiales
		coat_mat = PBRMaterials.make_fabric_material(Color(0.060, 0.062, 0.072), 0.84, 0.30)
	elif is_boss:
		coat_mat = PBRMaterials.make_fabric_material(Color(0.46, 0.06, 0.09), 0.72, 0.28)
	elif role == "enemy":
		coat_mat = PBRMaterials.make_fabric_material(Color(0.11, 0.12, 0.15), 0.76, 0.26)
	else:
		var civ_coats: Array[Color] = [
			Color(0.16, 0.22, 0.32),
			Color(0.42, 0.28, 0.18),
			Color(0.32, 0.34, 0.38),
			Color(0.38, 0.13, 0.18)
		]
		coat_mat = PBRMaterials.make_fabric_material(civ_coats[outfit_id % civ_coats.size()], 0.80, 0.28)

	# --- 1. CADERA / PELVIS (Y = 0.94 m sobre el suelo) ---
	var hip := Node3D.new()
	hip.position = Vector3(0.0, 0.94, 0.0)
	root.add_child(hip)

	_add_capsule(hip, 0.145, 0.30, Vector3(0.0, 0.03, 0.0), pants_mat, Vector3(0.0, 0.0, 90.0), Vector3(0.82, 1.0, 0.68))
	_add_box(hip, Vector3(0.31, 0.052, 0.20), Vector3(0.0, 0.08, 0.0), belt_mat)
	# Hebilla plateada del cinturón visible al frente
	_add_box(hip, Vector3(0.058, 0.050, 0.018), Vector3(0.0, 0.08, -0.104), silver_mat)

	# --- 2. PIERNAS ARTICULADAS (Muslo -> Rodilla -> Pantorrilla -> Tobillo -> Zapato) ---
	var leg_x: float = 0.102 if (role != "player" or is_nagumo) else 0.094
	var thigh_r: float = 0.084 if (role != "player" or is_nagumo) else 0.076
	var calf_r: float = 0.068 if (role != "player" or is_nagumo) else 0.062

	var left_leg := Node3D.new()
	left_leg.position = Vector3(-leg_x, 0.0, 0.0)
	hip.add_child(left_leg)
	_add_capsule(left_leg, thigh_r, 0.48, Vector3(0.0, -0.22, 0.0), pants_mat, Vector3.ZERO, Vector3(1.0, 1.0, 1.08))

	var left_knee := Node3D.new()
	left_knee.position = Vector3(0.0, -0.44, 0.0)
	left_leg.add_child(left_knee)
	_add_sphere(left_knee, calf_r * 1.04, calf_r * 2.0, Vector3.ZERO, pants_mat)
	_add_capsule(left_knee, calf_r, 0.46, Vector3(0.0, -0.22, 0.0), pants_mat, Vector3.ZERO, Vector3(0.96, 1.0, 1.05))

	var left_ankle := Node3D.new()
	left_ankle.position = Vector3(0.0, -0.44, 0.0)
	left_knee.add_child(left_ankle)
	_build_dress_shoe(left_ankle, shoe_mat)

	var right_leg := Node3D.new()
	right_leg.position = Vector3(leg_x, 0.0, 0.0)
	hip.add_child(right_leg)
	_add_capsule(right_leg, thigh_r, 0.48, Vector3(0.0, -0.22, 0.0), pants_mat, Vector3.ZERO, Vector3(1.0, 1.0, 1.08))

	var right_knee := Node3D.new()
	right_knee.position = Vector3(0.0, -0.44, 0.0)
	right_leg.add_child(right_knee)
	_add_sphere(right_knee, calf_r * 1.04, calf_r * 2.0, Vector3.ZERO, pants_mat)
	_add_capsule(right_knee, calf_r, 0.46, Vector3(0.0, -0.22, 0.0), pants_mat, Vector3.ZERO, Vector3(0.96, 1.0, 1.05))

	var right_ankle := Node3D.new()
	right_ankle.position = Vector3(0.0, -0.44, 0.0)
	right_knee.add_child(right_ankle)
	_build_dress_shoe(right_ankle, shoe_mat)

	# --- 3. FALDONES DE LA GABARDINA (articulados desde la cadera) ---
	var coat_left := Node3D.new()
	coat_left.position = Vector3(-0.145, 0.04, 0.04)
	hip.add_child(coat_left)
	var coat_right := Node3D.new()
	coat_right.position = Vector3(0.145, 0.04, 0.04)
	hip.add_child(coat_right)
	var coat_back := Node3D.new()
	coat_back.position = Vector3(0.0, 0.04, 0.115)
	hip.add_child(coat_back)

	if role == "player" or is_boss:
		_add_box(coat_left, Vector3(0.16, 0.66, 0.042), Vector3(-0.025, -0.33, 0.015), coat_mat, Vector3(-8.0, -18.0, -7.0))
		_add_box(coat_right, Vector3(0.16, 0.66, 0.042), Vector3(0.025, -0.33, 0.015), coat_mat, Vector3(-8.0, 18.0, 7.0))
		_add_box(coat_back, Vector3(0.28, 0.68, 0.040), Vector3(0.0, -0.34, 0.02), coat_mat, Vector3(-10.0, 0.0, 0.0))

	# --- 4. TORSO ANATÓMICO, VESTIMENTA FIEL Y HOMBROS ---
	var torso := Node3D.new()
	torso.position = Vector3(0.0, 0.06, 0.0)
	hip.add_child(torso)

	var torso_w: float = 0.36 if (role != "player" or is_nagumo) else 0.33
	var shoulder_x: float = 0.245 if (role != "player" or is_nagumo) else 0.225

	if role == "player":
		if is_nagumo:
			# Nagumo: camisa blanca elegante + corbata negra satinada + saco bajo gabardina abierta
			var shirt_mat := PBRMaterials.make_fabric_material(Color(0.90, 0.91, 0.94), 0.70, 0.14)
			var tie_mat := PBRMaterials.make_pbr_standard(Color(0.04, 0.04, 0.05), 0.35, 0.08)
			var vest_mat := PBRMaterials.make_fabric_material(Color(0.05, 0.052, 0.06), 0.78, 0.22)
			# Núcleo camisa blanca
			_add_capsule(torso, 0.155, 0.50, Vector3(0.0, 0.25, 0.0), shirt_mat, Vector3.ZERO, Vector3(1.06, 1.0, 0.66))
			# Nudo y corbata negra
			_add_box(torso, Vector3(0.046, 0.042, 0.028), Vector3(0.0, 0.42, -0.102), tie_mat)
			_add_box(torso, Vector3(0.044, 0.34, 0.022), Vector3(0.0, 0.23, -0.105), tie_mat)
			# Chaleco/saco interior en V
			_add_box(torso, Vector3(0.095, 0.36, 0.028), Vector3(-0.082, 0.22, -0.094), vest_mat, Vector3(0.0, 0.0, 6.0))
			_add_box(torso, Vector3(0.095, 0.36, 0.028), Vector3(0.082, 0.22, -0.094), vest_mat, Vector3(0.0, 0.0, -6.0))
		else:
			# Shado: camisa negra abotonada con cuello abierto (sin bufanda morada)
			var black_shirt := PBRMaterials.make_fabric_material(Color(0.048, 0.050, 0.058), 0.68, 0.20)
			_add_capsule(torso, 0.145, 0.49, Vector3(0.0, 0.25, 0.0), black_shirt, Vector3.ZERO, Vector3(1.02, 1.0, 0.64))
			# Pequeña abertura V mostrando piel del cuello/pecho superior
			_add_box(torso, Vector3(0.075, 0.10, 0.03), Vector3(0.0, 0.43, -0.084), skin_mat, Vector3(-12.0, 0.0, 0.0))
			# Botonera central discreta
			for by in [0.16, 0.24, 0.32]:
				_add_sphere(torso, 0.010, 0.02, Vector3(0.0, by, -0.096), silver_mat)

		# Espalda, laterales y solapas abiertas de la gabardina negra
		_add_capsule(torso, 0.165, 0.50, Vector3(0.0, 0.25, 0.035), coat_mat, Vector3.ZERO, Vector3(1.12, 1.0, 0.56))
		_add_box(torso, Vector3(0.115, 0.47, 0.16), Vector3(-0.135, 0.24, -0.015), coat_mat, Vector3(0.0, -10.0, 2.0))
		_add_box(torso, Vector3(0.115, 0.47, 0.16), Vector3(0.135, 0.24, -0.015), coat_mat, Vector3(0.0, 10.0, -2.0))
		# Yugo redondeado de hombros (elimina silueta cuadrada)
		_add_capsule(torso, 0.088, torso_w + 0.12, Vector3(0.0, 0.44, 0.005), coat_mat, Vector3(0.0, 0.0, 90.0), Vector3(0.88, 1.0, 0.92))
		# Cuello alzado y solapas características de la gabardina
		var collar_h: float = 0.11 if is_nagumo else 0.13
		_add_box(torso, Vector3(0.18, collar_h, 0.035), Vector3(0.0, 0.50, 0.085), coat_mat, Vector3(18.0, 0.0, 0.0))
		_add_box(torso, Vector3(0.032, collar_h, 0.13), Vector3(-0.088, 0.49, 0.015), coat_mat, Vector3(10.0, 18.0, 14.0))
		_add_box(torso, Vector3(0.032, collar_h, 0.13), Vector3(0.088, 0.49, 0.015), coat_mat, Vector3(10.0, -18.0, -14.0))
		_add_box(torso, Vector3(0.075, 0.18, 0.025), Vector3(-0.105, 0.39, -0.095), coat_mat, Vector3(0.0, 14.0, -18.0))
		_add_box(torso, Vector3(0.075, 0.18, 0.025), Vector3(0.105, 0.39, -0.095), coat_mat, Vector3(0.0, -14.0, 18.0))
	else:
		# Enemigos, Boss y Civiles con anatomía redondeada
		_add_capsule(torso, 0.16, 0.50, Vector3(0.0, 0.25, 0.0), coat_mat, Vector3.ZERO, Vector3(1.12, 1.0, 0.68))
		_add_capsule(torso, 0.086, torso_w + 0.10, Vector3(0.0, 0.44, 0.0), coat_mat, Vector3(0.0, 0.0, 90.0), Vector3(0.86, 1.0, 0.90))
		if role == "enemy" and not is_boss:
			var w_shirt := PBRMaterials.make_fabric_material(Color(0.86, 0.87, 0.90), 0.72, 0.12)
			var red_tie := PBRMaterials.make_pbr_standard(Color(0.75, 0.10, 0.15), 0.36, 0.05)
			_add_box(torso, Vector3(0.11, 0.28, 0.03), Vector3(0.0, 0.32, -0.10), w_shirt)
			_add_box(torso, Vector3(0.042, 0.28, 0.02), Vector3(0.0, 0.28, -0.112), red_tie)
		elif is_boss:
			var vest := PBRMaterials.make_leather_material(Color(0.06, 0.06, 0.08), 0.34)
			_add_box(torso, Vector3(0.28, 0.36, 0.22), Vector3(0.0, 0.26, -0.01), vest)

	# --- 5. BRAZOS ARTICULADOS (Hombro -> Codo -> Antebrazo -> Mano) ---
	var left_arm := Node3D.new()
	left_arm.position = Vector3(-shoulder_x, 0.44, 0.0)
	torso.add_child(left_arm)
	_add_sphere(left_arm, 0.072, 0.14, Vector3.ZERO, coat_mat)
	_add_capsule(left_arm, 0.060, 0.30, Vector3(0.0, -0.14, 0.0), coat_mat)

	var left_elbow := Node3D.new()
	left_elbow.position = Vector3(0.0, -0.27, 0.0)
	left_arm.add_child(left_elbow)
	_add_sphere(left_elbow, 0.056, 0.11, Vector3.ZERO, coat_mat)
	_add_capsule(left_elbow, 0.052, 0.28, Vector3(0.0, -0.13, 0.0), coat_mat)
	if role == "player":
		if is_nagumo:
			var cuff_m := PBRMaterials.make_fabric_material(Color(0.92, 0.92, 0.95), 0.65, 0.10)
			_add_cyl(left_elbow, 0.048, 0.036, Vector3(0.0, -0.245, 0.0), cuff_m)
		else:
			# Reloj icónico de Shado en muñeca izquierda (ver shado.png)
			_add_cyl(left_elbow, 0.054, 0.032, Vector3(0.0, -0.235, 0.0), belt_mat)
			_add_box(left_elbow, Vector3(0.022, 0.036, 0.036), Vector3(-0.048, -0.235, 0.0), silver_mat)
	_add_capsule(left_elbow, 0.040, 0.10, Vector3(0.0, -0.295, -0.005), skin_mat, Vector3.ZERO, Vector3(0.82, 1.0, 1.10))

	var right_arm := Node3D.new()
	right_arm.position = Vector3(shoulder_x, 0.44, 0.0)
	torso.add_child(right_arm)
	_add_sphere(right_arm, 0.072, 0.14, Vector3.ZERO, coat_mat)
	_add_capsule(right_arm, 0.060, 0.30, Vector3(0.0, -0.14, 0.0), coat_mat)

	var right_elbow := Node3D.new()
	right_elbow.position = Vector3(0.0, -0.27, 0.0)
	right_arm.add_child(right_elbow)
	_add_sphere(right_elbow, 0.056, 0.11, Vector3.ZERO, coat_mat)
	_add_capsule(right_elbow, 0.052, 0.28, Vector3(0.0, -0.13, 0.0), coat_mat)
	if role == "player" and is_nagumo:
		var cuff_r := PBRMaterials.make_fabric_material(Color(0.92, 0.92, 0.95), 0.65, 0.10)
		_add_cyl(right_elbow, 0.048, 0.036, Vector3(0.0, -0.245, 0.0), cuff_r)
	_add_capsule(right_elbow, 0.040, 0.10, Vector3(0.0, -0.295, -0.005), skin_mat, Vector3.ZERO, Vector3(0.82, 1.0, 1.10))

	var weapon_mount := Node3D.new()
	weapon_mount.position = Vector3(0.0, -0.295, -0.03)
	weapon_mount.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	right_elbow.add_child(weapon_mount)

	# --- 6. CUELLO, ROSTRO ESCULPIDO Y CABELLO DETALLADO ---
	var head := Node3D.new()
	head.position = Vector3(0.0, 0.56, 0.0)
	torso.add_child(head)

	# Cuello anatómico
	_add_cyl(head, 0.056, 0.13, Vector3(0.0, -0.075, 0.008), skin_mat)
	# Cráneo + Mandíbula/Mentón definido
	_add_sphere(head, 0.102, 0.21, Vector3(0.0, 0.035, 0.005), skin_mat, Vector3(0.92, 1.0, 1.02))
	_add_sphere(head, 0.078, 0.145, Vector3(0.0, -0.018, -0.015), skin_mat, Vector3(0.84, 0.92, 0.96))
	# Orejas y puente nasal
	_add_sphere(head, 0.022, 0.052, Vector3(-0.096, 0.012, 0.012), skin_mat, Vector3(0.55, 1.0, 0.85))
	_add_sphere(head, 0.022, 0.052, Vector3(0.096, 0.012, 0.012), skin_mat, Vector3(0.55, 1.0, 0.85))
	_add_box(head, Vector3(0.018, 0.044, 0.024), Vector3(0.0, 0.005, -0.095), skin_mat)

	# Rasgos faciales (cejas, ojos y boca)
	var sclera_mat := PBRMaterials.make_pbr_standard(Color(0.92, 0.92, 0.94), 0.25)
	var iris_mat := PBRMaterials.make_pbr_standard(Color(0.06, 0.05, 0.05), 0.10)
	var brow_mat := PBRMaterials.make_pbr_standard(hair_col, 0.55)
	_add_box(head, Vector3(0.036, 0.009, 0.014), Vector3(-0.036, 0.042, -0.088), brow_mat, Vector3(0.0, 0.0, -6.0))
	_add_box(head, Vector3(0.036, 0.009, 0.014), Vector3(0.036, 0.042, -0.088), brow_mat, Vector3(0.0, 0.0, 6.0))
	_add_sphere(head, 0.014, 0.020, Vector3(-0.035, 0.022, -0.084), sclera_mat, Vector3(1.1, 0.8, 0.6))
	_add_sphere(head, 0.014, 0.020, Vector3(0.035, 0.022, -0.084), sclera_mat, Vector3(1.1, 0.8, 0.6))
	_add_sphere(head, 0.009, 0.016, Vector3(-0.035, 0.022, -0.091), iris_mat)
	_add_sphere(head, 0.009, 0.016, Vector3(0.035, 0.022, -0.091), iris_mat)
	var mouth_mat := PBRMaterials.make_skin_material(skin_col * 0.72)
	_add_box(head, Vector3(0.036, 0.007, 0.010), Vector3(0.0, -0.044, -0.086), mouth_mat)

	# Gafas de aviador y cigarrillo icónico de Nagumo
	if role == "player" and is_nagumo:
		var lens_mat := PBRMaterials.make_pbr_standard(Color(0.02, 0.022, 0.028), 0.05, 0.65)
		var frame_m := PBRMaterials.make_metal_material(Color(0.14, 0.14, 0.16), 0.90, 0.25)
		_add_box(head, Vector3(0.048, 0.032, 0.014), Vector3(-0.038, 0.022, -0.100), lens_mat, Vector3(0.0, 8.0, 0.0))
		_add_box(head, Vector3(0.048, 0.032, 0.014), Vector3(0.038, 0.022, -0.100), lens_mat, Vector3(0.0, -8.0, 0.0))
		_add_box(head, Vector3(0.125, 0.007, 0.012), Vector3(0.0, 0.036, -0.102), frame_m)
		_add_box(head, Vector3(0.008, 0.007, 0.115), Vector3(-0.094, 0.026, -0.042), frame_m)
		_add_box(head, Vector3(0.008, 0.007, 0.115), Vector3(0.094, 0.026, -0.042), frame_m)
		# Cigarrillo
		var cig_m := PBRMaterials.make_pbr_standard(Color(0.92, 0.90, 0.86), 0.80)
		var ember_m := PBRMaterials.make_neon_material(Color(1.0, 0.35, 0.06), 1.8)
		_add_cyl(head, 0.0055, 0.056, Vector3(0.022, -0.048, -0.112), cig_m, Vector3(78.0, -14.0, 0.0))
		_add_sphere(head, 0.006, 0.012, Vector3(0.029, -0.054, -0.138), ember_m)

	# Cabello en múltiples capas y mechones
	_add_sphere(head, 0.109, 0.20, Vector3(0.0, 0.058, 0.018), hair_mat, Vector3(0.96, 0.92, 1.06))
	_add_capsule(head, 0.068, 0.16, Vector3(0.0, 0.015, 0.072), hair_mat, Vector3(12.0, 0.0, 0.0), Vector3(1.38, 1.0, 0.72))
	# Patillas laterales
	_add_box(head, Vector3(0.026, 0.095, 0.055), Vector3(-0.092, 0.035, -0.012), hair_mat)
	_add_box(head, Vector3(0.026, 0.095, 0.055), Vector3(0.092, 0.035, -0.012), hair_mat)

	if role == "player" and is_nagumo:
		# Flequillo revuelto y mechones despeinados de Nagumo
		for i in range(6):
			var fx: float = -0.070 + float(i) * 0.028
			var tilt_z: float = -18.0 + float(i) * 6.5
			_add_box(head, Vector3(0.032, 0.068, 0.035), Vector3(fx, 0.088, -0.074), hair_mat, Vector3(28.0, 0.0, tilt_z))
			_add_box(head, Vector3(0.034, 0.055, 0.060), Vector3(fx * 0.9, 0.145, 0.01 * (i % 2)), hair_mat, Vector3(-22.0 + float(i % 3) * 14.0, 0.0, tilt_z * 0.8))
	else:
		# Flequillo lacio en capas sobre la frente (Shado y generales)
		for i in range(5):
			var fx: float = -0.064 + float(i) * 0.032
			_add_box(head, Vector3(0.034, 0.082, 0.030), Vector3(fx, 0.078, -0.076), hair_mat, Vector3(20.0, 0.0, -6.0 + float(i) * 3.0))
		_add_box(head, Vector3(0.17, 0.05, 0.16), Vector3(0.0, 0.132, 0.01), hair_mat)

	# Escala realista diferenciada
	if is_boss:
		root.scale = Vector3(1.10, 1.10, 1.10)
	elif role == "player":
		root.scale = Vector3(1.02, 1.02, 1.02) if is_nagumo else Vector3(0.98, 0.99, 0.98)

	return {
		"root": root, "external": false, "role": role, "char_id": char_id,
		"hip": hip, "torso": torso,
		"left_leg": left_leg, "right_leg": right_leg,
		"left_knee": left_knee, "right_knee": right_knee,
		"left_ankle": left_ankle, "right_ankle": right_ankle,
		"left_arm": left_arm, "right_arm": right_arm,
		"left_elbow": left_elbow, "right_elbow": right_elbow,
		"coat_left": coat_left, "coat_right": coat_right, "coat_back": coat_back,
		"weapon_mount": weapon_mount, "head": head
	}

static func _build_dress_shoe(ankle_pivot: Node3D, shoe_mat: Material) -> void:
	_add_capsule(ankle_pivot, 0.054, 0.21, Vector3(0.0, -0.025, -0.045), shoe_mat, Vector3(90.0, 0.0, 0.0), Vector3(1.02, 1.0, 0.72))
	_add_sphere(ankle_pivot, 0.052, 0.076, Vector3(0.0, -0.032, -0.135), shoe_mat, Vector3(0.95, 0.72, 1.25))
	_add_box(ankle_pivot, Vector3(0.106, 0.022, 0.24), Vector3(0.0, -0.049, -0.05), shoe_mat)

static func animate_character_rig(
	rig: Dictionary,
	speed_ratio: float,
	phase: float,
	is_crouched: bool,
	delta: float,
	weapon_id: String = "fists",
	is_aiming: bool = false,
	look_pitch: float = 0.0,
	punch_timer: float = 0.0
) -> void:
	if bool(rig.get("external", false)):
		return

	var k: float = minf(1.0, delta * 12.0)
	var move_blend: float = clampf(speed_ratio, 0.0, 1.15)
	var hip: Node3D = rig["hip"] as Node3D
	var torso: Node3D = rig["torso"] as Node3D
	var l_leg: Node3D = rig["left_leg"] as Node3D
	var r_leg: Node3D = rig["right_leg"] as Node3D
	var l_knee: Node3D = rig["left_knee"] as Node3D
	var r_knee: Node3D = rig["right_knee"] as Node3D
	var l_ankle: Node3D = rig["left_ankle"] as Node3D
	var r_ankle: Node3D = rig["right_ankle"] as Node3D
	var l_arm: Node3D = rig["left_arm"] as Node3D
	var r_arm: Node3D = rig["right_arm"] as Node3D
	var l_elbow: Node3D = rig["left_elbow"] as Node3D
	var r_elbow: Node3D = rig["right_elbow"] as Node3D
	var mount: Node3D = rig["weapon_mount"] as Node3D
	var head: Node3D = rig["head"] as Node3D
	var c_left: Node3D = rig["coat_left"] as Node3D
	var c_right: Node3D = rig["coat_right"] as Node3D
	var c_back: Node3D = rig["coat_back"] as Node3D

	var t_sec: float = Time.get_ticks_msec() * 0.001
	var breath: float = sin(t_sec * 2.4) * 0.012

	# 1. Cadera, agachado anatómico real y balanceo de paso
	var stride_bob: float = absf(sin(phase)) * 0.042 * minf(1.0, move_blend)
	var target_hip_y: float = (0.655 if is_crouched else 0.94) + stride_bob + breath * 0.5
	hip.position.y = lerpf(hip.position.y, target_hip_y, k)
	hip.rotation.y = lerpf(hip.rotation.y, sin(phase) * 0.07 * minf(1.0, move_blend), k)

	# 2. Piernas y rodillas articuladas
	var stride: float = sin(phase) * (0.48 if is_crouched else 0.62) * minf(1.1, move_blend)
	var bend_l: float = maxf(0.0, -sin(phase + 0.45)) * 0.95 + maxf(0.0, sin(phase)) * 0.22
	var bend_r: float = maxf(0.0, sin(phase + 0.45)) * 0.95 + maxf(0.0, -sin(phase)) * 0.22
	var act_w: float = clampf(move_blend * 1.35, 0.0, 1.0)

	var base_thigh: float = 0.85 if is_crouched else 0.0
	var base_knee: float = -1.65 if is_crouched else -0.05
	var base_ankle: float = 0.80 if is_crouched else 0.03

	l_leg.rotation.x = lerpf(l_leg.rotation.x, base_thigh + stride, k)
	r_leg.rotation.x = lerpf(r_leg.rotation.x, base_thigh - stride, k)
	l_knee.rotation.x = lerpf(l_knee.rotation.x, base_knee - bend_l * act_w * (0.35 if is_crouched else 1.0), k)
	r_knee.rotation.x = lerpf(r_knee.rotation.x, base_knee - bend_r * act_w * (0.35 if is_crouched else 1.0), k)
	l_ankle.rotation.x = lerpf(l_ankle.rotation.x, base_ankle - stride * 0.25, k)
	r_ankle.rotation.x = lerpf(r_ankle.rotation.x, base_ankle + stride * 0.25, k)

	# 3. Torso y cabeza
	var torso_pitch: float = (-0.28 if is_crouched else -0.08 * minf(1.0, move_blend)) + breath
	torso.rotation.x = lerpf(torso.rotation.x, torso_pitch, k)
	torso.rotation.y = lerpf(torso.rotation.y, -sin(phase) * 0.09 * minf(1.0, move_blend), k)
	head.rotation.x = lerpf(head.rotation.x, clampf(look_pitch * 0.42 - torso_pitch * 0.6, -0.45, 0.45), k)

	# 4. Faldones largos de gabardina ondeando hacia atrás con velocidad + viento
	var wind: float = sin(t_sec * 3.1) * 3.5
	var coat_flare: float = (18.0 if is_crouched else 6.0) + minf(1.0, move_blend) * 20.0
	c_left.rotation.x = lerpf(c_left.rotation.x, -deg_to_rad(coat_flare + absf(sin(phase)) * 10.0 * act_w + wind), k)
	c_right.rotation.x = lerpf(c_right.rotation.x, -deg_to_rad(coat_flare + absf(cos(phase)) * 10.0 * act_w - wind), k)
	c_back.rotation.x = lerpf(c_back.rotation.x, -deg_to_rad(coat_flare + 4.0 + minf(1.0, move_blend) * 10.0 + wind * 0.7), k)

	# 5. Brazos, codos y pose real de arma
	var tgt_r_arm: Vector3 = Vector3.ZERO
	var tgt_l_arm: Vector3 = Vector3.ZERO
	var tgt_r_elb: Vector3 = Vector3(12.0, 0.0, 0.0)
	var tgt_l_elb: Vector3 = Vector3(12.0, 0.0, 0.0)
	var tgt_mount: Vector3 = Vector3(-90.0, 0.0, 0.0)

	if weapon_id == "fists":
		var arm_swing: float = rad_to_deg(sin(phase)) * 28.0 * minf(1.0, move_blend)
		if punch_timer > 0.0:
			tgt_r_arm = Vector3(72.0, -8.0, 0.0)
			tgt_r_elb = Vector3(26.0, 0.0, 0.0)
			tgt_l_arm = Vector3(42.0, 18.0, 0.0)
			tgt_l_elb = Vector3(88.0, -14.0, 0.0)
		elif is_aiming:
			tgt_r_arm = Vector3(44.0, -12.0, 0.0)
			tgt_r_elb = Vector3(84.0, 14.0, 0.0)
			tgt_l_arm = Vector3(46.0, 14.0, 0.0)
			tgt_l_elb = Vector3(82.0, -14.0, 0.0)
		else:
			tgt_r_arm = Vector3(-arm_swing, 0.0, -5.0)
			tgt_l_arm = Vector3(arm_swing, 0.0, 5.0)
			tgt_r_elb = Vector3(14.0 + maxf(0.0, -arm_swing) * 0.4, 0.0, 0.0)
			tgt_l_elb = Vector3(14.0 + maxf(0.0, arm_swing) * 0.4, 0.0, 0.0)
	elif weapon_id == "pistol":
		var p_deg: float = clampf(rad_to_deg(look_pitch), -35.0, 35.0) if is_aiming else 0.0
		if is_aiming:
			tgt_r_arm = Vector3(44.0 + p_deg, -4.0, 0.0)
			tgt_r_elb = Vector3(46.0, 4.0, 0.0)
			tgt_l_arm = Vector3(42.0 + p_deg, 26.0, 8.0)
			tgt_l_elb = Vector3(48.0, -24.0, 0.0)
		else:
			var sway: float = rad_to_deg(sin(phase)) * 14.0 * minf(1.0, move_blend)
			tgt_r_arm = Vector3(18.0 - sway, -4.0, -4.0)
			tgt_r_elb = Vector3(36.0, 0.0, 0.0)
			tgt_l_arm = Vector3(rad_to_deg(sin(phase)) * 22.0 * minf(1.0, move_blend), 0.0, 5.0)
			tgt_l_elb = Vector3(16.0, 0.0, 0.0)
		tgt_mount = Vector3(-90.0, 0.0, 0.0)
	elif weapon_id in ["m4", "smg"]:
		var p_deg: float = clampf(rad_to_deg(look_pitch), -35.0, 35.0) if is_aiming else 0.0
		if is_aiming:
			tgt_r_arm = Vector3(36.0 + p_deg, -10.0, -4.0)
			tgt_r_elb = Vector3(54.0, 10.0, 0.0)
			tgt_l_arm = Vector3(38.0 + p_deg, 28.0, 12.0)
			tgt_l_elb = Vector3(56.0, -24.0, 0.0)
			tgt_mount = Vector3(-90.0, -4.0, 0.0)
		else:
			tgt_r_arm = Vector3(22.0, -18.0, -6.0)
			tgt_r_elb = Vector3(48.0, 22.0, 0.0)
			tgt_l_arm = Vector3(26.0, 26.0, 12.0)
			tgt_l_elb = Vector3(54.0, -26.0, 0.0)
			tgt_mount = Vector3(-76.0, -14.0, 0.0)
	elif weapon_id == "bazooka":
		var p_deg: float = clampf(rad_to_deg(look_pitch), -30.0, 30.0) if is_aiming else 0.0
		tgt_r_arm = Vector3(62.0 + p_deg, 0.0, -4.0)
		tgt_r_elb = Vector3(46.0, 0.0, 0.0)
		tgt_l_arm = Vector3(48.0 + p_deg, 24.0, 8.0)
		tgt_l_elb = Vector3(56.0, -20.0, 0.0)
		tgt_mount = Vector3(-108.0, 0.0, 0.0)

	var ak: float = minf(1.0, delta * 14.0)
	r_arm.rotation = r_arm.rotation.lerp(Vector3(deg_to_rad(tgt_r_arm.x), deg_to_rad(tgt_r_arm.y), deg_to_rad(tgt_r_arm.z)), ak)
	l_arm.rotation = l_arm.rotation.lerp(Vector3(deg_to_rad(tgt_l_arm.x), deg_to_rad(tgt_l_arm.y), deg_to_rad(tgt_l_arm.z)), ak)
	r_elbow.rotation = r_elbow.rotation.lerp(Vector3(deg_to_rad(tgt_r_elb.x), deg_to_rad(tgt_r_elb.y), deg_to_rad(tgt_r_elb.z)), ak)
	l_elbow.rotation = l_elbow.rotation.lerp(Vector3(deg_to_rad(tgt_l_elb.x), deg_to_rad(tgt_l_elb.y), deg_to_rad(tgt_l_elb.z)), ak)
	mount.rotation = mount.rotation.lerp(Vector3(deg_to_rad(tgt_mount.x), deg_to_rad(tgt_mount.y), deg_to_rad(tgt_mount.z)), ak)

static func build_weapon_mesh(weapon_id: String, char_id: String = "") -> Node3D:
	var w_node := Node3D.new()
	var gunmetal := PBRMaterials.make_metal_material(Color(0.14, 0.16, 0.20), 0.88, 0.28)
	var polymer := PBRMaterials.make_pbr_standard(Color(0.05, 0.055, 0.065), 0.72, 0.08)
	var steel := PBRMaterials.make_metal_material(Color(0.32, 0.35, 0.40), 0.94, 0.22)

	if weapon_id == "fists":
		return w_node
	elif weapon_id == "pistol":
		_add_box(w_node, Vector3(0.042, 0.064, 0.24), Vector3(0.0, 0.02, -0.09), gunmetal)
		_add_box(w_node, Vector3(0.036, 0.125, 0.065), Vector3(0.0, -0.055, 0.0), polymer, Vector3(-12.0, 0.0, 0.0))
		_add_cyl(w_node, 0.012, 0.22, Vector3(0.0, 0.028, -0.13), steel, Vector3(90.0, 0.0, 0.0))
		if char_id == "shado":
			_add_cyl(w_node, 0.022, 0.16, Vector3(0.0, 0.028, -0.28), polymer, Vector3(90.0, 0.0, 0.0))
	elif weapon_id == "smg":
		_add_box(w_node, Vector3(0.058, 0.095, 0.38), Vector3(0.0, 0.02, -0.14), gunmetal)
		_add_box(w_node, Vector3(0.040, 0.12, 0.062), Vector3(0.0, -0.065, 0.01), polymer, Vector3(-10.0, 0.0, 0.0))
		_add_box(w_node, Vector3(0.034, 0.20, 0.050), Vector3(0.0, -0.11, -0.12), gunmetal, Vector3(12.0, 0.0, 0.0))
		_add_box(w_node, Vector3(0.034, 0.095, 0.040), Vector3(0.0, -0.06, -0.25), polymer)
		_add_cyl(w_node, 0.016, 0.18, Vector3(0.0, 0.025, -0.36), steel, Vector3(90.0, 0.0, 0.0))
	elif weapon_id == "m4":
		# Receptor y cañón táctico M4 realista
		_add_box(w_node, Vector3(0.064, 0.105, 0.52), Vector3(0.0, 0.02, -0.16), gunmetal)
		_add_box(w_node, Vector3(0.056, 0.095, 0.24), Vector3(0.0, 0.01, 0.18), polymer)  # Culata
		_add_box(w_node, Vector3(0.040, 0.12, 0.062), Vector3(0.0, -0.07, 0.0), polymer, Vector3(-14.0, 0.0, 0.0))
		_add_box(w_node, Vector3(0.044, 0.21, 0.072), Vector3(0.0, -0.12, -0.13), gunmetal, Vector3(10.0, 0.0, 0.0))
		_add_box(w_node, Vector3(0.046, 0.050, 0.22), Vector3(0.0, 0.095, -0.12), polymer)  # Mira holográfica/asa
		_add_cyl(w_node, 0.016, 0.34, Vector3(0.0, 0.032, -0.52), steel, Vector3(90.0, 0.0, 0.0))
	elif weapon_id == "bazooka":
		var rpg_mat := PBRMaterials.make_metal_material(Color(0.20, 0.27, 0.16), 0.35, 0.56)
		var rocket_mat := PBRMaterials.make_metal_material(Color(0.55, 0.16, 0.12), 0.45, 0.40)
		_add_cyl(w_node, 0.078, 1.28, Vector3(0.0, 0.10, -0.15), rpg_mat, Vector3(90.0, 0.0, 0.0))
		_add_cyl(w_node, 0.095, 0.18, Vector3(0.0, 0.10, 0.48), gunmetal, Vector3(90.0, 0.0, 0.0), 0.078)
		_add_box(w_node, Vector3(0.048, 0.14, 0.068), Vector3(0.0, -0.02, 0.02), polymer)
		_add_box(w_node, Vector3(0.045, 0.13, 0.055), Vector3(0.0, -0.01, -0.32), polymer)
		_add_cyl(w_node, 0.082, 0.26, Vector3(0.0, 0.10, -0.84), rocket_mat, Vector3(90.0, 0.0, 0.0), 0.015)

	return w_node

static func build_vehicle_mesh(v_type: String) -> Dictionary:
	# Soporte opcional para cargar modelos externos .glb si el usuario los coloca en res://assets/models/vehicles/<v_type>.glb
	var ext_path := "res://assets/models/vehicles/" + v_type + ".glb"
	if ResourceLoader.exists(ext_path):
		var scn = load(ext_path)
		if scn is PackedScene:
			var inst = scn.instantiate()
			if inst is Node3D:
				var brake_m := PBRMaterials.make_neon_material(Color(1.0, 0.12, 0.14), 4.2)
				var spot_l := SpotLight3D.new()
				spot_l.light_color = Color(1.0, 0.96, 0.85)
				spot_l.light_energy = 5.0
				spot_l.spot_range = 38.0
				spot_l.spot_angle = 35.0
				spot_l.position = Vector3(0, 0.65, -2.2)
				inst.add_child(spot_l)
				return {"root": inst, "brake_mat": brake_m, "headlight": spot_l}

	var root := Node3D.new()
	var brake_mat := PBRMaterials.make_neon_material(Color(1.0, 0.10, 0.12), 4.4)
	var head_mat := PBRMaterials.make_neon_material(Color(1.0, 0.96, 0.86), 4.8)
	var tire_mat := PBRMaterials.make_pbr_standard(Color(0.065, 0.068, 0.075), 0.84, 0.02)
	var rim_mat := PBRMaterials.make_metal_material(Color(0.84, 0.86, 0.90), 0.95, 0.20)
	var rotor_mat := PBRMaterials.make_metal_material(Color(0.68, 0.70, 0.74), 0.92, 0.28)
	var caliper_mat := PBRMaterials.make_pbr_standard(Color(0.92, 0.14, 0.16), 0.38, 0.22)
	var chrome_mat := PBRMaterials.make_metal_material(Color(0.92, 0.94, 0.98), 0.98, 0.10)
	var dark_trim := PBRMaterials.make_pbr_standard(Color(0.05, 0.055, 0.065), 0.62, 0.15)
	var glass_mat := PBRMaterials.make_glass_material(Color(0.08, 0.12, 0.18), 0.06)

	var spot_l := SpotLight3D.new()
	spot_l.light_color = Color(1.0, 0.96, 0.85)
	spot_l.light_energy = 4.8
	spot_l.spot_range = 36.0
	spot_l.spot_angle = 36.0
	spot_l.position = Vector3(0, 0.68, -2.25)
	root.add_child(spot_l)

	if v_type == "motorcycle":
		# Motocicleta urbana / streetfighter PBR
		var moto_paint := PBRMaterials.make_car_paint_material(Color(0.72, 0.14, 0.88), 0.16, 0.82)
		var leather_mat := PBRMaterials.make_leather_material(Color(0.09, 0.09, 0.10), 0.35)
		var gold_fork := PBRMaterials.make_metal_material(Color(0.88, 0.72, 0.24), 0.94, 0.18)
		var engine_mat := PBRMaterials.make_metal_material(Color(0.28, 0.31, 0.36), 0.86, 0.38)

		# Chasis tubular perimetral
		_add_box(root, Vector3(0.38, 0.42, 1.25), Vector3(0.0, 0.58, 0.0), dark_trim)
		# Depósito de combustible esculpido con rebajes para las rodillas
		_add_box(root, Vector3(0.44, 0.26, 0.68), Vector3(0.0, 0.85, -0.18), moto_paint, Vector3(-12.0, 0.0, 0.0))
		_add_cyl(root, 0.045, 0.02, Vector3(0.0, 0.99, -0.25), chrome_mat)  # Tapón de gasolina
		# Asiento de cuero biplaza escalonado
		_add_box(root, Vector3(0.34, 0.12, 0.62), Vector3(0.0, 0.80, 0.32), leather_mat, Vector3(6.0, 0.0, 0.0))
		_add_box(root, Vector3(0.28, 0.14, 0.32), Vector3(0.0, 0.86, 0.58), leather_mat)
		# Colín trasero afilado con luz de freno LED
		_add_box(root, Vector3(0.26, 0.16, 0.42), Vector3(0.0, 0.84, 0.84), moto_paint, Vector3(14.0, 0.0, 0.0))
		_add_box(root, Vector3(0.20, 0.06, 0.04), Vector3(0.0, 0.86, 1.05), brake_mat)

		# Bloque motor bicilíndrico con aletas de refrigeración
		_add_box(root, Vector3(0.36, 0.34, 0.48), Vector3(0.0, 0.40, -0.05), engine_mat)
		_add_cyl(root, 0.09, 0.42, Vector3(0.0, 0.38, 0.02), engine_mat, Vector3(0.0, 0.0, 90.0))
		# Colector de escape y silenciador deportivo cromado inclinado
		_add_cyl(root, 0.032, 0.62, Vector3(0.18, 0.32, 0.12), chrome_mat, Vector3(82.0, -10.0, 0.0))
		_add_cyl(root, 0.052, 0.52, Vector3(0.24, 0.48, 0.65), chrome_mat, Vector3(72.0, -8.0, 0.0))

		# Horquilla delantera telescópica invertida en oro anodizado
		_add_cyl(root, 0.026, 0.78, Vector3(-0.11, 0.56, -0.72), gold_fork, Vector3(-24.0, 0.0, 0.0))
		_add_cyl(root, 0.026, 0.78, Vector3(0.11, 0.56, -0.72), gold_fork, Vector3(-24.0, 0.0, 0.0))
		# Manillar con puños y panel de instrumentos digital
		_add_box(root, Vector3(0.68, 0.035, 0.035), Vector3(0.0, 0.94, -0.56), chrome_mat)
		_add_box(root, Vector3(0.12, 0.03, 0.035), Vector3(-0.29, 0.94, -0.56), dark_trim)
		_add_box(root, Vector3(0.12, 0.03, 0.035), Vector3(0.29, 0.94, -0.56), dark_trim)
		_add_box(root, Vector3(0.14, 0.07, 0.06), Vector3(0.0, 0.96, -0.52), dark_trim, Vector3(25.0, 0.0, 0.0))

		# Cúpula frontal aerodinámica con faro LED
		_add_box(root, Vector3(0.28, 0.22, 0.22), Vector3(0.0, 0.88, -0.74), moto_paint, Vector3(-18.0, 0.0, 0.0))
		_add_box(root, Vector3(0.18, 0.12, 0.04), Vector3(0.0, 0.84, -0.84), head_mat)

		# Basculante trasero monoamortiguador
		_add_box(root, Vector3(0.24, 0.10, 0.65), Vector3(0.0, 0.38, 0.48), dark_trim, Vector3(-14.0, 0.0, 0.0))
		_add_cyl(root, 0.035, 0.28, Vector3(0.0, 0.52, 0.26), gold_fork, Vector3(45.0, 0.0, 0.0))

		# Rueda delantera con disco y pinza
		_add_cyl(root, 0.34, 0.13, Vector3(0.0, 0.34, -0.85), tire_mat, Vector3(0.0, 0.0, 90.0))
		_add_cyl(root, 0.24, 0.14, Vector3(0.0, 0.34, -0.85), rim_mat, Vector3(0.0, 0.0, 90.0))
		_add_cyl(root, 0.20, 0.15, Vector3(0.0, 0.34, -0.85), rotor_mat, Vector3(0.0, 0.0, 90.0))

		# Rueda trasera deportiva ancha
		_add_cyl(root, 0.34, 0.22, Vector3(0.0, 0.34, 0.82), tire_mat, Vector3(0.0, 0.0, 90.0))
		_add_cyl(root, 0.23, 0.23, Vector3(0.0, 0.34, 0.82), rim_mat, Vector3(0.0, 0.0, 90.0))
		_add_cyl(root, 0.18, 0.24, Vector3(0.0, 0.34, 0.82), rotor_mat, Vector3(0.0, 0.0, 90.0))

		spot_l.position = Vector3(0.0, 0.82, -0.88)
		spot_l.spot_range = 30.0

		var underglow := OmniLight3D.new()
		underglow.light_color = Color(0.75, 0.18, 0.95)
		underglow.light_energy = 2.0
		underglow.omni_range = 4.5
		underglow.position = Vector3(0.0, 0.25, 0.0)
		root.add_child(underglow)

		return {"root": root, "brake_mat": brake_mat, "headlight": spot_l}

	var is_sport: bool = (v_type == "sports_car")

	if is_sport:
		# Auto Superdeportivo PBR: Perfil bajo, cuña aerodinámica, alerón GT y cuádruple escape
		var sport_paint := PBRMaterials.make_car_paint_material(Color(0.08, 0.46, 0.90), 0.14, 0.85)

		# Chasis inferior / splitter delantero en fibra de carbono
		_add_box(root, Vector3(2.08, 0.12, 4.42), Vector3(0.0, 0.22, 0.0), dark_trim)
		_add_box(root, Vector3(2.12, 0.06, 0.42), Vector3(0.0, 0.16, -2.18), dark_trim)

		# Carrocería principal esculpida
		_add_box(root, Vector3(2.02, 0.38, 4.25), Vector3(0.0, 0.44, 0.0), sport_paint)
		# Capó inclinado hacia adelante con salidas de aire
		_add_box(root, Vector3(1.82, 0.16, 1.52), Vector3(0.0, 0.60, -1.22), sport_paint, Vector3(7.0, 0.0, 0.0))
		_add_box(root, Vector3(0.65, 0.04, 0.45), Vector3(0.0, 0.67, -1.15), dark_trim, Vector3(7.0, 0.0, 0.0))

		# Cabina con parabrisas inclinado hacia atrás
		_add_box(root, Vector3(1.68, 0.46, 0.82), Vector3(0.0, 0.86, -0.32), glass_mat, Vector3(-32.0, 0.0, 0.0))
		# Techo aerodinámico con nervadura central
		_add_box(root, Vector3(1.52, 0.12, 1.32), Vector3(0.0, 1.10, 0.26), sport_paint)
		# Luna trasera fastback
		_add_box(root, Vector3(1.48, 0.38, 0.72), Vector3(0.0, 0.94, 0.98), glass_mat, Vector3(28.0, 0.0, 0.0))
		# Ventanillas laterales tintadas
		_add_box(root, Vector3(1.54, 0.34, 1.25), Vector3(0.0, 0.94, 0.28), glass_mat)

		# Tomas de aire laterales y taloneras aerodinámicas
		_add_box(root, Vector3(2.06, 0.22, 0.75), Vector3(0.0, 0.48, 0.55), dark_trim)
		# Espejos retrovisores exteriores con espejo cromado
		_add_box(root, Vector3(0.24, 0.10, 0.14), Vector3(-1.08, 0.85, -0.35), sport_paint)
		_add_box(root, Vector3(0.02, 0.08, 0.12), Vector3(-1.18, 0.85, -0.34), chrome_mat)
		_add_box(root, Vector3(0.24, 0.10, 0.14), Vector3(1.08, 0.85, -0.35), sport_paint)
		_add_box(root, Vector3(0.02, 0.08, 0.12), Vector3(1.18, 0.85, -0.34), chrome_mat)

		# Alerón GT sobre montantes gemelos
		_add_box(root, Vector3(0.06, 0.36, 0.18), Vector3(-0.65, 1.02, 1.88), dark_trim)
		_add_box(root, Vector3(0.06, 0.36, 0.18), Vector3(0.65, 1.02, 1.88), dark_trim)
		_add_box(root, Vector3(1.98, 0.08, 0.42), Vector3(0.0, 1.20, 1.94), sport_paint, Vector3(-5.0, 0.0, 0.0))

		# Difusor trasero con 4 tubos de escape cromados
		_add_box(root, Vector3(1.85, 0.16, 0.28), Vector3(0.0, 0.25, 2.14), dark_trim)
		for ex_x in [-0.58, -0.44, 0.44, 0.58]:
			_add_cyl(root, 0.052, 0.18, Vector3(ex_x, 0.26, 2.22), chrome_mat, Vector3(90.0, 0.0, 0.0))

		# Ópticas delanteras LED afiladas
		_add_box(root, Vector3(0.48, 0.12, 0.16), Vector3(-0.70, 0.56, -2.12), head_mat, Vector3(0.0, 12.0, 0.0))
		_add_box(root, Vector3(0.48, 0.12, 0.16), Vector3(0.70, 0.56, -2.12), head_mat, Vector3(0.0, -12.0, 0.0))

		# Tira LED horizontal trasera corrida de freno
		_add_box(root, Vector3(1.68, 0.09, 0.06), Vector3(0.0, 0.65, 2.14), brake_mat)

		# 4 Ruedas de aleación con frenos de disco y pinzas rojas visibles
		for wx in [-1.04, 1.04]:
			for wz in [-1.35, 1.35]:
				var rot_w := Vector3(0.0, 0.0, 90.0)
				_add_cyl(root, 0.38, 0.28, Vector3(wx, 0.38, wz), tire_mat, rot_w)
				_add_cyl(root, 0.28, 0.29, Vector3(wx, 0.38, wz), rim_mat, rot_w)
				_add_cyl(root, 0.22, 0.30, Vector3(wx, 0.38, wz), rotor_mat, rot_w)
				_add_box(root, Vector3(0.06, 0.14, 0.10), Vector3(wx, 0.50, wz - 0.10), caliper_mat)

		var underglow := OmniLight3D.new()
		underglow.light_color = Color(0.14, 0.88, 1.0)
		underglow.light_energy = 2.4
		underglow.omni_range = 6.5
		underglow.position = Vector3(0.0, 0.25, 0.0)
		root.add_child(underglow)

		return {"root": root, "brake_mat": brake_mat, "headlight": spot_l}

	else:
		# Sedán Ejecutivo / Mafia PBR: Parrilla cromada imponente, lunas tintadas VIP y elegancia oscura
		var sedan_paint := PBRMaterials.make_car_paint_material(Color(0.045, 0.048, 0.055), 0.12, 0.45)
		var vip_glass := PBRMaterials.make_glass_material(Color(0.035, 0.045, 0.060), 0.04)

		# Chasis y faldones
		_add_box(root, Vector3(2.10, 0.14, 4.60), Vector3(0.0, 0.24, 0.0), dark_trim)
		# Carrocería ejecutiva alargada
		_add_box(root, Vector3(2.05, 0.44, 4.48), Vector3(0.0, 0.48, 0.0), sedan_paint)
		# Capó prominente con nervadura central
		_add_box(root, Vector3(1.88, 0.18, 1.62), Vector3(0.0, 0.68, -1.25), sedan_paint)
		# Gran parrilla frontal cromada con lamas verticales
		_add_box(root, Vector3(0.88, 0.42, 0.08), Vector3(0.0, 0.54, -2.26), chrome_mat)
		_add_box(root, Vector3(0.96, 0.06, 0.10), Vector3(0.0, 0.74, -2.25), chrome_mat)
		_add_box(root, Vector3(2.08, 0.08, 0.22), Vector3(0.0, 0.32, -2.24), chrome_mat)

		# Cabina ejecutiva 4 puertas con marcos cromados en ventanas
		_add_box(root, Vector3(1.78, 0.54, 2.30), Vector3(0.0, 1.02, 0.18), sedan_paint)
		_add_box(root, Vector3(1.72, 0.48, 0.88), Vector3(0.0, 0.98, -0.42), vip_glass, Vector3(-24.0, 0.0, 0.0))  # Parabrisas
		_add_box(root, Vector3(1.70, 0.44, 0.78), Vector3(0.0, 1.00, 1.15), vip_glass, Vector3(22.0, 0.0, 0.0))    # Luna trasera
		_add_box(root, Vector3(1.80, 0.36, 1.85), Vector3(0.0, 1.02, 0.25), vip_glass)                             # Ventanillas laterales
		# Molduras cromadas de cintura y manillas de 4 puertas
		_add_box(root, Vector3(2.07, 0.035, 3.80), Vector3(0.0, 0.70, 0.05), chrome_mat)
		for mx in [-1.04, 1.04]:
			_add_box(root, Vector3(0.03, 0.04, 0.14), Vector3(mx, 0.72, -0.22), chrome_mat)
			_add_box(root, Vector3(0.03, 0.04, 0.14), Vector3(mx, 0.72, 0.52), chrome_mat)
			# Espejos retrovisores
			_add_box(root, Vector3(0.22, 0.11, 0.14), Vector3(mx * 1.06, 0.90, -0.40), sedan_paint)
			_add_box(root, Vector3(0.02, 0.09, 0.12), Vector3(mx * 1.14, 0.90, -0.39), chrome_mat)

		# Maletero trasero con listón cromado
		_add_box(root, Vector3(1.88, 0.18, 0.95), Vector3(0.0, 0.68, 1.72), sedan_paint)
		_add_box(root, Vector3(1.65, 0.045, 0.06), Vector3(0.0, 0.74, 2.22), chrome_mat)

		# Doble escape cromado ovalado
		_add_cyl(root, 0.055, 0.16, Vector3(-0.64, 0.26, 2.24), chrome_mat, Vector3(90.0, 0.0, 0.0))
		_add_cyl(root, 0.055, 0.16, Vector3(0.64, 0.26, 2.24), chrome_mat, Vector3(90.0, 0.0, 0.0))

		# Faros delanteros xenón dobles
		_add_box(root, Vector3(0.44, 0.16, 0.08), Vector3(-0.72, 0.60, -2.25), head_mat)
		_add_box(root, Vector3(0.44, 0.16, 0.08), Vector3(0.72, 0.60, -2.25), head_mat)

		# Luces traseras horizontales LED rojas de lujo
		_add_box(root, Vector3(0.48, 0.15, 0.08), Vector3(-0.72, 0.64, 2.24), brake_mat)
		_add_box(root, Vector3(0.48, 0.15, 0.08), Vector3(0.72, 0.64, 2.24), brake_mat)

		# 4 Ruedas de turbina multi-radio ejecutivas
		for wx in [-1.04, 1.04]:
			for wz in [-1.45, 1.45]:
				var rot_w := Vector3(0.0, 0.0, 90.0)
				_add_cyl(root, 0.39, 0.28, Vector3(wx, 0.39, wz), tire_mat, rot_w)
				_add_cyl(root, 0.29, 0.29, Vector3(wx, 0.39, wz), chrome_mat, rot_w)
				_add_cyl(root, 0.21, 0.30, Vector3(wx, 0.39, wz), rotor_mat, rot_w)
				_add_box(root, Vector3(0.06, 0.14, 0.10), Vector3(wx, 0.51, wz - 0.10), caliper_mat)

		var underglow := OmniLight3D.new()
		underglow.light_color = Color(0.96, 0.16, 0.22)
		underglow.light_energy = 2.0
		underglow.omni_range = 6.0
		underglow.position = Vector3(0.0, 0.25, 0.0)
		root.add_child(underglow)

		return {"root": root, "brake_mat": brake_mat, "headlight": spot_l}

