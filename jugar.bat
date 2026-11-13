@echo off
title The Life Project - Ciudad Nocturna
echo ========================================================
echo        THE LIFE PROJECT - CIUDAD NOCTURNA
echo ========================================================
echo Iniciando el juego...
python main.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] No se pudo iniciar el juego con 'python'.
    echo Intentando con 'py'...
    py main.py
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo [ERROR] Asegurate de tener instalado Python y Pygame:
        echo    pip install pygame
        pause
    )
)
