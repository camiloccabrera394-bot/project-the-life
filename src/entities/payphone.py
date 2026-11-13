import math
import pygame
from src.core.audio import SoundManager

class Payphone3D:
    """Cabina telefónica pública en 3D ubicada bajo el puente de las vías elevadas del tren."""
    def __init__(self, wx=2500, wz=2320):
        self.wx = float(wx)
        self.wy = 0.0
        self.wz = float(wz)
        self.is_ringing = True
        self.answered = False
        self.dialogue_active = False
        self.ring_timer = 0
        self.dialogue_step = 0

        self.dialogue_lines = [
            "Informante: Al habla... Sé lo que pasó en la cena y la muerte de tu madre.",
            "Informante: El Director Kuroshio dio la orden directa para borrarlos del mapa.",
            "Informante: Rodrigo 'El Chacal' fue quien disparó. Está escondido en el taller Cyber-Gear.",
            "Informante: Sigue la baliza en tu radar GPS hasta el Bulevar Este. Acaba con él."
        ]

    def update(self):
        if self.is_ringing and not self.answered:
            self.ring_timer += 1
            if self.ring_timer % 65 == 0:
                SoundManager.get().play_sfx("alert")

    def answer_call(self):
        if not self.answered:
            self.answered = True
            self.is_ringing = False
            self.dialogue_active = True
            self.dialogue_step = 0
            SoundManager.get().play_sfx("click")
            return True
        return False

    def advance_dialogue(self):
        if self.dialogue_active:
            SoundManager.get().play_sfx("click")
            self.dialogue_step += 1
            if self.dialogue_step >= len(self.dialogue_lines):
                self.dialogue_active = False
                return "CALL_FINISHED"
        return "IN_PROGRESS"

    def get_current_subtitle(self):
        if self.dialogue_active and self.dialogue_step < len(self.dialogue_lines):
            return self.dialogue_lines[self.dialogue_step]
        return None

    def draw(self, surface, camera, player):
        proj = camera.project(self.wx, self.wy, self.wz)
        if not proj:
            return
        px, py, scale = proj
        if scale < 0.12:
            return

        s = min(10.0, scale * 2.8)
        bw = max(8, int(22 * s))
        bh = max(16, int(52 * s))

        # Sombra
        pygame.draw.ellipse(surface, (8, 10, 14), (px - bw, py - int(4*s), bw * 2, max(2, int(8*s))))

        # Cabina de vidrio con luz neón azul y techo
        booth_rect = pygame.Rect(px - bw // 2, py - bh, bw, bh)
        pygame.draw.rect(surface, (20, 32, 48), booth_rect, border_radius=2)
        pygame.draw.rect(surface, (40, 225, 245), booth_rect, width=max(1, int(1.5*s)), border_radius=2)
        # Teléfono amarillo en el interior
        pygame.draw.rect(surface, (245, 200, 45), (px - int(4*s), py - int(36*s), max(3, int(8*s)), max(5, int(12*s))))

        # Ondas de timbre y aviso
        if self.is_ringing and not self.answered:
            pulse = abs(math.sin(pygame.time.get_ticks() * 0.008))
            rad = max(6, min(140, int((20 + pulse * 25) * s)))
            ring_surf = pygame.Surface((rad * 2, rad * 2), pygame.SRCALPHA)
            pygame.draw.circle(ring_surf, (245, 215, 50, int(180 * (1 - pulse))), (rad, rad), rad, width=2)
            surface.blit(ring_surf, (px - rad, py - bh // 2 - rad))

            if math.hypot(player.wx - self.wx, player.wz - self.wz) < 120:
                font = pygame.font.SysFont("Arial", 11, bold=True)
                txt = font.render("[E] CONTESTAR TELÉFONO", True, (255, 255, 255))
                badge = pygame.Rect(px - txt.get_width() // 2 - 6, py - bh - 24, txt.get_width() + 12, 18)
                pygame.draw.rect(surface, (15, 18, 24, 230), badge, border_radius=3)
                pygame.draw.rect(surface, (245, 205, 50), badge, width=1, border_radius=3)
                surface.blit(txt, (badge.x + 6, badge.y + 2))
