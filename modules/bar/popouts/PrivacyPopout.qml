pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Lumi.Config
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    spacing: Tokens.spacing.small
    width: 300

    Component.onCompleted: Privacy.refresh()

    // Header: one plain line saying how exposed we are
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: Privacy.tunneled ? "shield_lock" : "shield"
            fill: Privacy.tunneled ? 1 : 0
            color: Privacy.tunneled ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Privacy")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        StyledText {
            text: {
                if (!Privacy.networkingEnabled)
                    return "offline";
                if (Privacy.vpnActive)
                    return `via ${Privacy.vpnName}`;
                if (Privacy.torActive)
                    return "via tor";
                return "exposed";
            }
            color: Privacy.tunneled ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.mono.small
        }
    }

    // Tunnels and defences
    Toggle {
        label: qsTr("Tor")
        detail: Privacy.torInstalled ? "tor.service" : qsTr("not installed")
        isOn: Privacy.torActive
        toggle.disabled: !Privacy.torInstalled || Privacy.busy
        toggle.onToggled: Privacy.toggleTor()
    }

    Toggle {
        label: qsTr("Firewall")
        detail: Privacy.firewallName || "nftables.service"
        isOn: Privacy.firewallActive
        toggle.disabled: Privacy.busy
        toggle.onToggled: Privacy.toggleFirewall()
    }

    Toggle {
        label: qsTr("Random MAC")
        detail: Privacy.wifiConnection ? qsTr("%1, reconnects").arg(Privacy.wifiConnection) : qsTr("no wi-fi")
        isOn: Privacy.macRandom
        toggle.disabled: !Privacy.wifiConnection || Privacy.busy
        toggle.onToggled: Privacy.toggleMacRandom()
    }

    // Sensors
    StyledText {
        Layout.topMargin: Tokens.spacing.small
        text: qsTr("Sensors")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    Readout {
        label: "mic"
        value: Privacy.micInUse ? Privacy.micApps.join(", ") : "idle"
        alert: Privacy.micInUse
    }

    Readout {
        label: "cam"
        value: Privacy.camInUse ? "in use" : "idle"
        alert: Privacy.camInUse
    }

    // Public address, only fetched when asked
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.medium

        StyledText {
            text: "ip"
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.mono.small
        }

        StyledText {
            Layout.fillWidth: true
            text: {
                if (Privacy.checkingIp)
                    return "checking...";
                if (!Privacy.publicIp)
                    return "hidden";
                return Privacy.ipCountry ? `${Privacy.publicIp} · ${Privacy.ipCountry}` : Privacy.publicIp;
            }
            elide: Text.ElideRight
            font: Tokens.font.mono.small
        }

        TextButton {
            type: TextButton.Text
            text: Privacy.publicIp ? qsTr("Hide") : qsTr("Check")
            disabled: Privacy.checkingIp || !Privacy.networkingEnabled
            onClicked: Privacy.publicIp ? Privacy.clearIp() : Privacy.checkIp()
        }
    }

    // Kill switch
    TextButton {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        Layout.bottomMargin: Tokens.padding.small
        Layout.rightMargin: Tokens.padding.extraSmall

        type: TextButton.Tonal
        text: Privacy.networkingEnabled ? qsTr("Kill switch") : qsTr("Restore network")
        inactiveColour: Privacy.networkingEnabled ? Colours.palette.m3errorContainer : Colours.palette.m3secondaryContainer
        inactiveOnColour: Privacy.networkingEnabled ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSecondaryContainer
        onClicked: Privacy.networkingEnabled ? Privacy.panic() : Privacy.restoreNetwork()
    }

    StyledText {
        Layout.fillWidth: true
        Layout.bottomMargin: Tokens.padding.small
        visible: Privacy.networkingEnabled
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: "network off · clipboard wiped · locked"
        color: Colours.palette.m3outline
        font: Tokens.font.mono.small
    }

    component Toggle: RowLayout {
        id: toggleRow

        required property string label
        required property bool isOn
        property string detail
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: toggleRow.label
            }

            StyledText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: toggleRow.detail
                color: Colours.palette.m3outline
                elide: Text.ElideRight
                font: Tokens.font.mono.small
            }
        }

        StyledSwitch {
            id: toggle

            checked: toggleRow.isOn
        }

        // Flipping the switch breaks its binding; re-sync with the real state once the action settles
        Connections {
            function onBusyChanged(): void {
                if (!Privacy.busy)
                    toggle.checked = Qt.binding(() => toggleRow.isOn);
            }

            target: Privacy
        }
    }

    component Readout: RowLayout {
        required property string label
        required property string value
        property bool alert

        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.medium

        StyledText {
            text: parent.label
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.mono.small
        }

        StyledText {
            Layout.fillWidth: true
            text: parent.value
            color: parent.alert ? Colours.palette.m3error : Colours.palette.m3onSurface
            elide: Text.ElideRight
            font: Tokens.font.mono.small
        }
    }
}
