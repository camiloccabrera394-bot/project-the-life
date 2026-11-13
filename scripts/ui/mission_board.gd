extends Control

# ==============================================================================
# THE LIFE PROJECT — MENÚ DEL MODO HISTORIA (CAMPAÑA NARRATIVA)
# ==============================================================================

var selected_chapter_id: String = CampaignManager.CHAPTER_01
var chapter_buttons: Dictionary = {}

var detail_code_lbl: Label
var detail_title_lbl: Label
var detail_subtitle_lbl: Label
var detail_synopsis_lbl: Label
var detail_loc_lbl: Label
var detail_reward_lbl: Label
var detail_status_lbl: Label
var play_btn: Button

var modal_overlay: ColorRect
var modal_panel: PanelContainer
var modal_title_lbl: Label
var modal_body_lbl: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	CampaignManager.load_campaign()
	selected_chapter_id = CampaignManager.current_chapter
	if not CampaignManager.is_chapter_unlocked(selected_chapter_id):
		selected_chapter_id = CampaignManager.CHAPTER_01
	_build_ui()
	_update_chapter_details(selected_chapter_id)

func _build_ui() -> void:
	# 1. Fondo de pantalla con viñeta cinematográfica
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	var tex := GameState.load_texture_safe("res://assets/images/backgrounds/select_bg.jpg")
	if not tex:
		tex = GameState.load_texture_safe("res://assets/images/backgrounds/portada.png")
	if tex:
		bg.texture = tex
	add_child(bg)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.04, 0.05, 0.08, 0.78)
	add_child(overlay)

	# 2. Encabezado principal
	var header := VBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_CENTER_TOP)
	header.position = Vector2(-460, 20)
	header.custom_minimum_size = Vector2(920, 60)
	header.add_theme_constant_override("separation", 2)
	add_child(header)

	var title := Label.new()
	title.text = "THE LIFE PROJECT — MODO HISTORIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.25))
	header.add_child(title)

	var sub_title := Label.new()
	sub_title.text = "Campaña de Venganza y Espionaje en la Ciudad Nocturna"
	sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_title.add_theme_font_size_override("font_size", 13)
	sub_title.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
	header.add_child(sub_title)

	# 3. Contenedor Principal (2 Columnas: Acciones de Campaña a la izquierda, Selector de Capítulos a la derecha)
	var main_hbox := HBoxContainer.new()
	main_hbox.set_anchors_preset(Control.PRESET_CENTER)
	main_hbox.position = Vector2(-590, -230)
	main_hbox.custom_minimum_size = Vector2(1180, 480)
	main_hbox.add_theme_constant_override("separation", 28)
	add_child(main_hbox)

	# ==========================================================================
	# COLUMNA IZQUIERDA: ACCIONES GENERALES Y PROGRESO
	# ==========================================================================
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(340, 480)
	var sb_left := StyleBoxFlat.new()
	sb_left.bg_color = Color(0.06, 0.07, 0.10, 0.90)
	sb_left.border_color = Color(0.22, 0.26, 0.35)
	sb_left.set_border_width_all(2)
	sb_left.set_corner_radius_all(8)
	sb_left.content_margin_left = 18
	sb_left.content_margin_right = 18
	sb_left.content_margin_top = 20
	sb_left.content_margin_bottom = 20
	left_panel.add_theme_stylebox_override("panel", sb_left)
	main_hbox.add_child(left_panel)

	var left_vb := VBoxContainer.new()
	left_vb.add_theme_constant_override("separation", 12)
	left_panel.add_child(left_vb)

	var l_actions_title := Label.new()
	l_actions_title.text = "CAMPAMENTO DE OPERACIONES"
	l_actions_title.add_theme_font_size_override("font_size", 16)
	l_actions_title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.25))
	left_vb.add_child(l_actions_title)

	# Ficha rápida del Operativo actual
	var char_data: Dictionary = GameState.CHARACTERS.get(GameState.selected_char, GameState.CHARACTERS["nagumo"])
	var info_box := PanelContainer.new()
	var sb_info := StyleBoxFlat.new()
	sb_info.bg_color = Color(0.09, 0.11, 0.16, 0.85)
	sb_info.border_color = char_data["accent"]
	sb_info.set_border_width_all(1)
	sb_info.set_corner_radius_all(6)
	sb_info.content_margin_left = 12
	sb_info.content_margin_right = 12
	sb_info.content_margin_top = 8
	sb_info.content_margin_bottom = 8
	info_box.add_theme_stylebox_override("panel", sb_info)
	left_vb.add_child(info_box)

	var info_vb := VBoxContainer.new()
	info_box.add_child(info_vb)
	var op_label := Label.new()
	op_label.text = "OPERATIVO: %s" % char_data["name"]
	op_label.add_theme_font_size_override("font_size", 14)
	op_label.add_theme_color_override("font_color", char_data["accent"])
	info_vb.add_child(op_label)

	var prog_label := Label.new()
	prog_label.text = "Progreso Campaña: %d%%  |  Fondos: $%d" % [int(CampaignManager.get_progress_percentage()), GameState.cash]
	prog_label.add_theme_font_size_override("font_size", 12)
	prog_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.92))
	info_vb.add_child(prog_label)

	left_vb.add_child(HSeparator.new())

	# Botones de Acción Principal
	var btn_continue := _make_action_btn("CONTINUAR PARTIDA", Color(0.18, 0.72, 0.40), func():
		AudioManager.play_sfx("click")
		CampaignManager.continue_campaign()
	)
	left_vb.add_child(btn_continue)

	var btn_new_game := _make_action_btn("NUEVA PARTIDA", Color(0.92, 0.22, 0.28), func():
		AudioManager.play_sfx("click")
		get_tree().change_scene_to_file("res://scenes/ui/char_select.tscn")
	)
	left_vb.add_child(btn_new_game)

	var btn_story := _make_action_btn("RESUMEN DE LA HISTORIA", Color(0.24, 0.65, 0.95), func():
		AudioManager.play_sfx("click")
		_show_modal("RESUMEN DE LA HISTORIA", CampaignManager.get_story_summary())
	)
	left_vb.add_child(btn_story)

	var btn_stats := _make_action_btn("PROGRESO DE LA CAMPAÑA", Color(0.95, 0.75, 0.20), func():
		AudioManager.play_sfx("click")
		var stat_txt := """ESTADÍSTICAS DEL MODO HISTORIA

• Operativo Activo: %s
• Capítulos Completados: %d de %d
• Porcentaje de Progreso: %d%%
• Fondos Disponibles: $%d
• Capítulo Actual: %s
• Objetivos: Vengar a la madre de Nagumo y derrocar al Director Kuroshio.""" % [
			char_data["name"],
			CampaignManager.completed_chapters.size(),
			CampaignManager.CHAPTER_ORDER.size(),
			int(CampaignManager.get_progress_percentage()),
			GameState.cash,
			CampaignManager.get_current_chapter_data()["title"]
		]
		_show_modal("DOSSIER DE LA CAMPAÑA", stat_txt)
	)
	left_vb.add_child(btn_stats)

	var btn_char := _make_action_btn("CAMBIAR PERSONAJE", Color(0.70, 0.35, 0.95), func():
		AudioManager.play_sfx("click")
		get_tree().change_scene_to_file("res://scenes/ui/char_select.tscn")
	)
	left_vb.add_child(btn_char)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_child(spacer)

	var btn_back := _make_action_btn("VOLVER AL MENÚ", Color(0.45, 0.48, 0.55), func():
		AudioManager.play_sfx("click")
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	left_vb.add_child(btn_back)

	# ==========================================================================
	# COLUMNA CENTRAL: SELECTOR DE CAPÍTULOS DESBLOQUEADOS
	# ==========================================================================
	var mid_panel := PanelContainer.new()
	mid_panel.custom_minimum_size = Vector2(380, 480)
	var sb_mid := StyleBoxFlat.new()
	sb_mid.bg_color = Color(0.06, 0.07, 0.10, 0.90)
	sb_mid.border_color = Color(0.22, 0.26, 0.35)
	sb_mid.set_border_width_all(2)
	sb_mid.set_corner_radius_all(8)
	sb_mid.content_margin_left = 16
	sb_mid.content_margin_right = 16
	sb_mid.content_margin_top = 16
	sb_mid.content_margin_bottom = 16
	mid_panel.add_theme_stylebox_override("panel", sb_mid)
	main_hbox.add_child(mid_panel)

	var mid_vb := VBoxContainer.new()
	mid_vb.add_theme_constant_override("separation", 10)
	mid_panel.add_child(mid_vb)

	var l_chap_title := Label.new()
	l_chap_title.text = "SELECCIÓN DE CAPÍTULO"
	l_chap_title.add_theme_font_size_override("font_size", 16)
	l_chap_title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.25))
	mid_vb.add_child(l_chap_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mid_vb.add_child(scroll)

	var chap_list_vb := VBoxContainer.new()
	chap_list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chap_list_vb.add_theme_constant_override("separation", 8)
	scroll.add_child(chap_list_vb)

	for ch_id in CampaignManager.CHAPTER_ORDER:
		var cdata: Dictionary = CampaignManager.CHAPTERS_DATA[ch_id]
		var is_unlocked: bool = CampaignManager.is_chapter_unlocked(ch_id)
		var is_completed: bool = CampaignManager.is_chapter_completed(ch_id)

		var c_btn := Button.new()
		c_btn.custom_minimum_size = Vector2(340, 68)
		c_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		c_btn.text = ""

		var btn_vb := VBoxContainer.new()
		btn_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn_vb.position = Vector2(12, 8)
		btn_vb.size = Vector2(316, 52)
		c_btn.add_child(btn_vb)

		var status_str := "✓ COMPLETADO" if is_completed else ("● DISPONIBLE" if is_unlocked else "🔒 BLOQUEADO")
		var status_col := Color(0.28, 0.88, 0.45) if is_completed else (Color(0.96, 0.80, 0.25) if is_unlocked else Color(0.45, 0.48, 0.55))

		var l_head := Label.new()
		l_head.text = "%s  [%s]" % [cdata["code"], status_str]
		l_head.add_theme_font_size_override("font_size", 11)
		l_head.add_theme_color_override("font_color", status_col)
		btn_vb.add_child(l_head)

		var l_btitle := Label.new()
		l_btitle.text = cdata["title"]
		l_btitle.add_theme_font_size_override("font_size", 14)
		l_btitle.add_theme_color_override("font_color", Color.WHITE if is_unlocked else Color(0.55, 0.58, 0.65))
		btn_vb.add_child(l_btitle)

		var l_bsub := Label.new()
		l_bsub.text = cdata["subtitle"]
		l_bsub.add_theme_font_size_override("font_size", 11)
		l_bsub.add_theme_color_override("font_color", Color(0.68, 0.74, 0.85) if is_unlocked else Color(0.40, 0.42, 0.48))
		btn_vb.add_child(l_bsub)

		var btn_sb := StyleBoxFlat.new()
		btn_sb.bg_color = Color(0.08, 0.10, 0.14, 0.88) if is_unlocked else Color(0.05, 0.06, 0.08, 0.88)
		btn_sb.border_color = Color(0.92, 0.22, 0.28) if ch_id == selected_chapter_id else Color(0.18, 0.22, 0.28)
		btn_sb.set_border_width_all(2 if ch_id == selected_chapter_id else 1)
		btn_sb.set_corner_radius_all(6)
		c_btn.add_theme_stylebox_override("normal", btn_sb)

		c_btn.pressed.connect(func():
			AudioManager.play_sfx("click")
			_select_chapter(ch_id)
		)

		chap_list_vb.add_child(c_btn)
		chapter_buttons[ch_id] = c_btn

	# ==========================================================================
	# COLUMNA DERECHA: FICHA DETALLADA Y BOTÓN DESPLEGAR
	# ==========================================================================
	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(400, 480)
	var sb_right := StyleBoxFlat.new()
	sb_right.bg_color = Color(0.06, 0.07, 0.10, 0.90)
	sb_right.border_color = Color(0.22, 0.26, 0.35)
	sb_right.set_border_width_all(2)
	sb_right.set_corner_radius_all(8)
	sb_right.content_margin_left = 20
	sb_right.content_margin_right = 20
	sb_right.content_margin_top = 18
	sb_right.content_margin_bottom = 18
	right_panel.add_theme_stylebox_override("panel", sb_right)
	main_hbox.add_child(right_panel)

	var right_vb := VBoxContainer.new()
	right_vb.add_theme_constant_override("separation", 10)
	right_panel.add_child(right_vb)

	detail_code_lbl = Label.new()
	detail_code_lbl.add_theme_font_size_override("font_size", 13)
	detail_code_lbl.add_theme_color_override("font_color", Color(0.96, 0.80, 0.25))
	right_vb.add_child(detail_code_lbl)

	detail_title_lbl = Label.new()
	detail_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_title_lbl.add_theme_font_size_override("font_size", 20)
	right_vb.add_child(detail_title_lbl)

	detail_subtitle_lbl = Label.new()
	detail_subtitle_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_subtitle_lbl.add_theme_font_size_override("font_size", 13)
	detail_subtitle_lbl.add_theme_color_override("font_color", Color(0.16, 0.88, 0.96))
	right_vb.add_child(detail_subtitle_lbl)

	right_vb.add_child(HSeparator.new())

	detail_loc_lbl = Label.new()
	detail_loc_lbl.add_theme_font_size_override("font_size", 12)
	detail_loc_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.35))
	right_vb.add_child(detail_loc_lbl)

	detail_synopsis_lbl = Label.new()
	detail_synopsis_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_synopsis_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_synopsis_lbl.add_theme_font_size_override("font_size", 13)
	detail_synopsis_lbl.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92))
	right_vb.add_child(detail_synopsis_lbl)

	detail_reward_lbl = Label.new()
	detail_reward_lbl.add_theme_font_size_override("font_size", 12)
	detail_reward_lbl.add_theme_color_override("font_color", Color(0.35, 0.88, 0.45))
	right_vb.add_child(detail_reward_lbl)

	detail_status_lbl = Label.new()
	detail_status_lbl.add_theme_font_size_override("font_size", 13)
	right_vb.add_child(detail_status_lbl)

	play_btn = Button.new()
	play_btn.custom_minimum_size = Vector2(0, 46)
	play_btn.add_theme_font_size_override("font_size", 16)
	play_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		CampaignManager.select_and_play_chapter(selected_chapter_id)
	)
	right_vb.add_child(play_btn)

	# 4. Modal de Resumen y Estadísticas (Inicialmente oculto)
	_build_modal()

