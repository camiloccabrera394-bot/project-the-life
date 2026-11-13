import os
import json
import copy
import shutil
import pygame

# --- RESOLUCIÓN Y TÍTULO ---
WIDTH, HEIGHT = 1024, 576
FPS = 60
TITLE = "THE LIFE PROJECT - Venganza en la Ciudad Nocturna"

# --- RUTAS DE DIRECTORIOS ---
SRC_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(SRC_DIR)
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
IMAGES_DIR = os.path.join(ASSETS_DIR, "images")
BG_DIR = os.path.join(IMAGES_DIR, "backgrounds")
CHAR_DIR = os.path.join(IMAGES_DIR, "characters")
UI_DIR = os.path.join(IMAGES_DIR, "ui")
SETTINGS_FILE = os.path.join(BASE_DIR, "settings.json")

# Directorio de artefactos generados (antigravity brain)
ARTIFACT_DIR = r"C:\Users\Juan Camilo\.gemini\antigravity\brain\5e77e8e2-5a94-41f5-bf0d-7fad77f8e352"

# --- PALETA DE COLORES CIBERPUNK / NOIR ---
COLOR_DARK_BG = (12, 14, 20)
COLOR_WHITE = (245, 245, 245)
COLOR_TEXT_DIM = (160, 170, 185)
COLOR_TEXT_MUTED = (95, 105, 120)

COLOR_NEON_RED = (235, 40, 55)
COLOR_NEON_CYAN = (40, 220, 245)
COLOR_NEON_PURPLE = (175, 60, 240)
COLOR_GOLD = (245, 205, 50)
COLOR_HEALTH_GREEN = (45, 215, 95)
COLOR_HEALTH_RED = (220, 45, 45)
COLOR_STAMINA_BLUE = (45, 135, 245)

COLOR_HUD_BG = (18, 20, 28)
COLOR_HUD_BORDER = (45, 52, 68)

# --- GESTOR DE CONFIGURACIONES PERSISTENTES (settings.json) ---
DEFAULT_SETTINGS = {
    "master_volume": 0.8,
    "sfx_volume": 0.8,
    "music_volume": 0.6,
    "is_muted": False,
    "sfx_enabled": True,
    "music_enabled": True,
    "screen_shake": True,
    "rain_density": "high",   # "high", "medium", "off"
    "pedestrians_enabled": True,
    "control_scheme": "hybrid",  # "hybrid" (teclado + ratón) o "keyboard_only"
    "keys": {
        "up": "W",
        "down": "S",
        "left": "A",
        "right": "D",
        "shoot": "F",
        "stealth": "SPACE",
        "interact": "E",
        "vehicle": "E"
    }
}

KEY_NAME_TO_CODE = {
    "W": pygame.K_w, "S": pygame.K_s, "A": pygame.K_a, "D": pygame.K_d,
    "UP": pygame.K_UP, "DOWN": pygame.K_DOWN, "LEFT": pygame.K_LEFT, "RIGHT": pygame.K_RIGHT,
    "SPACE": pygame.K_SPACE, "LSHIFT": pygame.K_LSHIFT, "RSHIFT": pygame.K_RSHIFT,
    "E": pygame.K_e, "F": pygame.K_f, "R": pygame.K_r, "Q": pygame.K_q, "C": pygame.K_c,
    "RETURN": pygame.K_RETURN, "ESCAPE": pygame.K_ESCAPE, "TAB": pygame.K_TAB
}
KEY_CODE_TO_NAME = {v: k for k, v in KEY_NAME_TO_CODE.items()}

