import math
import array
import random
import pygame
from src.config import SettingsManager

class SoundManager:
    _instance = None

    def __init__(self):
        self.mixer_available = False
        self.sounds = {}
        self.settings = SettingsManager.get()
        self._init_mixer()

    @classmethod
    def get(cls):
        if cls._instance is None:
            cls._instance = SoundManager()
        return cls._instance

    def _init_mixer(self):
        try:
            if not pygame.mixer.get_init():
                pygame.mixer.init(frequency=22050, size=-16, channels=2, buffer=512)
            self.mixer_available = True
            self._generate_procedural_sounds()
        except Exception:
            self.mixer_available = False

    def _generate_procedural_sounds(self):
        """Genera efectos de sonido sintéticos nativos sin dependencias externas (solo stdlib + pygame)."""
        if not self.mixer_available:
            return

        sample_rate = 22050

        def make_sound(duration, fn):
            n = int(sample_rate * duration)
            buf = array.array('h')
            for i in range(n):
                t = i / sample_rate
                val = int(max(-32767, min(32767, fn(t) * 32767)))
                buf.append(val)
                buf.append(val)
            return pygame.mixer.Sound(buffer=buf)

        try:
            # 1. Disparo Táctico (M4)
            self.sounds["shoot_tactical"] = make_sound(0.18, lambda t: random.uniform(-1, 1) * math.exp(-t * 28) * 0.8)
            # 2. Disparo Silenciado
            self.sounds["shoot_silent"] = make_sound(0.12, lambda t: (math.sin(2 * math.pi * 180 * t) * 0.4 + random.uniform(-0.5, 0.5) * 0.6) * math.exp(-t * 38) * 0.5)
            # 3. Impacto de Bala / Chispas
            self.sounds["hit"] = make_sound(0.08, lambda t: random.uniform(-1, 1) * math.exp(-t * 45) * 0.6)
            # 4. Alerta Enemiga / Timbre
            self.sounds["alert"] = make_sound(0.16, lambda t: math.sin(2 * math.pi * (400 + t * 2800) * t) * math.exp(-t * 10) * 0.4)
            # 5. Clic de Interfaz
            self.sounds["click"] = make_sound(0.04, lambda t: math.sin(2 * math.pi * 1200 * t) * math.exp(-t * 80) * 0.25)
            # 6. Derribo / Explosión
            self.sounds["takedown"] = make_sound(0.25, lambda t: (math.sin(2 * math.pi * 75 * t) * 0.6 + random.uniform(-0.5, 0.5) * 0.4) * math.exp(-t * 14) * 0.85)
            # 7. Motor de Auto
            self.sounds["engine"] = make_sound(0.28, lambda t: (math.sin(2 * math.pi * 65 * t) + 0.3 * random.uniform(-1, 1)) * 0.3)
        except Exception:
            pass

    def play_sfx(self, name):
        if not self.mixer_available:
            return

        data = self.settings.data
        if data.get("is_muted", False) or not data.get("sfx_enabled", True):
            return

        master_vol = float(data.get("master_volume", 0.8))
        sfx_vol = float(data.get("sfx_volume", 0.8))
        effective_vol = max(0.0, min(1.0, master_vol * sfx_vol))

        snd = self.sounds.get(name)
        if snd:
            try:
                snd.set_volume(effective_vol)
                snd.play()
            except Exception:
                pass
