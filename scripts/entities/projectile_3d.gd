extends Node3D
class_name Projectile3D

var dir: Vector3 = Vector3.FORWARD
var speed: float = 65.0
var damage: float = 40.0
var is_rocket: bool = false
var owner_type: String = "Player"
var traveled: float = 0.0
const MAX_DIST := 180.0

var mesh_inst: MeshInstance3D

func setup(start_pos: Vector3, direction: Vector3, dmg: float, spd: float, rocket: bool, own: String) -> void:
	global_position = start_pos
	dir = direction.normalized()
	damage = dmg
	speed = spd
	is_rocket = rocket
	owner_type = own

func _ready() -> void:
	mesh_inst = MeshInstance3D.new()
	if is_rocket:
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.12
		cyl.height = 0.7
		mesh_inst.mesh = cyl
		mesh_inst.rotation_degrees = Vector3(90, 0, 0)
		mesh_inst.material_override = ModelBuilder.make_toon_material(Color(0.85, 0.25, 0.15), Color(1.0, 0.55, 0.15), 2.5, 0.0)

		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.5, 0.15)
		light.light_energy = 2.0
		light.omni_range = 6.0
		add_child(light)
	else:
		var sph := SphereMesh.new()
		sph.radius = 0.09
		sph.height = 0.18
		mesh_inst.mesh = sph
		var col := Color(1.0, 0.22, 0.22) if owner_type == "Enemy" else Color(1.0, 0.90, 0.30)
		mesh_inst.material_override = ModelBuilder.make_toon_material(col, col, 3.0, 0.0)

	add_child(mesh_inst)
	if dir.length_squared() > 0.001:
		look_at(global_position + dir, Vector3.UP)

func _physics_process(delta: float) -> void:
	var step := dir * speed * delta
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position, global_position + step)
	if owner_type == "Player":
		var ex: Array[RID] = []
		for p in get_tree().get_nodes_in_group("player"):
			if p is CollisionObject3D:
				ex.append(p.get_rid())
				var cv: Variant = p.get("current_vehicle")
				if cv is CollisionObject3D:
					ex.append((cv as CollisionObject3D).get_rid())
		query.exclude = ex
	var result := space_state.intersect_ray(query)

	if result:
		_on_hit(result["collider"], result["position"])
		return

	global_position += step
	traveled += step.length()
	if traveled > MAX_DIST:
		if is_rocket:
			_spawn_explosion(global_position)
		queue_free()

func _on_hit(collider: Object, hit_pos: Vector3) -> void:
	if is_rocket:
		_spawn_explosion(hit_pos)
	else:
		if owner_type == "Player":
			if collider is Node and collider.has_method("take_damage"):
				collider.call("take_damage", damage)
		else:
			if collider is Node and collider.is_in_group("player") and collider.has_method("take_damage"):
				collider.call("take_damage", damage)
			elif collider is Node and collider.is_in_group("vehicle") and collider.has_method("take_damage"):
				collider.call("take_damage", damage)
	queue_free()

func _spawn_explosion(pos: Vector3) -> void:
	AudioManager.play_sfx("explosion")
	var parent_world := get_parent()

	# Luz flash y bola de fuego 3D temporal
	var exp_node := Node3D.new()
	exp_node.global_position = pos
	var sph := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 3.5
	sm.height = 7.0
	sph.mesh = sm
	sph.material_override = ModelBuilder.make_toon_material(Color(1.0, 0.4, 0.1), Color(1.0, 0.65, 0.15), 5.0, 0.0)
	exp_node.add_child(sph)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.15)
	light.light_energy = 8.0
	light.omni_range = 18.0
	exp_node.add_child(light)

	parent_world.add_child(exp_node)
	var tw := parent_world.create_tween()
	tw.tween_property(sph, "scale", Vector3(2.2, 2.2, 2.2), 0.25)
	tw.parallel().tween_property(light, "light_energy", 0.0, 0.45)
	tw.tween_callback(exp_node.queue_free)

	# Daño de área contra enemigos, peatones y vehículos
	var radius := 14.0
	for en in get_tree().get_nodes_in_group("enemy"):
		if en is Node3D and is_instance_valid(en) and (en as Node3D).global_position.distance_to(pos) < radius:
			if en.has_method("take_damage"):
				en.call("take_damage", damage)
	for civ in get_tree().get_nodes_in_group("civilian"):
		if civ is Node3D and is_instance_valid(civ) and (civ as Node3D).global_position.distance_to(pos) < radius:
			if civ.has_method("get_hit_by_vehicle"):
				var push: Vector3 = ((civ as Node3D).global_position - pos).normalized() * 14.0
				civ.call("get_hit_by_vehicle", push)
	for veh in get_tree().get_nodes_in_group("vehicle"):
		if veh is Node3D and is_instance_valid(veh) and (veh as Node3D).global_position.distance_to(pos) < radius:
			if veh.has_method("explode"):
				veh.call("explode")
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p.has_method("add_camera_shake"):
			p.call("add_camera_shake", 0.75)
