import pygame
from src.config import (
    WIDTH, HEIGHT, COLOR_WHITE, COLOR_TEXT_DIM,
    COLOR_NEON_RED, COLOR_NEON_CYAN, COLOR_GOLD,
    SettingsManager, get_font, KEY_CODE_TO_NAME, KEY_NAME_TO_CODE
)
from src.ui.components import Button
from src.core.audio import SoundManager

class SettingsScene:
    def __init__(self):
        self.settings = SettingsManager.get()
        self.tabs = ["AUDIO", "CONTROLES", "GRÁFICOS"]
        self.active_tab = "AUDIO"

        # Pestañas
        self.tab_buttons = [
            Button(WIDTH // 2 - 270, 75, 160, 34, "AUDIO", font_size=18, accent_color=COLOR_NEON_CYAN),
            Button(WIDTH // 2 - 90, 75, 180, 34, "CONTROLES", font_size=18, accent_color=COLOR_NEON_CYAN),
            Button(WIDTH // 2 + 110, 75, 160, 34, "GRÁFICOS", font_size=18, accent_color=COLOR_NEON_CYAN)
        ]

        # Botón volver
        self.btn_back = Button(WIDTH // 2 - 120, HEIGHT - 55, 240, 36, "GUARDAR Y SALIR", font_size=18, accent_color=COLOR_NEON_RED)

        # Estado de reasignación de teclas (Key rebinding)
        self.listening_action = None

    def handle_events(self, events):
        for event in events:
            if event.type == pygame.KEYDOWN:
                # Si estamos esperando que el usuario presione una tecla para reasignar
                if self.listening_action:
                    if event.key != pygame.K_ESCAPE:
                        self.settings.set_key(self.listening_action, event.key)
                        SoundManager.get().play_sfx("click")
                    self.listening_action = None
                    return None

                if event.key in [pygame.K_ESCAPE, pygame.K_RETURN]:
                    self.settings.save()
                    SoundManager.get().play_sfx("click")
                    return "MENU"

            elif event.type == pygame.MOUSEMOTION:
                mx, my = event.pos
                self.btn_back.update((mx, my))
                for tb in self.tab_buttons:
                    tb.update((mx, my))

            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                mx, my = event.pos
                SoundManager.get().play_sfx("click")

                # Clic en botón volver
                if self.btn_back.rect.collidepoint((mx, my)):
                    self.settings.save()
                    return "MENU"

                # Clic en pestañas
                for i, tb in enumerate(self.tab_buttons):
                    if tb.rect.collidepoint((mx, my)):
                        self.active_tab = self.tabs[i]
                        self.listening_action = None
                        return None

                # Clics específicos según la pestaña activa
                if self.active_tab == "AUDIO":
                    self._handle_audio_clicks(mx, my)
                elif self.active_tab == "CONTROLES":
                    self._handle_controls_clicks(mx, my)
                elif self.active_tab == "GRÁFICOS":
                    self._handle_graphics_clicks(mx, my)

        return None

    def _handle_audio_clicks(self, mx, my):
        data = self.settings.data
        # Toggle Mute Total
        if pygame.Rect(WIDTH // 2 - 140, 160, 280, 34).collidepoint((mx, my)):
            data["is_muted"] = not data.get("is_muted", False)
            self.settings.save()
            return

        # Slider Volumen Maestro
        if pygame.Rect(WIDTH // 2 - 40, 220, 240, 24).collidepoint((mx, my)):
            rel = max(0.0, min(1.0, (mx - (WIDTH // 2 - 40)) / 240.0))
            data["master_volume"] = round(rel, 2)
            self.settings.save()

        # Toggle SFX
        if pygame.Rect(WIDTH // 2 - 40, 275, 120, 30).collidepoint((mx, my)):
            data["sfx_enabled"] = not data.get("sfx_enabled", True)
            self.settings.save()

        # Toggle Música / Ambiente
        if pygame.Rect(WIDTH // 2 - 40, 330, 120, 30).collidepoint((mx, my)):
            data["music_enabled"] = not data.get("music_enabled", True)
            self.settings.save()

    def _handle_controls_clicks(self, mx, my):
        # Botones para reasignar teclas
        actions = [
            ("Mover Arriba", "up"),
            ("Mover Abajo", "down"),
            ("Mover Izquierda", "left"),
            ("Mover Derecha", "right"),
            ("Disparar", "shoot"),
            ("Sigilo / Cubrirse", "stealth"),
            ("Interactuar / Vehículo", "interact")
        ]
        start_y = 145
        for i, (label, act_name) in enumerate(actions):
            btn_rect = pygame.Rect(WIDTH // 2 + 50, start_y + i * 36, 130, 28)
            if btn_rect.collidepoint((mx, my)):
                self.listening_action = act_name
                return

    def _handle_graphics_clicks(self, mx, my):
        data = self.settings.data
        # Screen Shake
        if pygame.Rect(WIDTH // 2 + 40, 170, 120, 30).collidepoint((mx, my)):
            data["screen_shake"] = not data.get("screen_shake", True)
            self.settings.save()

        # Lluvia
        if pygame.Rect(WIDTH // 2 + 40, 230, 160, 30).collidepoint((mx, my)):
            cur = data.get("rain_density", "high")
            order = ["high", "medium", "off"]
            next_idx = (order.index(cur) + 1) % len(order)
            data["rain_density"] = order[next_idx]
            self.settings.save()

        # Peatones
        if pygame.Rect(WIDTH // 2 + 40, 290, 120, 30).collidepoint((mx, my)):
            data["pedestrians_enabled"] = not data.get("pedestrians_enabled", True)
            self.settings.save()

    def update(self):
        pass

    def draw(self, surface):
        surface.fill((12, 14, 20))

        # Marco central
        box = pygame.Rect(WIDTH // 2 - 360, 40, 720, 480)
        pygame.draw.rect(surface, (18, 22, 30, 240), box, border_radius=8)
        pygame.draw.rect(surface, COLOR_NEON_CYAN, box, width=2, border_radius=8)

        # Botones de pestañas
        for i, tb in enumerate(self.tab_buttons):
            tb.accent_color = COLOR_GOLD if self.tabs[i] == self.active_tab else COLOR_NEON_CYAN
            tb.draw(surface)

        # Contenido de la pestaña
        if self.active_tab == "AUDIO":
            self._draw_audio_tab(surface)
        elif self.active_tab == "CONTROLES":
            self._draw_controls_tab(surface)
        elif self.active_tab == "GRÁFICOS":
            self._draw_graphics_tab(surface)

        # Botón Volver
        self.btn_back.draw(surface)

    def _draw_audio_tab(self, surface):
        data = self.settings.data
        font = get_font("title", 18)
        fval = get_font("mono", 14, bold=True)

        # 1. Silencio Total
        mute_rect = pygame.Rect(WIDTH // 2 - 140, 160, 280, 34)
        is_muted = data.get("is_muted", False)
        m_col = COLOR_NEON_RED if is_muted else (35, 180, 80)
        pygame.draw.rect(surface, (25, 28, 36), mute_rect, border_radius=4)
        pygame.draw.rect(surface, m_col, mute_rect, width=2, border_radius=4)
        mtxt = "SILENCIO: ACTIVADO (MUTE)" if is_muted else "SONIDO: ACTIVADO"
        t = font.render(mtxt, True, COLOR_WHITE)
        surface.blit(t, (mute_rect.centerx - t.get_width() // 2, mute_rect.centery - t.get_height() // 2))

        # 2. Barra de Volumen Maestro
        surface.blit(font.render("VOLUMEN GENERAL:", True, COLOR_WHITE), (WIDTH // 2 - 250, 220))
        vol_bar = pygame.Rect(WIDTH // 2 - 40, 222, 240, 20)
        pygame.draw.rect(surface, (30, 34, 45), vol_bar, border_radius=3)
        vol_val = float(data.get("master_volume", 0.8))
        pygame.draw.rect(surface, COLOR_NEON_CYAN, (vol_bar.x, vol_bar.y, int(vol_bar.width * vol_val), vol_bar.height), border_radius=3)
        surface.blit(fval.render(f"{int(vol_val * 100)}%", True, COLOR_WHITE), (vol_bar.right + 12, vol_bar.y))

        # 3. Efectos de Sonido (SFX)
        surface.blit(font.render("EFECTOS (SFX):", True, COLOR_WHITE), (WIDTH // 2 - 250, 280))
        sfx_rect = pygame.Rect(WIDTH // 2 - 40, 275, 120, 30)
        sfx_on = data.get("sfx_enabled", True)
        pygame.draw.rect(surface, (35, 180, 80) if sfx_on else (180, 40, 50), sfx_rect, border_radius=4)
        stxt = fval.render("ON" if sfx_on else "OFF", True, COLOR_WHITE)
        surface.blit(stxt, (sfx_rect.centerx - stxt.get_width() // 2, sfx_rect.centery - stxt.get_height() // 2))

        # 4. Música y Ambiente
        surface.blit(font.render("MÚSICA / AMBIENTE:", True, COLOR_WHITE), (WIDTH // 2 - 250, 335))
        mus_rect = pygame.Rect(WIDTH // 2 - 40, 330, 120, 30)
        mus_on = data.get("music_enabled", True)
        pygame.draw.rect(surface, (35, 180, 80) if mus_on else (180, 40, 50), mus_rect, border_radius=4)
        mtxt = fval.render("ON" if mus_on else "OFF", True, COLOR_WHITE)
        surface.blit(mtxt, (mus_rect.centerx - mtxt.get_width() // 2, mus_rect.centery - mtxt.get_height() // 2))

    def _draw_controls_tab(self, surface):
        font = get_font("title", 16)
        fval = get_font("mono", 14, bold=True)
        keys_dict = self.settings.data.get("keys", {})

        actions = [
            ("Mover Arriba:", "up"),
            ("Mover Abajo:", "down"),
            ("Mover Izquierda:", "left"),
            ("Mover Derecha:", "right"),
            ("Disparo de Arma:", "shoot"),
            ("Sigilo / Cubrirse:", "stealth"),
            ("Interactuar / Vehículo:", "interact")
        ]

        start_y = 145
        for i, (label, act_name) in enumerate(actions):
            y_pos = start_y + i * 36
            surface.blit(font.render(label, True, COLOR_WHITE), (WIDTH // 2 - 240, y_pos + 4))

            btn_rect = pygame.Rect(WIDTH // 2 + 50, y_pos, 130, 28)
            is_listening = (self.listening_action == act_name)
            bg_col = COLOR_NEON_RED if is_listening else (25, 30, 42)
            pygame.draw.rect(surface, bg_col, btn_rect, border_radius=3)
            pygame.draw.rect(surface, COLOR_NEON_CYAN, btn_rect, width=1, border_radius=3)

            val_str = "[PULSA TECLA]" if is_listening else keys_dict.get(act_name, "---")
            v_surf = fval.render(val_str, True, COLOR_WHITE)
            surface.blit(v_surf, (btn_rect.centerx - v_surf.get_width() // 2, btn_rect.centery - v_surf.get_height() // 2))

    def _draw_graphics_tab(self, surface):
        data = self.settings.data
        font = get_font("title", 18)
        fval = get_font("mono", 14, bold=True)

        # Temblor de Pantalla
        surface.blit(font.render("TEMBLOR DE PANTALLA:", True, COLOR_WHITE), (WIDTH // 2 - 250, 175))
        sh_rect = pygame.Rect(WIDTH // 2 + 40, 170, 120, 30)
        sh_on = data.get("screen_shake", True)
        pygame.draw.rect(surface, (35, 180, 80) if sh_on else (180, 40, 50), sh_rect, border_radius=4)
        surface.blit(fval.render("ON" if sh_on else "OFF", True, COLOR_WHITE), (sh_rect.centerx - 14, sh_rect.centery - 8))

        # Intensidad de Lluvia
        surface.blit(font.render("INTENSIDAD DE LLUVIA:", True, COLOR_WHITE), (WIDTH // 2 - 250, 235))
        rn_rect = pygame.Rect(WIDTH // 2 + 40, 230, 160, 30)
        rain_val = data.get("rain_density", "high").upper()
        pygame.draw.rect(surface, (30, 35, 48), rn_rect, border_radius=4)
        pygame.draw.rect(surface, COLOR_NEON_CYAN, rn_rect, width=1, border_radius=4)
        surface.blit(fval.render(rain_val, True, COLOR_WHITE), (rn_rect.centerx - 22, rn_rect.centery - 8))

        # Transeúntes y Peatones
        surface.blit(font.render("PEATONES Y TRÁFICO:", True, COLOR_WHITE), (WIDTH // 2 - 250, 295))
        ped_rect = pygame.Rect(WIDTH // 2 + 40, 290, 120, 30)
        ped_on = data.get("pedestrians_enabled", True)
        pygame.draw.rect(surface, (35, 180, 80) if ped_on else (180, 40, 50), ped_rect, border_radius=4)
        surface.blit(fval.render("ON" if ped_on else "OFF", True, COLOR_WHITE), (ped_rect.centerx - 14, ped_rect.centery - 8))
