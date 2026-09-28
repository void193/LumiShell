import "dash"
import QtQuick.Layouts
import Lumi.Config
import qs.components
import qs.services

GridLayout {
    id: root

    required property ScreenState screenState

    rowSpacing: Tokens.spacing.medium
    columnSpacing: Tokens.spacing.medium

    // Row 0: anonymous system card
    Rect {
        Layout.row: 0
        Layout.column: 0
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: sys.implicitHeight + Tokens.padding.large * 2

        radius: Tokens.rounding.extraLarge

        SysCard {
            id: sys
        }
    }

    // Row 1: clock, exposure readout, resources
    Rect {
        Layout.row: 1
        Layout.column: 0
        Layout.preferredWidth: dateTime.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.large

        DateTime {
            id: dateTime
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 1
        Layout.preferredWidth: privacy.implicitWidth + Tokens.padding.large * 2
        Layout.preferredHeight: privacy.implicitHeight + Tokens.padding.large * 2
        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: Tokens.rounding.extraLarge

        PrivacyCard {
            id: privacy
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 2
        Layout.preferredWidth: resources.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.large

        Resources {
            id: resources
        }
    }

    // Media spans both rows on the right
    Rect {
        Layout.row: 0
        Layout.column: 3
        Layout.rowSpan: 2
        Layout.preferredWidth: media.implicitWidth
        Layout.minimumHeight: media.implicitHeight
        Layout.fillHeight: true

        radius: Tokens.rounding.extraLarge * 2

        Media {
            id: media
        }
    }

    component Rect: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
    }
}
