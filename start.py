#!/usr/bin/env python3
"""One-command launcher for NORTE BOUND (Backend API + Admin Web + Flutter App)."""

from __future__ import annotations

import argparse
import functools
import http.server
import os
import shutil
import signal
import socket
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
import webbrowser
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BACKEND_DIR = ROOT / "backend"
ADMIN_WEB_DIR = ROOT / "admin-web"
MOBILE_DIR = ROOT / "mobile"

API_PORT = 5000
WEB_PORT = 5173
HEALTH_URL = f"http://127.0.0.1:{API_PORT}/api/v1/health"
ADMIN_WEB_URL = f"http://127.0.0.1:{WEB_PORT}"

_SPAWNED: list[subprocess.Popen] = []
_WEB_SERVER: http.server.ThreadingHTTPServer | None = None


def is_port_open(host: str, port: int, timeout: float = 0.6) -> bool:
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except OSError:
        return False


def is_health_ok(timeout: float = 1.5) -> bool:
    try:
        with urllib.request.urlopen(HEALTH_URL, timeout=timeout) as resp:
            return resp.status == 200
    except (urllib.error.URLError, OSError):
        return False


def detect_lan_ip() -> str:
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            if ip and not ip.startswith("127."):
                return ip
    except OSError:
        pass
    return "127.0.0.1"


def find_adb() -> str | None:
    adb_on_path = shutil.which("adb")
    if adb_on_path:
        return adb_on_path
    if os.name == "nt":
        local_app_data = os.environ.get("LOCALAPPDATA", "")
        candidate = Path(local_app_data) / "Android" / "Sdk" / "platform-tools" / "adb.exe"
        if candidate.is_file():
            return str(candidate)
    return None


def start_admin_web() -> None:
    global _WEB_SERVER
    if is_port_open("127.0.0.1", WEB_PORT):
        print(f"[admin-web] Already running at {ADMIN_WEB_URL}")
        return

    handler = functools.partial(
        http.server.SimpleHTTPRequestHandler,
        directory=str(ADMIN_WEB_DIR),
    )

    class QuietHandler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=str(ADMIN_WEB_DIR), **kwargs)

        def log_message(self, format, *args):  # noqa: A002
            pass

    del handler
    _WEB_SERVER = http.server.ThreadingHTTPServer(("127.0.0.1", WEB_PORT), QuietHandler)
    thread = threading.Thread(target=_WEB_SERVER.serve_forever, daemon=True)
    thread.start()
    print(f"[admin-web] Serving at {ADMIN_WEB_URL}")


def start_backend() -> None:
    if is_health_ok():
        print(f"[backend]   Already healthy at http://127.0.0.1:{API_PORT}/api/v1")
        return

    env_file = BACKEND_DIR / ".env"
    if not env_file.is_file():
        print("[backend]   Warning: backend/.env is missing. Copy backend/.env.example to backend/.env first.")

    if not (BACKEND_DIR / "node_modules").is_dir():
        print("[backend]   Installing Node dependencies (first run)...")
        subprocess.run("npm install", cwd=str(BACKEND_DIR), shell=True, check=True)

    node_exe = shutil.which("node") or "node"
    proc = subprocess.Popen(
        [node_exe, "src/app.js"],
        cwd=str(BACKEND_DIR),
    )
    _SPAWNED.append(proc)

    deadline = time.time() + 20.0
    while time.time() < deadline:
        if proc.poll() is not None:
            raise RuntimeError(f"Backend exited early with code {proc.returncode}")
        if is_health_ok():
            print(f"[backend]   Ready at http://127.0.0.1:{API_PORT}/api/v1")
            return
        time.sleep(0.5)

    raise TimeoutError(f"Backend did not respond at {HEALTH_URL} within 20s.")


