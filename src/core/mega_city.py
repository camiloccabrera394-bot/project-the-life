import math
import random
import pygame
from src.config import WIDTH, HEIGHT

class MegaCity:
    """Metrópolis masiva estilo GTA (5000 x 3500 px) con múltiples manzanas, avenidas, muelles y vías de tren."""
    def __init__(self, width=5000, height=3500):
        self.width = width
        self.height = height

        # Coordenadas de las 3 grandes Avenidas Horizontales
        self.avenues_y = [
            (650, 950),    # Avenida Norte Kuroshio
            (1650, 1950),  # Gran Vía Industrial / Vías del Tren
            (2650, 2950)   # Bulevar Marítimo de los Muelles
        ]

        # Coordenadas de los 3 Bulevares Verticales
        self.boulevards_x = [
            (900, 1200),   # Bulevar Oeste
            (2350, 2650),  # Corredor Central de las Vías Elevadas
            (3800, 4100)   # Bulevar Comercial Este
        ]

        # Cajas de colisión sólidas de las manzanas de edificios
        self.building_blocks = []
        self._generate_city_blocks()

        # Marcas de neumáticos en el asfalto (Skidmarks de derrape)
        self.skidmarks = []

        # Tren elevado periódico
        self.train_y = -800.0
        self.train_speed = 0.0
        self.train_timer = 200

    def _generate_city_blocks(self):
        # 12 Grandes Manzanas de Edificios Sólidos
        # Fila 1 (Norte)
        self.building_blocks.append(pygame.Rect(80, 80, 740, 500))
        self.building_blocks.append(pygame.Rect(1280, 80, 980, 500))
        self.building_blocks.append(pygame.Rect(2740, 80, 980, 500))   # Manzana con el Taller Cyber-Gear
        self.building_blocks.append(pygame.Rect(4180, 80, 740, 500))

        # Fila 2 (Centro)
        self.building_blocks.append(pygame.Rect(80, 1020, 740, 560))
        self.building_blocks.append(pygame.Rect(1280, 1020, 980, 560))
        self.building_blocks.append(pygame.Rect(2740, 1020, 980, 560))
        self.building_blocks.append(pygame.Rect(4180, 1020, 740, 560))

        # Fila 3 (Sur / Muelles)
        self.building_blocks.append(pygame.Rect(80, 2020, 740, 560))
        self.building_blocks.append(pygame.Rect(1280, 2020, 980, 560))
        self.building_blocks.append(pygame.Rect(2740, 2020, 980, 560))
        self.building_blocks.append(pygame.Rect(4180, 2020, 740, 560))

        # Pilares de las vías del tren elevado en los cruces
        track_cx = 2500
        for ay_top, ay_bot in self.avenues_y:
            self.building_blocks.append(pygame.Rect(track_cx - 80, ay_top - 30, 36, 48))
            self.building_blocks.append(pygame.Rect(track_cx + 50, ay_top - 30, 36, 48))
            self.building_blocks.append(pygame.Rect(track_cx - 80, ay_bot + 5, 36, 48))
            self.building_blocks.append(pygame.Rect(track_cx + 50, ay_bot + 5, 36, 48))

        # Límite acuático sur (muelles)
        self.building_blocks.append(pygame.Rect(0, 3080, self.width, 420))

    def add_skidmark(self, x, y, angle):
        if len(self.skidmarks) > 250:
            self.skidmarks.pop(0)
        self.skidmarks.append((x, y, angle, 180))

    def check_collision(self, x, y, radius=16):
        """Comprueba colisión física contra edificios y límites de la mega ciudad."""
        if x - radius < 30 or x + radius > self.width - 30:
            return True
        if y - radius < 30 or y + radius > self.height - 30:
            return True

        test_rect = pygame.Rect(x - radius, y - radius, radius * 2, radius * 2)
        for b in self.building_blocks:
            if b.colliderect(test_rect):
                return True
        return False

    def resolve_movement(self, old_x, old_y, new_x, new_y, radius=16):
        """Deslizamiento físico realista para no atravesar ni escalar edificios."""
        if not self.check_collision(new_x, new_y, radius):
            return new_x, new_y

        if not self.check_collision(new_x, old_y, radius):
            return new_x, old_y

        if not self.check_collision(old_x, new_y, radius):
            return old_x, new_y

        return old_x, old_y

    def update(self):
        # Desvanecer marcas de neumáticos
        self.skidmarks = [(x, y, a, alpha - 1) for x, y, a, alpha in self.skidmarks if alpha > 1]

        # Actualizar tren elevado
        if self.train_speed == 0.0:
            self.train_timer -= 1
            if self.train_timer <= 0:
                self.train_speed = 18.0
                self.train_y = -800.0
        else:
            self.train_y += self.train_speed
            if self.train_y > self.height + 600:
                self.train_speed = 0.0
                self.train_timer = random.randint(450, 750)

    def draw_ground_and_roads(self, surface, camera):
        """Dibuja la gran red de asfalto, aceras, líneas viales y cruces peatonales visibles en cámara."""
        # Fondo base oscuro
        surface.fill((16, 18, 24))

        cam_rect = pygame.Rect(camera.x, camera.y, camera.viewport_w, camera.viewport_h)

        # 1. Dibujar Bulevares Verticales de Asfalto
        for bx_left, bx_right in self.boulevards_x:
            bw = bx_right - bx_left
            bsx, bsy = camera.apply(bx_left, 0)
            b_rect = pygame.Rect(bsx, bsy, bw, self.height)
            pygame.draw.rect(surface, (20, 22, 28), b_rect)
            # Aceras este/oeste
            pygame.draw.rect(surface, (32, 36, 46), (bsx - 30, bsy, 30, self.height))
            pygame.draw.rect(surface, (32, 36, 46), (bsx + bw, bsy, 30, self.height))

        # 2. Dibujar Grandes Avenidas Horizontales de 4 Carriles
        for ay_top, ay_bot in self.avenues_y:
            ah = ay_bot - ay_top
            asx, asy = camera.apply(0, ay_top)
            a_rect = pygame.Rect(asx, asy, self.width, ah)
            pygame.draw.rect(surface, (20, 22, 28), a_rect)

            # Aceras norte y sur
            pygame.draw.rect(surface, (32, 36, 46), (asx, asy - 30, self.width, 30))
            pygame.draw.rect(surface, (32, 36, 46), (asx, asy + ah, self.width, 30))
            pygame.draw.line(surface, (48, 55, 68), (asx, asy), (asx + self.width, asy), 2)
            pygame.draw.line(surface, (48, 55, 68), (asx, asy + ah), (asx + self.width, asy + ah), 2)

            # Doble línea amarilla continua central
            mid_y = asy + ah // 2
            pygame.draw.line(surface, (235, 195, 45), (asx, mid_y - 3), (asx + self.width, mid_y - 3), 2)
            pygame.draw.line(surface, (235, 195, 45), (asx, mid_y + 3), (asx + self.width, mid_y + 3), 2)

            # Líneas discontinuas de carriles
            lane1 = asy + ah // 4
            lane2 = asy + (ah * 3) // 4
            start_x = int(camera.x // 60) * 60
            for rx in range(start_x, start_x + camera.viewport_w + 120, 60):
                sx1, _ = camera.apply(rx, 0)
                pygame.draw.line(surface, (75, 82, 95), (sx1, lane1), (sx1 + 35, lane1), 2)
                pygame.draw.line(surface, (75, 82, 95), (sx1, lane2), (sx1 + 35, lane2), 2)

        # 3. Pasos de Peatones en las Intersecciones
        for bx_left, bx_right in self.boulevards_x:
            for ay_top, ay_bot in self.avenues_y:
                # Cruce peatonal norte y sur
                for py in [ay_top + 10, ay_bot - 35]:
                    csx, csy = camera.apply(bx_left, py)
                    for px in range(0, bx_right - bx_left, 24):
                        pygame.draw.rect(surface, (170, 180, 195), (csx + px, csy, 16, 25))

        # 4. Bahía de Agua al Sur (Muelles)
        water_sx, water_sy = camera.apply(0, 3080)
        if water_sy < camera.viewport_h:
            water_rect = pygame.Rect(water_sx, water_sy, self.width, 420)
            pygame.draw.rect(surface, (12, 22, 38), water_rect)
            # Borde del muelle con balizas
            pygame.draw.line(surface, (60, 68, 82), (water_sx, water_sy), (water_sx + self.width, water_sy), 4)

        # 5. Marcas de Neumáticos (Skidmarks de derrape)
        for sx, sy, sang, salpha in self.skidmarks:
            ssx, ssy = camera.apply(sx, sy)
            if -40 <= ssx <= camera.viewport_w + 40 and -40 <= ssy <= camera.viewport_h + 40:
                s_surf = pygame.Surface((18, 6), pygame.SRCALPHA)
                pygame.draw.rect(s_surf, (15, 16, 20, min(140, salpha)), (0, 0, 18, 6), border_radius=2)
                rot = pygame.transform.rotate(s_surf, -math.degrees(sang))
                surface.blit(rot, (ssx - rot.get_width() // 2, ssy - rot.get_height() // 2))

    def draw_buildings_and_structures(self, surface, camera):
        """Dibuja las fachadas sólidas de rascacielos, anuncios de neón, vigas del tren y puentes."""
        cam_rect = pygame.Rect(camera.x, camera.y, camera.viewport_w, camera.viewport_h)

        # 1. Dibujar Bloques de Edificios Sólidos
        for idx, block in enumerate(self.building_blocks):
            # Solo dibujar si está visible en la cámara
            if block.colliderect(cam_rect):
                sc = camera.apply_rect(block)

                if block.height > 200:  # Manzana de rascacielos
                    # Fachada
                    pygame.draw.rect(surface, (22, 26, 36), sc, border_radius=4)
                    pygame.draw.rect(surface, (12, 14, 20), sc, width=3, border_radius=4)

                    # Ventanas iluminadas
                    step = 42
                    for wx in range(sc.left + 24, sc.right - 24, step):
                        for wy in range(sc.top + 28, sc.bottom - 28, step):
                            is_lit = (wx * 7 + wy * 13 + idx) % 5 == 0
                            w_col = (255, 230, 130, 190) if is_lit else (35, 42, 58, 140)
                            pygame.draw.rect(surface, w_col, (wx, wy, 20, 24), border_radius=2)

                    # Anuncios gigantes de neón en fachadas clave
                    font = pygame.font.SysFont("Impact", 18)
                    if idx == 0:
                        txt = font.render("HOTEL & CASINO KUROSHIO", True, (245, 50, 75))
                        surface.blit(txt, (sc.left + 30, sc.bottom - 36))
                    elif idx == 2:
                        txt = font.render("CYBER-GEAR AUTO TUNING", True, (40, 220, 245))
                        surface.blit(txt, (sc.left + 30, sc.bottom - 36))
                    elif idx == 6:
                        txt = font.render("SYNTH-CLUB 404 & VIP LOUNGE", True, (190, 50, 240))
                        surface.blit(txt, (sc.left + 30, sc.bottom - 36))
                    elif idx == 10:
                        txt = font.render("ALMACENES DE CARGA BAHÍA", True, (245, 205, 50))
                        surface.blit(txt, (sc.left + 30, sc.bottom - 36))

                else:
                    # Pilar de hormigón
                    pygame.draw.rect(surface, (45, 52, 65), sc, border_radius=3)
                    pygame.draw.rect(surface, (25, 28, 35), sc, width=2, border_radius=3)

        # 2. Estructura de las Vías Elevadas del Tren (Eje X = 2500)
        track_x = 2500
        bridge_sx = track_x - 120 - int(camera.x)
        if -280 <= bridge_sx <= camera.viewport_w:
            # Vigas metálicas superiores que cruzan toda la ciudad norte a sur
            viga_surf = pygame.Surface((240, camera.viewport_h), pygame.SRCALPHA)
            # Vigas transversales
            for cy in range(0, camera.viewport_h, 80):
                pygame.draw.rect(viga_surf, (42, 48, 62, 180), (10, cy, 220, 18))
                pygame.draw.line(viga_surf, (60, 68, 85, 140), (15, cy), (225, cy + 70), 3)
                pygame.draw.line(viga_surf, (60, 68, 85, 140), (225, cy), (15, cy + 70), 3)
            # Rieles de acero
            pygame.draw.rect(viga_surf, (25, 28, 36), (40, 0, 16, camera.viewport_h))
            pygame.draw.rect(viga_surf, (25, 28, 36), (184, 0, 16, camera.viewport_h))
            surface.blit(viga_surf, (bridge_sx, 0))

        # 3. Metro Nocturno pasando por las vías elevadas
        if self.train_speed > 0:
            tsx = track_x - 70 - int(camera.x)
            tsy = int(self.train_y - camera.y)
            for v_idx in range(5):
                v_rect = pygame.Rect(tsx, tsy + v_idx * 160, 140, 145)
                if -200 <= v_rect.y <= camera.viewport_h + 200:
                    pygame.draw.rect(surface, (185, 35, 45), v_rect, border_radius=6)
                    pygame.draw.rect(surface, (245, 245, 250), v_rect, width=2, border_radius=6)
                    # Ventanas del metro con siluetas
                    for wy in range(v_rect.top + 18, v_rect.bottom - 18, 30):
                        pygame.draw.rect(surface, (255, 240, 160), (v_rect.left + 15, wy, v_rect.width - 30, 18), border_radius=2)
