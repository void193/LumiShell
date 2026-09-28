pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import Lumi.Config
import qs.components
import qs.components.controls
import qs.services

// Privacy panel: status header, anonymity, local protections, live activity, kill switch
ColumnLayout {
    id: root

    readonly property string status: !Privacy.networkingEnabled ? "offline" : Privacy.tunneled ? "protected" : "exposed"
    readonly property color cardColour: Colours.tPalette.m3surfaceContainerHigh

    spacing: Tokens.spacing.medium
    width: 340

    Component.onCompleted: Privacy.refresh()

    // Status header
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium
        spacing: Tokens.spacing.large

        MaterialShape {
            implicitSize: 52
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
                fontStyle: Tokens.font.icon.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                animate: true
                text: root.status === "protected" ? qsTr("Protected") : root.status === "offline" ? qsTr("Offline") : qsTr("Exposed")
                font: Tokens.font.title.builders.medium.weight(Font.Medium).build()
            }

            StyledText {
                Layout.fillWidth: true
                animate: true
                text: {
                    if (root.status === "offline")
                        return qsTr("Network killed");
                    if (Privacy.vpnActive)
                        return `VPN · ${Privacy.vpnName}`;
                    if (Privacy.torRouting) {
                        if (!Privacy.torExitIp)
                            return qsTr("Tor · connecting");
                        return `Tor · ${Privacy.torExitCountry || Privacy.torExitIp}`;
                    }
                    return qsTr("Direct connection");
                }
                color: root.status === "protected" ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
                font: Tokens.font.body.small
            }
        }

        IconButton {
            id: identityBtn

            readonly property bool working: Privacy.rotating || (Privacy.checkingExit && !Privacy.torExitIp)

            visible: Privacy.torRouting
            type: IconButton.Tonal
            isRound: true
            icon: "autorenew"
            disabled: !Privacy.torControl || working
            onClicked: Privacy.newIdentity()
            onWorkingChanged: {
                if (!working)
                    identityBtn.label.rotation = 0;
            }

            // Spin while a new identity is being set up
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

    // Anonymity
    GroupLabel {
        text: qsTr("Anonymity")
    }

    Card {
        SettingRow {
            icon: "public"
            title: qsTr("Tor mode")
            detail: {
                if (!Privacy.torInstalled)
                    return qsTr("Not set up");
                if (Privacy.torRouting)
                    return Privacy.torExitIp || qsTr("Connecting...");
                return "";
            }
            isOn: Privacy.torRouting
            enabled: Privacy.torInstalled && !Privacy.busy
            onToggled: Privacy.toggleTor()
        }

        // Rotation, only while routing through Tor
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Privacy.torRouting ? implicitHeight : 0
            Layout.topMargin: Privacy.torRouting ? Tokens.spacing.small : 0
            visible: Privacy.torRouting
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Rotate identity")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                StyledText {
                    visible: Privacy.rotateMinutes > 0 && Privacy.nextRotateAt > 0
                    text: {
                        const left = Math.max(0, Math.round((Privacy.nextRotateAt - countdown.now) / 1000));
                        return qsTr("Next in %1").arg(`${Math.floor(left / 60)}:${String(left % 60).padStart(2, "0")}`);
                    }
                    color: Colours.palette.m3primary
                    font: Tokens.font.body.small
                }
            }

            // Segmented interval picker
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                Repeater {
                    model: [0, 5, 15, 30]

                    TextButton {
                        required property int modelData

                        Layout.fillWidth: true
                        type: TextButton.Tonal
                        isToggle: true
                        checked: Privacy.rotateMinutes === modelData
                        text: modelData === 0 ? qsTr("Off") : `${modelData} min`
                        font: Tokens.font.body.small
                        disabled: !Privacy.torControl && modelData > 0
                        onClicked: Privacy.setRotateMinutes(modelData)
                    }
                }
            }
        }
    }

    // Local protections
    GroupLabel {
        text: qsTr("Protection")
    }

    Card {
        SettingRow {
            icon: "local_fire_department"
            title: qsTr("Firewall")
            detail: Privacy.firewallInstalled ? "" : qsTr("Not set up")
            isOn: Privacy.firewallActive
            enabled: Privacy.firewallInstalled && !Privacy.busy
            onToggled: Privacy.toggleFirewall()
        }

        SettingRow {
            icon: "fingerprint"
            title: qsTr("Random MAC")
            detail: Privacy.wifiConnection ? "" : qsTr("No Wi-Fi")
            isOn: Privacy.macRandom
            enabled: Privacy.wifiConnection.length > 0 && !Privacy.busy
            onToggled: Privacy.toggleMacRandom()
        }

        SettingRow {
            icon: "content_paste_off"
            title: qsTr("Clipboard wipe")
            detail: Privacy.clipboardAutoClear ? qsTr("After %1 seconds").arg(Privacy.clipboardClearDelay) : ""
            isOn: Privacy.clipboardAutoClear
            onToggled: Privacy.setClipboardAutoClear(!Privacy.clipboardAutoClear)
        }
    }

    // Live activity
    GroupLabel {
        text: qsTr("Activity")
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Tokens.spacing.small
        columnSpacing: Tokens.spacing.small

        Tile {
            icon: "mic"
            label: qsTr("Microphone")
            value: Privacy.micApps.join(", ")
            alert: Privacy.micInUse
        }

        Tile {
            icon: "videocam"
            label: qsTr("Camera")
            value: qsTr("Camera in use")
            alert: Privacy.camInUse
        }

        Tile {
            icon: "lan"
            label: qsTr("No open ports")
            value: qsTr("Open: %1").arg(Privacy.exposedPorts.map(p => p.port).join(", "))
            alert: Privacy.exposedPorts.length > 0
        }

        Tile {
            icon: "swap_horiz"
            label: qsTr("%1 connections").arg(Privacy.connections)
            value: ""
        }
    }

    // Real address, only fetched when asked
    TextButton {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacing.small

        type: TextButton.Text
        text: {
            if (Privacy.checkingIp)
                return qsTr("Checking...");
            if (Privacy.publicIp)
                return Privacy.ipCountry ? qsTr("Real IP: %1 · %2").arg(Privacy.publicIp).arg(Privacy.ipCountry) : qsTr("Real IP: %1").arg(Privacy.publicIp);
            return qsTr("Reveal real IP");
        }
        font: Tokens.font.body.small
        disabled: Privacy.checkingIp || !Privacy.networkingEnabled
        onClicked: Privacy.publicIp ? Privacy.clearIp() : Privacy.checkIp()
    }

    IconTextButton {
        Layout.fillWidth: true
        Layout.bottomMargin: Tokens.padding.medium

        type: TextButton.Tonal
        icon: Privacy.networkingEnabled ? "emergency_home" : "wifi"
        text: Privacy.networkingEnabled ? qsTr("Kill switch") : qsTr("Restore network")
        inactiveColour: Privacy.networkingEnabled ? Colours.palette.m3errorContainer : Colours.palette.m3primaryContainer
        inactiveOnColour: Privacy.networkingEnabled ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimaryContainer
        onClicked: Privacy.networkingEnabled ? Privacy.panic() : Privacy.restoreNetwork()
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

    component GroupLabel: StyledText {
        Layout.topMargin: Tokens.spacing.small
        Layout.leftMargin: Tokens.padding.small
        color: Colours.palette.m3primary
        font: Tokens.font.label.builders.medium.weight(Font.Medium).build()
    }

    component Card: StyledRect {
        default property alias content: cardLayout.data

        Layout.fillWidth: true
        implicitHeight: cardLayout.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.large
        color: root.cardColour

        ColumnLayout {
            id: cardLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.large
        }
    }

    component SettingRow: RowLayout {
        id: row

        required property string icon
        required property string title
        required property string detail
        required property bool isOn

        signal toggled

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium
        opacity: enabled ? 1 : 0.6

        StyledRect {
            implicitWidth: 34
            implicitHeight: 34
            radius: Tokens.rounding.full
            color: row.isOn ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHighest

            Behavior on color {
                CAnim {}
            }

            MaterialIcon {
                anchors.centerIn: parent
                animate: true
                text: row.icon
                fill: row.isOn ? 1 : 0
                color: row.isOn ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: row.title
                font: Tokens.font.body.medium
            }

            StyledText {
                Layout.fillWidth: true
                visible: text.length > 0
                animate: true
                text: row.detail
                color: Colours.palette.m3outline
                elide: Text.ElideRight
                font: Tokens.font.body.small
            }
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

    component Tile: StyledRect {
        id: tile

        required property string icon
        required property string label
        required property string value
        property bool alert

        Layout.fillWidth: true
        implicitHeight: tileLayout.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.medium
        color: alert ? Colours.palette.m3errorContainer : root.cardColour

        Behavior on color {
            CAnim {}
        }

        RowLayout {
            id: tileLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: tile.icon
                fill: tile.alert ? 1 : 0
                color: tile.alert ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurfaceVariant
            }

            // One line: the quiet label, or what's happening when it needs attention
            StyledText {
                Layout.fillWidth: true
                animate: true
                text: tile.alert && tile.value ? tile.value : tile.label
                color: tile.alert ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
                font: Tokens.font.body.small
            }
        }
    }
}
