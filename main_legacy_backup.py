# Copia de seguridad del main.py original monolítico
# Para jugar a la nueva versión modular y mejorada, ejecuta el nuevo main.py
import pygame
import math
import sys
import os
import random

# Inicialización
pygame.init()
WIDTH, HEIGHT = 1024, 576
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("THE LIFE PROJECT - Callejón Isométrico (Versión Legacy)")
clock = pygame.time.Clock()

font_menu = pygame.font.SysFont("Impact", 22)
hud_font = pygame.font.SysFont("Arial", 11, bold=True)
hud_title = pygame.font.SysFont("Impact", 15)
wave_font = pygame.font.SysFont("Impact", 24)

COLOR_NEON_RED = (230, 35, 45)
COLOR_TEXT_DIM = (160, 170, 185)
COLOR_WHITE = (245, 245, 245)
COLOR_HEALTH_RED = (220, 45, 45)
COLOR_STAMINA_BLUE = (45, 130, 240)
COLOR_HUD_BG = (20, 22, 28)
COLOR_HUD_BORDER = (45, 52, 65)

def find_file(base_name):
    for ext in ['.png', '.jpg', '.jpeg']:
        path = f"{base_name}{ext}"
        if os.path.exists(path):
            return path
    return None

portada_path = find_file("portada")
bg_menu = None
if portada_path:
    raw = pygame.image.load(portada_path).convert()
    bg_menu = pygame.transform.smoothscale(raw, (WIDTH, HEIGHT))

callejon_path = find_file("callejon_bg")
bg_callejon = None
if callejon_path:
    raw_callejon = pygame.image.load(callejon_path).convert()
    bg_callejon = pygame.transform.smoothscale(raw_callejon, (WIDTH, HEIGHT))

def load_hud_portrait(image_path, size=(46, 46)):
    surf = pygame.Surface(size, pygame.SRCALPHA)
    if image_path and os.path.exists(image_path):
        raw = pygame.image.load(image_path).convert_alpha()
        w, h = raw.get_size()
        crop_size = int(w * 0.45)
        crop_x = (w - crop_size) // 2
        crop_y = int(h * 0.015)
        sub = raw.subsurface(pygame.Rect(crop_x, crop_y, crop_size, crop_size))
        scaled = pygame.transform.smoothscale(sub, size)
        surf.blit(scaled, (0, 0))
    else:
        pygame.draw.rect(surf, (80, 80, 90), (0, 0, *size))
    return surf

hud_nagumo_img = load_hud_portrait(find_file("nagumo"))
hud_shado_img = load_hud_portrait(find_file("shado"))

raindrops = [[random.randint(0, WIDTH), random.randint(0, HEIGHT), random.randint(12, 20)] for _ in range(130)]

def draw_isometric_rain(surface):
    rain_surf = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
    for drop in raindrops:
        drop[0] += 3
        drop[1] += drop[2]
        if drop[1] > HEIGHT:
            drop[1] = random.randint(-30, -5)
            drop[0] = random.randint(-50, WIDTH)
        pygame.draw.line(rain_surf, (140, 175, 210, 85), (drop[0], drop[1]), (drop[0] + 3, drop[1] + drop[2] * 0.7), 1)
    surface.blit(rain_surf, (0, 0))

def draw_flashlight(surface, origin_x, origin_y, angle, length=190, spread=0.45):
    light_surf = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
    p1 = (origin_x, origin_y)
    p2 = (origin_x + length * math.cos(angle - spread) * 1.1, origin_y + length * math.sin(angle - spread) * 0.65)
    p3 = (origin_x + length * math.cos(angle + spread) * 1.1, origin_y + length * math.sin(angle + spread) * 0.65)
    pygame.draw.polygon(light_surf, (255, 245, 170, 38), [p1, p2, p3])
    end_cx = (p2[0] + p3[0]) // 2
    end_cy = (p2[1] + p3[1]) // 2
    pygame.draw.ellipse(light_surf, (255, 250, 190, 48), (end_cx - 40, end_cy - 18, 80, 36))
    surface.blit(light_surf, (0, 0), special_flags=pygame.BLEND_RGBA_ADD)

class Bullet:
    def __init__(self, x, y, dx, dy, bullet_type="tactical", owner="Nagumo"):
        self.x = x
        self.y = y
        self.dx = dx
        self.dy = dy
        self.type = bullet_type
        self.owner = owner
        self.speed = 13
        self.damage = 50 if bullet_type == "tactical" else 40
        self.is_silent = (bullet_type == "silent")

    def update(self):
        self.x += self.dx * self.speed
        self.y += self.dy * self.speed * 0.75

    def draw(self, surface):
        col = (90, 225, 255) if self.is_silent else (255, 215, 60)
        pygame.draw.circle(surface, col, (int(self.x), int(self.y)), 3)
        pygame.draw.circle(surface, (255, 255, 255), (int(self.x), int(self.y)), 1)

