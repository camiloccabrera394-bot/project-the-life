import os
import pygame
from src.config import (
    WIDTH, HEIGHT, COLOR_WHITE, COLOR_TEXT_DIM,
    COLOR_NEON_RED, COLOR_NEON_CYAN, COLOR_GOLD,
    OPERATIONS, get_font, get_asset_path
)
from src.ui.components import Button
from src.core.audio import SoundManager

class MissionSelectScene:
    """Tablero de operaciones tácticas: Lista Negra de los asesinos de la madre."""
    def __init__(self, selected_char="nagumo"):
        self.selected_char = selected_char
        self.selected_index = 0
        self.bg_image = None
        self._load_background()

        self.btn_deploy = Button(WIDTH // 2 - 130, HEIGHT - 55, 260, 36, "INICIAR OPERACIÓN", font_size=20, accent_color=COLOR_NEON_RED)
        self.btn_back = Button(30, HEIGHT - 55, 120, 36, "VOLVER", font_size=16, accent_color=COLOR_TEXT_DIM)

    def _load_background(self):
        path = get_asset_path("bg", "select_bg.jpg")
        if path and os.path.exists(path):
            raw = pygame.image.load(path).convert()
            self.bg_image = pygame.transform.smoothscale(raw, (WIDTH, HEIGHT))

    def handle_events(self, events):
        for event in events:
            if event.type == pygame.KEYDOWN:
                if event.key in [pygame.K_LEFT, pygame.K_a]:
                    self.selected_index = (self.selected_index - 1) % len(OPERATIONS)
                    SoundManager.get().play_sfx("click")
                elif event.key in [pygame.K_RIGHT, pygame.K_d]:
                    self.selected_index = (self.selected_index + 1) % len(OPERATIONS)
                    SoundManager.get().play_sfx("click")
                elif event.key in [pygame.K_RETURN, pygame.K_SPACE]:
                    SoundManager.get().play_sfx("click")
                    op_data = OPERATIONS[self.selected_index]
                    return ("GAMEPLAY", (self.selected_char, op_data["id"]))
                elif event.key == pygame.K_ESCAPE:
                    return ("SELECT", None)

            elif event.type == pygame.MOUSEMOTION:
                mx, my = event.pos
                self.btn_deploy.update((mx, my))
                self.btn_back.update((mx, my))

            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                mx, my = event.pos
                if self.btn_deploy.rect.collidepoint((mx, my)):
                    SoundManager.get().play_sfx("click")
                    op_data = OPERATIONS[self.selected_index]
                    return ("GAMEPLAY", (self.selected_char, op_data["id"]))
                elif self.btn_back.rect.collidepoint((mx, my)):
                    return ("SELECT", None)

                # Clic directo en las tarjetas de operación
                card_w, card_h = 280, 360
                y_pos = 95
                total_w = len(OPERATIONS) * card_w + (len(OPERATIONS) - 1) * 24
                start_x = WIDTH // 2 - total_w // 2

                for i in range(len(OPERATIONS)):
                    c_rect = pygame.Rect(start_x + i * (card_w + 24), y_pos, card_w, card_h)
                    if c_rect.collidepoint((mx, my)):
                        self.selected_index = i
                        SoundManager.get().play_sfx("click")

        return None

    def update(self):
        pass

    def draw(self, surface):
        if self.bg_image:
            surface.blit(self.bg_image, (0, 0))
        else:
            surface.fill((10, 12, 16))

        # Encabezado
        font_t = get_font("title", 26)
        font_s = get_font("hud", 12)
        title = font_t.render("TABLERO DE VENGANZA - LA LISTA NEGRA", True, COLOR_WHITE)
        subtitle = font_s.render("Selecciona la operación para cazar a los miembros de la organización responsables de la emboscada", True, COLOR_TEXT_DIM)
        surface.blit(title, (WIDTH // 2 - title.get_width() // 2, 20))
        surface.blit(subtitle, (WIDTH // 2 - subtitle.get_width() // 2, 54))

        # Tarjetas de las 3 Operaciones
        card_w, card_h = 280, 370
        y_pos = 85
        total_w = len(OPERATIONS) * card_w + (len(OPERATIONS) - 1) * 24
        start_x = WIDTH // 2 - total_w // 2

        f_code = get_font("title", 14)
        f_name = get_font("title", 18)
        f_target = get_font("hud", 11, bold=True)
        f_desc = get_font("hud", 10)

        for i, op in enumerate(OPERATIONS):
            cx = start_x + i * (card_w + 24)
            card_rect = pygame.Rect(cx, y_pos, card_w, card_h)
            is_active = (i == self.selected_index)

            # Fondo
            bg_col = (20, 24, 34) if is_active else (14, 16, 22)
            pygame.draw.rect(surface, bg_col, card_rect, border_radius=6)
            border_col = COLOR_NEON_RED if is_active else (38, 44, 58)
            border_w = 3 if is_active else 1
            pygame.draw.rect(surface, border_col, card_rect, width=border_w, border_radius=6)

            # Resplandor exterior si está seleccionada
            if is_active:
                glow = pygame.Surface((card_w + 10, card_h + 10), pygame.SRCALPHA)
                pygame.draw.rect(glow, (235, 40, 55, 60), (0, 0, card_w + 10, card_h + 10), border_radius=10)
                surface.blit(glow, (cx - 5, y_pos - 5), special_flags=pygame.BLEND_RGBA_ADD)

            # Contenido de la tarjeta
            surface.blit(f_code.render(op["code"], True, COLOR_GOLD), (cx + 16, y_pos + 16))
            surface.blit(f_name.render(op["name"], True, COLOR_WHITE), (cx + 16, y_pos + 38))

            # Rótulo de Objetivo
            obj_box = pygame.Rect(cx + 16, y_pos + 70, card_w - 32, 54)
            pygame.draw.rect(surface, (28, 14, 18), obj_box, border_radius=4)
            pygame.draw.rect(surface, (180, 30, 40), obj_box, width=1, border_radius=4)
            surface.blit(f_target.render(f"OBJETIVO: {op['target_name']}", True, COLOR_NEON_RED), (cx + 24, y_pos + 76))
            surface.blit(f_desc.render(op['target_role'], True, COLOR_TEXT_DIM), (cx + 24, y_pos + 98))

            # Ubicación
            surface.blit(f_target.render("UBICACIÓN:", True, COLOR_NEON_CYAN), (cx + 16, y_pos + 138))
            surface.blit(f_desc.render(op['location'], True, COLOR_WHITE), (cx + 16, y_pos + 158))

            # Descripción de la venganza
            surface.blit(f_target.render("DETALLES DE LA MISIÓN:", True, COLOR_GOLD), (cx + 16, y_pos + 194))
            
            # Ajuste de texto multi-línea
            words = op['description'].split(' ')
            cur_line = ""
            line_y = y_pos + 214
            for word in words:
                test_line = cur_line + word + " "
                if f_desc.size(test_line)[0] < card_w - 36:
                    cur_line = test_line
                else:
                    surface.blit(f_desc.render(cur_line, True, COLOR_TEXT_DIM), (cx + 16, line_y))
                    line_y += 18
                    cur_line = word + " "
            if cur_line:
                surface.blit(f_desc.render(cur_line, True, COLOR_TEXT_DIM), (cx + 16, line_y))

            # Estado
            status_rect = pygame.Rect(cx + 16, y_pos + card_h - 44, card_w - 32, 26)
            if op.get("completed", False):
                pygame.draw.rect(surface, (45, 180, 80), status_rect, border_radius=3)
                stxt = f_target.render("✓ ELIMINADO", True, (10, 12, 16))
            else:
                pygame.draw.rect(surface, (30, 34, 46), status_rect, border_radius=3)
                stxt = f_target.render("PENDIENTE DE CAZA", True, COLOR_NEON_RED)
            surface.blit(stxt, (status_rect.centerx - stxt.get_width() // 2, status_rect.centery - stxt.get_height() // 2))

        # Botones inferiores
        self.btn_deploy.draw(surface)
        self.btn_back.draw(surface)
