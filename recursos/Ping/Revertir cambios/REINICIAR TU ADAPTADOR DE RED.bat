@echo off
:: ForkYard - Reset Network Adapter
fsutil dirty query %systemdrive% >nul
if %errorLevel% NEQ 0 (
    echo Ejecute este script como Administrador.
    exit /b 1
)
echo Resetting Network Settings...
ipconfig /flushdns
netsh int ipv4 reset
netsh int ipv6 reset
netsh winsock reset
echo Network Reset completado.
echo Reinicie el sistema para que los cambios surtan efecto.
