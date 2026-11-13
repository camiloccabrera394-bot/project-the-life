extends Control

var cards := {}
var confirm_btn: Button

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()
	_select_char(GameState.selected_char)

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	var tex := GameState.load_texture_safe("res://assets/images/backgrounds/select_bg.jpg")
	if tex:
		bg.texture = tex
	add_child(bg)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.04, 0.05, 0.08, 0.65)
	add_child(overlay)

	var title := Label.new()
	title.text = "SELECCIÓN DE OPERATIVO (1 JUGADOR)"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-300, 26)
	title.custom_minimum_size = Vector2(600, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_CENTER)
	hbox.position = Vector2(-410, -240)
	hbox.custom_minimum_size = Vector2(820, 470)
	hbox.add_theme_constant_override("separation", 40)
	add_child(hbox)

	for cid in ["nagumo", "shado"]:
		var data: Dictionary = GameState.CHARACTERS[cid]
		var card := _make_card(cid, data)
		hbox.add_child(card)
		cards[cid] = card

	confirm_btn = Button.new()
	confirm_btn.text = "CONFIRMAR Y CONTINUAR"
	confirm_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	confirm_btn.position = Vector2(-150, -70)
	confirm_btn.custom_minimum_size = Vector2(300, 44)
	confirm_btn.add_theme_font_size_override("font_size", 18)
	confirm_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		CampaignManager.start_new_campaign(GameState.selected_char)
	)
	add_child(confirm_btn)

	var back_btn := Button.new()
	back_btn.text = "VOLVER AL MODO HISTORIA"
	back_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back_btn.position = Vector2(30, -70)
	back_btn.custom_minimum_size = Vector2(240, 40)
	back_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		get_tree().change_scene_to_file("res://scenes/ui/mission_board.tscn")
	)
	add_child(back_btn)

func _make_card(cid: String, data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(390, 470)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(350, 260)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex := GameState.load_texture_safe(data["image_path"])
	if tex:
		portrait.texture = tex
	vb.add_child(portrait)

	var l_name := Label.new()
	l_name.text = "%s — %s" % [data["name"], data["title"]]
	l_name.add_theme_font_size_override("font_size", 20)
	l_name.add_theme_color_override("font_color", data["accent"])
	vb.add_child(l_name)

	var l_desc := Label.new()
	l_desc.text = data["description"]
	l_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	l_desc.add_theme_font_size_override("font_size", 13)
	vb.add_child(l_desc)

	for st_k in data["stats"].keys():
		var val: int = data["stats"][st_k]
		var st_lbl := Label.new()
		st_lbl.text = "%s: %s" % [st_k, "★".repeat(val) + "☆".repeat(5 - val)]
		st_lbl.add_theme_font_size_override("font_size", 13)
		st_lbl.add_theme_color_override("font_color", Color(0.96, 0.80, 0.22))
		vb.add_child(st_lbl)

	var sel_btn := Button.new()
	sel_btn.text = "ELEGIR A " + data["name"]
	sel_btn.custom_minimum_size = Vector2(0, 36)
	sel_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		_select_char(cid)
	)
	vb.add_child(sel_btn)
	return panel

func _select_char(cid: String) -> void:
	GameState.selected_char = cid
	for k in cards.keys():
		var p: PanelContainer = cards[k]
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.10, 0.14, 0.92)
		sb.border_color = GameState.CHARACTERS[k]["accent"] if k == cid else Color(0.22, 0.25, 0.32)
		sb.set_border_width_all(3 if k == cid else 1)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 12
		sb.content_margin_bottom = 12
		p.add_theme_stylebox_override("panel", sb)
