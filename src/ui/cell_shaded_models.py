import math
import pygame

def draw_protagonist_tps(surface, px, py, scale, char_id, weapon_id, anim_phase, is_walking, is_crouched, is_punching, muzzle_flash):
    """Dibuja al protagonista de espaldas en alta definición Anime Cell-Shaded (idéntico al estilo GTA SA mod)."""
    h_mult = 0.72 if is_crouched else 1.0
    s = min(12.0, scale * 3.0)
    if s < 0.12:
        return

    is_nagumo = (char_id == "nagumo")
    coat_base = (22, 24, 30) if is_nagumo else (26, 22, 34)
    coat_shade = (12, 13, 16)
    coat_rim = (90, 75, 65) if is_nagumo else (140, 70, 210)
    outline_col = (5, 5, 8)
    pants_col = (18, 20, 24)
    skin_col = (232, 190, 162)

    stride = math.sin(anim_phase) if is_walking else 0.0
    sway = math.cos(anim_phase * 0.5) * 4.0 if is_walking else math.sin(pygame.time.get_ticks() * 0.003) * 1.5

    # 1. Sombra suave en el asfalto
    sh_w, sh_h = max(10, int(26 * s)), max(4, int(9 * s))
    sh_surf = pygame.Surface((sh_w, sh_h), pygame.SRCALPHA)
    pygame.draw.ellipse(sh_surf, (8, 8, 12, 155), (0, 0, sh_w, sh_h))
    surface.blit(sh_surf, (px - sh_w // 2, py - sh_h // 2))

    # 2. Piernas y Zapatos
    leg_len = int(26 * s * h_mult)
    hip_y = py - leg_len
    l_leg_off = int(stride * 5 * s)
    r_leg_off = int(-stride * 5 * s)

    pygame.draw.polygon(surface, pants_col, [
        (px - int(7*s), hip_y), (px - int(1*s), hip_y),
        (px - int(2*s), py + l_leg_off // 3), (px - int(8*s), py + l_leg_off // 3)
    ])
    pygame.draw.polygon(surface, outline_col, [
        (px - int(7*s), hip_y), (px - int(1*s), hip_y),
        (px - int(2*s), py + l_leg_off // 3), (px - int(8*s), py + l_leg_off // 3)
    ], max(1, int(0.8*s)))

    pygame.draw.polygon(surface, pants_col, [
        (px + int(1*s), hip_y), (px + int(7*s), hip_y),
        (px + int(8*s), py + r_leg_off // 3), (px + int(2*s), py + r_leg_off // 3)
    ])
    pygame.draw.polygon(surface, outline_col, [
        (px + int(1*s), hip_y), (px + int(7*s), hip_y),
        (px + int(8*s), py + r_leg_off // 3), (px + int(2*s), py + r_leg_off // 3)
    ], max(1, int(0.8*s)))

    # 3. Torso y Gabardina Ondeando
    shoulder_y = hip_y - int(22 * s * h_mult)
    waist_y = hip_y - int(3 * s * h_mult)
    hem_y = py - int(7 * s * h_mult)

    flap_spread = int((9 + abs(stride) * 6) * s)
    coat_pts = [
        (px - int(10*s), shoulder_y + int(3*s)),
        (px + int(10*s), shoulder_y + int(3*s)),
        (px + int(9*s), waist_y),
        (px + int(14*s) + flap_spread + int(sway*s*0.5), hem_y),
        (px + int(3*s), hem_y - int(4*s)),
        (px, waist_y + int(6*s)),
        (px - int(3*s), hem_y - int(4*s)),
        (px - int(14*s) - flap_spread + int(sway*s*0.5), hem_y),
        (px - int(9*s), waist_y)
    ]
    pygame.draw.polygon(surface, coat_base, coat_pts)
    pygame.draw.line(surface, coat_shade, (px - int(4*s), shoulder_y + int(6*s)), (px - int(11*s), hem_y - int(3*s)), max(1, int(1.2*s)))
    pygame.draw.line(surface, coat_shade, (px + int(4*s), shoulder_y + int(6*s)), (px + int(11*s), hem_y - int(3*s)), max(1, int(1.2*s)))
    pygame.draw.line(surface, coat_rim, (px - int(9*s), shoulder_y + int(3*s)), (px + int(9*s), shoulder_y + int(3*s)), max(1, int(1.0*s)))
    pygame.draw.polygon(surface, outline_col, coat_pts, max(1, int(1.1*s)))

    # 4. Armamento y Brazos según el arma equipada
    arm_y = shoulder_y + int(5 * s)
    if weapon_id == "m4":
        gun_pts = [
            (px - int(18*s), arm_y + int(14*s)),
            (px - int(5*s), arm_y + int(9*s)),
            (px - int(2*s), arm_y + int(11*s)),
            (px - int(16*s), arm_y + int(16*s))
        ]
        pygame.draw.polygon(surface, (28, 32, 38), gun_pts)
        pygame.draw.polygon(surface, outline_col, gun_pts, max(1, int(0.8*s)))
        pygame.draw.line(surface, (18, 20, 24), (px - int(9*s), arm_y + int(12*s)), (px - int(11*s), arm_y + int(17*s)), max(2, int(1.8*s)))
        pygame.draw.line(surface, coat_base, (px - int(9*s), arm_y), (px - int(6*s), arm_y + int(10*s)), max(3, int(3.5*s)))
        pygame.draw.line(surface, coat_base, (px + int(9*s), arm_y), (px + int(12*s), arm_y + int(8*s)), max(3, int(3.5*s)))

    elif weapon_id == "bazooka":
        rpg_pts = [
            (px + int(5*s), shoulder_y - int(4*s)),
            (px + int(15*s), shoulder_y - int(16*s)),
            (px + int(18*s), shoulder_y - int(14*s)),
            (px + int(8*s), shoulder_y + int(6*s))
        ]
        pygame.draw.polygon(surface, (55, 72, 48), rpg_pts)
        pygame.draw.polygon(surface, outline_col, rpg_pts, max(1, int(0.9*s)))
        pygame.draw.circle(surface, (140, 45, 35), (px + int(16*s), shoulder_y - int(15*s)), max(2, int(2.5*s)))

    elif weapon_id == "smg":
        pygame.draw.line(surface, (30, 34, 42), (px + int(8*s), arm_y + int(6*s)), (px + int(15*s), arm_y + int(1*s)), max(2, int(2.5*s)))
        pygame.draw.line(surface, coat_base, (px + int(9*s), arm_y), (px + int(10*s), arm_y + int(7*s)), max(3, int(3.5*s)))

    elif weapon_id == "pistol":
        pygame.draw.line(surface, (35, 38, 45), (px + int(9*s), arm_y + int(5*s)), (px + int(14*s), arm_y + int(2*s)), max(2, int(1.8*s)))
        pygame.draw.line(surface, coat_base, (px + int(9*s), arm_y), (px + int(11*s), arm_y + int(6*s)), max(3, int(3.5*s)))

    else:  # fists
        punch_off = int(-10 * s) if is_punching else 0
        pygame.draw.line(surface, coat_base, (px - int(10*s), arm_y), (px - int(13*s), arm_y + int(7*s)), max(3, int(3.5*s)))
        pygame.draw.line(surface, coat_base, (px + int(10*s), arm_y), (px + int(12*s), arm_y + int(7*s) + punch_off), max(3, int(3.5*s)))
        pygame.draw.circle(surface, skin_col, (px + int(12*s), arm_y + int(7*s) + punch_off), max(2, int(2.2*s)))

    # 5. Cuello, Cabeza y Cabello Anime
    head_y = shoulder_y - int(6 * s)
    pygame.draw.polygon(surface, coat_base, [
        (px - int(5*s), shoulder_y + int(3*s)),
        (px + int(5*s), shoulder_y + int(3*s)),
        (px + int(4*s), shoulder_y - int(2*s)),
        (px - int(4*s), shoulder_y - int(2*s))
    ])
    if not is_nagumo:
        pygame.draw.rect(surface, (155, 50, 225), (px - int(4.5*s), shoulder_y - int(1*s), int(9*s), int(3*s)))

    pygame.draw.circle(surface, skin_col, (px - int(0.8*s), head_y), max(3, int(5.5*s)))
    if is_nagumo:
        pygame.draw.rect(surface, (10, 10, 12), (px - int(6*s), head_y - int(1*s), int(3.5*s), int(2*s)))

    hair_pts = [
        (px - int(5.5*s), head_y + int(1*s)),
        (px - int(6*s), head_y - int(4*s)),
        (px - int(2*s), head_y - int(7*s)),
        (px + int(4*s), head_y - int(6.5*s)),
        (px + int(6*s), head_y - int(2*s)),
        (px + int(4.5*s), head_y + int(3*s)),
        (px - int(1*s), head_y + int(3.5*s))
    ]
    pygame.draw.polygon(surface, (16, 17, 22), hair_pts)
    pygame.draw.line(surface, (55, 62, 78), (px - int(2*s), head_y - int(5*s)), (px + int(3*s), head_y - int(4.5*s)), max(1, int(0.8*s)))
    pygame.draw.polygon(surface, outline_col, hair_pts, max(1, int(0.8*s)))

    if muzzle_flash > 0:
        f_rad = max(4, int(10 * s))
        fsurf = pygame.Surface((f_rad * 2, f_rad * 2), pygame.SRCALPHA)
        pygame.draw.circle(fsurf, (255, 225, 110, 210), (f_rad, f_rad), f_rad)
        surface.blit(fsurf, (px - f_rad, shoulder_y - f_rad), special_flags=pygame.BLEND_RGBA_ADD)


def draw_npc_3d(surface, px, py, scale, role="civilian", outfit_id=0, anim_phase=0.0, is_alive=True, weapon_id="pistol", is_boss=False, boss_name="", state="PATROL"):
    """Dibuja transeúntes realistas, sicarios de la mafia y bosses en perspectiva Cell-Shaded."""
    s = min(11.0, scale * 2.8)
    if s < 0.15:
        return

    outline = (8, 8, 12)
    skin = (228, 185, 155)

    if not is_alive:
        sh_w, sh_h = max(8, int(24 * s)), max(4, int(10 * s))
        pygame.draw.ellipse(surface, (150, 20, 28), (px - sh_w // 2, py - sh_h // 2, sh_w, sh_h))
        pygame.draw.rect(surface, (35, 40, 50), (px - int(10*s), py - int(4*s), int(20*s), int(7*s)), border_radius=2)
        pygame.draw.circle(surface, skin, (px + int(11*s), py), max(2, int(4*s)))
        return

    if role == "civilian":
        outfits = [
            ((45, 58, 78), (28, 34, 45)),
            ((115, 68, 45), (30, 35, 48)),
            ((145, 145, 155), (35, 38, 45)),
            ((165, 45, 60), (24, 26, 34))
        ]
        jacket_col, pants_col = outfits[outfit_id % len(outfits)]
    elif is_boss:
        jacket_col = (175, 25, 38)
        pants_col = (18, 20, 25)
        s *= 1.15
    else:
        jacket_col = (185, 40, 45) if state == "CHASE" else (32, 36, 48)
        pants_col = (20, 22, 28)

    stride = math.sin(anim_phase)

    sh_w, sh_h = max(6, int(20 * s)), max(3, int(7 * s))
    sh_surf = pygame.Surface((sh_w, sh_h), pygame.SRCALPHA)
    pygame.draw.ellipse(sh_surf, (8, 10, 14, 140), (0, 0, sh_w, sh_h))
    surface.blit(sh_surf, (px - sh_w // 2, py - sh_h // 2))

    leg_h = int(22 * s)
    hip_y = py - leg_h
    pygame.draw.rect(surface, pants_col, (px - int(6*s), hip_y, int(5*s), leg_h + int(stride * 3 * s)))
    pygame.draw.rect(surface, pants_col, (px + int(1*s), hip_y, int(5*s), leg_h - int(stride * 3 * s)))

    sh_y = hip_y - int(20 * s)
    torso_pts = [
        (px - int(8*s), sh_y),
        (px + int(8*s), sh_y),
        (px + int(7*s), hip_y + int(3*s)),
        (px - int(7*s), hip_y + int(3*s))
    ]
    pygame.draw.polygon(surface, jacket_col, torso_pts)
    pygame.draw.polygon(surface, outline, torso_pts, max(1, int(0.8*s)))

    if role == "enemy" and not is_boss:
        pygame.draw.line(surface, (220, 35, 45), (px, sh_y + int(2*s)), (px, sh_y + int(11*s)), max(1, int(1.5*s)))

    arm_y = sh_y + int(3 * s)
    pygame.draw.line(surface, jacket_col, (px - int(8*s), arm_y), (px - int(10*s), arm_y + int(12*s)), max(2, int(2.8*s)))
    pygame.draw.line(surface, jacket_col, (px + int(8*s), arm_y), (px + int(10*s), arm_y + int(12*s)), max(2, int(2.8*s)))

    if role == "civilian":
        if outfit_id % 2 == 0:
            pygame.draw.rect(surface, (40, 28, 20), (px + int(9*s), arm_y + int(10*s), int(7*s), int(5*s)))
    else:
        pygame.draw.line(surface, (20, 22, 26), (px + int(8*s), arm_y + int(10*s)), (px + int(14*s), arm_y + int(6*s)), max(2, int(2.2*s)))

    head_y = sh_y - int(6 * s)
    pygame.draw.circle(surface, skin, (px, head_y), max(2, int(5 * s)))
    hair_col = (24, 24, 28) if outfit_id % 2 == 0 else (95, 65, 40)
    pygame.draw.arc(surface, hair_col, (px - int(5*s), head_y - int(6*s), int(10*s), int(8*s)), 0, math.pi, max(2, int(3*s)))

    if is_boss and s > 0.4:
        bfont = pygame.font.SysFont("Impact", max(10, int(9 * s)))
        btxt = bfont.render(boss_name, True, (255, 215, 60))
        surface.blit(btxt, (px - btxt.get_width() // 2, head_y - int(22*s)))


def draw_vehicle_3d(surface, px, py, scale, v_type, is_occupied, is_braking, is_accelerating, health_ratio):
    """Dibuja vehículos 3D vistos desde atrás/perspectiva con reflejos metálicos, luces de freno y neón."""
    s = min(10.0, scale * 2.5)
    if s < 0.12:
        return

    if v_type == "motorcycle":
        w, h = max(4, int(20 * s)), max(6, int(34 * s))
        pygame.draw.ellipse(surface, (8, 10, 14), (px - w, py - int(5*s), w*2, max(2, int(10*s))))
        pygame.draw.rect(surface, (15, 16, 20), (px - int(5*s), py - int(16*s), max(2, int(10*s)), max(4, int(16*s))), border_radius=3)
        pygame.draw.polygon(surface, (155, 35, 200), [
            (px - int(8*s), py - int(14*s)), (px + int(8*s), py - int(14*s)),
            (px + int(6*s), py - int(30*s)), (px - int(6*s), py - int(30*s))
        ])
        pygame.draw.circle(surface, (255, 45, 55), (px, py - int(16*s)), max(2, int(3*s)))
        return

    w = max(8, int(66 * s))
    h = max(6, int(42 * s))
    col_body = (24, 130, 215) if v_type == "sports_car" else (22, 24, 30)
    neon_col = (40, 235, 255, 95) if v_type == "sports_car" else (235, 40, 55, 95)

    ng_h = max(4, int(16 * s))
    ng_surf = pygame.Surface((w + 20, ng_h), pygame.SRCALPHA)
    pygame.draw.ellipse(ng_surf, neon_col, (0, 0, w + 20, ng_h))
    surface.blit(ng_surf, (px - (w + 20) // 2, py - ng_h // 2), special_flags=pygame.BLEND_RGBA_ADD)

    tw, th = max(3, int(11*s)), max(4, int(12*s))
    pygame.draw.rect(surface, (12, 12, 15), (px - w // 2 + int(2*s), py - th, tw, th), border_radius=2)
    pygame.draw.rect(surface, (12, 12, 15), (px + w // 2 - tw - int(2*s), py - th, tw, th), border_radius=2)

    body_h = max(4, h - int(12*s))
    body_rect = pygame.Rect(px - w // 2, py - h + int(8*s), w, body_h)
    pygame.draw.rect(surface, col_body, body_rect, border_radius=max(2, int(4*s)))
    pygame.draw.rect(surface, (5, 5, 8), body_rect, width=max(1, int(1*s)), border_radius=max(2, int(4*s)))

    roof_pts = [
        (px - int(w * 0.40), py - h + int(8*s)),
        (px + int(w * 0.40), py - h + int(8*s)),
        (px + int(w * 0.30), py - h - int(6*s)),
        (px - int(w * 0.30), py - h - int(6*s))
    ]
    pygame.draw.polygon(surface, (16, 22, 32), roof_pts)
    pygame.draw.polygon(surface, (5, 5, 8), roof_pts, max(1, int(0.9*s)))

    if v_type == "sports_car":
        pygame.draw.rect(surface, (16, 18, 22), (px - int(w*0.46), py - h + int(4*s), int(w*0.92), max(2, int(4*s))))

    tail_col = (255, 45, 55) if is_braking else (185, 25, 35)
    lw, lh = max(3, int(13*s)), max(2, int(5*s))
    pygame.draw.rect(surface, tail_col, (body_rect.left + int(4*s), body_rect.top + int(6*s), lw, lh), border_radius=1)
    pygame.draw.rect(surface, tail_col, (body_rect.right - lw - int(4*s), body_rect.top + int(6*s), lw, lh), border_radius=1)

    if is_accelerating and is_occupied:
        fl_rad = max(2, int(5 * s))
        pygame.draw.circle(surface, (255, 160, 40), (body_rect.left + int(10*s), body_rect.bottom - int(2*s)), fl_rad)
        pygame.draw.circle(surface, (120, 220, 255), (body_rect.right - int(10*s), body_rect.bottom - int(2*s)), fl_rad)
