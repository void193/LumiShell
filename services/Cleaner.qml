pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Lumi

// Memory clean-up: scan for heavy apps, let the user review, then close the chosen ones.
// All the safety rules (protected processes, windowed apps never preselected, polite
// SIGTERM first) live in assets/lumi-clean.py.
Singleton {
    id: root

    property var candidates: [] // [{ pid, name, mb, percent, windowed, selected }]
    property bool reviewing: false
    readonly property bool scanning: scanProc.running
    readonly property bool cleaning: cleanProc.running
    readonly property var selected: candidates.filter(c => c.selected)
    readonly property int selectedMb: selected.reduce((sum, c) => sum + c.mb, 0)

    function scan(): void {
        reviewing = true;
        candidates = [];
        scanProc.running = true;
    }

    function cancel(): void {
        reviewing = false;
        candidates = [];
    }

    function toggle(pid: int): void {
        candidates = candidates.map(c => c.pid === pid ? Object.assign({}, c, {
                selected: !c.selected
            }) : c);
    }

    function cleanSelected(): void {
        if (selected.length === 0 || cleanProc.running)
            return;
        cleanProc.command = ["python3", Quickshell.shellPath("assets/lumi-clean.py"), "clean", ...selected.map(c => String(c.pid))];
        cleanProc.running = true;
    }

    Process {
        id: scanProc

        command: ["python3", Quickshell.shellPath("assets/lumi-clean.py"), "scan"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.candidates = JSON.parse(text);
                } catch (e) {
                    root.candidates = [];
                }
            }
        }
    }

    Process {
        id: cleanProc

        stdout: StdioCollector {
            onStreamFinished: {
                let result = null;
                try {
                    result = JSON.parse(text);
                } catch (e) {}

                if (result && result.closed > 0)
                    Toaster.toast(qsTr("Memory cleaned"), result.freedMB > 0 ? qsTr("Closed %1 · freed %2 MB").arg(result.closed === 1 ? qsTr("1 app") : qsTr("%1 apps").arg(result.closed)).arg(result.freedMB) : qsTr("Closed %1").arg(result.closed === 1 ? qsTr("1 app") : qsTr("%1 apps").arg(result.closed)), "cleaning_services");
                else
                    Toaster.toast(qsTr("Nothing closed"), qsTr("The selected apps had already exited"), "cleaning_services");

                root.cancel();
            }
        }
    }
}
