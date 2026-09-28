import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Lumi.Config
import qs.components
import qs.components.controls
import qs.services

// Picks which media player the dashboard controls
SplitButton {
    id: root

    property real maxWidth: 320

    type: SplitButton.Tonal
    disabled: !Players.list.length
    active: menuItems.find(m => m.modelData === Players.active) ?? menuItems[0] ?? null
    menu.onItemSelected: item => Players.manualActive = (item as PlayerItem).modelData

    menuItems: playerList.instances
    fallbackIcon: "music_off"
    fallbackText: qsTr("No players")

    minLeftWidth: maxWidth - expandBtn.implicitWidth - spacing
    label.Layout.maximumWidth: minLeftWidth - iconLabel.implicitWidth - textRow.spacing - textRow.anchors.horizontalCenterOffset / 2 - horizontalPadding * 2
    label.elide: Text.ElideRight

    stateLayer.disabled: true
    menuOnTop: true

    Variants {
        id: playerList

        model: Players.list

        PlayerItem {}
    }

    component PlayerItem: MenuItem {
        required property MprisPlayer modelData

        icon: modelData === Players.active ? "check" : ""
        text: Players.getIdentity(modelData)
        activeIcon: "animated_images"
    }
}
