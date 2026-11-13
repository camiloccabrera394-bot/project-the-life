extends Control

# ==============================================================================
# THE LIFE PROJECT — PRÓLOGO CINEMÁTICO: LA ÚLTIMA NOCHE
# ==============================================================================

var slide_idx: int = 0
var title_lbl: Label
var speaker_lbl: Label
var body_lbl: Label
var btn_next: Button

var slides: Array = []

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_generate_character_slides()
	_build_ui()
	_show_slide()

func _generate_character_slides() -> void:
	var is_nagumo := (GameState.selected_char == "nagumo")

	if is_nagumo:
		slides = [
			{
				"title": "PRÓLOGO: LA RENUNCIA",
				"speaker": "NAGUMO",
				"text": "Durante años serví al Sindicato Kuroshio como su ejecutor más temido.\nCansado de la sangre y de las guerras corporativas en la sombra, decidí pactar mi retiro definitivo para cuidar de mi madre y empezar una vida en paz."
			},
			{
				"title": "LA CENA DE DESPEDIDA",
				"speaker": "MEMORIA DE LA NOCHE",
				"text": "El Director Kuroshio y sus lugartenientes fingieron aceptar mi renuncia.\nPara sellar el acuerdo en buenos términos, nos convocaron a una cena familiar privada en el reservado de la mansión. Confiando en su código de honor, acudí desarmado con mi madre."
			},
			{
				"title": "LA EMBOSCADA Y LA MASACRE",
				"speaker": "TRAICIÓN",
				"text": "Todo era una trampa para eliminar a testigos incómodos.\nRodrigo 'El Chacal' y un escuadrón de sicarios irrumpieron acribillando la sala con fusiles pesados. Mi madre cayó asesinada frente a mis ojos mientras intenté protegerla con mi propio cuerpo."
			},
			{
				"title": "DESPERTAR BAJO LA LLUVIA",
				"speaker": "JURAMENTO DE RETRIBUCIÓN",
				"text": "Me dieron por muerto y arrojaron mi cuerpo en los callejones bajo la lluvia helada.\nSobreviví. No descansaré hasta que cada miembro de la lista negra de Kuroshio pague con su vida."
			}
		]
	else:
		slides = [
			{
				"title": "PRÓLOGO: LA RED ENVENENADA",
				"speaker": "SHADO",
				"text": "Operé en las sombras de Kuroshio como su agente de contrainteligencia más letal.\nAl interceptar archivos confidenciales de purga interna, descubrí que la cúpula directiva preparaba la liquidación de sus propios activos de confianza."
			},
			{
				"title": "LA TRAMPA DE LA CENA",
				"speaker": "INFILTRACIÓN TARDÍA",
				"text": "Intenté interceptar la cena de despedida convocada para Nagumo y su familia.\nLlegué demasiado tarde: el estruendo de los disparos retumbaba en el salón. La madre de Nagumo ya había sido abatida por 'El Chacal' y sus esbirros."
			},
			{
				"title": "EXTRACCIÓN BAJO FUEGO",
				"speaker": "SUPERVIVENCIA",
				"text": "Cubrí la retirada y logré arrastrar a Nagumo malherido entre los disparos de la guardia.\nLa lluvia torrencial borró nuestras huellas mientras la metrópoli creía que los dos estábamos muertos."
			},
			{
				"title": "EL CONTRAATAQUE",
				"speaker": "ALIANZA EN LA OSCURIDAD",
				"text": "Ocultos en los distritos bajos, iniciamos la ofensiva.\nKuroshio cree que controla la ciudad, pero desmantelaremos sus finanzas, sus armas y sus cabecillas desde las mismas sombras."
			}
		]

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.07)
	add_child(bg)

	# Imagen de fondo si existe
	var bg_tex := TextureRect.new()
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
	var t := GameState.load_texture_safe("res://assets/images/backgrounds/portada.png")
	if t:
		bg_tex.texture = t
		bg_tex.modulate = Color(0.35, 0.35, 0.45, 0.45)
	add_child(bg_tex)

	# Panel Central Narrativo
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-460, -170)
	panel.custom_minimum_size = Vector2(920, 340)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.11, 0.96)
	sb.border_color = Color(0.92, 0.18, 0.24)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	panel.add_child(vb)

	title_lbl = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.82, 0.25))
	vb.add_child(title_lbl)

	speaker_lbl = Label.new()
	speaker_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speaker_lbl.add_theme_font_size_override("font_size", 13)
	speaker_lbl.add_theme_color_override("font_color", Color(0.92, 0.22, 0.28))
	vb.add_child(speaker_lbl)

	vb.add_child(HSeparator.new())

	body_lbl = Label.new()
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_lbl.add_theme_font_size_override("font_size", 16)
	body_lbl.add_theme_color_override("font_color", Color(0.90, 0.94, 0.98))
	vb.add_child(body_lbl)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 24)
	vb.add_child(hbox)

	btn_next = Button.new()
	btn_next.text = "CONTINUAR"
	btn_next.custom_minimum_size = Vector2(240, 44)
	btn_next.add_theme_font_size_override("font_size", 16)
	btn_next.pressed.connect(_next_slide)
	hbox.add_child(btn_next)

	var btn_skip := Button.new()
	btn_skip.text = "OMITIR INTRODUCCIÓN"
	btn_skip.custom_minimum_size = Vector2(180, 44)
	btn_skip.add_theme_font_size_override("font_size", 14)
	btn_skip.pressed.connect(_finish_prologue)
	hbox.add_child(btn_skip)

func _show_slide() -> void:
	var s: Dictionary = slides[slide_idx]
	title_lbl.text = s["title"]
	speaker_lbl.text = "— %s —" % s["speaker"]
	body_lbl.text = s["text"]

	if slide_idx == slides.size() - 1:
		btn_next.text = "COMENZAR CAPÍTULO 1 ➔"
	else:
		btn_next.text = "CONTINUAR"

func _next_slide() -> void:
	AudioManager.play_sfx("click")
	slide_idx += 1
	if slide_idx >= slides.size():
		_finish_prologue()
	else:
		_show_slide()

func _finish_prologue() -> void:
	AudioManager.play_sfx("click")
	CampaignManager.complete_chapter(CampaignManager.CHAPTER_PROLOGUE)
	# Desplegar inmediatamente en el Capítulo 1 dentro del mundo de la ciudad
	CampaignManager.select_and_play_chapter(CampaignManager.CHAPTER_01)
