import math
import random
import pygame
from src.core.audio import SoundManager

WEAPONS_DATA = [
    {
        "id": "fists",
        "slot": 1,
        "name": "PUÑOS",
        "damage": 38,
        "cooldown": 16,
        "range": 100.0,
        "is_melee": True,
        "is_auto": False,
        "is_explosive": False,
        "clip_size": 0,
        "start_reserve": 0,
        "sound": "takedown"
    },
    {
        "id": "pistol",
        "slot": 2,
        "name": "PISTOLA 9MM",
        "damage": 34,
        "cooldown": 14,
        "range": 1400.0,
        "is_melee": False,
        "is_auto": False,
        "is_explosive": False,
        "clip_size": 12,
        "start_reserve": 60,
        "sound": "shoot_silent"
    },
    {
        "id": "smg",
        "slot": 3,
        "name": "METRALLETA SMG",
        "damage": 22,
        "cooldown": 5,
        "range": 1200.0,
        "is_melee": False,
        "is_auto": True,
        "is_explosive": False,
        "clip_size": 35,
        "start_reserve": 140,
        "sound": "shoot_tactical"
    },
    {
        "id": "m4",
        "slot": 4,
        "name": "FUSIL M4",
        "damage": 44,
        "cooldown": 8,
        "range": 1800.0,
        "is_melee": False,
        "is_auto": True,
        "is_explosive": False,
        "clip_size": 30,
        "start_reserve": 90,
        "sound": "shoot_tactical"
    },
    {
        "id": "bazooka",
        "slot": 5,
        "name": "BAZUCA RPG",
        "damage": 260,
        "cooldown": 45,
        "range": 2000.0,
        "is_melee": False,
        "is_auto": False,
        "is_explosive": True,
        "clip_size": 1,
        "start_reserve": 8,
        "sound": "shoot_tactical"
    }
]

class WeaponSlot:
    def __init__(self, data):
        self.id = data["id"]
        self.slot = data["slot"]
        self.name = data["name"]
        self.damage = data["damage"]
        self.cooldown = data["cooldown"]
        self.range = data["range"]
        self.is_melee = data["is_melee"]
        self.is_auto = data["is_auto"]
        self.is_explosive = data["is_explosive"]
        self.clip_size = data["clip_size"]
        self.ammo_in_clip = data["clip_size"]
        self.ammo_reserve = data["start_reserve"]
        self.sound = data["sound"]

    def can_fire(self):
        if self.is_melee:
            return True
        return self.ammo_in_clip > 0 or self.ammo_reserve > 0

    def consume_ammo(self):
        if self.is_melee:
            return True
        if self.ammo_in_clip > 0:
            self.ammo_in_clip -= 1
            if self.ammo_in_clip == 0 and self.ammo_reserve > 0:
                self.reload()
            return True
        elif self.ammo_reserve > 0:
            self.reload()
            self.ammo_in_clip -= 1
            return True
        return False

    def reload(self):
        if self.is_melee or self.ammo_reserve <= 0:
            return
        needed = self.clip_size - self.ammo_in_clip
        transfer = min(needed, self.ammo_reserve)
        self.ammo_in_clip += transfer
        self.ammo_reserve -= transfer

    def add_ammo(self, amount):
        if not self.is_melee:
            self.ammo_reserve += amount


