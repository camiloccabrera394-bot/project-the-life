extends Area3D
class_name Pickup3D

signal item_collected(p_type: String)

var pickup_type: String = "ammo"
var amount: int = 30
var mesh_node: MeshInstance3D
var bob_time: float = 0.0

func setup(pos: Vector3, p_type: String = "ammo", amt: int = 30) -> void:
	global_position = pos
	pickup_type = p_type
	amount = amt

func _ready() -> void:
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.4
	col.shape = sph
	add_child(col)

	mesh_node = MeshInstance3D.new()
	var box := BoxMesh.new()
	if pickup_type == "briefcase":
		box.size = Vector3(0.72, 0.48, 0.22)
	else:
		box.size = Vector3(0.65, 0.45, 0.45)
	mesh_node.mesh = box

	var c := Color(0.18, 0.88, 0.35)
	if pickup_type == "briefcase":
		c = Color(0.96, 0.82, 0.25)
	elif pickup_type == "ammo":
		c = Color(0.16, 0.88, 0.96)

	mesh_node.material_override = PBRMaterials.make_pbr_standard(c, 0.28, 0.45, c, 1.2)
	add_child(mesh_node)

	var light := OmniLight3D.new()
	light.light_color = c
	light.light_energy = 2.0 if pickup_type == "briefcase" else 1.2
	light.omni_range = 6.0 if pickup_type == "briefcase" else 4.0
	add_child(light)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	bob_time += delta * 2.5
	mesh_node.rotation.y += delta * 1.8
	mesh_node.position.y = 0.6 + sin(bob_time) * 0.2

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		AudioManager.play_sfx("click")
		item_collected.emit(pickup_type)
		if pickup_type == "medkit":
			if body.has_method("heal"):
				body.call("heal", 45.0)
		elif pickup_type == "ammo":
			if body.has_method("add_ammo"):
				body.call("add_ammo", amount)
		queue_free()
