pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import Lumi.Config
import qs.components
import qs.components.controls
import qs.services

// Privacy panel: status, four switches, one line of activity, and a quiet footer
ColumnLayout {
    id: root

    readonly property string status: !Privacy.networkingEnabled ? "offline" : Privacy.tunneled ? "protected" : "exposed"

    // Only things that need attention; empty means all quiet
    readonly property list<string> alerts: {
        const out = [];
        if (Privacy.micInUse)
            out.push(`mic · ${Privacy.micApps.join(", ")}`);
        if (Privacy.camInUse)
            out.push("camera in use");
        if (Privacy.exposedPorts.length > 0)
            out.push(`open ${Privacy.exposedPorts.map(p => p.port).join(" ")}`);
        return out;
    }

    spacing: Tokens.spacing.small
    width: 300

    Component.onCompleted: Privacy.refresh()

    // Status
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium
        Layout.bottomMargin: Tokens.spacing.medium
        spacing: Tokens.spacing.medium

        MaterialShape {
            implicitSize: 40
            shape: MaterialShape.Cookie9Sided
            color: root.status === "protected" ? Colours.palette.m3primary : root.status === "offline" ? Colours.palette.m3errorContainer : Colours.tPalette.m3surfaceContainerHighest

            Behavior on color {
                CAnim {}
            }

            MaterialIcon {
                anchors.centerIn: parent
                animate: true
                text: root.status === "protected" ? "shield_lock" : root.status === "offline" ? "wifi_off" : "shield"
                fill: root.status === "exposed" ? 0 : 1
                color: root.status === "protected" ? Colours.palette.m3onPrimary : root.status === "offline" ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurfaceVariant
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                animate: true
                text: root.status === "protected" ? qsTr("Protected") : root.status === "offline" ? qsTr("Offline") : qsTr("Exposed")
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                Layout.fillWidth: true
                animate: true
                text: {
                    if (root.status === "offline")
                        return "network killed";
                    if (Privacy.vpnActive)
                        return `vpn · ${Privacy.vpnName}`;
                    if (Privacy.torRouting)
                        return Privacy.torExitIp ? `tor · ${Privacy.torExitCountry || Privacy.torExitIp}` : "tor · connecting";
                    return "direct connection";
                }
                color: root.status === "protected" ? Colours.palette.m3primary : Colours.palette.m3outline
                elide: Text.ElideRight
                font: Tokens.font.mono.small
            }
        }

        IconButton {
            id: identityBtn

            readonly property bool working: Privacy.rotating || (Privacy.checkingExit && !Privacy.torExitIp)

            visible: Privacy.torRouting
            type: IconButton.Text
            icon: "autorenew"
            disabled: !Privacy.torControl || working
            onClicked: Privacy.newIdentity()
            onWorkingChanged: {
                if (!working)
                    identityBtn.label.rotation = 0;
            }

            // Spins while a new identity is being set up
            RotationAnimator {
                target: identityBtn.label
                running: identityBtn.working
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
            }
        }
    }

    // Switches
    SettingRow {
        icon: "public"
        title: qsTr("Tor")
        detail: {
            if (!Privacy.torInstalled)
                return "run lumi-tor-setup";
            if (Privacy.torRouting)
                return Privacy.torExitIp || "connecting";
            return "";
        }
        isOn: Privacy.torRouting
        enabled: Privacy.torInstalled && !Privacy.busy
        onToggled: Privacy.toggleTor()
    }

    // Identity rotation, tucked under Tor while it's on
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 30
        Layout.preferredHeight: Privacy.torRouting ? implicitHeight : 0
        visible: Privacy.torRouting && Privacy.torControl
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.fillWidth: true
            text: {
                if (Privacy.rotateMinutes <= 0 || Privacy.nextRotateAt <= 0)
                    return "rotate";
                const left = Math.max(0, Math.round((Privacy.nextRotateAt - countdown.now) / 1000));
                return `rotate ${Math.floor(left / 60)}:${String(left % 60).padStart(2, "0")}`;
            }
            color: Privacy.rotateMinutes > 0 ? Colours.palette.m3primary : Colours.palette.m3outline
            font: Tokens.font.mono.small
        }

        Repeater {
            model: [0, 5, 15, 30]

            TextButton {
                required property int modelData

                type: TextButton.Text
                isToggle: true
                checked: Privacy.rotateMinutes === modelData
                text: modelData === 0 ? qsTr("off") : `${modelData}m`
                font: Tokens.font.mono.small
                horizontalPadding: Tokens.padding.small
                verticalPadding: Tokens.padding.extraSmall
                onClicked: Privacy.setRotateMinutes(modelData)
            }
        }
    }

    SettingRow {
        icon: "local_fire_department"
        title: qsTr("Firewall")
        detail: Privacy.firewallInstalled ? "" : "run lumi-tor-setup"
        isOn: Privacy.firewallActive
        enabled: Privacy.firewallInstalled && !Privacy.busy
        onToggled: Privacy.toggleFirewall()
    }

    SettingRow {
        icon: "fingerprint"
        title: qsTr("Random MAC")
        detail: Privacy.wifiConnection ? "" : "no wi-fi"
        isOn: Privacy.macRandom
        enabled: Privacy.wifiConnection.length > 0 && !Privacy.busy
        onToggled: Privacy.toggleMacRandom()
    }

    SettingRow {
        icon: "content_paste_off"
        title: qsTr("Clipboard wipe")
        detail: Privacy.clipboardAutoClear ? `${Privacy.clipboardClearDelay}s` : ""
        isOn: Privacy.clipboardAutoClear
        onToggled: Privacy.setClipboardAutoClear(!Privacy.clipboardAutoClear)
    }

    // Activity: one quiet line, red only when something needs attention
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.medium
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: root.alerts.length > 0 ? "warning" : "radar"
            color: root.alerts.length > 0 ? Colours.palette.m3error : Colours.palette.m3outline
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: root.alerts.length > 0 ? root.alerts.join("  ·  ") : "all quiet"
            color: root.alerts.length > 0 ? Colours.palette.m3error : Colours.palette.m3outline
            elide: Text.ElideRight
            font: Tokens.font.mono.small
        }
    }

    // Footer: real IP on demand, kill switch
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        Layout.bottomMargin: Tokens.padding.small
        spacing: Tokens.spacing.small

        TextButton {
            type: TextButton.Text
            text: {
                if (Privacy.checkingIp)
                    return "checking...";
                if (Privacy.publicIp)
                    return Privacy.ipCountry ? `${Privacy.publicIp} · ${Privacy.ipCountry}` : Privacy.publicIp;
                return qsTr("Reveal real IP");
            }
            font: Tokens.font.mono.small
            horizontalPadding: Tokens.padding.small
            disabled: Privacy.checkingIp || !Privacy.networkingEnabled
            onClicked: Privacy.publicIp ? Privacy.clearIp() : Privacy.checkIp()
        }

        Item {
            Layout.fillWidth: true
        }

        IconTextButton {
            type: TextButton.Tonal
            icon: Privacy.networkingEnabled ? "emergency_home" : "wifi"
            text: Privacy.networkingEnabled ? qsTr("Kill") : qsTr("Restore")
            font: Tokens.font.body.small
            inactiveColour: Privacy.networkingEnabled ? Colours.palette.m3errorContainer : Colours.palette.m3primaryContainer
            inactiveOnColour: Privacy.networkingEnabled ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer
            onClicked: Privacy.networkingEnabled ? Privacy.panic() : Privacy.restoreNetwork()
        }
    }

    // Drives the rotation countdown while the popout is open
    Timer {
        id: countdown

        property double now: Date.now()

        running: root.visible && Privacy.nextRotateAt > 0
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: now = Date.now()
    }

    component SettingRow: RowLayout {
        id: row

        required property string icon
        required property string title
        required property string detail
        required property bool isOn

        signal toggled

        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.extraSmall
        spacing: Tokens.spacing.medium
        opacity: enabled ? 1 : 0.5

        MaterialIcon {
            Layout.preferredWidth: 20
            animate: true
            text: row.icon
            fill: row.isOn ? 1 : 0
            color: row.isOn ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            text: row.title
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: row.detail
            color: Colours.palette.m3outline
            elide: Text.ElideRight
            font: Tokens.font.mono.small
        }

        StyledSwitch {
            id: toggle

            checked: row.isOn
            disabled: !row.enabled
            onToggled: row.toggled()
        }

        // Flipping the switch breaks its binding; re-sync with the real state once actions settle
        Connections {
            function onBusyChanged(): void {
                if (!Privacy.busy)
                    toggle.checked = Qt.binding(() => row.isOn);
            }

            target: Privacy
        }

        Connections {
            function onIsOnChanged(): void {
                toggle.checked = Qt.binding(() => row.isOn);
            }

            target: row
        }
    }
}
