pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Lumi.Config
import qs.components
import qs.components.controls
import qs.services

// Review step for the memory clean-up: nothing closes until "Clean now"
StyledRect {
    id: root

    function formatMb(mb: int): string {
        return mb >= 1024 ? `${(mb / 1024).toFixed(1)} GB` : `${mb} MB`;
    }

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.medium

    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        anchors.leftMargin: Tokens.padding.extraLargeIncreased
        anchors.rightMargin: Tokens.padding.extraLargeIncreased
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: "cleaning_services"
                color: Colours.palette.m3tertiary
                fontStyle: Tokens.font.icon.medium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: qsTr("Clean up memory")
                    font: Tokens.font.title.builders.small.weight(Font.Medium).build()
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (Cleaner.scanning)
                            return qsTr("Looking for heavy apps...");
                        if (Cleaner.candidates.length === 0)
                            return qsTr("Nothing heavy running. Memory looks healthy.");
                        return qsTr("Selected apps are asked to close. Apps with windows are never picked for you.");
                    }
                    color: Colours.palette.m3outline
                    wrapMode: Text.WordWrap
                    font: Tokens.font.body.small
                }
            }

            TextButton {
                type: TextButton.Text
                text: Cleaner.candidates.length === 0 && !Cleaner.scanning ? qsTr("Close") : qsTr("Cancel")
                disabled: Cleaner.cleaning
                onClicked: Cleaner.cancel()
            }

            TextButton {
                visible: Cleaner.candidates.length > 0
                type: TextButton.Filled
                text: Cleaner.cleaning ? qsTr("Cleaning...") : Cleaner.selected.length > 0 ? qsTr("Clean now · %1").arg(root.formatMb(Cleaner.selectedMb)) : qsTr("Clean now")
                disabled: Cleaner.selected.length === 0 || Cleaner.cleaning
                onClicked: Cleaner.cleanSelected()
            }
        }

        Repeater {
            model: ScriptModel {
                values: Cleaner.candidates
            }

            StyledRect {
                id: entry

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: entryLayout.implicitHeight + Tokens.padding.medium * 2
                radius: Tokens.rounding.small
                color: modelData.selected ? Qt.alpha(Colours.palette.m3tertiary, 0.12) : "transparent"

                Behavior on color {
                    CAnim {}
                }

                StateLayer {
                    radius: parent.radius
                    disabled: Cleaner.cleaning
                    onClicked: Cleaner.toggle(entry.modelData.pid)
                }

                RowLayout {
                    id: entryLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        animate: true
                        text: entry.modelData.selected ? "check_box" : "check_box_outline_blank"
                        fill: entry.modelData.selected ? 1 : 0
                        color: entry.modelData.selected ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
                    }

                    StyledText {
                        text: entry.modelData.name
                        font: Tokens.font.body.medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: entry.modelData.windowed ? qsTr("has a window") : qsTr("background")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                    }

                    StyledText {
                        text: root.formatMb(entry.modelData.mb)
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.medium
                    }
                }
            }
        }
    }
}
