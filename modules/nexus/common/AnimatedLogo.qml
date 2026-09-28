pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components
import qs.services

// The Lumi mark with an intro: the stroke drops in, the foot slides in, and the blur clears
Item {
    id: root

    property real blurAmount: skipIntroAnimation ? 0.0 : 1.0
    property bool skipIntroAnimation: false

    readonly property alias topShape: topShape
    readonly property alias bottomShape: bottomShape

    signal animationCompleted

    implicitWidth: 128 * 268 / 388
    implicitHeight: 128

    Item {
        id: logo

        readonly property real designWidth: 268
        readonly property real designHeight: 388

        property color topColour: Colours.palette.m3primary
        property color bottomColour: Colours.palette.m3onSurface

        property real strokeOffset: root.skipIntroAnimation ? 0 : -120
        property real footOffset: root.skipIntroAnimation ? 0 : -160
        property real footOpacity: root.skipIntroAnimation ? 1.0 : 0.0

        anchors.centerIn: parent
        width: designWidth
        height: designHeight
        scale: Math.min(root.width / designWidth, root.height / designHeight) * introScale
        opacity: root.skipIntroAnimation ? 1.0 : 0.0

        property real introScale: root.skipIntroAnimation ? 1.0 : 0.85

        layer.enabled: root.blurAmount > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blurAmount
            blurMax: 60
        }

        Behavior on topColour {
            CAnim {}
        }

        Behavior on bottomColour {
            CAnim {}
        }

        Shape {
            id: topShape

            y: logo.strokeOffset
            width: logo.designWidth
            height: logo.designHeight
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: logo.topColour
                strokeColor: "transparent"

                PathSvg {
                    path: "M0,0 C55,44 84,70 84,100 L84,286 Q84,290 81,293 L0,376 Z"
                }
            }
        }

        Shape {
            id: bottomShape

            x: logo.footOffset
            opacity: logo.footOpacity
            width: logo.designWidth
            height: logo.designHeight
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: logo.bottomColour
                strokeColor: "transparent"

                PathSvg {
                    path: "M9,387 L92,311 Q94,309 97,309 L246,309 C257,309 264,319 266,331 C255,327 244,328 236,335 L186,385 Q184,387 181,387 Z"
                }
            }
        }
    }

    ParallelAnimation {
        running: !root.skipIntroAnimation
        onFinished: root.animationCompleted()

        NumberAnimation {
            target: logo
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 500
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: root
            property: "blurAmount"
            from: 1.0
            to: 0.0
            duration: 900
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            NumberAnimation {
                target: logo
                property: "introScale"
                from: 0.85
                to: 1.03
                duration: 700
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: logo
                property: "introScale"
                from: 1.03
                to: 1.0
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }

        NumberAnimation {
            target: logo
            property: "strokeOffset"
            from: -120
            to: 0
            duration: 800
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }

        SequentialAnimation {
            PauseAnimation {
                duration: 350
            }

            ParallelAnimation {
                NumberAnimation {
                    target: logo
                    property: "footOffset"
                    from: -160
                    to: 0
                    duration: 750
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: logo
                    property: "footOpacity"
                    from: 0.0
                    to: 1.0
                    duration: 500
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
