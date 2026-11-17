
extends Node3D
class_name LandscapeGenerator

# ============================================================
# THE LIFE PROJECT
# Terreno, montañas y vegetación tropical
# Godot 4.7.2
# ============================================================

const GRID_RESOLUTION: int = 48
const TREES_PER_REGION: int = 38

var terrain_noise: FastNoiseLite
var rng := RandomNumberGenerator.new()

var terrain_material: StandardMaterial3D
var trunk_material: StandardMaterial3D
var leaves_material: StandardMaterial3D


# ============================================================
# GENERACIÓN PRINCIPAL
# ============================================================

func build_landscape() -> void:
	rng.seed = 20261113

	_setup_noise()
	_setup_materials()

	_create_world_foundation()

	var regions: Array[Dictionary] = [
		{
			"name": "Eastern_Mountains",
			"center": Vector2(325.0, 0.0),
			"size": Vector2(280.0, 300.0),
			"height": 65.0,
			"seed": 11
		},
		{
			"name": "Northern_Forest",
			"center": Vector2(0.0, -320.0),
			"size": Vector2(300.0, 300.0),
			"height": 48.0,
			"seed": 23
		},
		{
			"name": "Southern_Highlands",
			"center": Vector2(0.0, 320.0),
			"size": Vector2(300.0, 300.0),
			"height": 58.0,
			"seed": 37
		},
		{
			"name": "Southeastern_Jungle",
			"center": Vector2(310.0, 280.0),
			"size": Vector2(300.0, 300.0),
			"height": 52.0,
			"seed": 49
		}
	]

	for region in regions:
		_create_terrain_region(region)
		_create_forest_region(region)

	print("THE LIFE PROJECT: paisaje generado correctamente.")


# ============================================================
# BASE FÍSICA DEL MUNDO
# ============================================================

func _create_world_foundation() -> void:
	var ground_body := StaticBody3D.new()
	ground_body.name = "World_Foundation"

	var ground_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()

	# Base de seguridad debajo de las regiones.
	# Su superficie superior coincide con el borde del terreno.
	box.size = Vector3(1100.0, 0.5, 1200.0)

	ground_shape.shape = box
	ground_body.add_child(ground_shape)

	ground_body.position = Vector3(0.0, -0.5, 0.0)

	add_child(ground_body)


# ============================================================
# CONFIGURACIÓN
# ============================================================

func _setup_noise() -> void:
	terrain_noise = FastNoiseLite.new()
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	terrain_noise.seed = 73421
	terrain_noise.frequency = 0.012
	terrain_noise.fractal_octaves = 4
	terrain_noise.fractal_lacunarity = 2.0
	terrain_noise.fractal_gain = 0.48


func _setup_materials() -> void:
	terrain_material = StandardMaterial3D.new()
	terrain_material.vertex_color_use_as_albedo = true
	terrain_material.roughness = 0.96

	trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.27, 0.17, 0.10)
	trunk_material.roughness = 1.0

	leaves_material = StandardMaterial3D.new()
	leaves_material.albedo_color = Color(0.12, 0.29, 0.10)
	leaves_material.roughness = 1.0


# ============================================================
# CONSTRUCCIÓN DEL TERRENO
# ============================================================

func _create_terrain_region(region: Dictionary) -> void:
	var center: Vector2 = region["center"]
	var size: Vector2 = region["size"]
	var max_height: float = float(region["height"])
	var seed_offset: float = float(region["seed"])

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_x: float = size.x * 0.5
	var half_z: float = size.y * 0.5

	var step_x: float = size.x / float(GRID_RESOLUTION)
	var step_z: float = size.y / float(GRID_RESOLUTION)

	for x in range(GRID_RESOLUTION):
		for z in range(GRID_RESOLUTION):
			var x0: float = center.x - half_x + float(x) * step_x
			var x1: float = x0 + step_x

			var z0: float = center.y - half_z + float(z) * step_z
			var z1: float = z0 + step_z

			var p00 := _terrain_point(
				x0, z0, center, size, max_height, seed_offset
			)

			var p10 := _terrain_point(
				x1, z0, center, size, max_height, seed_offset
			)

			var p01 := _terrain_point(
				x0, z1, center, size, max_height, seed_offset
			)

			var p11 := _terrain_point(
				x1, z1, center, size, max_height, seed_offset
			)

			_add_colored_vertex(surface, p00, max_height)
			_add_colored_vertex(surface, p01, max_height)
			_add_colored_vertex(surface, p10, max_height)

			_add_colored_vertex(surface, p10, max_height)
			_add_colored_vertex(surface, p01, max_height)
			_add_colored_vertex(surface, p11, max_height)

	surface.generate_normals()

	var generated_mesh := surface.commit()

	var terrain_mesh := MeshInstance3D.new()
	terrain_mesh.name = str(region["name"])
	terrain_mesh.mesh = generated_mesh
	terrain_mesh.material_override = terrain_material
	terrain_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(terrain_mesh)

	# Crear colisión física sobre toda la montaña.
	terrain_mesh.create_trimesh_collision()

	print("Terreno y colisión creados: ", region["name"])


