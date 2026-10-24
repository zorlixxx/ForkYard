"""Liquid Chrome background stub.

La implementacion original basada en QQuickFramebufferObject (OpenGL) se
elimino porque es incompatible con el backend Direct3D11 de esta aplicacion.
El fondo liquido ahora se renderiza desde QML puro en
qml/ForkYard/components/LiquidChromeLegacy.qml, así que este modulo se queda
como placeholder vacio para evitar errores de importacion.
"""
from __future__ import annotations


class LiquidChromeItem:
    """Placeholder sin dependencias de PySide6/OpenGL."""

    def __init__(self, parent=None) -> None:
        pass


LiquidChromeRenderer = LiquidChromeItem
