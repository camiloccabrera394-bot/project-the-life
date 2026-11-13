import math
import pygame
from src.entities.base import IsometricEntity
from src.config import WIDTH, HEIGHT, COLOR_GOLD, COLOR_NEON_CYAN, COLOR_WHITE, COLOR_TEXT_DIM

class FireEscapeLadder(IsometricEntity):
    """Escalera de incendios exterior interactiva para trepar a las azoteas de los rascacielos."""
    def __init__(self, x, y, destination="rooftop", label="SUBIR A LA AZOTEA"):
        super().__init__(x, y)
        self.destination = destination  # "rooftop" o "street"
        self.label = label
        self.anim_timer = 0.0

    def update(self):
        self.anim_timer += 0.08

    def draw(self, surface, camera):
        sx, sy = camera.apply(self.x, self.y)
        pulse = math.sin(self.anim_timer) * 4

        # Estructura metálica de la escalera de incendios
        lad_w, lad_h = 28, 65
        lad_rect = pygame.Rect(sx - lad_w // 2, sy - lad_h, lad_w, lad_h)

        # Rieles verticales
        pygame.draw.line(surface, (140, 150, 165), (lad_rect.left, lad_rect.top), (lad_rect.left, lad_rect.bottom), 3)
        pygame.draw.line(surface, (140, 150, 165), (lad_rect.right, lad_rect.top), (lad_rect.right, lad_rect.bottom), 3)

        # Peldaños horizontales
        for r_y in range(lad_rect.top + 6, lad_rect.bottom, 10):
            pygame.draw.line(surface, (190, 200, 215), (lad_rect.left, r_y), (lad_rect.right, r_y), 2)

        # Baliza luminosa superior
        pygame.draw.circle(surface, (255, 215, 60), (sx, lad_rect.top - 4), 4)

        # Rótulo interactivo
        font = pygame.font.SysFont("Arial", 10, bold=True)
        txt = font.render(f"[E] {self.label}", True, (255, 255, 255))
        tx = sx - txt.get_width() // 2
        ty = sy - lad_h - 22 + int(pulse)
        badge = pygame.Rect(tx - 6, ty - 2, txt.get_width() + 12, 16)
        pygame.draw.rect(surface, (18, 20, 28, 230), badge, border_radius=3)
        pygame.draw.rect(surface, (245, 210, 50), badge, width=1, border_radius=3)
        surface.blit(txt, (tx, ty))


class RooftopZone:
    """Escenario vertical en lo alto de la azotea del rascacielos."""
    def __init__(self, width=1800, height=1100, name="AZOTEA TORRE CYBER-GEAR"):
        self.width = width
        self.height = height
        self.name = name

        # Cajas de colisión de cornisas, chimeneas y conductos de ventilación
        self.colliders = [
            # Pretiles exteriores para no caer al vacío
            pygame.Rect(0, 0, self.width, 40),
            pygame.Rect(0, self.height - 40, self.width, 40),
            pygame.Rect(0, 0, 40, self.height),
            pygame.Rect(self.width - 40, 0, 40, self.height),
            # Unidades gigantes de aire acondicionado
            pygame.Rect(320, 240, 120, 90),
            pygame.Rect(780, 420, 160, 100),
            pygame.Rect(1240, 260, 140, 90),
            # Base del helipuerto
            pygame.Rect(960, 720, 260, 180)
        ]

        self.fan_angle = 0.0

    def check_collision(self, x, y, radius=14):
        test = pygame.Rect(x - radius, y - radius, radius * 2, radius * 2)
        for c in self.colliders:
            if c.colliderect(test):
                return True
        return False

    def resolve_movement(self, old_x, old_y, new_x, new_y, radius=14):
        if not self.check_collision(new_x, new_y, radius):
            return new_x, new_y
        if not self.check_collision(new_x, old_y, radius):
            return new_x, old_y
        if not self.check_collision(old_x, new_y, radius):
            return old_x, new_y
        return old_x, old_y

    def update(self):
        self.fan_angle += 0.12

    def draw(self, surface, camera):
        # 1. Suelo de grava asfáltica y tela asfáltica oscura
        roof_rect = pygame.Rect(-camera.x, -camera.y, self.width, self.height)
        pygame.draw.rect(surface, (25, 28, 36), roof_rect)

        # Cuadrículas de losas
        for x in range(0, self.width, 100):
            sx, _ = camera.apply(x, 0)
            pygame.draw.line(surface, (35, 40, 52), (sx, -camera.y), (sx, self.height - camera.y), 1)
        for y in range(0, self.height, 100):
            _, sy = camera.apply(0, y)
            pygame.draw.line(surface, (35, 40, 52), (-camera.x, sy), (self.width - camera.x, sy), 1)

        # 2. Círculo del Helipuerto ("H")
        hx, hy = camera.apply(1090, 810)
        pygame.draw.circle(surface, (235, 195, 45), (hx, hy), 70, width=4)
        h_font = pygame.font.SysFont("Impact", 54)
        htxt = h_font.render("H", True, (235, 195, 45))
        surface.blit(htxt, (hx - htxt.get_width() // 2, hy - htxt.get_height() // 2))

        # 3. Muretes y cornisas perimetrales
        for c in self.colliders:
            sc = camera.apply_rect(c)
            if c.width == self.width or c.height == self.height:
                pygame.draw.rect(surface, (45, 52, 65), sc)
                pygame.draw.rect(surface, (20, 24, 30), sc, width=2)
            else:
                # Unidades HVAC de aire acondicionado con ventiladores girando
                pygame.draw.rect(surface, (38, 44, 56), sc, border_radius=4)
                pygame.draw.rect(surface, (20, 24, 30), sc, width=2, border_radius=4)
                # Ventilador giratorio
                fcx, fcy = sc.center
                for ang_off in [0, math.pi / 2, math.pi, math.pi * 1.5]:
                    fx2 = fcx + math.cos(self.fan_angle + ang_off) * 22
                    fy2 = fcy + math.sin(self.fan_angle + ang_off) * 22
                    pygame.draw.line(surface, (180, 190, 205), (fcx, fcy), (int(fx2), int(fy2)), 3)
