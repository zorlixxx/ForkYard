# ForkYard

Windows Optimization Toolkit

A comprehensive tool for improving Windows system performance and stability.

## About

ForkYard is a utility designed to optimize your Windows experience by:
- Managing system resources efficiently
- Cleaning temporary and unnecessary files
- Optimizing startup processes
- Providing system health insights

## Features

- **System Optimization**: Improve overall system performance
- **Startup Management**: Control programs that run at startup
- **Cleanup**: Remove temporary files and cache
- **Health Monitoring**: Check system status and performance

## Quick Start

1. Download the latest release from the [Releases](https://github.com/zorlixxx/ForkYard/releases) page
2. Run `ForkYard.exe`
3. Select the optimization you wish to apply
4. Click Apply and wait for the process to complete

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

**zorlixxx** — [GitHub](https://github.com/zorlixxx)

Feel free to contribute or report issues on the [GitHub](https://github.com/zorlixxx/ForkYard) repository.

A desktop application for Windows 10/11 that combines PC optimization tools into a simple interface. Apply validated registry tweaks, service optimizations, and system adjustments safely.

## Features

- **Categorized Optimizations**: GPU Settings, Power, Windows Services, Drivers, Input Lag, Cleanup, No Updates, Ping, RAM, Registry & BCD Tweaks, System, Gaming
- **Smart RAM Optimization**: Automatically detects installed RAM and applies matching registry settings
- **Simulation Mode**: Enabled by default — test changes without modifying the system registry
- **Safety First**: Risk levels (Safe / Moderate / Advanced), confirmations for risky tweaks, automatic backups before changes
- **Modern UI**: Dark theme with sidebar navigation, built with CustomTkinter

## Requirements

- Windows 10 or 11
- Python 3.13
- Dependencies: `customtkinter`, `pillow`, `psutil`, `pyinstaller`

## Usage

### Run from source

```powershell
py -3.13 main.py
```

### Build executable

```powershell
py -3.13 build.py
```

Produces a folder-mode executable in `dist/` using PyInstaller with `--onedir` and `--collect-all customtkinter`.

## Safety Warnings

- Some tweaks modify the Windows Registry. Always keep a system restore point before applying "Advanced" tweaks.
- Simulation Mode is ON by default. Leave it ON until you are certain about the changes.
- The app requires administrator privileges to import `.reg` files.
- SmartScreen may show a warning when running the built executable — this is normal for unsigned applications.

## Project Structure

- `main.py` — Application entry point
- `ui.py` — User interface (sidebar, content, tweak cards, log)
- `actions.py` — Tweak execution, external tools, backup/restore
- `catalog.py` — Catalog data model (loads `catalogo.json`)
- `utils.py` — Path helpers, hashing, admin check, logging
- `catalogo.json` — All tweak metadata (names, descriptions, paths, risk levels)
- `recursos/` — Copies of `.reg`, `.bat`, `.exe`, `.nip`, and image files from `programas/`
- `programas/` — Original source material (read-only, not modified)
- `backups/` — Timestamped backups created before applying tweaks

## Third-Party Tools (links only, not redistributed)

- Windows Update Blocker: https://www.sordum.org/9470/
- DNS Jumper: https://www.sordum.org/7952/
- Driver Magician: https://www.drivermagician.com/
- Geek Uninstaller: https://geekuninstaller.com/

## License

MIT License. See `LICENSE` file.

## Credits

See `CREDITS` file for third-party software licenses and attributions.
