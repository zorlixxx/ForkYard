"""Bridge between the Python core and the QML interface.

Everything that changes state - the current view, the activity log - lives
here.  QML never touches the file system or the registry directly; it asks
the controller, the controller decides.
"""
from __future__ import annotations

import os
import threading
import ctypes
try:
    _winmm = ctypes.WinDLL("winmm")
except Exception:
    _winmm = None
try:
    import winsound
except ImportError:
    winsound = None
import webbrowser
from typing import Any, Dict, List, Optional

from PySide6.QtCore import QObject, QThread, Property, Signal, Slot

from .actions import Actions
from .catalog import Catalog
from .paths import clock_time, is_admin, resource_path, writable_dir

DISCLAIMER_FILE = ".forkyard_accepted"

DEVELOPER_LINKS = [
    {"label": "GitHub", "url": "https://github.com/zorlixxx", "hint": "Developer profile",
     "icon": "github", "accent": "#E6EDF3"},
    {"label": "Website", "url": "https://ysn.lol/zorlix", "hint": "Developer personal site",
     "icon": "globe", "accent": "#5E9CE6"},
    {"label": "Ko-fi", "url": "https://ko-fi.com/zorlix", "hint": "Support the project",
     "icon": "heart", "accent": "#FF5E5B"},
]


def classify(message: str) -> str:
    """Map a log line onto the severity used by the activity panel."""
    text = message.strip()
    if text.startswith(("Applied", "Opened", "Launched", "RAM optimized", "System restore point")):
        return "ok"
    if text.startswith(("Error", "Failed", "File not found", "Could not", "Unsupported")):
        return "error"
    if "Warning" in text or "restart required" in text:
        return "warn"
    return "info"


class _ActionWorker(QObject):
    """Runs catalog actions off the UI thread."""

    logged = Signal(str)
    completed = Signal(str, bool, int)
    outputLine = Signal(str)

    def __init__(self, catalog: Catalog) -> None:
        super().__init__()
        self._catalog = catalog

    @Slot(str)
    def execute(self, tweak_id: str) -> None:
        tweak = self._catalog.tweak(tweak_id)
        if tweak is None:
            self.logged.emit(f"Unknown entry: {tweak_id}")
            self.completed.emit(tweak_id, False, -1)
            return

        actions = Actions(log_callback=self.logged.emit,
                          output_callback=self.outputLine.emit)
        try:
            exit_code = actions.handle_tweak(tweak)
            ok = True
        except Exception as exc:  # pragma: no cover - defensive
            self.logged.emit(f"Error while running '{tweak.get('name', tweak_id)}': {exc}")
            ok = False
            exit_code = -1
        self.completed.emit(tweak_id, ok, exit_code)


