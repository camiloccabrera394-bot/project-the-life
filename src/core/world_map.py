import math
import random
import pygame
from src.config import WIDTH, HEIGHT

class WorldMap:
    """Gestiona el trazado urbano realista, capas visuales y colisiones sólidas."""
    def __init__(self, width=2600, height=1300):
        self.width = width
        self.height = height

        # Definición de vías y aceras
        self.road_top = 460
        self.road_bottom = 860
        self.sidewalk_north_top = 370
        self.sidewalk_south_bottom = 950

        # Posición de las Vías Elevadas del Tren
        self.train_track_x = 1150
        self.train_track_w = 260

        # Cajas de colisión físicas (Edificios, muros y pilares de hormigón)
        self.colliders = []
        self._build_colliders()

        # Efecto de tren pasando
        self.train_x = -400.0
        self.train_speed = 0.0
        self.train_timer = 180

    def _build_colliders(self):
        # 1. Bloque de Edificios Norte (Zona superior del mapa)
        # Dejando callejones y entradas transitables
        self.colliders.append(pygame.Rect(0, 0, 720, self.sidewalk_north_top))
        # Entrada al Taller Cyber-Gear (abierta entre x=720 y x=880)
        self.colliders.append(pygame.Rect(880, 0, 270, self.sidewalk_north_top))
        # Edificio bajo las vías (hueco para pasar bajo el tren x=1150 a x=1410)
        self.colliders.append(pygame.Rect(1410, 0, 600, self.sidewalk_north_top))
        self.colliders.append(pygame.Rect(2080, 0, 520, self.sidewalk_north_top))

        # 2. Bloque de Edificios y Vallas Sur (Zona inferior del mapa)
        self.colliders.append(pygame.Rect(0, self.sidewalk_south_bottom, 800, self.height - self.sidewalk_south_bottom))
        self.colliders.append(pygame.Rect(880, self.sidewalk_south_bottom, 500, self.height - self.sidewalk_south_bottom))
        self.colliders.append(pygame.Rect(1460, self.sidewalk_south_bottom, 1140, self.height - self.sidewalk_south_bottom))

        # 3. Pilares de Hormigón de las Vías Elevadas del Tren (Bases sólidas)
        pilar_w, pilar_h = 36, 48
        # Pilares en la acera norte y acera sur
        self.colliders.append(pygame.Rect(self.train_track_x + 25, self.sidewalk_north_top - 10, pilar_w, pilar_h))
        self.colliders.append(pygame.Rect(self.train_track_x + self.train_track_w - 60, self.sidewalk_north_top - 10, pilar_w, pilar_h))
        self.colliders.append(pygame.Rect(self.train_track_x + 25, self.road_bottom + 15, pilar_w, pilar_h))
        self.colliders.append(pygame.Rect(self.train_track_x + self.train_track_w - 60, self.road_bottom + 15, pilar_w, pilar_h))

    def check_collision(self, x, y, radius=16):
        """Comprueba si un círculo en (x, y) intersecta con algún obstáculo sólido."""
        # Bordes exteriores del mapa
        if x - radius < 30 or x + radius > self.width - 30:
            return True
        if y - radius < 120 or y + radius > self.height - 40:
            return True

        test_rect = pygame.Rect(x - radius, y - radius, radius * 2, radius * 2)
        for c in self.colliders:
            if c.colliderect(test_rect):
                return True
        return False

    def resolve_movement(self, old_x, old_y, new_x, new_y, radius=16):
        """Permite deslizarse suavemente por las paredes sin trabarse ni atravesarlas."""
        # Intentar movimiento completo
        if not self.check_collision(new_x, new_y, radius):
            return new_x, new_y

        # Intentar solo en X
        if not self.check_collision(new_x, old_y, radius):
            return new_x, old_y

        # Intentar solo en Y
        if not self.check_collision(old_x, new_y, radius):
            return old_x, new_y

        # Bloqueado en ambos ejes
        return old_x, old_y

    def update(self):
        # Temporizador para el paso del tren elevado
        if self.train_speed == 0.0:
            self.train_timer -= 1
            if self.train_timer <= 0:
                self.train_speed = 16.0
                self.train_x = -600.0
        else:
            self.train_x += self.train_speed
            if self.train_x > self.width + 500:
                self.train_speed = 0.0
                self.train_timer = random.randint(400, 700)

    def draw_ground(self, surface, camera):
        """Dibuja el asfalto, marcas viales, aceras y bordillos según la cámara."""
        view_rect = pygame.Rect(camera.x, camera.y, camera.viewport_w, camera.viewport_h)

        # 1. Fondo oscuro de base
        surface.fill((14, 16, 22))

        # 2. Acera Norte (hormigón oscuro texturizado)
        sn_y = self.sidewalk_north_top - camera.y
        sn_h = (self.road_top - self.sidewalk_north_top)
        pygame.draw.rect(surface, (28, 32, 40), (-camera.x, sn_y, self.width, sn_h))
        # Bordillo con línea de relieve
        pygame.draw.line(surface, (45, 52, 65), (-camera.x, self.road_top - camera.y), (self.width - camera.x, self.road_top - camera.y), 3)

        # 3. Calzada / Asfalto de la Avenida Principal
        road_sy = self.road_top - camera.y
        road_sh = self.road_bottom - self.road_top
        pygame.draw.rect(surface, (18, 20, 26), (-camera.x, road_sy, self.width, road_sh))

        # Doble línea amarilla divisoria central
        mid_road_y = (self.road_top + self.road_bottom) // 2 - camera.y
        pygame.draw.line(surface, (230, 190, 40), (-camera.x, mid_road_y - 3), (self.width - camera.x, mid_road_y - 3), 2)
        pygame.draw.line(surface, (230, 190, 40), (-camera.x, mid_road_y + 3), (self.width - camera.x, mid_road_y + 3), 2)

        # Líneas blancas discontinuas de carril
        lane1_y = (self.road_top + (self.road_top + self.road_bottom) // 2) // 2 - camera.y
        lane2_y = (self.road_bottom + (self.road_top + self.road_bottom) // 2) // 2 - camera.y
        for x_step in range(0, self.width, 60):
            sx1 = x_step - camera.x
            sx2 = sx1 + 35
            pygame.draw.line(surface, (70, 78, 92), (sx1, lane1_y), (sx2, lane1_y), 2)
            pygame.draw.line(surface, (70, 78, 92), (sx1, lane2_y), (sx2, lane2_y), 2)

        # Pasos de peatones (Crosswalks)
        for cw_x in [680, 1600]:
            scw_x = cw_x - camera.x
            for st in range(0, road_sh, 28):
                pygame.draw.rect(surface, (160, 170, 185), (scw_x, road_sy + st, 60, 16))

        # 4. Acera Sur
        ss_y = self.road_bottom - camera.y
        ss_h = (self.sidewalk_south_bottom - self.road_bottom)
        pygame.draw.rect(surface, (28, 32, 40), (-camera.x, ss_y, self.width, ss_h))
        pygame.draw.line(surface, (45, 52, 65), (-camera.x, ss_y), (self.width - camera.x, ss_y), 3)

        # 5. Charcos de agua con reflejos de neón en el asfalto
        puddle_surf = pygame.Surface((camera.viewport_w, camera.viewport_h), pygame.SRCALPHA)
        puddles = [
            (520, 560, 110, 40, (40, 220, 245, 45)),
            (1020, 680, 140, 50, (235, 40, 160, 40)),
            (1240, 540, 160, 55, (245, 210, 50, 45)),  # Charco bajo las vías
            (1780, 620, 130, 45, (40, 220, 245, 40))
        ]
        for px, py, pw, ph, col in puddles:
            spx, spy = camera.apply(px, py)
            pygame.draw.ellipse(puddle_surf, col, (spx - pw // 2, spy - ph // 2, pw, ph))
        surface.blit(puddle_surf, (0, 0), special_flags=pygame.BLEND_RGBA_ADD)

        # 6. Sombra ambiental oscura proyectada bajo las vías del tren
        shadow_overpass = pygame.Surface((self.train_track_w + 80, camera.viewport_h), pygame.SRCALPHA)
        pygame.draw.rect(shadow_overpass, (8, 10, 16, 120), (0, 0, self.train_track_w + 80, camera.viewport_h))
        sp_x = (self.train_track_x - 40) - camera.x
        surface.blit(shadow_overpass, (sp_x, 0))

    def draw_buildings_and_overpass(self, surface, camera):
        """Dibuja las fachadas sólidas de los edificios, pilares y el puente del tren."""
        # 1. Fachadas y Edificios Norte
        for c in self.colliders:
            if c.y == 0:  # Edificios norte
                sc = camera.apply_rect(c)
                # Fachada de hormigón
                pygame.draw.rect(surface, (22, 25, 34), sc)
                pygame.draw.rect(surface, (12, 14, 18), sc, width=3)
                # Ventanas iluminadas
                for wx in range(sc.left + 25, sc.right - 25, 42):
                    for wy in range(sc.top + 30, sc.bottom - 40, 45):
                        win_col = (255, 235, 140, 180) if (wx + wy) % 3 == 0 else (35, 45, 60, 160)
                        pygame.draw.rect(surface, win_col, (wx, wy, 24, 28), border_radius=2)
                # Rótulo de tienda
                if c.x == 0:
                    font = pygame.font.SysFont("Impact", 16)
                    txt = font.render("NEO-RAMEN & BAR 24H", True, (245, 60, 80))
                    surface.blit(txt, (sc.left + 50, sc.bottom - 32))
                elif c.x == 880:
                    font = pygame.font.SysFont("Impact", 15)
                    txt = font.render("CYBER-GEAR AUTO REPAIR", True, (40, 220, 245))
                    surface.blit(txt, (sc.left + 15, sc.bottom - 32))

            elif c.y >= self.sidewalk_south_bottom:  # Edificios y almacenes sur
                sc = camera.apply_rect(c)
                pygame.draw.rect(surface, (20, 22, 30), sc)
                pygame.draw.rect(surface, (12, 14, 18), sc, width=3)

        # 2. Pilares de Hormigón de las Vías Elevadas
        pilar_w, pilar_h = 36, 48
        pilars = [
            (self.train_track_x + 25, self.sidewalk_north_top - 10),
            (self.train_track_x + self.train_track_w - 60, self.sidewalk_north_top - 10),
            (self.train_track_x + 25, self.road_bottom + 15),
            (self.train_track_x + self.train_track_w - 60, self.road_bottom + 15)
        ]
        for px, py in pilars:
            spx, spy = camera.apply(px, py)
            p_rect = pygame.Rect(spx, spy, pilar_w, pilar_h)
            pygame.draw.rect(surface, (45, 50, 60), p_rect, border_radius=2)
            pygame.draw.rect(surface, (25, 28, 35), p_rect, width=2, border_radius=2)
            pygame.draw.line(surface, (65, 75, 90), (spx + 4, spy + 2), (spx + 4, spy + pilar_h - 2), 2)

        # 3. Estructura Metálica del Puente Elevado del Tren
        bridge_sx = self.train_track_x - camera.x
        bridge_sy = 0
        bridge_h = HEIGHT
        
        # Vigas de acero en rejilla que cruzan por arriba
        viga_surf = pygame.Surface((self.train_track_w, bridge_h), pygame.SRCALPHA)
        # Tablero superior
        pygame.draw.rect(viga_surf, (35, 40, 52, 220), (0, 0, self.train_track_w, 90))
        pygame.draw.rect(viga_surf, (20, 24, 30), (0, 0, self.train_track_w, 90), width=3)
        # Viga transversal
        pygame.draw.rect(viga_surf, (45, 52, 65, 200), (0, self.road_top - 80, self.train_track_w, 35))
        pygame.draw.rect(viga_surf, (45, 52, 65, 200), (0, self.road_bottom + 45, self.train_track_w, 35))
        # Celosía de cruces metálicas
        for cy in range(110, HEIGHT - 100, 75):
            pygame.draw.line(viga_surf, (55, 62, 78, 140), (10, cy), (self.train_track_w - 10, cy + 65), 3)
            pygame.draw.line(viga_surf, (55, 62, 78, 140), (10, cy + 65), (self.train_track_w - 10, cy), 3)
        
        surface.blit(viga_surf, (bridge_sx, 0))

        # Rótulo de estación / vías
        font = pygame.font.SysFont("Impact", 13)
        rtxt = font.render("<< LÍNEA ELEVADA METRO NOCTURNO >>", True, (245, 210, 50))
        surface.blit(rtxt, (bridge_sx + self.train_track_w // 2 - rtxt.get_width() // 2, 45))

        # 4. Tren Elevado pasando por arriba (si está activo)
        if self.train_speed > 0:
            tsx = self.train_track_x - camera.x + 20
            tsy = int(self.train_x - camera.y)
            # Vagones del tren
            for v_idx in range(4):
                v_rect = pygame.Rect(tsx, tsy + v_idx * 140, self.train_track_w - 40, 125)
                pygame.draw.rect(surface, (180, 35, 45), v_rect, border_radius=4)
                pygame.draw.rect(surface, (240, 240, 245), v_rect, width=2, border_radius=4)
                # Ventanas con pasajeros / luces interiores
                for win_y in range(v_rect.top + 15, v_rect.bottom - 15, 28):
                    pygame.draw.rect(surface, (255, 245, 170), (v_rect.left + 15, win_y, v_rect.width - 30, 18), border_radius=2)
