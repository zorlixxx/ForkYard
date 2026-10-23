# -*- mode: python ; coding: utf-8 -*-
"""PyInstaller description of the ForkYard desktop build.

The QML interface, the generated artwork, the catalog and the tweak
resources travel with the program.  Only the Qt parts the interface really
uses are collected, so the bundle stays a sensible size.
"""
import os

from PyInstaller.utils.hooks import collect_data_files

HERE = os.path.abspath(os.getcwd())

datas = [
    (os.path.join(HERE, "catalogo.json"), "."),
    (os.path.join(HERE, "recursos"), "recursos"),
    (os.path.join(HERE, "assets"), "assets"),
    (os.path.join(HERE, "qml"), "qml"),
]
binaries = []
hiddenimports = ["shiboken6"]

# The QML modules the interface imports at runtime.  Everything the app
# does not import is left out, including the styles of the Controls module
# it does not use.
QML_ALLOWED = (
    "qml/QtQuick/",
    "qml/QtQml/",
)
QML_DENIED = (
    "qml/QtQuick/Dialogs/",
    "qml/QtQuick/LocalStorage/",
    "qml/QtQuick/NativeStyle/",
    "qml/QtQuick/Pdf/",
    "qml/QtQuick/Particles/",
    "qml/QtQuick/Scene2D/",
    "qml/QtQuick/Scene3D/",
    "qml/QtQuick/Timeline/",
    "qml/QtQuick/tooling/",
    "qml/QtQuick/VectorImage/",
    "qml/QtQuick/VirtualKeyboard/",
    "qml/QtQuick/Controls/Imagine/",
    "qml/QtQuick/Controls/FluentWinUI3/",
    "qml/QtQuick/Controls/Material/",
    "qml/QtQuick/Controls/Windows11/",
    "qml/QtQuick/Controls/macOS/",
    "qml/QtQuick/Controls/Universal/",
)


def keep(entry) -> bool:
    """Filter a collected file by its path inside the PySide6 package."""
    source = entry[0].replace("\\", "/")
    marker = "/PySide6/"
    if marker in source:
        relative = source.split(marker, 1)[1]
    else:
        relative = source
    if any(part in relative for part in QML_DENIED):
        return False
    return any(part in relative for part in QML_ALLOWED)


for module in ("QtQuick", "QtQml", "QtCore"):
    datas += [entry for entry in collect_data_files("PySide6", subdir=f"qml/{module}") if keep(entry)]

# The Windows platform plugin and the image formats Qt needs.
datas += collect_data_files("PySide6", subdir="plugins/platforms")
datas += collect_data_files("PySide6", subdir="plugins/imageformats")

a = Analysis(
    ["main.py"],
    pathex=[HERE],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=["tkinter", "customtkinter", "PIL", "numpy", "matplotlib"],
    noarchive=False,
    optimize=0,
)

# The interface uses the Basic style of the Controls module.  The other
# styles and the translations are not needed and only make the bundle
# bigger.
UNUSED = (
    "FluentWinUI3",
    "Imagine",
    "Material",
    "Universal",
    "Fusion",
    "translations",
    "Quick3D",
    "StateMachine",
    "Pdf",
    "VirtualKeyboard",
)
a.binaries = TOC(
    [entry for entry in a.binaries if not any(part in entry[0] for part in UNUSED)]
)
a.datas = TOC(
    [entry for entry in a.datas if not any(part in entry[0] for part in UNUSED)]
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="ForkYard",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    uac_admin=False,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name="ForkYard",
)