# ============================================================
# GENERACIÓN DE ALTURA
# ============================================================

func _terrain_point(
	x: float,
	z: float,
	center: Vector2,
	size: Vector2,
	max_height: float,
	seed_offset: float
) -> Vector3:

	var nx: float = (x - center.x) / (size.x * 0.5)
	var nz: float = (z - center.y) / (size.y * 0.5)

	var edge_x: float = maxf(0.0, 1.0 - nx * nx)
	var edge_z: float = maxf(0.0, 1.0 - nz * nz)

	# Transición progresiva en los bordes.
	var edge_mask: float = pow(edge_x * edge_z, 1.5)

	var peak_one: float = exp(
		-((nx + 0.20) * (nx + 0.20) * 7.0)
		-((nz - 0.10) * (nz - 0.10) * 5.0)
	)

	var peak_two: float = exp(
		-((nx - 0.30) * (nx - 0.30) * 10.0)
		-((nz + 0.25) * (nz + 0.25) * 8.0)
	)

	var noise_value: float = terrain_noise.get_noise_2d(
		x + seed_offset * 100.0,
		z - seed_offset * 80.0
	)

	# Montañas más suaves y menos abruptas.
	var mountain_shape: float = peak_one * 0.65 + peak_two * 0.45
	var natural_variation: float = noise_value * 0.10

	var height: float = (
		mountain_shape + natural_variation * edge_mask
	) * max_height * edge_mask

	height = maxf(0.0, height)

	return Vector3(x, -0.25 + height, z)


# ============================================================
# COLOR DEL TERRENO
# ============================================================

func _add_colored_vertex(
	surface: SurfaceTool,
	position: Vector3,
	max_height: float
) -> void:

	var height_ratio: float = clampf(
		(position.y + 0.25) / max_height,
		0.0,
		1.0
	)

	var vertex_color: Color

	if height_ratio < 0.20:
		vertex_color = Color(0.20, 0.34, 0.15)
	elif height_ratio < 0.48:
		vertex_color = Color(0.25, 0.32, 0.17)
	elif height_ratio < 0.75:
		vertex_color = Color(0.34, 0.32, 0.25)
	else:
		vertex_color = Color(0.43, 0.43, 0.40)

	surface.set_color(vertex_color)
	surface.add_vertex(position)


# ============================================================
# VEGETACIÓN TROPICAL
# ============================================================

func _create_forest_region(region: Dictionary) -> void:
	var center: Vector2 = region["center"]
	var size: Vector2 = region["size"]
	var max_height: float = float(region["height"])
	var seed_offset: float = float(region["seed"])

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.20
	trunk_mesh.bottom_radius = 0.34
	trunk_mesh.height = 5.5

	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.0
	crown_mesh.height = 2.0
	crown_mesh.radial_segments = 8
	crown_mesh.rings = 5

	var trunk_mm := MultiMesh.new()
	trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
	trunk_mm.mesh = trunk_mesh
	trunk_mm.instance_count = TREES_PER_REGION

	var crown_mm := MultiMesh.new()
	crown_mm.transform_format = MultiMesh.TRANSFORM_3D
	crown_mm.mesh = crown_mesh
	crown_mm.instance_count = TREES_PER_REGION

	var half_x: float = size.x * 0.34
	var half_z: float = size.y * 0.34

	for i in range(TREES_PER_REGION):
		var x: float = center.x + rng.randf_range(-half_x, half_x)
		var z: float = center.y + rng.randf_range(-half_z, half_z)

		var ground: Vector3 = _terrain_point(
			x, z, center, size, max_height, seed_offset
		)

		var tree_scale: float = rng.randf_range(0.75, 1.35)

		var trunk_transform := Transform3D(
			Basis().scaled(Vector3.ONE * tree_scale),
			ground + Vector3(0.0, 2.75 * tree_scale, 0.0)
		)

		var crown_transform := Transform3D(
			Basis().scaled(
				Vector3(
					2.2 * tree_scale,
					2.8 * tree_scale,
					2.2 * tree_scale
				)
			),
			ground + Vector3(0.0, 6.0 * tree_scale, 0.0)
		)

		trunk_mm.set_instance_transform(i, trunk_transform)
		crown_mm.set_instance_transform(i, crown_transform)

	var trunk_instance := MultiMeshInstance3D.new()
	trunk_instance.name = str(region["name"]) + "_Trunks"
	trunk_instance.multimesh = trunk_mm
	trunk_instance.material_override = trunk_material
	trunk_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trunk_instance)

	var crown_instance := MultiMeshInstance3D.new()
	crown_instance.name = str(region["name"]) + "_Canopies"
	crown_instance.multimesh = crown_mm
	crown_instance.material_override = leaves_material
	crown_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(crown_instance)
