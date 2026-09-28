import QtQuick
import QtQuick.Shapes
import qs.services

// The Lumi mark: a tall slanted stroke and a foot with a beaked tip
Item {
    id: root

    readonly property real designWidth: 268
    readonly property real designHeight: 388

    property color topColour: Colours.palette.m3primary
    property color bottomColour: Colours.palette.m3onSurface

    implicitWidth: designWidth
    implicitHeight: designHeight

    Shape {
        anchors.centerIn: parent
        width: root.designWidth
        height: root.designHeight
        scale: Math.min(root.width / width, root.height / height)
        transformOrigin: Item.Center
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.topColour
            strokeColor: "transparent"

            PathSvg {
                path: "M0,0 C55,44 84,70 84,100 L84,286 Q84,290 81,293 L0,376 Z"
            }
        }

        ShapePath {
            fillColor: root.bottomColour
            strokeColor: "transparent"

            PathSvg {
                path: "M9,387 L92,311 Q94,309 97,309 L246,309 C257,309 264,319 266,331 C255,327 244,328 236,335 L186,385 Q184,387 181,387 Z"
            }
        }
    }
}
