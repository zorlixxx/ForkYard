"""ForkYard - Windows optimization toolkit.

Entry point.  Sets up the Qt application, hands the design tokens, the
asset locator and the controller to the QML layer and starts the event
loop.
"""
from __future__ import annotations

import os
import sys

try:
    from PySide6.QtCore import Qt, QUrl
except ModuleNotFoundError:
    print("PySide6 is not installed for this Python. Run: py -3.13 main.py", file=sys.stderr)
    raise SystemExit(1)
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from forkyard import __version__
from forkyard.assets import AssetLocator
from forkyard.controller import Controller
from forkyard.paths import base_dir
from forkyard.theme import TOKENS


def main() -> int:
    # Fractional display scaling is honoured instead of being rounded to
    # whole steps, which is what caused the layout drift of the previous
    # interface when a monitor was re-scaled.
    QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )

    app = QGuiApplication(sys.argv)
    app.setApplicationName("ForkYard")
    app.setApplicationDisplayName("ForkYard")
    app.setOrganizationName("zorlix")
    app.setApplicationVersion(__version__)

    assets = AssetLocator()
    app.setWindowIcon(QIcon(assets.url("assets", "ui", "forkyard-128.png")))

    controller = Controller()

    engine = QQmlApplicationEngine()
    context = engine.rootContext()
    context.setContextProperty("controller", controller)
    context.setContextProperty("Theme", TOKENS)
    context.setContextProperty(
        "Assets",
        {"icons": assets.icons, "logos": assets.logos, "ui": assets.ui, "sounds": assets.sounds,
         "forkyardIcon": assets.url("assets", "ui", "forkyard-mark.svg")},
    )

    context.setContextProperty("appVersion", __version__)

    engine.addImportPath(os.path.join(base_dir(), "qml"))
    engine.load(
        QUrl.fromLocalFile(os.path.join(base_dir(), "qml", "ForkYard", "Main.qml"))
    )
    if not engine.rootObjects():
        print("ForkYard could not load its interface.", file=sys.stderr)
        controller.shutdown()
        return 1

    app.aboutToQuit.connect(controller.shutdown)
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())