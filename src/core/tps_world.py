import math
import random
import pygame
from src.config import WIDTH, HEIGHT

def clip_polygon_near_plane(cam_pts, near=16.0):
    """Recorta un polígono en espacio de cámara contra el plano Z >= near (Sutherland-Hodgman)."""
    if not cam_pts:
        return []
    out = []
    n = len(cam_pts)
    for i in range(n):
        p1 = cam_pts[i]
        p2 = cam_pts[(i + 1) % n]
        in1 = p1[2] >= near
        in2 = p2[2] >= near

        if in1 and in2:
            out.append(p2)
        elif in1 and not in2:
            t = (near - p1[2]) / (p2[2] - p1[2])
            out.append((p1[0] + t * (p2[0] - p1[0]), p1[1] + t * (p2[1] - p1[1]), near))
        elif not in1 and in2:
            t = (near - p1[2]) / (p2[2] - p1[2])
            out.append((p1[0] + t * (p2[0] - p1[0]), p1[1] + t * (p2[1] - p1[1]), near))
            out.append(p2)
    return out


class Camera3D:
    """Cámara en tercera persona 3D detrás del personaje/auto con perspectiva hacia el horizonte."""
    def __init__(self):
        self.cam_x = 0.0
        self.cam_y = 88.0
        self.cam_z = 0.0
        self.cam_yaw = 0.0
        self.focal_length = 480.0
        self.horizon_y = 235.0
        self.near_plane = 16.0

        # Vectores cacheados por fotograma
        self.fx = 1.0
        self.fz = 0.0
        self.rx = 0.0
        self.rz = 1.0

    def update_behind(self, target_x, target_y, target_z, target_yaw, dist=155.0, height=85.0, lerp=0.14):
        # Suavizado angular
        diff = (target_yaw - self.cam_yaw + math.pi) % (2 * math.pi) - math.pi
        self.cam_yaw += diff * 0.16

        self.fx = math.cos(self.cam_yaw)
        self.fz = math.sin(self.cam_yaw)
        self.rx = -self.fz
        self.rz = self.fx

        desired_x = target_x - self.fx * dist
        desired_z = target_z - self.fz * dist
        desired_y = target_y + height

        self.cam_x += (desired_x - self.cam_x) * lerp
        self.cam_z += (desired_z - self.cam_z) * lerp
        self.cam_y += (desired_y - self.cam_y) * lerp

    def to_camera_space(self, wx, wy, wz):
        dx = wx - self.cam_x
        dy = wy - self.cam_y
        dz = wz - self.cam_z
        cx = dx * self.rx + dz * self.rz
        cy = dy
        cz = dx * self.fx + dz * self.fz
        return (cx, cy, cz)

    def project(self, wx, wy, wz):
        cx, cy, cz = self.to_camera_space(wx, wy, wz)
        if cz <= self.near_plane:
            return None
        scale = self.focal_length / cz
        sx = int(WIDTH * 0.5 + cx * scale)
        sy = int(self.horizon_y - cy * scale)
        return (sx, sy, scale)

    def project_cam_pt(self, cx, cy, cz):
        scale = self.focal_length / cz
        sx = int(WIDTH * 0.5 + cx * scale)
        sy = int(self.horizon_y - cy * scale)
        return (sx, sy)

    def draw_quad_3d(self, surface, world_pts, color, border_color=None):
        cam_pts = [self.to_camera_space(*p) for p in world_pts]
        # Descartar rápido si todos detrás de la cámara o muy lejos
        if all(p[2] < self.near_plane for p in cam_pts):
            return
        clipped = clip_polygon_near_plane(cam_pts, self.near_plane)
        if len(clipped) < 3:
            return
        scr_pts = [self.project_cam_pt(*p) for p in clipped]
        pygame.draw.polygon(surface, color, scr_pts)
        if border_color:
            pygame.draw.polygon(surface, border_color, scr_pts, 1)


