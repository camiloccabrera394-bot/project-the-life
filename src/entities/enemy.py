import math
import random
import pygame
from src.core.audio import SoundManager
from src.entities.weapons import Projectile3D
from src.ui.cell_shaded_models import draw_npc_3d

class Enemy3D:
    """Sicario de la mafia Kuroshio o Boss en 3D con IA táctica y renderizado Cell-Shaded."""
    def __init__(self, wx, wy, wz, enemy_type="gun", is_boss=False, boss_name=""):
        self.wx = float(wx)
        self.wy = float(wy)
        self.wz = float(wz)
        self.enemy_type = enemy_type
        self.is_boss = is_boss
        self.boss_name = boss_name

        self.max_health = 320 if is_boss else 100
        self.health = self.max_health
        self.speed = 2.8 if is_boss else 2.4
        self.detection_radius = 600 if is_boss else 480

        self.state = "PATROL"
        self.patrol_dir = random.choice([-1, 1])
        self.patrol_origin = (wx, wz)
        self.anim_phase = random.uniform(0, math.pi * 2)
        self.shoot_timer = 0
        self.melee_timer = 0

    def update(self, player, projectiles, city_world, fx_manager):
        if self.health <= 0:
            return

        if self.shoot_timer > 0:
            self.shoot_timer -= 1
        if self.melee_timer > 0:
            self.melee_timer -= 1

        dist = math.hypot(player.wx - self.wx, player.wz - self.wz)
        # No atacar desde la calle si el jugador está muy arriba en una azotea diferente (a menos que sea distancia de rifle)
        height_diff = abs(player.wy - self.wy)

        eff_rad = self.detection_radius * (0.5 if player.is_crouched else 1.0)
        if dist < eff_rad and height_diff < 250 and player.health > 0:
            if self.state != "CHASE":
                SoundManager.get().play_sfx("alert")
            self.state = "CHASE"

        if self.state == "CHASE" and player.health > 0:
            ang = math.atan2(player.wz - self.wz, player.wx - self.wx)
            if dist > 180 and height_diff < 30:
                nx = self.wx + math.cos(ang) * self.speed
                nz = self.wz + math.sin(ang) * self.speed
                self.wx, self.wz = city_world.resolve_movement(self.wx, self.wz, nx, nz, radius=16)
                self.anim_phase += 0.2

            # Disparo hacia el jugador en 3D
            if dist < 850 and self.shoot_timer == 0:
                self.shoot_timer = 45 if self.is_boss else 65
                SoundManager.get().play_sfx("shoot_tactical")

                dx = player.wx - self.wx
                dy = (player.wy + 35) - (self.wy + 35)
                dz = player.wz - self.wz
                mag = math.hypot(dx, math.hypot(dy, dz))
                if mag > 0:
                    dx, dy, dz = dx / mag, dy / mag, dz / mag
                    projectiles.append(Projectile3D(self.wx + dx * 20, self.wy + 40, self.wz + dz * 20,
                                                    dx, dy, dz, 18 if self.is_boss else 12, 30.0, owner="Enemy"))
        else:
            # Patrulla
            self.anim_phase += 0.14
            nx = self.wx + self.patrol_dir * 1.4
            if abs(nx - self.patrol_origin[0]) > 220 or city_world.check_collision(nx, self.wz, 16):
                self.patrol_dir *= -1
            else:
                self.wx = nx

    def draw(self, surface, camera):
        if self.health <= 0:
            return
        proj = camera.project(self.wx, self.wy, self.wz)
        if not proj:
            return
        px, py, scale = proj
        draw_npc_3d(surface, px, py, scale, role="enemy", anim_phase=self.anim_phase,
                    is_alive=True, is_boss=self.is_boss, boss_name=self.boss_name, state=self.state)

        # Barra de vida flotante si ha recibido daño
        if self.health < self.max_health and scale > 0.2:
            bw = max(24, int(42 * scale))
            bh = max(4, int(5 * scale))
            bx = px - bw // 2
            by = py - int(195 * scale)
            pygame.draw.rect(surface, (20, 22, 26), (bx, by, bw, bh))
            fill_w = max(0, int(bw * (self.health / self.max_health)))
            pygame.draw.rect(surface, (220, 45, 50), (bx, by, fill_w, bh))