func _make_action_btn(txt: String, border_col: Color, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0, 38)
	btn.add_theme_font_size_override("font_size", 13)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.14, 0.9)
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(5)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(0.14, 0.17, 0.24, 0.95)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_h)
	btn.pressed.connect(cb)
	return btn

func _select_chapter(ch_id: String) -> void:
	selected_chapter_id = ch_id
	for id in chapter_buttons.keys():
		var b: Button = chapter_buttons[id]
		var sb := StyleBoxFlat.new()
		var is_unlocked: bool = CampaignManager.is_chapter_unlocked(id)
		sb.bg_color = Color(0.08, 0.10, 0.14, 0.88) if is_unlocked else Color(0.05, 0.06, 0.08, 0.88)
		sb.border_color = Color(0.92, 0.22, 0.28) if id == selected_chapter_id else Color(0.18, 0.22, 0.28)
		sb.set_border_width_all(2 if id == selected_chapter_id else 1)
		sb.set_corner_radius_all(6)
		b.add_theme_stylebox_override("normal", sb)
	_update_chapter_details(ch_id)

func _update_chapter_details(ch_id: String) -> void:
	var cdata: Dictionary = CampaignManager.CHAPTERS_DATA[ch_id]
	var is_unlocked: bool = CampaignManager.is_chapter_unlocked(ch_id)
	var is_completed: bool = CampaignManager.is_chapter_completed(ch_id)

	detail_code_lbl.text = cdata["code"]
	detail_title_lbl.text = cdata["title"]
	detail_subtitle_lbl.text = cdata["subtitle"]
	detail_loc_lbl.text = "📍 Ubicación: " + cdata["location"]
	detail_synopsis_lbl.text = cdata["synopsis"]

	var r_cash: int = cdata.get("reward_cash", 0)
	var r_wpn: String = cdata.get("reward_weapon", "")
	var wpn_txt := (" + " + r_wpn.to_upper()) if r_wpn != "" else ""
	detail_reward_lbl.text = "Recompensa: +$%d%s" % [r_cash, wpn_txt] if r_cash > 0 else "Recompensa: Experiencia e Hito Narrativo"

	if not is_unlocked:
		detail_status_lbl.text = "🔒 CAPÍTULO BLOQUEADO\nCompleta el capítulo anterior para avanzar."
		detail_status_lbl.add_theme_color_override("font_color", Color(0.92, 0.28, 0.32))
		play_btn.text = "BLOQUEADO"
		play_btn.disabled = true
	elif is_completed:
		detail_status_lbl.text = "✓ CAPÍTULO COMPLETADO (Rejugable)"
		detail_status_lbl.add_theme_color_override("font_color", Color(0.28, 0.88, 0.45))
		play_btn.text = "REPETIR CAPÍTULO"
		play_btn.disabled = false
	else:
		detail_status_lbl.text = "● LISTO PARA DESPLEGAR"
		detail_status_lbl.add_theme_color_override("font_color", Color(0.96, 0.80, 0.25))
		play_btn.text = "INICIAR ESTE CAPÍTULO"
		play_btn.disabled = false

