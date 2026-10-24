@echo off
:: ForkYard - Clean Sign-in / Temp Files
fsutil dirty query %systemdrive% >nul
if %errorLevel% NEQ 0 (
    echo Ejecute este script como Administrador.
    pause
    exit /b 1
)
echo Limpiando archivos temporales de usuario...
rd /s /q "%temp%" 2>nul
md "%temp%" 2>nul
del /s /f /q "%temp%\*.*" 2>nul
echo Limpiando carpeta temporal de Windows...
rd /s /q "C:\Windows\Temp" 2>nul
md "C:\Windows\Temp" 2>nul
del /s /f /q "C:\Windows\Temp\*.*" 2>nul
echo Limpiando Prefetch...
del /s /f /q "C:\Windows\Prefetch\*.*" 2>nul
:: -------------------------------------------------------------------------
:: Limpieza de registros de eventos (operaciµn intencional y destructiva)
:: No se incluye por defecto. Descomente sµlo si desea limpiar el historial
:: de eventos y comprende que no es reversible desde ForkYard.
:: -------------------------------------------------------------------------
:: for /F "tokens=*" %%G in ('wevtutil.exe el') DO (call :do_clear "%%G")
echo Limpieza completada.
goto :eof
:do_clear
echo clearing %1
wevtutil.exe cl %1 2>nul
goto :eof
