pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Read-mostly view of how exposed this machine is: tunnels (VPN/Tor), firewall,
// MAC randomisation, and whether anything is using the mic or camera.
// Everything is local except checkIp(), which only runs when asked.
Singleton {
    id: root

    // Tunnels
    property bool vpnActive: false
    property string vpnName: ""
    property bool torInstalled: false
    property bool torActive: false
    readonly property bool tunneled: vpnActive || torActive

    // Local defences
    property bool firewallActive: false
    property string firewallName: ""
    property bool macRandom: false
    property string wifiConnection: ""
    property bool networkingEnabled: true

    // Sensors
    readonly property var micApps: {
        const apps = [];
        for (const node of Pipewire.nodes.values) {
            // Capture streams aren't sinks; ones capturing a sink's monitor (visualisers) aren't using the mic
            if (node.isStream && !node.isSink && node.audio && node.properties["stream.capture.sink"] !== "true")
                apps.push(node.nickname || node.name);
        }
        return apps;
    }
    readonly property bool micInUse: micApps.length > 0
    property bool camInUse: false

    // Public address, fetched on demand only
    property string publicIp: ""
    property string ipCountry: ""
    readonly property bool checkingIp: ipProc.running

    property bool busy: false
    property bool clearBusyOnRefresh: false

    function refresh(): void {
        if (!statusProc.running)
            statusProc.running = true;
    }

    function checkIp(): void {
        publicIp = "";
        ipCountry = "";
        ipProc.running = true;
    }

    function clearIp(): void {
        publicIp = "";
        ipCountry = "";
    }

    function toggleTor(): void {
        run(["systemctl", torActive ? "stop" : "start", "tor.service"]);
    }

    function toggleFirewall(): void {
        run(["systemctl", firewallActive ? "stop" : "start", firewallName || "nftables.service"]);
    }

    // Changing the cloned MAC only applies after reconnecting, so bounce the connection
    function toggleMacRandom(): void {
        if (!wifiConnection)
            return;
        const conn = wifiConnection.replace(/'/g, "'\\''");
        run(["sh", "-c", `nmcli connection modify '${conn}' 802-11-wireless.cloned-mac-address ${macRandom ? "permanent" : "random"} && nmcli connection up '${conn}'`]);
    }

    // Cut the network, wipe the clipboard and lock, in that order
    function panic(): void {
        Quickshell.execDetached(["sh", "-c", "nmcli networking off; wl-copy --clear; wl-copy --primary --clear; cliphist wipe; lumi shell lock lock"]);
        networkingEnabled = false;
        clearIp();
    }

    function restoreNetwork(): void {
        run(["nmcli", "networking", "on"]);
    }

    function run(cmd: list<string>): void {
        busy = true;
        actionProc.command = cmd;
        actionProc.running = true;
    }

    PwObjectTracker {
        objects: Pipewire.nodes.values.filter(n => n.isStream)
    }

    Process {
        id: statusProc

        command: ["sh", "-c", `
            vpn=$(ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | cut -d@ -f1 | grep -E '^(wg|tun|tap|ppp|proton|nordlynx|tailscale|mullvad|ipsec|vpn)' | head -n1)
            [ -z "$vpn" ] && vpn=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="vpn"||$2=="wireguard"{print $1; exit}')
            echo "vpn=$vpn"
            command -v tor >/dev/null && echo tor_installed=1 || echo tor_installed=0
            echo "tor=$(systemctl is-active tor.service 2>/dev/null)"
            fw=""
            for s in nftables firewalld ufw; do [ "$(systemctl is-active $s.service 2>/dev/null)" = active ] && fw=$s.service && break; done
            echo "firewall=$fw"
            wifi=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="802-11-wireless"{print $1; exit}')
            echo "wifi=$wifi"
            [ -n "$wifi" ] && echo "mac=$(nmcli -g 802-11-wireless.cloned-mac-address connection show "$wifi" 2>/dev/null)"
            echo "networking=$(nmcli networking 2>/dev/null)"
            fuser -s /dev/video* 2>/dev/null && echo cam=1 || echo cam=0
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const kv = {};
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        kv[line.slice(0, i)] = line.slice(i + 1);
                }
                root.vpnName = kv.vpn ?? "";
                root.vpnActive = root.vpnName.length > 0;
                root.torInstalled = kv.tor_installed === "1";
                root.torActive = kv.tor === "active";
                root.firewallName = kv.firewall ?? "";
                root.firewallActive = root.firewallName.length > 0;
                root.wifiConnection = kv.wifi ?? "";
                root.macRandom = kv.mac === "random";
                root.networkingEnabled = kv.networking !== "disabled";
                root.camInUse = kv.cam === "1";
                if (root.clearBusyOnRefresh) {
                    root.clearBusyOnRefresh = false;
                    root.busy = false;
                }
            }
        }
    }

    Process {
        id: actionProc

        onExited: {
            root.clearBusyOnRefresh = true;
            root.refresh();
        }
    }

    Process {
        id: ipProc

        command: ["curl", "-s", "--max-time", "8", "https://ifconfig.co/json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const info = JSON.parse(text);
                    root.publicIp = info.ip ?? "";
                    root.ipCountry = info.country ?? "";
                } catch (e) {
                    root.publicIp = "unreachable";
                }
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "privacy"

        function panic(): void {
            root.panic();
        }

        function restoreNetwork(): void {
            root.restoreNetwork();
        }

        function status(): string {
            return JSON.stringify({
                tunneled: root.tunneled,
                vpn: root.vpnName,
                tor: root.torActive,
                firewall: root.firewallName,
                macRandom: root.macRandom,
                mic: root.micApps,
                cam: root.camInUse,
                networking: root.networkingEnabled
            });
        }
    }
}
