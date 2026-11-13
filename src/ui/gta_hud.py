import math
import pygame
from src.config import WIDTH, HEIGHT, COLOR_WHITE, COLOR_GOLD, COLOR_NEON_RED, COLOR_NEON_CYAN, get_font

class GTAHud:
    """Interfaz gráfica auténtica estilo GTA San Andreas (Radar circular, caja de arma, vida, dinero y subtítulos)."""
    def __init__(self):
        self.radar_radius = 60
        self.radar_cx = 86
        self.radar_cy = HEIGHT - 86

    def draw(self, surface, player, cash, active_weapon, target_pos, subtitle_text, city_map):
        self._draw_circular_radar(surface, player, target_pos, city_map)
        self._draw_top_right_stats(surface, player, cash, active_weapon)
        if subtitle_text:
            self._draw_subtitle_box(surface, subtitle_text)

    def _draw_circular_radar(self, surface, player, target_pos, city_map):
        r = self.radar_radius
        cx, cy = self.radar_cx, self.radar_cy

        # 1. Crear superficie con máscara circular para el mapa
        radar_surf = pygame.Surface((r * 2, r * 2), pygame.SRCALPHA)
        pygame.draw.circle(radar_surf, (22, 28, 36, 225), (r, r), r)

        # Escala del radar (1 px radar = 16 unidades mundo)
        map_scale = 0.06
        cos_y = math.cos(-player.yaw - math.pi / 2)
        sin_y = math.sin(-player.yaw - math.pi / 2)

        def world_to_radar(wx, wz):
            dx = (wx - player.wx) * map_scale
            dz = (wz - player.wz) * map_scale
            rx = dx * cos_y - dz * sin_y
            ry = dx * sin_y + dz * cos_y
            return int(r + rx), int(r + ry)

        # Dibujar bloques de edificios en el radar
        for b in city_map.building_blocks:
            rect = b["rect"] if isinstance(b, dict) else b
            bh = b.get("height", 200) if isinstance(b, dict) else rect.height
            pts = [
                world_to_radar(rect.left, rect.top),
                world_to_radar(rect.right, rect.top),
                world_to_radar(rect.right, rect.bottom),
                world_to_radar(rect.left, rect.bottom)
            ]
            # Comprobar si el polígono intersecta el área del radar
            min_px = min(p[0] for p in pts)
            max_px = max(p[0] for p in pts)
            min_py = min(p[1] for p in pts)
            max_py = max(p[1] for p in pts)
            if max_px >= 0 and min_px <= r * 2 and max_py >= 0 and min_py <= r * 2:
                col = (35, 75, 45) if bh > 260 else (45, 52, 65)
                pygame.draw.polygon(radar_surf, col, pts)

        # Baliza GPS del objetivo en el radar
        if target_pos:
            tx, tz = target_pos
            gx, gy = world_to_radar(tx, tz)
            # Limitar al borde del círculo para que actúe como brújula GPS
            dist_c = math.hypot(gx - r, gy - r)
            if dist_c > r - 8:
                ang = math.atan2(gy - r, gx - r)
                gx = int(r + math.cos(ang) * (r - 8))
                gy = int(r + math.sin(ang) * (r - 8))
            pygame.draw.rect(radar_surf, COLOR_GOLD, (gx - 4, gy - 4, 8, 8))
            pygame.draw.rect(radar_surf, (10, 10, 12), (gx - 4, gy - 4, 8, 8), width=1)

        # Aplicar máscara circular estricta usando superficie auxiliar
        mask_surf = pygame.Surface((r * 2, r * 2), pygame.SRCALPHA)
        pygame.draw.circle(mask_surf, (255, 255, 255, 255), (r, r), r)
        radar_surf.blit(mask_surf, (0, 0), special_flags=pygame.BLEND_RGBA_MIN)

        surface.blit(radar_surf, (cx - r, cy - r))

        # 2. Aro exterior azul/rojo estilo GTA
        pygame.draw.circle(surface, (15, 18, 22), (cx, cy), r + 3, width=5)
        # Arco de salud (rojo/rosa izquierda) y armadura (cian derecha)
        rect_arc = pygame.Rect(cx - r - 2, cy - r - 2, (r + 2) * 2, (r + 2) * 2)
        hp_ang = math.pi * max(0.0, player.health / player.max_health)
        pygame.draw.arc(surface, (235, 65, 75), rect_arc, math.pi / 2, math.pi / 2 + hp_ang, width=3)
        pygame.draw.arc(surface, (65, 195, 245), rect_arc, -math.pi / 2, math.pi / 2, width=3)

        # 3. Flecha del Jugador en el centro apuntando arriba
        pygame.draw.polygon(surface, COLOR_WHITE, [
            (cx, cy - 8), (cx - 6, cy + 6), (cx, cy + 3), (cx + 6, cy + 6)
        ])
        pygame.draw.polygon(surface, (10, 12, 16), [
            (cx, cy - 8), (cx - 6, cy + 6), (cx, cy + 3), (cx + 6, cy + 6)
        ], width=1)

        # 4. Letra "N" del Norte rotando según player.yaw
        n_ang = -player.yaw - math.pi / 2 - math.pi / 2
        nx = cx + int(math.cos(n_ang) * (r + 3))
        ny = cy + int(math.sin(n_ang) * (r + 3))
        pygame.draw.circle(surface, (15, 15, 18), (nx, ny), 9)
        pygame.draw.circle(surface, (220, 45, 55), (nx, ny), 9, width=1)
        f_n = get_font("hud", 10, bold=True)
        ntxt = f_n.render("N", True, COLOR_WHITE)
        surface.blit(ntxt, (nx - ntxt.get_width() // 2, ny - ntxt.get_height() // 2))

    def _draw_top_right_stats(self, surface, player, cash, weapon):
        # 1. Caja del Arma Actual (Esquina Superior Derecha)
        box_w, box_h = 110, 68
        box_x = WIDTH - box_w - 20
        box_y = 18

        panel = pygame.Surface((box_w, box_h), pygame.SRCALPHA)
        pygame.draw.rect(panel, (15, 18, 22, 185), (0, 0, box_w, box_h), border_radius=4)
        surface.blit(panel, (box_x, box_y))
        pygame.draw.rect(surface, (45, 52, 65), (box_x, box_y, box_w, box_h), width=2, border_radius=4)

        # Dibujo vectorial del icono del arma
        self._draw_weapon_icon(surface, weapon.id, box_x + box_w // 2, box_y + 26)

        # Contador de munición estilo 30 / 90
        f_ammo = get_font("hud", 12, bold=True)
        if weapon.is_melee:
            ammo_str = "PUÑOS [1]"
        else:
            ammo_str = f"{weapon.ammo_in_clip} / {weapon.ammo_reserve}"
        atxt = f_ammo.render(ammo_str, True, COLOR_WHITE)
        surface.blit(atxt, (box_x + box_w // 2 - atxt.get_width() // 2, box_y + box_h - 19))

        # 2. Barra de Salud (Debajo de la caja de arma)
        bar_w, bar_h = 110, 10
        bar_x = box_x
        bar_y = box_y + box_h + 6
        pygame.draw.rect(surface, (15, 15, 18), (bar_x, bar_y, bar_w, bar_h))
        hp_w = max(0, int((bar_w - 2) * (player.health / player.max_health)))
        pygame.draw.rect(surface, (205, 35, 45), (bar_x + 1, bar_y + 1, hp_w, bar_h - 2))
        pygame.draw.rect(surface, (220, 220, 230), (bar_x, bar_y, bar_w, bar_h), width=1)

        # 3. Contador de Dinero Verde GTA ($00000350)
        f_cash = get_font("title", 28)
        cash_str = f"${cash:08d}"
        shadow_txt = f_cash.render(cash_str, True, (5, 10, 5))
        cash_txt = f_cash.render(cash_str, True, (65, 185, 75))
        cx = WIDTH - cash_txt.get_width() - 20
        cy = bar_y + 14
        surface.blit(shadow_txt, (cx + 2, cy + 2))
        surface.blit(cash_txt, (cx, cy))

        # 4. Mini Selector de Inventario [1-5] discreto a la izquierda del icono
        f_slot = get_font("mono", 10, bold=True)
        slots_txt = f"[{weapon.slot}] {weapon.name}"
        st_surf = f_slot.render(slots_txt, True, COLOR_GOLD)
        surface.blit(st_surf, (box_x - st_surf.get_width() - 10, box_y + 6))

    def _draw_weapon_icon(self, surface, weapon_id, cx, cy):
        col = (210, 215, 225)
        dark = (35, 40, 48)
        if weapon_id == "fists":
            pygame.draw.rect(surface, (215, 175, 145), (cx - 12, cy - 10, 24, 20), border_radius=5)
            pygame.draw.line(surface, (20, 20, 24), (cx - 12, cy), (cx + 12, cy), 2)
        elif weapon_id == "pistol":
            pygame.draw.rect(surface, col, (cx - 12, cy - 8, 26, 7), border_radius=1)
            pygame.draw.rect(surface, dark, (cx - 12, cy - 1, 9, 14), border_radius=1)
        elif weapon_id == "smg":
            pygame.draw.rect(surface, col, (cx - 18, cy - 8, 36, 9), border_radius=2)
            pygame.draw.rect(surface, dark, (cx - 4, cy + 1, 6, 15))
            pygame.draw.rect(surface, dark, (cx - 16, cy + 1, 6, 11))
        elif weapon_id == "m4":
            # Silueta de Fusil de Asalto M4
            pygame.draw.line(surface, col, (cx - 32, cy), (cx + 34, cy), 4)
            pygame.draw.rect(surface, col, (cx - 12, cy - 6, 22, 6))  # Asa de transporte
            pygame.draw.polygon(surface, dark, [(cx - 34, cy - 2), (cx - 20, cy - 2), (cx - 22, cy + 9), (cx - 34, cy + 9)])  # Culata
            pygame.draw.line(surface, col, (cx + 2, cy + 2), (cx + 5, cy + 15), 4)  # Cargador curvo
        elif weapon_id == "bazooka":
            # Silueta Lanzacohetes RPG
            pygame.draw.rect(surface, (85, 110, 70), (cx - 30, cy - 5, 54, 10), border_radius=2)
            pygame.draw.polygon(surface, (190, 50, 40), [(cx + 24, cy - 7), (cx + 38, cy), (cx + 24, cy + 7)])  # Ojiva

    def _draw_subtitle_box(self, surface, text):
        font = get_font("hud", 12, bold=True)
        # Ajustar líneas si es texto largo
        words = text.split(" ")
        lines = []
        cur = ""
        for w in words:
            if font.size(cur + w)[0] < 360:
                cur += w + " "
            else:
                lines.append(cur)
                cur = w + " "
        if cur:
            lines.append(cur)

        box_w = 390
        box_h = 18 + len(lines) * 18
        box = pygame.Rect(24, 20, box_w, box_h)

        bg = pygame.Surface((box_w, box_h), pygame.SRCALPHA)
        pygame.draw.rect(bg, (10, 12, 16, 200), (0, 0, box_w, box_h), border_radius=6)
        surface.blit(bg, box.topleft)
        pygame.draw.rect(surface, (55, 62, 78), box, width=1, border_radius=6)

        for idx, line in enumerate(lines):
            ts = font.render(line.strip(), True, COLOR_WHITE)
            surface.blit(ts, (box.x + 12, box.y + 9 + idx * 18))

    def draw_crosshair(self, surface, mouse_pos, is_aiming=False):
        mx, my = mouse_pos
        rad = 10 if is_aiming else 14
        col = (245, 60, 70, 220) if is_aiming else (255, 255, 255, 180)
        csurf = pygame.Surface((36, 36), pygame.SRCALPHA)
        pygame.draw.circle(csurf, col, (18, 18), rad, width=1)
        pygame.draw.circle(csurf, (255, 60, 70, 255), (18, 18), 2)
        surface.blit(csurf, (mx - 18, my - 18))
