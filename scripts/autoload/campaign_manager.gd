extends Node

# ==============================================================================
# THE LIFE PROJECT — CAMPAIGN & NARRATIVE MANAGER (MODO HISTORIA)
# ==============================================================================

const CHAPTER_PROLOGUE := "prologue"
const CHAPTER_01 := "ch_01"
const CHAPTER_02 := "ch_02"
const CHAPTER_03 := "ch_03"
const CHAPTER_04 := "ch_04"

const CHAPTER_ORDER := [
	CHAPTER_PROLOGUE,
	CHAPTER_01,
	CHAPTER_02,
	CHAPTER_03,
	CHAPTER_04
]

const CHAPTERS_DATA := {
	"prologue": {
		"id": "prologue",
		"num": 0,
		"code": "PRÓLOGO",
		"title": "LA ÚLTIMA NOCHE",
		"subtitle": "La emboscada en la cena familiar",
		"synopsis": "Nagumo y Shado deciden abandonar la organización Kuroshio. Los jefes convocan una cena de despedida; sin embargo, se trataba de una trampa letal donde sicarios asesinaron a la madre de Nagumo y dejaron a los protagonistas por muertos bajo la lluvia.",
		"location": "Mansión Kuroshio",
		"scene_path": "res://scenes/ui/prologue.tscn",
		"reward_cash": 0,
		"reward_weapon": ""
	},
	"ch_01": {
		"id": "ch_01",
		"num": 1,
		"code": "CAPÍTULO 1",
		"title": "UNA LLAMADA EN LA OSCURIDAD",
		"subtitle": "Cipher y el Maletín del Hotel Kuroshio",
		"synopsis": "Despiertas bajo las vías del tren mientras un teléfono público suena en la noche lluviosa. Un informante anónimo que se hace llamar 'Cipher' revela que un equipo de limpieza de Kuroshio está destruyendo evidencias en el Hotel Kuroshio. Deberás llegar al hotel, neutralizar a los sicarios y recuperar el maletín de pruebas.",
		"location": "Avenida Central & Hotel Kuroshio",
		"scene_path": "res://scenes/world/city_world.tscn",
		"reward_cash": 750,
		"reward_weapon": "m4"
	},
	"ch_02": {
		"id": "ch_02",
		"num": 2,
		"code": "CAPÍTULO 2",
		"title": "SOMBRAS DEL PASADO",
		"subtitle": "El Taller Clandestino de Rodrigo 'El Chacal'",
		"synopsis": "Los documentos del maletín confirman que Rodrigo 'El Chacal' fue quien disparó en la cena. Se encuentra atrincherado en el taller mecánico clandestino Cyber-Gear, protegido por guardias en azoteas y perímetro electrificado.",
		"location": "Distrito Este - Taller Cyber-Gear",
		"scene_path": "res://scenes/world/city_world.tscn",
		"reward_cash": 1200,
		"reward_weapon": "smg"
	},
	"ch_03": {
		"id": "ch_03",
		"num": 3,
		"code": "CAPÍTULO 3",
		"title": "LA LISTA NEGRA",
		"subtitle": "Infiltración en el Synth-Club 404",
		"synopsis": "El registro confiscado a El Chacal revela la red de sobornos de Valeria 'Viper', la principal proveedora de armamento pesado del sindicato. Opera desde la zona VIP blindada del club nocturno ciberpunk Synth-Club 404.",
		"location": "Distrito Central - Synth-Club 404",
		"scene_path": "res://scenes/world/city_world.tscn",
		"reward_cash": 2000,
		"reward_weapon": "bazooka"
	},
	"ch_04": {
		"id": "ch_04",
		"num": 4,
		"code": "CAPÍTULO 4",
		"title": "VENGANZA FINAL",
		"subtitle": "La Cumbre de la Torre Kuroshio",
		"synopsis": "El cerebro de toda la conspiración, el Director Kuroshio, prepara su evacuación aérea en helicóptero desde la azotea más alta de la metrópoli. Asalta el rascacielos y pon fin a la organización de una vez por todas.",
		"location": "Distrito Financiero - Torre Kuroshio",
		"scene_path": "res://scenes/world/city_world.tscn",
		"reward_cash": 5000,
		"reward_weapon": ""
	}
}

# Señales de campaña para oyentes
signal chapter_unlocked(chapter_id: String)
signal chapter_completed(chapter_id: String, rewards: Dictionary)
signal objective_updated(text: String, waypoint: Vector2)

# Variables de estado de campaña persistentes
var current_chapter: String = CHAPTER_01
var unlocked_chapters: Array = [CHAPTER_PROLOGUE, CHAPTER_01]
var completed_chapters: Array = []
var campaign_flags: Dictionary = {}

const CAMPAIGN_SAVE_PATH := "user://campaign_save.cfg"

func _ready() -> void:
	load_campaign()

# ==============================================================================
# GESTIÓN DE FLUJO DE CAMPAÑA
# ==============================================================================

func start_new_campaign(char_id: String = "nagumo") -> void:
	GameState.selected_char = char_id
	GameState.cash = 350
	current_chapter = CHAPTER_PROLOGUE
	unlocked_chapters = [CHAPTER_PROLOGUE, CHAPTER_01]
	completed_chapters = []
	campaign_flags = {
		"briefcase_recovered": false,
		"cipher_first_call_done": false,
		"chacal_defeated": false,
		"viper_defeated": false,
		"kuroshio_defeated": false
	}
	save_campaign()
	get_tree().change_scene_to_file("res://scenes/ui/prologue.tscn")

