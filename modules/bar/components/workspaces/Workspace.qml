pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Lumi.Config
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset

    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property int size: implicitHeight + (hasWindows ? Tokens.padding.extraSmall : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows
    readonly property bool focused: activeWsId === ws

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: size

    spacing: 0

    // The workspace number: matches mod+1..N, bright when it has windows, dim when empty.
    // The sliding active indicator recolours whatever sits under it.
    Item {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        implicitWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small
        implicitHeight: Tokens.sizes.bar.innerWidth - Tokens.padding.small

        StyledText {
            anchors.centerIn: parent
            text: root.ws
            color: root.focused || root.isOccupied ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font: Tokens.font.mono.builders.medium.weight(root.focused || root.isOccupied ? Font.DemiBold : Font.Normal).build()

            Behavior on color {
                CAnim {}
            }
        }
    }

    Loader {
        id: windows

        asynchronous: true

        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.topMargin: -Tokens.spacing.extraSmall / 2

        visible: active
        active: root.hasWindows

        sourceComponent: Column {
            spacing: 0

            add: Transition {
                Anim {
                    properties: "scale"
                    from: 0
                    to: 1
                    easing: Tokens.anim.standardDecel
                }
            }

            move: Transition {
                Anim {
                    properties: "scale"
                    to: 1
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    properties: "x,y"
                }
            }

            Repeater {
                model: ScriptModel {
                    values: {
                        const windows = Hypr.toplevelsForWs(root.ws);
                        const maxIcons = root.Config.bar.workspaces.maxWindowIcons;
                        return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                    }
                }

                MaterialIcon {
                    required property var modelData

                    grade: 0
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }
}
