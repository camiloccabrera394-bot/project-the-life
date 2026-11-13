import pygame
from src.entities.base import IsometricEntity

class Bullet(IsometricEntity):
    def __init__(self, x, y, dx, dy, bullet_type="tactical", damage=35, speed=14, owner="Player"):
        super().__init__(x, y)
        self.dx = dx
        self.dy = dy
        self.type = bullet_type
        self.damage = damage
        self.speed = speed
        self.owner = owner
        self.is_silent = (bullet_type == "silent")
        self.is_enemy = (owner == "Enemy")
        self.alive = True
        self.trail = []
        self.max_distance = 1800
        self.traveled = 0

    def update(self):
        self.trail.append((self.x, self.y))
        if len(self.trail) > 4:
            self.trail.pop(0)

        step_x = self.dx * self.speed
        step_y = self.dy * self.speed * 0.70

        self.x += step_x
        self.y += step_y
        self.traveled += self.speed

        if self.traveled > self.max_distance:
            self.alive = False

    def draw(self, surface, camera):
        if not self.alive:
            return

        sx, sy = camera.apply(self.x, self.y)

        # Colores según tipo
        if self.is_enemy:
            core_col = (255, 60, 60)
            glow_col = (255, 120, 100, 70)
        elif self.is_silent:
            core_col = (110, 235, 255)
            glow_col = (140, 90, 255, 80)
        else:
            core_col = (255, 225, 75)
            glow_col = (255, 160, 40, 80)

        # Estela luminosa
        for idx, (tx, ty) in enumerate(self.trail):
            tsx, tsy = camera.apply(tx, ty)
            alpha = int(90 * ((idx + 1) / len(self.trail)))
            trail_surf = pygame.Surface((8, 8), pygame.SRCALPHA)
            pygame.draw.circle(trail_surf, (*core_col, alpha), (4, 4), 2)
            surface.blit(trail_surf, (tsx - 4, tsy - 4), special_flags=pygame.BLEND_RGBA_ADD)

        # Resplandor frontal
        glow_surf = pygame.Surface((16, 16), pygame.SRCALPHA)
        pygame.draw.circle(glow_surf, glow_col, (8, 8), 7)
        surface.blit(glow_surf, (sx - 8, sy - 8), special_flags=pygame.BLEND_RGBA_ADD)

        # Núcleo brillante
        pygame.draw.circle(surface, core_col, (sx, sy), 3)
        pygame.draw.circle(surface, (255, 255, 255), (sx, sy), 1)