func continue_campaign() -> void:
	load_campaign()
	var chap_data: Dictionary = CHAPTERS_DATA.get(current_chapter, CHAPTERS_DATA[CHAPTER_01])
	var target_scene: String = str(chap_data.get("scene_path", "res://scenes/world/city_world.tscn"))
	get_tree().change_scene_to_file(target_scene)

func select_and_play_chapter(chapter_id: String) -> bool:
	if not is_chapter_unlocked(chapter_id):
		return false
	current_chapter = chapter_id
	save_campaign()
	var chap_data: Dictionary = CHAPTERS_DATA.get(chapter_id, CHAPTERS_DATA[CHAPTER_01])
	var target_scene: String = str(chap_data.get("scene_path", "res://scenes/world/city_world.tscn"))
	get_tree().change_scene_to_file(target_scene)
	return true

func complete_chapter(chapter_id: String) -> Dictionary:
	if not (chapter_id in completed_chapters):
		completed_chapters.append(chapter_id)

	var chap_data: Dictionary = CHAPTERS_DATA.get(chapter_id, {})
	var r_cash: int = int(chap_data.get("reward_cash", 0))
	var r_weapon: String = str(chap_data.get("reward_weapon", ""))

	if r_cash > 0:
		GameState.cash += r_cash

	# Desbloquear el siguiente capítulo de la lista
	var next_chapter_id: String = ""
	var cur_idx: int = CHAPTER_ORDER.find(chapter_id)
	if cur_idx != -1 and cur_idx + 1 < CHAPTER_ORDER.size():
		next_chapter_id = CHAPTER_ORDER[cur_idx + 1]
		if not (next_chapter_id in unlocked_chapters):
			unlocked_chapters.append(next_chapter_id)
			chapter_unlocked.emit(next_chapter_id)
		current_chapter = next_chapter_id

	save_campaign()

	var rewards: Dictionary = {
		"cash": r_cash,
		"weapon": r_weapon,
		"next_chapter": next_chapter_id
	}
	chapter_completed.emit(chapter_id, rewards)
	return rewards

# ==============================================================================
# CONSULTAS Y ESTADÍSTICAS
# ==============================================================================

func is_chapter_unlocked(chapter_id: String) -> bool:
	return chapter_id in unlocked_chapters

func is_chapter_completed(chapter_id: String) -> bool:
	return chapter_id in completed_chapters

func get_progress_percentage() -> float:
	var total_story: int = CHAPTER_ORDER.size()
	if total_story == 0:
		return 0.0
	var done_count: int = completed_chapters.size()
	return clampf(float(done_count) / float(total_story) * 100.0, 0.0, 100.0)

func get_current_chapter_data() -> Dictionary:
	return CHAPTERS_DATA.get(current_chapter, CHAPTERS_DATA[CHAPTER_01])

func get_story_summary() -> String:
	return """HISTORIA DE 'THE LIFE PROJECT'

Nagumo y Shado eran los activos más letales del Sindicato Kuroshio, una corporación criminal que domina la metrópoli bajo el manto de la noche.

Tras años de servicio sangriento, deciden dar un paso al costado para buscar redención. Los líderes de la organización simularon aceptar su retiro y los invitaron a una cena de despedida.

Fue una emboscada despiadada.

Sicarios fuertemente armados asesinaron a la madre de Nagumo y dejaron a los protagonistas malheridos bajo la lluvia torrencial.

Ahora, guiados por un misterioso informante conocido como 'Cipher' a través de cabinas telefónicas secretas, Nagumo y Shado emprenden una cruzada de justicia y venganza para derribar a cada uno de los cabecillas de Kuroshio."""

# ==============================================================================
# PERSISTENCIA DEL MODO HISTORIA
# ==============================================================================

func save_campaign() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("campaign", "current_chapter", current_chapter)
	cfg.set_value("campaign", "unlocked_chapters", unlocked_chapters)
	cfg.set_value("campaign", "completed_chapters", completed_chapters)
	cfg.set_value("campaign", "selected_char", GameState.selected_char)
	cfg.set_value("campaign", "cash", GameState.cash)

	for k in campaign_flags.keys():
		cfg.set_value("flags", k, campaign_flags[k])

	cfg.save(CAMPAIGN_SAVE_PATH)

	# Sincronizar también con el estado global y del tiempo
	if Engine.has_singleton("GameState") or is_instance_valid(GameState):
		GameState.save_game()

func load_campaign() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CAMPAIGN_SAVE_PATH) == OK:
		current_chapter = str(cfg.get_value("campaign", "current_chapter", CHAPTER_01))
		var unl = cfg.get_value("campaign", "unlocked_chapters", [CHAPTER_PROLOGUE, CHAPTER_01])
		if unl is Array:
			unlocked_chapters = unl
		var cmp = cfg.get_value("campaign", "completed_chapters", [])
		if cmp is Array:
			completed_chapters = cmp

		if cfg.has_section("flags"):
			for k in cfg.get_section_keys("flags"):
				campaign_flags[k] = cfg.get_value("flags", k)

		var saved_char: String = str(cfg.get_value("campaign", "selected_char", "nagumo"))
		if saved_char != "":
			GameState.selected_char = saved_char
		GameState.cash = int(cfg.get_value("campaign", "cash", 350))
