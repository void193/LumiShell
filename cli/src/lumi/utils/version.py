import shutil
import subprocess
import sys

PKGS = ("lumi-shell", "quickshell-git")
INDENT = "    "


def _header(text: str, suffix: str = "") -> None:
    suffix = f" {suffix}" if suffix else ""
    if sys.stdout.isatty():
        print(f"\033[1;36m{text}\033[0m{suffix}")
    else:
        print(f"{text}{suffix}")


def _query(pkg: str) -> str | None:
    try:
        return subprocess.check_output(["pacman", "-Q", pkg], text=True, stderr=subprocess.DEVNULL).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def print_version() -> None:
    if shutil.which("pacman"):
        _header("Packages:")
        for pkg in PKGS:
            print(f"{INDENT}{_query(pkg) or f'{pkg} not installed'}")
    else:
        _header("Packages:", "not on Arch")

    print()
    try:
        shell_ver = subprocess.check_output(["/usr/lib/lumi/version", "-s"], text=True).strip()
        _header("Shell:")
        print(f"{INDENT}{shell_ver}")
    except FileNotFoundError:
        _header("Shell:", "version helper not available")

    print()
    if shutil.which("qs"):
        qs_ver = subprocess.check_output(["qs", "--version"], text=True).strip()
        _header("Quickshell:")
        print(f"{INDENT}{qs_ver}")
    else:
        _header("Quickshell:", "not in PATH")
