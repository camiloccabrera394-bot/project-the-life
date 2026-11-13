import os
import random
import math
import pygame
from src.config import WIDTH, HEIGHT, SettingsManager, OPERATIONS, get_font
from src.core.tps_world import TPSCityWorld, Camera3D
from src.core.effects import VisualEffectsManager
from src.core.audio import SoundManager
from src.entities.player import Player3D
from src.entities.enemy import Enemy3D
from src.entities.vehicles import Vehicle3D
from src.entities.civilians import Civilian3D
from src.entities.payphone import Payphone3D
from src.entities.weapons import Explosion3D
from src.ui.gta_hud import GTAHud

class Pickup3D:
    """Caja de munición o botiquín en 3D que sueltan los enemigos abatidos."""
    def __init__(self, wx, wz, p_type="ammo", amount=30):
        self.wx = wx
        self.wy = 12.0
        self.wz = wz
        self.p_type = p_type
        self.amount = amount
        self.picked = False
        self.bob = 0.0

    def update(self, player):
        self.bob += 0.1
        self.wy = 12.0 + math.sin(self.bob) * 4.0
        if math.hypot(player.wx - self.wx, player.wz - self.wz) < 55:
            self.picked = True
            SoundManager.get().play_sfx("click")
            if self.p_type == "ammo":
                for w in player.weapons:
                    w.add_ammo(self.amount if w.id != "bazooka" else 2)
            elif self.p_type == "medkit":
                player.health = min(player.max_health, player.health + 45)

    def draw(self, surface, camera):
        proj = camera.project(self.wx, self.wy, self.wz)
        if not proj:
            return
        px, py, sc = proj
        if sc < 0.15:
            return
        sz = max(6, int(14 * sc))
        col = (45, 225, 95) if self.p_type == "medkit" else (245, 205, 50)
        pygame.draw.rect(surface, col, (px - sz // 2, py - sz // 2, sz, sz), border_radius=2)
        pygame.draw.rect(surface, (15, 18, 24), (px - sz // 2, py - sz // 2, sz, sz), width=1, border_radius=2)


class GameplayScene:
    """Escena Principal 3D en Tercera Persona Estilo GTA San Andreas."""
    def __init__(self, selected_char="nagumo", operation_id="chacal"):
        self.selected_char = selected_char
        self.operation_id = operation_id
        self.settings = SettingsManager.get()
        self.fx_manager = VisualEffectsManager()
        self.hud = GTAHud()

        self.op_data = next((op for op in OPERATIONS if op["id"] == operation_id), OPERATIONS[0])

        # Mundo 3D y Cámara Trasera
        self.city_world = TPSCityWorld()
        self.camera = Camera3D()

        # Jugador aparece caminando en la Avenida Central (Z=2500) mirando hacia las vías del tren (+X)
        self.player = Player3D(wx=1400, wz=2500, char_id=selected_char)
        self.camera.cam_yaw = self.player.yaw
        self.camera.cam_x = self.player.wx - 155
        self.camera.cam_z = self.player.wz

        # Estado de alturas (Calle vs Azotea)
        self.on_rooftop = False
        self.active_rooftop_rect = None
        self.active_ladder_origin = None
        self.ladder_points = [
            (2680, 1280, "CYBER-GEAR AZOTEA"),
            (1080, 1280, "AZOTEA HOTEL KUROSHIO")
        ]

        # Cabina Telefónica sonando bajo el puente elevado (X=2500, Z=2320)
        self.payphone = Payphone3D(wx=2500, wz=2320)

        # Vehículos estacionados en la avenida listos para conducir
        self.vehicles = [
            Vehicle3D(1680, 2440, vehicle_type="sports_car", yaw=0.0),
            Vehicle3D(2100, 2560, vehicle_type="mafia_sedan", yaw=0.05),
            Vehicle3D(2400, 2000, vehicle_type="motorcycle", yaw=math.pi / 2),
            Vehicle3D(3100, 2440, vehicle_type="sports_car", yaw=math.pi),
            Vehicle3D(2680, 1600, vehicle_type="mafia_sedan", yaw=-math.pi / 2)
        ]

        # Transeúntes realistas caminando por las aceras
        self.civilians = []
        if self.settings.data.get("pedestrians_enabled", True):
            for x_pos in range(1200, 4200, 320):
                self.civilians.append(Civilian3D(x_pos, 2310, walk_axis="x", limits=(1100, 4400)))
                self.civilians.append(Civilian3D(x_pos + 140, 2690, walk_axis="x", limits=(1100, 4400)))
            for z_pos in range(1000, 3800, 420):
                self.civilians.append(Civilian3D(2310, z_pos, walk_axis="z", limits=(900, 4000)))
                self.civilians.append(Civilian3D(2690, z_pos + 160, walk_axis="z", limits=(900, 4000)))

        # Sicarios de la organización y Boss El Chacal en el distrito Cyber-Gear (X=2800..3100, Z=900)
        self.enemies = [
            Enemy3D(2200, 0, 2500, "gun"),
            Enemy3D(2650, 0, 1800, "gun"),
            Enemy3D(2750, 0, 1000, "gun"),
            Enemy3D(2920, 0, 950, "gun"),
            Enemy3D(3120, 0, 900, "boss", is_boss=True, boss_name=self.op_data["target_name"])
        ]

        self.projectiles = []
        self.explosions = []
        self.pickups = [
            Pickup3D(1550, 2500, "ammo", 40),
            Pickup3D(2650, 2480, "medkit", 40)
        ]

        self.mission_state = "FIND_PHONE"  # "FIND_PHONE" -> "HUNT_TARGET" -> "COMPLETE"
        self.subtitle = "Informante: Ve hacia las vías del tren y contesta el teléfono público que suena [E]."
        self.subtitle_timer = 300
        self.game_over_timer = 0
        self.complete_timer = 0
        self.is_aiming = False

    def handle_events(self, events):
        interact_k = self.settings.get_key_code("interact")
        shoot_k = self.settings.get_key_code("shoot")

        for event in events:
            if event.type == pygame.KEYDOWN:
                # Avanzar diálogo del teléfono
                if self.payphone.dialogue_active:
                    if event.key in [pygame.K_SPACE, pygame.K_RETURN, interact_k]:
                        res = self.payphone.advance_dialogue()
                        if res == "CALL_FINISHED":
                            self.mission_state = "HUNT_TARGET"
                            self.subtitle = f"Misión Actualizada: Elimina a {self.op_data['target_name']} en el Bulevar Norte (Cyber-Gear)."
                            self.subtitle_timer = 320
                    return None

                if event.key == pygame.K_ESCAPE:
                    return "MISSION_SELECT"

                # Cambio rápido de armas [1 - 5] o [Q]
                elif event.key == pygame.K_1: self.player.switch_weapon(0)
                elif event.key == pygame.K_2: self.player.switch_weapon(1)
                elif event.key == pygame.K_3: self.player.switch_weapon(2)
                elif event.key == pygame.K_4: self.player.switch_weapon(3)
                elif event.key == pygame.K_5: self.player.switch_weapon(4)
                elif event.key == pygame.K_q: self.player.cycle_weapon(1)

                elif event.key == interact_k:
                    # 1. Contestar teléfono público
                    if not self.payphone.answered and math.hypot(self.player.wx - self.payphone.wx, self.player.wz - self.payphone.wz) < 120:
                        self.payphone.answer_call()
                        return None

                    # 2. Subir o bajar escalera de incendios a la azotea
                    if self.on_rooftop and self.active_ladder_origin:
                        lx, lz = self.active_ladder_origin
                        # Punto de descenso en el borde del techo
                        b_r = self.active_rooftop_rect
                        drop_x = max(b_r.left + 25, min(lx, b_r.right - 25))
                        drop_z = max(b_r.top + 25, min(lz, b_r.bottom - 25))
                        if math.hypot(self.player.wx - drop_x, self.player.wz - drop_z) < 120:
                            SoundManager.get().play_sfx("click")
                            self.on_rooftop = False
                            self.active_rooftop_rect = None
                            self.player.wy = 0.0
                            self.player.wx, self.player.wz = lx, lz
                            self.subtitle = "Has bajado de la azotea a la avenida."
                            self.subtitle_timer = 180
                            return None
                    else:
                        for lx, lz, lname in self.ladder_points:
                            if math.hypot(self.player.wx - lx, self.player.wz - lz) < 115:
                                b = self.city_world.get_nearest_building(lx, lz)
                                if b:
                                    SoundManager.get().play_sfx("click")
                                    self.on_rooftop = True
                                    self.active_rooftop_rect = b["rect"]
                                    self.active_ladder_origin = (lx, lz)
                                    self.player.wy = float(b["height"])
                                    r = b["rect"]
                                    self.player.wx = max(r.left + 35, min(lx, r.right - 35))
                                    self.player.wz = max(r.top + 35, min(lz, r.bottom - 35))
                                    self.subtitle = f"Has subido a {lname}. Puedes vigilar la calle desde las alturas."
                                    self.subtitle_timer = 200
                                    return None

                    # 3. Subir / Bajar de Auto o Moto
                    if self.player.current_vehicle:
                        v = self.player.current_vehicle
                        v.is_occupied = False
                        self.player.wx = v.wx + math.cos(v.yaw + math.pi / 2) * 55
                        self.player.wz = v.wz + math.sin(v.yaw + math.pi / 2) * 55
                        self.player.current_vehicle = None
                        return None
                    else:
                        for v in self.vehicles:
                            if not v.destroyed and math.hypot(self.player.wx - v.wx, self.player.wz - v.wz) < 120:
                                v.is_occupied = True
                                self.player.current_vehicle = v
                                SoundManager.get().play_sfx("engine")
                                self.subtitle = "Conducción: [W] Acelerar, [S] Reversa, [A/D] Girar, [ESPACIO] Derrapar, [H] Bocina."
                                self.subtitle_timer = 220
                                return None

                elif event.key == shoot_k:
                    self.player.fire_weapon(pygame.mouse.get_pos(), self.camera, self.projectiles,
                                            self.enemies, self.civilians, self.explosions, self.fx_manager)

            elif event.type == pygame.MOUSEWHEEL:
                self.player.cycle_weapon(-event.y)

            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:
                    if self.payphone.dialogue_active:
                        res = self.payphone.advance_dialogue()
                        if res == "CALL_FINISHED":
                            self.mission_state = "HUNT_TARGET"
                            self.subtitle = f"Misión Actualizada: Elimina a {self.op_data['target_name']} en Cyber-Gear."
                            self.subtitle_timer = 320
                        return None

                    self.player.fire_weapon(event.pos, self.camera, self.projectiles,
                                            self.enemies, self.civilians, self.explosions, self.fx_manager)
                elif event.button == 3:
                    self.is_aiming = True

            elif event.type == pygame.MOUSEBUTTONUP:
                if event.button == 3:
                    self.is_aiming = False

        return None

    def update(self):
        if self.payphone.dialogue_active:
            return None

        if self.subtitle_timer > 0:
            self.subtitle_timer -= 1
            if self.subtitle_timer == 0:
                self.subtitle = None

        keys = pygame.key.get_pressed()
        mouse_btns = pygame.mouse.get_pressed()

        # Disparo automático continuo para Metralleta SMG / Fusil M4
        if (mouse_btns[0] or keys[self.settings.get_key_code("shoot")]) and self.player.active_weapon.is_auto:
            self.player.fire_weapon(pygame.mouse.get_pos(), self.camera, self.projectiles,
                                    self.enemies, self.civilians, self.explosions, self.fx_manager)

        self.fx_manager.update()
        self.city_world.update()
        self.payphone.update()

        # 1. Vehículos
        for v in self.vehicles:
            v.update(keys, self.settings, self.city_world, self.civilians, self.enemies, self.explosions, self.fx_manager, self.player)

        # 2. Jugador
        self.player.update(keys, self.settings, self.city_world, on_rooftop=self.on_rooftop, rooftop_rect=self.active_rooftop_rect)

        # 3. Cámara en Tercera Persona (detrás del jugador o auto)
        cam_dist = 200.0 if self.player.current_vehicle else (120.0 if self.is_aiming else 155.0)
        cam_h = 105.0 if self.player.current_vehicle else 86.0
        self.camera.update_behind(self.player.wx, self.player.wy, self.player.wz, self.player.yaw, dist=cam_dist, height=cam_h)

        # 4. Transeúntes
        for civ in self.civilians:
            civ.update()

        # 5. Pickups
        for pk in self.pickups[:]:
            pk.update(self.player)
            if pk.picked:
                self.pickups.remove(pk)

        # 6. Proyectiles 3D y Explosiones de Bazuca
        for p in self.projectiles[:]:
            p.update()
            if not p.alive:
                if p.is_rocket:
                    self._trigger_explosion(p.wx, p.wy, p.wz)
                self.projectiles.remove(p)
                continue

            # Impacto contra edificio
            if self.city_world.check_collision(p.wx, p.wz, radius=6) and p.wy < 220:
                p.alive = False
                if p.is_rocket:
                    self._trigger_explosion(p.wx, p.wy, p.wz)
                self.projectiles.remove(p)
                continue

            # Impacto contra autos
            hit_car = False
            for v in self.vehicles:
                if not v.destroyed and not v.is_occupied and math.hypot(v.wx - p.wx, v.wz - p.wz) < v.radius + 10 and p.wy < 60:
                    v.health -= p.damage
                    p.alive = False
                    if p.is_rocket or v.health <= 0:
                        v.explode(self.explosions, self.fx_manager)
                        self._trigger_explosion(v.wx, 15.0, v.wz)
                    self.projectiles.remove(p)
                    hit_car = True
                    break
            if hit_car:
                continue

            if p.owner == "Player":
                for en in self.enemies[:]:
                    if math.hypot(en.wx - p.wx, en.wz - p.wz) < 28 and abs(en.wy + 35 - p.wy) < 48:
                        p.alive = False
                        if p.is_rocket:
                            self._trigger_explosion(p.wx, p.wy, p.wz)
                        else:
                            en.health -= p.damage
                            en.state = "CHASE"
                            SoundManager.get().play_sfx("hit")
                            if en.health <= 0:
                                self._on_enemy_killed(en)
                        if p in self.projectiles:
                            self.projectiles.remove(p)
                        break
            else:  # Bala enemiga contra jugador
                if math.hypot(self.player.wx - p.wx, self.player.wz - p.wz) < 24 and abs(self.player.wy + 35 - p.wy) < 48:
                    if self.player.current_vehicle:
                        self.player.current_vehicle.health -= p.damage
                    else:
                        self.player.health = max(0, self.player.health - p.damage)
                        SoundManager.get().play_sfx("hit")
                        self.fx_manager.add_screen_shake(4)
                    p.alive = False
                    if p in self.projectiles:
                        self.projectiles.remove(p)

        # 7. Explosiones
        for exp in self.explosions[:]:
            exp.update()
            if not exp.alive:
                self.explosions.remove(exp)

        # 8. Enemigos
        for en in self.enemies:
            en.update(self.player, self.projectiles, self.city_world, self.fx_manager)

        # 9. Fin de misión / Muerte
        if self.mission_state == "COMPLETE":
            self.complete_timer += 1
            if self.complete_timer > 150:
                return "MISSION_SELECT"

        if self.player.health <= 0:
            self.game_over_timer += 1
            if self.game_over_timer > 90:
                return "GAME_OVER"

        return None

    def _trigger_explosion(self, wx, wy, wz):
        SoundManager.get().play_sfx("takedown")
        self.explosions.append(Explosion3D(wx, wy, wz, max_radius=170))
        self.fx_manager.add_screen_shake(16)
        area = 210.0

        # Daño de área a enemigos, peatones y vehículos
        for en in self.enemies[:]:
            if math.hypot(en.wx - wx, en.wz - wz) < area:
                en.health -= 240
                if en.health <= 0:
                    self._on_enemy_killed(en)

        for civ in self.civilians:
            if civ.alive and math.hypot(civ.wx - wx, civ.wz - wz) < area:
                ang = math.atan2(civ.wz - wz, civ.wx - wx)
                civ.get_hit_by_vehicle(math.cos(ang) * 14, math.sin(ang) * 14)

        for v in self.vehicles:
            if not v.destroyed and math.hypot(v.wx - wx, v.wz - wz) < area:
                v.explode(self.explosions, self.fx_manager)

    def _on_enemy_killed(self, en):
        self.player.cash += 500 if en.is_boss else 150
        if en in self.enemies:
            self.enemies.remove(en)
        self.pickups.append(Pickup3D(en.wx, en.wz, "ammo" if random.random() < 0.75 else "medkit", 30))
        if en.is_boss:
            self.mission_state = "COMPLETE"
            self.op_data["completed"] = True
            self.subtitle = "¡OBJETIVO ELIMINADO! Has vengado a tu madre. +$500."
            self.subtitle_timer = 300

    def draw(self, surface):
        ox, oy = self.fx_manager.get_shake_offset()
        render_surf = pygame.Surface((WIDTH, HEIGHT))

        # 1. Entorno 3D: Cielo dorado/crepúsculo, carreteras, edificios sólidos, farolas y puente de tren
        self.city_world.draw_environment(render_surf, self.camera)

        # 2. Dibujar marcadores de Escaleras de Incendio
        for lx, lz, lname in self.ladder_points:
            b = self.city_world.get_nearest_building(lx, lz)
            top_h = float(b["height"]) if b else 220.0
            proj_bot = self.camera.project(lx, 0, lz)
            proj_top = self.camera.project(lx, top_h, lz)
            if proj_bot and proj_top:
                px1, py1, sc1 = proj_bot
                px2, py2, sc2 = proj_top
                if sc1 > 0.15 or sc2 > 0.15:
                    pygame.draw.line(render_surf, (245, 205, 50), (px1 - int(6*sc1), py1), (px2 - int(6*sc2), py2), max(2, min(6, int(3*sc1))))
                    pygame.draw.line(render_surf, (245, 205, 50), (px1 + int(6*sc1), py1), (px2 + int(6*sc2), py2), max(2, min(6, int(3*sc1))))
                    if math.hypot(self.player.wx - lx, self.player.wz - lz) < 130:
                        f = get_font("hud", 11, bold=True)
                        lbl = "[E] BAJAR A LA CALLE" if self.on_rooftop else "[E] SUBIR A LA AZOTEA"
                        t = f.render(lbl, True, (255, 255, 255))
                        ty = py2 - 20 if self.on_rooftop else py1 - 110
                        render_surf.blit(t, (px1 - t.get_width() // 2, ty))

        # 3. Ordenar entidades por distancia Z a la cámara (Painter's Algorithm 3D)
        entities_dist = []
        all_objs = (self.civilians + self.enemies + self.vehicles + self.pickups + [self.payphone, self.player])
        for obj in all_objs:
            dist = math.hypot(obj.wx - self.camera.cam_x, obj.wz - self.camera.cam_z)
            if dist < 2400:
                entities_dist.append((dist, obj))

        entities_dist.sort(key=lambda item: -item[0])

        for _, obj in entities_dist:
            if isinstance(obj, Vehicle3D):
                obj.draw(render_surf, self.camera, self.player)
            elif isinstance(obj, Payphone3D):
                obj.draw(render_surf, self.camera, self.player)
            else:
                obj.draw(render_surf, self.camera)

        # 4. Proyectiles y Explosiones 3D
        for p in self.projectiles:
            p.draw(render_surf, self.camera)
        for exp in self.explosions:
            exp.draw(render_surf, self.camera)

        # 5. Partículas y Lluvia ambiental
        self.fx_manager.draw_particles(render_surf)
        self.fx_manager.draw_rain(render_surf)

        surface.blit(render_surf, (ox, oy))

        # 6. HUD Auténtico de GTA San Andreas
        target_pos = (self.payphone.wx, self.payphone.wz) if self.mission_state == "FIND_PHONE" else (3120, 900)
        cur_sub = self.payphone.get_current_subtitle() or self.subtitle
        self.hud.draw(surface, self.player, self.player.cash, self.player.active_weapon, target_pos, cur_sub, self.city_world)

        # Retícula de apuntado
        self.hud.draw_crosshair(surface, pygame.mouse.get_pos(), self.is_aiming)
