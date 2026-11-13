extends Node3D
class_name WorldSectorManager

# ==============================================================================
# THE LIFE PROJECT — GESTOR DE SECTORES DEL MUNDO ABIERTO (STREAMING / CULLING)
# ==============================================================================
# Particiona y gestiona la visibilidad y el rendimiento de las distintas
# regiones del mundo abierto para garantizar 60 FPS estables en hardware de
# gama media como NVIDIA GeForce 920MX.
# ==============================================================================

var coastal_builder: CoastalRegionBuilder = null

# Nodos contenedores de sectores
var sector_city: Node3D = null
var sector_coastal: Node3D = null

# Parámetros de streaming y LOD
const CHUNK_CHECK_INTERVAL := 0.25
var _time_since_check: float = 0.0

func initialize_sectors(parent: Node3D) -> void:
	# 1. Contenedor de la Gran Ciudad (Región 1)
	sector_city = Node3D.new()
	sector_city.name = "Sector_01_City"
	parent.add_child(sector_city)

	# 2. Contenedor de la Costa y Océano (Región 5 - Primera Región de Referencia)
	sector_coastal = Node3D.new()
	sector_coastal.name = "Sector_05_Coastal"
	parent.add_child(sector_coastal)

	coastal_builder = CoastalRegionBuilder.new()
	coastal_builder.name = "CoastalRegionBuilder"
	sector_coastal.add_child(coastal_builder)
	coastal_builder.build_coastal_region(sector_coastal)

func update_sectors(delta: float, player_pos: Vector3, night_factor: float, is_storm: bool, wind_strength: float) -> void:
	_time_since_check += delta
	if _time_since_check >= CHUNK_CHECK_INTERVAL:
		_time_since_check = 0.0
		_evaluate_sector_distances(player_pos)

	# Actualización continua de animaciones ambientales costeras (Faro, Olas, Farolas)
	if coastal_builder:
		coastal_builder.update_coastal_environment(delta, night_factor, is_storm, wind_strength)

func _evaluate_sector_distances(player_pos: Vector3) -> void:
	# Distancia al centro de la región costera (aprox X = -320, Z = 0)
	var coastal_center := Vector3(-320.0, 0.0, 0.0)
	var dist_coastal := player_pos.distance_to(coastal_center)

	# Si el jugador está excesivamente lejos de la costa (> 900m), se pueden ocultar elementos de micro-detalle
	if dist_coastal < 800.0:
		if not sector_coastal.visible:
			sector_coastal.visible = true
	else:
		if sector_coastal.visible:
			sector_coastal.visible = false
