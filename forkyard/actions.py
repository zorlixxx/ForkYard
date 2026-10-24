"""Execution of catalog entries.

The module is deliberately free of any UI dependency so the exact same
code path can be exercised from a test harness.  Every entry point
applies the change for real: the caller cannot opt out of the actual
modification, only the confirmation dialogs and the administrator gates
remain.
"""
from __future__ import annotations

import ctypes
import os
import subprocess
import sys
import webbrowser
from typing import Any, Callable, Dict, List, Optional

from .paths import ensure_dir, is_admin, resource_path, timestamp, writable_dir

LogCallback = Callable[[str], None]


class Actions:
    """Runs tweaks, external tools and helper operations safely.

    Every action is applied for real.  Simulation mode has been removed:
    the caller cannot opt out of the actual change, only the confirmation
    dialogs and the administrator gates remain.
    """

    def __init__(self, log_callback: Optional[LogCallback] = None,
                 output_callback: Optional[LogCallback] = None) -> None:
        self.log_callback = log_callback or (lambda *_args, **_kwargs: None)
        # ``output_callback`` receives each line of output produced by a
        # command-line action (bat/cmd/command) while it runs.  It is used
        # to surface genuine command output to the user instead of running
        # scripts invisibly.  May be None.
        self.output_callback = output_callback or (lambda *_args, **_kwargs: None)

    # ------------------------------------------------------------------ log

    def _log(self, message: str) -> None:
        self.log_callback(message)

    def _emit(self, line: str) -> None:
        """Deliver one line of live command output to the UI."""
        self.output_callback(line)

    # ------------------------------------------------------------------ helpers

    def _stream_command(
        self, command: List[str], elevate: bool = False
    ) -> int:
        """Run a shell command, streaming each output line to the UI.

        Returns the process exit code.  Standard error is merged into
        standard output so the user sees warnings and errors too.

        When ``elevate`` is True and the app is not already running with
        administrator rights, the command is launched in a visible elevated
        ``cmd`` window that stays open after the script finishes so the user
        can read the output.  The exit code cannot be captured from a
        separate elevated process, so -1 is returned in that case and the
        user is told to check the visible window.
        """
        if elevate and not is_admin():
            quoted = " ".join(f'"{c}"' if " " in c else c for c in command)
            try:
                ctypes.windll.shell32.ShellExecuteW(
                    None, "runas", "cmd.exe", f'/k {quoted}', None, 1
                )
            except Exception as exc:
                self._emit(f"(could not start elevated process: {exc})")
                return 1
            self._emit("(launched elevated - check the visible console window)")
            return 0

        lines: List[str] = []
        try:
            proc = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
            )
        except Exception as exc:
            self._emit(f"(could not start process: {exc})")
            return 1

        assert proc.stdout is not None
        for raw in proc.stdout:
            line = raw.rstrip("\n")
            lines.append(line)
            self._emit(line)
        proc.wait()
        return proc.returncode

    # -------------------------------------------------------------- dispatch

    def handle_tweak(self, tweak: Dict[str, Any]) -> None:
        """Run the action described by ``tweak``."""
        if tweak.get("is_external"):
            self.handle_external_tool(tweak)
            return

        if tweak.get("is_dynamic"):
            self.apply_smart_ram(tweak)
            return

        file_type = tweak.get("type") or "reg"
        path = resource_path(tweak.get("path", ""))

        if file_type == "reg":
            self.apply_reg_file(tweak, path)
        elif file_type == "bat":
            self.apply_bat_file(tweak, path)
        elif file_type == "cmd":
            self.apply_cmd_file(tweak, path)
        elif file_type == "command":
            self.run_command(tweak)
        elif file_type == "nip":
            self.apply_nip_profile(tweak, path)
        else:
            self._log(f"Unsupported entry type '{file_type}' for '{tweak.get('name', '')}'.")

    # --------------------------------------------------------------- helpers

    @staticmethod
    def _is_uri(value: str) -> bool:
        """True when the value looks like a URI scheme such as ``ms-settings:``."""
        token = value.strip().split()[0] if value.strip() else ""
        if ":" not in token:
            return False
        scheme = token.split(":", 1)[0]
        if len(scheme) < 2:  # a drive letter is a path, not a URI
            return False
        return scheme.replace("-", "").replace("+", "").replace(".", "").isalnum()

    @staticmethod
    def _open_uri(target: str) -> None:
        """Open a web URL in the browser, hand any other URI to the shell."""
        if target.lower().startswith(("http://", "https://")):
            webbrowser.open(target)
        else:
            os.startfile(target)

    def _backup_before_apply(self, tweak: Dict[str, Any], path: str) -> Optional[str]:
        """Copy the source file into a timestamped folder before it is used.

        The copy is a reference for manual restoration; it is not an
        automatic undo of the change that was made.
        """
        try:
            folder = os.path.join(writable_dir(), "backups", timestamp())
            ensure_dir(folder)
            destination = os.path.join(folder, os.path.basename(path))
            import shutil

            shutil.copy2(path, destination)
            return destination
        except Exception as exc:  # pragma: no cover - defensive
            self._log(f"Could not create a backup copy: {exc}")
            return None

    # ----------------------------------------------------------------- types

    def apply_reg_file(self, tweak: Dict[str, Any], path: str) -> None:
        """Import a ``.reg`` file into the registry (or simulate it)."""
        name = tweak.get("name", "Tweak")
        if not os.path.exists(path):
            self._log(f"File not found: {path}")
            return

        try:
            self._backup_before_apply(tweak, path)
            result = subprocess.run(
                ["reg", "import", path], capture_output=True, text=True, shell=True
            )
            if result.returncode == 0:
                message = f"Applied: {name}"
                if tweak.get("reboot_required"):
                    message += " - restart required"
                self._log(message)
            else:
                self._log(f"Failed to apply {name}: {result.stderr.strip()}")
        except Exception as exc:
            self._log(f"Error applying {name}: {exc}")

    def apply_bat_file(self, tweak: Dict[str, Any], path: str) -> None:
        """Run a ``.bat`` file in a visible CMD window."""
        name = tweak.get("name", "Tweak")
        if not os.path.exists(path):
            self._log(f"File not found: {path}")
            return

        try:
            self._backup_before_apply(tweak, path)
            quoted = f'"{path}"'
            if tweak.get("requires_admin") and not is_admin():
                ctypes.windll.shell32.ShellExecuteW(
                    None, "runas", "cmd.exe",
                    f'/k title ForkYard - {name} & {quoted}', None, 1
                )
                self._log(f"{name}: launched in elevated CMD - check the window.")
            else:
                subprocess.Popen(
                    ["cmd.exe", "/k", f"title ForkYard - {name} & {quoted}"],
                    creationflags=subprocess.CREATE_NEW_CONSOLE,
                )
                self._log(f"Applied: {name} - check the CMD window for output.")
        except Exception as exc:
            self._log(f"Error running {name}: {exc}")

    def apply_cmd_file(self, tweak: Dict[str, Any], path: str) -> None:
        """Run a ``.cmd`` file in a visible CMD window."""
        name = tweak.get("name", "Tweak")
        if not os.path.exists(path):
            self._log(f"File not found: {path}")
            return

        try:
            self._backup_before_apply(tweak, path)
            quoted = f'"{path}"'
            if tweak.get("requires_admin") and not is_admin():
                ctypes.windll.shell32.ShellExecuteW(
                    None, "runas", "cmd.exe",
                    f'/k title ForkYard - {name} & {quoted}', None, 1
                )
                self._log(f"{name}: launched in elevated CMD - check the window.")
            else:
                subprocess.Popen(
                    ["cmd.exe", "/k", f"title ForkYard - {name} & {quoted}"],
                    creationflags=subprocess.CREATE_NEW_CONSOLE,
                )
                self._log(f"Applied: {name} - check the CMD window for output.")
        except Exception as exc:
            self._log(f"Error running {name}: {exc}")

    def run_command(self, tweak: Dict[str, Any]) -> None:
        """Run a raw command string, streaming its output to the user."""
        name = tweak.get("name", "Tweak")
        command = tweak.get("command", "")
        if not command:
            self._log(f"No command for {name}.")
            return

        try:
            returncode = self._stream_command(
                command, elevate=tweak.get("requires_admin", False)
            )
            if returncode == 0:
                self._log(f"Applied: {name}")
            elif returncode > 0:
                self._log(f"Failed to run {name} (exit {returncode})")
        except Exception as exc:
            self._log(f"Error running {name}: {exc}")
    def apply_nip_profile(self, tweak: Dict[str, Any], path: str) -> None:
        """Guide a manual import of an NVIDIA ``.nip`` profile.

        NVIDIA Profile Inspector has no reliable command line import, so
        instead of pretending the profile was applied the official tool
        page is opened and the bundled file is revealed in Explorer.
        """
        name = tweak.get("name", "NVIDIA profile")
        if not os.path.exists(path):
            self._log(f"File not found: {path}")
            return

        self._log(f"{name}: manual import required (not applied automatically).")
        self._log("1. Download NVIDIA Profile Inspector from the page that opens.")
        self._log(f"2. The bundled profile is at: {path}")
        self._log("3. In the tool use 'Import Profile(s)' and pick that file.")

        try:
            self._open_uri("https://github.com/Orbmu2k/NvidiaProfileInspector")
            subprocess.Popen(["explorer", "/select,", os.path.normpath(path)])
        except Exception as exc:
            self._log(f"Could not open the profile resources: {exc}")

    def apply_smart_ram(self, tweak: Dict[str, Any]) -> None:
        """Detect the installed RAM and apply the matching registry profile."""
        try:
            import psutil
        except ImportError:
            self._log("psutil is not available, cannot detect the installed memory.")
            return

        name = tweak.get("name", "Smart RAM optimization")
        ram_gb = round(psutil.virtual_memory().total / (1024 ** 3))

        ram_map = {
            4: "4GB RAM OPTIMIZAR.reg",
            6: "6GB RAM OPTIMIZAR.reg",
            8: "8GB RAM OPTIMIZAR.reg",
            12: "12GB RAM OPTIMIZAR.reg",
            16: "16GB RAM OPTIMIZAR.reg",
            24: "24GB RAM OPTIMIZAR.reg",
            32: "32GB RAM OPTIMIZAR.reg",
            64: "64GB RAM OPTIMIZAR.reg",
        }

        target_file = None
        for key in sorted(ram_map):
            if ram_gb <= key:
                target_file = ram_map[key]
                break
        if target_file is None:
            target_file = ram_map[64]

        path = resource_path("recursos", "RAM", target_file)

        if not os.path.exists(path):
            self._log(f"RAM file not found: {path}")
            return

        try:
            self._backup_before_apply(tweak, path)
            result = subprocess.run(
                ["reg", "import", path], capture_output=True, text=True, shell=True
            )
            if result.returncode == 0:
                self._log(f"RAM optimized: {target_file} ({ram_gb}GB detected)")
            else:
                self._log(f"Failed to apply the RAM tweak: {result.stderr.strip()}")
        except Exception as exc:
            self._log(f"Error applying the RAM tweak: {exc}")

    def handle_external_tool(self, tweak: Dict[str, Any]) -> None:
        """Open the official page of a third-party tool."""
        name = tweak.get("name", "Tool")
        url = tweak.get("url")
        command = tweak.get("command")
        path = tweak.get("path")

        try:
            if url:
                self._open_uri(url)
                self._log(f"Opened: {name}")
            elif command and self._is_uri(command):
                self._open_uri(command)
                self._log(f"Opened: {name}")
            elif path:
                full_path = resource_path(path)
                if os.path.exists(full_path):
                    self._log(f"Revealed: {full_path}")
                else:
                    self._log(f"File not found: {full_path}")
            else:
                self._log(f"No official page available for {name}.")
        except Exception as exc:
            self._log(f"Error opening {name}: {exc}")

    # ----------------------------------------------------------- operations

    def create_restore_point(self) -> bool:
        """Create a Windows system restore point.

        ``Checkpoint-Computer`` from Windows PowerShell is used so the
        feature works without an extra Python dependency.
        """
        try:
            result = subprocess.run(
                [
                    "powershell",
                    "-NoProfile",
                    "-NonInteractive",
                    "-Command",
                    "Checkpoint-Computer -Description 'ForkYard restore point' "
                    "-RestorePointType 'MODIFY_SETTINGS'",
                ],
                capture_output=True,
                text=True,
                shell=True,
            )
            if result.returncode == 0:
                self._log("System restore point created")
                return True
            self._log(f"Could not create a restore point: {result.stderr.strip()}")
        except Exception as exc:
            self._log(f"Could not create a restore point: {exc}")
        return False

    def request_admin(self) -> bool:
        """Re-launch the application with administrator privileges."""
        if is_admin():
            return True
        try:
            ctypes.windll.shell32.ShellExecuteW(
                None, "runas", sys.executable, " ".join(sys.argv), None, 1
            )
            return True
        except Exception as exc:
            self._log(f"Could not elevate privileges: {exc}")
            return False

    # ------------------------------------------------------------- describe

    def describe(self, tweak: Dict[str, Any]) -> Dict[str, Any]:
        """Build the structured help payload for a catalog entry."""
        name = tweak.get("name", "Tweak")
        kind = tweak.get("type") or "reg"

        if tweak.get("is_external"):
            applied = (
                "ForkYard opens the official page of the tool in your browser. "
                "Nothing is downloaded, installed or started for you."
            )
        elif tweak.get("is_dynamic"):
            applied = (
                "ForkYard reads the installed memory and imports the matching "
                "registry profile automatically."
            )
        elif kind == "nip":
            applied = (
                "NVIDIA profiles cannot be imported silently. ForkYard opens the "
                "tool page and reveals the bundled .nip file so you can import it "
                "yourself."
            )
        elif kind == "reg":
            applied = (
                "A .reg file is imported into the Windows registry. ForkYard copies "
                "the file into the backups folder before importing it."
            )
        elif kind in ("bat", "cmd"):
            applied = (
                "A Windows script is executed. ForkYard copies the script into the "
                "backups folder before running it."
            )
        elif kind == "command":
            applied = "A single command is executed through the shell."
        else:
            applied = "The linked resource is applied by ForkYard."

        requirements: List[List[str]] = []
        if tweak.get("requires_admin"):
            requirements.append(
                [
                    "Administrator",
                    "Required. ForkYard has to run with elevated privileges for this entry."
                    if not is_admin()
                    else "Required and currently available - ForkYard runs elevated.",
                ]
            )
        else:
            requirements.append(["Administrator", "Not required."])

        requirements.append(
            [
                "Restart",
                "Required after applying." if tweak.get("reboot_required") else "Not required.",
            ]
        )

        reversal = tweak.get("reversal") or ""
        if reversal:
            requirements.append(["Reversal", reversal])
        else:
            requirements.append(
                [
                    "Reversal",
                    "No automatic undo is provided. ForkYard keeps a copy of the "
                    "script in the backups folder so you have a reference.",
                ]
            )

        compatibility = tweak.get("compatibility")
        if compatibility:
            requirements.append(["Windows", compatibility])
        note = tweak.get("compatibility_note")
        if note:
            requirements.append(["Note", note])

        sections: List[Dict[str, Any]] = [
            {"title": "What it does", "body": tweak.get("description", "No description available.")},
            {"title": "How it is applied", "body": applied},
            {"title": "Requirements", "rows": requirements},
        ]

        steps = tweak.get("instructions") or []
        if steps:
            sections.append({"title": "Step by step", "steps": list(steps)})

        if tweak.get("url"):
            sections.append({"title": "Source", "link": tweak["url"]})

        credits: List[List[str]] = []
        for label, key in (("Author", "author"), ("License", "license"), ("Verified", "verification_date")):
            value = tweak.get(key)
            if value:
                credits.append([label, str(value)])
        if credits:
            sections.append({"title": "Credits", "rows": credits})

        return {
            "id": tweak.get("id", ""),
            "name": name,
            "description": tweak.get("description", ""),
            "risk": tweak.get("risk", "Safe"),
            "category": tweak.get("category", ""),
            "action": tweak.get("action", "Apply"),
            "url": tweak.get("url", ""),
            "sections": sections,
        }
