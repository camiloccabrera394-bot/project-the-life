import math
import random
from src.ui.cell_shaded_models import draw_npc_3d

class Civilian3D:
    """Transeúnte realista en 3D con atuendos variados, animación de caminata y física de atropello."""
    def __init__(self, wx, wz, walk_axis="x", limits=(200, 4800)):
        self.wx = float(wx)
        self.wy = 0.0
        self.wz = float(wz)
        self.walk_axis = walk_axis
        self.limits = limits
        self.dir = random.choice([-1, 1])
        self.speed = random.uniform(1.4, 2.2)
        self.outfit_id = random.randint(0, 3)
        self.anim_phase = random.uniform(0, math.pi * 2)

        self.alive = True
        self.state = "WANDER"
        self.panic_timer = 0
        self.kvx = 0.0
        self.kvz = 0.0

    def alert_panic(self, ox, oz):
        if not self.alive:
            return
        self.state = "PANIC"
        self.panic_timer = 220
        self.speed = 5.2
        if self.walk_axis == "x":
            self.dir = 1 if self.wx > ox else -1
        else:
            self.dir = 1 if self.wz > oz else -1

    def get_hit_by_vehicle(self, vx, vz):
        self.alive = False
        self.state = "DEAD"
        self.kvx = vx
        self.kvz = vz

    def update(self):
        if not self.alive:
            self.wx += self.kvx
            self.wz += self.kvz
            self.kvx *= 0.88
            self.kvz *= 0.88
            return

        if self.panic_timer > 0:
            self.panic_timer -= 1
            if self.panic_timer == 0:
                self.state = "WANDER"
                self.speed = random.uniform(1.4, 2.2)

        self.anim_phase += 0.16 if self.state == "WANDER" else 0.35
        if self.walk_axis == "x":
            self.wx += self.dir * self.speed
            if self.wx < self.limits[0] or self.wx > self.limits[1]:
                self.dir *= -1
        else:
            self.wz += self.dir * self.speed
            if self.wz < self.limits[0] or self.wz > self.limits[1]:
                self.dir *= -1

    def draw(self, surface, camera):
        proj = camera.project(self.wx, self.wy, self.wz)
        if not proj:
            return
        px, py, scale = proj
        draw_npc_3d(surface, px, py, scale, role="civilian", outfit_id=self.outfit_id,
                    anim_phase=self.anim_phase, is_alive=self.alive)
