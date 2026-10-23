 <p align="center">
  <img src="assets/forkyard%20icon/forkyard-icon.svg" alt="ForkYard Logo" width="150">
</p>

<h1 align="center">ForkYard</h1>

<p align="center">
  <strong>Windows Optimization Toolkit — v1.0.0</strong>
</p>

<p align="center">
  <a href="https://github.com/zorlixxx/ForkYard/releases">
    <img src="https://img.shields.io/badge/Download-Latest%20Release-7c3aed?style=for-the-badge" alt="Download latest release">
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT%20NC-blue.svg" alt="License: MIT (no commercial use)">
  <img src="https://img.shields.io/badge/python-3.13-blue.svg" alt="Python 3.13">
  <img src="https://img.shields.io/badge/PySide6-6.12-blue.svg" alt="PySide6">
  <img src="https://img.shields.io/badge/Windows-10%20%7C%2011-blue.svg" alt="Windows 10/11">
</p>

ForkYard es una aplicación de optimización para Windows 10 y 11. Combina una interfaz moderna construida con **PySide6 y QML** con un catálogo de más de 200 optimizaciones: ajustes de registro, gestión de servicios, energía, GPU, drivers, limpieza, navegadores, redes y más.

---

## 📋 Resumen

| | |
|---|---|
| **Qué hace** | Optimiza y desbloquea Windows mediante tweaks de registro, scripts y enlaces a herramientas externas oficiales. |
| **Stack** | Python 3.13 + PySide6 + Qt Quick (QML) |
| **Entrada** | `main.py` |
| **Licencia** | MIT con cláusula de **no uso comercial** (ver `LICENSE`) |
| **Plataforma** | Windows 10 y Windows 11 |
| **Modo predeterminado** | Simulación (sin cambios al sistema hasta que lo desactives) |

---

## 🎯 Características principales

- **Niveles de riesgo**: `Safe` (aplica directo), `Moderate` (pide confirmación), `Advanced` (advertencia y backup).
- **Backups automáticos**: antes de tocar el registro, se crea una copia de seguridad y (cuando aplica) un punto de restauración de Windows.
- **Catálogo externo**: todas las optimizaciones viven en `catalogo.json`, fácil de ampliar y editar.
- **Herramientas externas**: ForkYard **no incluye ejecutables de terceros**. Solo abre la página oficial del desarrollador en tu navegador cuando eliges una herramienta externa (Firefox, 7-Zip, VLC, Process Explorer, etc.).
- **Interfaz moderna**: tema oscuro, animaciones y panel de actividad en tiempo real.
- **Sonidos de interfaz** y notificaciones de estado.

---

## 🚀 Inicio rápido (usuario final)

1. Descarga el último `ForkYard.exe` desde la página de [Releases](https://github.com/zorlixxx/ForkYard/releases).
2. Ejecútalo. Iniciará en **Modo Simulación**.
3. Explora las categorías y selecciona las optimizaciones que quieras aplicar.
4. Haz clic en **Aplicar**. Si el tweak requiere privilegios de administrador, se te pedirá elevación.
5. Revisa el panel de actividad para confirmar que todo se aplicó correctamente.

---

## 🛠️ Construir desde código fuente

### Requisitos

- Python 3.13 o superior
- PySide6 (`pip install PySide6`)

### Ejecutar desde el código

```powershell
py -3.13 main.py
```

### Generar ejecutable (PyInstaller)

```powershell
py -3.13 -m PyInstaller ForkYard.spec
```

El resultado queda en la carpeta `dist/` (modo carpeta, sin consola, sin UPX).

---

## ⚠️ Advertencias de seguridad

- Algunos tweaks escriben en el **Registro de Windows**. Crea un punto de restauración antes de aplicar tweaks de nivel `Advanced`.
- **Modo Simulación está activado por defecto**. Déjalo encendido hasta que estés seguro de lo que vas a aplicar.
- La aplicación requiere **privilegios de administrador** para importar archivos `.reg`.
- **SmartScreen** puede mostrar una advertencia al ejecutar el `.exe` compilado: es normal en aplicaciones sin firma digital como es la mía.

---

## 🧩 Catálogo de optimizaciones

Todas las optimizaciones viven en `catalogo.json`. Cada entrada incluye:

- **Nombre y descripción** de lo que hace.
- **Nivel de riesgo**: `Safe`, `Moderate` o `Advanced`.
- **Categoría**: System, Gaming, Power, Services, GPU Settings, Drivers, Input Lag, Cleanup, Ping, RAM, Debloat & Privacy, Monitoring & Benchmarks, Startup & Processes, Browsers, Archivers, Media, Utilities.
- **Tipo**: `reg`, `bat`, `cmd`, `nip` (local) o enlace externo (`is_external: true`).
- **Instrucciones** paso a paso.
- **Requiere administrador**: si aplica cambios en `HKEY_LOCAL_MACHINE` o usa comandos del sistema.
- **Reversión**: cómo deshacer el cambio (cuando existe un procedimiento real).

Puedes editar `catalogo.json` para añadir, quitar o modificar optimizaciones sin tocar el código Python.

---

## 🔗 Herramientas de terceros (solo enlaces)

ForkYard **no redistribuye** ejecutables de terceros. Cuando seleccionas una herramienta externa, la aplicación solo abre su página oficial en tu navegador.

Ejemplos incluidos: 7-Zip, VLC, Firefox, Brave, PowerToys, BleachBit, Process Explorer, Process Lasso, O&O ShutUp10, Win11Debloat, Chris Titus WinUtil y muchos más.

Cada enlace externo fue verificado contra su fuente oficial (fecha de verificación: 2026-10-19). Consulta `CREDITS` para la lista completa y las evidencias de verificación.

---

## 📄 Licencia

Este proyecto está bajo la **Licencia MIT** con una cláusula adicional de **no uso comercial**:

- Puedes usar, modificar y distribuir el software libremente con fines **no comerciales**.
- Está **prohibido vender, licenciar o redistribuir** el software (en código fuente o binario) con fines comerciales sin permiso escrito del titular de los derechos de autor.

Lee el archivo [`LICENSE`](LICENSE) para los términos completos.

---

## 👤 Autor

**zorlix** — [GitHub](https://github.com/zorlixxx) — [Sitio personal](https://ysn.lol/zorlix) — [Ko-fi](https://ko-fi.com/zorlix)

---

## 🐛 Soporte

- **Issues**: [GitHub Issues](https://github.com/zorlixxx/ForkYard/issues)
- **Email**: zorlix1git@protonmail.com

Reporta errores, pide funcionalidades o comparte tu experiencia con los tweaks aplicados.

---

## 📅 Versiones

- **v1.0.0** — Lanzamiento inicial con catálogo de optimizaciones, interfaz PySide6/QML, backups automáticos y enlaces a herramientas externas verificadas.

---

> ForkYard es una herramienta de optimización para Windows. Úsala con responsabilidad y siempre crea un punto de restauración antes de aplicar cambios de nivel avanzado en el registro del sistema.
