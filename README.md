# THE LIFE PROJECT — GODOT 4 (3D TERCERA PERSONA)

Videojuego 3D en tercera persona estilo **GTA San Andreas** con estética **Anime-Noir *Cell-Shaded*** desarrollado en **Godot Engine 4**.

---

## 🚀 Cómo Abrir y Jugar

1. Descarga e instala **Godot Engine 4** (versión estándar 4.2, 4.3 o 4.4 — gratis y portable desde [godotengine.org](https://godotengine.org)).
2. Abre Godot y selecciona **Importar** -> elige el archivo **`project.godot`** dentro de esta carpeta.
3. Presiona **F5** (o el botón ▶ Play arriba a la derecha) para jugar.

---

## 📁 Estructura del Proyecto Godot

```
projecto life/
├── project.godot                  # Configuración principal del proyecto Godot 4
├── assets/
│   └── images/
│       ├── backgrounds/           # Portada del menú y fondos de selección
│       └── characters/            # Retratos de Nagumo y Shado
├── shaders/
│   ├── toon_base.gdshader         # Shader 3D Anime Cell-Shaded + Rim Light
│   └── toon_outline.gdshader      # Shader de contorno de tinta negra
├── scenes/
│   ├── ui/                        # Menú, Selección, Prólogo, Lista Negra, Ajustes, Game Over
│   └── world/                     # Escena principal 3D de la ciudad (city_world.tscn)
└── scripts/
    ├── autoload/                  # GameState, SettingsManager (user://settings.cfg), AudioManager
    ├── entities/                  # Player3D, Vehicle3D, NPC3D, Enemy3D, Payphone3D, Projectile3D, ModelBuilder
    ├── world/                     # CityWorld (3D) e InteriorBuilder (Taller mecánico 3D)
    └── ui/                        # GTAHud (Radar circular, caja arma, dinero verde, subtítulos)
```

> **Nota sobre archivos antiguos de Python:** Si quieres limpiar completamente la carpeta, puedes borrar con seguridad `main.py`, `main_legacy_backup.py`, `jugar.bat`, `src/`, `callejon_bg.jpeg`, `portada.png`, `nagumo.png` y `shado.png` de la raíz (las imágenes ya están copiadas en `assets/images/` y `src/` tiene un archivo `.gdignore` para que Godot no lo cargue).

---

## 🔫 Arsenal Completo (Teclas `1` a `5` o Rueda del Ratón)

| Tecla | Arma | Características |
| :--- | :--- | :--- |
| **`1`** | **Puños** | Combate cuerpo a cuerpo y derribo sigiloso letal por la espalda. |
| **`2`** | **Pistola 9mm** | Precisa; silenciada al jugar con Shado. |
| **`3`** | **Metralleta SMG** | Disparo automático rápido manteniendo pulsado el gatillo. |
| **`4`** | **Fusil de Asalto M4** | Gran alcance y potencia táctica. |
| **`5`** | **Bazuca RPG** | Cohetes explosivos que destruyen vehículos y grupos en área. |

---

## 🕹️ Controles (Personalizables en Ajustes)

- **Moverse / Conducir:** `W, A, S, D` o Flechas
- **Cámara / Apuntar:** Ratón (Clic Derecho para zoom sobre el hombro)
- **Disparar / Golpear:** Clic Izquierdo o `F`
- **Cambiar de Arma:** `1` – `5`, `Q` o Rueda del Ratón
- **Interactuar (Subir a Auto / Contestar Teléfono / Entrar a Taller / Escalera Azotea):** `E`
- **Sigilo / Freno de Mano (Derrape):** `ESPACIO`
- **Bocina del Auto:** `H`
- **Menú / Pausa:** `ESC`
