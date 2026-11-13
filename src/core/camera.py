import math
import pygame
from src.config import WIDTH, HEIGHT

class Camera:
    """Cámara dinámica estilo GTA con anticipación de velocidad (Look-Ahead) y suavizado."""
    def __init__(self, world_w=5000, world_h=3500):
        self.world_w = world_w
        self.world_h = world_h
        self.viewport_w = WIDTH
        self.viewport_h = HEIGHT
        self.x = 0.0
        self.y = 0.0

        # Offset dinámico por velocidad de conducción
        self.look_ahead_x = 0.0
        self.look_ahead_y = 0.0

    def set_bounds(self, world_w, world_h):
        self.world_w = max(WIDTH, world_w)
        self.world_h = max(HEIGHT, world_h)

    def update(self, target_x, target_y, vehicle=None, lerp=0.08):
        # 1. Cálculo de anticipación de velocidad estilo GTA (Look-Ahead)
        desired_look_x = 0.0
        desired_look_y = 0.0

        if vehicle and abs(vehicle.speed) > 0.5:
            # Cuanto más rápido va el auto, más adelante se posiciona la cámara
            lead_distance = vehicle.speed * 28.0
            desired_look_x = math.cos(vehicle.angle) * lead_distance
            desired_look_y = math.sin(vehicle.angle) * (lead_distance * 0.7)

        # Suavizar el look-ahead para evitar sacudidas bruscas
        self.look_ahead_x += (desired_look_x - self.look_ahead_x) * 0.05
        self.look_ahead_y += (desired_look_y - self.look_ahead_y) * 0.05

        # 2. Posición deseada de la cámara
        focus_x = target_x + self.look_ahead_x
        focus_y = target_y + self.look_ahead_y

        desired_cam_x = focus_x - self.viewport_w / 2
        desired_cam_y = focus_y - self.viewport_h / 2

        # 3. Interpolación suave (lerp)
        self.x += (desired_cam_x - self.x) * lerp
        self.y += (desired_cam_y - self.y) * lerp

        # 4. Delimitación a los bordes de la mega ciudad
        max_x = max(0, self.world_w - self.viewport_w)
        max_y = max(0, self.world_h - self.viewport_h)
        self.x = max(0.0, min(float(max_x), self.x))
        self.y = max(0.0, min(float(max_y), self.y))

    def apply(self, world_x, world_y):
        """Convierte coordenadas del mundo a coordenadas de pantalla."""
        return int(world_x - self.x), int(world_y - self.y)

    def apply_rect(self, rect):
        """Ajusta un pygame.Rect a la posición de la cámara."""
        return pygame.Rect(rect.x - int(self.x), rect.y - int(self.y), rect.width, rect.height)

    def screen_to_world(self, screen_x, screen_y):
        """Convierte coordenadas de pantalla (como el ratón) a coordenadas del mundo."""
        return screen_x + self.x, screen_y + self.y
