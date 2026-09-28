pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import Lumi.Config
import qs.components
import qs.services
import qs.utils

// Anonymous system card: the Lumi mark and a few fetch-style lines, no name or photo
Item {
    id: root

    anchors.fill: parent
    anchors.margins: Tokens.padding.large

    implicitHeight: lines.implicitHeight

    // Keys share one column width so the values line up
    TextMetrics {
        id: keyMetrics

        font: Tokens.font.mono.small
        text: "kern"
    }

    MaterialShape {
        id: badge

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: Math.max(lines.implicitHeight, 76)

        shape: MaterialShape.Cookie7Sided
        color: Colours.palette.m3primaryContainer

        Logo {
            anchors.centerIn: parent
            implicitHeight: parent.height * 0.5

            topColour: Colours.palette.m3primary
            bottomColour: Colours.palette.m3onPrimaryContainer
        }
    }

    ColumnLayout {
        id: lines

        anchors.left: badge.right
        anchors.right: parent.right
        anchors.leftMargin: Tokens.spacing.extraLarge
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.extraSmall

        Line {
            key: "up"
            value: SysInfo.uptime.split(",").slice(0, 2).join(",")
        }

        Line {
            key: "wm"
            value: SysInfo.wm.toLowerCase()
        }

        Line {
            key: "kern"
            value: SysInfo.kernel
        }

        Line {
            key: "os"
            value: (SysInfo.osPrettyName || SysInfo.osName).toLowerCase()
        }
    }

    component Line: RowLayout {
        required property string key
        required property string value

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        StyledText {
            Layout.preferredWidth: keyMetrics.width
            text: parent.key
            color: Colours.palette.m3primary
            font: Tokens.font.mono.small
        }

        StyledText {
            Layout.fillWidth: true
            animate: true
            text: parent.value || "…"
            color: Colours.palette.m3onSurface
            elide: Text.ElideRight
            font: Tokens.font.mono.small
        }
    }
}
