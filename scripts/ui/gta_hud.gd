extends CanvasLayer
class_name GTAHud

var subtitle_panel: PanelContainer
var subtitle_label: Label
var prompt_panel: PanelContainer
var prompt_label: Label

var weapon_name_label: Label
var ammo_label: Label
var cash_label: Label
var hp_fill: ColorRect
var weapon_icon_ctrl: Control
var radar_ctrl: Control
var time_label: Label
var date_weather_label: Label
var letterbox_top: ColorRect
var letterbox_bot: ColorRect


func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# 1. Caja de Subtítulos (Arriba Izquierda, estilo captura GTA)
	subtitle_panel = PanelContainer.new()
	subtitle_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle_panel.position = Vector2(24, 20)
	subtitle_panel.custom_minimum_size = Vector2(440, 50)
	var sb_sub := StyleBoxFlat.new()
	sb_sub.bg_color = Color(0.05, 0.06, 0.08, 0.78)
	sb_sub.set_corner_radius_all(6)
	sb_sub.content_margin_left = 14
	sb_sub.content_margin_right = 14
	sb_sub.content_margin_top = 10
	sb_sub.content_margin_bottom = 10
	subtitle_panel.add_theme_stylebox_override("panel", sb_sub)
	add_child(subtitle_panel)

	subtitle_label = Label.new()
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitle_label.custom_minimum_size = Vector2(410, 0)
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.add_theme_color_override("font_color", Color.WHITE)
	subtitle_panel.add_child(subtitle_label)

	# 2. Panel de Arma, Vida y Dinero (Arriba Derecha)
	var top_right := Control.new()
	top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.position = Vector2(-240, 18)
	add_child(top_right)

	weapon_name_label = Label.new()
	weapon_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_name_label.position = Vector2(-80, 6)
	weapon_name_label.custom_minimum_size = Vector2(180, 24)
	weapon_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_name_label.add_theme_font_size_override("font_size", 14)
	weapon_name_label.add_theme_color_override("font_color", Color(0.96, 0.80, 0.20))
	top_right.add_child(weapon_name_label)

	var w_box := Panel.new()
	w_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w_box.position = Vector2(105, 0)
	w_box.size = Vector2(115, 72)
	var sb_w := StyleBoxFlat.new()
	sb_w.bg_color = Color(0.06, 0.07, 0.10, 0.75)
	sb_w.border_color = Color(0.22, 0.26, 0.34, 0.9)
	sb_w.set_border_width_all(2)
	sb_w.set_corner_radius_all(4)
	w_box.add_theme_stylebox_override("panel", sb_w)
	top_right.add_child(w_box)

	weapon_icon_ctrl = _WeaponIconDraw.new()
	weapon_icon_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_icon_ctrl.size = Vector2(115, 50)
	w_box.add_child(weapon_icon_ctrl)

	ammo_label = Label.new()
	ammo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ammo_label.position = Vector2(0, 48)
	ammo_label.size = Vector2(115, 22)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ammo_label.add_theme_font_size_override("font_size", 14)
	ammo_label.add_theme_color_override("font_color", Color.WHITE)
	w_box.add_child(ammo_label)

	# Barra de Vida roja debajo de la caja de arma
	var hp_bg := ColorRect.new()
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bg.position = Vector2(105, 78)
	hp_bg.size = Vector2(115, 11)
	hp_bg.color = Color(0.08, 0.08, 0.10)
	top_right.add_child(hp_bg)

	hp_fill = ColorRect.new()
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_fill.position = Vector2(107, 80)
	hp_fill.size = Vector2(111, 7)
	hp_fill.color = Color(0.84, 0.15, 0.18)
	top_right.add_child(hp_fill)

	# Dinero Verde GTA ($00000350)
	cash_label = Label.new()
	cash_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cash_label.position = Vector2(40, 94)
	cash_label.size = Vector2(180, 38)
	cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cash_label.add_theme_font_size_override("font_size", 28)
	cash_label.add_theme_color_override("font_color", Color(0.26, 0.76, 0.30))
	cash_label.add_theme_color_override("font_outline_color", Color.BLACK)
	cash_label.add_theme_constant_override("outline_size", 4)
	top_right.add_child(cash_label)

	# Widget Digital de Tiempo, Calendario y Clima
	var time_box := PanelContainer.new()
	time_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_box.position = Vector2(-20, 138)
	time_box.custom_minimum_size = Vector2(240, 48)
	var sb_t := StyleBoxFlat.new()
	sb_t.bg_color = Color(0.06, 0.08, 0.12, 0.78)
	sb_t.border_color = Color(0.18, 0.22, 0.28, 0.85)
	sb_t.set_border_width_all(1)
	sb_t.set_corner_radius_all(4)
	sb_t.content_margin_left = 10
	sb_t.content_margin_right = 10
	sb_t.content_margin_top = 4
	sb_t.content_margin_bottom = 4
	time_box.add_theme_stylebox_override("panel", sb_t)
	top_right.add_child(time_box)

	var vb_t := VBoxContainer.new()
	vb_t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_box.add_child(vb_t)

	time_label = Label.new()
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.add_theme_font_size_override("font_size", 16)
	time_label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.35))
	vb_t.add_child(time_label)

	date_weather_label = Label.new()
	date_weather_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	date_weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_weather_label.add_theme_font_size_override("font_size", 11)
	date_weather_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.92))
	vb_t.add_child(date_weather_label)

	# 3. Radar Circular GTA (Abajo Izquierda)

	var radar_container := Control.new()
	radar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radar_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	radar_container.position = Vector2(24, -162)
	add_child(radar_container)

	radar_ctrl = _RadarDraw.new()
	radar_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radar_ctrl.size = Vector2(140, 140)
	radar_container.add_child(radar_ctrl)

	# 4. Prompt Interactivo Central Inferior ([E] ...)
	prompt_panel = PanelContainer.new()
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_panel.position = Vector2(-150, -90)
	prompt_panel.custom_minimum_size = Vector2(300, 32)
	prompt_panel.visible = false
	var sb_p := StyleBoxFlat.new()
	sb_p.bg_color = Color(0.06, 0.08, 0.12, 0.88)
	sb_p.border_color = Color(0.96, 0.80, 0.20)
	sb_p.set_border_width_all(2)
	sb_p.set_corner_radius_all(4)
	prompt_panel.add_theme_stylebox_override("panel", sb_p)
	add_child(prompt_panel)

	prompt_label = Label.new()
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	prompt_panel.add_child(prompt_label)

	# 5. Retícula central de apuntado
	var cross := _CrosshairDraw.new()
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position = Vector2(-16, -16)
	cross.size = Vector2(32, 32)
	add_child(cross)

	# 6. Barras cinemáticas Letterbox (Modo Cinemática / Llamadas)
	letterbox_top = ColorRect.new()
	letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	letterbox_top.custom_minimum_size = Vector2(0, 0)
	letterbox_top.color = Color(0.02, 0.02, 0.04)
	add_child(letterbox_top)

	letterbox_bot = ColorRect.new()
	letterbox_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letterbox_bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	letterbox_bot.custom_minimum_size = Vector2(0, 0)
	letterbox_bot.position.y = 720
	letterbox_bot.color = Color(0.02, 0.02, 0.04)
	add_child(letterbox_bot)

