import os
import pygame
from src.config import (
    COLOR_NEON_RED, COLOR_NEON_CYAN, COLOR_NEON_PURPLE,
    COLOR_WHITE, COLOR_TEXT_DIM, COLOR_GOLD, COLOR_DARK_BG,
    get_font, get_asset_path
)

class Button:
    def __init__(self, x, y, width, height, text, font_size=20, accent_color=COLOR_NEON_RED):
        self.rect = pygame.Rect(x, y, width, height)
        self.text = text
        self.font_size = font_size
        self.accent_color = accent_color
        self.is_hovered = False

    def update(self, mouse_pos):
        self.is_hovered = self.rect.collidepoint(mouse_pos)
        return self.is_hovered

    def is_clicked(self, event):
        return event.type == pygame.MOUSEBUTTONDOWN and event.button == 1 and self.is_hovered

    def draw(self, surface):
        font = get_font("title", self.font_size)
        
        # Fondo del botón
        bg_col = (26, 28, 38) if self.is_hovered else (16, 18, 24)
        pygame.draw.rect(surface, bg_col, self.rect, border_radius=4)

        # Borde y resplandor
        border_col = self.accent_color if self.is_hovered else (45, 52, 65)
        border_w = 2 if self.is_hovered else 1
        pygame.draw.rect(surface, border_col, self.rect, width=border_w, border_radius=4)

        # Texto centrado
        txt_col = COLOR_WHITE if self.is_hovered else COLOR_TEXT_DIM
        prefix = "<  " if self.is_hovered else ""
        suffix = "  >" if self.is_hovered else ""
        txt_surf = font.render(f"{prefix}{self.text}{suffix}", True, txt_col)
        tx = self.rect.centerx - txt_surf.get_width() // 2
        ty = self.rect.centery - txt_surf.get_height() // 2
        surface.blit(txt_surf, (tx, ty))


class CharacterCard:
    """Tarjeta interactiva para la pantalla de selección de personajes."""
    _char_images = {}

    def __init__(self, x, y, width, height, char_data):
        self.rect = pygame.Rect(x, y, width, height)
        self.data = char_data
        self.char_id = char_data["id"]
        self.accent_color = char_data["accent_color"]
        self.is_hovered = False
        self.is_selected = False
        self._load_art()

    def _load_art(self):
        if self.char_id not in CharacterCard._char_images:
            path = get_asset_path("char", self.data["image_file"])
            if path and os.path.exists(path):
                raw = pygame.image.load(path).convert_alpha()
                # Escalar para que quepa en la parte superior de la tarjeta
                w, h = raw.get_size()
                target_h = int(self.rect.height * 0.58)
                target_w = int(w * (target_h / h))
                scaled = pygame.transform.smoothscale(raw, (target_w, target_h))
                CharacterCard._char_images[self.char_id] = scaled
            else:
                CharacterCard._char_images[self.char_id] = None

    def update(self, mouse_pos):
        self.is_hovered = self.rect.collidepoint(mouse_pos)
        return self.is_hovered

    def draw(self, surface):
        active = self.is_selected or self.is_hovered
        
        # 1. Fondo de la tarjeta con gradiente / panel oscuro
        bg_col = (20, 24, 34) if active else (14, 16, 22)
        card_surf = pygame.Surface((self.rect.width, self.rect.height), pygame.SRCALPHA)
        pygame.draw.rect(card_surf, (*bg_col, 240), (0, 0, self.rect.width, self.rect.height), border_radius=8)
        
        # 2. Resplandor exterior si está activo
        if active:
            glow_surf = pygame.Surface((self.rect.width + 12, self.rect.height + 12), pygame.SRCALPHA)
            r, g, b = self.accent_color
            pygame.draw.rect(glow_surf, (r, g, b, 70), (0, 0, self.rect.width + 12, self.rect.height + 12), border_radius=12)
            surface.blit(glow_surf, (self.rect.x - 6, self.rect.y - 6), special_flags=pygame.BLEND_RGBA_ADD)

        surface.blit(card_surf, self.rect.topleft)

        # Borde
        border_col = self.accent_color if active else (40, 48, 62)
        border_w = 3 if self.is_selected else (2 if self.is_hovered else 1)
        pygame.draw.rect(surface, border_col, self.rect, width=border_w, border_radius=8)

        # 3. Arte de cuerpo entero
        img = CharacterCard._char_images.get(self.char_id)
        if img:
            ix = self.rect.centerx - img.get_width() // 2
            iy = self.rect.y + 12
            surface.blit(img, (ix, iy))

        # 4. Información de Personaje
        info_y = self.rect.y + int(self.rect.height * 0.59)
        
        # Divisor
        pygame.draw.line(surface, border_col, (self.rect.x + 15, info_y), (self.rect.right - 15, info_y), 1)

        # Nombre y Título
        font_name = get_font("title", 24)
        name_surf = font_name.render(self.data["name"], True, COLOR_WHITE)
        surface.blit(name_surf, (self.rect.x + 20, info_y + 8))

        font_sub = get_font("hud", 11, bold=True)
        sub_surf = font_sub.render(self.data["title"], True, self.accent_color)
        surface.blit(sub_surf, (self.rect.x + 20, info_y + 34))

        # Arma principal
        font_weap = get_font("hud", 10, bold=False)
        w_surf = font_weap.render(f"Arma: {self.data['weapon_name']}", True, COLOR_GOLD)
        surface.blit(w_surf, (self.rect.x + 20, info_y + 54))

        # Estadísticas en estrellas
        stats_y = info_y + 74
        for idx, (stat_name, val) in enumerate(self.data["stats"].items()):
            sy = stats_y + idx * 16
            st_txt = font_weap.render(f"{stat_name}:", True, COLOR_TEXT_DIM)
            surface.blit(st_txt, (self.rect.x + 20, sy))

            # Puntos / barras de estadística
            for dot in range(5):
                d_rect = pygame.Rect(self.rect.x + 95 + dot * 14, sy + 3, 10, 8)
                if dot < val:
                    pygame.draw.rect(surface, self.accent_color, d_rect, border_radius=1)
                else:
                    pygame.draw.rect(surface, (30, 35, 45), d_rect, border_radius=1)

        # Badge "SELECCIONADO"
        if self.is_selected:
            badge_rect = pygame.Rect(self.rect.centerx - 65, self.rect.bottom - 34, 130, 22)
            pygame.draw.rect(surface, self.accent_color, badge_rect, border_radius=4)
            badge_font = get_font("title", 13)
            b_txt = badge_font.render("✓ SELECCIONADO", True, (10, 12, 16))
            surface.blit(b_txt, (badge_rect.centerx - b_txt.get_width() // 2, badge_rect.centery - b_txt.get_height() // 2))
