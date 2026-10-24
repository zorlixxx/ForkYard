"""Locates the image assets that ship with the application.

QML asks this object for a file URL instead of hard coding paths, which
keeps the interface working both from a checkout and from a packaged
build.  A missing asset never breaks the interface: the caller receives
a sensible fallback instead.
"""
from __future__ import annotations

import os
from typing import Dict, Optional

from .paths import base_dir

FALLBACK_ICON = "cog"


class AssetLocator:
    """Resolves asset names to ``file://`` URLs."""

    def __init__(self, root: Optional[str] = None) -> None:
        self.root = root or base_dir()
        self._icon_dir = os.path.join(self.root, "assets", "generated", "mask")
        self._logo_dir = os.path.join(self.root, "assets", "generated", "full")
        self._ui_dir = os.path.join(self.root, "assets", "ui")
        self._sound_dir = os.path.join(self.root, "assets", "sounds")
        self._cache: Dict[str, str] = {}

        # Plain dictionaries are handed to QML: they are cheap to read from
        # a binding and cannot break when a lookup misses.
        self.icons: Dict[str, str] = {}
        self.logos: Dict[str, str] = {}
        self.ui: Dict[str, str] = {}
        self.sounds: Dict[str, str] = {}

        self._scan(self._icon_dir, self.icons, "stem")
        self._scan(self._logo_dir, self.logos, "stem")
        self._scan(self._ui_dir, self.ui, "file")
        self._scan_sounds()

        fallback = self.icons.get(FALLBACK_ICON, "")
        for name in list(self.icons):
            self.icons[name] = self.icons[name] or fallback

    # --------------------------------------------------------------- helpers

    @staticmethod
    def _to_url(path: str) -> str:
        path = path.replace("\\", "/")
        if not path.startswith("/"):
            path = "/" + path
        return "file://" + path.replace(" ", "%20")

    def _scan(self, directory: str, target: Dict[str, str], key_mode: str) -> None:
        if not os.path.isdir(directory):
            return
        for entry in sorted(os.listdir(directory)):
            if not entry.lower().endswith(".png"):
                continue
            if key_mode == "file":
                key = entry.lower()
            else:
                key = os.path.splitext(entry)[0].lower()
            target[key] = self._to_url(os.path.join(directory, entry))

    def _scan_sounds(self) -> None:
        if not os.path.isdir(self._sound_dir):
            return
        for entry in sorted(os.listdir(self._sound_dir)):
            if not entry.lower().endswith((".wav", ".mp3")):
                continue
            key = os.path.splitext(entry)[0].lower()
            self.sounds[key] = os.path.join(self._sound_dir, entry)

    # ---------------------------------------------------------------- public

    def path(self, *parts: str) -> str:
        """Absolute path of a packaged file."""
        return os.path.join(self.root, *parts)

    def url(self, *parts: str) -> str:
        """``file://`` URL of a packaged file."""
        return self._to_url(os.path.join(self.root, *parts))
