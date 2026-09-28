pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import Lumi.Config
import qs.components
import qs.services
import qs.utils

// Dashboard banner: the Lumi mark, the security status and date, and a roomy grid
// of system facts. No name or photo.
Item {
    id: root

    readonly property bool secured: Privacy.tunneled
    readonly property string status: {
        if (!Privacy.networkingEnabled)
            return qsTr("Offline · network killed");
        if (Privacy.vpnActive)
            return qsTr("Protected · VPN %1").arg(Privacy.vpnName);
        if (Privacy.torRouting)
            return Privacy.torExitCountry ? qsTr("Protected · Tor via %1").arg(Privacy.torExitCountry) : qsTr("Protected · Tor");
        return qsTr("Exposed · direct connection");
    }

    anchors.fill: parent
    anchors.margins: Tokens.padding.extraLarge

    implicitHeight: Math.max(badge.implicitSize, facts.implicitHeight, headline.implicitHeight)

    MaterialShape {
        id: badge

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 88

        shape: MaterialShape.Cookie7Sided
        color: Colours.palette.m3primaryContainer

        Logo {
            anchors.centerIn: parent
            implicitHeight: parent.height * 0.5

            topColour: Colours.palette.m3primary
            bottomColour: Colours.palette.m3onPrimaryContainer
        }
    }

    // Security status and date
    ColumnLayout {
        id: headline

        anchors.left: badge.right
        anchors.leftMargin: Tokens.spacing.extraLarge
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.extraSmall

        RowLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                animate: true
                text: root.secured ? "shield_lock" : "shield"
                fill: root.secured ? 1 : 0
                color: root.secured ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                animate: true
                text: root.status
                color: root.secured ? Colours.palette.m3primary : Colours.palette.m3onSurface
                font: Tokens.font.title.builders.small.weight(Font.Medium).build()
            }
        }

        StyledText {
            text: Time.format("dddd, d MMMM")
            color: Colours.palette.m3outline
            font: Tokens.font.body.medium
        }
    }

    // Facts, two columns with room to breathe
    GridLayout {
        id: facts

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(360, parent.width - headline.x - headline.implicitWidth - Tokens.spacing.extraLarge * 2)
        columns: 2
        rowSpacing: Tokens.spacing.large
        columnSpacing: Tokens.spacing.extraLarge

        Fact {
            label: qsTr("Uptime")
            // "3 hours, 16 minutes" -> "3h 16m"
            value: SysInfo.uptime.split(",").slice(0, 2).map(p => p.trim().replace(/^(\d+)\s*(\w).*$/, "$1$2")).join(" ")
        }

        Fact {
            label: qsTr("Kernel")
            value: SysInfo.kernel
        }

        Fact {
            label: qsTr("Desktop")
            value: SysInfo.wm
        }

        Fact {
            label: qsTr("System")
            value: SysInfo.osPrettyName || SysInfo.osName
        }
    }

    component Fact: ColumnLayout {
        required property string label
        required property string value

        Layout.fillWidth: true
        Layout.preferredWidth: 1 // Equal columns
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: parent.label
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: parent.value || "…"
            color: Colours.palette.m3onSurface
            elide: Text.ElideRight
            font: Tokens.font.body.medium
        }
    }
}
