@echo off
:: ForkYard - Improve Latency (BCD Timer Settings)
:: REQUERE: privilegios de administrador y reinicio del sistema.
:: AVISO: sin eficacia demostrada en Windows 10/11 modernos.
bcdedit /set disabledynamictick yes
bcdedit /deletevalue useplatformclock
bcdedit /set useplatformtick yes
echo Cambios de BCD aplicados. Reinicie el sistema.
echo Para revertir, ejecute como Administrador:
echo   bcdedit /deletevalue disabledynamictick
echo   bcdedit /deletevalue useplatformtick
echo   bcdedit /set useplatformclock yes
