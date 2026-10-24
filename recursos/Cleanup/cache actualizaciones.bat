@echo off
:: ForkYard - Clean Windows Update Cache
fsutil dirty query %systemdrive% >nul
if %errorLevel% NEQ 0 (
    echo Ejecute este script como Administrador.
    pause
    exit /b 1
)
echo Deteniendo servicios de Windows Update...
net stop wuauserv >nul 2>&1
net stop UsoSvc >nul 2>&1
net stop bits >nul 2>&1
net stop dosvc >nul 2>&1
echo Borrando carpeta SoftwareDistribution...
rd /s /q "C:\Windows\SoftwareDistribution" 2>nul
md "C:\Windows\SoftwareDistribution" 2>nul
echo Restaurando servicios de Windows Update...
net start wuauserv >nul 2>&1
net start UsoSvc >nul 2>&1
net start bits >nul 2>&1
net start dosvc >nul 2>&1
echo CachÚ de Windows Update limpiada.
