@echo off
chcp 65001 >nul
echo ═══════════════════════════════════════════════════════════════════════════
echo   ALO Field App - Inicio Automático
echo ═══════════════════════════════════════════════════════════════════════════
echo.

REM Verificar que Flutter esté instalado
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Error: Flutter no está instalado o no está en el PATH
    pause
    exit /b 1
)

echo [1/3] Instalando dependencias de Flutter...
call flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Error al instalar dependencias
    pause
    exit /b 1
)
echo ✓ Dependencias instaladas
echo.

echo [2/3] Iniciando SAP CORS Proxy en puerto 8080...
echo    Proxy: http://localhost:8080
echo    SAP: https://sap.alo-group.com:50000
echo.
start "SAP Proxy" cmd /k "cd /d %~dp0tools && dart run sap_proxy.dart"

REM Esperar a que el proxy inicie
timeout /t 3 /nobreak >nul
echo.

echo [3/3] Iniciando aplicación Flutter...
echo    Asegúrate de tener un dispositivo/emulador conectado
echo.
call flutter run

echo.
echo ═══════════════════════════════════════════════════════════════════════════
echo   Para detener la app: presiona 'q' en la terminal de Flutter
echo   Para detener el proxy: cierra la ventana "SAP Proxy"
echo ═══════════════════════════════════════════════════════════════════════════
pause