def choose_mode(cli_mode: str | None, lan_ip: str) -> str:
    if cli_mode:
        return cli_mode
    print("\nSelect Flutter client connection mode:")
    print("  1) emulator  - Android Emulator            (http://10.0.2.2:5000/api/v1)")
    print("  2) usb       - Physical Phone via USB      (adb reverse -> http://127.0.0.1:5000/api/v1)")
    print(f"  3) wifi      - Physical Phone via Wi-Fi    (http://{lan_ip}:5000/api/v1)")
    print("  4) web       - Flutter Web in Chrome       (http://localhost:5000/api/v1)")
    print("  5) servers   - Backend + Admin Web only    (do not launch Flutter)")
    choice = input("\nEnter 1-5 [default 1]: ").strip().lower()
    mapping = {
        "": "emulator",
        "1": "emulator",
        "emulator": "emulator",
        "2": "usb",
        "usb": "usb",
        "3": "wifi",
        "wifi": "wifi",
        "4": "web",
        "web": "web",
        "5": "servers",
        "servers": "servers",
    }
    return mapping.get(choice, "emulator")


def setup_adb_reverse(adb_path: str | None) -> None:
    if not adb_path:
        print("[usb]       Warning: adb.exe not found on PATH or Android SDK; skipped adb reverse.")
        return
    res = subprocess.run(
        [adb_path, "reverse", f"tcp:{API_PORT}", f"tcp:{API_PORT}"],
        capture_output=True,
        text=True,
    )
    if res.returncode == 0:
        print(f"[usb]       adb reverse tcp:{API_PORT} -> tcp:{API_PORT} active")
    else:
        detail = (res.stderr or res.stdout).strip() or "no device attached"
        print(f"[usb]       adb reverse warning: {detail}")


def cleanup() -> None:
    if _WEB_SERVER is not None:
        _WEB_SERVER.shutdown()
        _WEB_SERVER.server_close()
    for proc in reversed(_SPAWNED):
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                proc.kill()


def main() -> int:
    parser = argparse.ArgumentParser(description="Start NORTE BOUND services and app.")
    parser.add_argument(
        "--mode",
        choices=["emulator", "usb", "wifi", "web", "servers"],
        help="Target Flutter connection mode",
    )
    parser.add_argument("--no-browser", action="store_true", help="Do not auto-open Admin Web in browser")
    parser.add_argument(
        "--check",
        "--exit-after-check",
        dest="check_only",
        action="store_true",
        help="Verify services/environment and exit immediately",
    )
    args = parser.parse_args()

    def _handle_sig(_sig, _frame):
        cleanup()
        sys.exit(0)

    signal.signal(signal.SIGINT, _handle_sig)
    if hasattr(signal, "SIGTERM"):
        signal.signal(signal.SIGTERM, _handle_sig)

    try:
        print("=== NORTE BOUND Launcher ===")
        start_backend()
        start_admin_web()

        lan_ip = detect_lan_ip()
        adb_path = find_adb()

        print("\nStatus Summary:")
        print(f"  - Backend API:    http://127.0.0.1:{API_PORT}/api/v1")
        print(f"  - Backend (LAN):  http://{lan_ip}:{API_PORT}/api/v1")
        print(f"  - Admin Web:      {ADMIN_WEB_URL}")
        print(f"  - ADB detected:   {adb_path or 'not found'}")

        if args.check_only:
            return 0

        if not args.no_browser:
            webbrowser.open(ADMIN_WEB_URL)

        mode = choose_mode(args.mode, lan_ip)
        if mode == "servers":
            print("\nBackend and Admin Web are active. Press Ctrl+C to stop.")
            while True:
                time.sleep(1)

        if mode == "usb":
            setup_adb_reverse(adb_path)
            api_url = f"http://127.0.0.1:{API_PORT}/api/v1"
            flutter_cmd = f'flutter run --dart-define="API_BASE_URL={api_url}"'
        elif mode == "wifi":
            api_url = f"http://{lan_ip}:{API_PORT}/api/v1"
            flutter_cmd = f'flutter run --dart-define="API_BASE_URL={api_url}"'
        elif mode == "web":
            api_url = f"http://localhost:{API_PORT}/api/v1"
            flutter_cmd = f'flutter run -d chrome --dart-define="API_BASE_URL={api_url}"'
        else:
            api_url = f"http://10.0.2.2:{API_PORT}/api/v1"
            flutter_cmd = f'flutter run --dart-define="API_BASE_URL={api_url}"'

        print(f"\n[flutter]   Launching ({mode}) with API_BASE_URL={api_url}")
        result = subprocess.run(flutter_cmd, cwd=str(MOBILE_DIR), shell=True)
        return result.returncode
    finally:
        cleanup()


if __name__ == "__main__":
    sys.exit(main())
