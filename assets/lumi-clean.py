#!/usr/bin/env python3
"""Find and close memory-hungry apps, safely.

  lumi-clean.py scan              -> JSON list of candidates
  lumi-clean.py clean PID [PID..] -> JSON result {closed, forced, freedMB}

Safety rules:
  - only processes owned by the current user; never root/system processes
  - never anything the desktop needs (compositor, shell, audio, portals, keyring...)
  - processes are grouped into apps (a main process plus its children), and an
    app is "windowed" if it or any ancestor owns a window (a terminal counts, so
    anything running inside a terminal is treated as the terminal's work)
  - windowed apps are only suggested, never preselected; background apps are
    preselected only when they use a lot of memory
  - closing asks politely (SIGTERM); only background apps are forced (SIGKILL)
    if they ignore it, and every PID is re-checked right before signalling
"""

import json
import os
import signal
import subprocess
import sys
import time

# Session plumbing and desktop essentials: never shown, never touched
PROTECTED = {
    "hyprland", "qs", "quickshell", "xwayland", "systemd", "(sd-pam)", "dbus-daemon", "dbus-broker",
    "dbus-broker-lau", "pipewire", "pipewire-pulse", "wireplumber", "xdg-desktop-por", "xdg-document-po",
    "xdg-permission-", "polkit-gnome-au", "gnome-keyring-d", "gpg-agent", "ssh-agent", "hypridle",
    "hyprsunset", "hyprlock", "eww", "cliphist", "wl-paste", "mpris-proxy", "agent", "at-spi-bus-laun",
    "at-spi2-registr", "dconf-service", "gvfsd", "gvfsd-fuse", "gvfs-udisks2-vo", "tor", "lumi", "login",
    "bash", "zsh", "fish", "sh", "sudo",
}
# Launch wrappers: an app's group stops climbing when it reaches one of these
LAUNCHERS = {"sh", "bash", "zsh", "fish", "dash", "uwsm", "app2unit", "systemd-run", "env", "setsid"}

BACKGROUND_SHARE = 0.05  # preselect background apps above 5% of RAM
WINDOWED_SHARE = 0.03  # suggest windowed apps above 3% of RAM


def read(path: str) -> str:
    try:
        with open(path) as f:
            return f.read()
    except OSError:
        return ""


def meminfo_kb(key: str) -> int:
    for line in read("/proc/meminfo").splitlines():
        if line.startswith(key + ":"):
            return int(line.split()[1])
    return 0


def pss_kb(pid: int, status_fields: dict) -> int:
    """Proportional set size: shared pages are split between their users, so summing
    across an app's processes doesn't count shared memory many times over."""
    for line in read(f"/proc/{pid}/smaps_rollup").splitlines():
        if line.startswith("Pss:"):
            return int(line.split()[1])
    rss = status_fields.get("VmRSS")
    return int(rss.split()[0]) if rss else 0


def processes() -> dict[int, dict]:
    uid = os.getuid()
    procs = {}
    for entry in os.listdir("/proc"):
        if not entry.isdigit():
            continue
        pid = int(entry)
        status = read(f"/proc/{pid}/status")
        if not status:
            continue
        fields = dict(line.split(":", 1) for line in status.splitlines() if ":" in line)
        if int(fields.get("Uid", "-1").split()[0]) != uid:
            continue
        rss_kb = pss_kb(pid, fields)
        procs[pid] = {
            "pid": pid,
            "ppid": int(fields.get("PPid", "0").strip()),
            "name": fields.get("Name", "").strip(),
            "rss": rss_kb,
        }
    return procs


def window_pids() -> set[int]:
    try:
        out = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, timeout=5).stdout
        return {c["pid"] for c in json.loads(out) if c.get("pid", 0) > 0}
    except (OSError, ValueError, subprocess.SubprocessError):
        return set()


def ancestors(pid: int, procs: dict) -> list[int]:
    chain = []
    seen = set()
    while pid in procs and pid not in seen:
        seen.add(pid)
        chain.append(pid)
        pid = procs[pid]["ppid"]
    return chain


def app_root(pid: int, procs: dict, windows: set[int]) -> int:
    """Climb to the app's main process, stopping at session roots, launch wrappers, and
    windows (an app opened from another app, like a browser from a chat link, is its own app)."""
    root = pid
    for pid_ in ancestors(pid, procs)[1:]:
        if root in windows:
            break
        name = procs[pid_]["name"].lower()
        if name in LAUNCHERS or name in PROTECTED or procs[pid_]["ppid"] in (0, 1):
            break
        root = pid_
    return root


def is_protected(pid: int, procs: dict) -> bool:
    return procs[pid]["name"].lower() in PROTECTED or pid == os.getpid()


def scan() -> list[dict]:
    procs = processes()
    windows = window_pids()
    total_kb = meminfo_kb("MemTotal")
    own_chain = set(ancestors(os.getpid(), procs))

    apps: dict[int, dict] = {}
    for pid in procs:
        root = app_root(pid, procs, windows)
        app = apps.setdefault(root, {"pid": root, "rss": 0, "windowed": False, "pids": []})
        app["rss"] += procs[pid]["rss"]
        app["pids"].append(pid)
        if any(a in windows for a in ancestors(pid, procs)):
            app["windowed"] = True

    candidates = []
    for root, app in apps.items():
        if root not in procs or is_protected(root, procs) or root in own_chain:
            continue
        share = app["rss"] / total_kb if total_kb else 0
        if share < (WINDOWED_SHARE if app["windowed"] else BACKGROUND_SHARE * 0.6):
            continue
        candidates.append({
            "pid": root,
            "name": procs[root]["name"],
            "mb": round(app["rss"] / 1024),
            "percent": round(share * 100, 1),
            "windowed": app["windowed"],
            "selected": not app["windowed"] and share >= BACKGROUND_SHARE,
        })

    candidates.sort(key=lambda c: -c["mb"])
    return candidates[:8]


def clean(pids: list[int]) -> dict:
    before = meminfo_kb("MemAvailable")
    procs = processes()
    windows = window_pids()
    own_chain = set(ancestors(os.getpid(), procs))

    targets = []
    for pid in pids:
        # Re-check everything: the PID could have been reused since the scan
        if pid not in procs or is_protected(pid, procs) or pid in own_chain:
            continue
        windowed = any(a in windows for a in ancestors(pid, procs))
        targets.append((pid, windowed))
        try:
            os.kill(pid, signal.SIGTERM)
        except OSError:
            pass

    # Give apps a few seconds to save and quit
    deadline = time.time() + 5
    while time.time() < deadline and any(os.path.exists(f"/proc/{p}") for p, _ in targets):
        time.sleep(0.25)

    forced = 0
    for pid, windowed in targets:
        if os.path.exists(f"/proc/{pid}") and not windowed:
            try:
                os.kill(pid, signal.SIGKILL)
                forced += 1
            except OSError:
                pass

    time.sleep(1)
    freed_mb = max(0, round((meminfo_kb("MemAvailable") - before) / 1024))
    return {"closed": len(targets), "forced": forced, "freedMB": freed_mb}


def main() -> int:
    if len(sys.argv) >= 2 and sys.argv[1] == "scan":
        print(json.dumps(scan()))
        return 0
    if len(sys.argv) >= 3 and sys.argv[1] == "clean":
        print(json.dumps(clean([int(p) for p in sys.argv[2:] if p.isdigit()])))
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
