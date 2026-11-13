extends StaticBody3D
class_name Payphone3D

signal call_answered
signal call_finished

var is_ringing: bool = true
var answered: bool = false
var ring_timer: float = 0.0
var pulse_light: OmniLight3D

var dialogue_lines := [
	"Informante: Al habla... Sé lo que pasó en la cena y la muerte de tu madre.",
	"Informante: El Director Kuroshio dio la orden directa para borrarlos del mapa.",
	"Informante: Rodrigo 'El Chacal' fue quien disparó. Se esconde en el taller Cyber-Gear al este.",
	"Informante: Sigue la baliza dorada en tu radar GPS hasta el taller y haz justicia."
]
var dialogue_idx: int = 0

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("payphone")

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.1, 2.4, 1.1)
	col.shape = shape
	col.position = Vector3(0, 1.2, 0)
	add_child(col)

	var frame_mat := ModelBuilder.make_toon_material(Color(0.10, 0.16, 0.25), Color(0.15, 0.85, 0.95), 0.4)
	var glass_mat := ModelBuilder.make_toon_material(Color(0.15, 0.35, 0.48), Color(0.20, 0.85, 1.0), 0.3)
	var phone_mat := ModelBuilder.make_toon_material(Color(0.95, 0.78, 0.18), Color(0.95, 0.75, 0.15), 0.8)

	# Estructura de cabina
	_box(Vector3(1.1, 2.4, 1.1), Vector3(0, 1.2, 0), glass_mat)
	_box(Vector3(1.2, 0.16, 1.2), Vector3(0, 2.45, 0), frame_mat)
	_box(Vector3(0.35, 0.55, 0.25), Vector3(0, 1.35, -0.35), phone_mat)

	pulse_light = OmniLight3D.new()
	pulse_light.light_color = Color(1.0, 0.85, 0.25)
	pulse_light.light_energy = 3.0
	pulse_light.omni_range = 9.0
	pulse_light.position = Vector3(0, 2.2, 0)
	add_child(pulse_light)

func _box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)

func _process(delta: float) -> void:
	if is_ringing and not answered:
		ring_timer += delta
		pulse_light.light_energy = 1.5 + abs(sin(ring_timer * 6.0)) * 3.5
		if fmod(ring_timer, 1.8) < delta:
			AudioManager.play_sfx("alert", -4.0)
	else:
		pulse_light.light_energy = 0.8

func get_prompt() -> String:
	if not answered:
		return "[E] CONTESTAR TELÉFONO PÚBLICO"
	return ""

func interact() -> String:
	if not answered:
		answered = true
		is_ringing = false
		dialogue_idx = 0
		AudioManager.play_sfx("click")
		call_answered.emit()
		return dialogue_lines[0]
	return ""

func advance_dialogue() -> String:
	AudioManager.play_sfx("click")
	dialogue_idx += 1
	if dialogue_idx < dialogue_lines.size():
		return dialogue_lines[dialogue_idx]
	call_finished.emit()
	return ""
