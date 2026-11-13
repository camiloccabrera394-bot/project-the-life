import math
import random
import pygame
from src.config import WIDTH, HEIGHT, SettingsManager

class RainDrop:
    __slots__ = ('x', 'y', 'speed', 'length')
    def __init__(self):
        self.reset()
        self.y = random.randint(-50, HEIGHT)

    def reset(self):
        self.x = random.randint(-60, WIDTH)
        self.y = random.randint(-60, -10)
        self.speed = random.randint(14, 22)
        self.length = random.randint(10, 18)

class Ripple:
    __slots__ = ('x', 'y', 'radius', 'max_radius', 'alpha')
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.radius = 2.0
        self.max_radius = random.uniform(8.0, 15.0)
        self.alpha = 140

    def update(self):
        self.radius += 0.8
        self.alpha = max(0, int(140 * (1.0 - (self.radius / self.max_radius))))
        return self.radius < self.max_radius

class Particle:
    __slots__ = ('x', 'y', 'vx', 'vy', 'color', 'size', 'life', 'max_life')
    def __init__(self, x, y, vx, vy, color, size, life):
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.color = color
        self.size = size
        self.life = life
        self.max_life = life

    def update(self):
        self.x += self.vx
        self.y += self.vy
        self.vx *= 0.94
        self.vy *= 0.94
        self.life -= 1
        return self.life > 0

class VisualEffectsManager:
    def __init__(self):
        self.settings = SettingsManager.get()
        density = self.settings.data.get("rain_density", "high")
        count = 160 if density == "high" else (80 if density == "medium" else 0)
        self.drops = [RainDrop() for _ in range(count)]
        self.ripples = []
        self.particles = []
        self.screen_shake = 0
        self.pulse_timer = 0.0

    def add_screen_shake(self, amount=6):
        if self.settings.data.get("screen_shake", True):
            self.screen_shake = min(20, self.screen_shake + amount)

    def get_shake_offset(self):
        if self.screen_shake > 0 and self.settings.data.get("screen_shake", True):
            ox = random.uniform(-self.screen_shake, self.screen_shake)
            oy = random.uniform(-self.screen_shake * 0.6, self.screen_shake * 0.6)
            self.screen_shake = max(0, self.screen_shake - 0.7)
            return int(ox), int(oy)
        return 0, 0

    def spawn_sparks(self, x, y, count=8, color=(255, 230, 110)):
        for _ in range(count):
            angle = random.uniform(0, math.pi * 2)
            spd = random.uniform(2.5, 7.0)
            vx = math.cos(angle) * spd
            vy = math.sin(angle) * spd * 0.65
            life = random.randint(10, 20)
            self.particles.append(Particle(x, y, vx, vy, color, random.randint(2, 3), life))

    def spawn_blood(self, x, y, count=6):
        for _ in range(count):
            angle = random.uniform(0, math.pi * 2)
            spd = random.uniform(1.2, 4.0)
            vx = math.cos(angle) * spd
            vy = math.sin(angle) * spd * 0.65
            life = random.randint(14, 25)
            self.particles.append(Particle(x, y, vx, vy, (190, 25, 30), random.randint(2, 4), life))

    def spawn_muzzle_flash(self, x, y, color=(255, 220, 120)):
        for _ in range(4):
            angle = random.uniform(0, math.pi * 2)
            spd = random.uniform(1.0, 3.0)
            self.particles.append(Particle(x, y, math.cos(angle)*spd, math.sin(angle)*spd*0.6, color, 4, 6))

    def update(self):
        self.pulse_timer += 0.05
        # Lluvia
        for drop in self.drops:
            drop.x += 3.5
            drop.y += drop.speed
            if drop.y > HEIGHT:
                if random.random() < 0.22 and drop.x < WIDTH:
                    self.ripples.append(Ripple(drop.x, min(HEIGHT - 20, drop.y - random.randint(5, 30))))
                drop.reset()

        self.ripples = [r for r in self.ripples if r.update()]
        self.particles = [p for p in self.particles if p.update()]

    def draw_rain(self, surface):
        if self.settings.data.get("rain_density", "high") == "off":
            return

        rain_surf = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        for r in self.ripples:
            col = (130, 185, 235, r.alpha)
            rx = int(r.radius * 1.6)
            ry = max(1, int(r.radius * 0.65))
            pygame.draw.ellipse(rain_surf, col, (int(r.x - rx), int(r.y - ry), rx * 2, ry * 2), 1)

        for drop in self.drops:
            dx2 = drop.x + 3.0
            dy2 = drop.y + drop.length * 0.75
            pygame.draw.line(rain_surf, (150, 195, 240, 75), (int(drop.x), int(drop.y)), (int(dx2), int(dy2)), 1)

        surface.blit(rain_surf, (0, 0))

    def draw_particles(self, surface, camera=None):
        for p in self.particles:
            factor = p.life / p.max_life
            alpha = int(255 * factor)
            radius = max(1, int(p.size * factor))
            
            p_surf = pygame.Surface((radius * 4, radius * 4), pygame.SRCALPHA)
            r, g, b = p.color
            pygame.draw.circle(p_surf, (r, g, b, alpha), (radius * 2, radius * 2), radius)

            if camera:
                sx, sy = camera.apply(p.x, p.y)
            else:
                sx, sy = int(p.x), int(p.y)

            surface.blit(p_surf, (sx - radius * 2, sy - radius * 2), special_flags=pygame.BLEND_RGBA_ADD)

    def draw_flashlight(self, surface, origin_sx, origin_sy, angle, length=210, spread=0.48, color=(255, 248, 190, 42)):
        light_surf = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        p1 = (origin_sx, origin_sy)
        p2 = (origin_sx + length * math.cos(angle - spread) * 1.15, origin_sy + length * math.sin(angle - spread) * 0.68)
        p3 = (origin_sx + length * math.cos(angle + spread) * 1.15, origin_sy + length * math.sin(angle + spread) * 0.68)
        
        pygame.draw.polygon(light_surf, color, [p1, p2, p3])
        end_cx = (p2[0] + p3[0]) // 2
        end_cy = (p2[1] + p3[1]) // 2
        r_col = (color[0], color[1], color[2], min(80, color[3] + 25))
        pygame.draw.ellipse(light_surf, r_col, (end_cx - 45, end_cy - 20, 90, 40))
        surface.blit(light_surf, (0, 0), special_flags=pygame.BLEND_RGBA_ADD)