class TPSCityWorld:
    """Ciudad masiva en 3D (5000x5000) con carreteras, aceras, edificios sólidos, farolas y puente de tren."""
    def __init__(self):
        self.width = 5000
        self.depth = 5000

        # Avenidas principales (Centros y anchura)
        self.avenues_z = [900, 2500, 4100]
        self.boulevards_x = [900, 2500, 4100]
        self.road_half_w = 150  # Carretera de 300 unidades de ancho + aceras de 60

        self.building_blocks = []  # Lista de dicts con rect y altura 3D
        self.streetlamps = []      # Postes de luz con resplandor cálido
        self.ladders = []          # Escaleras de incendio para subir a las azoteas
        self._build_city_geometry()

        # Cielo pre-renderizado gradiente estilo atardecer dorado/crepúsculo GTA
        self.sky_surf = self._create_sky_surface()

        # Tren elevado
        self.train_x = -800.0
        self.train_speed = 16.0

    def _create_sky_surface(self):
        surf = pygame.Surface((WIDTH, 245))
        for y in range(245):
            t = y / 245.0
            # De azul crepuscular oscuro arriba a naranja dorado cálido en el horizonte (como la foto)
            r = int(32 + t * 185)
            g = int(34 + t * 105)
            b = int(58 + t * 28)
            pygame.draw.line(surf, (r, g, b), (0, y), (WIDTH, y))

        # Silueta de rascacielos lejanos y colinas en el horizonte
        rng = random.Random(42)
        for bx in range(0, WIDTH, 28):
            bh = rng.randint(15, 75)
            bw = rng.randint(20, 36)
            pygame.draw.rect(surf, (42, 38, 46), (bx, 245 - bh, bw, bh))
        return surf

    def _build_city_geometry(self):
        # Construir manzanas entre las avenidas (4x4 bloques de edificios sólidos)
        z_ranges = [(80, 680), (1120, 2280), (2720, 3880), (4320, 4920)]
        x_ranges = [(80, 680), (1120, 2280), (2720, 3880), (4320, 4920)]

        rng = random.Random(101)
        for zr in z_ranges:
            for xr in x_ranges:
                rx, rz = xr[0], zr[0]
                rw, rd = xr[1] - xr[0], zr[1] - zr[0]
                bh = rng.randint(240, 420)
                rect = pygame.Rect(rx, rz, rw, rd)

                # Color arquitectónico variado
                wall_col = rng.choice([(36, 38, 46), (48, 42, 42), (32, 42, 52), (44, 46, 54)])
                label = ""
                if rx == 2720 and rz == 1120:
                    label = "CYBER-GEAR TALLER"
                    bh = 220
                elif rx == 1120 and rz == 1120:
                    label = "HOTEL KUROSHIO"
                    bh = 380
                elif rx == 2720 and rz == 2720:
                    label = "SYNTH-CLUB 404"

                self.building_blocks.append({
                    "rect": rect,
                    "height": bh,
                    "color": wall_col,
                    "label": label
                })

        # Farolas a lo largo de las avenidas principales
        for az in self.avenues_z:
            for lx in range(200, 4800, 380):
                # Evitar poner farolas en medio de las intersecciones
                if any(abs(lx - bx) < 220 for bx in self.boulevards_x):
                    continue
                self.streetlamps.append((lx, az - self.road_half_w - 20))
                self.streetlamps.append((lx, az + self.road_half_w + 20))

        for bx in self.boulevards_x:
            for lz in range(200, 4800, 380):
                if any(abs(lz - az) < 220 for az in self.avenues_z):
                    continue
                self.streetlamps.append((bx - self.road_half_w - 20, lz))
                self.streetlamps.append((bx + self.road_half_w + 20, lz))

    def get_building_rects(self):
        return [b["rect"] for b in self.building_blocks]

    def check_collision(self, wx, wz, radius=18):
        if wx - radius < 30 or wx + radius > self.width - 30:
            return True
        if wz - radius < 30 or wz + radius > self.depth - 30:
            return True
        test = pygame.Rect(wx - radius, wz - radius, radius * 2, radius * 2)
        for b in self.building_blocks:
            if b["rect"].colliderect(test):
                return True
        return False

    def resolve_movement(self, old_x, old_z, new_x, new_z, radius=18):
        if not self.check_collision(new_x, new_z, radius):
            return new_x, new_z
        if not self.check_collision(new_x, old_z, radius):
            return new_x, old_z
        if not self.check_collision(old_x, new_z, radius):
            return old_x, new_z
        return old_x, old_z

    def get_rooftop_height_at(self, wx, wz):
        for b in self.building_blocks:
            if b["rect"].collidepoint(wx, wz):
                return b["height"]
        return 0.0

    def get_nearest_building(self, wx, wz):
        best_b = None
        best_d = float("inf")
        for b in self.building_blocks:
            r = b["rect"]
            cx = max(r.left, min(wx, r.right))
            cz = max(r.top, min(wz, r.bottom))
            d = math.hypot(wx - cx, wz - cz)
            if d < best_d:
                best_d = d
                best_b = b
        return best_b

    def update(self):
        self.train_x += self.train_speed
        if self.train_x > self.width + 800:
            self.train_x = -800.0

    def draw_environment(self, surface, camera):
        """Dibuja el cielo crepuscular, suelo, carreteras 3D en perspectiva, aceras, edificios y tren."""
        # 1. Cielo hacia el horizonte
        surface.blit(self.sky_surf, (0, 0))

        # 2. Suelo base debajo del horizonte (Tierra/acera oscura)
        pygame.draw.rect(surface, (28, 30, 36), (0, int(camera.horizon_y), WIDTH, HEIGHT - int(camera.horizon_y)))

        # 3. Proyectar segmentos de carreteras y aceras cercanos al jugador (optimizado)
        cam_x, cam_z = camera.cam_x, camera.cam_z
        view_dist = 2400.0
        seg_len = 220

        # Avenidas Horizontales (Eje X)
        for az in self.avenues_z:
            if abs(az - cam_z) > view_dist + 400:
                continue
            start_x = max(0, int((cam_x - view_dist) // seg_len) * seg_len)
            end_x = min(self.width, int((cam_x + view_dist) // seg_len + 2) * seg_len)
            for x in range(start_x, end_x, seg_len):
                x2 = x + seg_len
                # Acera Norte y Sur
                camera.draw_quad_3d(surface, [
                    (x, 0, az - self.road_half_w - 55), (x2, 0, az - self.road_half_w - 55),
                    (x2, 0, az + self.road_half_w + 55), (x, 0, az + self.road_half_w + 55)
                ], (48, 52, 60))
                # Asfalto principal
                camera.draw_quad_3d(surface, [
                    (x, 0.5, az - self.road_half_w), (x2, 0.5, az - self.road_half_w),
                    (x2, 0.5, az + self.road_half_w), (x, 0.5, az + self.road_half_w)
                ], (32, 34, 40))
                # Doble línea amarilla central
                camera.draw_quad_3d(surface, [
                    (x, 1.0, az - 4), (x2, 1.0, az - 4),
                    (x2, 1.0, az + 4), (x, 1.0, az + 4)
                ], (235, 190, 45))
                # Líneas blancas discontinuas de carriles
                camera.draw_quad_3d(surface, [
                    (x + 40, 1.0, az - 75), (x + 130, 1.0, az - 75),
                    (x + 130, 1.0, az - 71), (x + 40, 1.0, az - 71)
                ], (155, 165, 180))
                camera.draw_quad_3d(surface, [
                    (x + 40, 1.0, az + 71), (x + 130, 1.0, az + 71),
                    (x + 130, 1.0, az + 75), (x + 40, 1.0, az + 75)
                ], (155, 165, 180))

        # Bulevares Verticales (Eje Z)
        for bx in self.boulevards_x:
            if abs(bx - cam_x) > view_dist + 400:
                continue
            start_z = max(0, int((cam_z - view_dist) // seg_len) * seg_len)
            end_z = min(self.depth, int((cam_z + view_dist) // seg_len + 2) * seg_len)
            for z in range(start_z, end_z, seg_len):
                z2 = z + seg_len
                camera.draw_quad_3d(surface, [
                    (bx - self.road_half_w - 55, 0, z), (bx + self.road_half_w + 55, 0, z),
                    (bx + self.road_half_w + 55, 0, z2), (bx - self.road_half_w - 55, 0, z2)
                ], (48, 52, 60))
                camera.draw_quad_3d(surface, [
                    (bx - self.road_half_w, 0.6, z), (bx + self.road_half_w, 0.6, z),
                    (bx + self.road_half_w, 0.6, z2), (bx - self.road_half_w, 0.6, z2)
                ], (32, 34, 40))
                camera.draw_quad_3d(surface, [
                    (bx - 4, 1.1, z), (bx + 4, 1.1, z),
                    (bx + 4, 1.1, z2), (bx - 4, 1.1, z2)
                ], (235, 190, 45))
                camera.draw_quad_3d(surface, [
                    (bx - 75, 1.1, z + 40), (bx - 71, 1.1, z + 40),
                    (bx - 71, 1.1, z + 130), (bx - 75, 1.1, z + 130)
                ], (155, 165, 180))
                camera.draw_quad_3d(surface, [
                    (bx + 71, 1.1, z + 40), (bx + 75, 1.1, z + 40),
                    (bx + 75, 1.1, z + 130), (bx + 71, 1.1, z + 130)
                ], (155, 165, 180))

        # 4. Vías Elevadas del Tren cruzando sobre la Avenida Central (Z = 2500)
        if abs(2500 - cam_z) < 2200:
            for tx in range(max(0, int(cam_x - 1800)), min(self.width, int(cam_x + 1800)), 300):
                # Puente metálico elevado a altura wy = 190
                camera.draw_quad_3d(surface, [
                    (tx, 185, 2410), (tx + 300, 185, 2410),
                    (tx + 300, 185, 2590), (tx, 185, 2590)
                ], (26, 30, 38), (15, 18, 22))
                # Vigas laterales del puente
                camera.draw_quad_3d(surface, [
                    (tx, 185, 2410), (tx + 300, 185, 2410),
                    (tx + 300, 210, 2410), (tx, 210, 2410)
                ], (45, 52, 65))
                # Pilares de soporte en aceras
                if tx % 600 == 0:
                    camera.draw_quad_3d(surface, [
                        (tx - 15, 0, 2380), (tx + 15, 0, 2380),
                        (tx + 15, 185, 2380), (tx - 15, 185, 2380)
                    ], (55, 62, 74))

            # Metro pasando sobre las vías
            for v_idx in range(4):
                vx1 = self.train_x + v_idx * 210
                vx2 = vx1 + 190
                if abs(vx1 - cam_x) < 2200:
                    camera.draw_quad_3d(surface, [
                        (vx1, 200, 2430), (vx2, 200, 2430),
                        (vx2, 265, 2430), (vx1, 265, 2430)
                    ], (185, 38, 48), (240, 240, 245))

        # 5. Dibujar Edificios Sólidos 3D ordenados del más lejano al más cercano (Painter's Algorithm)
        visible_buildings = []
        for b in self.building_blocks:
            r = b["rect"]
            bcx, bcz = r.centerx, r.centery
            dist = math.hypot(bcx - cam_x, bcz - cam_z)
            if dist < 2600:
                visible_buildings.append((dist, b))

        visible_buildings.sort(key=lambda item: -item[0])

        for _, b in visible_buildings:
            self._draw_building_3d(surface, camera, b)

        # 6. Farolas con resplandor cálido en las aceras
        for lx, lz in self.streetlamps:
            if math.hypot(lx - cam_x, lz - cam_z) < 1600:
                proj_base = camera.project(lx, 0, lz)
                proj_top = camera.project(lx, 125, lz)
                if proj_base and proj_top:
                    bx, by, sc = proj_base
                    tx, ty, _ = proj_top
                    pygame.draw.line(surface, (45, 50, 60), (bx, by), (tx, ty), max(2, min(8, int(3 * sc))))
                    # Luminaria cálida estilo farola de atardecer
                    l_rad = max(4, min(48, int(18 * sc)))
                    glow = pygame.Surface((l_rad * 4, l_rad * 4), pygame.SRCALPHA)
                    pygame.draw.circle(glow, (255, 165, 60, 110), (l_rad * 2, l_rad * 2), l_rad * 2)
                    pygame.draw.circle(glow, (255, 240, 180, 220), (l_rad * 2, l_rad * 2), max(2, l_rad // 2))
                    surface.blit(glow, (tx - l_rad * 2, ty - l_rad * 2), special_flags=pygame.BLEND_RGBA_ADD)

                    # Charco de luz en la acera bajo la farola
                    g_rad = max(4, min(65, int(26 * sc)))
                    g_surf = pygame.Surface((g_rad * 2, g_rad), pygame.SRCALPHA)
                    pygame.draw.ellipse(g_surf, (255, 155, 50, 48), (0, 0, g_rad * 2, g_rad))
                    surface.blit(g_surf, (bx - g_rad, by - g_rad // 2), special_flags=pygame.BLEND_RGBA_ADD)

    def _draw_building_3d(self, surface, camera, b):
        r = b["rect"]
        h = b["height"]
        col = b["color"]
        shade_col = (max(8, col[0] - 12), max(8, col[1] - 12), max(10, col[2] - 12))
        roof_col = (24, 26, 34)
        win_col = (240, 210, 130)

        x1, z1 = r.left, r.top
        x2, z2 = r.right, r.bottom
        cam_x, cam_z = camera.cam_x, camera.cam_z

        # Dibujar caras visibles hacia la cámara y bandas horizontales de ventanas iluminadas
        # Cara Norte (Z = z1)
        if cam_z < z1:
            camera.draw_quad_3d(surface, [(x1, 0, z1), (x2, 0, z1), (x2, h, z1), (x1, h, z1)], col, (15, 17, 22))
            for wy in range(45, h - 25, 42):
                camera.draw_quad_3d(surface, [(x1 + 25, wy, z1 - 0.5), (x2 - 25, wy, z1 - 0.5), (x2 - 25, wy + 12, z1 - 0.5), (x1 + 25, wy + 12, z1 - 0.5)], win_col)
        # Cara Sur (Z = z2)
        if cam_z > z2:
            camera.draw_quad_3d(surface, [(x1, 0, z2), (x2, 0, z2), (x2, h, z2), (x1, h, z2)], col, (15, 17, 22))
            for wy in range(45, h - 25, 42):
                camera.draw_quad_3d(surface, [(x1 + 25, wy, z2 + 0.5), (x2 - 25, wy, z2 + 0.5), (x2 - 25, wy + 12, z2 + 0.5), (x1 + 25, wy + 12, z2 + 0.5)], win_col)
        # Cara Oeste (X = x1)
        if cam_x < x1:
            camera.draw_quad_3d(surface, [(x1, 0, z1), (x1, 0, z2), (x1, h, z2), (x1, h, z1)], shade_col, (15, 17, 22))
            for wy in range(45, h - 25, 42):
                camera.draw_quad_3d(surface, [(x1 - 0.5, wy, z1 + 25), (x1 - 0.5, wy, z2 - 25), (x1 - 0.5, wy + 12, z2 - 25), (x1 - 0.5, wy + 12, z1 + 25)], (190, 165, 95))
        # Cara Este (X = x2)
        if cam_x > x2:
            camera.draw_quad_3d(surface, [(x2, 0, z1), (x2, 0, z2), (x2, h, z2), (x2, h, z1)], shade_col, (15, 17, 22))
            for wy in range(45, h - 25, 42):
                camera.draw_quad_3d(surface, [(x2 + 0.5, wy, z1 + 25), (x2 + 0.5, wy, z2 - 25), (x2 + 0.5, wy + 12, z2 - 25), (x2 + 0.5, wy + 12, z1 + 25)], (190, 165, 95))

        # Techo del edificio si la cámara está más alta (ej. en la azotea)
        if camera.cam_y > h:
            camera.draw_quad_3d(surface, [(x1, h, z1), (x2, h, z1), (x2, h, z2), (x1, h, z2)], roof_col, (40, 46, 58))

        # Cartel de neón si tiene etiqueta
        if b["label"]:
            proj = camera.project(r.centerx, h * 0.5, z1 if cam_z < z1 else z2)
            if proj:
                sx, sy, sc = proj
                if sc > 0.2:
                    fsize = max(10, min(28, int(24 * sc)))
                    font = pygame.font.SysFont("Impact", fsize)
                    txt = font.render(b["label"], True, (40, 225, 245))
                    surface.blit(txt, (sx - txt.get_width() // 2, sy - txt.get_height() // 2))