func set_letterbox(on: bool) -> void:
	var target_h: float = 62.0 if on else 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(letterbox_top, "custom_minimum_size:y", target_h, 0.35)
	tw.tween_property(letterbox_bot, "custom_minimum_size:y", target_h, 0.35)
	tw.tween_property(letterbox_bot, "position:y", 720.0 - target_h if on else 720.0, 0.35)

func set_subtitle(txt: String) -> void:
	subtitle_label.text = txt
	subtitle_panel.visible = (txt != "")
	if txt.begins_with("Cipher:") or txt.begins_with("Informante:"):
		subtitle_label.add_theme_color_override("font_color", Color(0.96, 0.82, 0.25))
	elif txt.begins_with("Nagumo:"):
		subtitle_label.add_theme_color_override("font_color", Color(0.18, 0.86, 0.96))
	elif txt.begins_with("Shado:"):
		subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.35, 0.95))
	elif txt.begins_with("¡Alerta!") or txt.begins_with("Kuroshio:"):
		subtitle_label.add_theme_color_override("font_color", Color(0.92, 0.22, 0.28))
	else:
		subtitle_label.add_theme_color_override("font_color", Color.WHITE)

func show_mission_completed(chap_code: String, chap_title: String, reward_cash: int, weapon_name: String, next_chap_title: String, on_continue: Callable) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.03, 0.04, 0.07, 0.90)
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-360, -180)
	panel.custom_minimum_size = Vector2(720, 360)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.12, 0.98)
	sb.border_color = Color(0.96, 0.82, 0.25)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", sb)
	overlay.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var l_head := Label.new()
	l_head.text = "★ MISIÓN SUPERADA ★"
	l_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_head.add_theme_font_size_override("font_size", 28)
	l_head.add_theme_color_override("font_color", Color(0.96, 0.82, 0.25))
	vb.add_child(l_head)

	var l_title := Label.new()
	l_title.text = "%s: %s" % [chap_code, chap_title]
	l_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_title.add_theme_font_size_override("font_size", 18)
	l_title.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(l_title)

	vb.add_child(HSeparator.new())

	var l_rew := Label.new()
	var wpn_txt := ("\n• Nueva Arma Desbloqueada: " + weapon_name.to_upper()) if weapon_name != "" else ""
	l_rew.text = "RECOMPENSAS DE LA OPERACIÓN:\n• Fondos Transferidos: +$%d%s\n• Siguiente Capítulo Desbloqueado: %s" % [reward_cash, wpn_txt, next_chap_title]
	l_rew.add_theme_font_size_override("font_size", 15)
	l_rew.add_theme_color_override("font_color", Color(0.35, 0.90, 0.45))
	vb.add_child(l_rew)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(spacer)

	var btn_cont := Button.new()
	btn_cont.text = "CONTINUAR CAMPAÑA"
	btn_cont.custom_minimum_size = Vector2(240, 44)
	btn_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_cont.add_theme_font_size_override("font_size", 16)
	btn_cont.pressed.connect(func():
		AudioManager.play_sfx("click")
		on_continue.call()
	)
	vb.add_child(btn_cont)

