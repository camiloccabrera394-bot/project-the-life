import math
import pygame
from src.entities.base import IsometricEntity

class BuildingDoor(IsometricEntity):
    """Puerta o escalera interactiva para ingresar a edificios o subir a azoteas."""
    def __init__(self, x, y, target_zone="indoor", label="ENTRAR AL TALLER"):
        super().__init__(x, y)
        self.target_zone = target_zone
        self.label = label
        self.glow_timer = 0.0

    def update(self):
        self.glow_timer += 0.06

    def draw(self, surface, camera):
        sx, sy = camera.apply(self.x, self.y)
        pulse = math.sin(self.glow_timer) * 6

        # Marco de puerta de neón cian/magenta
        glow_surf = pygame.Surface((70, 75), pygame.SRCALPHA)
        pygame.draw.rect(glow_surf, (40, 220, 245, int(40 + pulse * 2)), (0, 0, 70, 75), border_radius=4)
        surface.blit(glow_surf, (sx - 35, sy - 65), special_flags=pygame.BLEND_RGBA_ADD)

        door_rect = pygame.Rect(sx - 24, sy - 55, 48, 55)
        pygame.draw.rect(surface, (15, 18, 25), door_rect, border_radius=3)
        pygame.draw.rect(surface, (40, 220, 245), door_rect, width=2, border_radius=3)

        # Rótulo flotante interactivo
        font = pygame.font.SysFont("Arial", 10, bold=True)
        txt = font.render(f"[E] {self.label}", True, (255, 255, 255))
        tx = sx - txt.get_width() // 2
        ty = sy - 78
        badge = pygame.Rect(tx - 6, ty - 2, txt.get_width() + 12, 16)
        pygame.draw.rect(surface, (18, 20, 28, 230), badge, border_radius=3)
        pygame.draw.rect(surface, (245, 205, 50), badge, width=1, border_radius=3)
        surface.blit(txt, (tx, ty))


class PropCover(IsometricEntity):
    def __init__(self, x, y, width=70, height=45, prop_type="dumpster"):
        super().__init__(x, y)
        self.width = width
        self.height = height
        self.prop_type = prop_type

    def draw(self, surface, camera):
        sx, sy = camera.apply(self.x, self.y)

        # Sombra en el suelo
        shadow_surf = pygame.Surface((self.width + 20, int(self.height * 0.5)), pygame.SRCALPHA)
        pygame.draw.ellipse(shadow_surf, (10, 12, 16, 150), (0, 0, self.width + 20, int(self.height * 0.5)))
        surface.blit(shadow_surf, (sx - (self.width + 20) // 2, sy - 5))

        if self.prop_type == "dumpster":
            w, h = self.width, self.height
            rect = pygame.Rect(sx - w // 2, sy - h, w, h)
            pygame.draw.rect(surface, (36, 52, 44), rect, border_radius=3)
            pygame.draw.polygon(surface, (45, 68, 56), [
                (sx - w // 2, sy - h),
                (sx + w // 2, sy - h),
                (sx + w // 2 - 8, sy - h - 12),
                (sx - w // 2 + 8, sy - h - 12)
            ])
            pygame.draw.rect(surface, (25, 38, 30), rect, width=2, border_radius=3)
            pygame.draw.line(surface, (25, 38, 30), (sx - 10, sy - h + 6), (sx - 10, sy - 6), 2)
            pygame.draw.line(surface, (25, 38, 30), (sx + 10, sy - h + 6), (sx + 10, sy - 6), 2)
        elif self.prop_type == "boxes":
            w, h = self.width, self.height
            rect = pygame.Rect(sx - w // 2, sy - h, w, h)
            pygame.draw.rect(surface, (95, 68, 45), rect, border_radius=2)
            pygame.draw.rect(surface, (60, 42, 26), rect, width=2, border_radius=2)
            pygame.draw.line(surface, (60, 42, 26), (rect.left, rect.top), (rect.right, rect.bottom), 2)
            pygame.draw.line(surface, (60, 42, 26), (rect.left, rect.bottom), (rect.right, rect.top), 2)


class GroundItem(IsometricEntity):
    def __init__(self, x, y, item_type="ammo", count=25):
        super().__init__(x, y)
        self.type = item_type
        self.count = count
        self.picked = False
        self.bob_timer = 0.0

    def update(self):
        self.bob_timer += 0.08

    def check_pickup(self, player, interact_pressed=False):
        if self.picked or player.health <= 0:
            return False

        dist = math.hypot(player.x - self.x, player.y - self.y)
        if dist < 45 and (interact_pressed or dist < 24):
            if self.type == "ammo":
                player.ammo += self.count
                self.picked = True
                return "AMMO"
            elif self.type == "medkit":
                if player.health < player.max_health:
                    player.health = min(player.max_health, player.health + 35)
                    self.picked = True
                    return "MEDKIT"
            elif self.type == "weapon":
                player.has_weapon = True
                player.ammo += self.count
                self.picked = True
                return "WEAPON"
        return False

    def draw(self, surface, camera):
        if self.picked:
            return

        sx, sy = camera.apply(self.x, self.y)
        float_y = int(math.sin(self.bob_timer) * 4)

        glow_surf = pygame.Surface((50, 24), pygame.SRCALPHA)
        if self.type == "medkit":
            glow_col = (45, 230, 110, 60)
        elif self.type == "ammo":
            glow_col = (255, 210, 45, 60)
        else:
            glow_col = (40, 220, 245, 60)
        
        pygame.draw.ellipse(glow_surf, glow_col, (0, 0, 50, 24))
        surface.blit(glow_surf, (sx - 25, sy - 12), special_flags=pygame.BLEND_RGBA_ADD)

        shadow_surf = pygame.Surface((24, 10), pygame.SRCALPHA)
        pygame.draw.ellipse(shadow_surf, (10, 12, 16, 120), (0, 0, 24, 10))
        surface.blit(shadow_surf, (sx - 12, sy - 4))

        item_y = sy + float_y - 10

        if self.type == "medkit":
            pygame.draw.rect(surface, (235, 235, 240), (sx - 11, item_y - 7, 22, 15), border_radius=3)
            pygame.draw.rect(surface, (45, 50, 60), (sx - 11, item_y - 7, 22, 15), width=1, border_radius=3)
            pygame.draw.rect(surface, (225, 40, 45), (sx - 2, item_y - 5, 4, 11))
            pygame.draw.rect(surface, (225, 40, 45), (sx - 5, item_y - 2, 10, 4))
        elif self.type == "ammo":
            pygame.draw.rect(surface, (50, 65, 45), (sx - 10, item_y - 8, 20, 14), border_radius=2)
            pygame.draw.rect(surface, (245, 210, 50), (sx - 7, item_y - 5, 14, 4))
            pygame.draw.rect(surface, (30, 40, 28), (sx - 10, item_y - 8, 20, 14), width=1, border_radius=2)
        else:
            pygame.draw.line(surface, (25, 28, 35), (sx - 14, item_y), (sx + 14, item_y), 4)
            pygame.draw.rect(surface, (18, 20, 25), (sx - 3, item_y, 5, 7))
