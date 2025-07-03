@echo off
echo ===============================================
echo    PSD Real-Time Plotter - STM32F407G-DISC1
echo ===============================================
echo.

REM Cambiar al directorio del proyecto
cd /d "%~dp0"

REM Verificar si existe el entorno virtual
if not exist "Python\Scripts\activate.bat" (
    echo ERROR: No se encontró el entorno virtual de Python
    echo Por favor, crea el entorno virtual primero:
    echo python -m venv Python
    echo.
    pause
    exit /b 1
)

REM Activar el entorno virtual
echo Activando entorno virtual de Python...
call Python\Scripts\activate.bat

REM Verificar e instalar dependencias si es necesario
echo Verificando dependencias...
python -c "import serial, numpy, pyqtgraph" 2>nul
if errorlevel 1 (
    echo Instalando dependencias necesarias...
    pip install pyserial numpy pyqtgraph PyQt5
)

REM Ejecutar el script
echo.
echo Iniciando visualizador PSD en tiempo real...
echo Asegúrate de que el STM32 esté conectado al puerto COM3
echo.
python "Python Files\realTimePlot.py"

REM Desactivar entorno virtual al salir
deactivate

echo.
echo Programa finalizado. Presiona cualquier tecla para cerrar...
pause >nul