class SettingsManager:
    _instance = None

    def __init__(self):
        self.data = copy.deepcopy(DEFAULT_SETTINGS)
        self.load()

    @classmethod
    def get(cls):
        if cls._instance is None:
            cls._instance = SettingsManager()
        return cls._instance

    def load(self):
        if os.path.exists(SETTINGS_FILE):
            try:
                with open(SETTINGS_FILE, "r", encoding="utf-8") as f:
                    saved = json.load(f)
                    if "keys" in saved and isinstance(saved["keys"], dict):
                        self.data["keys"].update(saved.pop("keys"))
                    self.data.update(saved)
            except Exception:
                pass

    def save(self):
        try:
            with open(SETTINGS_FILE, "w", encoding="utf-8") as f:
                json.dump(self.data, f, indent=4)
        except Exception:
            pass

    def get_key_code(self, action_name):
        key_str = self.data.get("keys", {}).get(action_name, "SPACE")
        code = KEY_NAME_TO_CODE.get(key_str)
        if code is None:
            try:
                code = pygame.key.key_code(key_str.lower())
                KEY_NAME_TO_CODE[key_str] = code
            except Exception:
                code = pygame.K_SPACE
        return code

    def set_key(self, action_name, key_code):
        name = KEY_CODE_TO_NAME.get(key_code)
        if not name:
            name = pygame.key.name(key_code).upper()
            KEY_NAME_TO_CODE[name] = key_code
            KEY_CODE_TO_NAME[key_code] = name
        self.data.setdefault("keys", {})[action_name] = name
        self.save()

# --- AUTO-ORGANIZADOR DE ASSETS ---
def ensure_directories_and_migrate():
    """Crea la estructura de carpetas y organiza los archivos existentes."""
    for folder in [BG_DIR, CHAR_DIR, UI_DIR]:
        os.makedirs(folder, exist_ok=True)

    file_moves = {
        "portada.png": os.path.join(BG_DIR, "portada.png"),
        "callejon_bg.jpeg": os.path.join(BG_DIR, "legacy_callejon.jpeg"),
        "nagumo.png": os.path.join(CHAR_DIR, "nagumo.png"),
        "shado.png": os.path.join(CHAR_DIR, "shado.png"),
    }
    for filename, dest_path in file_moves.items():
        src_path = os.path.join(BASE_DIR, filename)
        if os.path.exists(src_path) and not os.path.exists(dest_path):
            try:
                shutil.copy2(src_path, dest_path)
            except Exception:
                pass

    # Copiar fondos generados del brain si existen
    gen_files = [
        ("night_city_street_1794356188932.jpg", "night_city.jpg"),
        ("character_select_bg_1794356219858.jpg", "select_bg.jpg"),
        ("neon_car_district_1794358269003.jpg", "neon_district.jpg"),
        ("chop_shop_interior_1794358309930.jpg", "chop_shop.jpg")
    ]
    for src_name, dest_name in gen_files:
        src_p = os.path.join(ARTIFACT_DIR, src_name)
        dest_p = os.path.join(BG_DIR, dest_name)
        if os.path.exists(src_p) and not os.path.exists(dest_p):
            try:
                shutil.copy2(src_p, dest_p)
            except Exception:
                pass

ensure_directories_and_migrate()

def get_asset_path(category, filename):
    folder = BG_DIR if category == "bg" else (CHAR_DIR if category == "char" else UI_DIR)
    path = os.path.join(folder, filename)
    if os.path.exists(path):
        return path
    
    base, _ = os.path.splitext(filename)
    for ext in ['.jpg', '.png', '.jpeg']:
        p = os.path.join(folder, base + ext)
        if os.path.exists(p):
            return p

    for ext in ['', '.jpg', '.png', '.jpeg']:
        p = os.path.join(BASE_DIR, base + ext)
        if os.path.exists(p):
            return p

    if os.path.exists(ARTIFACT_DIR):
        for candidate in os.listdir(ARTIFACT_DIR):
            if base in candidate:
                return os.path.join(ARTIFACT_DIR, candidate)

    return None

# --- FUENTES DEL SISTEMA ---
_fonts = {}
def get_font(name="main", size=18, bold=False):
    key = (name, size, bold)
    if key not in _fonts:
        if name == "title":
            _fonts[key] = pygame.font.SysFont("Impact", size)
        elif name == "hud":
            _fonts[key] = pygame.font.SysFont("Arial", size, bold=bold)
        elif name == "mono":
            _fonts[key] = pygame.font.SysFont("Consolas", size, bold=bold)
        else:
            _fonts[key] = pygame.font.SysFont("Impact", size)
    return _fonts[key]

