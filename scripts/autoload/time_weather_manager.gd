extends Node

# ==============================================================================
# THE LIFE PROJECT — TIME & WEATHER MANAGER (SISTEMA DINÁMICO DE TIEMPO Y CLIMA)
# ==============================================================================

# Constantes de Fases del Día
const PHASE_MADRUGADA := "MADRUGADA"
const PHASE_AMANECER := "AMANECER"
const PHASE_MANANA := "MAÑANA"
const PHASE_MEDIODIA := "MEDIODÍA"
const PHASE_TARDE := "TARDE"
const PHASE_ATARDECER := "ATARDECER"
const PHASE_ANOCHECER := "ANOCHECER"
const PHASE_MEDIANOCHE := "MEDIANOCHE"

# Constantes de Clima
const WEATHER_CLEAR := "DESPEJADO"
const WEATHER_SUNNY := "SOLEADO"
const WEATHER_PARTLY_CLOUDY := "PARCIALMENTE NUBLADO"
const WEATHER_CLOUDY := "NUBLADO"
const WEATHER_LIGHT_RAIN := "LLUVIA LIGERA"
const WEATHER_MODERATE_RAIN := "LLUVIA MODERADA"
const WEATHER_THUNDERSTORM := "TORMENTA ELÉCTRICA"
const WEATHER_FOGGY := "NIEBLA"
const WEATHER_STRONG_WIND := "VIENTO FUERTE"

# Constantes de Estaciones
const SEASON_SPRING := "PRIMAVERA"
const SEASON_SUMMER := "VERANO"
const SEASON_AUTUMN := "OTOÑO"
const SEASON_WINTER := "INVIERNO"

const DAYS_OF_WEEK := ["LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"]
const MONTHS := ["ENERO", "FEBRERO", "MARZO", "ABRIL", "MAYO", "JUNIO", "JULIO", "AGOSTO", "SEPTIEMBRE", "OCTUBRE", "NOVIEMBRE", "DICIEMBRE"]

# Señales de tiempo y eventos climáticos
signal minute_ticked(hour: int, minute: int)
signal hour_changed(hour: int)
signal day_changed(day: int, day_of_week: String, season: String)
signal day_phase_changed(new_phase: String)
signal weather_changed(new_weather: String, old_weather: String)
signal lightning_struck(intensity: float)
signal thunder_triggered(delay: float)
signal season_changed(new_season: String)

# Configuración del reloj
var time_speed_multiplier: float = 1.0  # Multiplicador configurable (1.0 = normal)
var day_duration_minutes: float = 24.0   # 24 min reales = 24 horas del juego
var time_seconds: float = 8.0 * 3600.0   # Iniciar por defecto a las 08:00 AM (Mañana brillante)

# Estado del calendario
var hour: int = 8
var minute: int = 0
var day_of_week_idx: int = 0  # 0: Lunes
var day_of_month: int = 15
var month_idx: int = 5        # 5: Junio (Verano)
var year: int = 2026
var current_season: String = SEASON_SUMMER
var current_phase: String = PHASE_MANANA

# Simulación meteorológica
var current_weather: String = WEATHER_SUNNY
var target_weather: String = WEATHER_SUNNY
var weather_transition_timer: float = 0.0
var weather_duration_timer: float = 240.0 # Segundos hasta el próximo cambio de clima
var weather_blend: float = 1.0             # 0.0 a 1.0 (factor de mezcla)

# Parámetros físicos ambientales para el mundo y los shaders
var temperature_celsius: float = 24.0
var night_factor: float = 0.0              # 0.0 (mediodía soleado) a 1.0 (noche oscura)
var wetness: float = 0.0                  # 0.0 (seco) a 1.0 (charcos profundos)
var rain_ripples: float = 0.0             # Ondas concéntricas de lluvia activa
var rain_intensity: float = 0.0           # 0.0 (sin lluvia) a 1.0 (diluvio torrencial)
var wind_vector: Vector2 = Vector2(1.0, 0.2).normalized()
var wind_strength: float = 1.0            # 1.0 normal, hasta 3.5 en vendaval/tormenta
var fog_density_mult: float = 1.0

# Rayos y truenos estocásticos
var lightning_timer: float = 0.0
var lightning_active: bool = false
var lightning_flash_energy: float = 0.0

