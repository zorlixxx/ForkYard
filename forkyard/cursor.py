"""Tracks the mouse for the custom cursor of the interface.

The React Bits "User Cursor" replaces the native pointer with an arrow
that follows the mouse on a spring and a name pill that trails behind on
a laggier spring.  The QML side draws it, this side only reports where
the pointer is, whether a button is held and what it is hovering.
"""
from __future__ import annotations

import struct

from PySide6.QtCore import Property, QEvent, QObject, Qt, Signal
from PySide6.QtGui import QCursor, QGuiApplication


def read_cur_hotspot(path: str) -> tuple[int, int]:
    """Reads the hot spot (pointer tip) from a Windows .cur file."""
    try:
        with open(path, "rb") as f:
            data = f.read()
    except OSError:
        return 0, 0
    if len(data) < 6:
        return 0, 0
    img_type = struct.unpack("<H", data[2:4])[0]
    count = struct.unpack("<H", data[4:6])[0]
    if img_type != 2:  # CUR, not ICO
        return 0, 0
    # Image width lives in the first directory entry (byte 6).
    width = data[6] if len(data) > 6 else 0
    if width == 0:
        width = 256
    # The hot spot lives after all directory entries (16 bytes each).
    hotspot_offset = 6 + count * 16
    if len(data) < hotspot_offset + 4:
        return 0, 0
    hot_x = struct.unpack("<H", data[hotspot_offset : hotspot_offset + 2])[0]
    hot_y = struct.unpack(
        "<H", data[hotspot_offset + 2 : hotspot_offset + 4]
    )[0]
    # Sanity check: clamp the hot spot to the image size so the cursor
    # never drifts outside its own bounds.  A bogus header (e.g. hot_x=40
    # on a 32px image) falls back to (0, 0): the image's top-left corner
    # sits on the pointer, which is where a Windows arrow tip lives.
    if hot_x > width:
        hot_x = 0
    if hot_y > width:
        hot_y = 0
    return hot_x, hot_y, width


class CursorTracker(QObject):
    """Feeds the custom cursor with the state of the mouse."""

    xChanged = Signal()
    yChanged = Signal()
    pressedChanged = Signal()
    insideChanged = Signal()
    interactiveChanged = Signal()
    textModeChanged = Signal()
    hotXChanged = Signal()
    hotYChanged = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._x = 0.0
        self._y = 0.0
        self._pressed = False
        self._inside = False
        self._interactive = False
        self._text_mode = False
        self._override_active = False
        self._hot_x = 0
        self._hot_y = 0

    # ---------------------------------------------------------------- state
    def getX(self) -> float:
        return self._x

    def getY(self) -> float:
        return self._y

    def getPressed(self) -> bool:
        return self._pressed

    def getInside(self) -> bool:
        return self._inside

    def getInteractive(self) -> bool:
        return self._interactive

    def getTextMode(self) -> bool:
        """True while the pointer sits over a text field."""
        return self._text_mode

    def getHotX(self) -> int:
        return self._hot_x

    def getHotY(self) -> int:
        return self._hot_y

    x = Property(float, getX, notify=xChanged)
    y = Property(float, getY, notify=yChanged)
    pressed = Property(bool, getPressed, notify=pressedChanged)
    inside = Property(bool, getInside, notify=insideChanged)
    interactive = Property(bool, getInteractive, notify=interactiveChanged)
    textMode = Property(bool, getTextMode, notify=textModeChanged)
    hotX = Property(int, getHotX, notify=hotXChanged)
    hotY = Property(int, getHotY, notify=hotYChanged)

    # ------------------------------------------------------------- tracking
    def _set_position(self, x: float, y: float) -> None:
        if abs(x - self._x) > 0.01:
            self._x = x
            self.xChanged.emit()
        if abs(y - self._y) > 0.01:
            self._y = y
            self.yChanged.emit()

    def _set_pressed(self, pressed: bool) -> None:
        if pressed != self._pressed:
            self._pressed = pressed
            self.pressedChanged.emit()

    def _set_inside(self, inside: bool) -> None:
        if inside != self._inside:
            self._inside = inside
            self.insideChanged.emit()

    def _set_interactive(self, interactive: bool) -> None:
        if interactive != self._interactive:
            self._interactive = interactive
            self.interactiveChanged.emit()

    def _set_text_mode(self, text_mode: bool) -> None:
        if text_mode == self._text_mode:
            return
        self._text_mode = text_mode
        self.textModeChanged.emit()
        # A text field keeps its own caret, so the blank cursor steps
        # aside for a moment.
        if text_mode and self._override_active:
            QGuiApplication.restoreOverrideCursor()
            self._override_active = False
        elif not text_mode and not self._override_active:
            QGuiApplication.setOverrideCursor(QCursor(Qt.CursorShape.BlankCursor))
            self._override_active = True

    def hide_native_cursor(self) -> None:
        """Makes the operating system pointer invisible."""
        if self._override_active:
            return
        QGuiApplication.setOverrideCursor(QCursor(Qt.CursorShape.BlankCursor))
        self._override_active = True

    # ---------------------------------------------------------- event filter
    def eventFilter(self, obj, event):
        kind = event.type()

        if kind == QEvent.Type.MouseMove:
            pos = event.windowPos()
            self._set_position(pos.x(), pos.y())
            self._set_inside(True)
            self._inspect(obj)
        elif kind == QEvent.Type.HoverMove:
            self._inspect(obj)
        elif kind == QEvent.Type.MouseButtonPress:
            self._set_pressed(True)
        elif kind == QEvent.Type.MouseButtonRelease:
            self._set_pressed(False)
        elif kind == QEvent.Type.Enter:
            self._set_inside(True)
        elif kind == QEvent.Type.Leave:
            self._set_inside(False)
            self._set_interactive(False)
        return False

    def _inspect(self, obj) -> None:
        """Reads the cursor shape of the item under the pointer."""
        try:
            shape = obj.property("cursorShape")
        except Exception:
            return
        if shape is None:
            return
        self._set_interactive(shape == Qt.CursorShape.PointingHandCursor)
        self._set_text_mode(shape == Qt.CursorShape.IBeamCursor)