class IsometricEntity:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    @property
    def depth(self):
        return self.y

class Player(IsometricEntity):
    def __init__(self, x, y, name, controls, bullet_type, is_nagumo=True):
        super().__init__(x, y)
        self.name = name
        self.controls = controls
        self.bullet_type = bullet_type
        self.is_nagumo = is_nagumo
        self.speed = 3.2
        self.health = 100
        self.stamina = 100
        self.is_crouched = False
        self.has_weapon = False
        self.ammo = 0
        self.shoot_cooldown = 0
        self.facing = (1, 0.4)

    def update(self, keys, covers):
        if self.shoot_cooldown > 0:
            self.shoot_cooldown -= 1
        dx, dy = 0, 0
        if keys[self.controls['up']]:    dy -= 1
        if keys[self.controls['down']]:  dy += 1
        if keys[self.controls['left']]:  dx -= 1
        if keys[self.controls['right']]: dx += 1

        if dx != 0 or dy != 0:
            mag = math.hypot(dx, dy)
            self.facing = (dx / mag, (dy / mag) * 0.6)
            self.x += (dx / mag) * self.speed
            self.y += (dy / mag) * self.speed * 0.65

        self.x = max(110, min(WIDTH - 120, self.x))
        self.y = max(240, min(HEIGHT - 50, self.y))
        stealth_key = keys[self.controls['stealth']]
        in_cover = any(math.hypot(c.x - self.x, c.y - self.y) < 65 for c in covers)
        self.is_crouched = stealth_key and in_cover

    def shoot(self, bullets_list, enemies_list):
        if not self.has_weapon or self.ammo <= 0 or self.shoot_cooldown > 0 or self.health <= 0:
            return
        self.shoot_cooldown = 14
        self.ammo -= 1
        spawn_x = self.x + self.facing[0] * 24
        spawn_y = self.y - 18 + self.facing[1] * 24
        b = Bullet(spawn_x, spawn_y, self.facing[0], self.facing[1], self.bullet_type, self.name)
        bullets_list.append(b)
        if not b.is_silent:
            for enemy in enemies_list:
                if math.hypot(enemy.x - self.x, enemy.y - self.y) < 420:
                    enemy.state = "INVESTIGATE"
                    enemy.target_pos = (self.x, self.y)

    def draw(self, surface):
        if self.health <= 0:
            return
        px, py = int(self.x), int(self.y)
        shadow_surf = pygame.Surface((36, 16), pygame.SRCALPHA)
        pygame.draw.ellipse(shadow_surf, (10, 12, 16, 140), (0, 0, 36, 16))
        surface.blit(shadow_surf, (px - 18, py - 6))
        body_y = py - 32 if not self.is_crouched else py - 20
        coat_col = (20, 24, 30) if self.is_nagumo else (28, 26, 36)
        pygame.draw.rect(surface, coat_col, (px - 8, body_y + 10, 16, 20), border_radius=2)
        pygame.draw.circle(surface, (235, 195, 170), (px, body_y + 4), 6)
        pygame.draw.circle(surface, (20, 20, 24), (px, body_y + 2), 6)
        if self.is_nagumo:
            pygame.draw.rect(surface, (10, 10, 10), (px - 1, body_y + 3, 5, 2))
            gun_end = (px + int(self.facing[0] * 18), body_y + 14 + int(self.facing[1] * 12))
            pygame.draw.line(surface, (15, 15, 18), (px + 2, body_y + 12), gun_end, 3)
        else:
            pygame.draw.line(surface, (160, 50, 220), (px - 3, body_y + 9), (px + 3, body_y + 9), 2)