func set_prompt(txt: String) -> void:
	prompt_label.text = txt
	prompt_panel.visible = (txt != "")

func _process(_delta: float) -> void:
	if is_instance_valid(time_label) and is_instance_valid(date_weather_label):
		var tw: Node = get_node_or_null("/root/TimeWeatherManager")
		if tw:
			time_label.text = "%s  %s  %s" % [tw.call("get_formatted_time"), tw.call("get_weather_icon"), tw.call("get_temperature_string")]
			var day_name: String = str(tw.call("get_day_of_week_name"))
			var d_num: int = int(tw.get("day_of_month"))
			var s_name: String = str(tw.call("get_season_name"))
			var w_name: String = str(tw.call("get_weather_name"))
			date_weather_label.text = "%s %d · %s · %s" % [day_name, d_num, s_name, w_name]


func update_health(hp: float, max_hp: float) -> void:
	var ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	hp_fill.size.x = 111.0 * ratio
	radar_ctrl.set("hp_ratio", ratio)

func update_cash(amount: int) -> void:
	cash_label.text = "$%08d" % amount

func update_weapon(w: Dictionary) -> void:
	weapon_name_label.text = "[%d] %s" % [w["slot"], w["name"]]
	weapon_icon_ctrl.set("weapon_id", w["id"])
	weapon_icon_ctrl.queue_redraw()
	if w["melee"]:
		ammo_label.text = "PUÑOS"
	else:
		ammo_label.text = "%d / %d" % [w["ammo_clip"], w["ammo_reserve"]]

func update_radar(p_pos: Vector3, p_yaw: float, target_gps: Vector2, blocks: Array) -> void:
	radar_ctrl.set("player_pos", Vector2(p_pos.x, p_pos.z))
	radar_ctrl.set("player_yaw", p_yaw)
	radar_ctrl.set("target_pos", target_gps)
	radar_ctrl.set("blocks", blocks)
	radar_ctrl.queue_redraw()


class _WeaponIconDraw extends Control:
	var weapon_id: String = "m4"
	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := size.y * 0.52
		var col := Color(0.84, 0.86, 0.90)
		var dark := Color(0.18, 0.20, 0.25)
		if weapon_id == "fists":
			draw_rect(Rect2(cx - 12, cy - 10, 24, 20), Color(0.85, 0.68, 0.56))
		elif weapon_id == "pistol":
			draw_rect(Rect2(cx - 14, cy - 8, 28, 8), col)
			draw_rect(Rect2(cx - 14, cy, 9, 14), dark)
		elif weapon_id == "smg":
			draw_rect(Rect2(cx - 18, cy - 8, 36, 9), col)
			draw_rect(Rect2(cx - 4, cy + 1, 6, 15), dark)
			draw_rect(Rect2(cx - 16, cy + 1, 6, 10), dark)
		elif weapon_id == "m4":
			draw_line(Vector2(cx - 34, cy), Vector2(cx + 36, cy), col, 4.0)
			draw_rect(Rect2(cx - 12, cy - 6, 22, 6), col)
			draw_rect(Rect2(cx - 36, cy - 2, 14, 11), dark)
			draw_line(Vector2(cx + 2, cy + 2), Vector2(cx + 5, cy + 15), col, 4.0)
		elif weapon_id == "bazooka":
			draw_rect(Rect2(cx - 32, cy - 5, 56, 10), Color(0.32, 0.42, 0.26))
			draw_colored_polygon(PackedVector2Array([Vector2(cx + 24, cy - 7), Vector2(cx + 38, cy), Vector2(cx + 24, cy + 7)]), Color(0.78, 0.20, 0.16))


