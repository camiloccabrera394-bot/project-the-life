import pygame
from src.config import (
    WIDTH, HEIGHT, COLOR_WHITE, COLOR_TEXT_DIM,
    COLOR_NEON_RED, COLOR_NEON_CYAN, get_font
)
from src.ui.components import Button
from src.core.effects import VisualEffectsManager

class GameOverScene:
    def __init__(self, selected_char="nagumo", wave_reached=1):
        self.selected_char = selected_char
        self.wave_reached = wave_reached
        self.fx = VisualEffectsManager()

        btn_w, btn_h = 240, 38
        cx = WIDTH // 2 - btn_w // 2
        self.btn_retry = Button(cx, 330, btn_w, btn_h, "REINTENTAR", font_size=18, accent_color=COLOR_NEON_RED)
        self.btn_select = Button(cx, 380, btn_w, btn_h, "CAMBIAR PERSONAJE", font_size=16, accent_color=COLOR_NEON_CYAN)
        self.btn_menu = Button(cx, 430, btn_w, btn_h, "MENÚ PRINCIPAL", font_size=16, accent_color=COLOR_TEXT_DIM)

    def handle_events(self, events):
        for event in events:
            if event.type == pygame.KEYDOWN:
                if event.key in [pygame.K_r, pygame.K_RETURN, pygame.K_SPACE]:
                    return ("GAMEPLAY", self.selected_char)
                elif event.key == pygame.K_c:
                    return ("MISSION_SELECT", self.selected_char)
                elif event.key == pygame.K_ESCAPE:
                    return ("MENU", None)

            elif event.type == pygame.MOUSEMOTION:
                mx, my = event.pos
                self.btn_retry.update((mx, my))
                self.btn_select.update((mx, my))
                self.btn_menu.update((mx, my))

            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                mx, my = event.pos
                if self.btn_retry.rect.collidepoint((mx, my)):
                    return ("GAMEPLAY", self.selected_char)
                elif self.btn_select.rect.collidepoint((mx, my)):
                    return ("MISSION_SELECT", self.selected_char)
                elif self.btn_menu.rect.collidepoint((mx, my)):
                    return ("MENU", None)

        return None

    def update(self):
        self.fx.update()

    def draw(self, surface):
        surface.fill((10, 11, 15))
        self.fx.draw_rain(surface)

        # Resplandor de alerta roja
        glow = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        pygame.draw.rect(glow, (180, 25, 35, 35), (0, 0, WIDTH, HEIGHT))
        surface.blit(glow, (0, 0))

        # Título
        font_title = get_font("title", 48)
        t_surf = font_title.render("OPERATIVO CAÍDO", True, COLOR_NEON_RED)
        surface.blit(t_surf, (WIDTH // 2 - t_surf.get_width() // 2, 160))

        # Subtítulo y estadísticas
        font_sub = get_font("hud", 16, bold=False)
        sub_surf = font_sub.render(f"Has sido neutralizado en las calles de la ciudad nocturna. Oleada alcanzada: {self.wave_reached}", True, COLOR_WHITE)
        surface.blit(sub_surf, (WIDTH // 2 - sub_surf.get_width() // 2, 230))

        # Botones
        self.btn_retry.draw(surface)
        self.btn_select.draw(surface)
        self.btn_menu.draw(surface)
