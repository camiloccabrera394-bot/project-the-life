"""
====================================================================
THE LIFE PROJECT - CIUDAD NOCTURNA
Punto de Entrada Principal (Main Launcher)
====================================================================
"""
import sys
import os

# Asegurar que la raíz del proyecto esté en el path de Python
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from src.core.game import GameApp

def main():
    app = GameApp()
    app.run()

if __name__ == "__main__":
    main()