class _CrosshairDraw extends Control:
	func _draw() -> void:
		var c := size * 0.5
		draw_arc(c, 10.0, 0, TAU, 24, Color(1.0, 1.0, 1.0, 0.7), 1.5)
		draw_circle(c, 2.0, Color(0.95, 0.22, 0.28))


class _RadarDraw extends Control:
	var player_pos := Vector2.ZERO
	var player_yaw: float = 0.0
	var target_pos := Vector2.ZERO
	var blocks := []
	var hp_ratio: float = 1.0

	func _draw() -> void:
		var r := 62.0
		var c := Vector2(70.0, 70.0)
		draw_circle(c, r, Color(0.08, 0.11, 0.15, 0.88))

		var map_scale := 0.55
		var cos_y := cos(player_yaw)
		var sin_y := sin(player_yaw)

		var world_to_radar := func(wx: float, wz: float) -> Vector2:
			var dx := (wx - player_pos.x) * map_scale
			var dz := (wz - player_pos.y) * map_scale
			var rx := dx * cos_y - dz * sin_y
			var ry := dx * sin_y + dz * cos_y
			return c + Vector2(rx, ry)

		# Edificios dentro del círculo del radar
		for b in blocks:
			var rect: Rect2 = b["rect"]
			var center_r: Vector2 = world_to_radar.call(rect.get_center().x, rect.get_center().y)
			if center_r.distance_to(c) < r + 24.0:
				var pts := PackedVector2Array([
					_clamp_to_circle(world_to_radar.call(rect.position.x, rect.position.y), c, r - 2.0),
					_clamp_to_circle(world_to_radar.call(rect.end.x, rect.position.y), c, r - 2.0),
					_clamp_to_circle(world_to_radar.call(rect.end.x, rect.end.y), c, r - 2.0),
					_clamp_to_circle(world_to_radar.call(rect.position.x, rect.end.y), c, r - 2.0)
				])
				var col := Color(0.16, 0.34, 0.20, 0.85) if b["height"] > 20.0 else Color(0.20, 0.24, 0.30, 0.85)
				draw_colored_polygon(pts, col)

		# Baliza GPS
		var g_pt: Vector2 = _clamp_to_circle(world_to_radar.call(target_pos.x, target_pos.y), c, r - 7.0)
		draw_rect(Rect2(g_pt.x - 4, g_pt.y - 4, 8, 8), Color(0.96, 0.80, 0.20))

		# Aro exterior y arcos de vida / blindaje
		draw_arc(c, r + 2.0, 0, TAU, 48, Color(0.06, 0.07, 0.09), 5.0)
		draw_arc(c, r + 2.0, PI * 0.5, PI * 0.5 + PI * hp_ratio, 24, Color(0.92, 0.22, 0.28), 3.0)
		draw_arc(c, r + 2.0, -PI * 0.5, PI * 0.5, 24, Color(0.22, 0.78, 0.96), 3.0)

		# Flecha del jugador en el centro
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(0, -8), c + Vector2(-6, 6), c + Vector2(0, 3), c + Vector2(6, 6)
		]), Color.WHITE)

		# Letra "N" del Norte rotando según la cámara
		var n_pos := c + Vector2(sin(player_yaw), -cos(player_yaw)) * (r + 3.0)
		draw_circle(n_pos, 9.0, Color(0.08, 0.08, 0.10))
		draw_arc(n_pos, 9.0, 0, TAU, 16, Color(0.88, 0.20, 0.25), 1.5)
		var f := ThemeDB.fallback_font
		draw_string(f, n_pos + Vector2(-4, 4), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color.WHITE)

	func _clamp_to_circle(pt: Vector2, center: Vector2, radius: float) -> Vector2:
		var d := pt - center
		if d.length() > radius:
			return center + d.normalized() * radius
		return pt
