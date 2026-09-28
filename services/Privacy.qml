pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Lumi
import Lumi.Config
import qs.utils

// Read-mostly view of how exposed this machine is: tunnels (VPN/Tor), firewall,
// MAC randomisation, and whether anything is using the mic or camera.
// Everything is local except IP checks, which only run when asked or right after a
// Tor identity change. Tor mode routes system-proxy apps (e.g. Firefox) through Tor
// and can rotate the exit IP on a timer.
Singleton {
    id: root

    // Tunnels
    property bool vpnActive: false
    property string vpnName: ""
    property bool torInstalled: false
    property bool torActive: false
    property bool torProxy: false // system proxy points at Tor's SOCKS port
    property bool torControl: false // lumi-tor-setup has run (control port password exists)
    readonly property bool torRouting: torActive && torProxy
    readonly property bool tunneled: vpnActive || torRouting

    // Tor exit, checked through Tor itself
    property string torExitIp: ""
    property string torExitCountry: ""
    readonly property bool checkingExit: exitProc.running

    // Identity rotation; the interval is saved in the state dir
    readonly property int rotateMinutes: store.rotateMinutes
    property double nextRotateAt: 0
    readonly property bool rotating: identityProc.running
    readonly property string torKeyPath: `${Paths.config}/tor-control.key`

    // Local defences
    property bool firewallActive: false
    property string firewallName: ""
    property bool firewallInstalled: false // lumi-firewall.service exists
    readonly property string firewallUnit: "lumi-firewall.service"
    property bool macRandom: false
    property string wifiConnection: ""
    property bool networkingEnabled: true

    // Sockets: listeners reachable from the network, and live connections
    property var exposedPorts: [] // [{ proto, port, proc }]
    property int localPorts: 0
    property int connections: 0

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

    // Clipboard auto-clear; the delay lives in config so it survives restarts
    readonly property int clipboardClearDelay: GlobalConfig.services.clipboardClearDelay ?? 0
    readonly property bool clipboardAutoClear: clipboardClearDelay > 0
    property bool ignoreClipboardEvents: false

    function setClipboardAutoClear(enabled: bool): void {
        GlobalConfig.services.clipboardClearDelay = enabled ? 45 : 0;
    }

    property bool busy: false
    property bool firewallRestored: false
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

    // Tor mode = tor.service + the system SOCKS proxy; both go on and off together
    function toggleTor(): void {
        if (torRouting || torActive) {
            torExitIp = "";
            torExitCountry = "";
            run(["sh", "-c", "gsettings set org.gnome.system.proxy mode none; systemctl stop tor.service"]);
        } else {
            run(["sh", "-c", "systemctl start tor.service && gsettings set org.gnome.system.proxy.socks host 127.0.0.1 && gsettings set org.gnome.system.proxy.socks port 9050 && gsettings set org.gnome.system.proxy mode manual"]);
            exitRetry.attempts = 0;
            exitRetry.restart();
        }
    }

    // Also covers shell restarts while Tor mode is already on
    onTorRoutingChanged: {
        if (torRouting && !torExitIp) {
            exitRetry.attempts = 0;
            exitRetry.restart();
        }
    }

    function setRotateMinutes(minutes: int): void {
        store.rotateMinutes = minutes;
        nextRotateAt = minutes > 0 ? Date.now() + minutes * 60000 : 0;
    }

    // Ask Tor for fresh circuits: new connections get a new exit IP
    function newIdentity(): void {
        if (!torActive || !torControl || identityProc.running)
            return;
        identityProc.running = true;
    }

    function checkExit(): void {
        if (torActive && !exitProc.running)
            exitProc.running = true;
    }

    // lumi-firewall.service (from lumi-tor-setup) keeps state and can be stopped;
    // Arch's own nftables.service only loads rules and reports inactive
    function toggleFirewall(): void {
        const enable = !firewallActive;
        store.firewall = enable;
        run(["systemctl", enable ? "start" : "stop", firewallUnit]);
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
            for s in lumi-firewall firewalld ufw; do [ "$(systemctl is-active $s.service 2>/dev/null)" = active ] && fw=$s.service && break; done
            echo "firewall=$fw"
            [ -f /etc/systemd/system/lumi-firewall.service ] && echo fwunit=1 || echo fwunit=0
            wifi=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="802-11-wireless"{print $1; exit}')
            echo "wifi=$wifi"
            [ -n "$wifi" ] && echo "mac=$(nmcli -g 802-11-wireless.cloned-mac-address connection show "$wifi" 2>/dev/null)"
            echo "networking=$(nmcli networking 2>/dev/null)"
            fuser -s /dev/video* 2>/dev/null && echo cam=1 || echo cam=0
            ss -Htulnp 2>/dev/null | awk '{ p=""; if (match($7, /"[^"]+"/)) p=substr($7, RSTART+1, RLENGTH-2); print "sock=" $1 "|" $5 "|" p }'
            echo "conn=$(ss -Htun state established 2>/dev/null | wc -l)"
            echo "proxy=$(gsettings get org.gnome.system.proxy mode 2>/dev/null)|$(gsettings get org.gnome.system.proxy.socks port 2>/dev/null)"
            [ -s "${root.torKeyPath}" ] && echo torctl=1 || echo torctl=0
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const kv = {};
                const socks = [];
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf("=");
                    if (i <= 0)
                        continue;
                    if (line.startsWith("sock="))
                        socks.push(line.slice(5));
                    else
                        kv[line.slice(0, i)] = line.slice(i + 1);
                }

                // Loopback listeners can't be reached from outside; everything else can
                const exposed = [];
                let local = 0;
                for (const sock of socks) {
                    const [proto, addr, proc] = sock.split("|");
                    const cut = addr.lastIndexOf(":");
                    const host = addr.slice(0, cut).replace(/^\[|\]$/g, "").replace(/%.*$/, "");
                    const port = addr.slice(cut + 1);
                    if (host.startsWith("127.") || host === "::1" || host === "localhost")
                        local++;
                    // UDP sockets in the ephemeral range are clients (browsers, calls), not services
                    else if (proto === "udp" && parseInt(port) >= 32768)
                        continue;
                    // mDNS is local discovery, not something to connect to
                    else if (proto === "udp" && port === "5353")
                        continue;
                    // The Lumi firewall drops unsolicited inbound traffic except ssh
                    else if (kv.firewall === root.firewallUnit && !(proto === "tcp" && port === "22"))
                        continue;
                    else if (!exposed.some(e => e.proto === proto && e.port === port))
                        exposed.push({ proto: proto, port: port, proc: proc || "?" });
                }
                root.exposedPorts = exposed;
                root.localPorts = local;
                root.connections = parseInt(kv.conn) || 0;
                root.vpnName = kv.vpn ?? "";
                root.vpnActive = root.vpnName.length > 0;
                root.torInstalled = kv.tor_installed === "1";
                root.torActive = kv.tor === "active";
                root.torProxy = kv.proxy === "'manual'|9050";
                root.torControl = kv.torctl === "1";
                root.firewallName = kv.firewall ?? "";
                root.firewallActive = root.firewallName.length > 0;
                root.firewallInstalled = kv.fwunit === "1";

                // Bring the firewall back after a reboot if it was left on
                if (!root.firewallRestored && root.firewallInstalled) {
                    root.firewallRestored = true;
                    if (store.firewall && !root.firewallActive)
                        root.run(["systemctl", "start", root.firewallUnit]);
                }
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

    // Every clipboard change restarts the countdown
    Process {
        running: root.clipboardAutoClear
        command: ["wl-paste", "--watch", "echo", "changed"]
        stdout: SplitParser {
            onRead: {
                if (!root.ignoreClipboardEvents)
                    clipboardTimer.restart();
            }
        }
    }

    Timer {
        id: clipboardTimer

        interval: root.clipboardClearDelay * 1000
        onTriggered: {
            // Clearing fires another change event; don't let it restart the countdown
            root.ignoreClipboardEvents = true;
            Quickshell.execDetached(["sh", "-c", "wl-copy --clear; wl-copy --primary --clear"]);
            ignoreTimer.restart();
        }
    }

    Timer {
        id: ignoreTimer

        interval: 1500
        onTriggered: root.ignoreClipboardEvents = false
    }

    // Tor takes a few seconds to bootstrap after starting, so retry the first exit check
    Timer {
        id: exitRetry

        property int attempts: 0

        interval: 5000
        onTriggered: {
            if (root.torExitIp || attempts >= 6)
                return;
            attempts++;
            root.checkExit();
            restart();
        }
    }

    Timer {
        running: root.torRouting && root.rotateMinutes > 0
        interval: root.rotateMinutes * 60000
        repeat: true
        onRunningChanged: root.nextRotateAt = running ? Date.now() + interval : 0
        onTriggered: {
            root.nextRotateAt = Date.now() + interval;
            root.newIdentity();
        }
    }

    Process {
        id: identityProc

        // NEWNYM plus closing open circuits, so browsers reconnect with the new exit
        command: ["python3", Quickshell.shellPath("assets/tor-new-identity.py"), root.torKeyPath]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.startsWith("ok")) {
                    // Circuits need a moment to rebuild before the new exit shows up
                    root.torExitIp = "";
                    root.torExitCountry = "";
                    identityCheck.restart();
                } else {
                    Toaster.toast(qsTr("New identity failed"), qsTr("Tor control port refused the request"), "shield", Toast.Warning);
                }
            }
        }
    }

    Timer {
        id: identityCheck

        interval: 2500
        onTriggered: {
            exitProc.announce = true;
            root.checkExit();
        }
    }

    Process {
        id: exitProc

        property bool announce

        command: ["curl", "-s", "--max-time", "20", "--socks5-hostname", "127.0.0.1:9050", "https://ifconfig.co/json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const info = JSON.parse(text);
                    root.torExitIp = info.ip ?? "";
                    root.torExitCountry = info.country ?? "";
                } catch (e) {
                    root.torExitIp = "";
                    root.torExitCountry = "";
                }
                if (exitProc.announce && root.torExitIp)
                    Toaster.toast(qsTr("New identity"), root.torExitCountry ? `${root.torExitIp} · ${root.torExitCountry}` : root.torExitIp, "shield_lock");
                exitProc.announce = false;
            }
        }
    }

    FileView {
        path: `${Paths.state}/privacy.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: store

            property int rotateMinutes: 0
            property bool firewall: false
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

        function newIdentity(): void {
            root.newIdentity();
        }

        function status(): string {
            return JSON.stringify({
                tunneled: root.tunneled,
                vpn: root.vpnName,
                tor: root.torActive,
                torProxy: root.torProxy,
                torControl: root.torControl,
                exit: root.torExitIp,
                exitCountry: root.torExitCountry,
                rotateMinutes: root.rotateMinutes,
                firewall: root.firewallName,
                firewallInstalled: root.firewallInstalled,
                macRandom: root.macRandom,
                mic: root.micApps,
                cam: root.camInUse,
                networking: root.networkingEnabled,
                exposedPorts: root.exposedPorts,
                localPorts: root.localPorts,
                connections: root.connections
            });
        }
    }
}
