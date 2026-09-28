pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

// A soft-blocked (rfkill) radio makes powering on fail silently, and while blocked
// BlueZ may not expose the adapter at all. Turning on therefore clears the block
// first, then waits for the adapter to show up before powering it.
Singleton {
    id: root

    function setEnabled(adapter: var, enabled: bool): void {
        if (!enabled) {
            if (adapter)
                adapter.enabled = false;
            return;
        }
        unblock.running = true;
    }

    function toggle(adapter: var): void {
        setEnabled(adapter, !(adapter?.enabled ?? false));
    }

    Process {
        id: unblock

        command: ["rfkill", "unblock", "bluetooth"]
        onExited: {
            powerOn.attempts = 0;
            powerOn.restart();
        }
    }

    // Retry for a few seconds while BlueZ brings the adapter back
    Timer {
        id: powerOn

        property int attempts: 0

        interval: 300
        onTriggered: {
            const adapter = Bluetooth.defaultAdapter;
            if (adapter) {
                adapter.enabled = true;
                if (adapter.enabled)
                    return;
            }
            if (++attempts < 15)
                restart();
        }
    }
}
