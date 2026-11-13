import sys
import pygame
from src.config import WIDTH, HEIGHT, FPS, TITLE
from src.scenes.menu_scene import MenuScene
from src.scenes.select_scene import SelectScene
from src.scenes.cinematic_scene import CinematicScene
from src.scenes.mission_select_scene import MissionSelectScene
from src.scenes.gameplay_scene import GameplayScene
from src.scenes.settings_scene import SettingsScene
from src.scenes.game_over_scene import GameOverScene

class GameApp:
    def __init__(self):
        pygame.init()
        pygame.font.init()

        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption(TITLE)
        self.clock = pygame.time.Clock()
        self.running = True

        self.state = "MENU"
        self.selected_char = "nagumo"
        self.selected_operation = "chacal"
        self.current_scene = MenuScene()

    def set_state(self, new_state, param=None):
        self.state = new_state

        if new_state == "MENU":
            self.current_scene = MenuScene()
        elif new_state == "SELECT":
            self.current_scene = SelectScene()
        elif new_state == "CINEMATIC":
            if param:
                self.selected_char = param
            self.current_scene = CinematicScene(selected_char=self.selected_char)
        elif new_state == "MISSION_SELECT":
            if param:
                self.selected_char = param
            self.current_scene = MissionSelectScene(selected_char=self.selected_char)
        elif new_state == "GAMEPLAY":
            if param:
                if isinstance(param, tuple):
                    self.selected_char, self.selected_operation = param
                else:
                    self.selected_char = param
            self.current_scene = GameplayScene(selected_char=self.selected_char, operation_id=self.selected_operation)
        elif new_state == "SETTINGS":
            self.current_scene = SettingsScene()
        elif new_state == "GAME_OVER":
            self.current_scene = GameOverScene(selected_char=self.selected_char)
        elif new_state == "QUIT":
            self.running = False

    def run(self):
        while self.running:
            self.clock.tick(FPS)
            events = pygame.event.get()

            for event in events:
                if event.type == pygame.QUIT:
                    self.running = False

            action = self.current_scene.handle_events(events)
            if action:
                if isinstance(action, tuple):
                    new_state, param = action
                    self.set_state(new_state, param)
                else:
                    self.set_state(action)

            update_result = self.current_scene.update()
            if update_result:
                if isinstance(update_result, tuple):
                    new_state, param = update_result
                    self.set_state(new_state, param)
                else:
                    self.set_state(update_result)

            self.current_scene.draw(self.screen)
            pygame.display.flip()

        pygame.quit()
        sys.exit()
