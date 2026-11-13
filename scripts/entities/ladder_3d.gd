extends StaticBody3D
class_name Ladder3D

var target_pos: Vector3
var label_txt: String = "SUBIR A LA AZOTEA"

func setup(pos: Vector3, dest: Vector3, lbl: String) -> void:
	position = pos
	target_pos = dest
	label_txt = lbl

func _ready() -> void:
	add_to_group("interactable")
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.4, 3.0, 0.5)
	col.shape = bs
	col.position = Vector3(0, 1.5, 0)
	add_child(col)

	var lad_mat := PBRMaterials.make_metal_material(Color(0.85, 0.68, 0.16), 0.82, 0.35)
	for ry in range(1, 13):
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.1, 0.12, 0.12)
		mi.mesh = bm
		mi.position = Vector3(0, ry * 0.9, 0)
		mi.material_override = lad_mat
		add_child(mi)

func get_prompt() -> String:
	return "[E] " + label_txt

func interact(player: Node3D) -> void:
	AudioManager.play_sfx("click")
	player.global_position = target_pos
