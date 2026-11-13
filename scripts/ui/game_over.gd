extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.02, 0.03)
	add_child(bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.position = Vector2(-200, -140)
	vb.custom_minimum_size = Vector2(400, 280)
	vb.add_theme_constant_override("separation", 18)
	add_child(vb)

	var title := Label.new()
	title.text = "ELIMINADO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.92, 0.16, 0.22))
	vb.add_child(title)

	var sub := Label.new()
	sub.text = "Has caído en las calles de la ciudad."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	vb.add_child(sub)

	var b_retry := Button.new()
	b_retry.text = "REINTENTAR OPERACIÓN"
	b_retry.custom_minimum_size = Vector2(0, 42)
	b_retry.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/world/city_world.tscn"))
	vb.add_child(b_retry)

	var b_board := Button.new()
	b_board.text = "TABLERO DE OPERACIONES"
	b_board.custom_minimum_size = Vector2(0, 42)
	b_board.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/mission_board.tscn"))
	vb.add_child(b_board)

	var b_menu := Button.new()
	b_menu.text = "MENÚ PRINCIPAL"
	b_menu.custom_minimum_size = Vector2(0, 42)
	b_menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	vb.add_child(b_menu)
