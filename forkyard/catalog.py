"""Catalog model: the tweak metadata that drives the whole interface."""
from __future__ import annotations

import json
from typing import Any, Dict, Iterable, List, Optional

from .paths import resource_path

# Icon used for every category in the sidebar.
CATEGORY_ICONS = {
    "System": "cog",
    "Gaming": "headset",
    "Power": "heart",
    "Services": "workflow",
    "GPU Settings": "layout-grid",
    "Drivers": "download",
    "Input Lag": "arrow-right",
    "Cleanup": "trash",
    "Ping": "activity",
    "RAM": "ram",
    "Debloat & Privacy": "eye-closed",
    "Monitoring & Benchmarks": "loader",
    "Startup & Processes": "users-round",
    "Browsers": "languages",
    "Archivers": "paperclip",
    "Media": "film",
    "Utilities": "file-text",
}

# Filters offered above the card grid.
FILTERS = [
    ("all", "All"),
    ("safe", "Safe"),
    ("moderate", "Moderate"),
    ("advanced", "Advanced"),
    ("restart", "Restart"),
    ("external", "External"),
]


class Catalog:
    """Loads ``catalogo.json`` and answers questions about it."""

    FILTERS = FILTERS

    def __init__(self, path: Optional[str] = None) -> None:
        self.path = path or resource_path("catalogo.json")
        self.categories: List[Dict[str, Any]] = []
        self._by_id: Dict[str, Dict[str, Any]] = {}
        self._load()

    # ------------------------------------------------------------------ load

    def _load(self) -> None:
        with open(self.path, "r", encoding="utf-8") as handle:
            data = json.load(handle)
        if not isinstance(data, list):
            data = [data]
        self.categories = [c for c in data if isinstance(c, dict)]
        self._by_id = {}
        for category in self.categories:
            for tweak in category.get("tweaks", []):
                tweak.setdefault("category", category.get("category", ""))
                self._by_id[tweak.get("id", "")] = tweak

    # -------------------------------------------------------------- queries

    @property
    def category_names(self) -> List[str]:
        return [c.get("category", "") for c in self.categories]

    def category(self, name: str) -> Optional[Dict[str, Any]]:
        for entry in self.categories:
            if entry.get("category") == name:
                return entry
        return None

    def tweaks_in(self, name: str) -> List[Dict[str, Any]]:
        entry = self.category(name)
        return list(entry.get("tweaks", [])) if entry else []

    def tweak(self, tweak_id: str) -> Optional[Dict[str, Any]]:
        return self._by_id.get(tweak_id)

    def all_tweaks(self) -> List[Dict[str, Any]]:
        return list(self._by_id.values())

    def category_summaries(self) -> List[Dict[str, Any]]:
        """Sidebar entries: name, icon and number of tweaks."""
        summaries = []
        for entry in self.categories:
            name = entry.get("category", "")
            summaries.append(
                {
                    "name": name,
                    "icon": CATEGORY_ICONS.get(name, "cog"),
                    "count": len(entry.get("tweaks", [])),
                    "group": entry.get("group", "Optimization"),
                }
            )
        return summaries

    def search(self, query: str) -> List[Dict[str, Any]]:
        """Find tweaks whose name, description, tags or category match."""
        needle = query.strip().lower()
        if not needle:
            return []
        terms = needle.split()
        matches: List[Dict[str, Any]] = []
        for tweak in self._by_id.values():
            haystack = " ".join(
                str(part)
                for part in (
                    tweak.get("name", ""),
                    tweak.get("description", ""),
                    tweak.get("category", ""),
                    " ".join(tweak.get("tags", []) or []),
                    tweak.get("author", "") or "",
                )
            ).lower()
            if all(term in haystack for term in terms):
                matches.append(tweak)
        return matches

    # -------------------------------------------------------------- helpers

    @staticmethod
    def action_label(tweak: Dict[str, Any]) -> str:
        """Verb shown on the primary button of a card."""
        if tweak.get("is_external"):
            return "Open"
        if tweak.get("is_dynamic"):
            return "Optimize"
        if tweak.get("type") == "nip":
            return "Import"
        return "Apply"

    @staticmethod
    def matches_filter(tweak: Dict[str, Any], filter_key: str) -> bool:
        if not filter_key or filter_key == "all":
            return True
        if filter_key == "safe":
            return tweak.get("risk") == "Safe"
        if filter_key == "moderate":
            return tweak.get("risk") == "Moderate"
        if filter_key == "advanced":
            return tweak.get("risk") == "Advanced"
        if filter_key == "restart":
            return bool(tweak.get("reboot_required"))
        if filter_key == "external":
            return bool(tweak.get("is_external"))
        return True

    @staticmethod
    def badge_rows(tweak: Dict[str, Any]) -> List[Dict[str, str]]:
        """Small factual badges shown on a card."""
        rows: List[Dict[str, str]] = []
        windows = tweak.get("compatibility")
        if windows:
            rows.append({"icon": "layout-grid", "text": windows})
        if tweak.get("requires_admin"):
            rows.append({"icon": "octagon-alert", "text": "Admin"})
        if tweak.get("reboot_required"):
            rows.append({"icon": "arrow-down-to-line", "text": "Restart"})
        if tweak.get("is_external"):
            rows.append({"icon": "download", "text": "Third-party"})
        elif tweak.get("is_dynamic"):
            rows.append({"icon": "loader", "text": "Auto-detect"})
        elif tweak.get("type") == "nip":
            rows.append({"icon": "file-text", "text": "Manual import"})
        return rows

    @staticmethod
    def view_entry(tweak: Dict[str, Any]) -> Dict[str, Any]:
        """Flatten a tweak into the shape the QML card consumes."""
        return {
            "id": tweak.get("id", ""),
            "name": tweak.get("name", ""),
            "description": tweak.get("description", ""),
            "category": tweak.get("category", ""),
            "risk": tweak.get("risk", "Safe"),
            "action": Catalog.action_label(tweak),
            "badges": Catalog.badge_rows(tweak),
            "author": tweak.get("author", "") or "",
            "isExternal": bool(tweak.get("is_external")),
            "needsAdmin": bool(tweak.get("requires_admin")),
            "needsRestart": bool(tweak.get("reboot_required")),
            "reversible": bool(tweak.get("reversal")),
            "logo": tweak.get("logo", ""),
        }

    @staticmethod
    def summarise(entries: Iterable[Dict[str, Any]]) -> Dict[str, int]:
        """Counts used for the subtitle of a view."""
        items = list(entries)
        return {
            "total": len(items),
            "admin": sum(1 for t in items if t.get("requires_admin")),
            "restart": sum(1 for t in items if t.get("reboot_required")),
            "external": sum(1 for t in items if t.get("is_external")),
        }
