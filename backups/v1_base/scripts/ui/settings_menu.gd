extends Control

var listening_action: String = ""
var key_buttons := {}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.09)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-420, -290)
	panel.custom_minimum_size = Vector2(840, 580)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.14)
	sb.border_color = Color(0.16, 0.86, 0.96)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var main_vb := VBoxContainer.new()
	main_vb.add_theme_constant_override("separation", 16)
	panel.add_child(main_vb)

	var title := Label.new()
	title.text = "AJUSTES Y CONFIGURACIÓN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	main_vb.add_child(title)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vb.add_child(tabs)

	# Pestaña 1: AUDIO
	var audio_vb := VBoxContainer.new()
	audio_vb.name = "AUDIO"
	audio_vb.add_theme_constant_override("separation", 14)
	tabs.add_child(audio_vb)

	var chk_mute := CheckButton.new()
	chk_mute.text = "Silenciar Todo el Audio (Mute Total)"
	chk_mute.button_pressed = SettingsManager.is_muted
	chk_mute.toggled.connect(func(on):
		SettingsManager.is_muted = on
		SettingsManager.apply_audio_settings()
		SettingsManager.save_settings()
	)
	audio_vb.add_child(chk_mute)

	var vol_hb := HBoxContainer.new()
	audio_vb.add_child(vol_hb)
	var l_vol := Label.new()
	l_vol.text = "Volumen General: "
	l_vol.custom_minimum_size = Vector2(200, 0)
	vol_hb.add_child(l_vol)
	var sld_vol := HSlider.new()
	sld_vol.min_value = 0.0
	sld_vol.max_value = 1.0
	sld_vol.step = 0.05
	sld_vol.value = SettingsManager.master_volume
	sld_vol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sld_vol.value_changed.connect(func(val):
		SettingsManager.master_volume = val
		SettingsManager.apply_audio_settings()
		SettingsManager.save_settings()
	)
	vol_hb.add_child(sld_vol)

	var chk_sfx := CheckButton.new()
	chk_sfx.text = "Efectos de Sonido (Disparos, Autos, Pasos)"
	chk_sfx.button_pressed = SettingsManager.sfx_enabled
	chk_sfx.toggled.connect(func(on):
		SettingsManager.sfx_enabled = on
		SettingsManager.save_settings()
	)
	audio_vb.add_child(chk_sfx)

	# Pestaña 2: CONTROLES
	var ctrl_scroll := ScrollContainer.new()
	ctrl_scroll.name = "CONTROLES"
	tabs.add_child(ctrl_scroll)

	var ctrl_vb := VBoxContainer.new()
	ctrl_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ctrl_vb.add_theme_constant_override("separation", 10)
	ctrl_scroll.add_child(ctrl_vb)

	var action_labels := [
		["move_forward", "Mover Adelante / Acelerar"],
		["move_back", "Mover Atrás / Reversa"],
		["move_left", "Girar / Mover Izquierda"],
		["move_right", "Girar / Mover Derecha"],
		["stealth", "Sigilo / Freno de Mano"],
		["interact", "Interactuar / Auto / Teléfono / Escalera"],
		["shoot", "Disparar (Teclado) / También Clic Izq."],
		["horn", "Bocina del Auto"],
		["weapon_next", "Siguiente Arma (También 1-5 o Rueda)"]
	]

	for pair in action_labels:
		var act: String = pair[0]
		var lbl_txt: String = pair[1]
		var hb := HBoxContainer.new()
		ctrl_vb.add_child(hb)
		var l := Label.new()
		l.text = lbl_txt
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(l)
		var b := Button.new()
		b.custom_minimum_size = Vector2(160, 32)
		b.text = OS.get_keycode_string(SettingsManager.current_keys[act])
		b.pressed.connect(func():
			listening_action = act
			b.text = "[PULSA TECLA]"
		)
		hb.add_child(b)
		key_buttons[act] = b

	var btn_reset := Button.new()
	btn_reset.text = "Restaurar Teclas por Defecto"
	btn_reset.pressed.connect(func():
		SettingsManager.restore_default_keys()
		for k in key_buttons.keys():
			key_buttons[k].text = OS.get_keycode_string(SettingsManager.current_keys[k])
	)
	ctrl_vb.add_child(btn_reset)

	# Pestaña 3: GRÁFICOS 3D
	var gfx_vb := VBoxContainer.new()
	gfx_vb.name = "GRÁFICOS 3D"
	gfx_vb.add_theme_constant_override("separation", 14)
	tabs.add_child(gfx_vb)

	var chk_night := CheckButton.new()
	chk_night.text = "Ambiente Nocturno Cyberpunk (Desactivar = Atardecer Dorado GTA)"
	chk_night.button_pressed = SettingsManager.night_mode
	chk_night.toggled.connect(func(on):
		SettingsManager.night_mode = on
		SettingsManager.save_settings()
	)
	gfx_vb.add_child(chk_night)

	var chk_shad := CheckButton.new()
	chk_shad.text = "Sombras Dinámicas 3D"
	chk_shad.button_pressed = SettingsManager.shadows_enabled
	chk_shad.toggled.connect(func(on):
		SettingsManager.shadows_enabled = on
		SettingsManager.save_settings()
	)
	gfx_vb.add_child(chk_shad)

	var chk_rain := CheckButton.new()
	chk_rain.text = "Lluvia 3D Ambiental"
	chk_rain.button_pressed = SettingsManager.rain_enabled
	chk_rain.toggled.connect(func(on):
		SettingsManager.rain_enabled = on
		SettingsManager.save_settings()
	)
	gfx_vb.add_child(chk_rain)

	var chk_shake := CheckButton.new()
	chk_shake.text = "Temblor de Cámara al Disparar y Explotar"
	chk_shake.button_pressed = SettingsManager.screen_shake
	chk_shake.toggled.connect(func(on):
		SettingsManager.screen_shake = on
		SettingsManager.save_settings()
	)
	gfx_vb.add_child(chk_shake)

	var chk_peds := CheckButton.new()
	chk_peds.text = "Transeúntes en Aceras"
	chk_peds.button_pressed = SettingsManager.pedestrians_enabled
	chk_peds.toggled.connect(func(on):
		SettingsManager.pedestrians_enabled = on
		SettingsManager.save_settings()
	)
	gfx_vb.add_child(chk_peds)

	# Botón Volver
	var back_btn := Button.new()
	back_btn.text = "GUARDAR Y VOLVER AL MENÚ"
	back_btn.custom_minimum_size = Vector2(260, 42)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		SettingsManager.save_settings()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	main_vb.add_child(back_btn)

func _unhandled_input(event: InputEvent) -> void:
	if listening_action != "" and event is InputEventKey and event.pressed:
		if event.keycode != KEY_ESCAPE:
			SettingsManager.rebind_action(listening_action, event.keycode)
			key_buttons[listening_action].text = OS.get_keycode_string(event.keycode)
		else:
			key_buttons[listening_action].text = OS.get_keycode_string(SettingsManager.current_keys[listening_action])
		listening_action = ""
		AudioManager.play_sfx("click")
		get_viewport().set_input_as_handled()
