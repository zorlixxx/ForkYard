"""Filesystem and privilege helpers shared by the whole application."""
from __future__ import annotations

import ctypes
import os
import sys
from datetime import datetime


def base_dir() -> str:
    """Return the directory that holds the application resources.

    In a PyInstaller bundle the resources live in the extraction folder, in
    a normal checkout they live next to this module.  The result never
    depends on the current working directory.
    """
    if getattr(sys, "frozen", False):
        bundle = getattr(sys, "_MEIPASS", None)
        if bundle:
            return bundle
        return os.path.dirname(os.path.abspath(sys.executable))
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def writable_dir() -> str:
    """Directory the application may write to.

    Backups and the stored acceptance of the disclaimer belong next to the
    program when it runs from a checkout.  A packaged build keeps them in
    the local application data folder, because the program folder is often
    read only.
    """
    if getattr(sys, "frozen", False):
        base = os.environ.get("LOCALAPPDATA") or os.path.expanduser("~")
        path = os.path.join(base, "ForkYard")
        ensure_dir(path)
        return path
    return base_dir()


def resource_path(*parts: str) -> str:
    """Resolve a path relative to :func:`base_dir`."""
    return os.path.join(base_dir(), *parts)


def is_admin() -> bool:
    """True when the process runs with administrator privileges."""
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return False


def ensure_dir(path: str) -> None:
    """Create ``path`` (and parents) when it does not exist yet."""
    os.makedirs(path, exist_ok=True)


def timestamp() -> str:
    """Timestamp used to name backup folders."""
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def clock_time() -> str:
    """Wall clock time used to prefix log entries."""
    return datetime.now().strftime("%H:%M:%S")
