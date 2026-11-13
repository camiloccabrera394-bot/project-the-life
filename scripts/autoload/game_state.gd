extends Node

var selected_char: String = "nagumo"
var selected_operation: String = "chacal"
var cash: int = 350

var CHARACTERS := {
	"nagumo": {
		"id": "nagumo",
		"name": "NAGUMO",
		"title": "EL EJECUTOR VENGADOR",
		"image_path": "res://assets/images/characters/nagumo.png",
		"health": 120.0,
		"speed": 7.2,
		"stealth_speed": 4.2,
		"accent": Color(0.16, 0.86, 0.96),
		"description": "Ex-operativo militar de élite. Sobrevivió a la trampa de la cena donde asesinaron a su madre. Blindaje alto y maestría con fusiles pesados.",
		"stats": {"Salud": 5, "Ataque": 5, "Velocidad": 3, "Sigilo": 3}
	},
	"shado": {
		"id": "shado",
		"name": "SHADO",
		"title": "LA SOMBRA INFILTRADA",
		"image_path": "res://assets/images/characters/shado.png",
		"health": 95.0,
		"speed": 8.6,
		"stealth_speed": 5.8,
		"accent": Color(0.68, 0.24, 0.94),
		"description": "Especialista en infiltración nocturna. Se mueve rápido entre la lluvia y ejecuta derribos letales silenciosos por la espalda.",
		"stats": {"Salud": 3, "Ataque": 4, "Velocidad": 5, "Sigilo": 5}
	}
}

var OPERATIONS := [
	{
		"id": "chacal",
		"num": 1,
		"code": "OPERACIÓN 01",
		"name": "EL TALLER DE NEÓN",
		"target_name": "RODRIGO 'EL CHACAL'",
		"target_role": "Sicario que apretó el gatillo en la cena",
		"location": "Distrito Este - Taller Clandestino Cyber-Gear",
		"description": "El Chacal asesinó a tu madre durante la emboscada. Se esconde en su taller mecánico clandestino rodeado de guardias armados.",
		"completed": false
	},
	{
		"id": "viper",
		"num": 2,
		"code": "OPERACIÓN 02",
		"name": "EL CLUB SUBTERRÁNEO",
		"target_name": "VALERIA 'VIPER'",
		"target_role": "Proveedora de armas y logística",
		"location": "Distrito Central - Synth-Club 404",
		"description": "Viper entregó el armamento pesado usado contra tu familia. Opera dentro del club nocturno blindado de neón.",
		"completed": false
	},
	{
		"id": "kuroshio",
		"num": 3,
		"code": "OPERACIÓN 03",
		"name": "LA CUMBRE DEL RASCACIELOS",
		"target_name": "DIRECTOR KUROSHIO",
		"target_role": "Líder supremo que ordenó la masacre",
		"location": "Torre Kuroshio - Azotea y Helipuerto",
		"description": "El cerebro detrás de la traición intenta escapar en helicóptero desde el tejado más alto de la metrópolis.",
		"completed": false
	}
]

var WEAPONS_DATA := [
	{"id": "fists",   "slot": 1, "name": "PUÑOS",          "damage": 40.0,  "cooldown": 0.35, "clip": 0,  "reserve": 0,   "auto": false, "explosive": false, "melee": true,  "sound": "takedown"},
	{"id": "pistol",  "slot": 2, "name": "PISTOLA 9MM",    "damage": 34.0,  "cooldown": 0.25, "clip": 12, "reserve": 60,  "auto": false, "explosive": false, "melee": false, "sound": "shoot_silent"},
	{"id": "smg",     "slot": 3, "name": "METRALLETA SMG", "damage": 22.0,  "cooldown": 0.09, "clip": 35, "reserve": 140, "auto": true,  "explosive": false, "melee": false, "sound": "shoot_tactical"},
	{"id": "m4",      "slot": 4, "name": "FUSIL M4",       "damage": 44.0,  "cooldown": 0.14, "clip": 30, "reserve": 90,  "auto": true,  "explosive": false, "melee": false, "sound": "shoot_tactical"},
	{"id": "bazooka", "slot": 5, "name": "BAZUCA RPG",     "damage": 260.0, "cooldown": 0.85, "clip": 1,  "reserve": 8,   "auto": false, "explosive": true,  "melee": false, "sound": "explosion"}
]

func _ready() -> void:
	load_game()

func get_current_operation() -> Dictionary:
	for op in OPERATIONS:
		if op["id"] == selected_operation:
			return op
	return OPERATIONS[0]

func mark_operation_completed(op_id: String) -> void:
	for op in OPERATIONS:
		if op["id"] == op_id:
			op["completed"] = true
	save_game()

const GAME_SAVE_PATH := "user://game_save.cfg"

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "cash", cash)
	cfg.set_value("game", "selected_char", selected_char)
	cfg.set_value("game", "selected_operation", selected_operation)
	var ops_completed: Array = []
	for op in OPERATIONS:
		if bool(op.get("completed", false)):
			ops_completed.append(op["id"])
	cfg.set_value("game", "completed_ops", ops_completed)
	cfg.save(GAME_SAVE_PATH)

	var tw = get_node_or_null("/root/TimeWeatherManager")
	if tw and tw.has_method("save_state"):
		tw.call("save_state")

func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(GAME_SAVE_PATH) == OK:
		cash = cfg.get_value("game", "cash", 350)
		selected_char = cfg.get_value("game", "selected_char", "nagumo")
		selected_operation = cfg.get_value("game", "selected_operation", "chacal")
		var ops_completed: Array = cfg.get_value("game", "completed_ops", [])
		for op in OPERATIONS:
			op["completed"] = op["id"] in ops_completed

	var tw = get_node_or_null("/root/TimeWeatherManager")
	if tw and tw.has_method("load_state"):
		tw.call("load_state")

func load_texture_safe(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var loaded = ResourceLoader.load(res_path)
		if loaded is Texture2D:
			return loaded
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img:
			return ImageTexture.create_from_image(img)
	return null
