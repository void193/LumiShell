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

        font: Tokens.font.mono.small
        text: "mac"
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
                        return "offline";
                    if (Privacy.vpnActive)
                        return `tunneled · ${Privacy.vpnName}`;
                    if (Privacy.torActive)
                        return "tunneled · tor";
                    return "exposed";
                }
                color: Privacy.tunneled ? Colours.palette.m3primary : Colours.palette.m3onSurface
                font: Tokens.font.mono.builders.medium.weight(Font.Medium).build()
            }
        }

        Line {
            key: "fw"
            value: Privacy.firewallActive ? "on" : "off"
            good: Privacy.firewallActive
        }

        Line {
            key: "mac"
            value: Privacy.macRandom ? "random" : "stock"
            good: Privacy.macRandom
        }

        Line {
            key: "mic"
            value: Privacy.micInUse ? Privacy.micApps.join(", ") : "idle"
            alert: Privacy.micInUse
        }

        Line {
            key: "cam"
            value: Privacy.camInUse ? "in use" : "idle"
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
            font: Tokens.font.mono.small
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: parent.value
            color: parent.alert ? Colours.palette.m3error : parent.good ? Colours.palette.m3primary : Colours.palette.m3onSurface
            elide: Text.ElideRight
            font: Tokens.font.mono.small
        }
    }
}
