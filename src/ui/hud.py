import os
import pygame
from src.config import (
    WIDTH, HEIGHT, COLOR_HUD_BG, COLOR_HUD_BORDER,
    COLOR_WHITE, COLOR_TEXT_DIM, COLOR_HEALTH_RED, COLOR_HEALTH_GREEN,
    COLOR_STAMINA_BLUE, COLOR_GOLD, COLOR_NEON_RED,
    get_font, get_asset_path
)

class GameHUD:
    _portraits = {}

    def __init__(self):
        self._load_portraits()

    def _load_portraits(self):
        for char_id, fname in [("nagumo", "nagumo.png"), ("shado", "shado.png")]:
            if char_id not in GameHUD._portraits:
                surf = pygame.Surface((52, 52), pygame.SRCALPHA)
                path = get_asset_path("char", fname)
                if path and os.path.exists(path):
                    raw = pygame.image.load(path).convert_alpha()
                    w, h = raw.get_size()
                    crop_size = int(w * 0.45)
                    crop_x = (w - crop_size) // 2
                    crop_y = int(h * 0.015)
                    sub = raw.subsurface(pygame.Rect(crop_x, crop_y, crop_size, crop_size))
                    scaled = pygame.transform.smoothscale(sub, (52, 52))
                    surf.blit(scaled, (0, 0))
                else:
                    pygame.draw.rect(surf, (60, 65, 80), (0, 0, 52, 52))
                GameHUD._portraits[char_id] = surf

    def draw(self, surface, player, wave_num, enemies_count):
        # 1. Panel de Jugador (Esquina superior izquierda)
        panel_w, panel_h = 280, 80
        panel_surf = pygame.Surface((panel_w, panel_h), pygame.SRCALPHA)
        pygame.draw.rect(panel_surf, (*COLOR_HUD_BG, 230), (0, 0, panel_w, panel_h), border_radius=6)
        surface.blit(panel_surf, (15, 14))
        pygame.draw.rect(surface, COLOR_HUD_BORDER, (15, 14, panel_w, panel_h), width=2, border_radius=6)

        # Retrato de avatar
        avatar = GameHUD._portraits.get(player.char_id)
        if avatar:
            surface.blit(avatar, (22, 22))
            pygame.draw.rect(surface, player.accent_color, (22, 22, 52, 52), width=2, border_radius=2)

        # Nombre y Rol
        font_title = get_font("title", 18)
        font_sub = get_font("hud", 10, bold=True)
        surface.blit(font_title.render(player.name, True, COLOR_WHITE), (82, 18))
        surface.blit(font_sub.render(player.title, True, player.accent_color), (82, 36))

        # Barra de Vida
        bar_x = 82
        bar_y = 52
        bar_w = 120
        pygame.draw.rect(surface, (30, 32, 40), (bar_x, bar_y, bar_w, 8), border_radius=2)
        hp_ratio = max(0.0, player.health / player.max_health)
        hp_col = COLOR_HEALTH_GREEN if hp_ratio > 0.4 else COLOR_HEALTH_RED
        pygame.draw.rect(surface, hp_col, (bar_x, bar_y, int(bar_w * hp_ratio), 8), border_radius=2)
        
        # Texto HP
        font_num = get_font("mono", 9, bold=True)
        surface.blit(font_num.render(f"{int(player.health)}/{player.max_health}", True, COLOR_WHITE), (bar_x + bar_w + 6, bar_y - 1))

        # Barra de Resistencia / Sigilo
        stamina_y = 64
        pygame.draw.rect(surface, (30, 32, 40), (bar_x, stamina_y, bar_w, 5), border_radius=2)
        st_ratio = max(0.0, player.stamina / player.max_stamina)
        pygame.draw.rect(surface, COLOR_STAMINA_BLUE, (bar_x, stamina_y, int(bar_w * st_ratio), 5), border_radius=2)

        # 2. Panel de Munición y Arma (Abajo a la derecha)
        ammo_w, ammo_h = 220, 52
        ammo_surf = pygame.Surface((ammo_w, ammo_h), pygame.SRCALPHA)
        pygame.draw.rect(ammo_surf, (*COLOR_HUD_BG, 230), (0, 0, ammo_w, ammo_h), border_radius=6)
        surface.blit(ammo_surf, (WIDTH - ammo_w - 15, HEIGHT - ammo_h - 15))
        pygame.draw.rect(surface, COLOR_HUD_BORDER, (WIDTH - ammo_w - 15, HEIGHT - ammo_h - 15, ammo_w, ammo_h), width=2, border_radius=6)

        ammo_font = get_font("title", 20)
        ammo_txt = f"BALAS: {player.ammo}" if player.has_weapon else "SIN MUNICIÓN"
        ammo_col = COLOR_GOLD if player.ammo > 10 else COLOR_NEON_RED
        surface.blit(ammo_font.render(ammo_txt, True, ammo_col), (WIDTH - ammo_w - 3, HEIGHT - ammo_h - 9))
        
        weap_font = get_font("hud", 10, bold=False)
        surface.blit(weap_font.render(player.weapon_name, True, COLOR_TEXT_DIM), (WIDTH - ammo_w - 3, HEIGHT - ammo_h + 16))

        # 3. Panel de Oleada (Esquina superior derecha)
        wave_w, wave_h = 200, 70
        wave_surf = pygame.Surface((wave_w, wave_h), pygame.SRCALPHA)
        pygame.draw.rect(wave_surf, (*COLOR_HUD_BG, 230), (0, 0, wave_w, wave_h), border_radius=6)
        surface.blit(wave_surf, (WIDTH - wave_w - 15, 14))
        pygame.draw.rect(surface, COLOR_HUD_BORDER, (WIDTH - wave_w - 15, 14, wave_w, wave_h), width=2, border_radius=6)

        wave_title = get_font("title", 22)
        surface.blit(wave_title.render(f"OLEADA {wave_num}", True, COLOR_WHITE), (WIDTH - wave_w, 18))

        wave_sub = get_font("hud", 11, bold=True)
        surface.blit(wave_sub.render(f"AMENAZAS ACTIVAS: {enemies_count}", True, COLOR_NEON_RED), (WIDTH - wave_w, 48))

    def draw_crosshair(self, surface, mouse_pos):
        mx, my = mouse_pos
        # Retícula táctica moderna
        col = (255, 60, 70, 200)
        csurf = pygame.Surface((24, 24), pygame.SRCALPHA)
        pygame.draw.circle(csurf, col, (12, 12), 8, width=1)
        pygame.draw.line(csurf, col, (12, 2), (12, 7), 2)
        pygame.draw.line(csurf, col, (12, 17), (12, 22), 2)
        pygame.draw.line(csurf, col, (2, 12), (7, 12), 2)
        pygame.draw.line(csurf, col, (17, 12), (22, 12), 2)
        pygame.draw.circle(csurf, (255, 255, 255), (12, 12), 1)
        surface.blit(csurf, (mx - 12, my - 12))
