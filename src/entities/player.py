import math
import pygame
from src.config import CHARACTERS, WIDTH, HEIGHT
from src.core.audio import SoundManager
from src.entities.weapons import WEAPONS_DATA, WeaponSlot, Projectile3D
from src.ui.cell_shaded_models import draw_protagonist_tps

class Player3D:
    """Protagonista en Tercera Persona (3D Behind-the-Back) con inventario de 5 armas y conducción."""
    def __init__(self, wx, wz, char_id="nagumo"):
        self.wx = float(wx)
        self.wy = 0.0  # Altura (0 = calle, >0 = azotea)
        self.wz = float(wz)
        self.yaw = 0.0  # Dirección mirando por la avenida (+X inicialmente)

        self.char_id = char_id
        cfg = CHARACTERS.get(char_id, CHARACTERS["nagumo"])
        self.name = cfg["name"]
        self.is_nagumo = (char_id == "nagumo")

        self.max_health = cfg["health"]
        self.health = self.max_health
        self.base_speed = cfg["speed"] * 1.45
        self.stealth_speed = cfg["stealth_speed"] * 1.35

        # Arsenal completo de 5 armas estilo GTA
        self.weapons = [WeaponSlot(w) for w in WEAPONS_DATA]
        self.weapon_idx = 3  # Empieza con Fusil M4 (igual que en la foto de referencia)

        self.shoot_cooldown = 0
        self.muzzle_timer = 0
        self.punch_timer = 0
        self.anim_phase = 0.0
        self.is_walking = False
        self.is_crouched = False
        self.current_vehicle = None
        self.radius = 18.0
        self.cash = 350  # Dinero inicial igual que en la foto ($00000350)

    @property
    def active_weapon(self):
        return self.weapons[self.weapon_idx]

    def switch_weapon(self, index):
        if 0 <= index < len(self.weapons):
            self.weapon_idx = index
            SoundManager.get().play_sfx("click")

    def cycle_weapon(self, direction=1):
        self.weapon_idx = (self.weapon_idx + direction) % len(self.weapons)
        SoundManager.get().play_sfx("click")

    def update(self, keys, settings_mgr, city_world, on_rooftop=False, rooftop_rect=None):
        if self.health <= 0:
            return

        if self.shoot_cooldown > 0:
            self.shoot_cooldown -= 1
        if self.muzzle_timer > 0:
            self.muzzle_timer -= 1
        if self.punch_timer > 0:
            self.punch_timer -= 1

        if self.current_vehicle:
            self.wx = self.current_vehicle.wx
            self.wy = self.current_vehicle.wy
            self.wz = self.current_vehicle.wz
            self.yaw = self.current_vehicle.yaw
            return

        up_k = settings_mgr.get_key_code("up")
        down_k = settings_mgr.get_key_code("down")
        left_k = settings_mgr.get_key_code("left")
        right_k = settings_mgr.get_key_code("right")
        stealth_k = settings_mgr.get_key_code("stealth")

        # 1. Giro lateral (A/D o Flechas Izq/Der)
        turn_speed = 0.045
        if keys[left_k] or keys[pygame.K_LEFT]:
            self.yaw -= turn_speed
        if keys[right_k] or keys[pygame.K_RIGHT]:
            self.yaw += turn_speed

        # 2. Sigilo
        self.is_crouched = keys[stealth_k] or keys[pygame.K_LSHIFT]
        spd = self.stealth_speed if self.is_crouched else self.base_speed

        # 3. Avance / Retroceso (W/S o Flechas)
        move_dir = 0.0
        if keys[up_k] or keys[pygame.K_UP]:
            move_dir = 1.0
        elif keys[down_k] or keys[pygame.K_DOWN]:
            move_dir = -0.7

        self.is_walking = (move_dir != 0.0)
        if self.is_walking:
            self.anim_phase += 0.22
            nx = self.wx + math.cos(self.yaw) * spd * move_dir
            nz = self.wz + math.sin(self.yaw) * spd * move_dir
            if on_rooftop and rooftop_rect:
                self.wx = max(rooftop_rect.left + 20, min(rooftop_rect.right - 20, nx))
                self.wz = max(rooftop_rect.top + 20, min(rooftop_rect.bottom - 20, nz))
            elif on_rooftop:
                self.wx = max(120, min(city_world.width - 120, nx))
                self.wz = max(120, min(city_world.depth - 120, nz))
            else:
                self.wx, self.wz = city_world.resolve_movement(self.wx, self.wz, nx, nz, radius=self.radius)

    def fire_weapon(self, mouse_pos, camera, projectiles, enemies, civilians, explosions, fx_manager):
        if self.current_vehicle or self.health <= 0 or self.shoot_cooldown > 0:
            return False

        w = self.active_weapon

        # 1. Combate con Puños
        if w.is_melee:
            self.shoot_cooldown = w.cooldown
            self.punch_timer = 10
            SoundManager.get().play_sfx("takedown")
            # Impactar a enemigos cercanos frente al jugador
            hit_any = False
            for en in enemies[:]:
                if en.health > 0 and math.hypot(en.wx - self.wx, en.wz - self.wz) < w.range:
                    en.health -= w.damage * (3 if en.state != "CHASE" else 1)  # Derribo sigiloso por espalda
                    fx_manager.spawn_blood(WIDTH // 2, HEIGHT // 2, count=8)
                    SoundManager.get().play_sfx("hit")
                    hit_any = True
                    if en.health <= 0:
                        self.cash += 120
                        enemies.remove(en)
            return hit_any

        # 2. Armas de Fuego y Bazuca
        if not w.can_fire():
            return False

        w.consume_ammo()
        self.shoot_cooldown = w.cooldown
        self.muzzle_timer = 4
        SoundManager.get().play_sfx(w.sound)
        fx_manager.add_screen_shake(8 if w.is_explosive else 3)

        # Calcular vector de disparo 3D usando la dirección del jugador + offset de mira del ratón
        mx, my = mouse_pos
        aim_yaw_offset = ((mx - WIDTH * 0.5) / (WIDTH * 0.5)) * 0.35
        aim_pitch = ((camera.horizon_y - my) / HEIGHT) * 0.45

        fire_yaw = self.yaw + aim_yaw_offset
        dx = math.cos(fire_yaw)
        dz = math.sin(fire_yaw)
        dy = aim_pitch

        mag = math.hypot(dx, math.hypot(dy, dz))
        dx, dy, dz = dx / mag, dy / mag, dz / mag

        # Origen desde el hombro / arma
        spawn_x = self.wx + dx * 20
        spawn_y = self.wy + 45
        spawn_z = self.wz + dz * 20

        spd = 24.0 if w.is_explosive else 48.0
        proj = Projectile3D(spawn_x, spawn_y, spawn_z, dx, dy, dz,
                            w.damage, spd, is_rocket=w.is_explosive, owner="Player")
        projectiles.append(proj)

        # Alertar a transeúntes y enemigos cercanos
        if w.id != "pistol" or self.is_nagumo:
            for civ in civilians:
                if civ.alive and math.hypot(civ.wx - self.wx, civ.wz - self.wz) < 650:
                    civ.alert_panic(self.wx, self.wz)
            for en in enemies:
                if math.hypot(en.wx - self.wx, en.wz - self.wz) < 700:
                    en.state = "CHASE"

        return True

    def draw(self, surface, camera):
        if self.current_vehicle or self.health <= 0:
            return
        proj = camera.project(self.wx, self.wy, self.wz)
        if not proj:
            return
        px, py, scale = proj
        draw_protagonist_tps(
            surface, px, py, scale,
            self.char_id, self.active_weapon.id,
            self.anim_phase, self.is_walking,
            self.is_crouched, self.punch_timer > 0,
            self.muzzle_timer
        )
