pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import M3Shapes
import Lumi.Config
import Lumi.Services
import qs.components
import qs.components.widgets
import qs.services

Item {
    id: root

    CoverArt {
        id: cover

        anchors.centerIn: parent
        shape.shape: MaterialShape.Cookie9Sided
        implicitWidth: Tokens.sizes.dashboard.mediaCoverArtSize
        implicitHeight: Tokens.sizes.dashboard.mediaCoverArtSize
    }
}
