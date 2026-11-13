import pygame
from src.config import (
    WIDTH, HEIGHT, COLOR_WHITE, COLOR_TEXT_DIM,
    COLOR_NEON_RED, COLOR_GOLD, get_font
)
from src.core.effects import VisualEffectsManager
from src.core.audio import SoundManager

class CinematicScene:
    """Cinemática del prólogo: La emboscada de la cena y el juramento de venganza."""
    def __init__(self, selected_char="nagumo"):
        self.selected_char = selected_char
        self.fx = VisualEffectsManager()
        self.current_slide = 0

        self.slides = [
            {
                "title": "PRÓLOGO: LA RENUNCIA",
                "text": "Durante años serviste a la organización criminal Kuroshio como su operativo más letal.\nCansado de la sangre, decidiste retirarte para tener una vida normal.",
                "color": (40, 220, 245)
            },
            {
                "title": "LA CENA TRAMPA",
                "text": "Los mandos fingieron aceptar tu salida y te invitaron a una cena de despedida.\nConfiando en su palabra, asististe junto a tu madre.",
                "color": (245, 205, 50)
            },
            {
                "title": "LA EMBOSCADA Y LA TRAGEDIA",
                "text": "La cena era una trampa mortal para silenciarte. Un escuadrón armado irrumpió,\nacribillando a tu madre a sangre fría y disparándote a quemarropa.",
                "color": (235, 40, 55)
            },
            {
                "title": "JURAMENTO DE VENGANZA",
                "text": "Te dieron por muerto y te abandonaron bajo la lluvia nocturna.\nSobreviviste por un milagro. Ahora no descansarás hasta eliminar a cada uno\nde los sicarios y a los líderes que ordenaron la masacre.",
                "color": (235, 40, 55)
            }
        ]

    def handle_events(self, events):
        for event in events:
            if event.type == pygame.KEYDOWN:
                if event.key in [pygame.K_SPACE, pygame.K_RETURN]:
                    SoundManager.get().play_sfx("click")
                    self.current_slide += 1
                    if self.current_slide >= len(self.slides):
                        return ("MISSION_SELECT", self.selected_char)
                elif event.key == pygame.K_ESCAPE:
                    return ("MISSION_SELECT", self.selected_char)

            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                SoundManager.get().play_sfx("click")
                self.current_slide += 1
                if self.current_slide >= len(self.slides):
                    return ("MISSION_SELECT", self.selected_char)

        return None

    def update(self):
        self.fx.update()

    def draw(self, surface):
        surface.fill((8, 10, 14))
        self.fx.draw_rain(surface)

        slide = self.slides[self.current_slide]

        # Resplandor de viñeta cinematográfica
        vignette = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        pygame.draw.rect(vignette, (15, 20, 30, 140), (0, 0, WIDTH, HEIGHT))
        surface.blit(vignette, (0, 0))

        # Panel central
        box = pygame.Rect(WIDTH // 2 - 380, HEIGHT // 2 - 130, 760, 260)
        pygame.draw.rect(surface, (16, 20, 28, 245), box, border_radius=8)
        pygame.draw.rect(surface, slide["color"], box, width=2, border_radius=8)

        # Título
        font_t = get_font("title", 28)
        t_surf = font_t.render(slide["title"], True, slide["color"])
        surface.blit(t_surf, (box.centerx - t_surf.get_width() // 2, box.y + 25))

        # Texto narrativo
        font_txt = get_font("hud", 14, bold=False)
        lines = slide["text"].split("\n")
        start_y = box.y + 90
        for line in lines:
            txt_surf = font_txt.render(line, True, COLOR_WHITE)
            surface.blit(txt_surf, (box.centerx - txt_surf.get_width() // 2, start_y))
            start_y += 30

        # Barra de progreso de diapositivas
        dot_w = 20
        dot_gap = 12
        total_w = len(self.slides) * dot_w + (len(self.slides) - 1) * dot_gap
        dot_x = box.centerx - total_w // 2
        for i in range(len(self.slides)):
            d_rect = pygame.Rect(dot_x + i * (dot_w + dot_gap), box.bottom - 45, dot_w, 6)
            col = slide["color"] if i == self.current_slide else (40, 48, 62)
            pygame.draw.rect(surface, col, d_rect, border_radius=2)

        # Instrucción inferior
        font_hint = get_font("hud", 11, bold=True)
        hint = font_hint.render("[CLIC o ESPACIO PARA CONTINUAR]  |  [ESC PARA OMITIR]", True, COLOR_TEXT_DIM)
        surface.blit(hint, (WIDTH // 2 - hint.get_width() // 2, HEIGHT - 40))
