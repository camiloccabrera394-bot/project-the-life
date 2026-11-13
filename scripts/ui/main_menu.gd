extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	var tex := GameState.load_texture_safe("res://assets/images/backgrounds/portada.png")
	if tex:
		bg.texture = tex
	else:
		var cr := ColorRect.new()
		cr.set_anchors_preset(Control.PRESET_FULL_RECT)
		cr.color = Color(0.05, 0.06, 0.09)
		add_child(cr)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	vbox.position = Vector2(-150, -210)
	vbox.custom_minimum_size = Vector2(300, 180)
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	var options := [
		["MODO HISTORIA (CAMPAÑA)", func(): AudioManager.play_sfx("click"); get_tree().change_scene_to_file("res://scenes/ui/mission_board.tscn")],
		["AJUSTES Y CONTROLES", func(): AudioManager.play_sfx("click"); get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")],
		["SALIR", func(): get_tree().quit()]
	]

	for opt in options:
		var btn := Button.new()
		btn.text = opt[0]
		btn.custom_minimum_size = Vector2(300, 44)
		btn.add_theme_font_size_override("font_size", 20)
		var sb_norm := StyleBoxFlat.new()
		sb_norm.bg_color = Color(0.07, 0.08, 0.12, 0.88)
		sb_norm.border_color = Color(0.25, 0.28, 0.36)
		sb_norm.set_border_width_all(2)
		sb_norm.set_corner_radius_all(5)

		var sb_hov := StyleBoxFlat.new()
		sb_hov.bg_color = Color(0.14, 0.07, 0.10, 0.95)
		sb_hov.border_color = Color(0.92, 0.16, 0.22)
		sb_hov.set_border_width_all(2)
		sb_hov.set_corner_radius_all(5)

		btn.add_theme_stylebox_override("normal", sb_norm)
		btn.add_theme_stylebox_override("hover", sb_hov)
		btn.add_theme_stylebox_override("pressed", sb_hov)
		btn.pressed.connect(opt[1])
		vbox.add_child(btn)
