extends Node

const CONFIG_PATH := "user://settings.cfg"

var is_muted: bool = false
var master_volume: float = 0.8
var sfx_enabled: bool = true
var music_enabled: bool = true

var shadows_enabled: bool = true
var rain_enabled: bool = true
var screen_shake: bool = true
var pedestrians_enabled: bool = true
var night_mode: bool = true  # true = Ciudad Nocturna, false = Atardecer Dorado GTA
var graphics_quality: String = "high"  # "low", "medium", "high"

var default_keys := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"stealth": KEY_SPACE,
	"interact": KEY_E,
	"shoot": KEY_F,
	"horn": KEY_H,
	"weapon_1": KEY_1,
	"weapon_2": KEY_2,
	"weapon_3": KEY_3,
	"weapon_4": KEY_4,
	"weapon_5": KEY_5,
	"weapon_next": KEY_Q,
	"camera_distance": KEY_V,
}

var current_keys := {}

func _ready() -> void:
	current_keys = default_keys.duplicate()
	load_settings()
	apply_input_map()
	apply_audio_settings()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		is_muted = cfg.get_value("audio", "is_muted", false)
		master_volume = cfg.get_value("audio", "master_volume", 0.8)
		sfx_enabled = cfg.get_value("audio", "sfx_enabled", true)
		music_enabled = cfg.get_value("audio", "music_enabled", true)

		shadows_enabled = cfg.get_value("graphics", "shadows_enabled", true)
		rain_enabled = cfg.get_value("graphics", "rain_enabled", true)
		screen_shake = cfg.get_value("graphics", "screen_shake", true)
		pedestrians_enabled = cfg.get_value("graphics", "pedestrians_enabled", true)
		night_mode = cfg.get_value("graphics", "night_mode", true)
		var gq: String = str(cfg.get_value("graphics", "graphics_quality", "high"))
		graphics_quality = gq if gq in ["low", "medium", "high"] else "high"

		for action in default_keys.keys():
			current_keys[action] = cfg.get_value("controls", action, default_keys[action])

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "is_muted", is_muted)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "sfx_enabled", sfx_enabled)
	cfg.set_value("audio", "music_enabled", music_enabled)

	cfg.set_value("graphics", "shadows_enabled", shadows_enabled)
	cfg.set_value("graphics", "rain_enabled", rain_enabled)
	cfg.set_value("graphics", "screen_shake", screen_shake)
	cfg.set_value("graphics", "pedestrians_enabled", pedestrians_enabled)
	cfg.set_value("graphics", "night_mode", night_mode)
	cfg.set_value("graphics", "graphics_quality", graphics_quality)

	for action in current_keys.keys():
		cfg.set_value("controls", action, current_keys[action])

	cfg.save(CONFIG_PATH)

func apply_audio_settings() -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, is_muted)
		var db: float = linear_to_db(maxf(0.001, master_volume))
		AudioServer.set_bus_volume_db(bus_idx, db)

func apply_input_map() -> void:
	for action in current_keys.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		else:
			InputMap.action_erase_events(action)

		var ev := InputEventKey.new()
		ev.keycode = current_keys[action]
		InputMap.action_add_event(action, ev)

		# Mantener flechas direccionales como respaldo para moverse
		if action == "move_forward":
			_add_backup_key(action, KEY_UP)
		elif action == "move_back":
			_add_backup_key(action, KEY_DOWN)
		elif action == "move_left":
			_add_backup_key(action, KEY_LEFT)
		elif action == "move_right":
			_add_backup_key(action, KEY_RIGHT)

	# Clic izquierdo para disparar y clic derecho para apuntar
	if not InputMap.has_action("fire_mouse"):
		InputMap.add_action("fire_mouse")
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire_mouse", mb)

	if not InputMap.has_action("aim_mouse"):
		InputMap.add_action("aim_mouse")
		var mb_r := InputEventMouseButton.new()
		mb_r.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("aim_mouse", mb_r)

func _add_backup_key(action: String, keycode: int) -> void:
	if current_keys.get(action, 0) != keycode:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		InputMap.action_add_event(action, ev)

func rebind_action(action: String, new_keycode: int) -> void:
	current_keys[action] = new_keycode
	apply_input_map()
	save_settings()

func restore_default_keys() -> void:
	current_keys = default_keys.duplicate()
	apply_input_map()
	save_settings()
