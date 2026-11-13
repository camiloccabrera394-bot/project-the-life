import math
import pygame
from src.core.audio import SoundManager
from src.ui.cell_shaded_models import draw_vehicle_3d
from src.entities.weapons import Explosion3D

class Vehicle3D:
    """Vehículo 3D conducible en tercera persona con aceleración, derrape, bocina y física de atropellos."""
    def __init__(self, wx, wz, vehicle_type="sports_car", yaw=0.0):
        self.wx = float(wx)
        self.wy = 0.0
        self.wz = float(wz)
        self.yaw = float(yaw)
        self.vehicle_type = vehicle_type

        self.speed = 0.0
        self.is_occupied = False
        self.is_braking = False
        self.is_accelerating = False
        self.destroyed = False

        if vehicle_type == "sports_car":
            self.max_speed = 16.5
            self.accel = 0.45
            self.turn_rate = 0.048
            self.health = 240
            self.radius = 36.0
        elif vehicle_type == "mafia_sedan":
            self.max_speed = 13.0
            self.accel = 0.34
            self.turn_rate = 0.038
            self.health = 340
            self.radius = 40.0
        else:  # motorcycle
            self.max_speed = 18.5
            self.accel = 0.58
            self.turn_rate = 0.065
            self.health = 140
            self.radius = 22.0

        self.max_health = self.health
        self.engine_timer = 0
        self.horn_timer = 0

    def explode(self, explosions, fx_manager):
        if self.destroyed:
            return
        self.destroyed = True
        self.speed = 0.0
        self.is_occupied = False
        SoundManager.get().play_sfx("takedown")
        explosions.append(Explosion3D(self.wx, 15.0, self.wz, max_radius=180))
        fx_manager.add_screen_shake(14)

    def update(self, keys, settings_mgr, city_world, civilians, enemies, explosions, fx_manager, player):
        if self.destroyed:
            return

        if not self.is_occupied:
            self.speed *= 0.88
            self.is_accelerating = False
            self.is_braking = False
            return

        up_k = settings_mgr.get_key_code("up")
        down_k = settings_mgr.get_key_code("down")
        left_k = settings_mgr.get_key_code("left")
        right_k = settings_mgr.get_key_code("right")
        brake_k = settings_mgr.get_key_code("stealth")

        self.is_braking = keys[brake_k]
        self.is_accelerating = False

        if self.is_braking:
            self.speed *= 0.86
        elif keys[up_k] or keys[pygame.K_UP]:
            self.speed = min(self.max_speed, self.speed + self.accel)
            self.is_accelerating = True
            self.engine_timer += 1
            if self.engine_timer % 28 == 0:
                SoundManager.get().play_sfx("engine")
        elif keys[down_k] or keys[pygame.K_DOWN]:
            self.speed = max(-self.max_speed * 0.45, self.speed - self.accel * 1.2)
        else:
            self.speed *= 0.96

        # Giro del vehículo
        if abs(self.speed) > 0.3:
            turn_dir = 1.0 if self.speed > 0 else -1.0
            turn_mult = 1.35 if self.is_braking else 1.0
            if keys[left_k] or keys[pygame.K_LEFT]:
                self.yaw -= self.turn_rate * turn_dir * turn_mult
            if keys[right_k] or keys[pygame.K_RIGHT]:
                self.yaw += self.turn_rate * turn_dir * turn_mult

        # Bocina [H]
        if keys[pygame.K_h] and self.horn_timer == 0:
            SoundManager.get().play_sfx("alert")
            self.horn_timer = 35
            for civ in civilians:
                if civ.alive and math.hypot(civ.wx - self.wx, civ.wz - self.wz) < 420:
                    civ.alert_panic(self.wx, self.wz)
        if self.horn_timer > 0:
            self.horn_timer -= 1

        # Movimiento con Colisión Sólida contra edificios
        vx = math.cos(self.yaw) * self.speed
        vz = math.sin(self.yaw) * self.speed
        nx = self.wx + vx
        nz = self.wz + vz

        rx, rz = city_world.resolve_movement(self.wx, self.wz, nx, nz, radius=self.radius)
        if (rx == self.wx and abs(vx) > 0.1) or (rz == self.wz and abs(vz) > 0.1):
            if abs(self.speed) > 5.0:
                SoundManager.get().play_sfx("hit")
                fx_manager.add_screen_shake(6)
            self.speed *= 0.15

        self.wx, self.wz = rx, rz

        # FÍSICA GTA: ATROPELLAR TRANSEÚNTES Y SICARIOS
        if abs(self.speed) > 2.8:
            for civ in civilians:
                if civ.alive and math.hypot(civ.wx - self.wx, civ.wz - self.wz) < self.radius + 22:
                    civ.get_hit_by_vehicle(vx * 1.4, vz * 1.4)
                    SoundManager.get().play_sfx("hit")
                    fx_manager.add_screen_shake(4)
                    self.speed *= 0.85

            for en in enemies[:]:
                if en.health > 0 and math.hypot(en.wx - self.wx, en.wz - self.wz) < self.radius + 24:
                    dmg = int(abs(self.speed) * 22)
                    en.health -= dmg
                    en.wx += vx * 2.5
                    en.wz += vz * 2.5
                    SoundManager.get().play_sfx("hit")
                    fx_manager.add_screen_shake(5)
                    self.speed *= 0.82
                    if en.health <= 0:
                        player.cash += 150
                        enemies.remove(en)

    def draw(self, surface, camera, player):
        if self.destroyed:
            return
        proj = camera.project(self.wx, self.wy, self.wz)
        if not proj:
            return
        px, py, scale = proj
        draw_vehicle_3d(surface, px, py, scale, self.vehicle_type,
                        self.is_occupied, self.is_braking, self.is_accelerating,
                        self.health / self.max_health)

        # Prompt flotante si el jugador está cerca y a pie
        if not self.is_occupied and not player.current_vehicle:
            dist = math.hypot(player.wx - self.wx, player.wz - self.wz)
            if dist < 120 and scale > 0.25:
                font = pygame.font.SysFont("Arial", 11, bold=True)
                txt = font.render("[E] CONDUCIR", True, (255, 255, 255))
                badge = pygame.Rect(px - txt.get_width() // 2 - 6, py - int(90 * scale) - 20, txt.get_width() + 12, 18)
                pygame.draw.rect(surface, (15, 18, 24, 220), badge, border_radius=3)
                pygame.draw.rect(surface, (40, 225, 245), badge, width=1, border_radius=3)
                surface.blit(txt, (badge.x + 6, badge.y + 2))