class Controller(QObject):
    """Application state exposed to QML."""

    categoriesChanged = Signal()
    viewChanged = Signal()
    logChanged = Signal()
    stateChanged = Signal()
    busyChanged = Signal()
    disclaimerDone = Signal()

    dispatchRequested = Signal(str)
    outputLine = Signal(str)

    def __init__(self, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self.catalog = Catalog()
        self._categories = self.catalog.category_summaries()
        self._current_category = self._categories[0]["name"] if self._categories else ""
        self._search_query = ""
        self._active_filter = "all"
        self._admin = is_admin()
        self._busy = False
        self._log: List[Dict[str, str]] = []
        self._entries: List[Dict[str, Any]] = []
        self._title = ""
        self._subtitle = ""

        self._thread = QThread(self)
        self._worker = _ActionWorker(self.catalog)
        self._worker.moveToThread(self._thread)
        self._worker.logged.connect(self._append_log)
        self._worker.outputLine.connect(self.outputLine.emit)
        self._worker.outputLine.connect(self._append_log)
        self._worker.completed.connect(self._on_action_completed)
        self._thread.finished.connect(self._worker.deleteLater)
        self.dispatchRequested.connect(self._worker.execute)
        self._thread.start()

        self._rebuild_view()
        self._append_log("ForkYard ready.")
        if not self._admin:
            self._append_log("Warning: not running as administrator, some entries will fail.")

    # ----------------------------------------------------------- properties

    @Property("QVariantList", notify=categoriesChanged)
    def categories(self) -> List[Dict[str, Any]]:
        return self._categories

    @Property("QVariantList", notify=viewChanged)
    def entries(self) -> List[Dict[str, Any]]:
        return self._entries

    @Property(str, notify=viewChanged)
    def viewTitle(self) -> str:
        return self._title

    @Property(str, notify=viewChanged)
    def viewSubtitle(self) -> str:
        return self._subtitle

    @Property(str, notify=viewChanged)
    def currentCategory(self) -> str:
        return self._current_category

    @Property(str, notify=viewChanged)
    def searchQuery(self) -> str:
        return self._search_query

    @Property(str, notify=viewChanged)
    def activeFilter(self) -> str:
        return self._active_filter

    @Property(bool, notify=stateChanged)
    def isAdmin(self) -> bool:
        return self._admin

    @Property(bool, notify=stateChanged)
    def disclaimerAccepted(self) -> bool:
        return os.path.exists(os.path.join(writable_dir(), DISCLAIMER_FILE))

    @Property("QVariantList", notify=logChanged)
    def logEntries(self) -> List[Dict[str, str]]:
        return self._log

    @Property(bool, notify=busyChanged)
    def busy(self) -> bool:
        return self._busy

    @Property("QVariantList", constant=True)
    def developerLinks(self) -> List[Dict[str, str]]:
        return DEVELOPER_LINKS

    @Property("QVariantList", constant=True)
    def filters(self) -> List[Dict[str, str]]:
        return [{"key": key, "label": label} for key, label in Catalog.FILTERS]

    # -------------------------------------------------------------- setters

    @Slot(str)
    def selectCategory(self, name: str) -> None:
        if name == self._current_category and not self._search_query:
            return
        self._current_category = name
        self._search_query = ""
        self._rebuild_view()

    @Slot(str)
    def setSearchQuery(self, query: str) -> None:
        if query == self._search_query:
            return
        self._search_query = query
        self._rebuild_view()

    @Slot(str)
    def setFilter(self, key: str) -> None:
        if key == self._active_filter:
            return
        self._active_filter = key
        self._rebuild_view()

    # ------------------------------------------------------------- actions

    @Slot(str, result="QVariantMap")
    def planTweak(self, tweak_id: str) -> Dict[str, Any]:
        """Build the confirmation steps that precede an action.

        The returned list is shown to the user one dialog at a time.  An
        empty ``prompts`` list means the action can run straight away.
        """
        tweak = self.catalog.tweak(tweak_id)
        if tweak is None:
            return {"prompts": [], "error": "Unknown entry"}

        prompts: List[Dict[str, str]] = []
        risk = tweak.get("risk", "Safe")
        name = tweak.get("name", "entry")

        # Every non-external entry requires explicit confirmation so the user
        # always knows what is about to be applied.  Risky entries get a
        # detailed warning; safe ones get a concise prompt.
        if not tweak.get("is_external"):
            if risk in ("Moderate", "Advanced"):
                body = (
                    f"Apply '{name}'?\n\n"
                    f"Risk level: {risk}\n\n"
                    "This writes to the Windows registry or runs a system script and "
                    "can change how other programs behave."
                )
            else:
                body = (
                    f"Apply '{name}'?\n\n"
                    f"Risk level: {risk} (low risk)\n\n"
                    "This entry will be applied to your system."
                )
            prompts.append(
                {
                    "kind": "confirm",
                    "title": "Confirm tweak",
                    "body": body,
                    "confirmLabel": "Apply",
                    "cancelLabel": "Cancel",
                }
            )
        elif risk in ("Moderate", "Advanced"):
            title = "Open external tool"
            body = (
                f"Open '{name}' in your browser?\n\n"
                f"Risk level: {risk}\n\n"
                "ForkYard only opens the official page of this tool. Nothing is "
                "downloaded, installed or started for you."
            )
            prompts.append(
                {
                    "kind": "confirm",
                    "title": title,
                    "body": body,
                    "confirmLabel": "Open",
                    "cancelLabel": "Cancel",
                }
            )
        if tweak.get("type") == "nip":
            prompts.append(
                {
                    "kind": "info",
                    "title": "Manual import required",
                    "body": (
                        "This NVIDIA profile cannot be imported automatically.\n\n"
                        "1. Download NVIDIA Profile Inspector from its official page.\n"
                        f"2. The bundled profile is at:\n{resource_path(tweak.get('path', ''))}\n"
                        "3. In the tool choose 'Import Profile(s)' and select the file."
                    ),
                    "confirmLabel": "Continue",
                    "cancelLabel": "Close",
                }
            )

        if tweak.get("reboot_required"):
            prompts.append(
                {
                    "kind": "info",
                    "title": "Restart required",
                    "body": (
                        "A restart is required for this entry to take effect.\n\n"
                        "Finish the changes first and restart Windows when it is "
                        "convenient."
                    ),
                    "confirmLabel": "Understood",
                    "cancelLabel": "Close",
                }
            )

        return {"prompts": prompts, "error": "", "isExternal": bool(tweak.get("is_external")), "isCommandLine": (tweak.get("type") in ("bat", "cmd"))}

    @Slot(str)
    def executeTweak(self, tweak_id: str) -> None:
        """Run an entry after the user confirmed every prompt."""
        if self._busy:
            self._append_log("An operation is already running. Please wait for it to finish.")
            return
        tweak = self.catalog.tweak(tweak_id)
        if tweak is None:
            self._append_log(f"Unknown entry: {tweak_id}")
            return
        if tweak.get("is_external"):
            self._actions().handle_external_tool(tweak)
            return
        self._set_busy(True)
        self.dispatchRequested.emit(tweak_id)

    @Slot(str)
    def launchExternal(self, tweak_id: str) -> None:
        """Open an external tool's official page without running anything."""
        tweak = self.catalog.tweak(tweak_id)
        if tweak is None:
            self._append_log(f"Unknown entry: {tweak_id}")
            return
        self._actions().handle_external_tool(tweak)

    @Slot(str, result="QVariantMap")
    def tweakDetail(self, tweak_id: str) -> Dict[str, Any]:
        """Structured help content for one entry."""
        tweak = self.catalog.tweak(tweak_id)
        if tweak is None:
            return {"name": "Unknown entry", "sections": []}
        payload = self._actions().describe(tweak)
        payload["logo"] = tweak.get("logo", "")
        return payload

    @Slot(str)
    def openUri(self, url: str) -> None:
        """Open a link outside of the application."""
        if not url:
            return
        try:
            if url.lower().startswith(("http://", "https://")):
                webbrowser.open(url)
            else:
                os.startfile(url)
            self._append_log(f"Opened in your browser: {url}")
        except Exception as exc:
            self._append_log(f"Could not open {url}: {exc}")

    @Slot()
    def acceptDisclaimer(self) -> None:
        try:
            with open(os.path.join(writable_dir(), DISCLAIMER_FILE), "w", encoding="utf-8") as handle:
                handle.write("accepted")
        except Exception as exc:
            self._append_log(f"Could not store the disclaimer acceptance: {exc}")
        self.stateChanged.emit()
        self.disclaimerDone.emit()
        self._append_log("Notice accepted.")

    @Slot()
    def createRestorePoint(self) -> None:
        actions = self._actions()
        actions.create_restore_point()

    @Slot()
    def clearLog(self) -> None:
        self._log.clear()
        self.logChanged.emit()

    @Slot()
    def requestElevation(self) -> None:
        actions = self._actions()
        if not actions.request_admin():
            self._append_log("Could not request administrator privileges.")

    @Slot(str)
    def copyToClipboard(self, text: str) -> None:
        from PySide6.QtGui import QGuiApplication

        clipboard = QGuiApplication.clipboard()
        if clipboard is not None:
            clipboard.setText(text)
            self._append_log("Details copied to the clipboard.")

    # -------------------------------------------------------------- helpers

    def _actions(self) -> Actions:
        return Actions(log_callback=self._append_log)

    def _set_busy(self, value: bool) -> None:
        if self._busy != value:
            self._busy = value
            self.busyChanged.emit()

    def _on_action_completed(self, _tweak_id: str, ok: bool, _exit_code: int) -> None:
        self._set_busy(False)
        if not ok:
            self.playSound("error")

    def _append_log(self, message: str) -> None:
        self._log.append({"time": clock_time(), "text": message, "level": classify(message)})
        if len(self._log) > 400:
            del self._log[: len(self._log) - 400]
        self.logChanged.emit()

    @Slot(result="QVariant")
    def cursorGlobal(self) -> Any:
        """Return the global cursor position for the decorative trail."""
        from PySide6.QtGui import QCursor
        point = QCursor.pos()
        return {"x": point.x(), "y": point.y()}

    @Slot(str)
    def playSound(self, name: str) -> None:
        """Play a short UI sound asynchronously (.wav via winsound, .mp3 via Windows MCI)."""
        if winsound is None:
            print(f"[sound] winsound not available, skipping {name}")
            return
        path = self._assets_sound_path(name)
        if path and os.path.exists(path):
            print(f"[sound] playing {name} -> {path}")
            try:
                if path.lower().endswith(".mp3"):
                    self._play_mp3(path)
                else:
                    winsound.PlaySound(path, winsound.SND_FILENAME | winsound.SND_ASYNC | winsound.SND_NODEFAULT)
            except Exception as exc:
                print(f"[sound] play failed for {name} ({path}): {exc}")
        else:
            print(f"[sound] file not found for {name}")

    def _play_mp3(self, path: str) -> None:
        """Play an .mp3 file asynchronously using Windows MCI in a background thread."""
        if _winmm is None:
            print(f"[sound] winmm.dll not available, cannot play {path}")
            return
        def _play() -> None:
            alias = "forkyard_sound_" + str(abs(hash(path)))
            try:
                _winmm.mciSendStringW(f"close {alias}".replace("/", "\\"), None, 0, None)
                quoted = path.replace("/", "\\")
                _winmm.mciSendStringW(f'open "{quoted}" alias {alias}', None, 0, None)
                _winmm.mciSendStringW(f"play {alias}", None, 0, None)
            except Exception as exc:
                print(f"[sound] MCI play failed for {path}: {exc}")
        t = threading.Thread(target=_play, daemon=True)
        t.start()

    def _assets_sound_path(self, name: str) -> Optional[str]:
        from .paths import base_dir
        sounds_dir = os.path.join(base_dir(), "assets", "sounds")
        if not os.path.isdir(sounds_dir):
            return None
        # Variantes del nombre a probar: tal cual, con guiones->espacios, y viceversa.
        variants = {
            name,
            name.replace("-", " "),
            name.replace(" ", "-"),
        }
        exts = (".wav", ".mp3")
        # Primera pasada: coincidencia exacta (case-sensitive) de cualquiera de las variantes.
        for variant in variants:
            for ext in exts:
                candidate = os.path.join(sounds_dir, variant + ext)
                if os.path.exists(candidate):
                    return candidate
        # Segunda pasada: coincidencia case-insensitive contra los archivos reales del directorio.
        try:
            real_files = os.listdir(sounds_dir)
        except OSError:
            real_files = []
        for variant in variants:
            lower_variant = variant.lower()
            for rf in real_files:
                lower_rf = rf.lower()
                for ext in exts:
                    if lower_rf == lower_variant + ext:
                        return os.path.join(sounds_dir, rf)
        return None

    def _rebuild_view(self) -> None:
        query = self._search_query.strip()
        if query:
            source = self.catalog.search(query)
            self._title = f'Search results for "{query}"'
        else:
            source = self.catalog.tweaks_in(self._current_category)
            self._title = self._current_category

        filtered = [t for t in source if Catalog.matches_filter(t, self._active_filter)]
        self._entries = [Catalog.view_entry(t) for t in filtered]

        stats = Catalog.summarise(filtered)
        parts = [f"{stats['total']} entr{'y' if stats['total'] == 1 else 'ies'}"]
        if stats["admin"]:
            parts.append(f"{stats['admin']} need administrator rights")
        if stats["restart"]:
            parts.append(f"{stats['restart']} need a restart")
        if stats["external"]:
            parts.append(f"{stats['external']} external tools")
        self._subtitle = " - ".join(parts)

        self.viewChanged.emit()

    def shutdown(self) -> None:
        """Stop the worker thread before the application quits."""
        if self._thread is None:
            return
        try:
            self.dispatchRequested.disconnect()
        except (RuntimeError, TypeError):
            pass
        self._thread.quit()
        if not self._thread.wait(2000):
            self._thread.terminate()
            self._thread.wait(500)
        self._thread = None

    def __del__(self) -> None:
        # The worker thread must never outlive the controller, otherwise Qt
        # aborts the process with "QThread: Destroyed while thread is still
        # running" when the interpreter tears the object down.
        try:
            self.shutdown()
        except Exception:
            pass
