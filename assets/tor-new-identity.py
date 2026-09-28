#!/usr/bin/env python3
"""Give Tor a new identity that apps actually notice.

SIGNAL NEWNYM only affects new connections, and browsers keep connections alive
for minutes, so they would keep showing the old exit IP. After NEWNYM this
closes every open circuit, which drops those connections and forces a reconnect
through a fresh circuit.

Usage: tor-new-identity.py <control-password-file>
Prints "ok <closed circuits>" on success, or an error and exits non-zero.
"""

import socket
import sys


def control(password: str, *commands: str) -> str:
    with socket.create_connection(("127.0.0.1", 9051), timeout=10) as sock:
        payload = f'AUTHENTICATE "{password}"\r\n' + "".join(f"{c}\r\n" for c in commands) + "QUIT\r\n"
        sock.sendall(payload.encode())
        reply = b""
        while chunk := sock.recv(65536):
            reply += chunk
    return reply.decode(errors="replace")


def main() -> int:
    try:
        password = open(sys.argv[1]).read().strip()
        reply = control(password, "SIGNAL NEWNYM", "GETINFO circuit-status")
    except (OSError, IndexError) as e:
        print(f"error {e}")
        return 1

    lines = reply.split("\r\n")
    if not lines or not lines[0].startswith("250") or len(lines) < 2 or not lines[1].startswith("250"):
        print(f"error {lines[0] if lines else 'no reply'}")
        return 1

    # Circuit lines look like "279 BUILT $FP~name,... PURPOSE=GENERAL ..."
    circuits = [line.split()[0] for line in lines if line.split() and line.split()[0].isdigit()]
    if circuits:
        control(password, *(f"CLOSECIRCUIT {c}" for c in circuits))

    print(f"ok {len(circuits)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
