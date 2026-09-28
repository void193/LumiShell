pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import Lumi.Config
import qs.components
import qs.services

Item {
    id: root

    required property int centerWidth
    readonly property color bgColour: Colours.tPalette.m3surfaceContainerHighest

    implicitWidth: Math.round(centerWidth * 0.7)
    implicitHeight: {
        shape.height; // Force update when shape height changes
        return shape.pathBounds().height;
    }

    MaterialShape {
        id: shape

        anchors.centerIn: parent
        implicitSize: root.implicitWidth

        shape: MaterialShape.ClamShell
        color: Qt.alpha(root.bgColour, 1)
        opacity: root.bgColour.a
        layer.enabled: true
    }

    // No face or username on the lock screen, just the Lumi mark
    Logo {
        anchors.centerIn: parent
        implicitHeight: root.centerWidth / 3.2

        topColour: Colours.palette.m3primary
        bottomColour: Colours.palette.m3onSurfaceVariant
    }
}
