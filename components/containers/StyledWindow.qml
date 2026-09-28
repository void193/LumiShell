import Quickshell
import Quickshell.Wayland
import Lumi.Config

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    required property string name

    WlrLayershell.namespace: `lumi-${name}`
    color: "transparent"

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name
}