func _build_modal() -> void:
	modal_overlay = ColorRect.new()
	modal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_overlay.color = Color(0.03, 0.04, 0.06, 0.88)
	modal_overlay.visible = false
	add_child(modal_overlay)

	modal_panel = PanelContainer.new()
	modal_panel.set_anchors_preset(Control.PRESET_CENTER)
	modal_panel.position = Vector2(-360, -220)
	modal_panel.custom_minimum_size = Vector2(720, 440)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.12, 0.98)
	sb.border_color = Color(0.92, 0.22, 0.28)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	modal_panel.add_theme_stylebox_override("panel", sb)
	modal_overlay.add_child(modal_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	modal_panel.add_child(vb)

	modal_title_lbl = Label.new()
	modal_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title_lbl.add_theme_font_size_override("font_size", 20)
	modal_title_lbl.add_theme_color_override("font_color", Color(0.96, 0.82, 0.25))
	vb.add_child(modal_title_lbl)

	vb.add_child(HSeparator.new())

	modal_body_lbl = Label.new()
	modal_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	modal_body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_body_lbl.add_theme_font_size_override("font_size", 14)
	modal_body_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.96))
	vb.add_child(modal_body_lbl)

	var close_btn := Button.new()
	close_btn.text = "CERRAR"
	close_btn.custom_minimum_size = Vector2(160, 38)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		modal_overlay.visible = false
	)
	vb.add_child(close_btn)

func _show_modal(title_txt: String, body_txt: String) -> void:
	modal_title_lbl.text = title_txt
	modal_body_lbl.text = body_txt
	modal_overlay.visible = true
