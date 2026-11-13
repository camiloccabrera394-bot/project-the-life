import os
import pygame
from src.config import (
    WIDTH, HEIGHT, COLOR_WHITE, COLOR_TEXT_DIM,
    COLOR_NEON_RED, get_font, get_asset_path
)

class MenuScene:
    def __init__(self):
        self.options = ["INICIAR JUEGO", "AJUSTES Y CONTROLES", "CRÉDITOS", "SALIR"]
        self.selected_index = 0
        self.bg_image = None
        self._load_background()

    def _load_background(self):
        path = get_asset_path("bg", "portada.png")
        if path and os.path.exists(path):
            raw = pygame.image.load(path).convert()
            self.bg_image = pygame.transform.smoothscale(raw, (WIDTH, HEIGHT))

    def handle_events(self, events):
        for event in events:
            if event.type == pygame.KEYDOWN:
                if event.key in [pygame.K_UP, pygame.K_w]:
                    self.selected_index = (self.selected_index - 1) % len(self.options)
                elif event.key in [pygame.K_DOWN, pygame.K_s]:
                    self.selected_index = (self.selected_index + 1) % len(self.options)
                elif event.key in [pygame.K_RETURN, pygame.K_SPACE]:
                    return self._activate_option(self.selected_index)

            elif event.type == pygame.MOUSEMOTION:
                mx, my = event.pos
                for i in range(len(self.options)):
                    rect = pygame.Rect(WIDTH // 2 - 140, 400 + i * 38, 280, 32)
                    if rect.collidepoint((mx, my)):
                        self.selected_index = i

            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                mx, my = event.pos
                for i in range(len(self.options)):
                    rect = pygame.Rect(WIDTH // 2 - 140, 400 + i * 38, 280, 32)
                    if rect.collidepoint((mx, my)):
                        return self._activate_option(i)

        return None

    def _activate_option(self, index):
        opt = self.options[index]
        if opt == "INICIAR JUEGO":
            return "SELECT"  # Lleva al selector de personaje
        elif opt in ["AJUSTES Y CONTROLES", "CRÉDITOS"]:
            return "SETTINGS"
        elif opt == "SALIR":
            return "QUIT"
        return None

    def update(self):
        pass

    def draw(self, surface):
        if self.bg_image:
            surface.blit(self.bg_image, (0, 0))
        else:
            surface.fill((14, 16, 22))

        # Opciones del Menú
        font = get_font("title", 21)
        for i, opt in enumerate(self.options):
            y_pos = 400 + i * 38
            is_active = (i == self.selected_index)

            box_rect = pygame.Rect(WIDTH // 2 - 140, y_pos - 3, 280, 32)
            if is_active:
                # Fondo y borde neón para el botón activo
                pygame.draw.rect(surface, (18, 12, 18, 230), box_rect, border_radius=4)
                pygame.draw.rect(surface, COLOR_NEON_RED, box_rect, width=2, border_radius=4)
                txt_surf = font.render(f"<  {opt}  >", True, COLOR_WHITE)
            else:
                pygame.draw.rect(surface, (12, 14, 20, 160), box_rect, border_radius=4)
                pygame.draw.rect(surface, (35, 40, 52), box_rect, width=1, border_radius=4)
                txt_surf = font.render(opt, True, COLOR_TEXT_DIM)

            surface.blit(txt_surf, (WIDTH // 2 - txt_surf.get_width() // 2, y_pos + 1))
