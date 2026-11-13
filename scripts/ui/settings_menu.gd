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
		["weapon_next", "Siguiente Arma (También 1-5 o Rueda)"],
		["camera_distance", "Distancia de Cámara (Cerca / Media / Lejos)"]
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

	var qual_hb := HBoxContainer.new()
	gfx_vb.add_child(qual_hb)
	var l_qual := Label.new()
	l_qual.text = "Calidad Gráfica 3D (PBR / SSAO / Reflejos):"
	l_qual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qual_hb.add_child(l_qual)
	var opt_qual := OptionButton.new()
	opt_qual.custom_minimum_size = Vector2(280, 34)
	opt_qual.add_item("Baja (Máximo FPS)")
	opt_qual.add_item("Media (PBR + SSAO)")
	opt_qual.add_item("Alta (PBR + SSAO + Reflejos SSR)")
	var q_levels := ["low", "medium", "high"]
	var cur_idx: int = q_levels.find(SettingsManager.graphics_quality)
	opt_qual.selected = cur_idx if cur_idx != -1 else 2
	opt_qual.item_selected.connect(func(idx: int) -> void:
		SettingsManager.graphics_quality = q_levels[idx]
		SettingsManager.save_settings()
	)
	qual_hb.add_child(opt_qual)

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

	# Pestaña 4: TIEMPO Y CLIMA DINÁMICO
	var tw_vb := VBoxContainer.new()
	tw_vb.name = "TIEMPO Y CLIMA"
	tw_vb.add_theme_constant_override("separation", 14)
	tabs.add_child(tw_vb)

	# 1. Velocidad del Ciclo Día/Noche
	var speed_hb := HBoxContainer.new()
	tw_vb.add_child(speed_hb)
	var l_speed := Label.new()
	l_speed.text = "Duración del Día Completo (24h de juego):"
	l_speed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_hb.add_child(l_speed)
	var opt_speed := OptionButton.new()
	opt_speed.custom_minimum_size = Vector2(280, 34)
	opt_speed.add_item("Rápido (12 minutos reales)")
	opt_speed.add_item("Normal (24 minutos reales)")
	opt_speed.add_item("Lento (48 minutos reales)")
	var dur_map := [12.0, 24.0, 48.0]
	var tw_node: Node = get_node_or_null("/root/TimeWeatherManager")
	var cur_dur: float = tw_node.get("day_duration_minutes") if tw_node else 24.0
	opt_speed.selected = 0 if cur_dur <= 14.0 else (2 if cur_dur >= 40.0 else 1)
	opt_speed.item_selected.connect(func(idx: int) -> void:
		var tw_ref: Node = get_node_or_null("/root/TimeWeatherManager")
		if tw_ref:
			tw_ref.call("set_day_duration_minutes", dur_map[idx])
			tw_ref.call("save_state")
	)
	speed_hb.add_child(opt_speed)

	# 2. Forzar Hora del Día (Pruebas y Demostración)
	var time_hb := HBoxContainer.new()
	tw_vb.add_child(time_hb)
	var l_thour := Label.new()
	l_thour.text = "Ajustar Hora Inmediata:"
	l_thour.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_hb.add_child(l_thour)
	var opt_hour := OptionButton.new()
	opt_hour.custom_minimum_size = Vector2(280, 34)
	opt_hour.add_item("Mantener Reloj Automático")
	opt_hour.add_item("Amanecer (06:00)")
	opt_hour.add_item("Mediodía Solar (12:00)")
	opt_hour.add_item("Atardecer Dorado (18:30)")
	opt_hour.add_item("Medianoche Urbana (00:00)")
	opt_hour.item_selected.connect(func(idx: int) -> void:
		var tw_ref: Node = get_node_or_null("/root/TimeWeatherManager")
		if tw_ref:
			match idx:
				1: tw_ref.call("set_time", 6, 0)
				2: tw_ref.call("set_time", 12, 0)
				3: tw_ref.call("set_time", 18, 30)
				4: tw_ref.call("set_time", 0, 0)
	)
	time_hb.add_child(opt_hour)

	# 3. Forzar Clima Inmediato
	var wtr_hb := HBoxContainer.new()
	tw_vb.add_child(wtr_hb)
	var l_wtr := Label.new()
	l_wtr.text = "Forzar Condición Meteorológica:"
	l_wtr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wtr_hb.add_child(l_wtr)
	var opt_wtr := OptionButton.new()
	opt_wtr.custom_minimum_size = Vector2(280, 34)
	opt_wtr.add_item("Clima Dinámico Automático")
	opt_wtr.add_item("Soleado / Despejado ☀️")
	opt_wtr.add_item("Lluvia Moderada 🌧️")
	opt_wtr.add_item("Tormenta Eléctrica ⛈️")
	opt_wtr.add_item("Niebla Densa 🌫️")
	opt_wtr.add_item("Viento Fuerte 💨")
	opt_wtr.item_selected.connect(func(idx: int) -> void:
		var tw_ref: Node = get_node_or_null("/root/TimeWeatherManager")
		if tw_ref:
			match idx:
				1: tw_ref.call("force_weather", "SOLEADO")
				2: tw_ref.call("force_weather", "LLUVIA MODERADA")
				3: tw_ref.call("force_weather", "TORMENTA ELÉCTRICA")
				4: tw_ref.call("force_weather", "NIEBLA")
				5: tw_ref.call("force_weather", "VIENTO FUERTE")
	)
	wtr_hb.add_child(opt_wtr)

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
