import os
import pygame
from src.config import (
    WIDTH, HEIGHT, COLOR_WHITE, COLOR_TEXT_DIM,
    COLOR_NEON_CYAN, COLOR_NEON_PURPLE, COLOR_NEON_RED,
    CHARACTERS, get_font, get_asset_path
)
from src.ui.components import CharacterCard, Button

class SelectScene:
    def __init__(self):
        self.bg_image = None
        self._load_background()

        card_w, card_h = 320, 420
        y_pos = 85
        card_nagumo_x = WIDTH // 2 - card_w - 20
        card_shado_x = WIDTH // 2 + 20

        self.cards = {
            "nagumo": CharacterCard(card_nagumo_x, y_pos, card_w, card_h, CHARACTERS["nagumo"]),
            "shado": CharacterCard(card_shado_x, y_pos, card_w, card_h, CHARACTERS["shado"])
        }
        self.selected_char = "nagumo"
        self.cards["nagumo"].is_selected = True

        # Botones inferiores
        self.btn_confirm = Button(WIDTH // 2 - 130, HEIGHT - 55, 260, 36, "DESPLEGARSE", font_size=20, accent_color=COLOR_NEON_CYAN)
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
                    self._select("nagumo")
                elif event.key in [pygame.K_RIGHT, pygame.K_d]:
                    self._select("shado")
                elif event.key in [pygame.K_RETURN, pygame.K_SPACE]:
                    return ("CINEMATIC", self.selected_char)
                elif event.key == pygame.K_ESCAPE:
                    return ("MENU", None)

            elif event.type == pygame.MOUSEMOTION:
                mx, my = event.pos
                self.btn_confirm.update((mx, my))
                self.btn_back.update((mx, my))
                for card in self.cards.values():
                    card.update((mx, my))

            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                mx, my = event.pos
                if self.btn_confirm.rect.collidepoint((mx, my)):
                    return ("CINEMATIC", self.selected_char)
                if self.btn_back.rect.collidepoint((mx, my)):
                    return ("MENU", None)
                for cid, card in self.cards.items():
                    if card.rect.collidepoint((mx, my)):
                        self._select(cid)

        return None

    def _select(self, char_id):
        self.selected_char = char_id
        for cid, card in self.cards.items():
            card.is_selected = (cid == char_id)
        # Adaptar color del botón según el personaje seleccionado
        accent = CHARACTERS[char_id]["accent_color"]
        self.btn_confirm.accent_color = accent

    def update(self):
        pass

    def draw(self, surface):
        if self.bg_image:
            surface.blit(self.bg_image, (0, 0))
        else:
            surface.fill((12, 14, 20))

        # Título superior
        title_font = get_font("title", 26)
        sub_font = get_font("hud", 12, bold=False)

        title_txt = title_font.render("SELECCIÓN DE OPERATIVO", True, COLOR_WHITE)
        sub_txt = sub_font.render("Elige tu especialista para infiltrarte en las calles de la ciudad nocturna", True, COLOR_TEXT_DIM)

        surface.blit(title_txt, (WIDTH // 2 - title_txt.get_width() // 2, 22))
        surface.blit(sub_txt, (WIDTH // 2 - sub_txt.get_width() // 2, 54))

        # Tarjetas de personaje
        for card in self.cards.values():
            card.draw(surface)

        # Botones inferiores
        self.btn_confirm.draw(surface)
        self.btn_back.draw(surface)