class Projectile3D:
    """Proyectil 3D (Bala de alta velocidad o Cohete RPG propulsado)."""
    def __init__(self, wx, wy, wz, dx, dy, dz, damage, speed, is_rocket=False, owner="Player"):
        self.wx = wx
        self.wy = wy
        self.wz = wz
        self.dx = dx
        self.dy = dy
        self.dz = dz
        self.damage = damage
        self.speed = speed
        self.is_rocket = is_rocket
        self.owner = owner
        self.alive = True
        self.traveled = 0.0
        self.max_dist = 2200.0
        self.smoke_trail = []

    def update(self):
        if self.is_rocket:
            self.smoke_trail.append((self.wx, self.wy, self.wz, 25))
            if len(self.smoke_trail) > 12:
                self.smoke_trail.pop(0)
            self.smoke_trail = [(sx, sy, sz, l - 1) for sx, sy, sz, l in self.smoke_trail if l > 1]

        self.wx += self.dx * self.speed
        self.wy += self.dy * self.speed
        self.wz += self.dz * self.speed
        self.traveled += self.speed

        if self.traveled > self.max_dist or self.wy < 0:
            self.alive = False

    def draw(self, surface, camera):
        # Dibujar estela de humo si es cohete de bazuca
        if self.is_rocket:
            for sx, sy, sz, life in self.smoke_trail:
                proj = camera.project(sx, sy, sz)
                if proj:
                    px, py, scale = proj
                    rad = max(2, min(40, int(6 * scale * (1.2 - life / 25.0))))
                    alpha = int(140 * (life / 25.0))
                    smk = pygame.Surface((rad * 2, rad * 2), pygame.SRCALPHA)
                    pygame.draw.circle(smk, (200, 200, 210, alpha), (rad, rad), rad)
                    surface.blit(smk, (px - rad, py - rad))

        proj = camera.project(self.wx, self.wy, self.wz)
        if not proj:
            return
        px, py, scale = proj

        if self.is_rocket:
            rad = max(3, int(6 * scale))
            pygame.draw.circle(surface, (255, 140, 30), (px, py), rad + 2)
            pygame.draw.circle(surface, (255, 255, 180), (px, py), rad)
        else:
            rad = max(2, int(2.8 * scale))
            col = (255, 60, 60) if self.owner == "Enemy" else (255, 230, 90)
            pygame.draw.circle(surface, col, (px, py), rad)
            pygame.draw.circle(surface, (255, 255, 255), (px, py), max(1, rad // 2))


class Explosion3D:
    """Explosión expansiva en 3D generada por cohetes RPG o autos destruidos."""
    def __init__(self, wx, wy, wz, max_radius=140):
        self.wx = wx
        self.wy = wy
        self.wz = wz
        self.radius = 10.0
        self.max_radius = max_radius
        self.life = 32
        self.max_life = 32
        self.alive = True
        self.sparks = []
        for _ in range(18):
            ang = random.uniform(0, math.pi * 2)
            spd = random.uniform(4, 14)
            vy = random.uniform(3, 12)
            self.sparks.append([wx, wy, wz, math.cos(ang) * spd, vy, math.sin(ang) * spd])

    def update(self):
        self.life -= 1
        self.radius += (self.max_radius - self.radius) * 0.25
        if self.life <= 0:
            self.alive = False

        for sp in self.sparks:
            sp[0] += sp[3]
            sp[1] += sp[4]
            sp[2] += sp[5]
            sp[4] -= 0.45  # Gravedad de escombros

    def draw(self, surface, camera):
        proj = camera.project(self.wx, self.wy, self.wz)
        if not proj:
            return
        px, py, scale = proj
        factor = self.life / self.max_life
        scr_rad = max(6, min(260, int(self.radius * scale)))

        # Bola de fuego multicapa
        exp_surf = pygame.Surface((scr_rad * 2, scr_rad * 2), pygame.SRCALPHA)
        alpha_outer = int(200 * factor)
        alpha_inner = int(255 * factor)
        pygame.draw.circle(exp_surf, (235, 65, 20, alpha_outer), (scr_rad, scr_rad), scr_rad)
        pygame.draw.circle(exp_surf, (255, 195, 45, alpha_inner), (scr_rad, scr_rad), int(scr_rad * 0.65))
        pygame.draw.circle(exp_surf, (255, 255, 230, alpha_inner), (scr_rad, scr_rad), int(scr_rad * 0.35))
        surface.blit(exp_surf, (px - scr_rad, py - scr_rad), special_flags=pygame.BLEND_RGBA_ADD)

        # Escombros ardientes
        for sp in self.sparks:
            s_proj = camera.project(sp[0], max(2, sp[1]), sp[2])
            if s_proj:
                spx, spy, s_sc = s_proj
                s_rad = max(2, int(4 * s_sc * factor))
                pygame.draw.circle(surface, (255, 140, 30), (spx, spy), s_rad)
