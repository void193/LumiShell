import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar

    // Text to pre-fill the launcher search with the next time it opens (e.g. ">wallpaper ")
    property string launcherPreset

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
