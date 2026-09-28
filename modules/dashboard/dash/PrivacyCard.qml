pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Lumi.Config
import qs.components
import qs.services

// At-a-glance exposure readout; the bar's privacy popout has the controls
Item {
    id: root

    anchors.fill: parent
    anchors.margins: Tokens.padding.large

    implicitWidth: 260
    implicitHeight: layout.implicitHeight

    Component.onCompleted: Privacy.refresh()

    TextMetrics {
        id: keyMetrics

        font: Tokens.font.body.small
        text: "Firewall"
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.small
            spacing: Tokens.spacing.small

            MaterialIcon {
                animate: true
                text: Privacy.tunneled ? "shield_lock" : "shield"
                fill: Privacy.tunneled ? 1 : 0
                color: Privacy.tunneled ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.large
            }

            StyledText {
                Layout.fillWidth: true
                animate: true
                text: {
                    if (!Privacy.networkingEnabled)
                        return qsTr("Offline");
                    if (Privacy.vpnActive)
                        return `VPN · ${Privacy.vpnName}`;
                    if (Privacy.torRouting)
                        return `Tor · ${Privacy.torExitCountry || Privacy.torExitIp || qsTr("connecting")}`;
                    return qsTr("Exposed");
                }
                color: Privacy.tunneled ? Colours.palette.m3primary : Colours.palette.m3onSurface
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }
        }

        Line {
            key: qsTr("Firewall")
            value: Privacy.firewallActive ? qsTr("On") : qsTr("Off")
            good: Privacy.firewallActive
        }

        Line {
            key: qsTr("MAC")
            value: Privacy.macRandom ? qsTr("Random") : qsTr("Hardware")
            good: Privacy.macRandom
        }

        Line {
            key: qsTr("Ports")
            value: Privacy.exposedPorts.length > 0 ? qsTr("%1 open").arg(Privacy.exposedPorts.length) : qsTr("Closed")
            good: Privacy.exposedPorts.length === 0
            alert: Privacy.exposedPorts.length > 0
        }

        Line {
            key: qsTr("Mic")
            value: Privacy.micInUse ? Privacy.micApps.join(", ") : qsTr("Idle")
            alert: Privacy.micInUse
        }

        Line {
            key: qsTr("Camera")
            value: Privacy.camInUse ? qsTr("In use") : qsTr("Idle")
            alert: Privacy.camInUse
        }
    }

    component Line: RowLayout {
        required property string key
        required property string value
        property bool good
        property bool alert

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        StyledText {
            Layout.preferredWidth: keyMetrics.width
            text: parent.key
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: parent.value
            color: parent.alert ? Colours.palette.m3error : parent.good ? Colours.palette.m3primary : Colours.palette.m3onSurface
            elide: Text.ElideRight
            font: Tokens.font.body.small
        }
    }
}