class Enemy(IsometricEntity):
    def __init__(self, x, y, enemy_type="bat"):
        super().__init__(x, y)
        self.enemy_type = enemy_type
        self.health = 100
        self.speed = 1.9
        self.detection_radius = 210
        self.state = "PATROL"
        self.patrol_dir = 1
        self.patrol_limit = (max(180, x - 120), min(WIDTH - 160, x + 120))
        self.target_pos = None
        self.attack_cooldown = 0
        self.facing_angle = 0

    def update(self, players):
        if self.attack_cooldown > 0:
            self.attack_cooldown -= 1
        target = None
        min_dist = float('inf')
        active = [p for p in players if not p.is_crouched and p.health > 0]
        for p in active:
            dist = math.hypot(p.x - self.x, p.y - self.y)
            if dist < self.detection_radius and dist < min_dist:
                min_dist = dist
                target = p
        if target:
            self.state = "CHASE"
            angle = math.atan2(target.y - self.y, target.x - self.x)
            self.facing_angle = angle
            self.x += math.cos(angle) * self.speed
            self.y += math.sin(angle) * self.speed * 0.65
            if math.hypot(target.x - self.x, target.y - self.y) < 28 and self.attack_cooldown == 0:
                target.health = max(0, target.health - 15)
                self.attack_cooldown = 45
        elif self.state == "INVESTIGATE" and self.target_pos:
            angle = math.atan2(self.target_pos[1] - self.y, self.target_pos[0] - self.x)
            self.facing_angle = angle
            self.x += math.cos(angle) * self.speed
            self.y += math.sin(angle) * self.speed * 0.65
            if math.hypot(self.target_pos[0] - self.x, self.target_pos[1] - self.y) < 18:
                self.state = "PATROL"
                self.target_pos = None
        else:
            self.state = "PATROL"
            self.facing_angle = 0 if self.patrol_dir == 1 else math.pi
            self.x += self.patrol_dir * 1.4
            if self.x > self.patrol_limit[1] or self.x < self.patrol_limit[0]:
                self.patrol_dir *= -1

    def draw(self, surface):
        ex, ey = int(self.x), int(self.y)
        if self.enemy_type == "flashlight" or self.state == "CHASE":
            draw_flashlight(surface, ex, ey - 14, self.facing_angle)
        shadow_surf = pygame.Surface((32, 14), pygame.SRCALPHA)
        pygame.draw.ellipse(shadow_surf, (10, 12, 16, 140), (0, 0, 32, 14))
        surface.blit(shadow_surf, (ex - 16, ey - 5))
        jacket_col = (115, 65, 45) if self.enemy_type == "bat" else (50, 60, 75)
        if self.state == "CHASE":
            jacket_col = (175, 40, 40)
        pygame.draw.rect(surface, (30, 35, 45), (ex - 7, ey - 15, 14, 15))
        pygame.draw.rect(surface, jacket_col, (ex - 8, ey - 28, 16, 15), border_radius=2)
        pygame.draw.circle(surface, (225, 185, 155), (ex, ey - 32), 6)
        if self.enemy_type == "bat":
            pygame.draw.line(surface, (180, 140, 80), (ex + 6, ey - 20), (ex + 15, ey - 32), 3)
        hp_bg = pygame.Rect(ex - 16, ey - 44, 32, 4)
        hp_fill = pygame.Rect(ex - 16, ey - 44, int(32 * (self.health / 100)), 4)
        pygame.draw.rect(surface, (35, 35, 40), hp_bg)
        pygame.draw.rect(surface, (45, 215, 80), hp_fill)

class PropCover(IsometricEntity):
    def __init__(self, x, y, width, height, prop_type="dumpster"):
        super().__init__(x, y)
        self.width = width
        self.height = height
        self.prop_type = prop_type

    def draw(self, surface):
        px, py = int(self.x), int(self.y)
        if bg_callejon is None:
            if self.prop_type == "dumpster":
                pygame.draw.rect(surface, (38, 70, 52), (px - 45, py - 45, 90, 45), border_radius=4)
                pygame.draw.rect(surface, (25, 45, 35), (px - 45, py - 45, 90, 45), width=2, border_radius=4)
            else:
                pygame.draw.rect(surface, (95, 68, 45), (px - 35, py - 40, 70, 40), border_radius=3)
                pygame.draw.rect(surface, (60, 40, 25), (px - 35, py - 40, 70, 40), width=2, border_radius=3)

class GroundItem(IsometricEntity):
    def __init__(self, x, y, item_type="weapon", count=25):
        super().__init__(x, y)
        self.type = item_type
        self.count = count
        self.picked = False

    def check_pickup(self, player, key_pressed):
        if not self.picked and math.hypot(player.x - self.x, player.y - self.y) < 38 and key_pressed:
            if self.type == "weapon":
                self.picked = True
                player.has_weapon = True
                player.ammo += self.count
            elif self.type == "medkit":
                if player.health < 100:
                    self.picked = True
                    player.health = min(100, player.health + 40)

    def draw(self, surface):
        if self.picked:
            return
        ix, iy = int(self.x), int(self.y)
        glow_surf = pygame.Surface((44, 22), pygame.SRCALPHA)
        color = (40, 215, 240, 55) if self.type == "weapon" else (60, 255, 120, 55)
        pygame.draw.ellipse(glow_surf, color, (0, 0, 44, 22))
        surface.blit(glow_surf, (ix - 22, iy - 11))
        if self.type == "weapon":
            pygame.draw.line(surface, (20, 20, 25), (ix - 12, iy - 2), (ix + 12, iy - 2), 3)
            pygame.draw.rect(surface, (15, 15, 20), (ix - 2, iy - 1, 4, 6))
        else:
            pygame.draw.rect(surface, (230, 230, 230), (ix - 10, iy - 7, 20, 14), border_radius=2)
            pygame.draw.rect(surface, (220, 40, 40), (ix - 2, iy - 5, 4, 10))
            pygame.draw.rect(surface, (220, 40, 40), (ix - 5, iy - 2, 10, 4))