# --- DATOS DE LOS PERSONAJES ---
CHARACTERS = {
    "nagumo": {
        "id": "nagumo",
        "name": "NAGUMO",
        "title": "EL EJECUTOR VENGADOR",
        "image_file": "nagumo.png",
        "health": 120,
        "speed": 3.4,
        "stealth_speed": 2.2,
        "weapon_name": "Fusil de Asalto Táctico M4",
        "bullet_type": "tactical",
        "bullet_damage": 40,
        "bullet_speed": 15,
        "shoot_cooldown": 11,
        "start_ammo": 45,
        "accent_color": COLOR_NEON_CYAN,
        "description": "Ex-miembro de élite de la organización. Sobrevivió a la emboscada donde mataron a su madre. Ahora busca retribución total con armamento pesado.",
        "stats": {
            "Salud": 5,
            "Ataque": 5,
            "Velocidad": 3,
            "Sigilo": 3
        }
    },
    "shado": {
        "id": "shado",
        "name": "SHADO",
        "title": "LA SOMBRA INFILTRADA",
        "image_file": "shado.png",
        "health": 95,
        "speed": 4.1,
        "stealth_speed": 2.9,
        "weapon_name": "Pistola Silenciada & Dagas",
        "bullet_type": "silent",
        "bullet_damage": 34,
        "bullet_speed": 17,
        "shoot_cooldown": 10,
        "start_ammo": 35,
        "accent_color": COLOR_NEON_PURPLE,
        "description": "Especialista en sigilo que rompió sus lazos con la organización. Su agilidad le permite acechar entre la lluvia y realizar derribos sin ser visto.",
        "stats": {
            "Salud": 3,
            "Ataque": 4,
            "Velocidad": 5,
            "Sigilo": 5
        }
    }
}

# --- OPERACIONES DE LA CAMPAÑA DE VENGANZA ---
OPERATIONS = [
    {
        "id": "chacal",
        "num": 1,
        "code": "OPERACIÓN 01",
        "name": "EL TALLER DE NEÓN",
        "target_name": "RODRIGO 'EL CHACAL'",
        "target_role": "Sicario líder del tiroteo en la cena",
        "location": "Distrito Automotriz - Cyber-Gear Repair & Taller Clandestino",
        "description": "El Chacal fue quien apretó el gatillo contra tu madre. Se esconde en un taller mecánico clandestino de autos deportivos blindados.",
        "intel": "Cuenta con una guardia de 6 mercenarios armados y un auto de escape preparado.",
        "bg_outdoor": "neon_district.jpg",
        "bg_indoor": "chop_shop.jpg",
        "completed": False
    },
    {
        "id": "viper",
        "num": 2,
        "code": "OPERACIÓN 02",
        "name": "EL BÚNKER SUBTERRÁNEO",
        "target_name": "VALERIA 'VIPER'",
        "target_role": "Proveedora de armas y logística de la emboscada",
        "location": "Club Nocturno Clandestino & Almacén Kuroshio",
        "description": "Viper suministró las armas que usaron en el atentado. Opera en el sótano blindado de un club de neón.",
        "intel": "La zona está custodiada por guardias con linternas de alta potencia. El sigilo es clave.",
        "bg_outdoor": "night_city.jpg",
        "bg_indoor": "chop_shop.jpg",
        "completed": False
    },
    {
        "id": "kuroshio",
        "num": 3,
        "code": "OPERACIÓN 03",
        "name": "LA CUMBRE DEL RASCACIELOS",
        "target_name": "DIRECTOR KUROSHIO",
        "target_role": "Líder supremo que ordenó la trampa de la cena",
        "location": "Ático y Helipuerto Torre Central Kuroshio",
        "description": "El autor intelectual de la traición intenta escapar en helicóptero privado hacia el extranjero.",
        "intel": "Defensa máxima de élite. Debes subir por las escaleras y azoteas bajo la tormenta.",
        "bg_outdoor": "select_bg.jpg",
        "bg_indoor": "night_city.jpg",
        "completed": False
    }
]
