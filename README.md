# ForkYard — Windows Optimization Toolkit

ForkYard is a desktop application for Windows 10/11 that gathers PC
optimization tweaks and links to third-party tools into one interface.
Registry tweaks, service changes and system adjustments can be previewed in
Simulation Mode before anything touches the system.

The interface is built with **PySide6 / Qt Quick (QML)**. The optimization
backend is plain Python and applies the bundled `.reg`, `.bat`, `.cmd`,
`.nip` and command resources for real.

## Features

- **17 categories and 93 entries** — System, Gaming, Power, Services, GPU
  Settings, Drivers, Input Lag, Cleanup, Ping, RAM, Debloat & Privacy,
  Monitoring & Benchmarks, Startup & Processes, Browsers, Archivers, Media
  and Utilities
- **Two kinds of cards** — local entries that apply a bundled
  `.reg`/`.bat`/`.cmd`/`.nip` file or command, and external cards that only
  open the tool's official page (ForkYard never downloads, installs or runs
  third-party tools for you)
- **Honest metadata** — every entry states its risk level, whether it needs
  administrator rights, whether it needs a restart, which Windows versions
  it applies to and, where a real procedure exists, how to undo it
- **Smart RAM optimization** — detects the installed memory and applies the
  matching registry profile
- **Visible command output** — `.bat`, `.cmd` and command actions stream
  their real output into an in-app terminal panel so you can see progress,
  warnings, errors and the actual exit code as they happen
- **In-window dialogs** — welcome notice, help panel, confirmation prompt,
  command output and developer menu all render inside the main window, never
  as a second window
- **Live activity log** — every action is written to the strip at the bottom
  of the window

## Requirements

- Windows 10 or 11
- Python 3.13
- `PySide6-Essentials` (6.12 or newer)
- `pyinstaller` if you want to build an executable

```powershell
py -3.13 -m pip install PySide6-Essentials pyinstaller
```

## Usage

### Run from source

```powershell
py -3.13 main.py
```

The application applies entries for real once you confirm them. Risky
entries show a confirmation prompt first, and administrator-required
entries need an elevated session.

### Build an executable

```powershell
py -3.13 -m PyInstaller --noconfirm --clean ForkYard.spec
```

The result is a folder build in `dist/ForkYard/`; the program is
`dist/ForkYard/ForkYard.exe`.

## Verifying the interface

Four harnesses check the application without changing the system:

```powershell
py -3.13 tools/qml_check.py          # loads the QML and reports every warning
py -3.13 tools/gui_test.py           # drives the real window, writes build/qa/*.png
py -3.13 tools/check_screenshots.py  # inspects the captured pixels
py -3.13 tools/verify_catalog.py     # checks the catalog for internal consistency
```

`gui_test.py` opens the real window, types into the welcome dialog, walks
the categories, searches, opens the help and confirmation overlays, applies
an entry in simulation mode, expands the activity log, resizes the window to
1280x800 and 1920x1080 and audits the layout for items that spill out of the
window. It never leaves simulation mode, and the acceptance marker of the
disclaimer is restored afterwards.

`verify_catalog.py` makes sure that every entry carries the metadata the
interface shows, that every resource the catalog points at exists and that
no external entry makes a compatibility claim ForkYard cannot know.

`capture_window.py` grabs the screen and checks what a running build - the
packaged executable as well - actually paints.

## Safety notes

- Some entries modify the Windows registry. Create a system restore point
  before applying "Advanced" entries.
- Administrator rights are needed for registry writes to `HKEY_LOCAL_MACHINE`
  and for commands such as `fsutil`, `bcdedit`, `powercfg`, `takeown` and
  `netsh`. ForkYard asks for elevation when the entry needs it.
- A backup of the affected files is written to `backups/<timestamp>/` before
  a resource is applied. These backups are **not** an automatic undo; use
  the reversal that the help panel describes for the entry.
- SmartScreen may warn about the built executable. This is normal for
  unsigned applications.

## Project structure

- `main.py` — entry point: creates the Qt application, hands the design
  tokens, the asset locator and the controller to the QML layer
- `forkyard/` — the Python side
  - `theme.py` — colours, spacing, radii, type scale and motion timings
  - `catalog.py` — loads `catalogo.json` and answers questions about it
  - `actions.py` — the real work: registry imports, scripts, commands,
    elevation, restore points and backups
  - `controller.py` — the `QObject` the QML layer talks to
  - `assets.py` — resolves artwork to `file://` URLs
  - `paths.py` — resource and writable paths, also inside a bundle
- `qml/ForkYard/` — the interface
  - `Main.qml` — window, layout and the dialog flow
  - `components/` — header, sidebar, content area, tweak card, activity
    panel and the four overlays
  - `util.js` — small shared helpers
- `assets/` — generated interface masks, product glyphs, the app mark and
  the backdrop plate (rebuild with `py -3.13 tools/build_assets.py`)
- `catalogo.json` — all entry metadata
- `recursos/` — the `.reg`, `.bat`, `.cmd` and `.nip` resources that the
  entries apply
- `backups/` — timestamped backups written before a resource is applied
  (git-ignored)
- `tools/` — the asset builder, the catalog enrichment, the four check
  harnesses and the window capture

## Third-party tools (links only, not redistributed)

ForkYard does not bundle, download, install or run third-party software.
Cards marked **Open** only open the tool's official page in the browser
(or a built-in Windows Settings page such as Startup Apps). Nothing is
installed silently. See `CREDITS` for the full list of linked tools with
authors, licenses and official URLs, and `docs/SOURCES.md` for the
verification log.

## License

ForkYard itself is MIT-licensed (see `LICENSE`). Third-party tools linked
from the catalog keep their own licenses (MIT, GPL, MPL, LGPL, freeware,
trial/shareware, etc.) — see `CREDITS`. ForkYard makes no claim over them.

## Credits

See `CREDITS` for third-party licenses and attributions.
