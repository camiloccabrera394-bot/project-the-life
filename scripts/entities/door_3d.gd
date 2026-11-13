extends StaticBody3D
class_name Door3D

var label_txt: String = "ENTRAR"
var callback: Callable

func setup(pos: Vector3, lbl: String, cb: Callable) -> void:
	position = pos
	label_txt = lbl
	callback = cb

func _ready() -> void:
	add_to_group("interactable")
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.4, 3.0, 0.5)
	col.shape = bs
	col.position = Vector3(0, 1.5, 0)
	add_child(col)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.4, 3.0, 0.3)
	mi.mesh = bm
	mi.position = Vector3(0, 1.5, 0)
	mi.material_override = PBRMaterials.make_glass_material(Color(0.08, 0.14, 0.22), 0.12, Color(0.16, 0.88, 1.0), 1.8)
	add_child(mi)

func get_prompt() -> String:
	return "[E] " + label_txt

func interact(player: Node3D) -> void:
	AudioManager.play_sfx("click")
	if callback.is_valid():
		callback.call(player)