# Nombres y probabilidades por estación
var _season_weather_probs := {
	SEASON_SPRING: [
		[WEATHER_SUNNY, 0.40],
		[WEATHER_PARTLY_CLOUDY, 0.30],
		[WEATHER_LIGHT_RAIN, 0.20],
		[WEATHER_MODERATE_RAIN, 0.10]
	],
	SEASON_SUMMER: [
		[WEATHER_SUNNY, 0.55],
		[WEATHER_CLEAR, 0.20],
		[WEATHER_PARTLY_CLOUDY, 0.15],
		[WEATHER_THUNDERSTORM, 0.10]
	],
	SEASON_AUTUMN: [
		[WEATHER_CLOUDY, 0.35],
		[WEATHER_MODERATE_RAIN, 0.25],
		[WEATHER_STRONG_WIND, 0.20],
		[WEATHER_FOGGY, 0.15],
		[WEATHER_LIGHT_RAIN, 0.05]
	],
	SEASON_WINTER: [
		[WEATHER_CLOUDY, 0.40],
		[WEATHER_FOGGY, 0.30],
		[WEATHER_LIGHT_RAIN, 0.20],
		[WEATHER_STRONG_WIND, 0.10]
	]
}

func _ready() -> void:
	load_state()
	_update_calendar_from_seconds()
	_update_season()
	_update_temperature()
	_calculate_environmental_factors(0.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		save_state()


func _process(delta: float) -> void:
	# 1. Avance del reloj interno
	# 86400 segundos de juego en (day_duration_minutes * 60) segundos reales
	var game_sec_per_real_sec: float = 86400.0 / (day_duration_minutes * 60.0) * time_speed_multiplier
	var prev_minute := minute
	var prev_hour := hour
	var prev_phase := current_phase

	time_seconds += delta * game_sec_per_real_sec
	if time_seconds >= 86400.0:
		time_seconds -= 86400.0
		_advance_day()

	_update_calendar_from_seconds()

	if minute != prev_minute:
		minute_ticked.emit(hour, minute)

	if hour != prev_hour:
		hour_changed.emit(hour)
		_update_temperature()

	var new_phase := _calculate_day_phase()
	if new_phase != prev_phase:
		current_phase = new_phase
		day_phase_changed.emit(current_phase)

	# 2. Avance de la simulación meteorológica
	_process_weather_simulation(delta)

	# 3. Cálculo de factores ambientales para shaders, iluminación y niebla
	_calculate_environmental_factors(delta)

	# 4. Procesamiento de tormenta y rayos si corresponde
	_process_thunderstorm(delta)

func _update_calendar_from_seconds() -> void:
	var total_mins := int(time_seconds / 60.0)
	hour = (total_mins / 60) % 24
	minute = total_mins % 60

func _advance_day() -> void:
	day_of_week_idx = (day_of_week_idx + 1) % 7
	day_of_month += 1
	if day_of_month > 30:
		day_of_month = 1
		month_idx = (month_idx + 1) % 12
		if month_idx == 0:
			year += 1
		_update_season()

	day_changed.emit(day_of_month, DAYS_OF_WEEK[day_of_week_idx], current_season)

func _update_season() -> void:
	var prev_season := current_season
	# Meses 2,3,4 (Marzo, Abril, Mayo) = Primavera
	# Meses 5,6,7 (Junio, Julio, Agosto) = Verano
	# Meses 8,9,10 (Septiembre, Octubre, Noviembre) = Otoño
	# Meses 11,0,1 (Diciembre, Enero, Febrero) = Invierno
	if month_idx in [2, 3, 4]:
		current_season = SEASON_SPRING
	elif month_idx in [5, 6, 7]:
		current_season = SEASON_SUMMER
	elif month_idx in [8, 9, 10]:
		current_season = SEASON_AUTUMN
	else:
		current_season = SEASON_WINTER

	if current_season != prev_season:
		season_changed.emit(current_season)

func _update_temperature() -> void:
	var base_temp: float = 24.0
	match current_season:
		SEASON_SPRING: base_temp = 18.0
		SEASON_SUMMER: base_temp = 29.0
		SEASON_AUTUMN: base_temp = 13.0
		SEASON_WINTER: base_temp = 4.0

	# Variación según la hora del día (más frío a las 05:00, más cálido a las 14:00)
	var h_float: float = float(hour) + float(minute) / 60.0
	var daily_curve: float = sin((h_float - 9.0) / 24.0 * TAU)
	temperature_celsius = base_temp + daily_curve * 5.5

	# El clima afecta la temperatura
	if current_weather in [WEATHER_LIGHT_RAIN, WEATHER_MODERATE_RAIN]:
		temperature_celsius -= 3.0
	elif current_weather == WEATHER_THUNDERSTORM:
		temperature_celsius -= 5.5
	elif current_weather == WEATHER_FOGGY:
		temperature_celsius -= 2.0

func _calculate_day_phase() -> String:
	var h := float(hour) + float(minute) / 60.0
	if h >= 0.0 and h < 5.0:
		return PHASE_MADRUGADA
	elif h >= 5.0 and h < 7.0:
		return PHASE_AMANECER
	elif h >= 7.0 and h < 11.5:
		return PHASE_MANANA
	elif h >= 11.5 and h < 14.0:
		return PHASE_MEDIODIA
	elif h >= 14.0 and h < 17.5:
		return PHASE_TARDE
	elif h >= 17.5 and h < 19.5:
		return PHASE_ATARDECER
	elif h >= 19.5 and h < 21.5:
		return PHASE_ANOCHECER
	else:
		return PHASE_MEDIANOCHE

func _process_weather_simulation(delta: float) -> void:
	weather_duration_timer -= delta
	if weather_duration_timer <= 0.0:
		# Elegir nuevo clima objetivo según la estación actual
		_pick_next_weather()

	# Interpolar gradualmente entre climas
	if weather_blend < 1.0:
		weather_blend = minf(1.0, weather_blend + delta * 0.04) # Transición suave en ~25 segundos
		if weather_blend >= 1.0:
			var old := current_weather
			current_weather = target_weather
			weather_changed.emit(current_weather, old)

func _pick_next_weather() -> void:
	var probs: Array = _season_weather_probs.get(current_season, _season_weather_probs[SEASON_SUMMER])
	var r := randf()
	var accum := 0.0
	var chosen: String = WEATHER_SUNNY
	for item in probs:
		accum += item[1]
		if r <= accum:
			chosen = item[0]
			break

	target_weather = chosen
	weather_blend = 0.0
	# Duración del nuevo clima: entre 3 y 7 minutos reales
	weather_duration_timer = randf_range(180.0, 420.0)

func _calculate_environmental_factors(delta: float) -> void:
	var h := float(hour) + float(minute) / 60.0

	# 1. night_factor: 0.0 pleno día, 1.0 plena noche
	if h >= 7.5 and h <= 17.5:
		night_factor = 0.0
	elif h > 17.5 and h < 20.0:
		night_factor = (h - 17.5) / 2.5
	elif h >= 20.0 or h < 5.0:
		night_factor = 1.0
	elif h >= 5.0 and h < 7.5:
		night_factor = 1.0 - (h - 5.0) / 2.5

	# 2. Lluvia y humedad del asfalto (wetness)
	var is_raining: bool = (current_weather in [WEATHER_LIGHT_RAIN, WEATHER_MODERATE_RAIN, WEATHER_THUNDERSTORM])
	var target_wetness: float = 0.0
	var target_rain_intensity: float = 0.0
	var target_ripples: float = 0.0

	if current_weather == WEATHER_LIGHT_RAIN:
		target_wetness = 0.45
		target_rain_intensity = 0.35
		target_ripples = 0.40
	elif current_weather == WEATHER_MODERATE_RAIN:
		target_wetness = 0.85
		target_rain_intensity = 0.70
		target_ripples = 0.85
	elif current_weather == WEATHER_THUNDERSTORM:
		target_wetness = 1.0
		target_rain_intensity = 1.0
		target_ripples = 1.0

	if delta > 0.0:
		if is_raining:
			wetness = lerpf(wetness, target_wetness, delta * 0.08)
			rain_intensity = lerpf(rain_intensity, target_rain_intensity, delta * 0.12)
			rain_ripples = lerpf(rain_ripples, target_ripples, delta * 0.15)
		else:
			# Secado progresivo: las ondas desaparecen rápido, los charcos se evaporan gradualmente
			rain_intensity = lerpf(rain_intensity, 0.0, delta * 0.25)
			rain_ripples = lerpf(rain_ripples, 0.0, delta * 0.50)
			wetness = lerpf(wetness, 0.0, delta * 0.012) # Secado suave en unos 80 segundos

	# 3. Viento
	var target_wind: float = 1.0
	if current_weather == WEATHER_STRONG_WIND:
		target_wind = 3.2
	elif current_weather == WEATHER_THUNDERSTORM:
		target_wind = 2.6
	elif current_weather == WEATHER_MODERATE_RAIN:
		target_wind = 1.5

	if delta > 0.0:
		wind_strength = lerpf(wind_strength, target_wind, delta * 0.08)

	# 4. Niebla
	if current_weather == WEATHER_FOGGY:
		fog_density_mult = 3.5
	elif current_weather == WEATHER_THUNDERSTORM:
		fog_density_mult = 1.8
	elif is_raining:
		fog_density_mult = 1.3
	else:
		fog_density_mult = 1.0

	# 5. Actualizar audio ambiental reactivo
	if AudioManager:
		AudioManager.update_ambient_weather(rain_intensity, wind_strength)

func _process_thunderstorm(delta: float) -> void:
	if current_weather != WEATHER_THUNDERSTORM:
		lightning_active = false
		lightning_flash_energy = 0.0
		return

	if lightning_active:
		lightning_flash_energy = maxf(0.0, lightning_flash_energy - delta * 35.0)
		if lightning_flash_energy <= 0.0:
			lightning_active = false

	lightning_timer -= delta
	if lightning_timer <= 0.0:
		# Próximo relámpago entre 7 y 18 segundos
		lightning_timer = randf_range(7.0, 18.0)
		_trigger_lightning()

func _trigger_lightning() -> void:
	lightning_active = true
	lightning_flash_energy = randf_range(8.0, 14.0)
	lightning_struck.emit(lightning_flash_energy)

	# Trueno con retraso físico según la distancia acústica (0.6s a 2.4s)
	var thunder_delay := randf_range(0.6, 2.4)
	thunder_triggered.emit(thunder_delay)

	get_tree().create_timer(thunder_delay).timeout.connect(func():
		AudioManager.play_sfx("thunder", -2.0)
	)


# ==============================================================================
# MÉTODOS PÚBLICOS DE CONSULTA Y CONFIGURACIÓN
# ==============================================================================

func get_formatted_time() -> String:
	return "%02d:%02d" % [hour, minute]

func get_day_of_week_name() -> String:
	return DAYS_OF_WEEK[day_of_week_idx]

func get_formatted_date() -> String:
	return "%s %d DE %s" % [DAYS_OF_WEEK[day_of_week_idx], day_of_month, MONTHS[month_idx]]

func get_day_phase_name() -> String:
	return current_phase

func get_weather_name() -> String:
	return current_weather

func get_season_name() -> String:
	return current_season

func get_temperature_string() -> String:
	return "%d°C" % int(roundf(temperature_celsius))

func get_weather_icon() -> String:
	match current_weather:
		WEATHER_SUNNY: return "☀️"
		WEATHER_CLEAR: return "🌙" if night_factor > 0.5 else "☀️"
		WEATHER_PARTLY_CLOUDY: return "⛅"
		WEATHER_CLOUDY: return "☁️"
		WEATHER_LIGHT_RAIN: return "🌦️"
		WEATHER_MODERATE_RAIN: return "🌧️"
		WEATHER_THUNDERSTORM: return "⛈️"
		WEATHER_FOGGY: return "🌫️"
		WEATHER_STRONG_WIND: return "💨"
		_: return "☀️"

func set_time(new_hour: int, new_minute: int = 0) -> void:
	hour = clamp(new_hour, 0, 23)
	minute = clamp(new_minute, 0, 59)
	time_seconds = float(hour * 3600 + minute * 60)
	_update_temperature()
	_calculate_environmental_factors(0.0)
	minute_ticked.emit(hour, minute)

func force_weather(weather_name: String) -> void:
	target_weather = weather_name
	current_weather = weather_name
	weather_blend = 1.0
	weather_duration_timer = 600.0
	weather_changed.emit(current_weather, current_weather)
	_update_temperature()
	_calculate_environmental_factors(1.0)

func set_day_duration_minutes(mins: float) -> void:
	day_duration_minutes = clampf(mins, 6.0, 96.0)

const SAVE_PATH := "user://time_weather.cfg"

func save_state() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("time", "time_seconds", time_seconds)
	cfg.set_value("time", "day_of_month", day_of_month)
	cfg.set_value("time", "day_of_week_idx", day_of_week_idx)
	cfg.set_value("time", "month_idx", month_idx)
	cfg.set_value("time", "year", year)
	cfg.set_value("time", "day_duration_minutes", day_duration_minutes)
	cfg.set_value("weather", "current_weather", current_weather)
	cfg.save(SAVE_PATH)

func load_state() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		time_seconds = cfg.get_value("time", "time_seconds", 8.0 * 3600.0)
		day_of_month = cfg.get_value("time", "day_of_month", 15)
		day_of_week_idx = cfg.get_value("time", "day_of_week_idx", 0)
		month_idx = cfg.get_value("time", "month_idx", 5)
		year = cfg.get_value("time", "year", 2026)
		day_duration_minutes = cfg.get_value("time", "day_duration_minutes", 24.0)
		current_weather = cfg.get_value("weather", "current_weather", WEATHER_SUNNY)
		target_weather = current_weather
		_update_calendar_from_seconds()
		_update_season()
		_update_temperature()
		_calculate_environmental_factors(0.0)
