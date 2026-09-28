import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

// Shield (hollow when exposed, filled when tunneled), plus mic/camera marks that only appear while in use
ColumnLayout {
    id: root

    required property color colour
    required property int parentSpacing

    spacing: 0

    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter

        animate: true
        text: Privacy.tunneled ? "shield_lock" : "shield"
        color: Privacy.tunneled ? Colours.palette.m3primary : root.colour
        fill: Privacy.tunneled ? 1 : 0
    }

    Sensor {
        active: Privacy.micInUse
        icon: "mic"
    }

    Sensor {
        active: Privacy.camInUse
        icon: "videocam"
    }

    component Sensor: Item {
        id: sensor

        required property bool active
        required property string icon

        property real shownHeight: active ? sensorIcon.implicitHeight + root.parentSpacing : 0

        Layout.alignment: Qt.AlignHCenter
        implicitWidth: sensorIcon.implicitWidth
        implicitHeight: Math.round(shownHeight)

        MaterialIcon {
            id: sensorIcon

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            scale: sensor.active ? 1 : 0.5
            opacity: sensor.active ? 1 : 0

            text: sensor.icon
            color: Colours.palette.m3error
            fill: 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }

        Behavior on shownHeight {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }
}
